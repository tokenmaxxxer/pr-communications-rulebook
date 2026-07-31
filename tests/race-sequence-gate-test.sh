#!/usr/bin/env bash
# Test suite for race-sequence/hooks/race-sequence-gate.sh
set -uo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
gate="${repo_root}/race-sequence/hooks/race-sequence-gate.sh"

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

# Case 1: PASS - correct order, landed
cat > "${workdir}/docs/issue-1/reports/case1.md" <<'EOF'
loop_state: landed

## Communications plan

**Research**
Current state summary.

**Action**
Concrete next actions.

**Communication**
Channel and timing confirmed.

**Evaluation**
Success criteria defined before send.
EOF

# Case 2: REJECT - missing Communications plan heading
cat > "${workdir}/docs/issue-1/reports/case2.md" <<'EOF'
loop_state: landed

**Research**
Current state summary.

**Action**
Concrete next actions.

**Communication**
Channel and timing confirmed.

**Evaluation**
Success criteria defined before send.
EOF

# Case 3: REJECT - order violation, Evaluation before Communication
cat > "${workdir}/docs/issue-1/reports/case3.md" <<'EOF'
loop_state: landed

## Communications plan

**Research**
Current state summary.

**Action**
Concrete next actions.

**Evaluation**
Success criteria defined before send.

**Communication**
Channel and timing confirmed.
EOF

# Case 4: PASS-THROUGH - scope-proposed, with all defects present
cat > "${workdir}/docs/issue-1/reports/case4.md" <<'EOF'
loop_state: scope-proposed

**Evaluation**
Success criteria defined before send.

**Communication**
Channel and timing confirmed.
EOF

run_gate_direct() {
  "$gate" "$1" >"${workdir}/gate-stdout" 2>"${workdir}/gate-stderr"
  echo $?
}

# Case 1
rc="$(run_gate_direct "${workdir}/docs/issue-1/reports/case1.md")"
if [[ "$rc" == "0" ]]; then report "PASS - correct RACE order, landed" "0" "0"; else report "PASS - correct RACE order, landed" "0" "$rc"; fi

# Case 2
rc="$(run_gate_direct "${workdir}/docs/issue-1/reports/case2.md")"
if [[ "$rc" != "0" ]]; then report "REJECT - missing Communications plan heading" "nonzero" "nonzero"; else report "REJECT - missing Communications plan heading" "nonzero" "0"; fi

# Case 3
rc="$(run_gate_direct "${workdir}/docs/issue-1/reports/case3.md")"
if [[ "$rc" != "0" ]]; then report "REJECT - Evaluation before Communication" "nonzero" "nonzero"; else report "REJECT - Evaluation before Communication" "nonzero" "0"; fi

# Case 4
rc="$(run_gate_direct "${workdir}/docs/issue-1/reports/case4.md")"
if [[ "$rc" == "0" ]]; then report "PASS-THROUGH - non-terminal loop_state (scope-proposed)" "0" "0"; else report "PASS-THROUGH - non-terminal loop_state (scope-proposed)" "0" "$rc"; fi

# Case 5: FAIL-CLOSED - nonexistent file path
rc="$(run_gate_direct "${workdir}/docs/issue-1/reports/does-not-exist.md")"
if [[ "$rc" != "0" ]]; then report "FAIL-CLOSED - nonexistent file path" "nonzero" "nonzero"; else report "FAIL-CLOSED - nonexistent file path" "nonzero" "0"; fi

echo "---"
if [[ "$fail_count" -eq 0 ]]; then
  echo "ALL CASES PASSED"
  exit 0
else
  echo "${fail_count} CASE(S) FAILED"
  exit 1
fi
