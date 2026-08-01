# Survey — issue-10 audit findings, current state

Scope: the three PreToolUse gates this repo ships —
`key-message-tiers/hooks/key-message-gate.sh`,
`race-sequence/hooks/race-sequence-gate.sh`,
`qa-preapproval/hooks/qa-preapproval-gate.sh` — plus their `hooks.json`
matchers, tests, and READMEs.

## 1. Path matching: relative glob vs absolute path (production no-op)

All three gates gate the `case "$file" in docs/issue-*/reports/pr-communications.md)`
(or `[[ "$file" != docs/issue-*/... ]]`) form. `tool_input.file_path` from a
real Claude Code `Write`/`Edit` event is the **absolute** path the tool
actually resolved (e.g. `/home/u/repo/docs/issue-10/reports/pr-communications.md`),
which never matches a pattern anchored at `docs/...`. Confirmed against all
three: `key-message-gate.sh:19`, `race-sequence-gate.sh:33`,
`qa-preapproval-gate.sh:22`. Result: in real hook wiring the gate silently
no-ops on every real write — only the manual `<gate> <relative-path>` test
invocation path exercises the check.

## 2. Matcher/tool coverage: no MultiEdit, no Bash-write coverage

`hooks.json` in all three plugins matches only `"Write|Edit"`. A
`MultiEdit` call reaching the same file bypasses every gate entirely (not
merely mishandled — never invoked). None of the three gates use
`gate_bash_write_targets`-equivalent scanning, so a `Bash`-tool write
(`cat > docs/issue-10/reports/pr-communications.md <<EOF ...`) also bypasses.

## 3. Pre-write content check: reads the file on disk, not the write

All three gates, once a target file is identified, `grep`/`awk` the
**current on-disk content** (`"$file"`), never `tool_input.content` /
`old_string`+`new_string` / `tool_input.edits`. For `Write` this means the
gate is validating the file *before* the write it's supposed to be gating
lands — a `Write` that introduces a violation is not blocked (nothing on
disk yet reflects it at PreToolUse time), and a `Write` that fixes a
violation is not credited (disk still shows the old, violating content).
For `Edit`, the string being introduced by `new_string` is never inspected
at all.

## 4. No Edit/MultiEdit reconstruction; `replace_all` unread

Direct consequence of #3: none of the three gates reconstruct the
resulting content of an `Edit` (old_string/new_string, honoring
`replace_all`) or a `MultiEdit` (ordered edits, each with its own
`replace_all`). There is no reconstruction logic to audit for a
`replace_all`-ignoring bug because there is no reconstruction logic at all.

## 5. First-Write-of-a-file rejection (false deny on legitimate first write)

Because gates check on-disk content and treat "file doesn't exist yet" as
fail-closed (`race-sequence-gate.sh:40` `cat "$file" >/dev/null` under the
`ERR` trap; `qa-preapproval-gate.sh:29-32` explicit `[ ! -f "$file" ]` deny;
`key-message-gate.sh:24` `[[ -f "$file" ]] || { false; }`), the very first
`Write` that creates `docs/issue-<n>/reports/pr-communications.md` is
unconditionally denied — before `loop_state: landed` can ever be checked,
so even a phase-1-only write with no landed content gets refused once the
path pattern happens to match (mitigated today only by the #1 bug making
the path pattern never match in production; fixing #1 without also fixing
this exposes a new false-deny).

## 6. Deny-reason delivery: already stderr, already exit 2 — compliant

