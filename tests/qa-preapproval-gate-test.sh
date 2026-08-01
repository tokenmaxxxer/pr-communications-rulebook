#!/usr/bin/env bash
# Test suite for qa-preapproval/hooks/qa-preapproval-gate.sh.
#
# The gate now reads the full PreToolUse JSON payload on stdin (gate-lib.sh
# adoption, issue-10) instead of a bare relative-path argument, so every
# case here builds a real tool_use-shaped payload.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GATE="$REPO_ROOT/qa-preapproval/hooks/qa-preapproval-gate.sh"
CORE_ROOT="${CLAUDE_PLUGIN_ROOT_CORE:-/home/jwjung/tokenmaxxxer/tokenmaxxxer-core/core}"

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

overall=0
pass_count=0
fail_count=0
report() {
  local name="$1" status="$2"
  if [ "$status" -eq 0 ]; then
    echo "PASS: $name"; pass_count=$((pass_count + 1))
  else
    echo "FAIL: $name"; fail_count=$((fail_count + 1)); overall=1
  fi
}

mkdir -p "$WORKDIR/docs/issue-1/reports"
f="$WORKDIR/docs/issue-1/reports/pr-communications.md"

run_gate() { # <json>
  printf '%s' "$1" | env CLAUDE_PROJECT_DIR="$WORKDIR" CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" "$GATE"
}
run_gate_env() { # <json> <env-assignment...>
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

# Case 1: PASS - landed, complete Risk/Q&A prep section
CASE1='loop_state: landed

## Risk/Q&A prep

Q: What is the rollback plan?
A: Revert the previous commit. (pre-approved by approver)

## Next section
'
printf '%s' "$CASE1" > "$f"
run_gate "$(j_write "$f" "$CASE1")" >"$WORKDIR/err1.log" 2>&1
status1=$?
report "case1 PASS - complete section, landed" "$([ $status1 -eq 0 ] && echo 0 || echo 1)"

# Case 2: REJECT - missing heading
CASE2='loop_state: landed

## Some other section

Q: What is the rollback plan?
A: Revert the previous commit. (pre-approved)
'
run_gate "$(j_write "$f" "$CASE2")" >/dev/null 2>&1
status2=$?
report "case2 REJECT - missing heading" "$([ $status2 -ne 0 ] && echo 0 || echo 1)"

# Case 3: REJECT - Q&A pair present but no pre-approval mark
CASE3='loop_state: landed

## Risk/Q&A prep

Q: What is the rollback plan?
A: Revert the previous commit.

## Next section
'
run_gate "$(j_write "$f" "$CASE3")" >/dev/null 2>&1
status3=$?
report "case3 REJECT - no pre-approval mark" "$([ $status3 -ne 0 ] && echo 0 || echo 1)"

# Case 4: PASS-THROUGH - not landed, same defects present
CASE4='loop_state: scope-proposed

## Some other section

Q: What is the rollback plan?
A: Revert the previous commit.
'
run_gate "$(j_write "$f" "$CASE4")" >/dev/null 2>&1
status4=$?
report "case4 PASS-THROUGH - not landed" "$([ $status4 -eq 0 ] && echo 0 || echo 1)"

# Case 5: FAIL-CLOSED - Edit against a nonexistent target file
rm -f "$f"
run_gate "$(j_edit "$f" "x" "y" 0)" >/dev/null 2>&1
status5=$?
report "case5 FAIL-CLOSED - nonexistent file" "$([ $status5 -ne 0 ] && echo 0 || echo 1)"

# Case 6 (structural-upgrade regression): the section has 5 Q&A pairs and
# exactly one pre-approved mark, attached to a DIFFERENT pair than the one
# carrying a draft answer with no sign-off. The OLD "anywhere in section"
# check would have passed this; adjacency pairing must deny it.
CASE6='loop_state: landed

## Risk/Q&A prep

Q: Is the rollback plan documented?
A: Yes, see runbook. (pre-approved by approver)

Q: What happens if the vendor API is down?
A: We queue and retry.

Q: Who owns the on-call rotation this week?
A: Alice.

Q: Is legal aware of the wording change?
A: Draft sent, no reply yet.

Q: Does this affect the SLA?
A: No impact expected.

## Next section
'
run_gate "$(j_write "$f" "$CASE6")" >/dev/null 2>&1
status6=$?
report "case6 REGRESSION - unrelated pre-approved mark must FAIL (adjacency)" "$([ $status6 -ne 0 ] && echo 0 || echo 1)"

# Case 7: Edit with replace_all: true against a multiply-occurring old_string.
REPEATED='loop_state: landed

before: draft.

## Risk/Q&A prep

Q: What is the rollback plan?
A: Revert the previous commit. draft. (pre-approved)

## Next section

after: draft.
'
printf '%s' "$REPEATED" > "$f"
run_gate "$(j_edit "$f" "draft." "final." 1)" >/dev/null 2>&1
status7=$?
report "case7 replace_all:true - reconstructs every occurrence and passes" "$([ $status7 -eq 0 ] && echo 0 || echo 1)"

# Case 8: MultiEdit with mixed replace_all true/false in one call.
printf '%s' "$CASE1" > "$f"
edits='[{"old_string":"rollback plan?","new_string":"rollback plan, confirmed?","replace_all":false},{"old_string":"Revert the previous commit.","new_string":"Revert the previous commit.","replace_all":true}]'
run_gate "$(j_multiedit "$f" "$edits")" >/dev/null 2>&1
status8=$?
report "case8 MultiEdit mixed replace_all - still passes" "$([ $status8 -eq 0 ] && echo 0 || echo 1)"

# Case 9: malformed JSON — truncated, non-object, empty — all deny.
printf '%s' '{"tool_name":"Write"' | env CLAUDE_PROJECT_DIR="$WORKDIR" CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" "$GATE" >/dev/null 2>&1
status9a=$?
report "case9a malformed JSON (truncated) denies" "$([ $status9a -ne 0 ] && echo 0 || echo 1)"
printf '%s' '"just a string"' | env CLAUDE_PROJECT_DIR="$WORKDIR" CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" "$GATE" >/dev/null 2>&1
status9b=$?
report "case9b malformed JSON (non-object) denies" "$([ $status9b -ne 0 ] && echo 0 || echo 1)"
printf '%s' '' | env CLAUDE_PROJECT_DIR="$WORKDIR" CLAUDE_PLUGIN_ROOT_CORE="$CORE_ROOT" "$GATE" >/dev/null 2>&1
status9c=$?
report "case9c malformed JSON (empty) denies" "$([ $status9c -ne 0 ] && echo 0 || echo 1)"

# Case 10: kill switch set to an unrecognized value stays ACTIVE.
printf '%s' "$CASE3" > "$f"
run_gate_env "$(j_write "$f" "$CASE3")" env QA_PREAPPROVAL_GATE_DISABLE=banana >/dev/null 2>&1
status10=$?
report "case10 kill-switch unrecognized value stays ACTIVE" "$([ $status10 -ne 0 ] && echo 0 || echo 1)"
run_gate_env "$(j_write "$f" "$CASE3")" env QA_PREAPPROVAL_GATE_DISABLE=1 >/dev/null 2>&1
status10b=$?
report "case10b kill-switch '1' disables (sanity check)" "$([ $status10b -eq 0 ] && echo 0 || echo 1)"

# Case 11: absolute file_path and ./-prefixed variant get the same verdict
# a relative-path fixture already gets.
printf '%s' "$CASE1" > "$f"
run_gate "$(j_write "$f" "$CASE1")" >/dev/null 2>&1
status11a=$?
report "case11a absolute file_path resolves to the same target and passes" "$([ $status11a -eq 0 ] && echo 0 || echo 1)"
rel="./docs/issue-1/reports/pr-communications.md"
( cd "$WORKDIR" && run_gate "$(j_write "$rel" "$CASE1")" ) >/dev/null 2>&1
status11b=$?
report "case11b ./-prefixed file_path resolves to the same target and passes" "$([ $status11b -eq 0 ] && echo 0 || echo 1)"

# Case 12: a Bash-tool write reaching the same target a Write-tool fixture
# already exercises gets evaluated too (post-write, on-disk content).
printf '%s' "$CASE3" > "$f"
run_gate "$(j_bash "cat > ${f} <<'CASEEOF'
$CASE3
CASEEOF")" >/dev/null 2>&1
status12=$?
report "case12 Bash-tool write to the same target denies on the same defect" "$([ $status12 -ne 0 ] && echo 0 || echo 1)"

# Case 13 (F3 regression): a draft answer whose note literally reads "NOT
# pre-approved" must not satisfy the approval regex via substring match.
CASE13='loop_state: landed

## Risk/Q&A prep

Q: What is the rollback plan?
A: Revert the previous commit. (NOT pre-approved yet)
'
run_gate "$(j_write "$f" "$CASE13")" >/dev/null 2>&1
status13=$?
report "case13 REJECT - 'NOT pre-approved' does not satisfy the approval mark" "$([ $status13 -ne 0 ] && echo 0 || echo 1)"

# Case 14 (missing-core, gate-house-standard.md case group 7): core
# unreachable via both CLAUDE_PLUGIN_ROOT_CORE and the relative ../../core
# fallback -> fail closed (exit 2, not silent allow/crash).
printf '%s' "$CASE1" > "$f"
missing_core_out="$(printf '%s' "$(j_write "$f" "$CASE1")" | env CLAUDE_PROJECT_DIR="$WORKDIR" CLAUDE_PLUGIN_ROOT_CORE="/nonexistent/path" "$GATE" 2>&1)"
status14=$?
if [[ "$status14" -eq 2 ]] && grep -q "cannot source gate-lib.sh" <<<"$missing_core_out"; then
  report "case14 missing-core - fails closed with exit 2 and source-failure message" 0
else
  report "case14 missing-core - fails closed with exit 2 and source-failure message (got status=$status14, out=$missing_core_out)" 1
fi

# Case 15 (harmless Bash allow): an ordinary Bash command touching no path
# resolving to docs/issue-*/reports/pr-communications.md passes through.
run_gate "$(j_bash "git status")" >/dev/null 2>&1
status15=$?
report "case15 harmless Bash command (git status) passes through" "$([ $status15 -eq 0 ] && echo 0 || echo 1)"

echo ""
echo "Passed: $pass_count, Failed: $fail_count"

exit $overall
