"""Voice assistant: headset mic -> whisper -> openrouter llm with a shell tool -> kokoro.

pipecat supplies turn detection (silero vad + smart turn v3), interruption and
sentence streaming. SIGUSR1 toggles listening; the process starts deaf.
"""

import asyncio
import os
import signal
import sys
from collections.abc import AsyncGenerator

import numpy as np
from kokoro import KModel, KPipeline
from loguru import logger
from pipecat.audio.vad.silero import SileroVADAnalyzer
from pipecat.frames.frames import (
    Frame,
    InputAudioRawFrame,
    InterruptionWorkerFrame,
    TTSAudioRawFrame,
    TTSSpeakFrame,
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
from pipecat.services.whisper.stt import WhisperSTTService
from pipecat.transports.local.audio import (
    LocalAudioTransport,
    LocalAudioTransportParams,
)
from pipecat.workers.runner import WorkerRunner

KOKORO_REPO = "hexgrad/Kokoro-82M"
KOKORO_SAMPLE_RATE = 24000


class KokoroTTS(TTSService):
    """pipecat's own kokoro service needs kokoro-onnx, which nixpkgs lacks."""

    def __init__(self, *, config: str, weights: str, voice: str, **kwargs):
        super().__init__(
            push_start_frame=True,
            push_stop_frames=True,
            sample_rate=KOKORO_SAMPLE_RATE,
            settings=TTSSettings(model=None, voice=voice, language=None),
            **kwargs,
        )
        model = KModel(repo_id=KOKORO_REPO, config=config, model=weights).eval()
        self._pipeline = KPipeline(lang_code="a", repo_id=KOKORO_REPO, model=model)
        self._voice = voice

    def _synthesize(self, text: str) -> bytes:
        chunks = [r.audio.numpy() for r in self._pipeline(text, voice=self._voice)]
        if not chunks:
            return b""
        pcm = (np.concatenate(chunks) * 32767).clip(-32768, 32767)
        return pcm.astype(np.int16).tobytes()

    async def run_tts(self, text: str, context_id: str) -> AsyncGenerator[Frame, None]:
        audio = await asyncio.to_thread(self._synthesize, text)
        yield TTSAudioRawFrame(
            audio=audio,
            sample_rate=KOKORO_SAMPLE_RATE,
            num_channels=1,
            context_id=context_id,
        )


class MicGate(FrameProcessor):
    """Drops microphone audio while the assistant is not listening."""

    def __init__(self):
        super().__init__()
        self.listening = False

    async def process_frame(self, frame: Frame, direction: FrameDirection):
        await super().process_frame(frame, direction)
        if isinstance(frame, InputAudioRawFrame) and not self.listening:
            return
        await self.push_frame(frame, direction)


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
        LocalAudioTransportParams(audio_in_enabled=True, audio_out_enabled=True)
    )
    gate = MicGate()
    stt = WhisperSTTService(
        device="cpu",
        compute_type="int8",
        settings=WhisperSTTService.Settings(model=os.environ["WHISPER_MODEL"]),
    )
    llm = OpenRouterLLMService(
        api_key=os.environ["OPENROUTER_API_KEY"],
        settings=OpenRouterLLMService.Settings(
            model=os.environ["VOICE_ASSISTANT_MODEL"],
            system_instruction=system_prompt,
        ),
    )
    tts = KokoroTTS(
        config=os.environ["KOKORO_CONFIG"],
        weights=os.environ["KOKORO_WEIGHTS"],
        voice=os.environ["KOKORO_VOICE"],
    )

    context = LLMContext(tools=[run_shell])
    user_aggregator, assistant_aggregator = LLMContextAggregatorPair(
        context,
        user_params=LLMUserAggregatorParams(vad_analyzer=SileroVADAnalyzer()),
    )

    worker = PipelineWorker(
        Pipeline(
            [
                transport.input(),
                gate,
                stt,
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
        gate.listening = not gate.listening
        logger.info(f"listening: {gate.listening}")
        if gate.listening:
            await worker.queue_frames([TTSSpeakFrame("Listening.")])
        else:
            await worker.queue_frames([InterruptionWorkerFrame()])

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
