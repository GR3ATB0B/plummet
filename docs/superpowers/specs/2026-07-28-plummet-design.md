# Plummet — Design Spec

*A playful iOS kinematics solver. Throw something off a building, time the fall, learn how high it was — and see every equation behind the answer.*

Date: 2026-07-28
Status: Approved (design), pending implementation plan
Platform: Native SwiftUI, iOS 17+, iPhone. Builds and runs in the iOS Simulator.

---

## 1. Concept

One screen. A short list of the five kinematics variables. Fill in any three and Plummet
instantly solves the rest. A stopwatch at the bottom lets you time a real fall — press stop
and the elapsed time drops straight into the time field, solving the page for you.

The whole thing looks like a physicist's graph-paper field notebook. Answers appear filled in
and clean by default; tap any solved value to expand the full worked steps beneath it.

The signature payoff: drop or throw something, and Plummet tells you how high it went — in
meters, feet, and "≈ N floors."

---

## 2. Physics engine

The core is a pure Swift value type, `KinematicsSolver`, with **no UI dependencies**. It is the
most heavily tested part of the app.

### Variables (suvat)

| Symbol | Meaning | Unit | Default |
|--------|---------|------|---------|
| `s`  | displacement | m | — |
| `v0` | initial velocity | m/s | — |
| `v`  | final velocity | m/s | — |
| `a`  | acceleration | m/s² | **−9.81** (prefilled, editable) |
| `t`  | time | s | — |

### Sign convention

**Up is positive.** Gravity therefore points down: `a = −9.81 m/s²`, shown on screen as `↑ +`.
This matches lay intuition — throwing something *up* is a positive launch velocity.

A consequence: an object that falls ends up *below* its start, so its displacement `s` is
negative. To keep the "how high" experience intuitive, the **feet + floors readout uses the
magnitude** `|s|` — a fall is always reported as a positive height, never "−22 m." The raw
signed `s` still appears in its own field for anyone who wants it.

### Solving

- The solver treats each of the five variables as *known* (a value) or *unknown* (nil).
- It solves when **at least 3 are known**. With the standard suvat equation set, any 3 knowns
  determine the remaining 2.
- It is closed-form: given which trio is known, it selects the appropriate suvat equation(s)
  and computes each unknown directly (no numeric iteration). Each solved value records **which
  equation produced it**, for the worked-steps display.

The five suvat equations available to the solver:

1. `v = v0 + a·t`
2. `s = v0·t + ½·a·t²`
3. `s = ½·(v0 + v)·t`
4. `v² = v0² + 2·a·s`
5. `s = v·t − ½·a·t²`

### Edge cases

- **Two-solution cases** — e.g. an object thrown up passes a given height twice, so solving for
  `t` from `s` yields a quadratic with two positive roots. Plummet shows the **earliest positive
  time** as the primary answer and surfaces a small "▸ 2nd solution" affordance when a second
  physically-valid root exists.
- **Conflicting over-input** — the user has typed more than three values and they cannot all be
  simultaneously true. Plummet does **not** silently overwrite or lie: it flags the offending
  row(s) with a dashed underline and a quiet "doesn't add up" note, and holds off on presenting
  a false solution.
- **No real solution** — e.g. `v² = v0² + 2·a·s` yields a negative under the root. The dependent
  field shows a gentle "no real answer" state rather than NaN.
- **Divide-by-zero / degenerate** — e.g. solving for `t` when `a = 0` falls back to the linear
  equation; guarded so no field ever displays NaN or ∞.

---

## 3. Screen layout — locked to the graph grid

The graph-paper square is the layout unit. This is a hard requirement, not decoration.

- **Every field row is exactly 2 grid squares tall.**
- **Text baselines sit on a ruled line** — never floating between lines, never overlapping one.
- **Left margin aligns to a column line;** values are right-aligned to a column line.
- Expanding a row to show worked steps grows it **downward by a whole number of grid squares**,
  so the grid alignment is preserved for every row below.

Vertical structure, top to bottom:

1. **Title block** — "Plummet" + the sign-convention hint (`↑ + · a = −9.81`).
2. **Field list** — five rows: `s height`, `v₀ launch`, `v final`, `a accel`, `t time`.
   Each row: label (left), value (right), dim unit. User-entered values render in
   "handwriting" ink-black; solved values render in ink-green with a faint solved tick.
