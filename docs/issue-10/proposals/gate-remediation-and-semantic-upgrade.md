---
subject: issue-10
role: pr-communications
loop_state: scope-proposed
---

# Proposal — 게이트 A+ 상향: 결함 수정 + 시맨틱 검사 상향 (issue-10)

Survey: [survey.md](../reports/pr-communications/survey.md).
Scout brief: [scout-brief.md](../reports/pr-communications/scout-brief.md)
(skipped — reason recorded there).

Phase 1 ONLY — this PR fixes nothing yet. It fixes the design; Phase 2
(actual gate-lib migration, semantic rewrite, test additions, README
sync) starts only after a human Approve on this PR, per contract v3 s19.

## 1. gate-lib adoption (issue의 선행 조건 — 자체 재구현 금지)

All three gates (`key-message-gate.sh`, `race-sequence-gate.sh`,
`qa-preapproval-gate.sh`) source `gate-lib.sh` and load `gate-lib.py`
exactly per `gate-house-standard.md`'s usage block, mirroring the
already-established `directive.sh` convention
(`CLAUDE_PLUGIN_ROOT_CORE:-...`):

```sh
. "${CLAUDE_PLUGIN_ROOT_CORE:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../../core" && pwd -P)}/hooks/lib/gate-lib.sh"
gate_trap_fail_closed
set -uo pipefail
gate_kill_switch_active "${RACE_SEQUENCE_GATE_DISABLE:-}" || { trap - EXIT; exit 0; }
```

replacing, one-to-one, each survey finding:

| Survey finding | Fix |
|---|---|
| #6 non-0/2 exit codes fail-open | `gate_trap_fail_closed` as the literal first statement (before `set -uo pipefail`), remapping every non-0/2 exit to 2; all internal `exit 1`s in the three scripts change to rely on the trap (or explicit `gate_deny`) instead |
| #7 hand-rolled kill switch | `gate_kill_switch_active "${<NAME>_DISABLE:-}"` replaces the `== "1"` string check in all three; on-spellings extended to `1/true/yes/on` case-insensitive, everything else (including today's bare `"1"`-only recognizers) stays active |
| — deny delivery | `gate_deny "<gate-name>" "<reason>"` replaces the ad-hoc `echo ... >&2; exit 1` pairs, standardizing the message prefix and guaranteeing exit 2 |

`gate_normalize_path`, `gate_reconstruct_write`, `gate_parse_json_or_deny`
are Python — each gate's existing pure-bash body gets a Python payload
(the repo's own `core/hooks/*.sh` convention: bash driver + inline Python
heredoc) that loads `gate-lib.py` via `GATE_LIB_PY` (exported by
`gate-lib.sh`) and calls all three. This is the mechanism for fixes 2-5
below, not a separate step.

## 2. Path matching (survey #1) — absolute-path production no-op

Each gate's Python payload calls
`gate_lib.gate_normalize_path(repo_root, file_path)` where `repo_root` is
derived once via `git rev-parse --show-toplevel` (or
`CLAUDE_PROJECT_DIR` if the harness sets it — decided in phase 2 against
whichever the running harness actually exposes; both normalize
identically through `gate_normalize_path` so the choice does not change
gate semantics, only which env read succeeds). The gate's target-path
check becomes a match against the **normalized, root-relative tail**
(`fnmatch`/regex on `issue-*/reports/pr-communications.md` with no leading
`docs/` — `gate_normalize_path` strips the root, so the pattern anchors
one level in) instead of the raw `file_path` string. This is what makes
absolute paths, `./`-prefixed paths, and today's already-working relative
paths all resolve to the same match — survey #1's production no-op is a
direct consequence of skipping this normalization, not a separate design
question.

## 3. Tool/matcher coverage (survey #2) — MultiEdit + Bash-write

- `hooks.json` matcher changes from `"Write|Edit"` to
  `"Write|Edit|MultiEdit"` in all three plugins (`NotebookEdit` is not
  added — no plugin's record file is a notebook; adding a matcher for a
  tool that can never produce a real target path is dead surface, not
  defense-in-depth).
