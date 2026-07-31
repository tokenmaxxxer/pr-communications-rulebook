#!/usr/bin/env bash
set -uo pipefail

trap 'echo "qa-preapproval-gate: internal error, failing closed" >&2; exit 1' ERR

if [ "${QA_PREAPPROVAL_GATE_DISABLE:-}" = "1" ]; then
  echo "qa-preapproval-gate: disabled via QA_PREAPPROVAL_GATE_DISABLE, skipping" >&2
  exit 0
fi

explicit_file=0
if [ "${1:-}" != "" ]; then
  file="$1"
  explicit_file=1
else
  input="$(cat)"
  file="$(printf '%s' "$input" | jq -r '.tool_input.file_path // .tool_input.path')"
fi

if [ "$explicit_file" -ne 1 ]; then
  case "$file" in
    docs/issue-*/reports/pr-communications.md) ;;
    *) exit 0 ;;
  esac
fi

# Nonexistent file must fail closed via ERR trap (grep on missing file -> non-zero -> set -e-less,
# so force it explicitly).
if [ ! -f "$file" ]; then
  echo "qa-preapproval-gate: internal error, failing closed" >&2
  exit 1
fi

grep -q '^loop_state: landed' "$file" || exit 0

if ! grep -qF '## Risk/Q&A prep' "$file"; then
  echo "qa-preapproval-gate: missing '## Risk/Q&A prep'" >&2
  exit 1
fi

section="$(awk '
  /^## Risk\/Q&A prep/ { capture=1; print; next }
  capture && /^## / { exit }
  capture { print }
' "$file")"

has_en_pair=0
if printf '%s\n' "$section" | grep -q '^Q:'; then
  q_line=$(printf '%s\n' "$section" | grep -n '^Q:' | head -1 | cut -d: -f1)
  if printf '%s\n' "$section" | awk -v start="$q_line" 'NR>start && /^A:/ {found=1} END{exit !found}'; then
    has_en_pair=1
  fi
fi

has_kr_pair=0
if printf '%s\n' "$section" | grep -q '질문'; then
  qk_line=$(printf '%s\n' "$section" | grep -n '질문' | head -1 | cut -d: -f1)
  if printf '%s\n' "$section" | awk -v start="$qk_line" 'NR>start && /답변/ {found=1} END{exit !found}'; then
    has_kr_pair=1
  fi
fi

if [ "$has_en_pair" -ne 1 ] && [ "$has_kr_pair" -ne 1 ]; then
  echo "qa-preapproval-gate: no Q&A pair found in Risk/Q&A prep" >&2
  exit 1
fi

if ! printf '%s\n' "$section" | grep -qi 'pre-approved' && ! printf '%s\n' "$section" | grep -qF '사전 승인'; then
  echo "qa-preapproval-gate: no pre-approved/사전 승인 mark found — ad-hoc answer without approver sign-off" >&2
  exit 1
fi

exit 0
