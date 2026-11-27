"""openai-style speech-to-text endpoint on faster-whisper, for silo"""

import os
import signal
import threading
import time
from typing import Annotated

import uvicorn
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.responses import PlainTextResponse
from faster_whisper import WhisperModel

app = FastAPI()
lock = threading.Lock()
model = None
last_used = 0.0


def release_when_idle(idle_seconds):
    # dropping the model keeps a 240 MiB cuda context; only an exit frees
    # all vram. systemd restarts the server with nothing loaded
    while True:
        time.sleep(5)
        with lock:
            if model and time.monotonic() - last_used > idle_seconds:
                os.kill(os.getpid(), signal.SIGTERM)
                return


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/v1/audio/transcriptions")
def transcribe(
    file: Annotated[UploadFile, File()],
    language: Annotated[str, Form()] = "",
    # on unless a client says otherwise: without it whisper turns silence into
    # repeated filler words. silo sends the field itself
    vad_filter: Annotated[bool, Form()] = True,
    # openai's default; silo asks for verbose_json
    response_format: Annotated[str, Form()] = "json",
):
    global model, last_used
    verbose = response_format == "verbose_json"
    with lock:
        if model is None:
            model = WhisperModel(
                os.environ["WHISPER_MODEL"],
                device="cuda",
                compute_type="int8_float16",
            )
        segments, info = model.transcribe(
            file.file,
            language=language or None,
            vad_filter=vad_filter,
            word_timestamps=verbose,
            temperature=0,
        )
        # silo joins the words with spaces, so they have to be whole words
        result = [
            {
                "id": index,
                "start": segment.start,
                "end": segment.end,
                "text": segment.text,
                "words": [
                    {"word": word.word, "start": word.start, "end": word.end}
                    for word in segment.words or []
                ],
            }
            for index, segment in enumerate(segments)
        ]
        last_used = time.monotonic()
    text = "".join(segment["text"] for segment in result)
    if response_format == "text":
        return PlainTextResponse(text)
    if not verbose:
        return {"text": text}
    return {
        "task": "transcribe",
        "language": info.language,
        "duration": info.duration,
        "text": text,
        "segments": result,
    }


if __name__ == "__main__":
    threading.Thread(
        target=release_when_idle,
        args=(int(os.environ["WHISPER_IDLE_SECONDS"]),),
        daemon=True,
    ).start()
    uvicorn.run(
        app,
        host=os.environ["WHISPER_HOST"],
        port=int(os.environ["WHISPER_PORT"]),
    )
