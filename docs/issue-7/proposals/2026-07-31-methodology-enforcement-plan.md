---
subject: issue-7
role: pr-communications
loop_state: scope-proposed
---

# Proposal — 방법론 강제 장치, 플러그인 세트로 재설계 (issue-7, 개정)

Survey: [survey.md](../reports/pr-communications/survey.md).
Scout brief: [scout-brief.md](../reports/pr-communications/scout-brief.md).

**개정 사유**: 승인자 코멘트("요구 정정")에 따라 단일 게이트/디렉티브
심화안을 폐기하고, 채택 방법론(RACE, 3-tier key message, pre-approved
Q&A — 전부 `docs/issue-1/proposals/methodology-and-artifact-norms.md`
근거) 각각을 **독립 플러그인**으로 분리, phase-1/phase-2 규범을 그
플러그인들의 **조합**으로 재구성한다. 여전히 phase 1 ONLY — 아래 모든
플러그인 파일(`plugin.json`, gate script, test, checklist fragment)은
phase-2, Approve 이후에 작성한다. 이 PR은 설계와 플러그인 목록만 확정한다.

## 플러그인 목록 (필수)

| 플러그인 | 담당 방법론 | 구성요소 | 조합 관계 |
|---|---|---|---|
| `race-sequence` | RACE 4단계(Research→Objectives→Communication→Evaluation) 순서 | phase-1/phase-2 directive facet, `hooks/race-sequence-gate.sh`(PreToolUse), `tests/race-sequence-gate-test.sh` | phase-1 규범의 유일 구성원(R/O facet) + phase-2 규범 구성원(전체 4단계 순서 게이트) |
| `key-message-tiers` | 3-tier key message(core 1개+supporting+proof point) | phase-2 directive facet, `hooks/key-message-gate.sh`(PreToolUse), `tests/key-message-gate-test.sh` | phase-2 규범 구성원 (phase-1엔 참여 안 함 — 실제 문구는 phase-2 산출물) |
| `qa-preapproval` | pre-approved Q&A(승인자 사전 승인 표식) | phase-2 directive facet, `hooks/qa-preapproval-gate.sh`(PreToolUse), `tests/qa-preapproval-gate-test.sh`, `checklists/qa-preapproval.md` | phase-2 규범 구성원 (phase-1엔 참여 안 함) |

각 플러그인은 자기 완결(directive+gate+test, 필요 시 checklist)이며
`.claude-plugin/plugin.json`을 갖고 이 레포 루트 `.claude-plugin/
marketplace.json`에 각각 별도 엔트리로 등록한다(현재는 `pr-communications`
role 플러그인 하나만 등록돼 있음 — 세 엔트리 추가는 phase-2 작업). 셋 다
단일 방법론만 담당하며, 방법론 간 결합은 아래 "조합 관계" 절이 유일한
연결고리다 — 한 플러그인이 다른 플러그인의 gate/directive를 참조하거나
호출하지 않는다(freelunch/scout이 서로 독립인 것과 같은 결).

## Phase-1 규범 = 플러그인 조합

Phase-1엔 문면 강제 대상이 RACE의 R/O 단계뿐이다(key-message tiering과
Q&A pre-approval은 실제 문구·승인이 필요한 phase-2 전용 산출물이라 phase-1
초안에는 아직 존재할 수 없다). 따라서 **phase-1 규범 = `race-sequence`
플러그인의 phase-1 facet 단독**:

- **단계**: Research(현재 상태+이해관계자 초안) → Objectives(이슈에서 도출한
  목표, 명시적으로 서술) — 이 둘만 phase-1에 존재. Communication/Evaluation은
  아직 확정 대상이 아니라 초안 스케치 수준(대상·채널 스케치)까지만 허용.
- **판단 기준**: Objectives 없이 Evaluation 기준을 정의할 수 없다 —
  Objectives 절이 비어 있거나 이슈 텍스트를 그대로 복사한 경우 미완성으로
  간주한다(사람 승인자 판단 — 기계 게이트 대상 아님, 이유는 아래).
