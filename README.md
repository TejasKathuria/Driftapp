# 🎵 Drift — Real-Time Synced Lyrics for macOS

> **Drift** is a native macOS application that identifies the currently playing song and active verse in real-time, overlaying gorgeous, synchronized lyrics on your MacBook's display with millisecond precision.

---

## ✨ Features

- **🎯 Song & Verse Identification**:
  - Automatically hooks into **Spotify** and **Apple Music** (via AppleScript automation).
  - High-frequency interpolated clock (50ms interval) for zero-latency, sub-millisecond audio-lyric sync without drift.
  - Intelligent verse section detection (`[Verse 1]`, `[Chorus]`, `[Bridge]`, `[Outro]`, and instrumental preludes `• • •`).

- **⚡ Full Synced Lyrics Accuracy**:
  - Direct integration with the **LRCLIB** database for millisecond-stamped synced lyrics (`syncedLyrics`).
  - Offline disk & memory caching (`~/Library/Caches/DriftLyrics/`) for instantaneous reloads.
  - Manual sync calibration (`-3.0s` to `+3.0s`) with intuitive stepper buttons and slider.

- **💎 Appealing Display Modes**:
  1. **Floating Glass HUD**:
     - Modern glassmorphism (`.ultraThinMaterial` / liquid blur) with customizable backdrop opacity.
     - Active verse highlighted with bold typography, vibrant gradient colors, and glowing drop shadow.
     - **Dynamic Karaoke Sweep**: Text smoothly illuminates from left to right as the line is sung.
     - Interactive scrubbing & verse seeking: Click any lyric line to jump playback directly to that verse!
     - **Click-Through Mode** (`⌘L` or lock icon): Allows working/coding under the lyrics overlay without accidental clicks.
  2. **Notch Dynamic Island**:
     - Snaps right below the MacBook notch or top of the screen.
     - Compact pill showing vinyl artwork, active lyric line, and live audio spectrum waveform.
     - Expands smoothly on hover to show the surrounding verses and scrub bar.
  3. **Immersive Studio (Apple Music 3D Style)**:
     - Fullscreen cinematic mode with living, organic fluid mesh gradients reacting to track artwork.
     - Oversized typography with spring physics and depth-of-field focus on the active verse.
  4. **Menu Bar Status Item**:
     - Mini controller right in the macOS menu bar with quick transport, mode switching, and active verse indicator.

- **🎨 Themes & Typography**:
  - **Fonts**: SF Pro Rounded, SF Pro System, New York Serif, SF Mono.
  - **Color Palettes**: Dynamic Artwork Glow, Cyberpunk (Neon Magenta/Cyan), Aurora (Emerald/Teal), Sunset (Coral/Amber), Diamond White.

- **⚡ Zero Configuration Demo Mode**:
  - Built-in synchronized demo tracks (*Blinding Lights* by The Weeknd, *Bohemian Rhapsody* by Queen, *Viva La Vida* by Coldplay, *Hotel California* by Eagles) so you can test the visuals immediately without even opening a streaming player!

---

## 🛠️ Quick Start

### Build & Run
From the project directory:

```bash
# Build the native macOS bundle
make build

# Launch Drift
make run
```

Or run the build script directly:
```bash
./scripts/build_app.sh
open Drift.app
```

### Run Unit Tests
```bash
make test
```

---

## 🏗️ Architecture

```
drift/
├── Drift.app/                     # Packaged native macOS App Bundle
├── Package.swift                  # Swift Package Manager definition
├── Makefile                       # Build, run, test targets
├── scripts/
│   ├── build_app.sh               # App bundle packager & compiler
│   └── GenerateIcon.swift         # CoreGraphics 1024x1024 icon renderer
├── Resources/
│   └── AppIcon.icns               # High-res macOS squircle icon
├── Sources/
│   ├── main.swift                 # AppKit NSApplication entry & lifecycle
│   ├── App/
│   │   └── WindowManager.swift    # Multi-window & status bar controller
│   ├── Models/
│   │   ├── Track.swift            # Song metadata & playback state
│   │   ├── LyricLine.swift        # Timestamped verse line & progress
│   │   ├── DriftTheme.swift       # Color themes, fonts & display modes
│   │   └── AppState.swift         # Global reactive state & audio visualizer
│   ├── Services/
│   │   ├── LRCParser.swift        # Precise millisecond LRC & section parser
│   │   ├── LyricsService.swift    # LRCLIB client, disk cache & demo database
│   │   └── MusicDetector.swift    # Spotify & Apple Music AppleScript bridge
│   └── Views/
│       ├── FloatingLyricsView.swift    # Glass desktop HUD overlay
│       ├── NotchIslandView.swift       # Dynamic island capsule for MacBook notch
│       ├── ImmersiveStudioView.swift   # Fullscreen animated fluid gradient mode
│       ├── LyricRowView.swift          # Verse row with karaoke sweep glow
│       ├── AudioVisualizerView.swift   # Real-time rhythmic audio spectrum
│       └── SettingsView.swift          # Complete preferences & song search pane
└── Tests/
    └── main.swift                 # Automated unit tests
```

---

## 📄 License
MIT License. Built for macOS.
