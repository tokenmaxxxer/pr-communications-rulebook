#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
GATE="$REPO_ROOT/key-message-tiers/hooks/key-message-gate.sh"

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

FAILED=0

pass_case() {
  local name="$1"
  echo "PASS: $name"
}

fail_case() {
  local name="$1"
  echo "FAIL: $name"
  FAILED=1
}

mkdir -p "$WORKDIR/docs/issue-1/reports"
cd "$WORKDIR"

# Case 1: PASS — landed, exactly 1 Core message, at least 1 Proof point.
f1="docs/issue-1/reports/pr-communications.md"
cat > "$f1" <<'EOF'
loop_state: landed

## Key message

Core message: ship it.

Supporting message: it is fast.

Proof point: benchmark shows 2x speedup.

## Other section
EOF
if "$GATE" "$f1" >/dev/null 2>&1; then
  pass_case "1 PASS - valid landed key message section"
else
  fail_case "1 PASS - valid landed key message section (expected exit 0)"
fi

# Case 2: REJECT — missing '## Key message' heading.
f2="docs/issue-1/reports/pr-communications.md"
cat > "$f2" <<'EOF'
loop_state: landed

## Some other heading

Core message: ship it.
Proof point: works.
EOF
if "$GATE" "$f2" >/dev/null 2>&1; then
  fail_case "2 REJECT - missing '## Key message' heading (expected non-zero)"
else
  pass_case "2 REJECT - missing '## Key message' heading"
fi

# Case 3: REJECT — 2 Core message occurrences in the section.
f3="docs/issue-1/reports/pr-communications.md"
cat > "$f3" <<'EOF'
loop_state: landed

## Key message

Core message: ship it.
Core message: ship it faster.

Proof point: benchmark shows 2x speedup.

## Other section
EOF
if "$GATE" "$f3" >/dev/null 2>&1; then
  fail_case "3 REJECT - 2 core messages (expected non-zero)"
else
  pass_case "3 REJECT - 2 core messages"
fi

# Case 4: PASS-THROUGH — non-landed loop_state with the same defects present.
f4="docs/issue-1/reports/pr-communications.md"
cat > "$f4" <<'EOF'
loop_state: scope-proposed

## Key message

Core message: ship it.
Core message: ship it faster.

## Other section
EOF
if "$GATE" "$f4" >/dev/null 2>&1; then
  pass_case "4 PASS-THROUGH - non-landed loop_state with defects present"
else
  fail_case "4 PASS-THROUGH - non-landed loop_state with defects present (expected exit 0)"
fi

# Case 5: FAIL-CLOSED — nonexistent file path.
if "$GATE" "docs/issue-999/reports/pr-communications.md" >/dev/null 2>&1; then
  fail_case "5 FAIL-CLOSED - nonexistent file path (expected non-zero)"
else
  pass_case "5 FAIL-CLOSED - nonexistent file path"
fi

if [[ "$FAILED" -eq 0 ]]; then
  echo "All test cases passed."
  exit 0
else
  echo "One or more test cases failed."
  exit 1
fi
