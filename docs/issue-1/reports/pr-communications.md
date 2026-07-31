---
subject: issue-1
role: pr-communications
loop_state: landed
---

# Record — RACE-based phase-1/phase-2 norms, plugin reflection (issue-1)

Per the approved proposal
(`docs/issue-1/proposals/methodology-and-artifact-norms.md`, approved via
issue-1 comment, exact string `APPROVE issue-1/pr-communications`).

## What was done

1. **`pr-communications/hooks/directive.sh`** — `PRODUCES` string expanded
   from the bare `communications plan, key message, risk/Q&A prep` to
   spell out the adopted structure per proposal (d): `communications plan
   (RACE: research/objectives/communication/evaluation), key message
   (core+supporting+proof point), risk/Q&A prep (pre-approved)`. Only the
   argument value changed; `core_role_directive`'s 4-argument stub shape
   (issue-2/core issue-66) is untouched — no new argument added, no local
   gate script written.
2. **Record template** — added `docs/handbooks/record-template.md`,
   documenting the three mandatory phase-2 record subsections
   (Communications plan / Key message / Risk-Q&A prep) per proposal (b),
   for this and future issues' `docs/issue-<n>/reports/pr-communications.md`.
3. **Gate**: per proposal (d) and Q1's approved recommendation, no local
   `PreToolUse` content gate was added. Core's `record-fields-gate.sh`
   (core issue-66) continues to check only contract §20 structural fields;
   this role's `produces` sub-structure (the three subsections above) is
   manual-compliance via the record template, pending a new core issue for
   per-role `produces` sub-structure checking (not filed by this session —
   out of write scope, same pattern as issue-2's own open finding).

## Communications plan

- **Research** — this issue's own scope is internal (rulebook plugin
  reflection), not an external-facing communication; see
  `docs/issue-1/reports/pr-communications/survey.md` for the domain survey
  that grounds the adopted norms.
- **Objectives** — make this rulebook's phase-1 proposal and phase-2
  record structure match RACE-derived, domain-grounded norms rather than
  ad hoc conventions, so future issues on this role inherit a settled
  structure.
- **Communication** — delivered as this PR (code + docs) against
  `pr-communications-rulebook`, reviewed via the standing single-account
  approval flow.
- **Evaluation** — success = `directive.sh`'s `PRODUCES` string and the
  new record template are in place and this record itself conforms to the
  template it defines (self-check below), verified at merge time by PR
  review, not after the fact.

## Key message

- **Core message**: this role's phase-1/phase-2 outputs now follow an
  industry-standard (RACE) structure instead of an unstructured
  `produces` list.
  - Proof point: RACE's four stages map 1:1 onto this contract's existing
    phase-1 (Research+Objectives) / phase-2 (Communication+Evaluation)
    split — no new structure was invented, see proposal (c).
- **Supporting message**: key messages are only complete with a
  proof point.
  - Proof point: scout brief (`docs/issue-1/reports/pr-communications/scout-brief.md`)
    found this pattern converged across surveyed angles.
- **Supporting message**: Q&A prep is prepared before a crisis, not during.
  - Proof point: this role's `hand-off` already scopes it to
    crisis/external-response communication, where live drafting loses
    message control.

## Risk/Q&A prep

- **Q: Why wasn't a local content gate added to enforce the three record
  subsections?**
  A (pre-approved, proposal Q1 resolution): core's structural gate
  (issue-66) doesn't cover role-specific `produces` sub-structure, and
  writing one locally would repeat the vendored-copy pattern issue-2 just
  removed. Manual compliance via the template, plus a future core issue,
  is the deliberate tradeoff.
- **Q: Does this change affect warrant-hunter or the core-canon reference
  structure from issue-2?**
  A: No — out of scope per the proposal; issue-2's reference-only
  structure is untouched.

## Open findings

- Follow-up core issue for per-role `produces` sub-structure gate config
  not yet filed (tracked here and in issue-2's record as the same class of
  gap; out of this role's write scope to file against `core`).

## loop_state

`landed` — phase-2 delivery for issue-1 is committed on this branch; no
further steps remain on this role's side pending the open core-issue
follow-up noted above.