3. **Height readout** — appears under `s` once height is known: `|s|` in meters, feet, and
   "≈ N floors" (floor ≈ 3 m / ~10 ft).
4. **Stopwatch bar** — pinned at the bottom.

Visual style ("Field notebook", chosen from three explored directions):
- Cream paper (`#FBFBF3`) with a ruled graph grid (`#E4E7D8`).
- Monospace type throughout.
- Dashed rule under each row.
- Ink-green (`#173404` / `#3B6D11`) for solved / accent, near-black for user input.

---

## 4. Stopwatch and interaction flow

- **Stopwatch bar**: a large `▷ START`. Tap → runs, showing live elapsed time → button becomes
  `◼ STOP`. Tap stop → elapsed seconds are written into the `t` field and the page solves
  immediately.
- **Live solving**: any edit to any field re-runs the solver. When the known-count reaches 3,
  the remaining fields fill in.
- **Solved vs input styling**: solved fields are visually distinct (ink-green + tick) from
  user-entered fields, so it's always clear what you gave vs. what Plummet found.
- **Editing a solved field** promotes it to a user input; the solver frees whatever was most
  recently derived and recomputes. Clearing a field frees it.
- **Worked steps**: tap a solved value → the row expands downward (whole grid squares) to show:
  the equation used → the same equation with the user's numbers substituted in → the result.
  Tap again to collapse. Default state is collapsed (answers-first).
- **Reset**: a small `⌫` clears all fields back to blank, restoring `a = −9.81`.

---

## 5. Playful touches (all optional, low-cost)

- Haptic tick on stopwatch start, stopwatch stop, and on a successful solve.
- When a height solves, the number animates in with a small "drop" (falls into place), echoing
  the theme. One modifier, easily removed.
- Cohesive notebook aesthetic: monospace, dashed rules, cream graph paper.

None of these are load-bearing; the app is fully usable with all animation/haptics disabled.

---

## 6. Architecture

Three layers, clean boundaries:

- **`KinematicsSolver`** (pure struct) — inputs: the five optional values. Output: a result with
  every variable's value plus, per solved variable, the equation and substituted-numbers record.
  No UI, no Foundation UI types. Independently testable.
- **`SolverState`** (`ObservableObject`) — the view model. Holds each field's current value and
  whether it is user-entered or solved, owns the stopwatch timer, and calls `KinematicsSolver`
  on every change. Exposes formatting helpers (feet, floors, rounding).
- **Views** — `NotebookView` (screen + grid background), `FieldRowView` (one variable row,
  including its expandable worked-steps), `StopwatchBar`. Views are thin; all logic lives below.

Each unit answers cleanly: *what does it do, how is it used, what does it depend on.* The solver
depends on nothing; the state depends on the solver; the views depend on the state.

---

## 7. Testing

- **`KinematicsSolver` gets real unit tests, written first (TDD).** Coverage includes:
  - drop from rest (`v0 = 0`, given `t` → `s`)
  - throw up, throw down
  - apex (solving where `v = 0`)
  - representative 3-known combinations across all five variables
  - the two-solution (quadratic) case, asserting the earliest-positive-time primary answer
  - conflicting over-input → flagged, not falsely solved
  - degenerate guards (`a = 0`, negative-under-root) → no NaN/∞
- **Solver correctness is verified against hand-computed physics values.**
- UI is smoke-verified in the iOS Simulator (launch, enter a fall, run the stopwatch, expand a
  worked-step, reset).

---

## 8. Explicitly out of scope (YAGNI)

- Air resistance / drag. Ideal kinematics only.
- Multiple planets / configurable gravity presets (though `a` is user-editable, so Moon gravity
  works if you type it).
- Persistence, history, accounts, sharing.
- iPad / landscape-specific layouts. iPhone portrait only.
- Imperial *input* — solving is metric; feet/floors are display-only.

---

## 9. Open decisions resolved during brainstorming

- Physics scope: **full 5-variable suvat solver** (not drop-only).
- App shape: **single screen** — field list + stopwatch that feeds the time field.
- Fields: **all five suvat variables**, `a` prefilled.
- Units: **metric solve + feet + "≈ N floors"** display.
- Math display: **answers first, full worked steps on tap** (progressive disclosure).
- Sign convention: **up positive**, `a = −9.81`; height readout uses magnitude.
- Visual style: **field notebook**, strictly grid-aligned.
