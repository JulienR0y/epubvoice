# EpubVoice — Local TTS Server (V2)

Runs on your computer and synthesizes speech in your cloned voice using Coqui XTTS v2.

## Requirements

- Python 3.13+
- ~5 GB disk space for the XTTS model
- A GPU is optional but speeds up synthesis significantly

## Setup

```bash
cd server
python -m venv .venv
source .venv/bin/activate      # Windows: .venv\Scripts\activate
pip install -r requirements.txt
```

## Record your voice sample

1. Record 30–60 seconds of yourself reading clearly (no background noise, no music)
2. Save it as `voice_sample/my_voice.wav` (WAV or MP3 both work)
3. The server picks up the first file it finds in `voice_sample/`

## Run

```bash
python main.py
```

Server starts at `http://0.0.0.0:8000`.

First request will be slow — XTTS loads the model into memory (~30s).
Subsequent requests are fast.

## API

### `GET /health`
Returns `{"status": "ok"}` when the server is up.

### `POST /synthesize`
```json
{ "text": "Hello, this is a test.", "language": "en" }
```
Returns raw WAV audio bytes (`audio/wav`).

## Finding your local IP

The app needs your computer's local IP address to reach this server over WiFi.

```bash
# macOS / Linux
ipconfig getifaddr en0       # or: ip addr show

# Windows
ipconfig
```

Look for something like `192.168.x.x`. Enter that in the app's server settings screen.
