# Per-state file/frontmatter contract

What must exist on disk for a ticket to legitimately be in a given state (`states.md`
defines the transitions; this defines what each state *looks like* on disk, so any
agent can determine a ticket's current state by reading files, never by asking).

| State | Required on disk |
|---|---|
| `backlog` | Slice named in `SLICES.md` (or the feature's equivalent list); no `00-spec/` directory. |
| `specified` | `00-spec/spec.local.md` exists, frontmatter `status: specified`. |
| `dispatch_pending_approval` | `01-implement/handoff.local.md` exists, generated **fresh** from the current `00-spec/spec.local.md` + the feature's current `00-requirement/amendments.md` — never a cached/stale copy. This is the direct fix for amendments.md decision 8's cross-session decision drift: a stale handoff package is exactly how one session re-decides something another session already settled. |
| `dispatched` | `01-implement/handoff.local.md` plus a recorded human approval (the gate-1 write/confirmation). |
| `implementing` | No new required file — transient. `01-implement/BLOCKED.local.md` may transiently appear and disappear during this state (interactive cmux dispatch only, per `08-handoff-implement-here`) when the implementer asks a genuine blocking question — not a new top-level ticket state, since the ticket tracker/dependency graph only cares about the terminal `DONE`/`FAILED` sentinels, not mid-implementation Q&A. |
| `implemented` | Path A: sentinel `01-implement/DONE` or `01-implement/FAILED` (decision 1 — an orchestrator/human checks for the sentinel's existence, **never** polls a live pane or process). Path B: the agent's own evidence note (what it wrote, what it validated), same evidentiary weight as a sentinel. |
| `review_in_progress` | No new required file — transient (reviewer actively working). |
| (verdict recorded) | `02-review/verdict.local.md`, frontmatter `verdict: accept \| retry_with_feedback \| escalate_to_human`; for non-`accept`, also `rejection_type: fixable \| capability` — **only `fixable` may retry**. A `capability` verdict skips the retry and goes straight to `escalated`: retrying a capability gap just fails the same way twice and burns tokens doing it. Reviewers must justify the tag, not default to `fixable`. Before setting the verdict, the reviewer walks the spec's **Acceptance Checklist** (FR5, now guaranteed to exist per `07-clarify-specify-updates` — every `specify` output includes one) — this is FR20's "spec conformance" check, not just a correctness review. |
| `pending_done_approval` | The implementer/agent has presented the result and explicitly asked — has **not** written `status: done` itself. |
| `done` | `00-spec/spec.local.md` frontmatter `status: done`, plus an `evidence:` field describing what was delivered and how it was checked. Written only after gate 2's explicit human approval — see `states.md`'s retroactive note for the two tickets that skipped this. |
| `escalated` | `02-review/verdict.local.md` has `verdict: escalate_to_human`; once the human decides, `human_decision: retry_again \| reassign \| claude_implements \| abandon` is recorded in the same file. |

## Dependency graph (FR2, generalized 2026-07-15)

`depends_on` is a **list** (`depends_on: [slug, ...]`; empty or absent = no dependency),
not a single slug — every ticket so far only ever had one dependency, which is why this
wasn't caught earlier. Entries may be same-feature (`02-role-matrix-config`) or
cross-feature (`<feature-slug>/<slice-slug>`). A ticket is `blocked` (per `states.md`'s
computed overlay) if **any** entry in the list isn't `done` — read "the depends_on
slice's state" elsewhere in `states.md` as "each entry in the depends_on list."
Existing tickets' singular values remain valid (a one-element list is the same thing —
no migration needed for already-`done` tickets).

## Prioritization (FR11, derived — not independently set)

Every ticket's frontmatter carries `moscow: must | should | could | wont` (required
from this slice forward) and, optionally, `kano: basic | performance | delighter`.
**These are derived, never invented at the ticket level.** Priority originates at the
requirement level: `clarify` tags each FR/NFR/US with MoSCoW/Kano when it writes them;
`specify` sets a ticket's tags to the *highest* priority among the FR/NFR/US IDs its
spec cites (`Must` beats `Should` beats `Could` beats `Won't`). A ticket satisfying even
one Must-have requirement is a Must-have ticket regardless of what else it touches. See
`00-requirement/amendments.md`'s MoSCoW/Kano decision for this project's own frozen
requirement doc, which deferred this tagging to `/specify` explicitly.

## Token metering (closes the amendments.md token-metering gap)

Every phase subdirectory that involves an agent invocation (`01-implement/`, and
`02-review/` if the reviewer is itself a model call) gets a `tokens.local.md`:

```
---
phase: <00-spec|01-implement|02-review>
model_used: <actual model, not the assigned tier's nominal one — they can differ, see 01-system-readme's tokens.local.md for a real example of drift>
tier_assigned: <small|default|complex>
---
Tokens: <input> sent, <output> received.
```

This makes NFR1 (token spend is the only cost) and Success Criterion 3 (the second
agent didn't have to re-derive context) actually measurable instead of asserted —
`01-system-readme/01-implement/tokens.local.md` is the first real instance of this.

## Transcript capture (closes the amendments.md durable-transcript gap)

A live cmux pane or interactive session is not an audit log. Whenever a phase involves
an interactive agent session (e.g. Aider), the raw transcript is retained as a file in
that phase's subdirectory — the same pattern `01-system-readme` already used by
necessity (`.aider.chat.history.md` stayed in place as evidence rather than being
deleted, per amendments.md decision 8). Prefer copying/moving the relevant excerpt into
the phase subdirectory itself once this pattern is exercised again; for this project's
first three tickets the transcript lived at the repo root instead, which is acceptable
evidence but not yet the ideal location — a cleanup for whichever slice next touches a
real handoff (`08-handoff-implement-here`).
