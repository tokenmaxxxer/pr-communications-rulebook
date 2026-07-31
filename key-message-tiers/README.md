# key-message-tiers

Claude Code plugin that owns the **3-tier key message methodology** for PR
communications: exactly **1 core message**, supporting messages, and
**proof points** backing each key message.

## Phase-2 only

This plugin only applies during phase-2 (drafting). It does not participate
in phase-1 norms, because actual key message text does not exist until
phase-2 drafting begins — there is nothing for this methodology to check
before that point.

## The gate rule

The `PreToolUse` hook (`hooks/key-message-gate.sh`) runs on every `Write`/`Edit`
and inspects the target file only when it matches
`docs/issue-*/reports/pr-communications.md`. It is a no-op for any other path.

For a matching file:

1. If `loop_state: landed` is not present, the gate exits 0 (pass-through —
   not yet in a terminal state relevant to this check).
2. Once `loop_state: landed` is present:
   - A `## Key message` heading must exist, or the gate rejects
     (`missing '## Key message'`).
   - Within that section (from the `## Key message` heading to the next
     `## ` heading or end of file), the case-insensitive phrase
     "Core message" must occur **exactly once**:
     - 0 occurrences → rejects (`no Core message found`).
     - 2+ occurrences → rejects (`N core messages found, 3-tier structure
       requires exactly 1`).
   - The same section must contain **at least 1** case-insensitive
     occurrence of "Proof point", or the gate rejects (`no Proof point found
     for any key message`).
3. If all checks pass, the gate exits 0.

A nonexistent target file path fails closed (non-zero exit) via the script's
`ERR` trap — it is never treated as an automatic pass.

## Manual invocation

```bash
./hooks/key-message-gate.sh <path-to-pr-communications.md>
```

If no `$1` is given, the script reads a `PreToolUse` hook JSON payload from
stdin and extracts `.tool_input.file_path // .tool_input.path` via `jq`.

## Kill switch

Set `KEY_MESSAGE_GATE_DISABLE=1` to skip the gate entirely (prints a notice
to stderr and exits 0). This is an emergency-only escape hatch — use it only
to unblock an urgent landing when the gate itself is broken or the check is
known to be wrong for a specific edge case, and remove the override as soon
as the underlying issue is fixed. Do not leave it set in normal operation.

## Tests

```bash
../tests/key-message-gate-test.sh
```

(or, from the repo root: `tests/key-message-gate-test.sh`)

The suite is self-contained: it creates its own fixtures under `mktemp` and
cleans them up on exit. It covers:

1. PASS — landed state, exactly 1 Core message, at least 1 Proof point.
2. REJECT — missing `## Key message` heading.
3. REJECT — a condition violation (e.g. 2 Core messages) in landed state.
4. PASS-THROUGH — non-landed `loop_state` with the same defects present.
5. FAIL-CLOSED — nonexistent file path passed as `$1`.
