# Ticket state machine

Canonical states for a slice ticket (a `<NN>-<slug>/` directory under a feature's
`.agents/features/<feature-slug>/`). An agent may only write the *next* valid state per
the tables below — never skip ahead. This is what makes Haiku-safe-as-default-orchestrator
(amendments.md decision 4) work: the orchestrator's job is "check the table, write the
next state," not judgment.

## Two paths

There are two ways a ticket moves from `specified` to `done`, depending on whether
implementation crosses to a *different* agent/session or stays with the one that wrote
the spec. This distinction matters because the `dispatch_pending_approval` gate exists
specifically to approve *crossing to another agent* — it has no purpose when no crossing
happens.

### Path A — Handoff (implementer is a different agent, e.g. Aider)

| From | To | Triggered by | Recorded |
|---|---|---|---|
| `backlog` | `specified` | whoever runs `/specify` for this slice | `00-spec/spec.local.md` created, `status: specified` |
| `specified` | `dispatch_pending_approval` | orchestrator, once a handoff package is ready | `01-implement/handoff.local.md` drafted (not yet approved) |
| `dispatch_pending_approval` | `dispatched` | **human only** (gate 1, amendments.md decision 2) | explicit human approval recorded (file write or interactive confirmation) |
| `dispatched` | `implementing` | orchestrator, at the moment the implementer agent is actually invoked | — |
| `implementing` | `implemented` | the implementer agent itself | sentinel `01-implement/DONE` or `01-implement/FAILED` written (never inferred by polling) |
| `implemented` | `review_in_progress` | reviewer (per FR17's `code_reviewer`/`spec_reviewer` role) | — |
| `review_in_progress` | `pending_done_approval` | reviewer, verdict `accept` | `02-review/verdict.local.md` (`verdict: accept`) |
| `review_in_progress` | `dispatch_pending_approval` (retry_count+1) | reviewer, verdict `retry_with_feedback` | `verdict.local.md` (`verdict: retry_with_feedback`, `rejection_type: fixable`) — **only `fixable`, never `capability`** |
| `review_in_progress` | `escalated` | reviewer, verdict `escalate_to_human` (either a `capability` rejection, or a second `fixable` rejection after the one retry) | `verdict.local.md` (`verdict: escalate_to_human`, `rejection_type`) |
| `pending_done_approval` | `done` | **human only** (gate 2, amendments.md decision 2) | explicit human approval recorded |
| `escalated` | (human's choice) | **human only** | `human_decision: retry_again \| reassign \| claude_implements \| abandon` recorded, then re-enters the table at the matching point |

### Path B — Implement-here (same agent implements directly, no handoff)

No agent-crossing occurs, so `dispatch_pending_approval`/`dispatched` don't apply — but
the completion gate still does; finishing the work is not the same as a human having
looked at it.

| From | To | Triggered by | Recorded |
|---|---|---|---|
| `backlog` | `specified` | whoever runs `/specify` | `00-spec/spec.local.md`, `status: specified` |
| `specified` | `implementing` | the same agent, choosing implement-here | — |
| `implementing` | `implemented` | that agent, when its own work + self-check against the spec's Test plan is complete | evidence recorded (what was written, what was validated) — same evidentiary bar as a sentinel file, just self-attested rather than a separate implementer's signal |
| `implemented` | `pending_done_approval` | that agent | presents the result and explicitly asks; does **not** write `status: done` itself |
| `pending_done_approval` | `done` | **human only** (gate 2) | explicit human approval |

**Retroactive note (2026-07-15, discovered while implementing this very ticket):** slices
`02-role-matrix-config` and `03-repo-bootstrap` were marked `status: done` directly by the
implementing agent, without pausing at `pending_done_approval` to ask first — skipping
gate 2. This is exactly the failure mode Risk #2 below exists to prevent. Not backfilled
retroactively (the human accepted both in the conversation that followed, informally
satisfying the gate's intent after the fact), but this ticket (`04`) is the first to
follow the corrected Path B honestly: implemented, then held at `pending_done_approval`
for explicit approval before this file's own `status` is written as `done`.

## `backlog` and the computed `blocked` overlay

`backlog` = a slice named in its feature's agreed slice order (e.g. `SLICES.md`) with no
`00-spec/` directory yet.

**`blocked` is not a stored state.** It's a read-time overlay: any ticket in `backlog` or
`specified` whose `depends_on` slice is not itself `done` displays as blocked. Computed
by reading the depended-on ticket's current state — never a separate flag, so it cannot
drift out of sync with reality.

## Roles permitted per transition (FR17)

- `orchestrator`: `backlog→specified` (delegates to whoever runs `/specify`), prepares
  `dispatch_pending_approval`, advances `dispatched→implementing`.
- `implementer`: `implementing→implemented`.
- `code_reviewer` / `spec_reviewer` (per the ticket's nature): `implemented→review_in_progress→{...}`.
- **human** (no agent role substitutes): both approval gates, and all `escalated` decisions.
