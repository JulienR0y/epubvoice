import io
import wave
from pathlib import Path
from TTS.api import TTS

VOICE_SAMPLE_DIR = Path(__file__).parent / "voice_sample"
MODEL_NAME = "tts_models/multilingual/multi-dataset/xtts_v2"


class TTSEngine:
    def __init__(self) -> None:
        self._tts: TTS | None = None

    def _load(self) -> TTS:
        """Lazy-load the model on first use (cold start is slow)."""
        if self._tts is None:
            self._tts = TTS(MODEL_NAME, gpu=False)
        return self._tts

    def _find_voice_sample(self) -> str:
        for ext in ("*.wav", "*.mp3"):
            samples = list(VOICE_SAMPLE_DIR.glob(ext))
            if samples:
                return str(samples[0])
        raise FileNotFoundError(
            f"No voice sample found in {VOICE_SAMPLE_DIR}. "
            "Add a clean 30-60s WAV or MP3 recording of your voice."
        )

    def synthesize(self, text: str, language: str = "en") -> bytes:
        """Return raw WAV bytes for the given text."""
        tts = self._load()
        speaker_wav = self._find_voice_sample()

        buf = io.BytesIO()
        tts.tts_to_file(
            text=text,
            speaker_wav=speaker_wav,
            language=language,
            file_path=buf,
        )
        buf.seek(0)
        return buf.read()


# Module-level singleton — shared across requests
engine = TTSEngine()
