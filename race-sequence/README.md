# race-sequence

Owns the **RACE sequencing methodology**: Research -> Action -> Communication
-> Evaluation.

## Naming correction

The second letter of RACE is **Action**, not "Objectives". An earlier round
of review mislabeled it and an approver required it be corrected back to
"Action". Every label, doc string, and gate check in this plugin uses
"Action" — never "Objectives".

## Phase-1 vs phase-2 participation

- **Phase-1 (draft stage):** only Research and Action are finalized.
  - Research: current-state summary + stakeholder draft.
  - Action: goals drawn explicitly from the issue — concretely stated
    objectives/next actions, not a copy-paste of the issue text.
  - Communication and Evaluation exist only as a target/channel sketch; they
    are not finalized in phase-1.
- **Phase-2 (landed stage):** the full 4-stage RACE order is enforced:
  1. Research — reconfirmed from the phase-1 survey (not re-researched).
  2. Action — reconfirmed from phase-1.
  3. Communication — channel, timing, and actual delivery confirmed.
  4. Evaluation — success criteria defined **before** send. Defining
     success criteria after the send is RACE's core failure mode.

## Gate rule enforced

`hooks/race-sequence-gate.sh` runs on `PreToolUse` for `Write|Edit` and acts
only on files matching `docs/issue-*/reports/pr-communications.md`. It is a
no-op for anything else.

For an in-scope file:

1. If `loop_state: landed` is not present in the file, the write passes
   through un-gated (non-terminal writes such as `scope-proposed` are not
   checked).
2. If terminal, the file must contain a `## Communications plan` heading.
3. The file must contain all four bold labels — `**Research**`,
   `**Action**`, `**Communication**`, `**Evaluation**` — and their line
   numbers must appear in that exact, strictly increasing order. Any
   missing label or any out-of-order pair fails the gate with a message
   naming the specific problem (e.g. "Evaluation (line 12) appears before
   Communication (line 20)").

Non-existent input files fail closed (non-zero exit), not exit 0 — see
`hooks/race-sequence-gate.sh` for the explicit read check that triggers
this via the script's `ERR` trap.

## Manual invocation for testing

```sh
./hooks/race-sequence-gate.sh <path-to-pr-communications.md>
```

Exit code `0` = pass/pass-through. Non-zero = rejected (message on stderr).

## Kill switch

Setting `RACE_SEQUENCE_GATE_DISABLE=1` in the environment skips the gate
entirely and logs a notice to stderr. This is an **emergency admin escape
hatch only** — not a routine bypass. Use it only when the gate itself is
broken and blocking unrelated work; remove it as soon as the underlying
issue is fixed.

## Tests

Run the gate's test suite from the repo root:

```sh
./tests/race-sequence-gate-test.sh
```
