# SIAM Browser UI Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a browser-based SIAM board game UI using SWI-Prolog WASM for game logic.

**Architecture:** Single `index.html` file. Prolog game logic from `plateau.pl` runs in SWI-Prolog WASM. JS handles rendering (emoji pieces on a CSS grid) and user interaction (click-to-select with highlighted valid moves). Board state lives in Prolog via `dynamic etat_courant/1`; JS uses string-based queries to avoid term marshalling.

**Tech Stack:** SWI-Prolog WASM (CDN), vanilla JS, CSS Grid

**Spec:** `docs/superpowers/specs/2026-03-16-siam-browser-ui-design.md`

---

## File Structure

- **Create:** `index.html` — single self-contained file with all CSS, JS, and embedded Prolog
  - `<style>` block: dark theme, 5x5 grid, responsive layout, direction picker, victory overlay
  - `<script type="text/prolog" id="siam-prolog">`: adapted game logic from `plateau.pl` + adapter predicates
  - `<script type="module">`: JS bridge (init WASM, query helpers, render loop, click handlers)
  - HTML: board grid, reserve areas, turn indicator, action hint, direction picker overlay, victory overlay

No other files created. `plateau.pl`, `HH.pl`, `ia.pl` left untouched.

---

## Chunk 1: Prolog Adapter and WASM Bootstrap

### Task 1: Create adapted Prolog source embedded in index.html

**Files:**
- Create: `index.html`

This task creates the HTML skeleton with the embedded Prolog code. The Prolog source is `plateau.pl` with I/O predicates stripped and adapter predicates added.

- [ ] **Step 1: Create index.html with HTML skeleton and embedded Prolog**

Create `index.html` with:
1. Basic HTML structure with `<meta charset="utf-8">` and viewport meta for mobile
2. A `<script type="text/prolog" id="siam-prolog">` block containing:
   - All game logic from `plateau.pl` lines 1-10 (get, element, sed)
   - `plateauDepart/1` (line 12)
   - Lines 60-220 (all game logic: isElephant through majPlateau) **except**:
     - Replace `gain/2` (lines 151-153) with the dynamic winner version
     - Remove `affiche_*` predicates (lines 16-58)
     - Remove `jouer_coup`, `jouer`, `mauvaisCoup`, `testTest`, `testDepart` (lines 222-243)
   - Add adapter predicates from spec: `etat_plateau/5`, `liste_coups/2`, `coups_piece/3`, `coup_depart/2`, `appliquer_coup/3`, `partie_finie/1`, `reserve_count/3`, `is_reserve/1`, `gagnant/1`, `init_jeu/0`, `etat_courant/1`
   - Add `:- use_module(library(apply)).` at top
   - Add `:- dynamic winner/1, etat_courant/1.`
3. An empty `<style>` block (filled in Task 3)
4. An empty `<div id="app">` (filled in Task 3)
5. An empty `<script type="module">` block (filled in Task 2)

- [ ] **Step 2: Verify Prolog loads in SWI-Prolog locally**

Extract just the Prolog content from the script tag into a temp file and test:

```bash
swipl -l /tmp/siam_test.pl -g "init_jeu, etat_courant(P), etat_plateau(P, E, R, M, J), write(J), nl, halt."
```

Expected output: `E` (elephant goes first)

- [ ] **Step 3: Test coups_piece returns moves**

```bash
swipl -l /tmp/siam_test.pl -g "init_jeu, etat_courant(P), coups_piece(P, 0, C), length(C, N), write(N), nl, halt."
```

Expected: a number > 0 (entry moves available)

- [ ] **Step 4: Test appliquer_coup works**

```bash
swipl -l /tmp/siam_test.pl -g "init_jeu, etat_courant(P), appliquer_coup(P, (0,11,'N'), New), retract(etat_courant(P)), assertz(etat_courant(New)), etat_courant(Q), etat_plateau(Q,_,_,_,J), write(J), nl, halt."
```

Expected: `R` (turn switches to rhinoceros after elephant enters)

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "feat: create index.html with embedded Prolog game logic and adapter"
```

---

### Task 2: JS↔Prolog WASM bridge

**Files:**
- Modify: `index.html` (the `<script type="module">` block)

- [ ] **Step 1: Write the WASM initialization code**

In the `<script type="module">` block, add:

```javascript
import SWIPL from 'https://SWI-Prolog.github.io/npm-swipl-wasm/latest/index.js';

