# Mountainfall — Project Guide

## Architecture

Single-page browser game. Game logic in Prolog, UI in vanilla JS/CSS. No build step, no dependencies beyond the swipl-wasm CDN.

### Key files

- `index.html` — Self-contained browser game. Contains three blocks:
  - `<script type="text/prolog" id="siam-prolog">` — Adapted game logic from `plateau.pl` plus adapter predicates for JS queries
  - `<style>` — Dark-themed CSS with responsive grid layout
  - `<script>` — JS bridge (WASM init, Prolog queries, board rendering, click handlers)
- `plateau.pl` — Authoritative Prolog game logic (terminal version). Changes here should be reflected in the embedded Prolog in `index.html`.
- `ia.pl` — AI opponent (not yet integrated into browser version)

### How the JS-Prolog bridge works

Board state lives in Prolog via `dynamic etat_courant/1`. JS uses string-based queries to avoid term marshalling:

```javascript
queryOnce('etat_courant(P), coups_piece(P, 0, C).')  // get entry moves
queryOnce('etat_courant(P), appliquer_coup(P, (0,11,\'N\'), New), retract(etat_courant(P)), assertz(etat_courant(New)).')  // apply move
```

swipl-wasm returns Prolog tuples `(A,B)` as `{$t: "t", ",": [[A, B]]}`. Triples `(A,B,C)` are right-associated: `','(A, ','(B,C))`. The `tupleArgs(term)` helper extracts `term[","][0]` to get the args array.

### Adapter predicates (in index.html, not in plateau.pl)

- `init_jeu/0` — Initialize board state
- `etat_plateau/5` — Decompose board into E, R, M, J
- `liste_coups/2` — All valid moves (wraps setof with empty-list fallback)
- `coups_piece/3` — Moves filtered by departure cell
- `appliquer_coup/3` — Validate and apply a move
- `partie_finie/1` — Check if a mountain is off the board
- `gagnant/1` — Get the winner (uses `dynamic winner/1`)

## Conventions

- Prolog game logic is the single source of truth. JS never validates moves — it only renders and sends queries.
- Board cells are numbered `RC` where R=row (1-5), C=column (1-5). E.g., 11=bottom-left, 55=top-right.
- Moves are tuples `(Depart, Arrivee, Orientation)`. Depart=0 means entering from reserve. Arrivee=0 means withdrawing.
- `gain/2` in the embedded Prolog is replaced with a dynamic version that asserts `winner/1` instead of using `write/1`.

## Testing Prolog changes

Extract the Prolog from `index.html` and test locally:

```bash
swipl -l /tmp/siam_test.pl -g "init_jeu, etat_courant(P), etat_plateau(P, E, R, M, J), write(J), nl, halt."
```

For browser testing, serve via HTTP:

```bash
python3 -m http.server 8080
```
