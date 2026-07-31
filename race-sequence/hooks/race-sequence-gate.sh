#!/usr/bin/env bash
# race-sequence-gate.sh
#
# PreToolUse (Write|Edit) gate enforcing RACE order (Research -> Action ->
# Communication -> Evaluation) on terminal (loop_state: landed) writes to
# docs/issue-*/reports/pr-communications.md.
#
# Manual invocation for testing: ./race-sequence-gate.sh <path>
#
# Kill switch: RACE_SEQUENCE_GATE_DISABLE=1 skips the gate entirely
# (emergency admin escape hatch only — see README.md).

set -uo pipefail

trap 'echo "race-sequence-gate: internal error, failing closed" >&2; exit 1' ERR

if [[ "${RACE_SEQUENCE_GATE_DISABLE:-}" == "1" ]]; then
  echo "race-sequence-gate: disabled via RACE_SEQUENCE_GATE_DISABLE, skipping" >&2
  exit 0
fi

if [[ $# -ge 1 ]]; then
  file="$1"
else
  payload="$(cat)"
  file="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.path // empty')"

  if [[ -z "${file:-}" ]]; then
    # Nothing we can act on.
    exit 0
  fi

  if [[ "$file" != docs/issue-*/reports/pr-communications.md ]]; then
    exit 0
  fi
fi

# Explicit existence/read check so a missing file fails closed via the ERR
# trap, rather than being swallowed by a later "grep ... || exit 0" idiom.
cat "$file" >/dev/null

grep -q '^loop_state: landed' "$file" || exit 0

grep -qF '## Communications plan' "$file" || {
  echo "race-sequence-gate: missing '## Communications plan'" >&2
  exit 1
}

matches="$(grep -noE '\*\*(Research|Action|Communication|Evaluation)\*\*' "$file")"

get_line() {
  local label="$1"
  printf '%s\n' "$matches" | grep -F "**${label}**" | head -n1 | cut -d: -f1
}

research_line="$(get_line Research)"
action_line="$(get_line Action)"
communication_line="$(get_line Communication)"
evaluation_line="$(get_line Evaluation)"

for pair in "Research:$research_line" "Action:$action_line" "Communication:$communication_line" "Evaluation:$evaluation_line"; do
  label="${pair%%:*}"
  value="${pair#*:}"
  if [[ -z "$value" ]]; then
    echo "race-sequence-gate: missing **${label}** label in RACE sequence" >&2
    exit 1
  fi
done

check_order() {
  local before_label="$1" before_line="$2" after_label="$3" after_line="$4"
  if (( after_line <= before_line )); then
    echo "race-sequence-gate: ${after_label} (line ${after_line}) appears before ${before_label} (line ${before_line}) — success criteria defined after send is RACE's core failure mode" >&2
    exit 1
  fi
}

check_order "Research" "$research_line" "Action" "$action_line"
check_order "Action" "$action_line" "Communication" "$communication_line"
check_order "Communication" "$communication_line" "Evaluation" "$evaluation_line"

echo "race-sequence-gate: RACE order OK" >&2
exit 0
