# Vermeer (1987) — Modern Open-Source Remake (LÖVE / Love2D)

An open-source (FOSS) reverse-engineering preservation project and modernized grand-strategy edition of the classic 1987 Commodore 64 economic & art-trading simulation **Vermeer** (originally created by Ralf Glau / Ariolasoft).

---

## About This Project

This repository combines **6502 reverse engineering** of the original C64 binaries (`vermeer-db.prg` and `vermeer-pic.prg`, disassembled with JC64dis) with a clean, modernized **LÖVE (Love2D 11.5)** grand-strategy interface inspired by modern historical strategy games (*Europa Universalis*):

- **Authentic C64 Economic & Simulation Rules:** All city travel matrices, currency exchange indices, plantation commodities, seasonal harvest windows, weather/pest risks, and the 64-painting 8-byte catalog schema (including the Byte 6 `$00`–`$FF` forgery quality mechanic) are implemented directly from the disassembled specifications in [`docs/architecture.md`](docs/architecture.md) and [`docs/assets.md`](docs/assets.md).
- **Modernized Grand-Strategy Interface:** Replaces cramped multi-screen menus with a full-screen North Atlantic & European cartographic map, heraldic city coats-of-arms (**London**, **Paris**, **Berlin**, **New York**), a single clean left-docked inspector drawer, and a real-time/turn-based imperial clock.
- **Public Domain & Creative Commons Artworks:** Uses Public Domain / Creative Commons Old Master paintings from Wikimedia Commons across the 8 catalog artists (*Johannes Vermeer*, *Rembrandt van Rijn*, *Peter Paul Rubens*, *Albrecht Dürer*, *Lucas Cranach*, *Frans Hals*, *Hieronymus Bosch*, and *Pieter Bruegel*).

---

## Installation & Running the Game

### 1. Install LÖVE (Love2D 11.5+)

- **macOS (Homebrew):**
  ```bash
  brew install --cask love
  ```
  *(Alternatively, download `love-11.5-macos.zip` from [love2d.org](https://love2d.org/) and drag `love.app` to `/Applications`.)*

- **Linux (Ubuntu / Debian / Fedora / Arch):**
  ```bash
  # Ubuntu / Debian
  sudo apt install love

  # Arch Linux
  sudo pacman -S love
  ```
  *(Or download the official LÖVE 11.5 AppImage from [love2d.org](https://love2d.org/).)*

- **Windows:**
  Download and install the LÖVE 11.5 64-bit installer from [love2d.org](https://love2d.org/).

### 2. Clone & Launch

```bash
git clone https://github.com/designcastle/Vermeer-remake.git
cd Vermeer-remake
love .
```

*(On macOS without a CLI `love` symlink, you can run `/Applications/love.app/Contents/MacOS/love .`)*

---

## Controls & Keyboard Shortcuts

| Key / Action | Function |
|---|---|
| **`1`** | **World Map & City Inspector** (Travel between London, Paris, Berlin & New York) |
| **`2`** | **Colonial Estates, Commodity Market & Bank** (Left-docked tabbed drawer) |
| **`3`** | **Auction Salon** (Live Old Master paddle bidding & expert forgery appraisal) |
| **`4`** | **Art Collection & Treasury** (Framed masterpiece gallery grid & museum loans) |
| **`Space`** | Step forward **+5 Days** (or place a **+1x Bid** inside the Auction Salon) |
| **`B` / `E` / `P`** | **Jump Bid (+2x)** / **Expert Appraisal** / **Pass Lot** (in Auction Salon) |
| **`H` or `?`** | Open searchable **Encyclopedia & C64 Reference Tables** |
| **`F5` / `F9`** | **Quick Save** / **Quick Load** campaign |
| **`Esc`** | Close modal or return to Title Screen |

---

## Project Structure

```text
├── main.lua                 # LÖVE 11.5 entry point, fixed-timestep loop & scene router
├── conf.lua                 # Window setup (1280x720, resizable, high-DPI)
├── data/
│   ├── cities.lua           # London, Paris, Berlin & New York travel/currency tables
│   ├── commodities.lua      # Tea, Coffee, Tobacco & Cocoa plantation yield/risk tables
│   ├── artworks.lua         # 64-painting 8-byte catalog & Byte 6 forgery flags
│   ├── events.lua           # Colonial weather/pest telegrams & market modifiers
│   └── tutorials.lua        # Contextual micro-tutorials & rulebook encyclopedia
├── sim/
│   ├── game_state.lua       # Deterministic RNG, player/rival state & save/load serializer
│   ├── economy.lua          # Monthly harvests, loans, upkeep & Byte 6 expert inspection
│   ├── auction.lua          # Live paddle bidding state machine & gavel countdown
│   └── ai_rivals.lua        # Gerd, Kurt & Baron von Stahl AI decision logic
├── ui/
│   ├── theme.lua            # Grand-strategy palette, typography & asset loader
│   ├── widgets.lua          # Brass-trimmed panels, framed paintings, shields & sparklines
│   ├── hud.lua              # Top imperial ribbon, resource pills & real-time/step clock
│   └── tutorial_overlay.lua # Contextual callout cards & searchable rulebook modal
├── scenes/
│   ├── title.lua            # Campaign configuration & title showcase
│   ├── world_map.lua        # Interactive North Atlantic/Europe map & city inspector dock
│   ├── city_hub.lua         # Tabbed left drawer (Estates, Market, Bank) over live map
│   ├── auction_room.lua     # Focused live bidding salon & rival portraits
│   ├── portfolio.lua        # Framed masterpiece gallery grid & house standings
│   └── end_screen.lua       # Final testament verdict & score breakdown
├── assets/                  # Public Domain/CC paintings, heraldic shields, fonts & SFX
└── docs/
    ├── architecture.md      # C64 6502 disassembly & hardware specification
    ├── assets.md            # Extracted C64 memory offsets & economic master tables
    └── implementation_notes.md # Fidelity matrix & ByteKiller payload notes
```

---

## Automated Verification

To run the built-in headless verification suite (validating all 64 artworks, 4 cities, 4 commodities, economy turns, save/load, and UI rendering paths):

```bash
love . --headless
```

---

## License & Attribution

- **Source Code:** Released as Free and Open Source Software (MIT License).
- **Artworks:** Old Master paintings by Vermeer, Rembrandt, Rubens, Dürer, Cranach, Hals, Bosch, and Bruegel are in the **Public Domain (CC0)** via Wikimedia Commons.
- **Historical Notice:** This is an independent clean-room reverse-engineering and preservation project created for educational and historical purposes.
