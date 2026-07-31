---
subject: issue-7
role: pr-communications
---

# Scout brief (issue-7)

Mode: parallel fan-out, 2 angles in one turn (WebSearch), 1 sweep stage, no
deepening round — both angles converged on patterns already consistent with
this repo's own established conventions (core-canon reference, PreToolUse
gates on write surfaces), so judge point 1 found no mismatch and judge point
2 (saturation) said another round would not change the gate's design.
Scope: this is a mechanism-design question (how to build a content gate and
an ordering check), not a product/exemplar question, so angles targeted
"how do comparable hook-based content gates work" rather than PR-methodology
sources (already covered by issue-1's scout).

## Angles run

1. Bash pre-commit / PreToolUse-style hooks that check markdown files for
   required section headers.
2. Enforcing step ordering (state-machine / sequencing) via git hooks or file
   locks.

## Must-bes / performance axes extracted

- **Content gates are grep/heading-position checks over staged or
  about-to-be-written content**, not full parsers: check that required
  section headers (`## Communications plan`, `## Key message`, `## Risk/Q&A
  prep`) are present, and — for ordering — that heading line numbers appear
  in the required sequence. This matches the shape of `core`'s own
  `record-fields-gate.sh` (frontmatter-field presence) one level down, at
  content-section granularity instead of frontmatter-field granularity.
- **Exit non-zero + printed reason is the whole enforcement contract** for a
  `PreToolUse` hook — no separate remediation UI is expected; the message
  itself must say which section is missing/misordered and how to fix it
  (mirrors this repo's board-gate.sh error text style already observed this
  session).
- **State tracking for ordering is only needed across separate
  writes/sessions**, not within one file: a single-file positional check
  (heading line-number comparison) covers in-file sequence; a persistent
  state file/lock is the pattern for cross-invocation sequencing (e.g. "step
  A's artifact must exist before step B's write succeeds"), which is a
  different problem than checking one file's internal section order.

## Adopt / skip

- **Adopt**: a `PreToolUse` gate scoped to `Write|Edit` matcher, path-filtered
  to `docs/issue-<n>/reports/pr-communications.md`, doing (a) required-heading
  presence and (b) required-heading order via line-number comparison. No
  external state file — the ordering constraint is intra-file.
- **Adopt**: gate error output states which section is missing/out of order,
  in the same terse, contract-citing style as this repo's existing board-gate
  messages.
- **Skip**: a general state-machine/lock library — overkill for a single
  linear 4-stage in-file check; would be the kind of "vendored complexity
  copying a pattern that doesn't fit" this repo's core-canon discipline
  already warns against (docs/issue-2 precedent).
- **Skip**: gating phase-1 proposal content mechanically beyond what a human
  reviewer reads before Approve — phase-1's "판단 기준" per the issue are
  directive-text guidance for the *agent writing the proposal*, not a
  machine-checkable structural gate (a proposal's Research/Objectives content
  quality is a judgment call, not a grep target); only phase-2's record has a
  fixed, gateable produces-shape. This mirrors why issue-1 Q1 recommended
  against a local content gate at all at the time — but issue-7 now
  explicitly asks for the mechanical version issue-1 deferred, so this
  proposal adopts it for the phase-2 record only, per the gap line below.

## Gap line (vs current-state survey)

- Directive depth gap (survey point 1) → filled by proposal (a)/(b)'s
  per-facet directive text.
- Gate gap (survey point 2) → filled by proposal (c)'s gate design (adopted
  above): presence + intra-file order, no external state.
- Test gap (survey point 3) → filled by proposal (d)'s test-case list.
- Agent/checklist gap (survey point 4) → filled by proposal (e): a checklist,
  not an agent (RACE has no repeated hunt-cadence loop to justify an agent).

Sources:
- https://blog.scottlowe.org/2025/10/20/using-git-pre-commit-hooks/
- https://github.com/pre-commit/pre-commit-hooks
- https://medium.com/jungletronics/gits-pre-commit-commit-msg-hooks-9d541bb6dffd
- https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks
- https://git-scm.com/book/en/v2/Customizing-Git-An-Example-Git-Enforced-Policy
- https://git-scm.com/docs/githooks
- https://wendelladriel.com/blog/welcome-to-the-state-machine-pattern
