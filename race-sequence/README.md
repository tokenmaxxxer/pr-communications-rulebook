# race-sequence

Owns the **RACE sequencing methodology**: Research -> Action -> Communication
-> Evaluation.

## Naming correction

The second letter of RACE is **Action**, not "Objectives". An earlier round
of review mislabeled it and an approver required it be corrected back to
"Action". Every label, doc string, and gate check in this plugin uses
"Action" — never "Objectives".

## Phase-1 vs phase-2 participation

- **Phase-1 (draft stage):** only Research and Action are finalized.
  - Research: current-state summary + stakeholder draft.
  - Action: goals drawn explicitly from the issue — concretely stated
    objectives/next actions, not a copy-paste of the issue text.
  - Communication and Evaluation exist only as a target/channel sketch; they
    are not finalized in phase-1.
- **Phase-2 (landed stage):** the full 4-stage RACE order is enforced:
  1. Research — reconfirmed from the phase-1 survey (not re-researched).
  2. Action — reconfirmed from phase-1.
  3. Communication — channel, timing, and actual delivery confirmed.
  4. Evaluation — success criteria defined **before** send. Defining
     success criteria after the send is RACE's core failure mode.

## Gate rule enforced

`hooks/race-sequence-gate.sh` sources `core/hooks/lib/gate-lib.sh`/
`gate-lib.py` (the gate-house standard, core issue-72) for the fail-closed
trap, kill-switch, path-normalize, and Edit/MultiEdit reconstruction
machinery — see core's own `docs/handbooks/gate-house-standard.md` (this
repo carries no local copy). The `PreToolUse`
hook (`hooks.json` matcher `Write|Edit|MultiEdit|Bash`) reads the full
tool-call JSON payload on stdin and acts only when the resolved target
normalizes (via `gate_normalize_path`, absolute/relative/`./`-prefixed all
alike) to `docs/issue-<n>/reports/pr-communications.md`. It is a no-op for
anything else.

For an in-scope write:

1. The gate reconstructs the **resulting** content via
   `gate_reconstruct_write` (`Write` content verbatim, `Edit`/`MultiEdit`
   honoring each edit's own `replace_all`) rather than reading stale
   on-disk content. A `Bash`-tool write to the same target is matched via
   `gate_bash_write_targets`, checked against on-disk content — no
   `tool_input.content` exists to reconstruct from a shell heredoc, so
   this one path stays a post-write check by necessity.
2. If the reconstructed content lacks `loop_state: landed`, the write
   passes through un-gated (non-terminal writes such as `scope-proposed`
   are not checked).
3. If terminal, the content must contain a `## Communications plan`
   heading.
4. Within that section (not the whole document), all four labels —
   `**Research**`, `**Action**`, `**Communication**`, `**Evaluation**` —
   must each start their own line (`**Label**` or `**Label**:`, not a
   bolded word inside a prose sentence — the structural upgrade over a
   whole-document grep, issue-10), and their line numbers must appear in
   that exact, strictly increasing order. Any missing label or any
   out-of-order pair fails the gate with a message naming the specific
   problem (e.g. "Evaluation appears before Communication").

A target that cannot be reconstructed, or malformed JSON on stdin, fails
closed (exit 2) via `gate_trap_fail_closed` — never treated as an
automatic pass.

## Manual invocation for testing

```sh
echo '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-1/reports/pr-communications.md","content":"..."}}' \
  | ./hooks/race-sequence-gate.sh
```

The gate always reads the `PreToolUse` hook's JSON payload from stdin —
there is no longer a bare-path `$1` form. Exit code `0` = pass/pass-through.
Non-zero (2) = rejected (message on stderr).

## Kill switch

Set `RACE_SEQUENCE_GATE_DISABLE` to `1`/`true`/`yes`/`on` (case-insensitive)
to skip the gate entirely and log a notice to stderr. Any other value —
including unset, a recognized off-spelling, or an unrecognized typo —
leaves the gate **active** (`gate_kill_switch_active`). This is an
**emergency admin escape hatch only** — not a routine bypass. Use it only
when the gate itself is broken and blocking unrelated work; remove it as
soon as the underlying issue is fixed.

## Tests

Run the gate's test suite from the repo root:

```sh
./tests/race-sequence-gate-test.sh
```

The suite builds its own JSON payloads and pipes them on stdin. Beyond the
happy/sad path cases, it covers every mandatory case from
`gate-house-standard.md`: `Edit`/`MultiEdit` with `replace_all`, malformed
JSON, a kill-switch set to an unrecognized value, absolute/`./`-prefixed
paths, a `Bash`-tool write, a structural-upgrade regression case (all
four labels present as bolded words in prose, not as top-level entries,
which the old whole-document grep would have passed), and a missing-core
case (core unreachable via both the `CLAUDE_PLUGIN_ROOT_CORE` override and
the relative `../../core` fallback, which must fail closed with exit 2).