let prolog;

async function initProlog() {
  const swipl = await SWIPL({ arguments: ['-q'] });
  prolog = swipl.prolog;

  const prologSource = document.getElementById('siam-prolog').textContent;
  await prolog.load_string(prologSource, 'siam');
  prolog.call('init_jeu');
}
```

- [ ] **Step 2: Write query helper functions**

```javascript
// Helper: run a query, return first result bindings or null
function queryOnce(queryStr) {
  const q = prolog.query(queryStr);
  const result = q.once();
  q.close();
  // swipl-wasm .once() returns {success: false} on failure, not falsy
  if (!result || result.success === false) return null;
  return result;
}

function getState() {
  return queryOnce('etat_courant(P), etat_plateau(P, E, R, M, J).');
}

function getMovesForPiece(depart) {
  const result = queryOnce(
    `etat_courant(P), coups_piece(P, ${depart}, C).`
  );
  return result ? result.C : [];
}

function applyMove(depart, arrivee, dir) {
  return !!queryOnce(
    `etat_courant(P), appliquer_coup(P, (${depart},${arrivee},'${dir}'), New), retract(etat_courant(P)), assertz(etat_courant(New)).`
  );
}

function isGameOver() {
  return !!queryOnce('etat_courant(P), partie_finie(P).');
}

function getWinner() {
  const result = queryOnce('gagnant(J).');
  return result ? String(result.J) : null;
}
```

- [ ] **Step 3: Write Prolog term → JS conversion helpers**

The swipl-wasm returns Prolog lists as JS arrays. Tuples `(A,B)` are compound terms with functor `','`, returned as `{$: "t", ",": [A, B]}`. A triple `(A,B,C)` is nested: `{$: "t", ",": [{$: "t", ",": [A, B]}, C]}`.

Write helpers to parse them:

```javascript
// Extract args from a Prolog tuple (compound with ',' functor)
function tupleArgs(term) {
  return term[','];
}

function parsePieceList(prologList) {
  const pieces = [];
  if (!prologList) return pieces;
  for (const item of prologList) {
    const args = tupleArgs(item);  // [caseNum, dir]
    const caseNum = args[0];
    const dir = args[1];
    if (caseNum !== 0) {
      pieces.push({ cell: caseNum, dir: String(dir) });
    }
  }
  return pieces;
}

function parseMountainList(prologList) {
  if (!prologList) return [];
  return prologList.filter(m => m !== 0);
}

function parseMoveList(prologList) {
  const moves = [];
  if (!prologList) return moves;
  for (const item of prologList) {
    const outer = tupleArgs(item);    // [','(D, A), O]
    const inner = tupleArgs(outer[0]); // [D, A]
    const depart = inner[0];
    const arrivee = inner[1];
    const dir = outer[1];
    moves.push({ depart, arrivee, dir: String(dir) });
  }
  return moves;
}

function countReserve(pieceList) {
  let count = 0;
  if (!pieceList) return count;
  for (const item of pieceList) {
    if (tupleArgs(item)[0] === 0) count++;
  }
  return count;
}
```

**Important:** The exact shape of swipl-wasm compound terms should be verified in Task 2 Step 4 by inspecting `console.log(JSON.stringify(state.E[0]))`. If the shape differs from `{$: "t", ",": [...]}`, adapt the `tupleArgs` helper accordingly. This is the one function to fix if the API returns a different format.

- [ ] **Step 4: Test in browser — verify Prolog loads**

Add a temporary init call and console log:

```javascript
initProlog().then(() => {
  const state = getState();
  console.log('Current player:', String(state.J));
  console.log('Elephants:', state.E);
  console.log('Mountains:', state.M);
});
```

Open `index.html` in a browser. Check console for output. The CDN fetch may take a few seconds on first load.

Expected: `Current player: E`, elephant list with 5 `(0,0)` entries, mountains `[32,33,34]`.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "feat: add JS-Prolog WASM bridge with query helpers"
```

---

## Chunk 2: Board Rendering and CSS

### Task 3: HTML structure and CSS styling

