#!/usr/bin/env bash
# key-message-gate.sh
#
# PreToolUse (Write|Edit|MultiEdit|Bash) gate enforcing the 3-tier key
# message structure (1 core message + supporting messages + proof points,
# each proof point nested under its own message) on terminal
# (loop_state: landed) writes to docs/issue-*/reports/pr-communications.md.
#
# Sources core/hooks/lib/gate-lib.sh (docs/handbooks/gate-house-standard.md,
# issue-72) for the fail-closed trap, kill-switch, path-normalize, and
# Edit/MultiEdit reconstruction machinery, instead of hand-rolling any of
# it (issue-10 audit).
#
# Manual invocation for testing: pass the PreToolUse JSON payload on stdin.
#
# Kill switch: KEY_MESSAGE_GATE_DISABLE=1 (or true/yes/on) skips the gate
# entirely (emergency admin escape hatch only — see README.md). Any other
# value, including unrecognized garbage, leaves the gate ACTIVE.
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" \
  || { echo "key-message-gate.sh: cannot source gate-lib.sh" >&2; exit 2; }
gate_trap_fail_closed
set -uo pipefail

GATE_NAME="key-message-gate"
gate_kill_switch_active "${KEY_MESSAGE_GATE_DISABLE:-}" || { trap - EXIT; exit 0; }

command -v python3 >/dev/null 2>&1 || gate_deny "$GATE_NAME" "python3 is required but not on PATH"

root="${CLAUDE_PROJECT_DIR:-}"
[ -n "$root" ] || root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$root" ] || root="$(pwd -P)"

payload="$(cat 2>/dev/null || true)"

GATE_NAME="$GATE_NAME" GATE_PAYLOAD="$payload" GATE_ROOT="$root" GATE_LIB_PY="$GATE_LIB_PY" \
python3 <<'PY'
import sys as _fc_sys  # fail-closed-on-internal-error
try:
    import importlib.util, json, os, re, sys

    NAME = os.environ["GATE_NAME"]

    def deny(msg):
        sys.stderr.write("%s: refused — %s\n" % (NAME, msg))
        sys.exit(2)

    _spec = importlib.util.spec_from_file_location("gate_lib", os.environ["GATE_LIB_PY"])
    gate_lib = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(gate_lib)

    event = gate_lib.gate_parse_json_or_deny(os.environ.get("GATE_PAYLOAD", ""), deny)

    tool = event.get("tool_name")
    ti = event.get("tool_input")
    if not isinstance(ti, dict):
        sys.exit(0)

    root = os.environ["GATE_ROOT"]
    TARGET_RE = re.compile(r'^docs/issue-[0-9]+/reports/pr-communications\.md$')

    def matched_path(p):
        if not isinstance(p, str) or not p:
            return None
        rel = gate_lib.gate_normalize_path(root, p)
        if rel is not None and TARGET_RE.match(rel):
            return os.path.join(root, rel)
        return None

    new_text = None

    if tool in ("Write", "Edit", "MultiEdit"):
        target = matched_path(ti.get("file_path"))
        if target is None:
            sys.exit(0)
        current = ""
        if os.path.isfile(target):
            try:
                with open(target, encoding="utf-8-sig") as fh:
                    current = fh.read(1 << 20)
            except OSError:
                deny("%s exists but cannot be read; failing closed." % target)
        elif tool in ("Edit", "MultiEdit"):
            deny("%s: %s targets a file that does not exist; an Edit/MultiEdit "
                 "requires an existing target." % (NAME, target))
        new_text, ok = gate_lib.gate_reconstruct_write(tool, ti, current)
        if not ok or new_text is None:
            deny("cannot determine the resulting content of this %s "
                 "(old_string not found, or the edit shape is not "
                 "understood) — refusing rather than guessing." % tool)

    elif tool == "Bash":
        command = ti.get("command")
        if not isinstance(command, str):
            sys.exit(0)
        target = None
        for token in gate_lib.gate_bash_write_targets(command):
            target = matched_path(token)
            if target is not None:
                break
        if target is None:
            sys.exit(0)
        if not os.path.isfile(target):
            sys.exit(0)  # nothing on disk yet to check; Bash writes aren't reconstructed (§3)
        try:
            with open(target, encoding="utf-8-sig") as fh:
                new_text = fh.read(1 << 20)
        except OSError:
            deny("%s exists but cannot be read; failing closed." % target)

    else:
        sys.exit(0)

    if not re.search(r'^loop_state:\s*landed\s*$', new_text, re.M):
        sys.exit(0)

    m = re.search(r'^## Key message\s*$', new_text, re.M)
    if not m:
        deny("missing '## Key message' section")

    rest = new_text[m.end():]
    m_next = re.search(r'^## ', rest, re.M)
    section = rest[:m_next.start()] if m_next else rest

    HEADING_RE = re.compile(r'^\*\*(Core message|Supporting message)\*\*\s*:', re.M | re.I)
    PROOF_RE = re.compile(r'^\*\*Proof point\*\*\s*:', re.M | re.I)

    headings = list(HEADING_RE.finditer(section))
    core_headings = [h for h in headings if h.group(1).lower() == "core message"]

    if len(core_headings) == 0:
        deny("no '**Core message**:' heading found in '## Key message' — a bare "
             "mention of the words does not count as a key message entry")
    if len(core_headings) > 1:
        deny("%d '**Core message**:' headings found, 3-tier structure requires "
             "exactly 1" % len(core_headings))

    # Every message block (from its heading to the next heading, or section
    # end) must nest at least one proof point.
    bounds = [h.start() for h in headings] + [len(section)]
    unproven = []
    for i, h in enumerate(headings):
        block = section[bounds[i]:bounds[i + 1]]
        if not PROOF_RE.search(block):
            unproven.append(h.group(1))
    if unproven:
        deny("no '**Proof point**:' found nested under: %s — each key message "
             "needs at least 1 proof point of its own" % ", ".join(unproven))

    sys.exit(0)
except SystemExit:
    raise
except Exception as _fc_e:  # fail-closed-on-internal-error
    _fc_sys.stderr.write("key-message-gate: fail-closed: internal error: %r\n" % (_fc_e,))
    _fc_sys.exit(2)
PY
