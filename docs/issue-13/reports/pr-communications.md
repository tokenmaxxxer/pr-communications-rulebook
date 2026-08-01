---
role: pr-communications
subject: issue-13
loop_state: landed
---

# Record — issue-13 게이트 A+ 최종 마감 (phase 2)

## What was done

Phase-2 delivery of `docs/issue-13/proposals/gate-a-plus-remediation.md`
(approved via issue-13 comment `APPROVE issue-13/pr-communications`),
closing every finding in `docs/issue-13/reports/pr-communications/survey.md`:

- F1/F2 — added the canon `||` guard clause to every unguarded
  `gate-lib.sh`/`role-directive.sh` source line: `key-message-gate.sh:19`,
  `qa-preapproval-gate.sh:19`, `race-sequence-gate.sh:18`, and
  `pr-communications/hooks/directive.sh:5`. Each now exits 2 with
  `"<script>: cannot source <lib>.sh"` on stderr instead of silently
  running no code when core is unreachable.
- F3 — `qa-preapproval-gate.sh`'s `APPROVED_RE` now carries two negation
  lookbehinds, `(?<!not\s)(?<!아니)(?<!미)`, so "NOT pre-approved" no
  longer satisfies the approval mark (split into two fixed-width
  lookbehind groups — Python's `re` rejects a single variable-width
  alternation).
- F4 — added a missing-core case to all three `tests/*-gate-test.sh`
  (env pointed at a nonexistent path; the repo has no `../../core`
  fallback directory either, so both resolution paths fail together),
  asserting exit 2 and the `"cannot source gate-lib.sh"` message.
- F5 — added a harmless-Bash-allow case to all three suites (`git
  status` reaching no tracked record path passes through with exit 0),
  closing the gap where only the Bash-deny path was tested.
- qa-preapproval's suite additionally gained an F3 regression case
  (case13: a draft answer noted "(NOT pre-approved yet)" must still
  deny) — not separately proposed but the direct, cheap-to-add
  verification that F3's fix doesn't silently regress.
- F6/F7 — verified, no code change: all three plugins' `hooks.json`
  already carry `"matcher": "Write|Edit|MultiEdit|Bash"` matching each
  gate's four handled tool branches; no ghost file or old role/plugin
  name reference exists across the five READMEs/four `plugin.json`s.
  Updated the one stale claim F7 found: the three sibling READMEs'
  "covers every mandatory case" line now names all seven cases
  (missing-core added) instead of six.

## Why

The 2026-08-01 재감사 (grade C) found that issue-10's gate-lib migration
left the source line itself unguarded — exactly the failure mode core
#75 had already named and fixed canonically upstream (an unguarded
source that fails leaves every `gate_*` function undefined, so the next
statement, `gate_trap_fail_closed`, itself errors "command not found"
and the gate silently fails open) — plus one live false-negative in
qa-preapproval's approval regex and two test-coverage gaps (missing-core,
harmless-Bash-allow) that meant nothing proved F1's fix, once applied,
stays fixed. Fixing this without re-deriving core #75's canon form would
reintroduce the same defect class core already centralized and audited a
fix for.

## Upstream basis

- Issue: #13.
- Proposal: `docs/issue-13/proposals/gate-a-plus-remediation.md`
  (approved via issue-13 comment `APPROVE issue-13/pr-communications`).
- Survey: `docs/issue-13/reports/pr-communications/survey.md`.
- Precondition: core #75 (`tokenmaxxxer-core` PR #77, MERGED) — the
  `||`-guard canon form, `compliance-check.sh`'s unguarded-source
  detection rule, and the missing-core mandatory test case group 7.
- Precondition: on-the-record #182 (`on-the-record` PR #185, MERGED) —
  `spawn_cmd()` injects `CLAUDE_PLUGIN_ROOT_CORE`, unrelated to this
  role's own fix but confirmed landed per the issue's stated common
  preconditions.

## Communications plan

**Research**
Reconfirmed from `docs/issue-13/reports/pr-communications/survey.md`:
F1/F2 unguarded source (fail-open on missing core), F3 negation-blind
approval regex, F4/F5 absent regression tests, F6/F7 already-correct
matcher/README state with one stale case-count line.

**Action**
Apply proposal §1-4's exact diffs (guard clause, regex, test cases) to
each named site, verified against 2026-08-01's re-audit findings and
nothing beyond them; re-verify F6/F7's already-correct claims and update
the one stale README line F7 flagged.

**Communication**
This record and its diff deliver through the `issue-13/pr-communications`
branch's pull request for the approvers.md reviewer to re-confirm — no
external/customer-facing channel, per contract v3's role-handoff model.