- **금지 사항**: phase-2 실행 내용(실제 발송 문구, 실제 채널 확정, key
  message 확정, Q&A 승인)을 phase-1 제안서에 선반영 금지 — contract v3
  s19의 phase 분리를 프러포절 콘텐츠 레벨에서도 지킨다. campaign 성격
  메시지가 섞여 있으면 즉시 hand-off(marketing) 판단을 내리고 흡수하지
  않는다.
- **게이트 없음, 왜**: phase-1 판단 기준(리서치가 충분한가, 목표가 이슈에서
  도출됐는가)은 사람 승인자의 판단 대상이지 grep으로 잡을 수 있는 구조가
  아니다 — `key-message-tiers`/`qa-preapproval`이 phase-2에서 기계 게이트를
  갖는 것과 대조된다(고정 스키마 vs. 개방형 판단).

## Phase-2 규범 = 플러그인 조합

**Phase-2 규범 = `race-sequence` + `key-message-tiers` + `qa-preapproval`
세 게이트의 조합**, 전부 같은 파일(`docs/issue-*/reports/
pr-communications.md`)의 PreToolUse Write|Edit에서 순차 실행되고, `loop_state:
landed`(terminal state) 시점에만 강제한다(`scope-proposed` 등 중간 상태
커밋에는 미적용 — phase-1 제안서 반복 수정을 막지 않기 위함, 캐논의
`RECORD_FIELDS_TERMINAL_STATES` 관례와 동일한 결). 세 게이트는 서로
독립적으로 동작하며 어느 하나가 실패해도 나머지는 각자 자기 검사를
수행하고 실패 사유를 각자 출력한다(원자적 단일 스크립트가 아님 — 이래야
플러그인 하나만 교체/확장해도 나머지에 영향이 없다).

### `race-sequence` 플러그인 — phase-2 facet

- **단계**: RACE 4단계를 실행 순서대로 — Research 재확인(phase-1 survey
  참조, 재조사 아님) → Objectives 재확인 → Communication(채널/타이밍/실제
  전달 방식 확정) → Evaluation(성공 기준, **발송 전 정의** — 이 순서가
  뒤집히면, 즉 발송 후에 성공 기준을 적어 넣으면 RACE의 핵심 실패 모드).
- **게이트 검사** (`hooks/race-sequence-gate.sh`): `## Communications plan`
  절 본문 안에서 `Research`, `Objectives`, `Communication`, `Evaluation` 네
  레이블이(예: `- **Research**` 형태의 bold-label 줄로) 모두 나타나야 하고,
  그 line 번호가 이 순서로 단조증가해야 한다. 하나라도 없거나 순서가
  뒤바뀌면 실패 — 특히 Evaluation이 Communication보다 앞에 오면 "성공
  기준을 발송 후에 적어넣는" 실패 모드로 명시해 에러 메시지에 담는다.
  `## Communications plan` 헤딩 자체가 없어도 실패.

### `key-message-tiers` 플러그인 — phase-2 facet

- **단계**: key message 각각에 최소 1개 proof point 필수 — 없으면 해당
  key message는 미완성. Core message를 2개 이상 두는 것 금지(3-tier 구조
  위반 — core는 정확히 1개).
- **게이트 검사** (`hooks/key-message-gate.sh`): `## Key message` 헤딩
  존재 확인. 그 절 안에 `Core message`가 정확히 1개, 이후 아래로 최소
  1개의 `Proof point`(또는 동의어 레이블, 대소문자 무관) 언급이 있어야
  한다. Core message가 0개 또는 2개 이상이면 실패. Proof point가 전혀
  없으면 실패.

### `qa-preapproval` 플러그인 — phase-2 facet

- **단계**: Risk/Q&A는 "사전 승인"이 필수 속성 — 승인자 서명/코멘트 없이
  draft만 있는 답변은 미완성으로 간주.
