"""Voice assistant: headset mic -> audio-input chat model with a shell tool -> cloud voice.

The model hears the user's audio directly, so there is no speech-to-text stage;
a separate text-to-speech model speaks its replies in a cloned voice. pipecat
supplies turn detection (silero vad + smart turn v3), interruption and sentence
streaming. SIGUSR1 toggles listening; the process starts deaf.
"""

import array
import asyncio
import math
import os
import signal
import sys
import time
from collections import deque
from collections.abc import AsyncGenerator

from loguru import logger
from openai import AsyncOpenAI
from pipecat.audio.turn.smart_turn.local_smart_turn_v3 import LocalSmartTurnAnalyzerV3
from pipecat.audio.vad.silero import SileroVADAnalyzer
from pipecat.frames.frames import (
    Frame,
    InputAudioRawFrame,
    InterruptionWorkerFrame,
    TTSAudioRawFrame,
)
from pipecat.pipeline.pipeline import Pipeline
from pipecat.pipeline.worker import PipelineParams, PipelineWorker
from pipecat.processors.aggregators.llm_context import LLMContext
from pipecat.processors.aggregators.llm_response_universal import (
    LLMContextAggregatorPair,
    LLMUserAggregatorParams,
)
from pipecat.processors.frame_processor import FrameDirection, FrameProcessor
from pipecat.services.llm_service import FunctionCallParams
from pipecat.services.openrouter.llm import OpenRouterLLMService
from pipecat.services.settings import TTSSettings
from pipecat.services.tts_service import TTSService
from pipecat.transports.local.audio import (
    LocalAudioTransport,
    LocalAudioTransportParams,
)
from pipecat.turns.user_start import VADUserTurnStartStrategy
from pipecat.turns.user_stop import TurnAnalyzerUserTurnStopStrategy
from pipecat.turns.user_turn_strategies import UserTurnStrategies
from pipecat.workers.runner import WorkerRunner

OPENROUTER_URL = "https://openrouter.ai/api/v1"
# fish audio's pcm rate on openrouter
OUTPUT_SAMPLE_RATE = 44100
# the vad needs some speech before it reports a turn; keep what came before it
PRE_ROLL_SECONDS = 0.6
# each kept turn is re-uploaded as audio on every request
KEPT_AUDIO_TURNS = 4


class Mic(FrameProcessor):
    """Gates the microphone and keeps its recent audio, so a turn can be sent as audio."""

    def __init__(self):
        super().__init__()
        self.listening = False
        self._frames: deque[tuple[float, InputAudioRawFrame]] = deque()
        self._turn_start = 0.0

    async def process_frame(self, frame: Frame, direction: FrameDirection):
        await super().process_frame(frame, direction)
        if isinstance(frame, InputAudioRawFrame):
            if not self.listening:
                return
            now = time.monotonic()
            self._frames.append((now, frame))
            while self._frames[0][0] < now - 60:
                self._frames.popleft()
        await self.push_frame(frame, direction)

    def turn_started(self):
        self._turn_start = time.monotonic() - PRE_ROLL_SECONDS

    def take_turn(self) -> list[InputAudioRawFrame]:
        frames = [frame for at, frame in self._frames if at >= self._turn_start]
        self._frames.clear()
        return frames


class CloudTTS(TTSService):
    """Speaks through openrouter's speech endpoint; pipecat's fish service needs a fish account."""

    def __init__(self, *, api_key: str, model: str, voice: str, **kwargs):
        super().__init__(
            push_start_frame=True,
            push_stop_frames=True,
            sample_rate=OUTPUT_SAMPLE_RATE,
            settings=TTSSettings(model=model, voice=voice, language=None),
            **kwargs,
        )
        self._client = AsyncOpenAI(api_key=api_key, base_url=OPENROUTER_URL)
        self._model = model
        self._voice = voice

    async def run_tts(self, text: str, context_id: str) -> AsyncGenerator[Frame, None]:
        # a chunk can end in the middle of a 16-bit sample
        carry = b""
        async with self._client.audio.speech.with_streaming_response.create(
            model=self._model, voice=self._voice, input=text, response_format="pcm"
        ) as response:
            async for chunk in response.iter_bytes(8192):
                pcm = carry + chunk
                cut = len(pcm) - len(pcm) % 2
                carry = pcm[cut:]
                yield TTSAudioRawFrame(
                    audio=pcm[:cut],
                    sample_rate=OUTPUT_SAMPLE_RATE,
                    num_channels=1,
                    context_id=context_id,
                )