**Files:**
- Modify: `index.html` (`<style>` block and `<div id="app">`)

- [ ] **Step 1: Write the HTML structure inside `<div id="app">`**

```html
<div id="app">
  <div id="turn-indicator"></div>
  <div id="game-area">
    <div id="reserve-left" class="reserve"></div>
    <div id="board"></div>
    <div id="reserve-right" class="reserve"></div>
  </div>
  <div id="action-hint">Loading Prolog engine...</div>
  <div id="direction-picker" class="hidden">
    <button data-dir="N" class="dir-btn">▲</button>
    <button data-dir="W" class="dir-btn">◀</button>
    <button data-dir="E" class="dir-btn">▶</button>
    <button data-dir="S" class="dir-btn">▼</button>
  </div>
  <div id="victory-overlay" class="hidden">
    <div id="victory-message"></div>
    <button id="restart-btn">New Game</button>
  </div>
</div>
```

- [ ] **Step 2: Write the CSS**

```css
* { margin: 0; padding: 0; box-sizing: border-box; }
body {
  background: #1a1a2e;
  color: #eee;
  font-family: system-ui, sans-serif;
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
}
#app { text-align: center; padding: 1rem; }
#turn-indicator {
  font-size: 1.3rem;
  font-weight: bold;
  padding: 0.5rem 1.5rem;
  border-radius: 20px;
  display: inline-block;
  margin-bottom: 1rem;
}
#turn-indicator.elephant { background: #e94560; }
#turn-indicator.rhino { background: #533483; }
#game-area {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.8rem;
}
.reserve {
  display: flex;
  flex-direction: column;
  gap: 0.4rem;
  align-items: center;
}
.reserve-label {
  font-size: 0.7rem;
  color: #aaa;
  text-transform: uppercase;
  margin-bottom: 0.2rem;
}
.reserve-piece {
  width: 44px;
  height: 44px;
  background: #16213e;
  border: 2px solid #333;
  border-radius: 6px;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1.4rem;
  cursor: pointer;
  transition: border-color 0.15s;
}
.reserve-piece:hover { border-color: #4ecca3; }
.reserve-piece.selected { border-color: #4ecca3; box-shadow: 0 0 8px #4ecca355; }
.reserve-piece.elephant { border-color: #e94560; }
.reserve-piece.rhino { border-color: #533483; }
#board {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  grid-template-rows: repeat(5, 1fr);
  gap: 2px;
  background: #0f3460;
  padding: 4px;
  border-radius: 8px;
  width: min(70vw, 350px);
  height: min(70vw, 350px);
}
.cell {
  background: #16213e;
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  cursor: pointer;
  font-size: clamp(1.2rem, 4vw, 1.8rem);
  min-width: 0;
  min-height: 0;
  transition: border-color 0.15s;
  border: 2px solid transparent;
}
.cell:hover { border-color: #ffffff33; }
.cell.highlighted { border-color: #4ecca3; box-shadow: inset 0 0 6px #4ecca333; }
.cell.selected { border-color: #fff; box-shadow: 0 0 8px #ffffff55; }
.cell.withdraw-target {
  border-color: #e94560;
  background: #1a1a2e;
}
.dir-arrow {
  position: absolute;
  font-size: 0.55em;
  color: #aaa;
  line-height: 1;
}
.dir-arrow.N { top: 1px; left: 50%; transform: translateX(-50%); }
.dir-arrow.S { bottom: 1px; left: 50%; transform: translateX(-50%); }
.dir-arrow.W { left: 2px; top: 50%; transform: translateY(-50%); }
.dir-arrow.E { right: 2px; top: 50%; transform: translateY(-50%); }
.cell-label {
  position: absolute;
  font-size: 0.45em;
  color: #333;
  bottom: 1px;
  right: 3px;
}
#action-hint {
  margin-top: 1rem;
  color: #aaa;
  font-size: 0.9rem;
  min-height: 1.5em;
}
#direction-picker {
  position: fixed;
  display: grid;
  grid-template-areas: ". n ." "w . e" ". s .";
  grid-template-columns: 44px 44px 44px;
  grid-template-rows: 44px 44px 44px;
  gap: 4px;
  z-index: 100;
}
#direction-picker.hidden { display: none; }
.dir-btn {
  background: #0f3460;
  color: #eee;
  border: 2px solid #4ecca3;
  border-radius: 8px;
  font-size: 1.2rem;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
}
.dir-btn:hover { background: #4ecca3; color: #1a1a2e; }
.dir-btn.disabled {
  opacity: 0.2;
  pointer-events: none;
  border-color: #333;
}
.dir-btn[data-dir="N"] { grid-area: n; }
.dir-btn[data-dir="S"] { grid-area: s; }
.dir-btn[data-dir="W"] { grid-area: w; }
.dir-btn[data-dir="E"] { grid-area: e; }
#victory-overlay {
  position: fixed;
  inset: 0;
  background: #000000cc;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  z-index: 200;
}
#victory-overlay.hidden { display: none; }
#victory-message { font-size: 2rem; font-weight: bold; margin-bottom: 1rem; }
#restart-btn {
  padding: 0.8rem 2rem;
  font-size: 1.1rem;
  background: #4ecca3;
  color: #1a1a2e;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: bold;
}
#restart-btn:hover { background: #3dbb94; }

@media (max-width: 480px) {
  #game-area { gap: 0.4rem; }
  .reserve-piece { width: 36px; height: 36px; font-size: 1.1rem; }
  #board { width: 75vw; height: 75vw; }
}
```

