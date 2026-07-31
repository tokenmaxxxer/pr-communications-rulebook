---
subject: issue-1
role: pr-communications
loop_state: scope-proposed
---

# Proposal — pr-communications 방법론·산출물 규범 (issue-1)

Survey: [survey.md](../reports/pr-communications/survey.md).
Scout brief: [scout-brief.md](../reports/pr-communications/scout-brief.md).

## (a) Phase 1 제안서 규범

**방법론: RACE (Research → Objectives → Communication → Evaluation, 이하
근거 참조)의 R+O 단계를 phase-1 제안서 범위로 채택한다.** phase-2 실행
(Communication)과 성과 측정(Evaluation)은 phase-2 산출물에서 다룬다 — 이미
이 컨트랙트가 강제하는 phase-1/phase-2 분리와 RACE의 4단계가 자연스럽게
겹친다.

phase-1 제안서 필수 섹션:

1. **Research** — 이 커뮤니케이션이 걸리는 상황/이슈에 대한 현재 상태 요약과
   (해당 시) 이해관계자 목록 초안. `docs/issue-<n>/reports/pr-communications/survey.md`가
   이 자리를 채운다.
2. **Objectives** — 이 커뮤니케이션으로 달성하려는 목표를 이슈 텍스트에서
   도출해 명시. 목표가 없으면 Evaluation 단계에서 무엇을 측정할지 정의할 수
   없으므로 필수.
3. **Stakeholder analysis (초안)** — 대상 청중과 채널 매칭 스케치. phase-2에서
   전체 목록으로 확정되지만, phase-1에서 최소 후보군을 밝힌다.
4. **근거 형식** — 채택한 방법론/구성요소 각각에 "왜 이 역할의 의도된 가치와
   맞아떨어질 수밖에 없는지"를 한 줄 이상 명시 (이슈-1의 명시적 요구).

## (b) Phase 2 산출물 규범

**방법론: RACE의 Communication 단계 실행 + Evaluation 기준 명시.**

phase-2 필수 구성요소 (`produces` 필드 세 항목을 각각 이렇게 구체화):

1. **Communications plan** — RACE 4단계를 모두 명시한 문서: Research(요약,
   phase-1 survey 참조), Objectives, Communication(전달 방식/채널/타이밍),
   Evaluation(성공 기준 — 발송 *전에* 정의, 사후 정의 금지, RACE의 핵심
   실패 모드).
2. **Key message** — **3계층 구조 필수**: core message(1개) + supporting
   messages + proof points. 각 key message는 최소 1개의 proof point(근거/
   사실)를 명시해야 한다 — 근거 없는 key message는 미완성으로 간주.
   1~3문장/메시지, 페이지당 최대 약 3개 권장(강제 게이트 대상 아님, 서술
   가이드).
3. **Risk/Q&A prep** — 예상 질문 + **사전 승인된** 답변 캐시. "위기 발생 시
   즉석 작성"이 아니라 사전 준비물로 취급한다.

## (c) 채택 근거

- **RACE 채택 이유**: 이 역할의 `decides`("메시지가 외부에 어떻게 읽힐지")와
  `use_when`("외부 커뮤니케이션이 걸릴 때")은 정의상 리서치 없이는 판단할 수
  없는 질문이다 — "어떻게 읽힐지"는 청중을 모르고는 답할 수 없다. RACE는
  업계 표준 4단계 프로세스(Marston 1979, Cutlip-Center-Broom 계열)이며,
  이미 이 컨트랙트가 강제하는 phase-1(조사+계획)/phase-2(실행) 분리와
  1:1로 대응한다 — 새 구조를 발명하지 않고 기존 컨트랙트 위에 업계 표준을
  얹는 선택이다.
- **3계층 key-message 구조 채택 이유**: scout 결과 전 앵글에서 수렴한
  패턴이며, `produces`의 "key message"가 근거 없이 나열되는 것을 막는다 —
  이 역할이 만드는 메시지가 "외부에 어떻게 읽힐지"를 책임지는 역할이라면,
  각 메시지가 왜 그렇게 읽힐 것으로 기대하는지(proof point)를 명시하는 것이
  역할의 존재 이유와 직결된다.
