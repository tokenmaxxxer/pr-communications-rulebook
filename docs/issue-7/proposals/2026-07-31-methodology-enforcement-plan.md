---
subject: issue-7
role: pr-communications
loop_state: scope-proposed
---

# Proposal — 방법론(RACE) 강제 장치 설계 (issue-7)

Survey: [survey.md](../reports/pr-communications/survey.md).
Scout brief: [scout-brief.md](../reports/pr-communications/scout-brief.md).

Adopts issue-1's methodology (RACE, 3-tier key message, pre-approved Q&A;
`docs/issue-1/proposals/methodology-and-artifact-norms.md`) as the norm
source, per the issue's constraint. This proposal only *designs* the
enforcement; per this issue's explicit instruction ("phase 1 ONLY — proposal
PR까지만"), no `directive.sh`, gate script, test file, or checklist file is
written in this PR. All code blocks below are the phase-2 implementation
spec, to be executed verbatim after Approve.

## (a) Directive 심화 — Phase 1 facet

Phase 1 없이 방법론을 강제할 곳은 프러포절 작성 시점의 directive 텍스트뿐이다.
`PRODUCES`를 아래처럼 phase-1 전용 절로 확장한다 (SessionStart 출력, 기계
게이트 대상 아님 — 사람 승인자가 읽는 판단 기준):

- **단계**: Research(현재 상태+이해관계자 초안) → Objectives(이슈에서 도출한
  목표, 명시적으로 서술) → Stakeholder analysis 초안(대상·채널 스케치) →
  근거 형식(채택 요소별 "왜 이 역할 의도와 맞는지" 1줄+).
- **판단 기준**: Objectives 없이 Evaluation 기준을 정의할 수 없다 — Objectives
  절이 비어 있거나 이슈 텍스트를 그대로 복사한 경우 미완성으로 간주한다.
- **금지 사항**: phase-2 실행 내용(실제 발송 문구, 실제 채널 확정)을 phase-1
  제안서에 선반영 금지 — contract v3 s19의 phase 분리를 프러포절 콘텐츠
  레벨에서도 지킨다. campaign 성격 메시지가 섞여 있으면 즉시 hand-off
  (marketing) 판단을 내리고 흡수하지 않는다.

## (b) 병 — Phase 2 facet

`PRODUCES`의 phase-2 절 (현재 문자열 그대로 유지 + 판단기준/금지 추가, 구조
변경 없음 — `core_role_directive`는 여전히 4-인자):

- **단계**: RACE 4단계를 실행 순서대로 — Research 재확인(phase-1 survey 참조,
  재조사 아님) → Objectives 재확인 → Communication(채널/타이밍/실제 전달
  방식 확정) → Evaluation(성공 기준, **발송 전 정의** — 이 순서가
  뒤집히면, 즉 발송 후에 성공 기준을 적어 넣으면 RACE의 핵심 실패 모드).
- **판단 기준**: key message 각각에 최소 1개 proof point 필수 — 없으면 해당
  key message는 미완성. Risk/Q&A는 "사전 승인"이 필수 속성 — 승인자 서명/
  코멘트 없이 draft만 있는 답변은 미완성으로 간주.
- **금지 사항**: Evaluation 기준을 Communication 이후 섹션에 사후 소급
  기재 금지(게이트가 이를 위치로 기계 검증, (c) 참조). Core message를
  2개 이상 두는 것 금지(3-tier 구조 위반 — core는 정확히 1개).

## (c) 방법론 게이트 — 기계 검증 설계

패턴: 캐논(core `record-fields-gate.sh`, issue-66)이 contract §20 구조적
frontmatter 필드만 검사하는 것과 동일한 결(PreToolUse, path-scoped, exit
non-zero + 이유 출력)을 **한 단계 더 세밀한 콘텐츠 레벨**(section heading
존재/순서)에 적용한다. 캐논 스크립트 자체는 복사하지 않는다 — 이 게이트는
캐논이 커버하지 않는 role-specific 서브구조(RACE 4단계 순서, key-message
proof-point, pre-approved Q&A)만 본다. 순서 제약은 **단일 파일 내부**의
heading 위치 비교로 충분하다 — RACE 4단계가 phase-2 record 한 파일 안에서
선형으로 나타나야 하므로, 파일 간/세션 간 상태 저장소는 불필요하다
(scout-brief 결론). Phase-1/phase-2 자체의 순서(제안서 먼저, Approve 후
실행)는 이미 contract v3 s19의 phase 게이트가 강제하므로 이 게이트가
새로 다룰 대상이 아니다.