- **게이트 검사** (`hooks/qa-preapproval-gate.sh`): `## Risk/Q&A prep`
  헤딩 존재 확인. 그 절 안에 최소 1개의 질문-답변 쌍이 있고("Q:"/"A:"
  또는 "질문"/"답변" 페어), "pre-approved"/"사전 승인" 표식이 절 어딘가에
  있어야 한다. 표식 없으면 실패 — 승인자 서명 없는 즉석 답변으로 간주.
- **checklist fragment** (`checklists/qa-preapproval.md`): Risk/Q&A
  쌍마다 "사전 승인" 표식이 있는지 작성자가 게이트 실행 전 자가 확인하는
  1개 항목 — 이 방법론이 반복 확인이 필요한 유일한 항목이라(각 Q&A 쌍마다
  반복) 체크리스트를 이 플러그인이 직접 소유한다.

### 공통 등록 방식 (세 플러그인 동일)

각 플러그인의 `hooks/hooks.json`에 `PreToolUse` 엔트리, matcher
`Write|Edit`, 이 저장소 소유 경로(`docs/issue-*/reports/
pr-communications.md`)에만 적용 — 다른 role의 record는 건드리지 않는다
(write_scope 불변). 패턴은 캐논(core `record-fields-gate.sh`, issue-66)이
contract §20 구조적 frontmatter 필드만 검사하는 것과 동일한 결
(PreToolUse, path-scoped, exit non-zero + 이유 출력)을 role-specific
서브구조(RACE 순서, key-message tiering, Q&A pre-approval)에 각각
적용한 것 — 캐논 스크립트 자체는 복사하지 않는다.

의사코드 스켈레톤 예시 (`race-sequence-gate.sh`, phase-2에서 정식 작성,
나머지 두 게이트도 동일 골격 — 검사 항목만 자기 플러그인 몫으로 교체):

```bash
#!/usr/bin/env bash
set -uo pipefail
trap 'echo "race-sequence-gate: internal error, failing closed" >&2; exit 1' ERR

file="$1"
grep -q '^loop_state: landed' "$file" || exit 0   # non-terminal write: skip

grep -qF '## Communications plan' "$file" || { echo "race-sequence-gate: missing '## Communications plan'"; exit 1; }

race_lines=$(grep -noE '\*\*(Research|Objectives|Communication|Evaluation)\*\*' "$file" \
  | awk -F: '{print $1}')
# ... verify all 4 present and line numbers monotonically increasing;
#     name the specific pair that is out of order in the error message.
```

## 게이트 테스트 (플러그인별 1개씩, 레포 루트 `tests/`)

각 게이트마다 독립 테스트 파일 — `tests/race-sequence-gate-test.sh`,
`tests/key-message-gate-test.sh`, `tests/qa-preapproval-gate-test.sh`.
Pass/reject 케이스(공통 골격):

1. **PASS** — 해당 플러그인이 요구하는 조건을 모두 만족하는 완전한 record
   fixture.
2. **REJECT — 담당 섹션 누락**.
3. **REJECT — 담당 조건 위반**(race-sequence: 순서 위반 / key-message:
   core 개수 위반 또는 proof point 없음 / qa-preapproval: 사전승인
   미표식).
4. **PASS-THROUGH(게이트 미적용)** — `loop_state: scope-proposed`인
   파일: 위 결함을 다 갖고 있어도 게이트가 개입하지 않아야 한다(터미널
   상태 전용임을 확인).
5. **내부 에러 시 fail-closed** — 존재하지 않는 파일 인자 등 비정상
   입력에서 0이 아닌 종료 코드를 반환하는지 확인.

## 채택 근거 — 왜 플러그인 세트인가