def beep(rising: bool) -> TTSAudioRawFrame:
    """Two short tones mark the listening state; faster than a spoken cue."""
    tones = (660, 880) if rising else (880, 660)
    samples = array.array("h")
    for tone in tones:
        for n in range(OUTPUT_SAMPLE_RATE // 12):
            samples.append(
                int(6000 * math.sin(2 * math.pi * tone * n / OUTPUT_SAMPLE_RATE))
            )
    return TTSAudioRawFrame(
        audio=samples.tobytes(), sample_rate=OUTPUT_SAMPLE_RATE, num_channels=1
    )


def drop_old_audio(context: LLMContext):
    """Replace all but the newest turns' audio with a note, to bound the upload."""
    spoken = [
        message
        for message in context.get_messages()
        if message["role"] == "user"
        and isinstance(message["content"], list)
        and any(part["type"] == "input_audio" for part in message["content"])
    ]
    for message in spoken[: -(KEPT_AUDIO_TURNS - 1)]:
        message["content"] = "(earlier spoken request; audio no longer available)"


async def run_shell(params: FunctionCallParams, command: str):
    """Run a bash command on the user's desktop and return its output.

    Args:
        command: The bash command line to run.
    """
    process = await asyncio.create_subprocess_exec(
        "bash",
        "-c",
        command,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.STDOUT,
        cwd=os.path.expanduser("~"),
    )
    try:
        output, _ = await asyncio.wait_for(process.communicate(), timeout=30)
    except TimeoutError:
        process.kill()
        await params.result_callback({"error": "timed out after 30 seconds"})
        return
    await params.result_callback(
        {
            "exit_code": process.returncode,
            "output": output.decode(errors="replace")[-4000:],
        }
    )


async def main(system_prompt: str):
    transport = LocalAudioTransport(
        LocalAudioTransportParams(
            audio_in_enabled=True,
            audio_out_enabled=True,
            audio_out_sample_rate=OUTPUT_SAMPLE_RATE,
        )
    )
    mic = Mic()
    api_key = os.environ["OPENROUTER_API_KEY"]
    llm = OpenRouterLLMService(
        api_key=api_key,
        settings=OpenRouterLLMService.Settings(
            model=os.environ["VOICE_ASSISTANT_MODEL"],
            system_instruction=system_prompt,
        ),
    )
    tts = CloudTTS(
        api_key=api_key,
        model=os.environ["VOICE_ASSISTANT_TTS_MODEL"],
        voice=os.environ["VOICE_ASSISTANT_VOICE"],
    )

    context = LLMContext(tools=[run_shell])
    user_aggregator, assistant_aggregator = LLMContextAggregatorPair(
        context,
        user_params=LLMUserAggregatorParams(
            vad_analyzer=SileroVADAnalyzer(),
            user_turn_strategies=UserTurnStrategies(
                start=[VADUserTurnStartStrategy()],
                stop=[
                    # there is no transcript; the turn ends on smart turn alone
                    TurnAnalyzerUserTurnStopStrategy(
                        turn_analyzer=LocalSmartTurnAnalyzerV3(),
                        wait_for_transcript=False,
                    )
                ],
            ),
            # every turn looks empty without a transcript; the handler below answers it
            empty_user_turn=None,
        ),
    )

    @user_aggregator.event_handler("on_user_turn_started")
    async def on_user_turn_started(aggregator, strategy):
        mic.turn_started()

    @user_aggregator.event_handler("on_user_turn_stopped")
    async def on_user_turn_stopped(aggregator, strategy, message):
        frames = mic.take_turn()
        if not frames:
            return
        drop_old_audio(context)
        await context.add_audio_frames_message(audio_frames=frames, text="(spoken)")
        await aggregator.push_context_frame()

    worker = PipelineWorker(
        Pipeline(
            [
                transport.input(),
                mic,
                user_aggregator,
                llm,
                tts,
                transport.output(),
                assistant_aggregator,
            ]
        ),
        params=PipelineParams(enable_metrics=True),
    )

    async def toggle():
        mic.listening = not mic.listening
        logger.info(f"listening: {mic.listening}")
        if not mic.listening:
            await worker.queue_frames([InterruptionWorkerFrame()])
        await worker.queue_frames([beep(rising=mic.listening)])

    asyncio.get_running_loop().add_signal_handler(
        signal.SIGUSR1, lambda: asyncio.create_task(toggle())
    )

    runner = WorkerRunner()
    await runner.add_workers(worker)
    await runner.run()


if __name__ == "__main__":
    logger.remove()
    logger.add(sys.stderr, level=os.environ.get("VOICE_ASSISTANT_LOG_LEVEL", "INFO"))
    with open(os.environ["VOICE_ASSISTANT_PROMPT"]) as f:
        asyncio.run(main(f.read()))