- [ ] **Step 3: Commit**

```bash
git add index.html
git commit -m "feat: add HTML structure and CSS dark theme for board"
```

---

### Task 4: Board rendering from Prolog state

**Files:**
- Modify: `index.html` (JS module block)

- [ ] **Step 1: Write the render function**

```javascript
const ROWS = [5, 4, 3, 2, 1];
const COLS = [1, 2, 3, 4, 5];
const DIR_ARROWS = { N: '▲', S: '▼', W: '◀', E: '▶' };

function renderBoard() {
  const state = getState();
  if (!state) return;

  const player = String(state.J);
  const elephants = parsePieceList(state.E);
  const rhinos = parsePieceList(state.R);
  const mountains = parseMountainList(state.M);
  const elReserve = countReserve(state.E);
  const rhReserve = countReserve(state.R);

  // Turn indicator
  const turnEl = document.getElementById('turn-indicator');
  turnEl.className = player === 'E' ? 'elephant' : 'rhino';
  turnEl.textContent = player === 'E' ? '🐘 Elephant\'s Turn' : '🦏 Rhinoceros\' Turn';

  // Reserves
  renderReserve('reserve-left', '🐘', elReserve, 'elephant', player === 'E');
  renderReserve('reserve-right', '🦏', rhReserve, 'rhino', player === 'R');

  // Board cells
  const boardEl = document.getElementById('board');
  boardEl.innerHTML = '';
  for (const row of ROWS) {
    for (const col of COLS) {
      const cellNum = row * 10 + col;
      const cell = document.createElement('div');
      cell.className = 'cell';
      cell.dataset.cell = cellNum;

      const el = elephants.find(p => p.cell === cellNum);
      const rh = rhinos.find(p => p.cell === cellNum);
      const isMtn = mountains.includes(cellNum);

      if (el) {
        cell.innerHTML = `🐘<span class="dir-arrow ${el.dir}">${DIR_ARROWS[el.dir]}</span>`;
      } else if (rh) {
        cell.innerHTML = `🦏<span class="dir-arrow ${rh.dir}">${DIR_ARROWS[rh.dir]}</span>`;
      } else if (isMtn) {
        cell.textContent = '⛰️';
      }

      cell.addEventListener('click', () => onCellClick(cellNum));
      boardEl.appendChild(cell);
    }
  }

  document.getElementById('action-hint').textContent = 'Click a piece or reserve to start your turn';
}

function renderReserve(containerId, emoji, count, colorClass, isActive) {
  const container = document.getElementById(containerId);
  container.innerHTML = `<div class="reserve-label">${emoji} Reserve</div>`;
  for (let i = 0; i < count; i++) {
    const piece = document.createElement('div');
    piece.className = `reserve-piece ${colorClass}`;
    piece.textContent = emoji;
    if (isActive) {
      piece.addEventListener('click', () => onReserveClick());
    } else {
      piece.style.opacity = '0.4';
      piece.style.cursor = 'default';
    }
    container.appendChild(piece);
  }
}
```

