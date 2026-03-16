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

## Source Prolog File

**`plateau.pl`** is the authoritative source. `HH.pl` is an older version with different `caseSuiv/3` and `coup_possible/2` behavior. `ia.pl` is out of scope (AI deferred).

The `coup_possible/2` catch-all clause with `write` side-effects (present in `HH.pl` but not `plateau.pl`) must not be included. `plateau.pl` does not have this issue.

## Prolog Adapter Layer

The existing game logic predicates from `plateau.pl` are kept unchanged: `coup_possible/2`, `majPlateau/3`, `coups_possibles/2`, `isElephant/2`, `isRhinoceros/2`, `isMontagne/2`, `borneCase/2`, `caseSuiv/3`, `poussee_possible/2`, `bouger/6`, `orienter/3`, etc.

I/O predicates are stripped: `affiche_*`, `jouer_coup`, `jouer`, `mauvaisCoup`, `testTest`, `testDepart`.

Adapter predicates added for JS queries:

```prolog
:- use_module(library(apply)).  % for include/3
% Extract board components for rendering.
% E and R are lists of (Case, Dir) tuples. M is a list of case numbers.
% J is 'E' or 'R' (current player).
etat_plateau([E, R, M, J], E, R, M, J).

% All valid moves as a list of (Depart, Arrivee, O) tuples.
% Returns [] if no moves exist (wraps setof to avoid failure).
liste_coups(Plateau, Coups) :-
    (setof(C, coup_possible(Plateau, C), Coups) -> true ; Coups = []).

% Moves filtered by departure cell. For entry moves, Depart = 0.
coups_piece(Plateau, Depart, Coups) :-
    liste_coups(Plateau, Tous),
    include(coup_depart(Depart), Tous, Coups).
coup_depart(D, (D, _, _)).

% Apply a move, return new board state.
appliquer_coup(Plateau, Coup, NouveauPlateau) :-
    coup_possible(Plateau, Coup),
    majPlateau(Plateau, Coup, NouveauPlateau).

% Check if game is over (a mountain at position 0 = pushed off board).
partie_finie([_, _, M, _]) :- member(0, M).

% Count reserve pieces (position 0 = not on board).
reserve_count([E, _, _, _], 'E', N) :-
    include(is_reserve, E, Res), length(Res, N).
reserve_count([_, R, _, _], 'R', N) :-
    include(is_reserve, R, Res), length(Res, N).
is_reserve((0, _)).

% Determine the winner after game ends.
% The winner is tracked by bouger/6 via the gain/2 predicate.
% We replace gain/2 with a version that asserts the winner.
% After appliquer_coup, check:
gagnant(Joueur) :- winner(Joueur).
```

### Winner Detection Strategy

The existing `gain/2` predicate is called inside `bouger` when a mountain is pushed off the board. It receives the player who initiated the push chain (`B` parameter). Replace `gain/2` with:

```prolog
:- dynamic winner/1.
gain(0, J) :- retractall(winner(_)), assertz(winner(J)).
gain(_, _).
```