- **사전 승인 Q&A 채택 이유**: `hand-off`가 "캠페인 성격 메시지는 →
  marketing"으로 이미 이 역할을 위기/외부 대응 중심으로 좁혀 놓았다 — 위기
  상황에서 즉석 답변은 이 역할이 통제해야 할 "메시지가 어떻게 읽힐지"를
  잃는 실패 모드이므로, 사전 준비가 방법론적으로 필수다.
- **Evaluation-before-send 채택 이유**: RACE의 "E" 단계 자체가 사후 측정
  기준을 사전에 정의하도록 요구하며, 이는 phase-2 record가 "무엇을
  했는가"뿐 아니라 "성공을 어떻게 판단할 것인가"를 담아야 한다는 기존
  record 규율 강화 조항(이슈-1 제약: "record 규율·문서화 의무는 기존 강화
  조항 유지")과 정합적이다.

## (d) 플러그인 반영 계획

issue-2의 core-canon 전환 패턴을 그대로 따른다 — 캐논 스크립트 복사 금지,
참조만.

- **directive.sh**: `PRODUCES` 인자 문자열을 아래처럼 구체화한다 (구조
  변경 없음, 값만 확장):
  `"PRODUCES (required record fields): communications plan (RACE: research/objectives/communication/evaluation), key message (core+supporting+proof point), risk/Q&A prep (pre-approved)"`.
  `core_role_directive`의 4-인자 shape(`you_decide`/`use_when`/`produces`/
  `hand_off`)는 그대로 유지 — issue-2가 이미 이 shape을 core 표준으로
  확정했으므로 새 인자를 추가하지 않는다.
- **record 필수 필드**: phase-2 record(`docs/issue-<n>/reports/pr-communications.md`)에
  아래 3개 하위 섹션을 필수화 — `## Communications plan` (4단계 명시),
  `## Key message` (core/supporting/proof point 구분 표기), `## Risk/Q&A prep`
  (질문-승인답변 쌍 목록). 이는 core의 구조적 게이트(frontmatter 필드 존재
  여부)가 커버하지 않는 영역이므로, 이슈-2 Q1과 동일한 성격의 갭이다.
- **게이트**: core의 `record-fields-gate.sh`(core issue-66)는 frontmatter
  구조만 검사하고 이 3-섹션 내용 요구는 검사하지 않는다. issue-2 Q1의
  권고(c)를 그대로 따라 — **로컬 게이트 재구현 대신 core에 role별
  `produces` 하위구조 체크 기능을 새 core 이슈로 제기**하고, 그 사이에는
  이 문서(및 phase-2 record 템플릿)를 규율로 삼아 수동 준수한다. 로컬 게이트
  스크립트를 새로 작성하는 것은 issue-2가 방금 제거한 "캐논 복사본" 패턴을
  반복하는 것이므로 피한다.
- **적용 시점**: 이 반영(directive.sh 문자열 수정, record 템플릿 확립)은
  phase-2 작업이다 — 이 PR(phase-1)은 제안서만 제출하고, 승인 후 phase-2에서
  실행한다.

## Open question for the approver

**Q1 — 로컬 콘텐츠 게이트 여부.** (c)의 게이트 절에서 core 이슈 제기 +
수동 준수를 권고했으나, 대안으로 이 저장소에 한해 3-섹션 존재를 검사하는
얇은 로컬 `PreToolUse` 게이트를 두는 방안도 가능하다(issue-2가 제거한 것은
"캐논이 이미 커버하는 것의 복사본"이었지, "캐논이 커버하지 않는 신규
로컬 체크"는 별개 판단이 필요). 권고안(core 이슈 제기, 로컬 게이트 없음)을
따를지, 로컬 게이트를 병행할지 승인자 판단을 요청한다.

## Out of scope

- 이번 phase-1에서는 실제 `directive.sh`/record 템플릿 변경을 하지 않는다
  (이슈-1 명시: "phase 1 ONLY — proposal PR까지만").
- warrant-hunter core-canon 참조 구조는 이슈-1과 무관, 변경 없음.