- [ ] **Step 2: Wire up init to render**

Replace the temporary console.log init with:

```javascript
initProlog().then(() => {
  renderBoard();
}).catch(err => {
  document.getElementById('action-hint').textContent = 'Error loading Prolog: ' + err.message;
});
```

- [ ] **Step 3: Test in browser — verify board renders**

Open `index.html` in a browser. Expected:
- Turn indicator shows "🐘 Elephant's Turn" with red background
- 5x5 grid with 3 mountains (⛰️) in row 3 at columns 2, 3, 4
- 5 elephant reserves on left, 5 rhino reserves on right
- All other cells empty

- [ ] **Step 4: Commit**

```bash
git add index.html
git commit -m "feat: render board, pieces, and reserves from Prolog state"
```

---

## Chunk 3: Interaction — Select, Highlight, Move

### Task 5: Piece selection and move highlighting

**Files:**
- Modify: `index.html` (JS module block)

- [ ] **Step 1: Write selection state and click handlers**

```javascript
let selectedDepart = null;
let currentMoves = [];

function onReserveClick() {
  selectedDepart = 0;
  currentMoves = parseMoveList(getMovesForPiece(0));
  highlightMoves();
  document.getElementById('action-hint').textContent = 'Click a highlighted cell to place your piece';
}

function onCellClick(cellNum) {
  // If direction picker is open, ignore board clicks
  if (!document.getElementById('direction-picker').classList.contains('hidden')) return;

  if (selectedDepart === null) {
    // Selecting a piece on the board
    const state = getState();
    const player = String(state.J);
    const elephants = parsePieceList(state.E);
    const rhinos = parsePieceList(state.R);

    const isOwn = (player === 'E' && elephants.some(p => p.cell === cellNum))
               || (player === 'R' && rhinos.some(p => p.cell === cellNum));

    if (!isOwn) return;

    selectedDepart = cellNum;
    currentMoves = parseMoveList(getMovesForPiece(cellNum));
    highlightMoves();
    document.getElementById('action-hint').textContent = 'Click a highlighted cell to move, or click the same cell to rotate';
  } else {
    // Clicking a destination
    const validDirs = currentMoves
      .filter(m => m.arrivee === cellNum)
      .map(m => m.dir);

    if (cellNum === 0) {
      // Withdraw — handled by withdraw target (see Task 6)
      return;
    }

    if (validDirs.length === 0) {
      // Clicked invalid cell — deselect
      clearSelection();
      return;
    }

    if (validDirs.length === 1) {
      // Auto-apply single direction
      executeMove(selectedDepart, cellNum, validDirs[0]);
    } else {
      // Show direction picker
      showDirectionPicker(cellNum, validDirs);
    }
  }
}

function highlightMoves() {
  // Clear previous highlights
  document.querySelectorAll('.cell').forEach(c => {
    c.classList.remove('highlighted', 'selected');
  });

  // Highlight selected piece
  if (selectedDepart > 0) {
    const selCell = document.querySelector(`.cell[data-cell="${selectedDepart}"]`);
    if (selCell) selCell.classList.add('selected');
  }

  // Highlight valid destinations
  const destinations = [...new Set(currentMoves.map(m => m.arrivee))];
  for (const dest of destinations) {
    if (dest === 0) continue; // Withdraw handled separately
    const cell = document.querySelector(`.cell[data-cell="${dest}"]`);
    if (cell) cell.classList.add('highlighted');
  }

  // Highlight selected reserve
  document.querySelectorAll('.reserve-piece').forEach(p => p.classList.remove('selected'));
  if (selectedDepart === 0) {
    const activeReserve = document.querySelector('.reserve-piece');
    if (activeReserve) activeReserve.classList.add('selected');
  }
}

function clearSelection() {
  selectedDepart = null;
  currentMoves = [];
  document.querySelectorAll('.cell').forEach(c => {
    c.classList.remove('highlighted', 'selected');
  });
  document.querySelectorAll('.reserve-piece').forEach(p => p.classList.remove('selected'));
  document.getElementById('direction-picker').classList.add('hidden');
  document.getElementById('action-hint').textContent = 'Click a piece or reserve to start your turn';
}
```