파일: `pr-communications/hooks/methodology-gate.sh` (신규, phase-2에서 작성).
등록: `pr-communications/hooks/hooks.json`에 `PreToolUse` 엔트리 추가,
matcher `Write|Edit`, 이 저장소 소유 경로(`docs/issue-*/reports/
pr-communications.md`)에만 적용 — 다른 role의 record는 건드리지 않는다
(write_scope 불변).

검사 항목 (실패 시 exit 1 + 어떤 섹션/순서가 문제인지 출력):

1. **필수 헤딩 존재**: `## Communications plan`, `## Key message`,
   `## Risk/Q&A prep` 세 개가 모두 있어야 한다(기존 record-template.md와
   1:1). 하나라도 없으면 실패.
2. **RACE 4단계 존재+순서**: `## Communications plan` 절 본문 안에서
   `Research`, `Objectives`, `Communication`, `Evaluation` 네 레이블이
   (예: `- **Research**` 형태의 bold-label 줄로) 모두 나타나야 하고, 그
   line 번호가 이 순서로 단조증가해야 한다. 하나라도 없거나 순서가
   뒤바뀌면 실패 — 특히 Evaluation이 Communication보다 앞에 오면 "성공
   기준을 발송 후에 적어넣는" 실패 모드로 명시해 에러 메시지에 담는다.
3. **Key message 3-tier + proof point**: `## Key message` 절 안에 `Core
   message`가 정확히 1개, 이후 아래로 최소 1개의 `Proof point`(또는 동의어
   레이블, 대소문자 무관) 언급이 있어야 한다. Core message가 0개 또는
   2개 이상이면 실패. Proof point가 전혀 없으면 실패.
4. **Risk/Q&A pre-approval 표식**: `## Risk/Q&A prep` 절 안에 최소 1개의
   질문-답변 쌍이 있고("Q:"/"A:" 또는 "질문"/"답변" 페어), "pre-approved"
   /"사전 승인" 표식이 절 어딘가에 있어야 한다. 표식 없으면 실패 — 승인자
   서명 없는 즉석 답변으로 간주.
5. **frontmatter loop_state 정합성**: `loop_state: landed`(또는 이 역할의
   terminal state)로 쓰이는 시점에만 위 4개 검사를 전부 강제한다.
   `scope-proposed` 등 중간 상태 커밋에는 게이트를 적용하지 않는다 — 이는
   phase-1 제안서 반복 수정을 막지 않기 위함(캐논의
   `RECORD_FIELDS_TERMINAL_STATES` 관례와 동일한 결).

의사코드 스켈레톤 (phase-2에서 정식 작성, 여기서는 설계 확정용):

```bash
#!/usr/bin/env bash
set -uo pipefail
# methodology-gate: RACE/key-message/risk-Q&A content check for
# docs/issue-*/reports/pr-communications.md at terminal loop_state only.
# References core's gate conventions (issue-66); does not vendor them.
trap 'echo "methodology-gate: internal error, failing closed" >&2; exit 1' ERR

file="$1"
grep -q '^loop_state: landed' "$file" || exit 0   # non-terminal write: skip

for h in '## Communications plan' '## Key message' '## Risk/Q&A prep'; do
  grep -qF "$h" "$file" || { echo "methodology-gate: missing section '$h'"; exit 1; }
done

race_lines=$(grep -noE '\*\*(Research|Objectives|Communication|Evaluation)\*\*' "$file" \
  | awk -F: '{print $1}')
# ... verify all 4 present and line numbers monotonically increasing;
#     name the specific pair that is out of order in the error message.

core_count=$(grep -ciF 'core message' "$file")
[ "$core_count" -eq 1 ] || { echo "methodology-gate: exactly one core message required, found $core_count"; exit 1; }

grep -qiF 'proof point' "$file" || { echo "methodology-gate: no proof point found"; exit 1; }

grep -qiE '(pre-approved|사전 승인)' "$file" || { echo "methodology-gate: risk/Q&A prep not marked pre-approved"; exit 1; }
```

## (d) 게이트 테스트

`tests/methodology-gate-test.sh` (신규, repo root, phase-2에서 작성).
Pass/reject 케이스:

1. **PASS** — 4개 검사 모두 통과하는 완전한 record fixture.
2. **REJECT — 섹션 누락**: `## Risk/Q&A prep` 삭제한 fixture.
3. **REJECT — 순서 위반**: Evaluation 레이블이 Communication보다 앞선 fixture.
4. **REJECT — core message 개수 위반**: core message 2개인 fixture.
5. **REJECT — proof point 없음**: key message 절에 proof point 언급 없는 fixture.
6. **REJECT — 사전승인 미표식**: Q&A 쌍은 있으나 "pre-approved"/"사전 승인"
   표식이 없는 fixture.
7. **PASS-THROUGH (게이트 미적용)**: `loop_state: scope-proposed`인 파일 —
   위 결함을 다 갖고 있어도 게이트가 개입하지 않아야 한다(터미널 상태
   전용임을 확인).
