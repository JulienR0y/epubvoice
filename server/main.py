from fastapi import FastAPI, HTTPException
from fastapi.responses import Response
from pydantic import BaseModel

from tts_engine import engine

app = FastAPI(title="EpubVoice TTS Server")


class SynthesizeRequest(BaseModel):
    text: str
    language: str = "en"


@app.get("/health")
def health() -> dict:
    return {"status": "ok"}


@app.post("/synthesize")
def synthesize(req: SynthesizeRequest) -> Response:
    if not req.text.strip():
        raise HTTPException(status_code=400, detail="text must not be empty")

    try:
        audio_bytes = engine.synthesize(req.text, req.language)
    except FileNotFoundError as e:
        raise HTTPException(status_code=503, detail=str(e))

    return Response(content=audio_bytes, media_type="audio/wav")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=False)