- [ ] **Step 2: Test in browser — verify highlighting**

Open `index.html`. Click a reserve elephant. Expected:
- Reserve piece gets selected border
- Edge cells highlighted with green border
- Hint text updates

Click an empty non-highlighted cell. Expected:
- Selection cleared, highlights removed

- [ ] **Step 3: Commit**

```bash
git add index.html
git commit -m "feat: piece selection and valid move highlighting"
```

---

### Task 6: Direction picker and move execution

**Files:**
- Modify: `index.html` (JS module block)

- [ ] **Step 1: Write direction picker logic**

```javascript
let pendingArrivee = null;

function showDirectionPicker(arrivee, validDirs) {
  pendingArrivee = arrivee;
  const picker = document.getElementById('direction-picker');

  // Position near the target cell, clamped to viewport
  const targetCell = document.querySelector(`.cell[data-cell="${arrivee}"]`);
  const rect = targetCell.getBoundingClientRect();
  const pickerW = 140, pickerH = 140; // 3×(44+4) grid
  let left = rect.left + rect.width / 2 - pickerW / 2;
  let top = rect.top + rect.height / 2 - pickerH / 2;
  left = Math.max(4, Math.min(left, window.innerWidth - pickerW - 4));
  top = Math.max(4, Math.min(top, window.innerHeight - pickerH - 4));
  picker.style.left = `${left}px`;
  picker.style.top = `${top}px`;

  // Enable/disable direction buttons
  picker.querySelectorAll('.dir-btn').forEach(btn => {
    const dir = btn.dataset.dir;
    if (validDirs.includes(dir)) {
      btn.classList.remove('disabled');
    } else {
      btn.classList.add('disabled');
    }
  });

  picker.classList.remove('hidden');
  document.getElementById('action-hint').textContent = 'Pick a direction for your piece';
}

// Wire up direction buttons
document.querySelectorAll('.dir-btn').forEach(btn => {
  btn.addEventListener('click', () => {
    const dir = btn.dataset.dir;
    if (btn.classList.contains('disabled')) return;
    document.getElementById('direction-picker').classList.add('hidden');
    executeMove(selectedDepart, pendingArrivee, dir);
  });
});
```

- [ ] **Step 2: Write move execution and win check**

```javascript
function executeMove(depart, arrivee, dir) {
  const ok = applyMove(depart, arrivee, dir);
  if (!ok) {
    document.getElementById('action-hint').textContent = 'Invalid move — try again';
    clearSelection();
    return;
  }

  clearSelection();

  if (isGameOver()) {
    renderBoard();
    const winner = getWinner();
    const overlay = document.getElementById('victory-overlay');
    const msg = document.getElementById('victory-message');
    if (winner === 'E') {
      msg.textContent = '🐘 Elephants Win!';
    } else if (winner === 'R') {
      msg.textContent = '🦏 Rhinoceros Win!';
    } else {
      msg.textContent = 'Game Over!';
    }
    overlay.classList.remove('hidden');
  } else {
    renderBoard();
  }
}

// Restart button
document.getElementById('restart-btn').addEventListener('click', () => {
  prolog.call('init_jeu');
  prolog.call('retractall(winner(_))');
  document.getElementById('victory-overlay').classList.add('hidden');
  renderBoard();
});
```

- [ ] **Step 3: Test in browser — play a full entry move**

Open `index.html`. Click elephant reserve → click edge cell 11 → if direction picker shows, click ▲ (North). Expected:
- 🐘 appears on cell 11 with ▲ arrow
- Turn switches to "🦏 Rhinoceros' Turn"
- Reserve count decreases by 1

- [ ] **Step 4: Commit**

```bash
git add index.html
git commit -m "feat: direction picker, move execution, and win detection"
```

---

### Task 7: Withdraw move support

**Files:**
- Modify: `index.html` (JS module block + HTML)

- [ ] **Step 1: Add withdraw targets to the board rendering**

In `renderBoard()`, after rendering the 5x5 grid, check if the selected piece is on an edge and has withdraw moves. If so, render a visual withdraw target.

The approach: when a piece is selected and `currentMoves` includes a move with `arrivee === 0`, show an indicator. Since withdraw isn't to a board cell, we add a "Withdraw" button below the board that appears only when relevant.

