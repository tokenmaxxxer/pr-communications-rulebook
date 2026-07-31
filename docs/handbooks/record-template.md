---
role: pr-communications
---

# Phase-2 record template — required sections

Per `docs/issue-1/proposals/methodology-and-artifact-norms.md` (b)/(d),
approved via issue-1 comment `APPROVE issue-1/pr-communications`. Every
`docs/issue-<n>/reports/pr-communications.md` phase-2 record must contain
these three subsections, in addition to whatever `produces` requires
structurally (checked by core's `record-fields-gate.sh`, issue-66):

## Communications plan

State all four RACE stages explicitly:

- **Research** — summary, pointing back to this issue's phase-1 survey.
- **Action** — what this communication is meant to achieve/do (RACE's
  second stage — corrected from an earlier "Objectives" mislabeling;
  restores the actual RACE acronym, Research→Action→Communication→
  Evaluation).
- **Communication** — delivery mode / channel / timing.
- **Evaluation** — success criteria, defined *before* send, not after.

## Key message

Three-layer structure, required:

- **Core message** — exactly one.
- **Supporting messages** — as many as needed.
- **Proof points** — each message (core or supporting) carries at least
  one proof point; a key message with no proof point is incomplete.

## Risk/Q&A prep

List of expected question → pre-approved answer pairs. Prepared ahead of
time, not drafted live during a crisis.

---

Per issue-7 (mechanical enforcement), this manual-compliance gap is now
covered by three local plugins — `race-sequence`, `key-message-tiers`,
`qa-preapproval` — each a self-contained PreToolUse gate on `loop_state:
landed` writes to `docs/issue-*/reports/pr-communications.md`, checking
one methodology's sub-structure above (see each plugin's README and
`docs/issue-7/reports/pr-communications.md` §Phase-2 checklist). Core's
`record-fields-gate.sh` still checks only contract §20 structural fields
— the local plugins are a stopgap per issue-7 proposal Q2, to be
migrated to a core config mechanism if/when one exists; they are not
meant to be permanent local infrastructure.
