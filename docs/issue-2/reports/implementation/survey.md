---
subject: issue-2
role: implementation
loop_state: scope-proposed
---

# Current-state survey — core canon 참조 전환 (issue-2)

## Scope note (scout skip record)

Scout sweep skipped. Reason: this task has no product/exemplar-comparison
decision to scout — the target shape is fixed by two already-landed core
commits (`core` issue-63 and issue-66), read directly below rather than
guessed from the issue text. The only open decision (produces-field
coverage, see Finding 3) is an internal design tradeoff, not something a
market sweep would inform.

## This repo's current vendored copies

| File | Role in this repo |
|---|---|
| `pr-communications/agents/warrant-hunter.md` | vendored copy, adapted from `implementation-rulebook`'s copy (skeleton — stances not yet enumerated) |
| `pr-communications/hooks/trailer-gate.sh` | vendored copy, "role-agnostic" per its own header comment |
| `pr-communications/hooks/record-fields-gate.sh` | vendored copy, checks THIS role's own `produces` field set (`communications-plan`, `key-message`, `risk-qa-prep`) |
| `pr-communications/hooks/handbook-trigger-gate.sh` | vendored copy, placeholder verdict (`exit 0` — unimplemented) |
| `pr-communications/hooks/directive.sh` | role directive, currently a full standalone script (trap/kill-switch/guard + role content inline) |
| `pr-communications/hooks/hooks.json` | registers all four above locally |

## Core canon state (verified by reading the landed commits directly)

- **core issue-63** (`tokenmaxxxer-core-issue-63-implementation/core`,
  commit `1e16d64`, on branch `issue-63/implementation`, 1 commit ahead of
  `origin/main` — not yet merged to core's main): adds `warrant/` as a
  top-level canon plugin (`warrant/.claude-plugin/plugin.json`,
  `warrant/agents/warrant-hunter.md`, `warrant/hooks/{directive.sh,
  hunt-guard.sh, hunt-state.sh, scope-gate.sh, state.sh, hooks.json}`),
  registered in `.claude-plugin/marketplace.json`. This is the "single
  original" the issue refers to for warrant-hunter.

- **core issue-66** (`tokenmaxxxer-core-issue-66-implementation/core`,
  commit `d5b544e`, branch `issue-66/implementation`, also not yet merged
  to core's main): adds `core/hooks/{trailer-gate.sh,
  record-fields-gate.sh, handbook-trigger-gate.sh}` — each reads
  `CLAUDE_ROLE` from the environment at runtime and derives its message
  prefix from it (no per-role literal). Registered directly in
  `core/hooks/hooks.json`'s `PreToolUse` block on matcher `.*`, so they
  fire for **every** plugin install automatically — a rulebook no longer
  needs its own `hooks.json` entry for any of the three.
  Also adds `core/hooks/lib/role-directive.sh` (a sourceable function
  `core_role_directive <you_decide> <use_when> <produces> <hand_off>` that
  renders the fixed preamble) and `core/hooks/tests/stub-check.sh` (fails
  if a rulebook still has its own copy of any of the four filenames under
  `hooks/`, or if `directive.sh` isn't the exact source+call stub shape).

**Important**: both core commits are only on their respective feature
branches (`issue-63/implementation`, `issue-66/implementation`), one commit
ahead of `origin/main` each, in a *different* repo (`tokenmaxxxer/core`,
not this one). Per contract v3, "the board is what is merged to main" —
this repo's transition should not assume those branches are already on
core's main; it depends on them landing there. Flagged as an open question
in the proposal.

## Findings

1. **trailer-gate.sh** is a true byte-for-byte-except-role-token copy in
   this repo too (confirmed by direct read) — safe to delete outright per
   core's `stub-check.sh` expectation.

2. **handbook-trigger-gate.sh** here is an unimplemented placeholder
   (`exit 0`, marked `TODO before this repo is treated as load-bearing`).
   Deleting it in favor of core's real implementation is a strict
   improvement, not a functionality loss.

3. **record-fields-gate.sh divergence** (the one substantive finding):
   this repo's local copy does NOT check the same thing core's promoted
   version checks. Core's `record-fields-gate.sh` (issue-66) enforces
   contract §20's *structural* minimum — a what-was-done section, a why
   section, upstream basis, `loop_state`, open-findings, and (when
   `loop_state` is non-terminal) next-steps + resolution path — configurable
   per-role only via `RECORD_FIELDS_TERMINAL_STATES` (default `landed`).
   This repo's local copy instead checks a fixed, different field list —
   this role's own `produces` triad: `communications-plan`, `key-message`,
   `risk-qa-prep`. These are not the same requirement; removing the local
   copy in favor of core's drops the produces-triad check entirely, since
   core's canon has no hook for role-specific `produces` content. Core's
   own issue-66 record acknowledges it found real per-role semantic
   divergence in this exact file (terminal-state sets) and deliberately
   did not silently collapse it — but the produces-triad check goes
   further than terminal-state config can express (it is a different
   field list, not a different terminal-state set). This is a genuine gap
   in what canon promotion covers versus what this role's local gate did,
   named as the proposal's open question rather than silently dropped.

4. **RECORD_FIELDS_TERMINAL_STATES**: current directive.sh implies this
   role's own record's terminal `loop_state` is `landed` (matches core's
   default) — no divergence found on this axis, so no override needed for
   item 4 of the issue's task list (finding: no explicit override
   required, default suffices).

5. **directive.sh stub shape**: core's `core_role_directive` takes exactly
   4 positional values (`you_decide`, `use_when`, `produces`, `hand_off`)
   and renders `RECORD: ...` itself — it has no parameter for the current
   directive's `WRITE_SCOPE` line or `BOUNDARY CASE` paragraph. Converting
   to the stub form means either folding `WRITE_SCOPE`/`BOUNDARY CASE`
   into one of the four existing string args, or losing those two lines.
   Flagged as a second open question.

## Stub-check dry run (informational, not yet executed against this repo)

`core/hooks/tests/stub-check.sh`, read from the issue-66 commit, would
currently FAIL against this repo's `hooks/` tree on all three gate
filenames (vendored copies present) and on `directive.sh` (current form
has case statements / guards beyond the stub shape — regrown boilerplate
by the detector's own definition). This confirms the issue's premise: this
repo is exactly the drift the detector exists to catch.
