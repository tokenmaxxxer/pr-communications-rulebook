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
- **Objectives** — what this communication is meant to achieve.
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

This template is manual-compliance only: core's `record-fields-gate.sh`
checks contract §20 structural fields, not this role-specific
`produces` sub-structure. Per proposal (d)/Q1, the gap is tracked as a
follow-up for a new core issue (per-role `produces` sub-structure check),
not solved with a local gate script (would repeat the vendored-copy
pattern issue-2 just removed).
