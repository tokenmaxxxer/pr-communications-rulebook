#!/usr/bin/env bash
cat <<'EOF'
[qa-preapproval] phase-2 only.

A risk/Q&A entry with a draft answer but no approver pre-approval mark
("pre-approved" / "사전 승인") is incomplete — a draft answer is not the
same thing as sign-off.

The mechanical check is the PreToolUse gate (hooks/qa-preapproval-gate.sh),
which runs on Write|Edit against docs/issue-*/reports/pr-communications.md
once loop_state: landed.

Before relying on the gate, self-check with checklists/qa-preapproval.md —
the gate's grep pass can miss a lone missing mark when many Q&A pairs are
present.
EOF