- **방법론당 독립 플러그인인 이유**: RACE, 3-tier key message,
  pre-approved Q&A는 issue-1이 서로 다른 근거로 각각 채택한 세 개의 별개
  방법론이다(하나의 "커뮤니케이션 방법론"이 아니라 세 개의 규범). 하나로
  묶으면 하나만 교체·확장하고 싶을 때(예: Q&A 승인 표식 방식만 바꾸는
  경우) 나머지 두 개의 게이트/테스트까지 건드려야 한다 — core의
  freelunch/scout이 서로 다른 관심사를 별도 플러그인으로 유지하는 것과
  같은 이유.
- **phase-1/phase-2 규범을 플러그인 조합으로 표현하는 이유**: "이 규범이
  왜 이렇게 구성되는가"를 플러그인 조합 관계표로 드러내면, 승인자가 각
  방법론의 phase별 참여 여부(예: key-message-tiers/qa-preapproval은 왜
  phase-1엔 없는가)를 설계 표에서 바로 검증할 수 있다 — 단일 문서 서술로
  묻혀 있던 근거를 구조화한다.
- **순서 검증을 파일 내부 heading 위치로 한 이유**: RACE의 유일한 진짜
  실패 모드(Evaluation을 사후에 적는 것)는 한 파일 안에서 일어나는 순서
  실수이고, scout 결과 이 클래스 문제에 외부 상태 저장소를 쓰는 것은
  이 저장소가 지금까지 지켜온 "캐논이 이미 잘 푸는 문제를 로컬에서 다시
  발명하지 않는다"는 원칙(issue-2)에 반한다.
- **체크리스트를 qa-preapproval 플러그인 하나만 갖는 이유**: RACE와
  key-message-tiers는 게이트만으로 자가 검증이 충분한 선형/카운트 조건인
  반면, Q&A pre-approval은 "쌍마다" 반복 확인이 필요한 유일한 항목이라
  체크리스트가 실제로 필요한 곳도 이 플러그인뿐이다 — 다른 두 플러그인에
  억지로 체크리스트를 부여하지 않는다.

## Open questions for the approver

**Q1 — 게이트 실패 시 우회 경로.** 세 게이트 각각에 대해 승인자가 이미
예외적으로 승인한 record(예: risk/Q&A가 필요 없는 극히 단순한 케이스)를
게이트가 막을 가능성이 있다. 플러그인마다 override 플래그를 둘지, 항상
hard-block으로 둘지 승인자 판단을 요청한다. 권고안은 항상 hard-block
(override 없음) — 세 방법론 모두 issue-1이 이미 필수로 확정했으므로
예외를 두면 그 확정을 재협상하는 것과 같다.

**Q2 — core config 후속.** issue-1 Q1 / issue-2 Q1이 남긴 "core에 role별
produces 서브구조 체크를 config로 올리자"는 권고는 이 이슈로 세 개의 로컬
플러그인을 만들면서 자연히 대체되는가, 아니면 여전히 별도 core 이슈로
남겨 로컬 플러그인들을 이후 core config로 이관할 여지를 두는가. 권고안은
후자(로컬 플러그인을 임시 조치로 명시, core config가 생기면 이관) —
이번 이슈도 "당장 로컬로 강제 장치를 만들라"는 요구이지 "이게 영구적으로
로컬이어야 한다"는 요구는 아니기 때문.

## Out of scope

- 세 플러그인의 `.claude-plugin/plugin.json`, `hooks/*-gate.sh`,
  `hooks/hooks.json`, `tests/*-gate-test.sh`,
  `checklists/qa-preapproval.md`, `marketplace.json` 엔트리 3개 추가 —
  전부 phase-2, Approve 이후.
- `pricing-rulebook`의 실제 `methodology-gate.sh` 소스 열람/복사 — 이
  세션의 파일시스템 접근 범위 밖(survey 참조)이며, 이슈의 "참조만·복사
  금지" 제약과도 부합해 설계는 독립적으로 도출했다.
- core 신규 이슈 제기(Q2의 대안 경로) — 이 role의 write scope 밖.
