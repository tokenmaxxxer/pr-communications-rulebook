#!/usr/bin/env bash
set -uo pipefail

cat <<'EOF'
[key-message-tiers] directive
- This plugin applies in phase-2 only. Real key message text does not exist
  before phase-2 drafting, so this methodology has nothing to check in phase-1.
- Each key message needs at least 1 proof point, or it is incomplete.
- Exactly one core message is required. Two or more core messages violates
  the 3-tier structure (1 core + supporting messages + proof points).
- The mechanical check is enforced by the PreToolUse gate
  (hooks/key-message-gate.sh) on docs/issue-*/reports/pr-communications.md
  once loop_state: landed.
EOF
