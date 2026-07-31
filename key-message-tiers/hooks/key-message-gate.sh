#!/usr/bin/env bash
set -uo pipefail

trap 'echo "key-message-gate: internal error, failing closed" >&2; exit 1' ERR

if [[ "${KEY_MESSAGE_GATE_DISABLE:-}" == "1" ]]; then
  echo "key-message-gate: disabled via KEY_MESSAGE_GATE_DISABLE, skipping" >&2
  exit 0
fi

if [[ $# -ge 1 ]]; then
  file="$1"
else
  input="$(cat)"
  file="$(echo "$input" | jq -r '.tool_input.file_path // .tool_input.path')"
fi

case "$file" in
  docs/issue-*/reports/pr-communications.md) ;;
  *) exit 0 ;;
esac

# Nonexistent file paths must fail closed via the ERR trap.
[[ -f "$file" ]] || { false; }

grep -q '^loop_state: landed' "$file" || exit 0

grep -qF '## Key message' "$file" || {
  echo "key-message-gate: missing '## Key message'" >&2
  exit 1
}

section="$(awk '
  /^## Key message/ { capture=1; print; next }
  capture && /^## / { exit }
  capture { print }
' "$file")"

core_count="$(printf '%s\n' "$section" | grep -ioc 'core message')"

if [[ "$core_count" -eq 0 ]]; then
  echo "key-message-gate: no Core message found" >&2
  exit 1
elif [[ "$core_count" -gt 1 ]]; then
  echo "key-message-gate: ${core_count} core messages found, 3-tier structure requires exactly 1" >&2
  exit 1
fi

proof_count="$(printf '%s\n' "$section" | grep -ioc 'proof point')"

if [[ "$proof_count" -eq 0 ]]; then
  echo "key-message-gate: no Proof point found for any key message" >&2
  exit 1
fi

exit 0
