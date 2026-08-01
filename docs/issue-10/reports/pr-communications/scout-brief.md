# Scout brief — issue-10

**Skipped.** Reason: the issue's own precondition names the exact,
already-landed reference implementation to adopt — `core/hooks/lib/
gate-lib.sh`/`gate-lib.py` + `docs/handbooks/gate-house-standard.md`
(core issue #72) — and explicitly forbids self-reimplementation. There is
no open "which pattern fits this field" decision to scout: the survey
(`survey.md`) already read gate-lib.sh, gate-lib.py, and the standard doc
in full as the current-state check, and that reading **is** the exemplar
comparison the issue calls for (its API surface is the bar; adoption
is mechanical, not a design choice among competing external patterns).
The one genuinely open design decision — how to upgrade "substring match"
to "section/adjacency/structure" for each of the three methodologies'
own semantics (key-message tiers, RACE order, Q&A pre-approval) — is
intrinsic to this repo's own already-adopted methodology definitions
(`docs/issue-1/proposals/methodology-and-artifact-norms.md`), not a
field with external best-in-class exemplars to sweep; it is designed
directly in `proposal.md` from the survey's per-gate findings (survey.md
§8) instead.
