<div align="center">

# EpubVoice

**Your books, read aloud in your own voice.**

A personal epub reader with text-to-speech — built as a self-hosted alternative to ElevenLabs Reader.
No subscription. No limits. Your voice. Your data.

[![Flutter](https://img.shields.io/badge/Flutter-3.41-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Python](https://img.shields.io/badge/Python-3.13+-3776AB?logo=python&logoColor=white)](https://python.org)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Release](https://img.shields.io/github/v/release/JulienR0y/epubvoice?color=brightgreen)](https://github.com/JulienR0y/epubvoice/releases)

<br />

<p>
  <img src="assets/screenshots/home.png" width="230" alt="Home screen" />
  &nbsp;&nbsp;&nbsp;
  <img src="assets/screenshots/library.png" width="230" alt="Chapter list" />
  &nbsp;&nbsp;&nbsp;
  <img src="assets/screenshots/reader.png" width="230" alt="Reader with TTS controls" />
</p>

<br />

[Download APK](https://github.com/JulienR0y/epubvoice/releases/latest) &nbsp;&bull;&nbsp; [Report Bug](https://github.com/JulienR0y/epubvoice/issues) &nbsp;&bull;&nbsp; [V2 Roadmap](#roadmap)

</div>

---

## Features

- **Import** any `.epub` file from your phone
- **Chapter navigation** with TOC support (EPUB 2 NCX + EPUB 3 nav)
- **Text-to-speech** using native Android TTS
- **Playback controls** — play, pause, skip forward, skip backward
- **Speed control** — 0.75x, 1x, 1.25x, 1.5x
- **Progress persistence** — remembers your position across sessions
- **Dark theme** — easy on the eyes for long reading sessions

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) 3.41+
- Android device or emulator
- [Android SDK](https://developer.android.com/studio) with platform 36

### Install from release

Download the latest APK from the [Releases](https://github.com/JulienR0y/epubvoice/releases/latest) page, transfer to your Android phone, and install.

### Build from source

```bash
git clone https://github.com/JulienR0y/epubvoice.git
cd epubvoice/app

# Deploy directly to a connected device
flutter run

# Or build a release APK
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

## Architecture

```
epubvoice/
├── app/                          Flutter mobile app (Dart)
│   └── lib/
│       ├── main.dart             App entry, dark theme
│       ├── models/
│       │   └── chapter.dart      Chapter data model
│       ├── screens/
│       │   ├── home_screen.dart      Import epub
│       │   ├── library_screen.dart   Chapter list
│       │   └── reader_screen.dart    TTS reading + controls
│       └── services/
│           ├── epub_parser.dart      OPF/NCX/nav parsing
│           ├── tts_service.dart      flutter_tts wrapper
│           └── progress_service.dart shared_preferences
│
└── server/                       V2: Local TTS server (Python)
    ├── main.py                   FastAPI + /synthesize endpoint
    ├── tts_engine.py             Coqui XTTS wrapper
    └── voice_sample/             Your recorded voice goes here
```

## Tech Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| App | **Flutter** / Dart | Cross-platform mobile UI |
| TTS (V1) | **flutter_tts** | Native Android text-to-speech |
| Epub parsing | **archive** + **xml** | Custom zip extraction + XML parsing |
| File import | **file_picker** | System file picker for epub selection |
| Persistence | **shared_preferences** | Save/restore reading position |
| TTS Server (V2) | **Python** / FastAPI | Voice cloning API server |
| Voice Model (V2) | **Coqui XTTS v2** | Open source voice cloning |

## Roadmap

### V1 — Native TTS Reader *(shipped)*

- [x] Epub import and parsing
- [x] Chapter list with TOC titles
- [x] TTS playback with controls
- [x] Speed adjustment
- [x] Progress persistence
- [x] Dark theme UI

### V2 — Cloned Voice *(in progress)*

- [ ] Local Python TTS server with Coqui XTTS v2
- [ ] Voice cloning from a 60-second recording
- [ ] Auto-detect server on local WiFi
- [ ] Fallback to native TTS when server is offline
- [ ] Server setup script

## Design Decisions

<details>
<summary><strong>Why Flutter over React Native?</strong></summary>

<br />

Originally built with React Native / Expo. Switched after hitting multiple toolchain issues:

- `expo-modules-core` ships TypeScript source as its package entry point — Node.js can't execute `.ts` files, crashing the CLI at startup
- Node version sensitivity: v20, v22, and v25 all failed differently
- npm peer dependency conflicts between Expo SDK, React, and expo-router
- React Native's `Blob`/`FileReader` API gaps broke every epub parser we tried

Flutter's `pub` resolved all dependencies on the first try. The epub parser runs pure Dart — no native module compatibility concerns.

</details>

<details>
<summary><strong>Why a custom epub parser?</strong></summary>

<br />

Tried `epub.js` and `@lingo-reader/epub-parser` — both depend on browser APIs (`FileReader`, `Blob`, `DOMParser`) that don't exist or are incomplete in mobile runtimes. A custom parser using `archive` (zip) + `xml` gives full control and handles both EPUB 2 (NCX) and EPUB 3 (nav.xhtml) table of contents.

</details>

<details>
<summary><strong>Why paragraph-level chunking?</strong></summary>

<br />

TTS engines handle shorter text better and have inconsistent behavior with long strings. Splitting by paragraph also enables precise skip forward/back and accurate position tracking for progress persistence.

</details>

<details>
<summary><strong>Why Coqui XTTS for V2?</strong></summary>

<br />

Free, runs locally, voice data never leaves the machine, no API rate limits. The only requirement is a 30–60 second clean voice recording.

</details>

---

<div align="center">

Made by [Julien Roy](https://github.com/JulienR0y)

</div>
