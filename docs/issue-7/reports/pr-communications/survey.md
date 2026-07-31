---
subject: issue-7
role: pr-communications
---

# Current-state survey (issue-7)

## What exists today

- `pr-communications/hooks/directive.sh` — stub sourcing core's
  `role-directive.sh`. `PRODUCES` is a single-line string: `"communications
  plan (RACE: research/objectives/communication/evaluation), key message
  (core+supporting+proof point), risk/Q&A prep (pre-approved)"`. It states
  the four RACE stages and the three-tier message shape by name only — no
  per-stage criteria, no prohibitions, no phase-1 vs phase-2 split in the
  directive text itself (issue-1's proposal put that split in the *proposal
  document*, not in what SessionStart actually prints to the agent).
- `docs/handbooks/record-template.md` — the phase-2 record template
  (RACE plan / key message / risk-Q&A) approved in issue-1. It is prose-only:
  "manual-compliance only... the gap is tracked as a follow-up... not solved
  with a local gate script."
- `docs/issue-1/proposals/methodology-and-artifact-norms.md` Q1 explicitly
  left this open and recommended (c): raise a core issue for a generic
  per-role produces-substructure gate, do nothing locally in the meantime.
  No core issue has been filed (per issue-2's record, "not filed by this
  session"); no such core gate exists yet as of this survey.
- No `pr-communications/hooks/*-gate.sh` file exists (issue-2 deleted the
  three vendored copies; core's `record-fields-gate.sh` only checks contract
  §20 structural frontmatter fields, not this role's RACE/key-message/Q&A
  content).
- No `tests/` directory at the repo root.
- No `agents/` directory (issue-2 removed `warrant-hunter.md`; core's
  `warrant/` plugin is the canon rotating-stance hunt agent and is unrelated
  to this issue's "반복 절차" ask).
- `docs/specs/approvers.md` — single approver, `JiwonJung94`; this repo is in
  single-account mode (PR author and approver are the same login), so phase 2
  opens via the issue comment `APPROVE issue-7/pr-communications`, not a PR
  review.

## Gaps against issue-7's four requirements

1. **Directive depth (req 1)** — `PRODUCES` is one line, no phase split, no
   per-facet criteria/prohibitions. Confirmed gap.
2. **Methodology gate (req 2)** — no mechanical check of RACE-plan /
   key-message / risk-Q&A structure anywhere. `record-fields-gate.sh` (core)
   does not cover it (survey point above, and issue-1 Q1 / issue-2 Q1 already
   established this precisely). Confirmed gap. Ordering constraint: RACE is
   sequential (R→O→C→E) *within a single phase-2 record file* — this is a
   positional check (heading order), not a cross-file/cross-session state
   machine; no persistent state store is needed for it. The phase-1→phase-2
   ordering (research/objectives before communication/evaluation) is already
   enforced structurally by contract v3 s19's phase gate (Approve-gated), so
   nothing new is needed there either.
3. **Gate tests (req 3)** — no `tests/` directory exists at all. Confirmed gap.
4. **Agents/checklist (req 4)** — RACE has no genuinely repeated procedural
   loop analogous to `implementation-rulebook`'s hunt cadence (that pattern
   fits an iterate-until-dry search; RACE is a single linear plan). A
   checklist (not an agent) is the right-sized artifact if req 4 applies at
   all — see proposal (d).

## Reference points examined

- `docs/issue-2/proposals/core-canon-transition.md` and its record — the
  established local precedent for "reference the canon, do not vendor a
  copy," and for how a produces-substructure gap gets flagged (Q1 pattern)
  rather than silently reimplemented.
- Issue text's own reference, `pricing-rulebook`'s `methodology-gate.sh`, is
  outside this session's filesystem access (sandboxed to this repo's working
  tree) and could not be read directly; the gate design in the proposal is
  derived from the issue's own description of that pattern ("record/proposal
  쓰기 표면에서 필수 섹션·요소 검사") plus this repo's own established
  gate conventions (`PreToolUse` matcher on Write/Edit, path-scoped to
  `docs/issue-<n>/...`, canon lib sourced not copied) — not from reading the
  pricing gate's source.
