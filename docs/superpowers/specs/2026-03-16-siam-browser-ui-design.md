# SIAM Browser UI — Design Spec

## Overview

Browser-based UI for the SIAM board game, keeping the existing Prolog game logic as the single source of truth via SWI-Prolog compiled to WebAssembly.

## Goals

- Playable in any modern browser, no server required
- Prolog validates all moves and manages board state — JS only renders and handles clicks
- Human vs Human mode only (AI deferred)
- Mobile-friendly via responsive CSS

## File Structure

Single self-contained `index.html` file containing:
- SWI-Prolog WASM loader (from CDN)
- Adapted Prolog game logic (embedded `<script type="text/prolog">`)
- All CSS and JS inline

No build step. Open `index.html` in a browser to play.

## Prolog Adapter Layer

The existing game logic predicates are kept unchanged: `coup_possible/2`, `majPlateau/3`, `coups_possibles/2`, `isElephant/2`, `isRhinoceros/2`, `isMontagne/2`, `borneCase/2`, `caseSuiv/3`, `poussee_possible/2`, etc.

I/O predicates are stripped: `affiche_*`, `jouer_coup`, `jouer`, `mauvaisCoup`.

Thin adapter predicates are added for JS queries:

```prolog
etat_plateau(Plateau, E, R, M, J) :-
    Plateau = [E, R, M, J].

liste_coups(Plateau, Coups) :-
    coups_possibles(Plateau, Coups).

appliquer_coup(Plateau, Coup, NouveauPlateau) :-
    coup_possible(Plateau, Coup),
    majPlateau(Plateau, Coup, NouveauPlateau).

partie_finie(Plateau) :-
    Plateau = [_, _, M, _], element(0, M).
```

## UI Layout

- **Turn indicator**: Banner at top showing current player (🐘 Elephant / 🦏 Rhinoceros)
- **Reserve areas**: Elephant reserve on the left, Rhino reserve on the right. Shows clickable pieces not yet on the board.
- **Board**: 5x5 CSS grid. Dark theme. Cells numbered 11-55 (row × 10 + column).
- **Action hint**: Text below board describing what to do next.

### Piece Rendering

- Elephants: 🐘 emoji with small triangle arrow (▲▼◀▶) indicating facing direction
- Rhinoceros: 🦏 emoji with small triangle arrow indicating facing direction
- Mountains: ⛰️ emoji, no direction
- Valid move highlights: Green border on eligible destination cells

## Interaction Flow

### Turn Sequence

1. **Click piece or reserve** — selected piece is highlighted, all valid destinations for that piece are shown with green borders
2. **Click destination** — direction picker overlay appears on the cell showing only valid direction arrows (↑↓←→)
3. **Pick direction** — if only one valid direction, auto-applied. JS builds move tuple `(Depart, Arrivee, O)`.
4. **Prolog validates and updates** — `appliquer_coup/3` returns new board state, JS re-renders.
5. **Win check** — `partie_finie/1` called after each move. If true, victory overlay shown.

### Move Types

- **Enter**: Click a reserve piece, then click an edge cell, pick inward-facing direction.
- **Move**: Click a board piece, click an adjacent highlighted cell, pick direction.
- **Rotate**: Click a board piece, click its own cell (highlighted). Direction picker shows with current direction grayed out.
- **Withdraw**: Click a board piece on an edge, an X icon outside the board edge is shown as a withdraw option.

### Direction Picker

- 4 arrow buttons overlaid on/around the destination cell
- Only valid directions shown (filtered via `coup_possible/2`)
- Current direction grayed out for rotation moves
- Single valid direction auto-applied (no extra click)

## JS↔Prolog Bridge

### Initialization

1. Load `swipl-wasm` from CDN (`https://SWI-Prolog.github.io/npm-swipl-wasm/latest/index.js`)
2. Feed adapted Prolog source via `prolog.load_string()`
3. Query `plateauDepart(P)` to get initial board state
4. Render initial board

### Per-Turn Cycle

1. Player clicks a piece → JS calls `coups_possibles(Plateau, Coups)` → filters to moves from that piece → highlights valid destinations
2. Player clicks destination + direction → JS builds `(Depart, Arrivee, O)` → calls `appliquer_coup(Plateau, Coup, NouveauPlateau)` → receives new state → re-renders
3. Win check → `partie_finie(Plateau)` → victory overlay if true

### Data Flow

Board state is an opaque Prolog term held in JS. JS passes it back to Prolog on each query. JS only interprets the elephant/rhino/mountain lists for rendering (placing emojis on correct cells with correct direction arrows).

### Error Handling

Since only valid moves are shown, `appliquer_coup` should not fail. If it does, show "invalid move" message and let player retry.

## Visual Style

- Dark theme (#1a1a2e background, #16213e cells, #0f3460 board border)
- Emoji pieces: 🐘, 🦏, ⛰️
- Direction arrows: small ▲▼◀▶ triangles positioned on cell edges
- Valid moves: #4ecca3 (green) cell border
- Elephant player color: #e94560 (red)
- Rhino player color: #533483 (purple)
- Responsive: CSS grid scales down for mobile, touch targets at least 44px

## Out of Scope

- AI opponent (deferred — `ia.pl` not loaded)
- Sound effects
- Move history / undo
- Online multiplayer
