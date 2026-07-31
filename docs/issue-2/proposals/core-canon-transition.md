---
subject: issue-2
role: implementation
loop_state: scope-proposed
---

# Proposal — core canon 참조 전환 (warrant-hunter·게이트 복사본 제거)

Survey: [survey.md](../reports/implementation/survey.md).

## Plan, per the issue's 5-item task list

1. **Delete `pr-communications/agents/warrant-hunter.md`** and drop any
   hunt-cadence directive text tied to it (none found outside that file
   itself — `directive.sh` and `hooks.json` do not reference it). Replace
   with a one-line pointer in `README.md`'s Layout section to core's
   `warrant/` plugin (core issue-63) as the canon original. No local stance
   list to preserve — this repo's copy never got past skeleton ("enumerate
   this role's own stance set before shipping").

2. **Delete the three gate copies**
   (`trailer-gate.sh`, `record-fields-gate.sh`, `handbook-trigger-gate.sh`)
   and their `hooks.json` `PreToolUse` entries. Core's `core/hooks/hooks.json`
   (issue-66) registers all three on matcher `.*` for every plugin
   install — this repo installing the `core` plugin is what makes them
   fire; nothing left for `pr-communications`'s own `hooks.json` to wire.
   `hooks.json` keeps only the `SessionStart` → `directive.sh` entry.

3. **Rewrite `directive.sh` as a stub**, sourcing
   `core/hooks/lib/role-directive.sh` and calling `core_role_directive`
   with this role's four values, matching the shape
   `stub-check.sh` enforces (source line + call, `trap`/`set -uo pipefail`
   kept at top per issue-66's own note that this pair cannot be factored
   out of the sourcing script).

4. **RECORD_FIELDS_TERMINAL_STATES**: survey finding 4 — no override
   needed. This role's terminal `loop_state` is `landed`, matching core's
   default; nothing to set in `hooks.json` `env`.

5. **stub-check.sh confirmation**: add
   `core/hooks/tests/stub-check.sh` to this repo's own test harness (or
   run it ad hoc against `pr-communications/hooks/`) once items 1–3 land,
   and record the pass in `docs/issue-2/reports/implementation.md`
   (phase-2, post-Approve).

## Open questions for the approver

**Q1 — produces-triad check (survey finding 3).** Core's promoted
`record-fields-gate.sh` checks contract §20's structural minimum only; it
has no mechanism for a role's own `produces` field list
(`communications-plan`, `key-message`, `risk-qa-prep`), which this repo's
local copy currently enforces and core's canon does not replace. Three
options:
  - (a) accept the loss — rely on §20 structural fields only, drop the
    produces-triad check entirely (matches "delete the copy" literally,
    simplest, but is a real behavior regression versus today).
  - (b) do not delete `record-fields-gate.sh` here; keep only this repo's
    produces-triad check as a second, narrower PreToolUse hook alongside
    core's structural one (partial removal — the issue's item 2 said
    remove the copy, so this would need explicit sign-off to deviate).
  - (c) raise this gap as a **new core issue** (produces-field config,
    parallel to how `RECORD_FIELDS_TERMINAL_STATES` was added) rather than
    solving it locally, and land (a) here in the meantime.

  Recommendation: (c) — matches issue-66's own precedent of surfacing
  genuine per-role divergence as core config rather than a local
  workaround, and keeps this repo's gate surface at zero per the issue's
  literal ask. Needs approver sign-off since it changes enforced behavior,
  not just file location.

**Q2 — WRITE_SCOPE / BOUNDARY CASE lines.** `core_role_directive` has no
parameter for these two lines currently in this role's directive output.
Recommendation: fold `WRITE_SCOPE: []` and the `BOUNDARY CASE` paragraph
into the `hand_off` argument (they are both hand-off-adjacent content) so
no information is dropped and the stub stays in the exact 4-arg shape
`stub-check.sh` expects. Flagging for approver confirmation since it
changes the rendered directive's wording, not just its plumbing.

**Q3 — upstream branch state.** Both `core` commits this transition
depends on (issue-63, issue-66) are only on their own feature branches in
the `core` repo, not yet on `core`'s `main`. Recommendation: this repo's
phase-2 work should not merge to `main` here before confirming (via the
`core` repo, out of this role's write scope) that both have landed on
`core`'s `main` — otherwise `pr-communications` would depend on
unmerged core state. Sequencing question for the approver / on-the-record,
not something this role can resolve unilaterally.

## Out of scope / preserved

- Role-unique content (`decides`/`use_when`/`produces`/`hand-off` values,
  the `pr-communications` plugin identity, `docs/specs/approvers.md`) is
  untouched by this transition — only the vendored-copy mechanics change.
