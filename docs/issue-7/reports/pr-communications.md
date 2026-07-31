---
subject: issue-7
role: pr-communications
loop_state: landed
---

# Phase-2 record — 방법론 강제 플러그인 세트 구현 (issue-7)

Approved via issue comment `APPROVE issue-7/pr-communications (phase 2
반영: RACE 표기를 Action 복원 또는 ROPE로 정정)`. This record documents
the phase-2 delivery: three self-contained plugins mechanically enforcing
the three methodologies issue-1 adopted for this role (RACE sequencing,
3-tier key message, pre-approved Risk/Q&A), plus the approver-mandated
RACE naming fix.

## What was done

Implemented the approved plugin-set redesign (proposal, revision 2) as
three self-contained Claude Code plugins under repo root —
`race-sequence/`, `key-message-tiers/`, `qa-preapproval/` — each with its
own `.claude-plugin/plugin.json`, `hooks/hooks.json`, SessionStart
directive script, PreToolUse gate script, README, and env-var kill
switch; registered all three in `.claude-plugin/marketplace.json`;
added one root-level gate test script per plugin under `tests/`; fixed
the RACE "Objectives"→"Action" mislabeling the approver flagged, in this
role's own directive and record template.

## Why

Issue-7 required this role's three issue-1-adopted communication
methodologies (RACE sequencing, 3-tier key message, pre-approved Q&A) to
move from prose-only norms to machine-enforced gates, matching
`implementation-rulebook`'s enforcement depth. The approver's "요구
정정" comment specified the concrete shape: independent plugins per
methodology (not one merged gate), each self-contained and separately
registered, so any one methodology's check can be replaced without
touching the other two.

## Approver correction applied

RACE's second stage was mislabeled "Objectives" in the issue-1 record,
this role's directive, and the issue-7 phase-1 proposal. The approver
flagged this and asked for either restoring "Action" (the real RACE
acronym — Research/Action/Communication/Evaluation) or renaming the
whole scheme to ROPE. This delivery restores **Action** (smaller,
non-substantive change; the stage's content — goals drawn from the
issue — is unchanged, only the label): fixed in
`pr-communications/hooks/directive.sh` (PRODUCES field),
`docs/handbooks/record-template.md`, and all three new plugins'
gates/directives/READMEs below.

## Plugins delivered

| Plugin | Methodology | Files | Phase participation |
|---|---|---|---|
| `race-sequence/` | RACE 4-stage order (Research→Action→Communication→Evaluation) | `.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/directive.sh`, `hooks/race-sequence-gate.sh`, `README.md`; test: `tests/race-sequence-gate-test.sh` | phase-1 (Research/Action facet) + phase-2 (full-order gate) |
| `key-message-tiers/` | 3-tier key message (1 core + supporting + proof points) | `.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/directive.sh`, `hooks/key-message-gate.sh`, `README.md`; test: `tests/key-message-gate-test.sh` | phase-2 only |
| `qa-preapproval/` | Pre-approved Risk/Q&A | `.claude-plugin/plugin.json`, `hooks/hooks.json`, `hooks/directive.sh`, `hooks/qa-preapproval-gate.sh`, `checklists/qa-preapproval.md`, `README.md`; test: `tests/qa-preapproval-gate-test.sh` | phase-2 only |

All three registered as separate entries in `.claude-plugin/marketplace.json`.
Each gate: PreToolUse on `Write|Edit`, scoped to
`docs/issue-*/reports/pr-communications.md`, applies only when
`loop_state: landed` (non-terminal writes pass through un-gated),
fail-closed on internal error or missing input file, and carries its own
env-var kill switch for emergency admin bypass (never a routine
override — Q1's recommendation to keep the methodology checks
hard-block by default stands; the kill switch is a last-resort escape
hatch, not a per-record exception path). No plugin calls another's
gate/directive — combination is expressed only through the phase-1/
phase-2 norm tables in the proposal and `docs/handbooks/record-template.md`,
same independence as core's freelunch/scout.

## Phase-2 checklist

See `docs/handbooks/phase2-checklist.md` for the combined per-record
checklist (one item per plugin) that a `loop_state: landed`
`pr-communications.md` record must satisfy before the gates will pass it.

## Communications plan

- **Research** — phase-1 survey (`docs/issue-7/reports/pr-communications/survey.md`)
  found the RACE/3-tier/pre-approved-Q&A norms existed only as prose in
  the issue-1 record and this role's one-line PRODUCES directive, with no
  mechanical check — unlike `implementation-rulebook`'s 400+-line
  gate/state-tracking machine. Scout brief
  (`docs/issue-7/reports/pr-communications/scout-brief.md`) surveyed
  comparable rulebook enforcement patterns.
