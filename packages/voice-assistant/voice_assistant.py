"""Voice assistant: headset mic -> a speech-to-speech chat model with a shell tool -> headset.

The model hears the user's audio and answers in audio, so there is no local
speech-to-text or text-to-speech. pipecat supplies turn detection (silero vad +
smart turn v3) and interruption. SIGUSR1 toggles listening; the process starts
deaf.
"""

import array
import asyncio
import base64
import math
import os
import signal
import sys
import time
from collections import deque

from loguru import logger
from pipecat.audio.turn.smart_turn.local_smart_turn_v3 import LocalSmartTurnAnalyzerV3
from pipecat.audio.vad.silero import SileroVADAnalyzer
from pipecat.frames.frames import (
    Frame,
    InputAudioRawFrame,
    InterruptionWorkerFrame,
    TTSAudioRawFrame,
    TTSStartedFrame,
    TTSStoppedFrame,
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
from pipecat.transports.local.audio import (
    LocalAudioTransport,
    LocalAudioTransportParams,
)
from pipecat.turns.user_start import VADUserTurnStartStrategy
from pipecat.turns.user_stop import TurnAnalyzerUserTurnStopStrategy
from pipecat.turns.user_turn_strategies import UserTurnStrategies
from pipecat.workers.runner import WorkerRunner

# the model's pcm16 output rate
OUTPUT_SAMPLE_RATE = 24000
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


class SpeechLLM(OpenRouterLLMService):
    """pipecat forwards this model's transcript but drops its audio; play the audio."""

    async def get_chat_completions(self, context: LLMContext):
        return self._play_audio(await super().get_chat_completions(context))

    async def _play_audio(self, chunks):
        speaking = False
        # a base64 chunk can end in the middle of a 16-bit sample
        carry = b""
        try:
            async for chunk in chunks:
                delta = chunk.choices[0].delta if chunk.choices else None
                audio = getattr(delta, "audio", None) or {}
                if audio.get("data"):
                    if not speaking:
                        speaking = True
                        await self.push_frame(TTSStartedFrame())
                    pcm = carry + base64.b64decode(audio["data"])
                    cut = len(pcm) - len(pcm) % 2
                    carry = pcm[cut:]
                    await self.push_frame(
                        TTSAudioRawFrame(
                            audio=pcm[:cut],
                            sample_rate=OUTPUT_SAMPLE_RATE,
                            num_channels=1,
                        )
                    )
                yield chunk
        finally:
            await chunks.close()
            if speaking:
                await self.push_frame(TTSStoppedFrame())


def beep(rising: bool) -> TTSAudioRawFrame:
    """Two short tones: the only cue for the listening state, as nothing speaks locally."""
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
    llm = SpeechLLM(
        api_key=os.environ["OPENROUTER_API_KEY"],
        settings=SpeechLLM.Settings(
            model=os.environ["VOICE_ASSISTANT_MODEL"],
            system_instruction=system_prompt,
            extra={
                "modalities": ["text", "audio"],
                "audio": {
                    "voice": os.environ["VOICE_ASSISTANT_VOICE"],
                    "format": "pcm16",
                },
            },
        ),
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
