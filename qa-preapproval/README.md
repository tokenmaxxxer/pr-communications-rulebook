# qa-preapproval

Claude Code plugin that owns the **pre-approved Risk/Q&A methodology**:
every risk Q&A pair must carry an approver's pre-approval mark — a draft
answer by itself is not enough. **Phase-2 only.**

## Phase-2-only participation

This plugin's gate only fires once a report has reached a terminal state
(`loop_state: landed`). Phase-1 drafting (any other `loop_state`) passes
through untouched — the gate does not interfere with in-progress work.

## Exact gate rule

For any `Write|Edit` targeting a path matching `docs/issue-*/reports/pr-communications.md`:

1. If the target file does not exist, the gate fails closed (non-zero exit).
2. If `^loop_state: landed` is not present in the file, the gate exits 0 (not yet terminal — out of scope).
3. The file must contain a `## Risk/Q&A prep` heading. Missing it → reject.
4. Within that section (heading to the next `## ` heading, or EOF), at least
   one Q&A pair must be present, in either style:
   - a `Q:` line followed later by an `A:` line, or
   - a line containing `질문` followed later by a line containing `답변`.
   Missing → reject.
5. Within the same section, a pre-approval mark must be present:
   case-insensitive `pre-approved`, or the literal `사전 승인`. Missing →
   reject with the reason "ad-hoc answer without approver sign-off".
6. Otherwise, exit 0.

Any unexpected internal error fails closed (non-zero exit) rather than
silently passing.

## Manual invocation

```sh
./hooks/qa-preapproval-gate.sh <path-to-report.md>
```

Passing a path directly (as the tests do) bypasses reading the PreToolUse
hook JSON from stdin.

## Kill switch (emergency only)

Set `QA_PREAPPROVAL_GATE_DISABLE=1` to skip the gate entirely. This is an
emergency escape hatch, not a normal workflow control — use it only when
the gate itself is broken and blocking an unrelated, urgent operation, and
prefer fixing the gate or the underlying document over leaving the switch on.

## Checklist

`checklists/qa-preapproval.md` holds the one self-check this plugin owns:
confirm, by eye, that **every** Q&A pair in the section — not just one —
carries a pre-approval mark. This plugin is the only one of the three
sibling plugins (`qa-preapproval`, `race-sequence`, `key-message-tiers`)
with a checklist, because it is the only gate whose mechanical check
(a single grep pass over the whole section) can be satisfied by one marked
pair while other pairs in the same section remain unmarked — a per-pair
repeated review is the one thing the grep can miss.

## Tests

```sh
./../tests/qa-preapproval-gate-test.sh
```

or, from the repo root:

```sh
./tests/qa-preapproval-gate-test.sh
```
