---
name: handoff
description: Package a specified ticket for a different agent to implement, resolve the implementer via role-matrix tiers, dispatch interactively (live cmux pane, primary) or via a one-shot batch script (fallback), relay any blocking questions to the human without answering them itself, and review the result against the spec's Acceptance Checklist once it lands. Cloud-sync aware.
---

# Handoff Skill

Dispatches an already-specced ticket to a different agent/session than the one that
wrote the spec, then reviews the result. See `README.md` for why interactive dispatch
is primary (not the batch script), why the orchestrator never answers a sub-agent's
question itself, and the incident this formalizes.

## Invocation

Parse the input to extract:
- **--feature SLUG**: the feature this ticket belongs to
- **--slice SLUG**: the slice/ticket to hand off (must be `status: specified`)

If the ticket isn't `specified` yet, stop and say so — run `specify` first.

## 1. Resolve the implementer

Read the ticket's `00-spec/spec.local.md` `complexity` tag. Read
`.agents/role-matrix.default.json`'s `roles.implementer.tiers`, overridden by
`.agents/role-matrix.project.json` if present, matched to `complexity` with fallback to
`tiers.default` if the specific tier is absent. Result: an `{agent, model, vendor}`
triple.

## 2. Generate the handoff package

Write `01-implement/handoff.local.md`, generated **fresh** from the *current*
`00-spec/spec.local.md` plus the feature's *current* `00-requirement/amendments.md` —
never cached (decision 8's fix). Include this instruction block verbatim at the top:

```
If you are genuinely blocked on a decision you can't make yourself, write
01-implement/BLOCKED.local.md with your question and wait — don't guess. On success,
write 01-implement/DONE. On unrecoverable failure, write 01-implement/FAILED with why.
If this ticket's frontmatter has a `github_issue`, any PR you open must close that
issue and only that issue — never the `parent_issue`, if one is present. The parent/
epic issue is closed manually once every slice is done, not by any single slice's PR.
```

## 3. Prepare dispatch — cmux (primary) or batch script (fallback)

Check `cmux ping`.

**cmux available**: prepare (don't send yet) a startup command that launches the
resolved agent **interactively** — no `--yes-always`/non-interactive flags — in a fresh
pane, with the handoff package as its first input (e.g. for `aider`:
`aider --model <resolved model> --no-git --read 01-implement/handoff.local.md`, then a
follow-up message telling it to proceed).

**cmux unavailable**: generate a non-interactive batch script instead (same shape as
`01-system-readme`'s dispatch script: shebang, `set -euo pipefail`, resolved
model/agent, `--yes-always --message-file`), with the sentinel writes baked into the
script itself since there's no live pane to relay follow-up input into: write
`01-implement/dispatched.local.md` first, invoke the agent, then write `DONE`/`FAILED`
on exit. `chmod +x` it.

Do **not** send/run either path yet.

## 4. Dispatch-approval gate — stop here

`.agents/orchestration/states.md`'s `dispatch_pending_approval` gate. Present what was
prepared and **explicitly ask** for approval. Generating/preparing dispatch is not
approval — nothing below runs until a distinct, explicit approval act is recorded.

## 5. Execute — only after approval

**cmux path**: write `01-implement/dispatched.local.md`, then run the routine,
predictable part of the sequence as **one shell invocation, not several separate tool
calls** — `cmux new-pane`, capture its `surface:N` ref, `cmux rename-tab --surface
surface:N "dispatch-<slice-slug>"` (always name it — a project with more than one pane
open makes an unnamed one indistinguishable from the others, a real problem hit live
implementing this skill), then `cmux send`/`send-key` the startup command. Batching
these into a single script is a token-cost concern (NFR1), not a speed one — this
project's cost function explicitly excludes wall-clock time; the actual waste is
separate `Bash` tool round-trips for steps that don't need independent inspection
between them. Reaching for the raw Unix socket instead of the `cmux` CLI wouldn't help
this — the CLI already talks to the socket directly, and hand-writing the underlying
RPC protocol would cost more tokens to construct correctly, not fewer.
**Batch path**: present the script for the human to run themselves.

Either way, the human's approval is what's recorded — this skill doesn't decide to
dispatch on its own regardless of which transport executes it.

## 6. Detect state — push notification, never polling

Watch `01-implement/` for `DONE`, `FAILED`, or `BLOCKED.local.md` appearing, using the
`Monitor` tool with an `inotifywait`-based command (one push notification the instant
any of the three appears) — not a `sleep`-loop content check, and never reading cmux
pane text as the signal.

## 7. On `BLOCKED.local.md`

Read the question. **Relay it to the human — never answer it yourself**, even if the
answer seems obvious; this is the one invariant the whole interactive-dispatch design
exists to protect (see README). Once the human answers, `cmux send-panel` the answer
into the live pane, rename the marker to `BLOCKED-N-answered.local.md` (supports
multiple rounds, keeps an audit trail), and resume watching (step 6). This path only
applies to the cmux transport — the batch script has no live pane to relay an answer
into, so a batch-dispatched implementer that gets stuck simply fails (`FAILED`).

## 8. On `DONE` or `FAILED` — review

`FAILED` always resolves to `rejection_type: capability` — a process failure isn't a
fixable spec-conformance gap. On `DONE`, read the evidence and walk the spec's
Acceptance Checklist line by line. Record `02-review/verdict.local.md`:

```
---
verdict: accept | retry_with_feedback | escalate_to_human
rejection_type: fixable | capability   # only for non-accept
---
```

- `fixable`: exactly one automatic retry — regenerate the handoff package (step 2)
  with the review feedback appended, then return to step 4 for a fresh approval (a
  retry is a new dispatch; it goes through the gate again too).
- `capability`: skip the retry, go straight to `escalated`, per FR18.
- `accept`: proceed to `pending_done_approval` — present, don't self-write
  `status: done`, same discipline `implement-here` already follows.

Either way — once `done` is approved, or once `escalated` — suggest (don't run) `retro`
for this ticket, if the project has that skill. A suggestion only, same pattern
`specify` already uses for its own next step.

## Cloud sync

Read `.agents/config.md`'s `cloud:` field. If non-`none`, comment the handoff package
onto the ticket's **own mapped issue** (`github_issue` — the slice's own child issue if
this feature was sliced, never the `parent_issue`) when dispatching, and comment the
verdict there when review completes — comment-only, never edit the issue body. On
`accept`, if this ticket's frontmatter has a `parent_issue` field, also post a brief
progress note there (see `implement-here/SKILL.md`'s equivalent step) — never a
"closes" reference, and never close the parent from here.
