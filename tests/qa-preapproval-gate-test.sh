#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GATE="$SCRIPT_DIR/../qa-preapproval/hooks/qa-preapproval-gate.sh"

TMPDIR_TEST="$(mktemp -d)"
cleanup() { rm -rf "$TMPDIR_TEST"; }
trap cleanup EXIT

overall=0
pass_count=0
fail_count=0

report() {
  local name="$1"
  local status="$2"
  if [ "$status" -eq 0 ]; then
    echo "PASS: $name"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $name"
    fail_count=$((fail_count + 1))
    overall=1
  fi
}

# Case 1: PASS - landed, complete Risk/Q&A prep section
f1="$TMPDIR_TEST/case1.md"
cat > "$f1" <<'EOF'
loop_state: landed

## Risk/Q&A prep

Q: What is the rollback plan?
A: Revert the previous commit. (pre-approved by approver)

## Next section
EOF
"$GATE" "$f1" >"$TMPDIR_TEST/err1.log" 2>&1
status1=$?
report "case1 PASS - complete section, landed" "$([ $status1 -eq 0 ] && echo 0 || echo 1)"

# Case 2: REJECT - missing heading
f2="$TMPDIR_TEST/case2.md"
cat > "$f2" <<'EOF'
loop_state: landed

## Some other section

Q: What is the rollback plan?
A: Revert the previous commit. (pre-approved)
EOF
"$GATE" "$f2" >/dev/null 2>&1
status2=$?
report "case2 REJECT - missing heading" "$([ $status2 -ne 0 ] && echo 0 || echo 1)"

# Case 3: REJECT - Q&A pair present but no pre-approval mark
f3="$TMPDIR_TEST/case3.md"
cat > "$f3" <<'EOF'
loop_state: landed

## Risk/Q&A prep

Q: What is the rollback plan?
A: Revert the previous commit.

## Next section
EOF
"$GATE" "$f3" >/dev/null 2>&1
status3=$?
report "case3 REJECT - no pre-approval mark" "$([ $status3 -ne 0 ] && echo 0 || echo 1)"

# Case 4: PASS-THROUGH - not landed, same defects present
f4="$TMPDIR_TEST/case4.md"
cat > "$f4" <<'EOF'
loop_state: scope-proposed

## Some other section

Q: What is the rollback plan?
A: Revert the previous commit.
EOF
"$GATE" "$f4" >/dev/null 2>&1
status4=$?
report "case4 PASS-THROUGH - not landed" "$([ $status4 -eq 0 ] && echo 0 || echo 1)"

# Case 5: FAIL-CLOSED - nonexistent file
f5="$TMPDIR_TEST/does-not-exist.md"
"$GATE" "$f5" >/dev/null 2>&1
status5=$?
report "case5 FAIL-CLOSED - nonexistent file" "$([ $status5 -ne 0 ] && echo 0 || echo 1)"

echo ""
echo "Passed: $pass_count, Failed: $fail_count"

exit $overall
