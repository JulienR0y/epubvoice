# EpubVoice — Personal Epub Reader with Cloned Voice
## Project Plan for Claude Code

---

## What I'm Building

A personal mobile app that lets me import an `.epub` file and have it read aloud in my own cloned voice. This is a simpler, self-hosted alternative to ElevenLabs Reader — no subscription, no limits, my voice, my data.

This is a **portfolio project** that solves a real problem I have. I want to be able to explain every decision in it.

---

## The Architecture (High Level)

```
[Phone App] ←→ WiFi ←→ [Local TTS Server on my computer]
     |                           |
  React Native             Coqui XTTS (voice cloning)
  Expo                     Python + FastAPI
  expo-speech (fallback)   My cloned voice model
```

**Phase 1 (V1):** App only, using device native TTS (no server needed, ship fast)
**Phase 2 (V2):** Add local TTS server with my cloned voice

---

## Tech Stack

### Mobile App
- **React Native** with **Expo** (managed workflow)
- **TypeScript**
- **expo-speech** — native TTS for V1
- **expo-document-picker** — import epub from phone
- **expo-file-system** — read and store epub locally
- **@react-native-async-storage/async-storage** — save reading progress
- **epubjs** — parse epub content and extract chapters

### Local TTS Server (V2)
- **Python 3.13+**
- **Coqui XTTS v2** — open source voice cloning model
- **FastAPI** — lightweight HTTP server
- **uvicorn** — ASGI server runner

---

## V1 Feature Scope (ship this first, nothing more)

- [ ] Import a single `.epub` file from the phone
- [ ] Parse epub and show a list of chapters
- [ ] Tap a chapter to start reading it aloud (native TTS)
- [ ] Play / Pause button
- [ ] Skip forward / backward by paragraph
- [ ] Playback speed control (0.75x, 1x, 1.25x, 1.5x)
- [ ] Remember last position when app is closed
- [ ] Minimal but clean UI (dark background, readable font)

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
├── CLAUDE.md                  ← this file
├── app/                       ← React Native / Expo app
│   ├── app/
│   │   ├── index.tsx          ← home screen (import epub)
│   │   ├── library.tsx        ← chapter list
│   │   └── reader.tsx         ← reading screen with TTS controls
│   ├── components/
│   │   ├── PlayerControls.tsx ← play/pause/skip/speed
│   │   ├── ChapterList.tsx    ← scrollable chapter selector
│   │   └── ImportButton.tsx   ← epub file picker
│   ├── hooks/
│   │   ├── useEpubParser.ts   ← parse epub, extract chapters
│   │   ├── useTTS.ts          ← manage speech synthesis
│   │   └── useProgress.ts     ← save/load reading position
│   ├── utils/
│   │   └── epubUtils.ts       ← helper functions for epub parsing
│   ├── package.json
│   └── app.json
│
└── server/                    ← V2: local TTS server (Python)
    ├── main.py                ← FastAPI server
    ├── tts_engine.py          ← Coqui XTTS wrapper
    ├── voice_sample/          ← my recorded voice samples go here
    ├── requirements.txt
    └── README.md              ← how to run the server
```

---

## Build Order

Work through these phases in order. Do not skip ahead.

### Phase 1 — Scaffold & Import
1. Initialize Expo project with TypeScript: `npx create-expo-app epubvoice --template`
2. Install all dependencies listed above
3. Build `ImportButton` component using `expo-document-picker`
4. Store imported epub file locally using `expo-file-system`
5. Verify the file is saved and readable

### Phase 2 — Epub Parsing
1. Integrate `epubjs` to parse the stored epub file
2. Extract chapter list (title + content)
3. Strip HTML tags from chapter content to get clean plain text
4. Build `ChapterList` component to display chapters
5. Wire up navigation from home screen → chapter list

### Phase 3 — TTS Reading
1. Build `useTTS` hook wrapping `expo-speech`
2. Split chapter text into paragraph-sized chunks (for better control)
3. Implement play / pause (stop and resume speech)
4. Implement skip forward / backward by paragraph index
5. Implement speed control (pass rate to expo-speech)
6. Build `PlayerControls` component

### Phase 4 — Progress & Polish
1. Build `useProgress` hook using AsyncStorage
2. Save: current book, current chapter, current paragraph index
3. Restore position on app open
4. Basic UI polish — dark theme, readable font size, comfortable spacing
5. Test on a real device (not just simulator)

### Phase 5 — V2 Local Server (after V1 is fully working)
1. Set up Python environment and install Coqui XTTS
2. Record 60-second voice sample (clean audio, no background noise)
3. Build FastAPI endpoint: `POST /synthesize` accepts `{text: string}`, returns audio
4. Test server locally, confirm audio quality
5. Update `useTTS` hook: check if server is reachable, use it if yes, fallback to native if no
6. Add server URL setting in app (so I can change IP if needed)

---

## Key Technical Decisions & Rationale

**Why Expo managed workflow?**
Faster setup, no Xcode/Android Studio config hell for V1. Can eject later if needed.

**Why native TTS for V1?**
Zero setup, works offline, ships faster. The goal is a working app first, perfect voice second.

**Why Coqui XTTS for V2 instead of ElevenLabs API?**
Free, runs locally, voice data never leaves my machine, no rate limits.

**Why FastAPI for the server?**
Minimal boilerplate, async by default, auto-generates API docs, easy to test.

**Why paragraph-level chunking for TTS?**
`expo-speech` has limits on text length and doesn't handle very long strings well. Chunking by paragraph also gives better control over skip forward/back behavior.

---

## Known Challenges to Watch For

- **epub parsing inconsistency:** epub files vary a lot in structure. Some use `<p>` tags, some use `<div>`, some have nested HTML. The HTML stripping logic needs to handle edge cases.
- **expo-speech on iOS vs Android:** behavior differs slightly (pausing, rate limits). Test on both.
- **Local server IP:** When on WiFi, the computer's local IP can change. Either hardcode it in a settings screen or use mDNS/Bonjour to discover it.
- **XTTS cold start:** The first synthesis request after starting the server takes longer (model loads into memory). Handle loading state in the app.

---

## How to Run (once set up)

```bash
# Mobile app
cd app
npx expo start

# Local TTS server (V2)
cd server
pip install -r requirements.txt
python main.py
```

---

## Definition of Done for V1

- I can pick an epub from my phone
- I can see the chapter list
- I tap a chapter and it reads it out loud
- I can pause, resume, skip paragraphs
- I can change speed
- When I close and reopen the app, it remembers where I was
- It runs on my actual phone without crashing