- A fourth matcher entry, `"Bash"`, added to all three, running the same
  gate script; the gate's Python payload calls
  `gate_lib.gate_bash_write_targets(tool_input["command"])` for a `Bash`
  event and applies the same normalized-path match against each candidate
  token — same code path as `Write`/`Edit`/`MultiEdit` reach for target
  identification, differing only in how the candidate path list is
  produced. A `Bash`-tool write that matches gets the **on-disk-after**
  content (no `tool_input.content` exists for a shell heredoc the way it
  does for `Write`) checked the same way today's gates already do for
  reads — this one case does not get the pre-write reconstruction fix in
  §4, since there is nothing to reconstruct from `tool_input` alone; it
  remains a post-write check, documented as such in the gate's own
  comment.

## 4. Pre-write content check + Edit/MultiEdit/replace_all (survey #3, #4)

The core rewrite. Each gate's semantic check function currently takes a
file path and reads disk; it changes to take a **content string**, built
before any semantic check runs:

```
For Write/Edit/MultiEdit on a matched, existing target:
  current = read the file from disk (empty string if it doesn't exist — see §5)
  new_text, ok = gate_lib.gate_reconstruct_write(tool, tool_input, current)
  ok is False  -> gate_deny (old_string not found / malformed edit shape —
                   fail closed rather than silently pass an
                   undeterminable write)
  ok is True   -> run every semantic check (§6) against new_text, not
                   against disk content
```

This directly replaces every `grep`/`awk "$file"` call across all three
scripts with the equivalent operation against the in-memory
`new_text` string (`awk` becomes a Python section-scan over `new_text`
lines — moving the semantic checks into the same Python payload that
already loaded `gate-lib.py`, rather than shelling back out to bash
`awk` against a temp file, keeps one reconstruction pass authoritative).
`MultiEdit`'s per-edit `replace_all` and `Edit`'s single `replace_all`
are both exercised purely by calling `gate_reconstruct_write` — no
gate-local replace logic remains to independently get `replace_all`
wrong.

## 5. First-Write false-deny (survey #5)