All three gates already write deny reasons to `stderr` and `exit 1` (not
`exit 2`) on internal-error paths, and `exit 1` on a semantic failure too
(e.g. `key-message-gate.sh:30,42,46,53`). Per `gate-lib.sh`'s
`gate_trap_fail_closed` contract, Claude Code only treats `0`/`2` as
defined (allow/deny); any other exit code (including this repo's `1`) is
non-blocking/fail-**open** in the harness, which is the opposite of these
scripts' own "failing closed" comments. This is the concrete case
`gate_trap_fail_closed` exists to close: remap every non-0/2 exit to 2 at
the top of the script, before any other logic can throw.

## 7. Kill switch semantics

Current form, e.g. `race-sequence-gate.sh:17`:
`[[ "${RACE_SEQUENCE_GATE_DISABLE:-}" == "1" ]]` — only the literal string
`"1"` disables; every other value, including intended on-spellings
(`true`/`yes`/`on`) and typos, stays active. This is *already* the safe
direction (unrecognized = active), unlike core's pre-issue-72 bug
(unrecognized = disabled) — but it under-recognizes the documented
on-spellings and is a third hand-rolled idiom to unify under
`gate_kill_switch_active` for consistency and single-source correctness.

## 8. Semantic checks: substring/mention, not section/adjacency/structure

- `key-message-gate.sh`: correctly scopes to the `## Key message` section
  (good — `awk` block capture) but then counts `grep -ic 'core message'`
  and `grep -ic 'proof point'` as bare case-insensitive substring counts
  anywhere in the section. A line reading "avoid over-claiming in the core
  message" or a stray Markdown comment mentioning "proof point" counts
  identically to an actual tiered entry. No check that a "proof point"
  is *attached to* a specific key message (adjacency/nesting), no check
  that exactly one message is structurally marked as core (vs. incidental
  word count).
- `race-sequence-gate.sh`: matches `**Research**` / `**Action**` /
  `**Communication**` / `**Evaluation**` as bold-label line markers
  (already stronger than bare substring) and checks line-number ordering —
  this one is closest to structural, but still accepts the label
  appearing anywhere in the document (not scoped to the `## Communications
  plan` section it just verified exists), and does not verify the four
  labels are the section's top-level subheadings rather than incidental
  bolded words inside prose.
- `qa-preapproval-gate.sh`: scopes to `## Risk/Q&A prep` (good), finds
  *a* `Q:`/`A:` or 질문/답변 pair by first-occurrence line-order (adjacency
  is checked directionally: A must appear after Q, but not immediately
  after — an A: belonging to a *different* Q pair earlier in the section
  satisfies it), then checks `pre-approved`/사전 승인 exists **anywhere in
  the whole section**, not attached to the specific Q&A pair that has a
  draft answer. A section with 5 Q&A pairs and exactly one pre-approved
  mark (on an unrelated pair) passes today.

## 9. Tests: current coverage vs issue's mandatory list

`tests/*-gate-test.sh` (337 lines total) cover ordering/section-presence
happy/sad paths per gate, invoked via the `<gate> <relative-path>`
explicit-arg form (bypassing bug #1 entirely, which is why bug #1 has
stayed invisible). None of the three test files cover: `Edit`
`replace_all: true` against a multiply-occurring `old_string`,
`MultiEdit` with mixed `replace_all`, malformed JSON (truncated /
non-object / empty), kill-switch set to an unrecognized value asserting
**stays active**, an absolute `file_path` (or `./`-prefixed) matching the
same scope a relative fixture already matches, or a `Bash`-tool write
reaching the same target. This is exactly `gate-house-standard.md`'s
six-case mandatory list — zero of six currently present.

## 10. README drift

None of the three plugin dirs (`key-message-tiers/`, `race-sequence/`,
`qa-preapproval/`) has been checked against gate-lib adoption yet since it
doesn't exist in this repo's tree pre-migration. Root `README.md`
documents only the `pr-communications` role plugin's layout and already
correctly states the trailer/record-fields/handbook-trigger gates are core
canon carried by core, not this repo — this pattern (reference, not
restate) is the one to extend to the three methodology plugins' own
READMEs once gate-lib adoption lands, each documenting: its actual gate
file, its actual `docs/issue-*/reports/pr-communications.md` target path, and its
actual kill-switch env var name — `race-sequence/README.md` and
`qa-preapproval/README.md` exist already; `key-message-tiers/README.md`
exists too — all three need a pass once the gate script changes, not
before (documenting a bug is not the fix).

## Dependency check — core issue #72 landing status

`docs/handbooks/gate-house-standard.md` and `core/hooks/lib/gate-lib.sh` /
`gate-lib.py` (read from local reference copies) describe the adopted,
landed standard: `gate_trap_fail_closed`, `gate_kill_switch_active`,
`gate_deny`/`gate_allow`, `gate_bash_write_targets` (bash);
`gate_parse_json_or_deny`, `gate_normalize_path`, `gate_reconstruct_write`
(Python, loaded via `importlib` using `GATE_LIB_PY`). The issue's
precondition ("core issue #72가 랜딩된 뒤") is met; this repo's own gates
have never sourced it (no `CORE_PLUGIN_ROOT`/`GATE_LIB_PY` reference
anywhere in this repo's hooks — confirmed via grep). `core/hooks/tests/
run-gate-lib-tests.sh` (six mandatory cases) and `compliance-check.sh`
exist as the standard's own harness/detector to reuse rather than
reinvent equivalents.