8. **내부 에러 시 fail-closed**: 존재하지 않는 파일 인자 등 비정상 입력에서
   0이 아닌 종료 코드를 반환하는지 확인 (core 게이트들의 "fail-closed on
   internal error" 관례, `docs/issue-2` 참조 계열과 동일 원칙).

## (e) 체크리스트

RACE는 issue-1 scout 결론대로 반복(hunt-cadence) 루프가 아니라 선형 4단계
프로세스이므로, 이슈가 요구하는 "반복 절차"에 해당하는 것은 agent가 아니라
**phase-2 작성 전 자가 점검 체크리스트**다. `docs/handbooks/
phase2-checklist.md` (신규, phase-2에서 작성) — record 작성자가 게이트를
돌리기 전 스스로 확인하는 5개 항목, (c)의 5개 게이트 검사와 1:1 대응:

- [ ] Communications plan에 R/O/C/E 네 레이블이 이 순서로 있다
- [ ] Evaluation 기준을 Communication보다 먼저(=발송 전) 적었다
- [ ] Core message가 정확히 1개다
- [ ] 모든 key message(core+supporting)에 proof point가 있다
- [ ] Risk/Q&A 쌍마다 "사전 승인" 표식이 있다

## (f) 채택 근거 — 왜 이 설계가 이 역할의 의도와 맞아떨어질 수밖에 없는가

- **게이트를 phase-2 record에만 걸고 phase-1 제안서에는 걸지 않는 이유**:
  phase-1 판단 기준(리서치가 충분한가, 목표가 이슈에서 도출됐는가)은 사람
  승인자의 판단 대상이지 grep으로 잡을 수 있는 구조가 아니다 — 반면
  phase-2의 RACE/key-message/Q&A는 issue-1이 이미 고정 스키마로 확정한
  구조이므로 기계 검증이 정확히 들어맞는다.
- **순서 검증을 파일 내부 heading 위치로 한 이유**: RACE의 유일한 진짜
  실패 모드(Evaluation을 사후에 적는 것)는 한 파일 안에서 일어나는 순서
  실수이고, scout 결과 이 클래스 문제에 외부 상태 저장소를 쓰는 것은
  이 저장소가 지금까지 지켜온 "캐논이 이미 잘 푸는 문제를 로컬에서 다시
  발명하지 않는다"는 원칙(issue-2)에 반한다.
- **체크리스트를 agent 대신 택한 이유**: agents/는 반복 탐색(warrant-hunter
  류) 패턴을 위한 것이고, RACE는 선형 4단계다 — 존재하지 않는 반복 루프를
  위해 agent를 만드는 것은 이슈의 요구("반복 절차가 있으면")를 문자 그대로
  충족하지 않는 곳에 무리하게 끼워 맞추는 것이다.

## Open questions for the approver

**Q1 — 게이트 실패 시 우회 경로.** 승인자가 이미 예외적으로 승인한 record
(예: risk/Q&A가 필요 없는 극히 단순한 케이스)를 게이트가 막을 가능성이
있다. Core의 다른 게이트들처럼 저장소-로컬 override 플래그를 둘지, 아니면
게이트를 항상 hard-block으로 둘지 승인자 판단을 요청한다. 권고안은 항상
hard-block(override 없음) — RACE 4요소는 issue-1이 이미 필수로 확정했으므로
예외를 두면 그 확정을 재협상하는 것과 같다.

**Q2 — core config 후속.** issue-1 Q1 / issue-2 Q1이 남긴 "core에 role별
produces 서브구조 체크를 config로 올리자"는 권고는 이 이슈로 로컬 게이트를
만들면서 자연히 대체되는가, 아니면 여전히 별도 core 이슈로 남겨 로컬 게이트를
이후 core config로 이관할 여지를 두는가. 권고안은 후자(로컬 게이트를 임시
조치로 명시, core config가 생기면 이관) — 이번 이슈도 "당장 로컬로 강제
장치를 만들라"는 요구이지 "이게 영구적으로 로컬이어야 한다"는 요구는
아니기 때문.

## Out of scope

- `directive.sh`, `methodology-gate.sh`, `tests/methodology-gate-test.sh`,
  `docs/handbooks/phase2-checklist.md`의 실제 작성/커밋 — 전부 phase-2,
  Approve 이후.
- `pricing-rulebook`의 실제 `methodology-gate.sh` 소스 열람/복사 — 이
  세션의 파일시스템 접근 범위 밖(survey 참조)이며, 이슈의 "참조만·복사
  금지" 제약과도 부합해 설계는 독립적으로 도출했다.
- core 신규 이슈 제기(Q2의 대안 경로) — 이 role의 write scope 밖.
