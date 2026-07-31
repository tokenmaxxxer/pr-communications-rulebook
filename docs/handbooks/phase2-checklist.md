---
role: pr-communications
---

# Phase-2 checklist — plugin-set gates (issue-7)

Before writing a `docs/issue-<n>/reports/pr-communications.md` record
with `loop_state: landed`, self-check against each plugin's gate — the
gates enforce this mechanically, but catching it before the write saves
a round-trip:

- [ ] **race-sequence** — `## Communications plan` section states
  **Research**, **Action**, **Communication**, **Evaluation** in that
  order (bold labels), Evaluation criteria written before Communication
  describes the actual send.
- [ ] **key-message-tiers** — `## Key message` section has exactly one
  **Core message** and at least one **Proof point** per message.
- [ ] **qa-preapproval** — `## Risk/Q&A prep` section has at least one
  Q/A pair and a `pre-approved`/`사전 승인` mark (see
  `qa-preapproval/checklists/qa-preapproval.md` for the per-pair
  self-check this plugin owns).

Each item maps to one independent plugin's gate (`race-sequence/`,
`key-message-tiers/`, `qa-preapproval/` at repo root) — see this record's
`docs/issue-7/reports/pr-communications.md` for what each plugin
delivers and why they stay separate.
