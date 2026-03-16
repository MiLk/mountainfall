# SIAM — Elephants vs Rhinoceros

A browser-based implementation of the SIAM board game. Two players take turns placing and moving their animals on a 5x5 board, trying to push one of three mountains off the edge.

## Play

Open `index.html` in any modern browser. No server or build step required.

The game logic runs in [SWI-Prolog](https://www.swi-prolog.org/) compiled to WebAssembly via [swipl-wasm](https://github.com/nicknisi/swipl-wasm). The WASM engine (~10MB) loads from a CDN on first visit and is cached by the browser.

## Rules

- **5 elephants** vs **5 rhinoceros** on a 5x5 board with **3 mountains** in the center.
- On your turn, do one of: **enter** a piece from reserve, **move** one cell, **rotate** in place, or **withdraw** from an edge.
- Every piece has a facing direction. A piece can **push** a line of pieces/mountains in its facing direction if it has more force than resistance.
- **Win** by pushing a mountain off any edge of the board.

## How it works

The original game logic is written in Prolog (`plateau.pl`). The browser version embeds this logic in `index.html` inside a `<script type="text/prolog">` tag. SWI-Prolog WASM loads and executes it. JavaScript handles rendering (emoji pieces on a CSS grid) and user interaction, calling Prolog for move validation and board state updates.

### Files

| File | Description |
|------|-------------|
| `index.html` | Self-contained browser game (Prolog + JS + CSS) |
| `plateau.pl` | Original Prolog game logic (authoritative source) |
| `HH.pl` | Older version of the game logic |
| `ia.pl` | AI opponent (not yet wired into the browser version) |

## Development

Requires [SWI-Prolog](https://www.swi-prolog.org/) for local testing of Prolog changes:

```bash
brew install swi-prolog
swipl -l plateau.pl -g jouer   # Play in terminal
```

To test the browser version locally, serve via HTTP (WASM requires it):

```bash
python3 -m http.server 8080
open http://localhost:8080/index.html
```
