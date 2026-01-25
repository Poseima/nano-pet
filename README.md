<div align="center">
  <img src="docs/images/icon.png" width="128" height="128" alt="Nano Pet Icon">
  <h1>Nano Pet</h1>
  <p><strong>Desktop Shimeji for macOS</strong></p>
  <p>Adorable desktop companions that walk, climb, and interact with your windows</p>

  <p>
    <a href="../../releases/latest"><img src="https://img.shields.io/github/v/release/Poseima/nano-pet?style=flat-square&color=blue" alt="Release"></a>
    <a href="../../releases"><img src="https://img.shields.io/github/downloads/Poseima/nano-pet/total?style=flat-square&color=green" alt="Downloads"></a>
    <img src="https://img.shields.io/badge/platform-macOS-lightgrey?style=flat-square" alt="Platform">
  </p>

  <p>
    <a href="README_CN.md">中文</a> | English
  </p>

  <!-- Character GIF Showcase -->
  <p>
    <img src="docs/images/hutao.gif" width="64" alt="Hu Tao">
    <img src="docs/images/klee.gif" width="64" alt="Klee">
    <img src="docs/images/venti.gif" width="64" alt="Venti">
    <img src="docs/images/kazuha.gif" width="64" alt="Kazuha">
    <img src="docs/images/xiao.gif" width="64" alt="Xiao">
    <img src="docs/images/jimin.gif" width="64" alt="Jimin">
    <img src="docs/images/taehyung.gif" width="64" alt="V">
    <img src="docs/images/jungkook.gif" width="64" alt="Jungkook">
    <img src="docs/images/suga.gif" width="64" alt="Suga">
    <img src="docs/images/demo.gif" width="64" alt="Squirtle">
  </p>
</div>

---

## Showcase

<div align="center">
  <img src="docs/images/long_queue_desktop_show.png" width="100%" alt="Pets lined up on dock">
  <p><em>A parade of pets walking along your dock!</em></p>
</div>

<div align="center">
  <img src="docs/images/desktop_random_mode.png" width="100%" alt="Random mode with pets everywhere">
  <p><em>Random mode: pets roam freely across your entire desktop</em></p>
</div>

---

## The Nest

<table>
  <tr>
    <td align="center" width="60%">
      <img src="docs/images/app_main_page.png" alt="Main Interface">
      <br><em>Character picker with category sidebar</em>
    </td>
    <td align="center" width="40%">
      <img src="docs/images/settings_english.png" width="200" alt="Quick Menu">
      <br><em>Quick menu</em>
    </td>
  </tr>
</table>

---

## Features

### Core Features
- **Desktop Pets** — Cute animated characters that roam freely on your desktop
- **Window Interaction** — Pets walk on window title bars, climb edges, and jump between windows
- **Physics Engine** — Realistic gravity, collision detection, and smooth animations
- **60+ Characters** — Pokemon, Genshin Impact, BTS, Mario, anime characters and more (20,000+ animation frames)

### Behavior Modes
- **Random Mode** — Pets wander everywhere, climb windows, and perform random actions
- **Focus Mode** — Pets stay at the bottom of screen or on the dock, less distracting for work

### Automation
- **Auto Clone** — Automatically spawn new pets at set intervals
- **Random Replace** — Periodically swap pet characters for variety
- **Adjustable Speed** — Control how often pets perform actions (Slow/Medium/Fast)

### Smart Features
- **Fullscreen Detection** — Automatically hides pets when you enter fullscreen apps
- **Window Awareness** — Pets can detect and interact with application windows
- **Multi-display Support** — Works across all your monitors

### Customization
- **Import Custom Characters** — Add your own Shimeji sprite packs
- **Favorites & Recent** — Quick access to your favorite characters
- **Category Organization** — Browse characters by series (Pokemon, Genshin, etc.)

### Localization
- **Bilingual Support** — Full English and Chinese interface
- **In-app Language Switch** — Change language without restarting

---


## Installation

### Download

1. Download `Nano.Pet.dmg` from [Releases](../../releases)
2. Open the DMG and drag **Nano Pet** to your Applications folder
3. Launch from Applications

> **Note:** On first launch, you may need to right-click and select "Open" to bypass Gatekeeper.

### Build from Source

```bash
git clone https://github.com/user/nano-pet.git
cd nano-pet
open "Nano Pet.xcodeproj"
```

Build and run with Xcode 15+ on macOS 14+.

---

## Usage

### Getting Started
1. **Launch** — Click the menu bar icon to open the character picker
2. **Deploy** — Click any character to add it to your desktop (or drag to the drop zone)
3. **Manage** — View active pets in the "Desktop Pets" section at the bottom

### Menu Bar Controls
- **Left-click** — Open character picker window
- **Right-click** — Quick menu for common actions

### Quick Menu Options
| Option | Description |
|--------|-------------|
| Disable Jumping | Prevent pets from jumping |
| Hide Pets | Temporarily hide all pets |
| Hide on Fullscreen | Auto-hide when in fullscreen apps |
| Pets Go Home | Remove all pets from desktop |
| Random Birth | Spawn a random character |
| Auto Clone | Periodically duplicate pets |
| Random Replace | Periodically change pet characters |
| Behavior Mode | Switch between Random and Focus modes |
| Action Speed | Control animation frequency |

---

## Adding Custom Characters

Nano Pet supports standard Shimeji sprite packs:

1. Prepare a folder with sprite images named `shime1.png`, `shime2.png`, etc.
2. Open the app and go to Asset Manager
3. Drag the folder into the import area
4. Your character will appear in the character picker

### Sprite Requirements
- PNG format with transparency
- Recommended size: 128x128 pixels
- Standard Shimeji frame numbering (`shime1.png` through `shime46.png`)

---

## Tech Stack

- **SwiftUI** — Modern declarative UI framework
- **AppKit** — Native macOS window management
- **Core Graphics** — Efficient sprite rendering
- **Combine** — Reactive state management

---

## Disclaimer

The character sprites included in this repository are fan-made Shimeji assets collected from various sources. All characters belong to their respective copyright holders:

- Pokemon characters © Nintendo/Game Freak
- Genshin Impact characters © miHoYo/HoYoverse
- BTS fan art © respective artists
- Mario characters © Nintendo
- Anime characters © their respective studios

**This project is for educational and personal use only.**

---

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

**Note:** The MIT license applies to the application code only. Character sprites and assets have separate copyrights belonging to their respective owners.

---

<div align="center">
  <p>
    <img src="docs/images/hutao.gif" width="48">
    <img src="docs/images/klee.gif" width="48">
    <img src="docs/images/venti.gif" width="48">
    <img src="docs/images/jimin.gif" width="48">
    <img src="docs/images/demo.gif" width="48">
  </p>
  <p>Made with ❤️ for desktop pet lovers</p>
</div>
