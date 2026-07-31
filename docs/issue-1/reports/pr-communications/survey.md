---
subject: issue-1
role: pr-communications
loop_state: scope-proposed
---

# Current-state survey (issue-1)

## What this repo currently has

- `README.md`: role identity only — `decides`/`use_when`/`produces`/`write_scope`/
  `hand-off`, copied from `directive.sh`. `produces` = "communications plan, key
  message, risk/Q&A prep" (three nouns, no definition of what belongs in each,
  no required methodology, no required sections).
- `pr-communications/hooks/directive.sh`: stub sourcing core's
  `role-directive.sh` (core issue-66/issue-2 here) — SessionStart banner only,
  carries the four directive values above. No phase-1/phase-2 content-quality
  gate of its own.
- `pr-communications/hooks/hooks.json`: `SessionStart` → `directive.sh` only.
  Core's `hooks.json` (issue-66) supplies the generic trailer/record-fields/
  handbook-trigger `PreToolUse` gates for every plugin install — these check
  contract-v3 structural minimums (frontmatter fields, record existence), not
  domain content.
- No `docs/handbooks/`, no `docs/decisions/` content yet — this repo is
  "scaffolding, not a finished rulebook" per its own README.
- issue-2 (implementation role, already merged) established the pattern this
  issue should follow for its own plugin reflection: canon lives in `core`,
  this repo's `directive.sh` is a thin stub carrying only role-unique values,
  and any new required field is proposed as a value inside the existing
  `core_role_directive` call shape (`you_decide`/`use_when`/`produces`/
  `hand_off`) rather than a new local script.

## Gaps this issue must close

1. **No methodology named** for phase-1 proposals in this role (what process
   produces "communications plan, key message, risk/Q&A prep"?) — currently
   just three nouns.
2. **No required sections/components enumerated** — a phase-2 deliverable
   with those three noun-labels but empty content would currently pass every
   existing gate (core's structural gate checks frontmatter fields exist, not
   domain substance).
3. **No sourcing/evidence-basis convention** — nothing requires a
   communications plan to name its stakeholder basis, or a key message to
   show its supporting proof points.
4. **No plugin enforcement point identified yet** — `core_role_directive`'s
   `PRODUCES` argument is one string; there is no mechanism today to check
   that a record actually contains the sub-components this issue's proposal
   will require (parallel to issue-2's Q1 finding — the local produces-triad
   check was dropped in favor of core's structural-only gate, leaving a real
   gap this repo has not filled).

These four gaps are what the scout sweep below aims at: what does the field's
best-in-class practice require for (a) the phase-1 planning artifact and
(b) the phase-2 deliverable set, and what field-standard content check would
plug gap 3–4.

## Constraints carried over (per issue-1 text)

- warrant-hunter stays a core-canon reference only (core issue-63) — no local
  copy, unaffected by this issue.
- Existing record discipline / documentation obligations from prior
  hardening (issue-2) are preserved, not loosened.
