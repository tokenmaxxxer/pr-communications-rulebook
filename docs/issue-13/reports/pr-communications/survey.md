---
subject: issue-13
role: pr-communications
loop_state: scope-proposed
---

# Survey — gate A+ re-audit residual defects (issue-13)

## Preconditions (confirmed landed on their own mains)

- core #75 (`tokenmaxxxer-core` PR #77, MERGED): mandatory `||`-guarded
  `gate-lib.sh` source, `compliance-check.sh` detection rule for an
  unguarded source line, a missing-core deny test case, and
  `gate_bash_write_targets` ported to `gate-lib.py`.
- on-the-record #182 (`on-the-record` PR #185, MERGED): `spawn_cmd()`
  injects `CLAUDE_PLUGIN_ROOT_CORE` from the already-resolved core entry;
  a missing core entry now warns instead of silently falling through to
  an unresolvable relative fallback.

Both confirmed via `gh pr view --json state,mergedAt` against their own
repos' checked-out worktrees. This role's three gates already source
`gate-lib.sh`/`gate-lib.py` (issue-10, landed `5171205`) — the work here
is applying core #75's now-finalized guard form and closing the specific
defects the 2026-08-01 re-audit named, not a fresh gate-lib migration.

## Findings

### F1 — unguarded `gate-lib.sh` source in all three gates (issue 요구 1, common)

`key-message-gate.sh:19`, `qa-preapproval-gate.sh:19`,
`race-sequence-gate.sh:18` all read:

```sh
. "${CLAUDE_PLUGIN_ROOT_CORE:-...}/hooks/lib/gate-lib.sh"
```

with no `||` guard on the same line — exactly the issue-75-confirmed
defect: a failed source runs no code (including no `gate_*` function
definitions), so the very next line, `gate_trap_fail_closed`, itself
errors "command not found" and every downstream
`gate_kill_switch_active ... || { exit 0; }` call site is never reached —
the gate silently fails open on a missing/unreachable core. Reproduced by
running core's own `compliance-check.sh` against each hooks dir:

```
$ compliance-check.sh key-message-tiers/hooks
FAIL — key-message-gate.sh: sources gate-lib.sh with no || guard ...
$ compliance-check.sh qa-preapproval/hooks
FAIL — qa-preapproval-gate.sh: sources gate-lib.sh with no || guard ...
$ compliance-check.sh race-sequence/hooks
FAIL — race-sequence-gate.sh: sources gate-lib.sh with no || guard ...
```

### F2 — same defect class in `pr-communications/hooks/directive.sh`, outside compliance-check's scan (common, related to 요구 1)

`pr-communications/hooks/directive.sh:5` sources
`core/hooks/lib/role-directive.sh` with the identical unguarded form. It
is not a `*-gate.sh` file, so `compliance-check.sh`'s filename-scoped scan
(`find ... -name '*-gate.sh'`) never sees it, but the failure mode is
identical: an unreachable core silently no-ops the SessionStart directive
instead of surfacing the problem. core #75's confirmed fix applies to any
`gate-lib.sh`/`role-directive.sh` source line, not only ones inside a
`*-gate.sh` file — compliance-check's naming filter is a coverage gap in
the detector, not evidence the defect is scoped to gates only.

### F3 — `qa-preapproval-gate.sh`'s pre-approval regex matches its own negation (issue 요구 1, 'NOT pre-approved')

`qa-preapproval-gate.sh:129`:

```python
APPROVED_RE = re.compile(r'pre-approved|사전\s*승인', re.I)
```

is a bare substring search with no negation guard. A draft answer whose
approver note literally reads "NOT pre-approved" (a real rejection,
explicitly recorded as such) satisfies this regex and the gate treats the
pair as approved — the exact opposite of the note's meaning. This is a
false-negative on the gate's core job: the one case it exists to catch
(an unapproved draft answer) is silently waved through when the record
happens to spell out the rejection in words containing the substring.

### F4 — missing-core test case absent from all three test files (issue 요구 3)

None of `tests/{key-message,qa-preapproval,race-sequence}-gate-test.sh`
exercises `CLAUDE_PLUGIN_ROOT_CORE` pointed at a nonexistent path with no
valid relative fallback (core #75's mandatory case group 7). All three
files exercise cases 1-6 (replace_all/MultiEdit, malformed JSON,
kill-switch unrecognized value, absolute/`./`-prefixed path, Bash-tool
write) but stop there — confirmed by `grep -n
"missing-core\|CLAUDE_PLUGIN_ROOT_CORE\|nonexistent"` against all three
files (only case-5 first-write-nonexistent-target and the harness's own
`CLAUDE_PLUGIN_ROOT_CORE` env passthrough appear, no case-7 fixture).
Once F1 is fixed, nothing currently proves it stays fixed under test.

### F5 — no "harmless Bash command" allow-path regression test (issue 요구 1, '무해 Bash allow')

The `Bash` matcher (added issue-10) means every Bash tool call the user
runs now invokes all three gates. Each gate's Python payload correctly
`sys.exit(0)`s when no `gate_bash_write_targets` token resolves to the
tracked record path (verified by reading the code path at
`key-message-gate.sh:94-100` and its siblings), but no test asserts an
ordinary command (e.g. `git status`, `ls docs/`) reaches that pass-through
and is not denied — the only existing Bash case (`tests/*-gate-test.sh`
case 12) is a Bash write that *should* deny. A regression in the token
scan or the match logic that turned harmless commands into wholesale Bash
denial would currently go undetected.

### F6 — hooks.json matcher coverage: no defect found

All three plugins' `hooks.json` (`key-message-tiers`, `qa-preapproval`,
`race-sequence`) already use `"matcher": "Write|Edit|MultiEdit|Bash"`,
matching exactly the four tool branches each gate's Python payload
handles (`Write`/`Edit`/`MultiEdit` reconstructed, `Bash` token-scanned,
else `sys.exit(0)`). `pr-communications/hooks.json` carries no PreToolUse
entry (no gate lives there). Re-confirmed clean; issue 요구 2 needs no
code change, only the compliance/test evidence tying the two together
(folded into the phase-2 exit criteria below).

### F7 — README/manifest ghost files: no defect found, one stale claim to correct

Cross-referencing every backticked `*.sh`/`*.md`/`*.json` path across the
five READMEs and four `plugin.json`s against the actual tree finds no
reference to a file that does not exist, and no leftover old role/plugin
name (issue-10's survey already established this and issue-13's re-audit
does not name a new instance). One accuracy gap, not a ghost file: all
three sibling READMEs (`race-sequence`, `key-message-tiers`,
`qa-preapproval`) currently claim their test suite "covers every
mandatory case from `gate-house-standard.md`" naming six cases — the
standard now has seven (core #75 added case 7, missing-core). Once F4 is
closed this claim becomes literally true again only if the READMEs are
updated to say seven, not six — otherwise the fix and the doc drift apart
a second time the moment the next case is added upstream.

## Scope note

F1-F5 are concrete defects with a reproducible fail case each. F6-F7 are
verification findings (already correct) carried into the proposal as
exit-criteria evidence, per issue 요구 2-4's explicit ask for "정합"/"잔재
0" as a checked state, not only a code diff.