Add to HTML after the board:

```html
<button id="withdraw-btn" class="hidden">❌ Withdraw piece</button>
```

Add CSS:

```css
#withdraw-btn {
  margin-top: 0.5rem;
  padding: 0.5rem 1rem;
  background: #e94560;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-size: 0.9rem;
}
#withdraw-btn.hidden { display: none; }
#withdraw-btn:hover { background: #d63851; }
```

- [ ] **Step 2: Show/hide withdraw button in highlightMoves**

In `highlightMoves()`, after highlighting destinations:

```javascript
const hasWithdraw = currentMoves.some(m => m.arrivee === 0);
const withdrawBtn = document.getElementById('withdraw-btn');
if (hasWithdraw) {
  withdrawBtn.classList.remove('hidden');
} else {
  withdrawBtn.classList.add('hidden');
}
```

In `clearSelection()`, add:

```javascript
document.getElementById('withdraw-btn').classList.add('hidden');
```

- [ ] **Step 3: Wire up withdraw button click**

```javascript
document.getElementById('withdraw-btn').addEventListener('click', () => {
  if (selectedDepart === null || selectedDepart === 0) return;
  executeMove(selectedDepart, 0, 'N');
});
```

- [ ] **Step 4: Test in browser — withdraw a piece**

Enter an elephant on an edge cell (e.g. 11). On next elephant turn, click the elephant on cell 11. Expected:
- Valid move cells highlighted
- "Withdraw piece" button appears
Click withdraw. Expected: piece removed from board, turn switches, reserve count increases.

- [ ] **Step 5: Commit**

```bash
git add index.html
git commit -m "feat: withdraw button for removing pieces from edge cells"
```

---

## Chunk 4: Polish and Final Testing

### Task 8: Click-outside to dismiss and UX polish

**Files:**
- Modify: `index.html` (JS module block)

- [ ] **Step 1: Dismiss direction picker on click outside**

```javascript
document.addEventListener('click', (e) => {
  const picker = document.getElementById('direction-picker');
  if (!picker.classList.contains('hidden') && !picker.contains(e.target)) {
    picker.classList.add('hidden');
    pendingArrivee = null;
    document.getElementById('action-hint').textContent = 'Click a highlighted cell to move';
  }
});
```

Note: prevent this from interfering with cell clicks by checking `e.target` isn't inside `#board` or a `.dir-btn`. Use `e.stopPropagation()` on the direction picker clicks.

- [ ] **Step 2: Add loading state**

Update the init chain to show a loading message:

```javascript
document.getElementById('action-hint').textContent = 'Loading Prolog engine...';
initProlog().then(() => {
  renderBoard();
}).catch(err => {
  document.getElementById('action-hint').textContent = 'Error: ' + err.message;
});
```

- [ ] **Step 3: Commit**

```bash
git add index.html
git commit -m "feat: dismiss direction picker on outside click, loading state"
```

---

### Task 9: End-to-end manual testing

**Files:** None (testing only)

- [ ] **Step 1: Test full game flow in desktop browser**

Open `index.html` in Chrome/Firefox. Play through these scenarios:

1. **Enter piece**: Click reserve → click edge cell → pick direction → piece appears
2. **Move piece**: Click own piece → click adjacent highlighted cell → pick direction
3. **Rotate piece**: Click own piece → click its own cell (highlighted) → pick new direction
4. **Withdraw piece**: Click own piece on edge → click withdraw button → piece returns to reserve
5. **Push**: Move piece into occupied cell in the right direction → chain resolves
6. **Win**: Push a mountain off the board → victory overlay appears with correct winner
7. **Restart**: Click "New Game" → board resets to starting position

- [ ] **Step 2: Test on mobile viewport**

Open Chrome DevTools → toggle device toolbar → select iPhone SE or similar. Verify:
- Board scales to fit
- Touch targets are tappable (44px minimum)
- Direction picker is reachable
- No horizontal scroll

- [ ] **Step 3: Fix any issues found**

Address bugs found in steps 1-2. Each fix gets its own commit.

- [ ] **Step 4: Final commit**

```bash
git add index.html
git commit -m "fix: address issues from end-to-end testing"
```