After each `appliquer_coup`, JS checks `gagnant(J)` to get the winner. If `partie_finie` is true but `gagnant` has no value, it means the mountain fell off without a push (shouldn't happen in normal play).

## JS↔Prolog Term Marshalling

This is the critical bridge concern. Prolog tuples `(A, B)` are compound terms with functor `','`.

### JS → Prolog (building moves)

To build a move `(Depart, Arrivee, O)` in JS:
```javascript
// Using swipl-wasm term construction
const move = prolog.compound(",",
    prolog.compound(",", depart, arrivee),
    orientation);
```

Or use string-based queries — simpler and sufficient for our use case:
```javascript
const query = `appliquer_coup(${boardVar}, (${depart},${arrivee},'${dir}'), New).`;
```

**Recommended approach: string-based queries.** Board state is stored as a Prolog-side asserted fact, not passed through JS. This avoids all marshalling complexity.

### Stateful Bridge (Recommended)

Instead of passing board state through JS, keep it in Prolog:

```prolog
:- dynamic etat_courant/1.
init_jeu :- plateauDepart(P), retractall(etat_courant(_)), assertz(etat_courant(P)).
```

JS queries become simple strings:
- `init_jeu.` — start game
- `etat_courant(P), etat_plateau(P, E, R, M, J).` — get state for rendering
- `etat_courant(P), coups_piece(P, 0, C).` — get entry moves
- `etat_courant(P), coups_piece(P, 32, C).` — get moves for piece on cell 32
- `etat_courant(P), appliquer_coup(P, (32,33,'N'), New), retract(etat_courant(P)), assertz(etat_courant(New)).` — apply move

### Prolog → JS (reading state for rendering)

Query `etat_courant(P), etat_plateau(P, E, R, M, J)` and read bindings:
- `E` = list of `(Case, Dir)` — JS iterates to place 🐘 on each Case with Dir arrow
- `R` = list of `(Case, Dir)` — JS iterates to place 🦏
- `M` = list of integers — JS iterates to place ⛰️
- `J` = atom `'E'` or `'R'` — turn indicator

Pieces with `Case = 0` are in reserve (not rendered on board). Count them for reserve display.

### Reading move lists

Query `etat_courant(P), coups_piece(P, Depart, C)` — returns a list of `(D, A, O)` tuples. JS extracts `A` (destination) and `O` (direction) from each to:
1. Highlight destination cells (unique `A` values)
2. Show valid directions per destination (group by `A`, collect `O` values)

## UI Layout

- **Turn indicator**: Banner at top showing current player (🐘 Elephant / 🦏 Rhinoceros)
- **Reserve areas**: Elephant reserve on the left, Rhino reserve on the right. Count from `reserve_count/3`. Clickable — clicking selects Depart=0.
- **Board**: 5x5 CSS grid. Dark theme. Cells numbered 11-55 (row × 10 + column).
- **Action hint**: Text below board describing what to do next.

### Piece Rendering

- Elephants: 🐘 emoji with small triangle arrow (▲▼◀▶) indicating facing direction
- Rhinoceros: 🦏 emoji with small triangle arrow indicating facing direction
- Mountains: ⛰️ emoji, no direction
- Valid move highlights: Green border on eligible destination cells

## Interaction Flow

### Turn Sequence

1. **Click piece or reserve** — selected piece highlighted, JS queries `coups_piece(P, Depart, C)` to get valid moves for that piece, highlights destination cells.
2. **Click destination** — JS filters move list to those matching this destination, extracts valid directions. If only one direction, auto-apply. Otherwise show direction picker overlay.
3. **Pick direction** — JS builds string query `appliquer_coup(P, (D,A,'O'), New)`, Prolog validates and returns new state. JS updates `etat_courant` and re-renders.
4. **Win check** — JS queries `partie_finie(P)`. If true, queries `gagnant(J)` and shows victory overlay naming the winner.

### Move Types

- **Enter**: Click a reserve piece (sets Depart=0), edge cells highlighted, pick direction (all directions valid for empty cells; only inward-facing for occupied cells requiring a push).
- **Move**: Click a board piece, adjacent highlighted cells shown, pick direction.
- **Rotate**: Click a board piece, its own cell is highlighted (if rotation is a valid move — i.e. at least one different orientation is possible). Direction picker shows with current direction grayed out.
- **Withdraw**: Click a board piece on an edge. A special "withdraw" target appears outside the board edge (X icon). Clicking it sends `(Depart, 0, 'N')` — direction is arbitrary for withdraw since `coup_possible` accepts any direction for `(Depart, 0, _)`.

### Direction Picker

- 4 arrow buttons overlaid on/around the destination cell
- Only valid directions shown (from the filtered move list for that destination)
- Current direction grayed out for rotation moves
- Single valid direction auto-applied (no extra click)

## JS↔Prolog Bridge

### Initialization

1. Load `swipl-wasm` from CDN (`https://SWI-Prolog.github.io/npm-swipl-wasm/latest/index.js`)
2. Feed adapted Prolog source via `prolog.load_string()`
3. Call `init_jeu.` to initialize board state
4. Query state and render initial board

### Per-Turn Cycle

1. Player clicks a piece → JS queries `coups_piece(P, Depart, C)` → highlights valid destinations
2. Player clicks destination → JS shows valid directions from filtered list → player picks direction
3. JS runs `appliquer_coup` query → updates `etat_courant` → re-renders board
4. Win check → `partie_finie` + `gagnant` → victory overlay if true

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
