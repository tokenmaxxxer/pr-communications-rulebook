#!/usr/bin/env bash
set -uo pipefail

cat <<'EOF'
[race-sequence] RACE methodology directive (informational)

RACE = Research -> Action -> Communication -> Evaluation.
("Action" is the correct second letter — not "Objectives".)

Phase-1 facet (early draft stage):
  - Only Research and Action exist as finalized content.
    - Research: current-state summary + stakeholder draft.
    - Action: goals drawn explicitly from the issue itself — concretely
      stated objectives/next actions, not a copy-paste of the issue text.
  - Communication and Evaluation are sketch-only at this stage (target
    audience / channel sketch). They are NOT finalized in phase-1.

Phase-2 facet (landed / terminal stage):
  - Full RACE order is enforced, in this exact sequence:
    1. Research      - reconfirmed from the phase-1 survey (not re-researched).
    2. Action        - reconfirmed from phase-1.
    3. Communication - channel, timing, and actual delivery confirmed.
    4. Evaluation    - success criteria defined BEFORE send.
       Defining success criteria after the send is RACE's core failure mode.

This directive is informational only. The mechanical check is enforced by
the PreToolUse gate: hooks/race-sequence-gate.sh, which runs against
docs/issue-*/reports/pr-communications.md whenever it reaches
loop_state: landed.
EOF