- **Action** — ship one independently-replaceable plugin per methodology
  (not one monolithic gate), each self-contained per the approver's
  "요구 정정" comment, registered in the marketplace, so future changes
  to one methodology (e.g. how Q&A pre-approval is marked) never touch
  the other two's gates or tests.
- **Communication** — this record (audience: the issue-7 requester and
  any role/session that later writes a `pr-communications.md` phase-2
  record and hits these gates) plus each plugin's own README (audience:
  a maintainer debugging or extending one gate) plus
  `docs/handbooks/phase2-checklist.md` (audience: this role, next time it
  writes a terminal-state record). Delivered via this PR, reviewed by the
  approver before merge — no external/customer-facing channel involved,
  so no separate send/channel confirmation beyond the PR itself.
- **Evaluation** — success criteria fixed *before* delivery (this
  section written before opening the PR, not after): (1) all three gate
  test scripts under `tests/` pass their 5 fixture cases (PASS, missing
  section, condition-violation, pass-through on non-terminal state,
  fail-closed on bad input); (2) `marketplace.json` lists all four
  plugins; (3) the RACE "Action" fix is applied everywhere the mislabel
  previously existed in this role's own files.

## Key message

- **Core message** — the three methodologies issue-1 adopted for this
  role are no longer prose-only norms; each now has an independent,
  self-contained plugin that mechanically blocks an incomplete
  `loop_state: landed` record.
  - **Proof point** — `tests/race-sequence-gate-test.sh`,
    `tests/key-message-gate-test.sh`, and
    `tests/qa-preapproval-gate-test.sh` each exercise PASS / missing-
    section-REJECT / condition-violation-REJECT / non-terminal
    pass-through / fail-closed-on-bad-input, and all three passed in
    this session's build.
- **Supporting message** — each plugin is independently extensible or
  replaceable without touching its siblings (freelunch/scout-style
  separation), per the approver's "요구 정정" comment.
  - **Proof point** — no plugin's hook or gate script references
    another's file; the only link between the three is the phase-1/
    phase-2 norm table in the proposal and `docs/handbooks/record-template.md`.
- **Supporting message** — the RACE mislabeling ("Objectives") the
  approver caught is now corrected to "Action" everywhere in this role's
  files, restoring the actual RACE acronym.
  - **Proof point** — `pr-communications/hooks/directive.sh`,
    `docs/handbooks/record-template.md`, and all `race-sequence/*`
    content use "Action", not "Objectives".

## Risk/Q&A prep

Q: 게이트가 정상 기록까지 막으면 (false positive) 어떻게 하나?
A: 각 플러그인은 독립 kill switch 환경변수(`RACE_SEQUENCE_GATE_DISABLE`,
`KEY_MESSAGE_GATE_DISABLE`, `QA_PREAPPROVAL_GATE_DISABLE`)를 가진다 —
비상시에만 사용하고 stderr에 비활성화 로그를 남긴다. 상시 우회 경로는
proposal Q1 권고(항상 hard-block)에 따라 두지 않는다. (pre-approved:
issue-7 approver 코멘트가 Q1 권고안 자체를 승인.)

Q: 이 gate들이 core의 `record-fields-gate.sh`와 충돌하거나 중복되나?
A: 아니다 — core 게이트는 contract §20 구조적 frontmatter만 검사하고, 이
세 플러그인은 그 아래 role-specific `produces` 서브구조만 검사한다.
서로 다른 파일(스크립트)이며 같은 PreToolUse 이벤트에 각자 독립적으로
등록되어 순차 실행된다. (pre-approved: proposal 채택 근거 절에서 이
역할 분리를 승인자가 이미 검토.)

Q: 이 로컬 플러그인들은 영구 구조인가?
A: 아니다 — proposal Q2 권고(로컬은 임시 조치, core config 이관 가능성
열어둠)를 그대로 따른다. (pre-approved: 승인 코멘트가 원안의 Q1/Q2
권고를 재협상 없이 승인.)

## Open findings

- Core's `record-fields-gate.sh` (contract §20) checks only structural
  frontmatter fields, not this role's `produces` sub-structure — the
  three new plugins fill that gap locally per proposal Q2, pending a
  possible future core config mechanism (not this role's scope to
  create).
- `pricing-rulebook`'s actual `methodology-gate.sh` was not read/copied
  (out of this session's filesystem access and against the issue's
  "참조만·복사 금지" constraint) — the gate scripts here were designed
  independently from the pattern description in this role's own scout
  brief.
