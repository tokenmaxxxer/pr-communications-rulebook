---
subject: issue-13
role: pr-communications
loop_state: scope-proposed
---

# Proposal — gate A+ 최종 마감: 재감사 잔여 결함 보수 (issue-13)

Survey: [survey.md](../reports/pr-communications/survey.md).

Scout: skipped — every fix below is either core #75's already-landed,
already-worded canon form applied verbatim (F1/F2/F4), or a one-line
negation-guard correction to an existing regex with no external design
space (F3). No product-facing or stylistic decision is open; scouting a
category of "best-in-class PreToolUse gates" would not change any of
these four patches. F6/F7 are verification-only, not builds.

Phase 1 ONLY — this PR designs the fix, it does not apply it. Phase 2
(the actual edits, test additions, README line updates, and the
compliance-check run) starts only after a human Approve on this PR, per
contract v3 s19.

## 1. F1 + F2 — `||`-guard every core-lib source line (issue 요구 1, common)

Apply core #75's exact usage-contract form
(`core/hooks/lib/gate-lib.sh`'s own header comment) to all four source
sites, changing only the guard clause — nothing else on the line moves:

```sh
# key-message-gate.sh:19, qa-preapproval-gate.sh:19, race-sequence-gate.sh:18
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh" \
  || { echo "<gate-name>.sh: cannot source gate-lib.sh" >&2; exit 2; }
```

```sh
# pr-communications/hooks/directive.sh:5
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/role-directive.sh" \
  || { echo "directive.sh: cannot source role-directive.sh" >&2; exit 2; }
```

`<gate-name>.sh` in each message is the gate's own filename, matching the
existing `GATE_NAME`/`gate_deny` message-prefix convention already used
elsewhere in these scripts — no new naming decision. `gate_trap_fail_closed`
stays the *next* statement after the guarded source (per the canon usage
block) so a source failure exits 2 directly via the guard's own `exit 2`,
never reaching a trap that isn't installed yet — this is why the guard's
own `exit 2` is required rather than relying on the not-yet-installed
trap to catch it.

`directive.sh` is a SessionStart hook, not a PreToolUse gate — it has no
`gate_trap_fail_closed`/`gate_deny` machinery to lean on, so its guard
clause is self-contained (`exit 2` directly on failure), matching the
`||`-guard pattern's own general form from core #75's comment, not the
gate-specific deny wrapper.

## 2. F3 — negative-match guard on qa-preapproval's approval regex (issue 요구 1, 'NOT pre-approved')

`qa-preapproval-gate.sh:129`'s `APPROVED_RE` changes from a bare
substring search to one that requires the match not be immediately
preceded by a negation:

```python
APPROVED_RE = re.compile(r'(?<!not\s)(?<!아니|미)(?:pre-approved|사전\s*승인)', re.I)
```

Design constraint: the negation set stays narrow and explicit (`not `
immediately before, plus the two Korean negation morphemes that would
directly precede the approval phrase — `아니`/미승인-shaped "미") rather
than a general sentiment classifier — this mirrors the gate's existing
philosophy (structural/lexical checks, not NLP) and keeps the fix a
one-line regex change reviewable against the exact failure case the
re-audit named. A negation appearing elsewhere in the same pair-block
(e.g. a separate sentence unrelated to the approval mark) is out of
scope — the fix targets the literal "NOT pre-approved" adjacency the
audit found, not a general sentiment scan across the block.

## 3. F4 — missing-core test case, all three gates (issue 요구 3)

Each `tests/*-gate-test.sh` gains core #75's mandatory case group 7,
adapted to that file's existing harness style (env-var override, not a
shared runner — matching the established one-file-per-gate convention):

```sh
# invoke the gate with CLAUDE_PLUGIN_ROOT_CORE pointed at a path that
# does not exist and no valid relative ../../core fallback (run from a
# scratch dir outside the repo, or with the relative fallback also
# redirected) -> expect exit 2 with a "cannot source gate-lib.sh" message,
# not exit 0 (silent allow) and not a bare interpreter crash.
```

Concretely: a case that `cd`s the test invocation into a `mktemp -d`
working directory (breaking the `../../core` relative fallback) while
also exporting `CLAUDE_PLUGIN_ROOT_CORE=/nonexistent/path`, then asserts
the gate's exit code is `2` and stderr contains "cannot source
gate-lib.sh" (the exact message from §1's guard clause) — proving F1's
fix denies rather than silently passing when core truly cannot be found,
not merely that the guard clause exists in the source.

## 4. F5 — harmless-Bash-allow regression test, all three gates (issue 요구 1)

One case per test file: a `Bash` `tool_input.command` that touches no
path resolving to `docs/issue-*/reports/pr-communications.md` (e.g. `git
status` or `ls docs/`), asserting exit `0` with empty stderr — the
positive complement to the existing Bash-write-denies case (case 12 in
the current suites), closing the gap the survey found: today only the
deny path for Bash is tested, never the pass-through path.

## 5. F6/F7 — verification evidence, no code change

- F6 (matcher/coverage parity): cite the current `hooks.json` matcher
  strings for all three plugins as already-correct in the phase-2 delivery
  record — no diff.
- F7 (ghost files): re-run the same backticked-path cross-reference the
  survey did as part of phase-2's delivery evidence (documented state,
  not a new script — the check is cheap enough to redo by hand each time
  and doesn't warrant a permanent CI script for three READMEs). The one
  actual edit under F7 is updating the "covers every mandatory case from
  `gate-house-standard.md`" line in `race-sequence/README.md`,
  `key-message-tiers/README.md`, and `qa-preapproval/README.md` from
  naming six cases to naming all seven (adding the missing-core case),
  once F4 lands — keeping the doc and the standard in sync rather than
  re-drifting the moment this fix ships.

## Phase-2 exit criteria (issue 요구 3)

1. `bash tests/*.sh` green, including the new F4/F5 cases, for all three
   gates.
2. `core/hooks/tests/compliance-check.sh <plugin>/hooks` clean against
   `key-message-tiers/hooks`, `qa-preapproval/hooks`, `race-sequence/hooks`
   (currently FAILs all three on F1; `pr-communications/hooks` has no
   `*-gate.sh` file so stays a no-op pass, unaffected by F2's separate
   fix, which compliance-check's filename filter cannot see — recorded as
   verified by direct inspection instead, per F2's finding).
3. `docs/issue-13/reports/pr-communications.md` records the compliance-check
   and full-suite-green output as the "pass 기록" issue 요구 3 asks for.
4. The three README "mandatory case" lines and the F3 regex both reviewed
   against this proposal's exact wording before merge.
