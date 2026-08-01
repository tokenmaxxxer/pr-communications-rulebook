# qa-preapproval

Claude Code plugin that owns the **pre-approved Risk/Q&A methodology**:
every risk Q&A pair must carry an approver's pre-approval mark — a draft
answer by itself is not enough. **Phase-2 only.**

## Phase-2-only participation

This plugin's gate only fires once a report has reached a terminal state
(`loop_state: landed`). Phase-1 drafting (any other `loop_state`) passes
through untouched — the gate does not interfere with in-progress work.

## Exact gate rule

`hooks/qa-preapproval-gate.sh` sources `core/hooks/lib/gate-lib.sh`/
`gate-lib.py` (the gate-house standard, core issue-72) for the
fail-closed trap, kill-switch, path-normalize, and Edit/MultiEdit
reconstruction machinery — see core's own `docs/handbooks/gate-house-standard.md`
(this repo carries no local copy). The `PreToolUse` hook (`hooks.json` matcher `Write|Edit|MultiEdit|Bash`)
reads the full tool-call JSON payload on stdin and acts only when the
resolved target normalizes (via `gate_normalize_path`,
absolute/relative/`./`-prefixed all alike) to
`docs/issue-<n>/reports/pr-communications.md`:

1. The gate reconstructs the **resulting** content via
   `gate_reconstruct_write` (`Write` content verbatim, `Edit`/`MultiEdit`
   honoring each edit's own `replace_all`) rather than reading stale
   on-disk content. An `Edit`/`MultiEdit` targeting a file that does not
   yet exist fails closed. A `Bash`-tool write to the same target is
   matched via `gate_bash_write_targets`, checked against on-disk content
   — no `tool_input.content` exists to reconstruct from a shell heredoc,
   so this one path stays a post-write check by necessity.
2. If `^loop_state: landed` is not present in the reconstructed content,
   the gate exits 0 (not yet terminal — out of scope).
3. The content must contain a `## Risk/Q&A prep` heading. Missing it →
   reject.
4. Within that section (heading to the next `## ` heading, or EOF), split
   into **pair-blocks**: each block starts at a `Q:`/`질문` line and runs to
   the next such line or section end (adjacency pairing — the structural
   upgrade over "first Q, first A anywhere after it", issue-10).
   - At least one pair-block must contain a draft answer (`A:`/`답변`),
     or the gate rejects (no Q&A pair with a draft answer).
   - Every pair-block that has a draft answer must also carry its own
     pre-approval mark — case-insensitive `pre-approved`, or the literal
     `사전 승인` — **within that same block**. A mark sitting on a
     different pair in the same section no longer counts; a section with
     5 pairs and one unrelated pre-approved mark now correctly rejects.
5. Otherwise, exit 0.

A target that cannot be reconstructed, or malformed JSON on stdin, fails
closed (exit 2) via `gate_trap_fail_closed` — never treated as an
automatic pass.

## Manual invocation

```sh
echo '{"tool_name":"Write","tool_input":{"file_path":"docs/issue-1/reports/pr-communications.md","content":"..."}}' \
  | ./hooks/qa-preapproval-gate.sh
```

The gate always reads the `PreToolUse` hook's JSON payload from stdin —
there is no longer a bare-path `$1` form.

## Kill switch (emergency only)

Set `QA_PREAPPROVAL_GATE_DISABLE` to `1`/`true`/`yes`/`on`
(case-insensitive) to skip the gate entirely. Any other value — including
unset, a recognized off-spelling, or an unrecognized typo — leaves the
gate **active** (`gate_kill_switch_active`). This is an emergency escape
hatch, not a normal workflow control — use it only when the gate itself is
broken and blocking an unrelated, urgent operation, and prefer fixing the
gate or the underlying document over leaving the switch on.

## Checklist

`checklists/qa-preapproval.md` holds the one self-check this plugin owns:
confirm, by eye, that **every** Q&A pair in the section — not just one —
carries a pre-approval mark. This plugin is the only one of the three
sibling plugins (`qa-preapproval`, `race-sequence`, `key-message-tiers`)
with a checklist, because it is the only gate whose mechanical check
(a single grep pass over the whole section) can be satisfied by one marked
pair while other pairs in the same section remain unmarked — a per-pair
repeated review is the one thing the grep can miss.

## Tests

```sh
./../tests/qa-preapproval-gate-test.sh
```

or, from the repo root:

```sh
./tests/qa-preapproval-gate-test.sh
```

The suite builds its own JSON payloads and pipes them on stdin. Beyond the
happy/sad path cases, it covers every mandatory case from
`gate-house-standard.md`: `Edit`/`MultiEdit` with `replace_all`, malformed
JSON, a kill-switch set to an unrecognized value, absolute/`./`-prefixed
paths, a `Bash`-tool write, a structural-upgrade regression case (5
Q&A pairs, one pre-approved mark on an unrelated pair, which the old
whole-section check would have passed), and a missing-core case (core
unreachable via both the `CLAUDE_PLUGIN_ROOT_CORE` override and the
relative `../../core` fallback, which must fail closed with exit 2).