**Evaluation**
Success criteria, defined here before delivery: (1) `bash tests/*.sh`
exit 0 for all three gates, including the new F4/F5 (and qa-preapproval's
F3 regression) cases; (2) `core/hooks/tests/compliance-check.sh` reports
`ok` for `key-message-tiers/qa-preapproval/race-sequence` hooks dirs
(F2's `directive.sh` sits outside compliance-check's `*-gate.sh` filename
filter, verified instead by direct `git grep` inspection of the guarded
source line); (3) the three README case-count lines match the actual
test-case count; (4) zero ghost-file/old-role-name references across
READMEs and manifests. All four checked before this record was written
(see Evidence).

## Key message

**Core message**: issue-13's re-audited residual defects (F1-F5) are
closed against the approved proposal's exact diffs, and F6/F7's
already-correct state is re-verified with the one stale doc line synced.
**Proof point**: all three `tests/*-gate-test.sh` exit 0 (55 cases total,
including every new F3/F4/F5 case) and `compliance-check.sh` reports `ok`
for all three plugin hooks dirs.

**Supporting message**: the three gates now fail closed (exit 2), not
open, when core is unreachable.
**Proof point**: the new missing-core case in each suite asserts exit 2
and stderr containing `"cannot source gate-lib.sh"` when
`CLAUDE_PLUGIN_ROOT_CORE` points nowhere and the repo's own `../../core`
relative fallback also does not exist.

**Supporting message**: qa-preapproval no longer misreads an explicit
rejection as an approval.
**Proof point**: the new F3 regression case denies a draft answer noted
"(NOT pre-approved yet)"; case6 (an unrelated-pair pre-approved mark)
continues to deny as before, confirming the fix didn't loosen the
existing adjacency check.

## Risk/Q&A prep

Q: F2 (`directive.sh`)는 `compliance-check.sh`의 `*-gate.sh` 파일명
필터 밖인데, 가드 절이 실제로 적용됐다는 것을 어떻게 보증하나?
A: `compliance-check.sh`로는 검출 불가라는 점을 proposal §1이 이미
detector 커버리지 갭으로 명시했고, 대신 `git grep`로 해당 소스 라인에
`||`-가드가 실제로 붙어 있음을 직접 확인했다 — 별도 자동 테스트는
proposal 스코프 밖(F2는 코드 3줄 수정이며 SessionStart hook이라 이
role의 `tests/*-gate-test.sh` PreToolUse harness로 exercise할 수 없다).
(pre-approved by JiwonJung94 — 2026-08-01 이슈 코멘트
`APPROVE issue-13/pr-communications`가 proposal 전체 범위를 사전
승인했으며, 이 갭은 proposal §5 F6/F7 절에서 이미 명시적으로 다뤘다.)

Q: F3의 부정 전방탐색이 "아니"/"미" 두 형태소만 잡는데, 다른 한국어 부정
표현(예: "거부됨", "반려")은 여전히 오탐 위험이 있지 않나?
A: 맞다 — proposal §2가 명시적으로 스코프를 좁혔다: 재감사가 지목한
정확한 실패 사례("NOT pre-approved" 인접 부정)만 고치는 좁은 렉시컬
가드이며, 일반 감성/부정 분류로 확장하는 것은 이 게이트의 기존 철학
(구조/어휘 검사, NLP 아님)과 어긋나 범위 밖으로 의도적으로 남겼다. 향후
새로운 부정 표현이 실제 오탐 사례로 발견되면 별도 이슈로 다룰 사항.
(pre-approved by JiwonJung94 — 2026-08-01 이슈 코멘트
`APPROVE issue-13/pr-communications`가 proposal §2의 이 설계 제약을
포함해 사전 승인.)

## Evidence

```
$ bash tests/key-message-gate-test.sh
... (18 cases, incl. case13 missing-core, case14 harmless-Bash-allow)
All test cases passed.

$ bash tests/qa-preapproval-gate-test.sh
... (19 cases, incl. case13 F3 regression, case14 missing-core, case15
    harmless-Bash-allow)
Passed: 19, Failed: 0

$ bash tests/race-sequence-gate-test.sh
... (18 cases, incl. missing-core, harmless-Bash-allow)
ALL CASES PASSED

$ core/hooks/tests/compliance-check.sh key-message-tiers/hooks
compliance-check: ok — key-message-tiers/hooks/key-message-gate.sh

$ core/hooks/tests/compliance-check.sh qa-preapproval/hooks
compliance-check: ok — qa-preapproval/hooks/qa-preapproval-gate.sh

$ core/hooks/tests/compliance-check.sh race-sequence/hooks
compliance-check: ok — race-sequence/hooks/race-sequence-gate.sh

$ core/hooks/tests/compliance-check.sh pr-communications/hooks
compliance-check: no *-gate.sh files found under pr-communications/hooks
    — nothing to check
```

## Open findings

None outstanding against the approved proposal's scope. F2's
`directive.sh` guard is confirmed by direct source inspection rather
than an automated test (documented limitation, pre-approved above), and
F6/F7 required no code change beyond the one README case-count sync.
