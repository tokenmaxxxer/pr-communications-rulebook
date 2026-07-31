#!/usr/bin/env bash
# SessionStart: pr-communications's role directive, stub form (core issue-66) —
# shared boilerplate lives in core/hooks/lib/role-directive.sh; only this
# role's four unique values live here.
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh"

YOU_DECIDE="YOU DECIDE: 메시지가 외부에 어떻게 읽힐지"
USE_WHEN="USE WHEN: 외부 커뮤니케이션이 걸릴 때"
PRODUCES="PRODUCES (required record fields): communications plan (RACE: research/objectives/communication/evaluation), key message (core+supporting+proof point), risk/Q&A prep (pre-approved)"
HAND_OFF=$'WRITE_SCOPE: []\n\nHAND-OFF: 캠페인 성격 메시지는 → marketing\n\nBOUNDARY CASE: if the work in front of you drifts outside `decides` above, stop and hand off per the arrow — do not silently absorb another role\'s scope. Record the hand-off point in this role\'s record before opening the next role\'s session.'

core_role_directive "$YOU_DECIDE" "$USE_WHEN" "$PRODUCES" "$HAND_OFF"
