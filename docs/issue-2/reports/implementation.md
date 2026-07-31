---
subject: issue-2
role: implementation
loop_state: landed
---

# Record — core canon 참조 전환 (issue-2)

## What was done

Per the approved proposal (`docs/issue-2/proposals/core-canon-transition.md`,
approved via issue comment `APPROVE issue-2/implementation`):

1. Deleted `pr-communications/agents/warrant-hunter.md` (and the now-empty
   `pr-communications/agents/` directory). README's Layout section replaced
   with a pointer to core's `warrant/` plugin (core issue-63) as canon.
2. Deleted the three gate copies — `trailer-gate.sh`, `record-fields-gate.sh`,
   `handbook-trigger-gate.sh` — and their `PreToolUse` entries from
   `pr-communications/hooks/hooks.json`, which now carries only the
   `SessionStart` → `directive.sh` entry. Core's `core/hooks/hooks.json`
   (issue-66) registers all three on matcher `.*` for every plugin install.
3. Rewrote `pr-communications/hooks/directive.sh` as a stub: sources
   `core/hooks/lib/role-directive.sh` and calls `core_role_directive` with
   this role's four values (`you_decide`, `use_when`, `produces`,
   `hand_off`). Per proposal Q2, `WRITE_SCOPE: []` and the `BOUNDARY CASE`
   paragraph — both hand-off-adjacent content with no dedicated parameter in
   `core_role_directive` — are folded into the `hand_off` argument, so no
   information is dropped.
4. `RECORD_FIELDS_TERMINAL_STATES`: no override added. This role's terminal
   `loop_state` is `landed`, matching core's default (survey finding 4).
5. Ran `core/hooks/tests/stub-check.sh` (read from the issue-66 checkout,
   `tokenmaxxxer-core-issue-66-implementation/core`) ad hoc against
   `pr-communications/hooks/` — see Stub-check confirmation below.

Proposal Q1 (produces-triad check gap) was resolved per the proposal's own
recommendation (c): the local produces-triad enforcement
(`communications-plan`, `key-message`, `risk-qa-prep`) is not replaced by
core's structural gate and is not reimplemented locally — accepted as a gap
to raise as a new core issue (out of this role's write scope; not filed by
this session). Core's structural `record-fields-gate.sh` (issue-66) is now
the only record-fields enforcement in effect for this repo.

## Why

Issue-2 requires converting this rulebook's warrant-hunter and gate-triad
vendored copies to references against the now-landed core canon (core
issue-63, issue-66), per the role-handoff contract's drift-prevention intent
— a local copy of a promoted core file is drift, not a stub, per
`stub-check.sh`'s own definition.

## Upstream basis

- Proposal: `docs/issue-2/proposals/core-canon-transition.md`
- Survey: `docs/issue-2/reports/implementation/survey.md`
- Approval: issue-2 comment, exact string `APPROVE issue-2/implementation`
- Core issue-63 (`tokenmaxxxer/core`, branch `issue-63/implementation`,
  commit `1e16d64`): `warrant/` canon plugin
- Core issue-66 (`tokenmaxxxer/core`, branch `issue-66/implementation`,
  commit `d5b544e`): `core/hooks/{trailer-gate.sh,record-fields-gate.sh,
  handbook-trigger-gate.sh,lib/role-directive.sh,tests/stub-check.sh}`

## Stub-check confirmation

Ran:

```
bash tokenmaxxxer-core-issue-66-implementation/core/hooks/tests/stub-check.sh \
  pr-communications-rulebook-issue-2-implementation/pr-communications/hooks
```

Output — all five checks pass (exit 0):

```
stub-check: ok — no vendored 'trailer-gate.sh' under .../pr-communications/hooks
stub-check: ok — no vendored 'record-fields-gate.sh' under .../pr-communications/hooks
stub-check: ok — no vendored 'handbook-trigger-gate.sh' under .../pr-communications/hooks
stub-check: ok — no vendored 'parse-check.sh' under .../pr-communications/hooks
stub-check: ok — .../pr-communications/hooks/directive.sh is a role-directive stub
```

Note: `stub-check.sh` was run ad hoc from the sibling core issue-66 checkout
per the proposal's item-5 allowance ("run it ad hoc against
`pr-communications/hooks/`"); it was not copied into this repo's own test
harness, since this repo has no test harness directory yet.

## Sequencing caveat (proposal Q3, unresolved by this role)

Both core commits this transition depends on (issue-63, issue-66) are only
on their own feature branches in the `core` repo, not yet on `core`'s
`main`. This is out of this role's write scope to resolve; flagging again
here per the proposal — merging this repo's `issue-2/implementation` branch
to `main` should wait for confirmation that both core branches have landed
on `core`'s `main` first.

## Open findings

- Produces-triad gate gap (proposal Q1): needs a new core issue for
  per-role `produces`-field config, parallel to
  `RECORD_FIELDS_TERMINAL_STATES`. Not filed by this session (out of write
  scope) — on-the-record should track it.
- Core issue-63 / issue-66 not yet on core's `main` (Q3, above).

## loop_state

`landed` — this role's phase-2 delivery for issue-2 is complete and
committed; no further steps remain on this role's side pending the two open
findings above, which are follow-ups outside this branch's scope.
