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

`hooks/key-message-gate.sh` sources `core/hooks/lib/gate-lib.sh`/`gate-lib.py`
(the gate-house standard, core issue-72) instead of hand-rolling the
trap/kill-switch/path-normalize/reconstruct machinery — see core's own
`docs/handbooks/gate-house-standard.md` (this repo carries no local copy).
The `PreToolUse` hook
(`hooks.json` matcher `Write|Edit|MultiEdit|Bash`) reads the full tool-call
JSON payload on stdin and acts only when the resolved target normalizes
(via `gate_normalize_path`, absolute/relative/`./`-prefixed all alike) to
`docs/issue-<n>/reports/pr-communications.md`. It is a no-op for any other
path or tool.

For a matching write:

1. The gate reconstructs the **resulting** content — not what's currently
   on disk — via `gate_reconstruct_write`: `Write`'s `content` verbatim,
   `Edit`'s `old_string`/`new_string` (honoring `replace_all`), or
   `MultiEdit`'s ordered edit list (each edit's own `replace_all` honored
   independently). A `Bash`-tool write to the same target is matched via
   `gate_bash_write_targets`, but checked against on-disk content — a
   shell heredoc carries no `tool_input.content` to reconstruct from, so
   this one path stays a post-write check by necessity, not by omission.
   An `Edit`/`MultiEdit` whose `old_string` cannot be found, or a `Write`
   that doesn't yet exist as a first-time create, are handled explicitly —
   a first `Write` of a brand-new file is `current = ""`, not a fail-closed
   abort.
2. If the reconstructed content lacks `loop_state: landed`, the gate exits
   0 (pass-through — not yet in a terminal state relevant to this check).
3. Once `loop_state: landed` is present, within the `## Key message`
   section (heading to the next `## ` heading or end of file):
   - Exactly **one** `**Core message**:` heading line must be present —
     the words "core message" appearing in prose, with no such heading,
     does not count (this is the structural upgrade over a bare substring
     count, issue-10).
   - Every message heading (`**Core message**:` / `**Supporting
     message**:`) must have at least one `**Proof point**:` line **nested
     under it** (between that heading and the next one) — a proof point
     floating elsewhere in the section does not count for any message.
4. If all checks pass, the gate exits 0.

A target that cannot be reconstructed, or malformed JSON on stdin, fails
closed (exit 2) via `gate_trap_fail_closed` — never treated as an
automatic pass.

## Manual invocation

```bash
echo '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-1/reports/pr-communications.md","content":"..."}}' \
  | ./hooks/key-message-gate.sh
```

The gate always reads the `PreToolUse` hook's JSON payload from stdin
(`tool_name` + `tool_input`) — there is no longer a bare-path `$1` form.

## Kill switch

Set `KEY_MESSAGE_GATE_DISABLE` to `1`/`true`/`yes`/`on` (case-insensitive)
to skip the gate entirely (prints a notice to stderr and exits 0). Any
other value — including unset, a recognized off-spelling, or an
unrecognized typo — leaves the gate **active** (`gate_kill_switch_active`).
This is an emergency-only escape hatch — use it only to unblock an urgent
landing when the gate itself is broken or the check is known to be wrong
for a specific edge case, and remove the override as soon as the
underlying issue is fixed. Do not leave it set in normal operation.

## Tests

```bash
../tests/key-message-gate-test.sh
```

(or, from the repo root: `tests/key-message-gate-test.sh`)

The suite is self-contained: it creates its own fixtures under `mktemp` and
cleans them up on exit, building the JSON payload itself pipes on stdin. It
covers the happy/sad path cases plus every mandatory case from
`gate-house-standard.md`: `Edit`/`MultiEdit` with `replace_all`, malformed
JSON, a kill-switch set to an unrecognized value, absolute/`./`-prefixed
paths, a `Bash`-tool write, a structural-upgrade regression case (a
word mention with no heading, which the old substring check would have
passed), and a missing-core case (core unreachable via both the
`CLAUDE_PLUGIN_ROOT_CORE` override and the relative `../../core`
fallback, which must fail closed with exit 2).
