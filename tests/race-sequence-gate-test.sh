#!/usr/bin/env bash
# Test suite for race-sequence/hooks/race-sequence-gate.sh.
#
# The gate now reads the full PreToolUse JSON payload on stdin (gate-lib.sh
# adoption, issue-10) instead of a bare relative-path argument, so every
# case here builds a real tool_use-shaped payload.
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
gate="${repo_root}/race-sequence/hooks/race-sequence-gate.sh"
core_root="${CLAUDE_PLUGIN_ROOT_CORE:-/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core}"

workdir="$(mktemp -d)"
cleanup() { rm -rf "$workdir"; }
trap cleanup EXIT

fail_count=0
report() {
  local case_name="$1" expected="$2" actual="$3"
  if [[ "$expected" == "$actual" ]]; then
    echo "PASS: ${case_name}"
  else
    echo "FAIL: ${case_name} (expected exit-behavior=${expected}, got=${actual})"
    fail_count=$((fail_count + 1))
  fi
}

mkdir -p "${workdir}/docs/issue-1/reports"

run_gate() { # <json>
  printf '%s' "$1" | env CLAUDE_PROJECT_DIR="$workdir" CLAUDE_PLUGIN_ROOT_CORE="$core_root" "$gate"
}
run_gate_env() { # <json> <env-assignment...>
  local json="$1"; shift
  printf '%s' "$json" | env CLAUDE_PROJECT_DIR="$workdir" CLAUDE_PLUGIN_ROOT_CORE="$core_root" "$@" "$gate"
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

f="${workdir}/docs/issue-1/reports/pr-communications.md"

CASE1='loop_state: landed

## Communications plan

**Research**
Current state summary.

**Action**
Concrete next actions.

**Communication**
Channel and timing confirmed.

**Evaluation**
Success criteria defined before send.
'

# Case 1: PASS - correct order, landed
printf '%s' "$CASE1" > "$f"
rc=0; run_gate "$(j_write "$f" "$CASE1")" >/dev/null 2>&1 || rc=$?
report "PASS - correct RACE order, landed" "0" "$rc"

# Case 2: REJECT - missing Communications plan heading
CASE2='loop_state: landed

**Research**
Current state summary.

**Action**
Concrete next actions.

**Communication**
Channel and timing confirmed.

**Evaluation**
Success criteria defined before send.
'
rc=0; run_gate "$(j_write "$f" "$CASE2")" >/dev/null 2>&1 || rc=$?
[[ "$rc" != "0" ]] && report "REJECT - missing Communications plan heading" "nonzero" "nonzero" \
  || report "REJECT - missing Communications plan heading" "nonzero" "0"

# Case 3: REJECT - order violation, Evaluation before Communication
CASE3='loop_state: landed

## Communications plan

**Research**
Current state summary.

**Action**
Concrete next actions.

**Evaluation**
Success criteria defined before send.

**Communication**
Channel and timing confirmed.
'
rc=0; run_gate "$(j_write "$f" "$CASE3")" >/dev/null 2>&1 || rc=$?
[[ "$rc" != "0" ]] && report "REJECT - Evaluation before Communication" "nonzero" "nonzero" \
  || report "REJECT - Evaluation before Communication" "nonzero" "0"

# Case 4: PASS-THROUGH - scope-proposed, with all defects present
CASE4='loop_state: scope-proposed

**Evaluation**
Success criteria defined before send.

**Communication**
Channel and timing confirmed.
'
rc=0; run_gate "$(j_write "$f" "$CASE4")" >/dev/null 2>&1 || rc=$?
report "PASS-THROUGH - non-terminal loop_state (scope-proposed)" "0" "$rc"

# Case 5: FAIL-CLOSED - Edit against a nonexistent target file
rm -f "$f"
rc=0; run_gate "$(j_edit "$f" "x" "y" 0)" >/dev/null 2>&1 || rc=$?
[[ "$rc" != "0" ]] && report "FAIL-CLOSED - nonexistent target" "nonzero" "nonzero" \
  || report "FAIL-CLOSED - nonexistent target" "nonzero" "0"

# Case 6 (structural-upgrade regression): the four labels appear as bolded
# words inside prose, not as top-level section entries — the OLD
# whole-document grep would have accepted this; the new scoped/anchored
# check must deny it.
CASE6='loop_state: landed

## Communications plan

We ran **Research** earlier and then took **Action** on it. Only after
that did **Communication** happen, and **Evaluation** was defined last,
all inside one paragraph rather than as its own labeled entry.
'
printf '%s' "$CASE6" > "$f"
rc=0; run_gate "$(j_write "$f" "$CASE6")" >/dev/null 2>&1 || rc=$?
[[ "$rc" != "0" ]] && report "REGRESSION - bolded words in prose, not top-level entries, must FAIL" "nonzero" "nonzero" \
  || report "REGRESSION - bolded words in prose, not top-level entries, must FAIL" "nonzero" "0"

# Case 7: Edit with replace_all: true against a multiply-occurring old_string.
REPEATED='loop_state: landed

before section: OK.

## Communications plan

**Research**
Current state summary.

**Action**
Concrete next actions.

**Communication**
Channel and timing confirmed.

**Evaluation**
Success criteria defined before send.

after section: OK.
'
printf '%s' "$REPEATED" > "$f"
rc=0; run_gate "$(j_edit "$f" "OK." "OK, confirmed." 1)" >/dev/null 2>&1 || rc=$?
report "replace_all:true - reconstructs every occurrence and passes" "0" "$rc"

# Case 8: MultiEdit with mixed replace_all true/false in one call.
printf '%s' "$CASE1" > "$f"
edits='[{"old_string":"Current state summary.","new_string":"Current state summary (confirmed).","replace_all":false},{"old_string":"Channel and timing confirmed.","new_string":"Channel and timing confirmed.","replace_all":true}]'
rc=0; run_gate "$(j_multiedit "$f" "$edits")" >/dev/null 2>&1 || rc=$?
report "MultiEdit mixed replace_all - still passes" "0" "$rc"

# Case 9: malformed JSON — truncated, non-object, empty — all deny.
rc=0; printf '%s' '{"tool_name":"Write"' | env CLAUDE_PROJECT_DIR="$workdir" CLAUDE_PLUGIN_ROOT_CORE="$core_root" "$gate" >/dev/null 2>&1 || rc=$?
[[ "$rc" != "0" ]] && report "malformed JSON (truncated) denies" "nonzero" "nonzero" \
  || report "malformed JSON (truncated) denies" "nonzero" "0"
rc=0; printf '%s' '"just a string"' | env CLAUDE_PROJECT_DIR="$workdir" CLAUDE_PLUGIN_ROOT_CORE="$core_root" "$gate" >/dev/null 2>&1 || rc=$?
[[ "$rc" != "0" ]] && report "malformed JSON (non-object) denies" "nonzero" "nonzero" \
  || report "malformed JSON (non-object) denies" "nonzero" "0"
rc=0; printf '%s' '' | env CLAUDE_PROJECT_DIR="$workdir" CLAUDE_PLUGIN_ROOT_CORE="$core_root" "$gate" >/dev/null 2>&1 || rc=$?
[[ "$rc" != "0" ]] && report "malformed JSON (empty) denies" "nonzero" "nonzero" \
  || report "malformed JSON (empty) denies" "nonzero" "0"

# Case 10: kill switch set to an unrecognized value stays ACTIVE.
printf '%s' "$CASE3" > "$f"
rc=0; run_gate_env "$(j_write "$f" "$CASE3")" env RACE_SEQUENCE_GATE_DISABLE=banana >/dev/null 2>&1 || rc=$?
[[ "$rc" != "0" ]] && report "kill-switch unrecognized value stays ACTIVE" "nonzero" "nonzero" \
  || report "kill-switch unrecognized value stays ACTIVE" "nonzero" "0"
rc=0; run_gate_env "$(j_write "$f" "$CASE3")" env RACE_SEQUENCE_GATE_DISABLE=1 >/dev/null 2>&1 || rc=$?
report "kill-switch '1' disables (sanity check)" "0" "$rc"

# Case 11: absolute file_path and ./-prefixed variant get the same verdict
# a relative-path fixture already gets.
printf '%s' "$CASE1" > "$f"
rc=0; run_gate "$(j_write "$f" "$CASE1")" >/dev/null 2>&1 || rc=$?
report "absolute file_path resolves to the same target and passes" "0" "$rc"
rel="./docs/issue-1/reports/pr-communications.md"
rc=0; (cd "$workdir" && run_gate "$(j_write "$rel" "$CASE1")") >/dev/null 2>&1 || rc=$?
report "./-prefixed file_path resolves to the same target and passes" "0" "$rc"

# Case 12: a Bash-tool write reaching the same target a Write-tool fixture
# already exercises gets evaluated too (post-write, on-disk content).
printf '%s' "$CASE3" > "$f"
rc=0; run_gate "$(j_bash "cat > ${f} <<'CASEEOF'
$CASE3
CASEEOF")" >/dev/null 2>&1 || rc=$?
[[ "$rc" != "0" ]] && report "Bash-tool write to the same target denies on the same defect" "nonzero" "nonzero" \
  || report "Bash-tool write to the same target denies on the same defect" "nonzero" "0"

# Case 13 (missing-core, gate-house-standard.md case group 7): core
# unreachable via both CLAUDE_PLUGIN_ROOT_CORE and the relative ../../core
# fallback -> fail closed (exit 2, not silent allow/crash).
printf '%s' "$CASE1" > "$f"
missing_core_out="$(printf '%s' "$(j_write "$f" "$CASE1")" | env CLAUDE_PROJECT_DIR="$workdir" CLAUDE_PLUGIN_ROOT_CORE="/nonexistent/path" "$gate" 2>&1)"
rc=$?
if [[ "$rc" -eq 2 ]] && grep -q "cannot source gate-lib.sh" <<<"$missing_core_out"; then
  report "missing-core - fails closed with exit 2 and source-failure message" "0" "0"
else
  report "missing-core - fails closed with exit 2 and source-failure message" "0" "1 (status=$rc, out=$missing_core_out)"
fi

# Case 14 (harmless Bash allow): an ordinary Bash command touching no path
# resolving to docs/issue-*/reports/pr-communications.md passes through.
rc=0; run_gate "$(j_bash "git status")" >/dev/null 2>&1 || rc=$?
report "harmless Bash command (git status) passes through" "0" "$rc"

echo "---"
if [[ "$fail_count" -eq 0 ]]; then
  echo "ALL CASES PASSED"
  exit 0
else
  echo "${fail_count} CASE(S) FAILED"
  exit 1
fi
