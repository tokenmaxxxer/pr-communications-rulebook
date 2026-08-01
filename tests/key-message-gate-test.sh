#!/usr/bin/env bash
# Test suite for key-message-tiers/hooks/key-message-gate.sh.
#
# The gate now reads the full PreToolUse JSON payload on stdin (gate-lib.sh
# adoption, issue-10) instead of a bare relative-path argument, so every
# case here builds a real tool_use-shaped payload.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GATE="$REPO_ROOT/key-message-tiers/hooks/key-message-gate.sh"
CORE_ROOT="${CLAUDE_PLUGIN_ROOT_CORE:-/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core}"

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

FAILED=0
pass_case() { echo "PASS: $1"; }
fail_case() { echo "FAIL: $1"; FAILED=1; }

mkdir -p "$WORKDIR/docs/issue-1/reports"
cd "$WORKDIR"

run_gate() { # <json> [env...]
  local json="$1"; shift
  printf '%s' "$json" | env CLAUDE_PROJECT_DIR="$WORKDIR" CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" "$@" "$GATE"
}

j_write() { python3 -c '
import json, sys
print(json.dumps({"tool_name": "Write", "tool_input": {"file_path": sys.argv[1], "content": sys.argv[2]}}))
' "$1" "$2"; }

j_edit() { python3 -c '
import json, sys
print(json.dumps({"tool_name": "Edit", "tool_input": {
    "file_path": sys.argv[1], "old_string": sys.argv[2], "new_string": sys.argv[3],
    "replace_all": sys.argv[4] == "1"}}))
' "$1" "$2" "$3" "$4"; }

j_multiedit() { python3 -c '
import json, sys
edits = json.loads(sys.argv[2])
print(json.dumps({"tool_name": "MultiEdit", "tool_input": {"file_path": sys.argv[1], "edits": edits}}))
' "$1" "$2"; }

j_bash() { python3 -c '
import json, sys
print(json.dumps({"tool_name": "Bash", "tool_input": {"command": sys.argv[1]}}))
' "$1"; }

GOOD='loop_state: landed

## Key message

**Core message**: ship it.
**Proof point**: benchmark shows 2x speedup.

**Supporting message**: it is fast.
**Proof point**: another proof.

## Other section
'

f1="docs/issue-1/reports/pr-communications.md"
printf '%s' "$GOOD" > "$f1"

# Case 1: PASS - valid landed key message section (Write, re-affirming content)
if run_gate "$(j_write "$f1" "$GOOD")" >/dev/null 2>&1; then
  pass_case "1 PASS - valid landed key message section"
else
  fail_case "1 PASS - valid landed key message section (expected exit 0)"
fi

# Case 2: REJECT - missing '## Key message' heading
BAD2='loop_state: landed

## Some other heading

**Core message**: ship it.
**Proof point**: works.
'
if run_gate "$(j_write "$f1" "$BAD2")" >/dev/null 2>&1; then
  fail_case "2 REJECT - missing '## Key message' heading (expected non-zero)"
else
  pass_case "2 REJECT - missing '## Key message' heading"
fi

# Case 3: REJECT - 2 core message headings
BAD3='loop_state: landed

## Key message

**Core message**: ship it.
**Proof point**: a.
**Core message**: ship it faster.
**Proof point**: b.

## Other section
'
if run_gate "$(j_write "$f1" "$BAD3")" >/dev/null 2>&1; then
  fail_case "3 REJECT - 2 core messages (expected non-zero)"
else
  pass_case "3 REJECT - 2 core messages"
fi

# Case 4: PASS-THROUGH - non-landed loop_state with the same defects present
BAD4='loop_state: scope-proposed

## Key message

**Core message**: ship it.
**Core message**: ship it faster.

## Other section
'
if run_gate "$(j_write "$f1" "$BAD4")" >/dev/null 2>&1; then
  pass_case "4 PASS-THROUGH - non-landed loop_state with defects present"
else
  fail_case "4 PASS-THROUGH - non-landed loop_state with defects present (expected exit 0)"
fi

# Case 5: FAIL-CLOSED - Edit against a nonexistent target file
if run_gate "$(j_edit "docs/issue-999/reports/pr-communications.md" "x" "y" 0)" >/dev/null 2>&1; then
  fail_case "5 FAIL-CLOSED - Edit against nonexistent target (expected non-zero)"
else
  pass_case "5 FAIL-CLOSED - Edit against nonexistent target"
fi

# Case 6 (structural-upgrade regression): the words appear in prose but not
# as structural headings/nested proof points — the OLD substring check
# would have passed this; the new structural check must deny it.
BAD6='loop_state: landed

## Key message

This avoids over-claiming in the core message and cites a proof point
elsewhere in the doc, but never actually states one as a tiered entry.

## Other section
'
if run_gate "$(j_write "$f1" "$BAD6")" >/dev/null 2>&1; then
  fail_case "6 REGRESSION - word mention without structure must now FAIL (expected non-zero)"
else
  pass_case "6 REGRESSION - word mention without structure now correctly denied"
fi

# Case 7: Edit with replace_all: true against a multiply-occurring old_string.
printf '%s' "$GOOD" > "$f1"
REPEATED='loop_state: landed

boilerplate: ship it.

## Key message

**Core message**: ship it.
**Proof point**: benchmark.

## Other section

boilerplate: ship it.
'
printf '%s' "$REPEATED" > "$f1"
if run_gate "$(j_edit "$f1" "ship it." "ship it now." 1)" >/dev/null 2>&1; then
  pass_case "7 replace_all:true - reconstructs every occurrence and passes"
else
  fail_case "7 replace_all:true - reconstructs every occurrence and passes (expected exit 0)"
fi

# Case 8: MultiEdit with mixed replace_all true/false in one call.
printf '%s' "$GOOD" > "$f1"
edits='[{"old_string":"ship it.","new_string":"ship it now.","replace_all":false},{"old_string":"Proof point","new_string":"Proof point","replace_all":true}]'
if run_gate "$(j_multiedit "$f1" "$edits")" >/dev/null 2>&1; then
  pass_case "8 MultiEdit mixed replace_all - still recognized as structurally valid"
else
  fail_case "8 MultiEdit mixed replace_all - still recognized as structurally valid (expected exit 0)"
fi

# Case 9: malformed JSON — truncated, non-object, empty — all deny.
if printf '%s' '{"tool_name":"Write"' | env CLAUDE_PROJECT_DIR="$WORKDIR" CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" "$GATE" >/dev/null 2>&1; then
  fail_case "9a malformed JSON (truncated) denies (expected non-zero)"
else
  pass_case "9a malformed JSON (truncated) denies"
fi
if printf '%s' '"just a string"' | env CLAUDE_PROJECT_DIR="$WORKDIR" CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" "$GATE" >/dev/null 2>&1; then
  fail_case "9b malformed JSON (non-object) denies (expected non-zero)"
else
  pass_case "9b malformed JSON (non-object) denies"
fi
if printf '%s' '' | env CLAUDE_PROJECT_DIR="$WORKDIR" CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" "$GATE" >/dev/null 2>&1; then
  fail_case "9c malformed JSON (empty) denies (expected non-zero)"
else
  pass_case "9c malformed JSON (empty) denies"
fi

# Case 10: kill switch set to an unrecognized value stays ACTIVE (still
# denies the same BAD3 content it would deny with the switch unset).
printf '%s' "$BAD3" > "$f1"
if run_gate "$(j_write "$f1" "$BAD3")" env KEY_MESSAGE_GATE_DISABLE=banana >/dev/null 2>&1; then
  fail_case "10 kill-switch unrecognized value stays ACTIVE (expected non-zero, same as unset)"
else
  pass_case "10 kill-switch unrecognized value stays ACTIVE"
fi
if run_gate "$(j_write "$f1" "$BAD3")" env KEY_MESSAGE_GATE_DISABLE=1 >/dev/null 2>&1; then
  pass_case "10b kill-switch '1' disables (sanity check)"
else
  fail_case "10b kill-switch '1' disables (expected exit 0, sanity check)"
fi

# Case 11: absolute file_path and ./-prefixed variant get the same verdict
# a relative-path fixture already gets.
printf '%s' "$GOOD" > "$f1"
abs="$WORKDIR/$f1"
if run_gate "$(j_write "$abs" "$GOOD")" >/dev/null 2>&1; then
  pass_case "11a absolute file_path resolves to the same target and passes"
else
  fail_case "11a absolute file_path resolves to the same target and passes (expected exit 0)"
fi
if run_gate "$(j_write "./$f1" "$GOOD")" >/dev/null 2>&1; then
  pass_case "11b ./-prefixed file_path resolves to the same target and passes"
else
  fail_case "11b ./-prefixed file_path resolves to the same target and passes (expected exit 0)"
fi

# Case 12: a Bash-tool write reaching the same target a Write-tool fixture
# already exercises gets evaluated too (post-write, on-disk content).
printf '%s' "$BAD3" > "$f1"
if run_gate "$(j_bash "cat > $f1 <<'EOF'
$BAD3
EOF")" >/dev/null 2>&1; then
  fail_case "12 Bash-tool write to the same target denies on the same defect (expected non-zero)"
else
  pass_case "12 Bash-tool write to the same target denies on the same defect"
fi

# Case 13 (missing-core, gate-house-standard.md case group 7): core
# unreachable via both CLAUDE_PLUGIN_ROOT_CORE and the relative ../../core
# fallback -> fail closed (exit 2, not silent allow/crash).
printf '%s' "$GOOD" > "$f1"
missing_core_out="$(cd "$WORKDIR" && printf '%s' "$(j_write "$f1" "$GOOD")" | env CLAUDE_PROJECT_DIR="$WORKDIR" CLAUDE_PLUGIN_ROOT_CORE="/nonexistent/path" "$GATE" 2>&1)"
missing_core_status=$?
if [[ "$missing_core_status" -eq 2 ]] && grep -q "cannot source gate-lib.sh" <<<"$missing_core_out"; then
  pass_case "13 missing-core - fails closed with exit 2 and source-failure message"
else
  fail_case "13 missing-core - fails closed with exit 2 and source-failure message (got status=$missing_core_status, out=$missing_core_out)"
fi

# Case 14 (harmless Bash allow): an ordinary Bash command touching no path
# resolving to docs/issue-*/reports/pr-communications.md passes through.
if run_gate "$(j_bash "git status")" >/dev/null 2>&1; then
  pass_case "14 harmless Bash command (git status) passes through"
else
  fail_case "14 harmless Bash command (git status) passes through (expected exit 0)"
fi

if [[ "$FAILED" -eq 0 ]]; then
  echo "All test cases passed."
  exit 0
else
  echo "One or more test cases failed."
  exit 1
fi