`current` for a target that does not yet exist on disk is the empty
string (`""`), not a fail-closed abort — `Write` is exactly the tool that
legitimately creates the file for the first time. The existing
fail-closed-on-missing-file behavior narrows to apply only when the tool
is `Edit`/`MultiEdit` (which require the target to already exist by the
tool's own contract) or when `gate_reconstruct_write` itself returns
`ok=False`. A first `Write` with `loop_state: landed` already set and a
genuine section violation is still correctly denied — it is denied by
§6's semantic check against `new_text`, not by an existence check that
fires before `loop_state` is even inspected.

## 6. Semantic check upgrade: substring → section/adjacency/structure

Per-gate, addressing survey #8. All three keep the existing "scope to the
`## <Section>` block first" step (already correct in all three) and
replace the substring/mention count inside that scope with a structural
parse:

- **key-message-gate.sh**: within the `## Key message` section, parse
  markdown sub-structure — a "core message" and "supporting message" are
  identified by their own heading/label markers (design detail to pin in
  phase 2 against `methodology-and-artifact-norms.md`'s actual documented
  key-message format, e.g. `### Core message` / `### Supporting message`
  as the structural marker, not a bare grep for the words "core message"
  anywhere), and a "proof point" only counts when it is nested under —
  i.e. appears between one message's heading and the next message's
  heading/section end, not merely present anywhere in the section — a
  specific message's block. Exactly-one-core-message becomes a count of
  matching **headings**, not word occurrences; each message's block is
  additionally checked for at least one nested proof-point marker (the
  per-message form of today's section-wide `proof_count`).
- **race-sequence-gate.sh**: the four `**Label**` matches are re-scoped to
  fire only inside the already-verified `## Communications plan` section
  (today's `matches=$(grep -noE ... "$file")` runs over the whole file);
  additionally required to be the label starting its own line (a
  top-level entry marker within the section), not a bolded word inside a
  prose sentence — i.e. the line must match `^\*\*(Research|Action|
  Communication|Evaluation)\*\*\s*$` or `^\*\*(...)\*\*:` (exact
  delimiter choice pinned in phase 2 against existing fixture files in
  `tests/race-sequence-gate-test.sh`, which already use bare `**Research**`
  on its own line — this becomes the *required* shape, not just the
  tested one). Ordering check (already line-number based, already
  correct) is unchanged.
- **qa-preapproval-gate.sh**: Q&A pairing changes from "first Q, first A
  anywhere after it" to **adjacent pairing** — split the `## Risk/Q&A
  prep` section into pair-blocks (each block starts at a `Q:`/질문 line
  and ends at the next `Q:`/질문 line or section end), and require the
  pre-approved mark to be found **within the same pair-block** as its
  `A:`/답변 line, not merely anywhere in the section. A section with N
  Q&A pairs now requires the specific pair carrying a draft answer to
  also carry its own pre-approval mark — survey #8's "5 pairs, 1
  unrelated pre-approved mark passes" case is exactly what this closes.

## 7. Mandatory test cases (issue 요구 3, gate-house-standard.md's six)

Each of the three `tests/*-gate-test.sh` gains all six
`gate-house-standard.md` cases, adapted to that gate's own target section
(not a shared harness file — these three test files stay separate,
matching this repo's existing one-file-per-gate convention; a shared
six-case *template* of inputs is reused across the three files' fixture
construction, not a shared *runner*):

1. `Edit` with `replace_all: true` against an `old_string` occurring more
   than once in the fixture (e.g. a repeated boilerplate phrase both
   before and after the target section) — asserts only every occurrence
   changes.
2. `MultiEdit` with a mix of `replace_all: true`/`false` edits in one
   call.
3. Malformed JSON: truncated payload, non-object top level (e.g. a bare
   JSON array or string), and empty payload — all three assert deny.
4. Kill-switch env var set to an unrecognized value (e.g. `maybe`) —
   asserts the gate **stays active** (denies/allows on content exactly as
   if the var were unset), not disabled.
5. Absolute `file_path` reaching the same target a relative-path fixture
   already exercises, plus a `./`-prefixed variant — both assert the same
   verdict the existing relative-path case gets.
6. A `Bash`-tool `tool_input.command` (e.g.
   `cat > docs/issue-1/reports/pr-communications.md <<'EOF' ... EOF`) reaching
   the same target a `Write`-tool fixture already exercises.

Plus, per-gate, at least one case each for the §6 structural upgrades
specifically (a "word mentioned but not structurally present" input that
must now FAIL where the current substring check would have PASSED) —
these are the regression tests that prove the semantic upgrade actually
tightened the gate, distinct from the six mechanical cases above.

Delivery gate: full suite green (`bash tests/*.sh`, no skips) is a
Phase-2 completion condition, not optional coverage.

## 8. README sync (issue 요구 4)

Deferred to phase 2 (documenting today's bugs is not the fix — survey
#10). Each of the three plugin `README.md`s, once the gate script changes
land, gets a pass adding: the actual gate script path, the actual target
path pattern it matches (root-normalized form, not the raw glob), the
actual kill-switch env var name, and a line noting gate-lib adoption
(mirroring root `README.md`'s existing "carries no local copy, references
core canon" pattern for the trailer/record-fields/handbook-trigger
gates). No ghost files are currently referenced in any of the three
READMEs (checked in survey) — this is a completeness/accuracy pass, not a
removal.

## Compliance verification (phase-2 exit criterion)

Phase 2 closes with `core/hooks/tests/compliance-check.sh
<plugin>/hooks` run clean against all three plugin hooks dirs, plus a
copy of `core/hooks/tests/run-gate-lib-tests.sh`'s six cases adapted per
§7, cited as evidence in the PR that requests re-Approve for phase-2
delivery — matching `gate-house-standard.md`'s own per-repo migration
checklist steps 3-4.
