# EpubVoice — Personal Epub Reader with Cloned Voice
## Project Plan

---

## What I'm Building

A personal mobile app that lets me import an `.epub` file and have it read aloud in my own cloned voice. This is a simpler, self-hosted alternative to ElevenLabs Reader — no subscription, no limits, my voice, my data.

This is a **portfolio project** that solves a real problem I have. I want to be able to explain every decision in it.

---

## The Architecture (High Level)

```
[Phone App] ←→ WiFi ←→ [Local TTS Server on my computer]
     |                           |
  Flutter / Dart           Coqui XTTS (voice cloning)
  flutter_tts              Python + FastAPI
  (native TTS fallback)    My cloned voice model
```

**Phase 1 (V1):** App only, using device native TTS (no server needed, ship fast)
**Phase 2 (V2):** Add local TTS server with my cloned voice

---

## Tech Stack

### Mobile App
- **Flutter 3.41+** / **Dart 3.11+**
- **flutter_tts** — native TTS for V1
- **file_picker** — import epub from phone
- **shared_preferences** — save reading progress
- **archive** + **xml** — custom epub parser (zip extraction + XML parsing)

### Local TTS Server (V2)
- **Python 3.13+**
- **Coqui XTTS v2** — open source voice cloning model
- **FastAPI** — lightweight HTTP server
- **uvicorn** — ASGI server runner

---

## V1 Feature Scope (ship this first, nothing more)

- [x] Import a single `.epub` file from the phone
- [x] Parse epub and show a list of chapters
- [x] Tap a chapter to start reading it aloud (native TTS)
- [x] Play / Pause button
- [x] Skip forward / backward by paragraph
- [x] Playback speed control (0.75x, 1x, 1.25x, 1.5x)
- [x] Remember last position when app is closed
- [x] Minimal but clean UI (dark background, readable font)

**Explicitly out of scope for V1:**
- Multiple books / library management
- Custom voice (that's V2)
- Cloud sync
- Bookmarks
- User accounts
- Any backend

---

## V2 Feature Scope (after V1 ships)

- [ ] Local Python TTS server running on my computer
- [ ] Voice cloning with my recorded voice using Coqui XTTS
- [ ] App detects if server is reachable on local WiFi
- [ ] If server available → use cloned voice
- [ ] If server not available → fallback to native TTS
- [ ] Server setup script and README

---

## Project File Structure

```
epubvoice/
├── README.md
├── CLAUDE.md                       ← this file
├── app/                            ← Flutter mobile app
│   └── lib/
│       ├── main.dart               ← app entry, dark theme
│       ├── models/
│       │   └── chapter.dart        ← Chapter data model
│       ├── screens/
│       │   ├── home_screen.dart    ← import epub
│       │   ├── library_screen.dart ← chapter list
│       │   └── reader_screen.dart  ← TTS reading + controls
│       └── services/
│           ├── epub_parser.dart    ← OPF/NCX/nav parsing
│           ├── tts_service.dart    ← flutter_tts wrapper
│           └── progress_service.dart ← shared_preferences
│
└── server/                         ← V2: local TTS server (Python)
    ├── main.py                     ← FastAPI server
    ├── tts_engine.py               ← Coqui XTTS wrapper
    ├── voice_sample/               ← recorded voice samples
    ├── requirements.txt
    └── README.md
```

---

## Key Technical Decisions & Rationale

**Why Flutter instead of React Native?**
Started with Expo/React Native but hit too many toolchain issues: expo-modules-core shipping TS source that broke Node CLI, npm peer dependency hell, Blob/FileReader API gaps in RN. Flutter's pub manager resolved all deps on first try, and the epub parser runs pure Dart.

**Why native TTS for V1?**
Zero setup, works offline, ships faster. The goal is a working app first, perfect voice second.

**Why a custom epub parser instead of a library?**
epub.js and @lingo-reader/epub-parser both broke in mobile runtimes (browser API dependencies). A custom parser using archive (zip) + xml gives full control and handles EPUB 2/3 variants.

**Why Coqui XTTS for V2 instead of ElevenLabs API?**
Free, runs locally, voice data never leaves my machine, no rate limits.

**Why FastAPI for the server?**
Minimal boilerplate, async by default, auto-generates API docs, easy to test.

**Why paragraph-level chunking for TTS?**
TTS engines handle shorter text better. Chunking by paragraph also gives precise skip forward/back and position tracking.

---

## Known Challenges to Watch For

- **epub parsing inconsistency:** epub files vary a lot in structure. Some use `<p>` tags, some use `<div>`, some have nested HTML. The parser handles common cases but edge cases exist.
- **flutter_tts rate mapping:** Android uses 0.0–1.0 range where 0.5 is normal. User-facing speeds are mapped accordingly (1.0x → 0.5 native).
- **Local server IP:** When on WiFi, the computer's local IP can change. Either hardcode it in a settings screen or use mDNS/Bonjour to discover it.
- **XTTS cold start:** The first synthesis request after starting the server takes longer (model loads into memory). Handle loading state in the app.

---

## How to Run

```bash
# Mobile app — deploy to connected Android device
cd app
flutter run

# Or build a debug APK
flutter build apk --debug

# Local TTS server (V2)
cd server
pip install -r requirements.txt
python main.py
```

---

## Definition of Done for V1

- [x] I can pick an epub from my phone
- [x] I can see the chapter list
- [x] I tap a chapter and it reads it out loud
- [x] I can pause, resume, skip paragraphs
- [x] I can change speed
- [x] When I close and reopen the app, it remembers where I was
- [x] It runs on my actual phone without crashing
