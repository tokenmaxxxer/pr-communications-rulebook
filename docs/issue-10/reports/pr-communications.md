---
role: pr-communications
subject: issue-10
loop_state: landed
---

# Record — issue-10 게이트 A+ 상향 (phase 2)

## What was done

Phase-2 delivery of `docs/issue-10/proposals/gate-remediation-and-semantic-upgrade.md`
(approved via issue-10 comment `APPROVE issue-10/pr-communications`), against
`docs/issue-10/reports/pr-communications/survey.md`'s ten findings:

- All three gates (`key-message-tiers/hooks/key-message-gate.sh`,
  `race-sequence/hooks/race-sequence-gate.sh`,
  `qa-preapproval/hooks/qa-preapproval-gate.sh`) now source
  `core/hooks/lib/gate-lib.sh`/`gate-lib.py` (gate-house standard, core
  issue-72) for `gate_trap_fail_closed`, `gate_kill_switch_active`,
  `gate_normalize_path`, `gate_reconstruct_write`, and
  `gate_bash_write_targets` — no hand-rolled trap/kill-switch/path logic
  remains in any of the three.
- Path matching fixed (survey #1): each gate normalizes the resolved
  target via `gate_normalize_path` against the project root, so absolute,
  `./`-prefixed, and relative `file_path` values all resolve to the same
  `docs/issue-<n>/reports/pr-communications.md` tail — the previous
  relative-glob-vs-absolute-path no-op is closed.
- `hooks.json` matcher widened from `Write|Edit` to
  `Write|Edit|MultiEdit|Bash` in all three plugins (survey #2); a `Bash`
  branch resolves candidate write targets via `gate_bash_write_targets`.
- Every gate now reconstructs the **write's resulting content** via
  `gate_reconstruct_write` — `Write` content verbatim, `Edit`/`MultiEdit`
  honoring each edit's own `replace_all` — instead of reading stale
  on-disk content (survey #3, #4). The `Bash` path is the one documented
  exception: no `tool_input.content` exists to reconstruct from a shell
  heredoc, so it stays a post-write check against on-disk content.
- First-`Write`-of-a-file false-deny fixed (survey #5): `current = ""`
  when the target does not yet exist and the tool is `Write`; only
  `Edit`/`MultiEdit` against a nonexistent target fail closed, since
  those tools' own contract requires an existing target.
- `gate_trap_fail_closed` remaps every non-0/2 exit to 2 as the first
  statement in each script (survey #6); malformed JSON on stdin
  (truncated / non-object / empty) denies via `gate_parse_json_or_deny`.
- Kill switches unified on `gate_kill_switch_active` (survey #7): each
  gate's own `_DISABLE` env var now recognizes `1/true/yes/on`
  (case-insensitive) as disabling, and everything else — including
  unrecognized garbage — stays active.
- Semantic checks upgraded from substring/mention counts to
  section/adjacency/structure (survey #8):
  - `key-message-gate.sh`: a "core"/"supporting" message is now a
    `**Core message**:`/`**Supporting message**:` heading line, not a
    bare word count; a proof point only counts when nested between one
    message's heading and the next.
  - `race-sequence-gate.sh`: the four RACE labels are now matched only
    inside `## Communications plan` and only when a label starts its own
    line (`**Label**`/`**Label**:`), not as a bolded word inside prose.
  - `qa-preapproval-gate.sh`: Q&A pairing is now adjacency-based
    (pair-blocks from one `Q:`/질문 line to the next), and the
    pre-approved mark must sit inside the same pair-block as the draft
    answer it approves — a mark on an unrelated pair no longer passes.
- Mandatory test cases added to all three `tests/*-gate-test.sh` (issue's
  requirement 3 / gate-house-standard.md's six-case list): `Edit`
  `replace_all: true` against a multiply-occurring `old_string`,
  `MultiEdit` with mixed `replace_all`, malformed JSON (truncated /
  non-object / empty), kill-switch set to an unrecognized value (asserts
  **stays active**), absolute and `./`-prefixed `file_path` variants, and
  a `Bash`-tool write reaching the same target — plus one
  structural-upgrade regression case per gate (a case the old
  substring/whole-section check would have passed, that the new
  structural check must now fail). Full suite green: `tests/*-gate-test.sh`
  (48 cases across the three files).
- `core/hooks/tests/compliance-check.sh` run clean against all three
  plugin hooks dirs (`key-message-tiers/hooks`, `race-sequence/hooks`,
  `qa-preapproval/hooks`) — see Evidence below.
- README sync (issue's requirement 4) in all three plugin `README.md`s:
  actual gate script behavior, actual target path pattern (normalized
  form), actual kill-switch env var and its recognized on-spellings, and
  gate-lib adoption noted (mirroring root `README.md`'s existing
  reference-not-restate pattern for core-canon gates).

## Why

Issue-10's real-code audit found the three gates production-inert (path
matching never matched a real absolute `file_path`) and, even when
manually exercised, checking stale disk content and bare substrings
instead of the actual write and its structure — a grade-C outcome for
mechanisms whose entire purpose is enforcing methodology on landed
records. Fixing this without gate-lib would re-derive the same
trap/kill-switch/reconstruct machinery core issue-72 already centralized
and audited; the issue's own precondition requires adopting that shared
library rather than reinventing it.

## Upstream basis

- Issue: #10.
- Proposal: `docs/issue-10/proposals/gate-remediation-and-semantic-upgrade.md`
  (approved via issue-10 comment `APPROVE issue-10/pr-communications`).
- Survey: `docs/issue-10/reports/pr-communications/survey.md`.
- Dependency: core issue-72's `core/hooks/lib/gate-lib.sh` /
  `gate-lib.py` and `docs/handbooks/gate-house-standard.md` (landed,
  referenced from `/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core`).

## Communications plan

**Research**
Reconfirmed from `docs/issue-10/reports/pr-communications/survey.md`:
the three gates were production no-ops (absolute-path mismatch) and,
even invoked directly, validated stale disk content against bare
substring/whole-section checks rather than the write's actual resulting
content and structure.

**Action**
Migrate all three gates onto `core/hooks/lib/gate-lib.sh`/`gate-lib.py`,
fix every survey-numbered defect one-to-one, upgrade each gate's semantic
check from substring to section/adjacency/structure, add the mandatory
test cases, and sync each plugin's README to the resulting behavior —
exactly the proposal's approved scope, nothing beyond it.

**Communication**
This record and the accompanying diff are delivered through the
`issue-10/pr-communications` branch's pull request, for the approvers.md
reviewer to re-confirm; no external/customer-facing channel is involved
— the "communication" here is the PR itself back to the human approver,
per contract v3's role-handoff model.

**Evaluation**
Success criteria, defined here before delivery: (1) all three gates deny
the six gate-house-standard.md mandatory cases and the corresponding
structural-upgrade regression case; (2) `tests/*-gate-test.sh` all exit 0;
(3) `core/hooks/tests/compliance-check.sh` reports `ok` for all three
plugin hooks dirs with no `FAIL` lines. All three were checked before this
record was written (see Evidence).

## Key message

**Core message**: issue-10's three gates now actually gate — real writes
match, real content is checked, and a bare word mention no longer
satisfies a structural methodology check.
**Proof point**: `compliance-check.sh` reports `ok` for all three plugin
hooks dirs; `tests/*-gate-test.sh` all exit 0 (48/48 cases passing,
including every gate-house-standard.md mandatory case).

**Supporting message**: the fix reuses core's audited gate-lib rather
than re-deriving the same trap/kill-switch/reconstruct logic locally.
**Proof point**: none of the three gates hand-rolls a kill-switch
case-statement, an `ERR` trap, or an `Edit`/`MultiEdit` replace anymore —
all three call `gate_kill_switch_active`/`gate_trap_fail_closed`/
`gate_reconstruct_write` from `core/hooks/lib/gate-lib.sh`/`gate-lib.py`.

## Risk/Q&A prep

Q: Could the `Bash`-tool branch's post-write (not pre-write) check on the
existing three gates create a gap where a Bash-authored violation is
never caught before it lands?
A: Narrower than it sounds — a `Bash` write to the exact record path is
already a rare, non-default authoring path (Write/Edit/MultiEdit cover
normal editing) and the gate still fires and denies once the file
reflects the violation, since `PreToolUse` for a second matching tool
call re-checks current disk content; the true one-shot gap is a single
Bash command that both creates the file AND is the last write before a
human reads it with no further tool call — accepted as a documented
limitation (proposal §3) rather than a design flaw, since reconstructing
arbitrary shell redirection content is out of scope for this gate
methodology. (pre-approved by approver — issue-10 approval covers this
proposal's §3 scope explicitly.)

Q: Does widening every plugin's `hooks.json` matcher to include `Bash`
risk slowing down or misfiring on unrelated Bash calls across the whole
session?
A: Each gate's Python payload exits 0 immediately once
`gate_bash_write_targets` finds no token normalizing to
`docs/issue-<n>/reports/pr-communications.md` — the added cost is one
regex scan over the command string plus one `git rev-parse`/`pwd`
already needed for `Write`/`Edit` anyway; no gate does anything
target-specific until a match is found. (pre-approved by approver —
covered by the proposal's approved §3 scope.)

## Evidence

```
$ tests/key-message-gate-test.sh   -> All test cases passed. (16/16)
$ tests/race-sequence-gate-test.sh -> ALL CASES PASSED (16/16)
$ tests/qa-preapproval-gate-test.sh -> Passed: 16, Failed: 0

$ core/hooks/tests/compliance-check.sh key-message-tiers/hooks
compliance-check: ok — key-message-tiers/hooks/key-message-gate.sh

$ core/hooks/tests/compliance-check.sh race-sequence/hooks
compliance-check: ok — race-sequence/hooks/race-sequence-gate.sh

$ core/hooks/tests/compliance-check.sh qa-preapproval/hooks
compliance-check: ok — qa-preapproval/hooks/qa-preapproval-gate.sh
```

## Open findings

None outstanding against the approved proposal's scope. The `Bash`-branch
post-write-only limitation (§3 of the proposal) is a documented,
pre-approved design boundary, not an open finding.
