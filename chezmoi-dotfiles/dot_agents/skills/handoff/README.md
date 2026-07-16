# `handoff` — rationale

See `../README.md` for cross-skill conventions (cloud-sync model, comment-only
discipline, NFR1 discipline). This file covers what's specific to `handoff`.

## Why review is bundled in, not a separate skill

A handoff isn't verified until reviewed — a "dispatch-only" skill would produce an
untestable fragment on its own (you can't confirm a handoff worked without seeing it
through review), which is exactly what `specify`'s vertical-slicing rule (FR3) rejects
at the skill-design level, not just the ticket-slicing level.

## Why interactive dispatch (cmux) is primary, and the batch script is the fallback

The original design was purely non-interactive: pack everything upfront, run
`--yes-always`, check an exit code. That's brittle exactly where it matters — when the
implementer hits something genuinely ambiguous, a non-interactive run can only guess or
fail, with no way to ask. This project already has a real example of the guess going
wrong: a stray Aider session (outside this skill, before it existed) hit a genuine
naming-convention question mid-task, had no way to ask, and picked `.agent/` (singular,
flat) — the wrong answer, later corrected by hand once discovered (see `amendments.md`
decision 8). Interactive dispatch via a live cmux pane exists specifically so a future
implementer facing the same kind of decision can ask instead of guessing.

The batch script isn't a worse version of this — it's the correct answer when cmux
genuinely isn't available (`amendments.md` decision 1: cmux is transport, never a
dependency), and it's what `dispatched.local.md`/`DONE`/`FAILED` still get written by
either way, since the *script* (batch) or the *skill watching for the markers*
(interactive) is the only thing that reliably knows when an agent process actually
begins and ends — never something a human is trusted to remember to record by hand.

## Why the orchestrator relays `BLOCKED` questions, but never answers them

The whole point of interactive dispatch is answering the implementer's question — but
*who* answers it matters. If the orchestrator (deliberately the cheap, judgment-free
Haiku tier per `amendments.md` decision 4 — "no free-form judgment in the orchestrator
loop") answered on its own, that would quietly reintroduce the exact kind of scope
judgment call the rigid ticket state machine exists to keep out of the orchestrator's
hands. So the split is strict: the **orchestrator routes** (reads `BLOCKED.local.md`,
relays it, relays the answer back), the **human decides**, the **implementer executes**.
Nobody's role changes — the orchestrator doesn't get smarter, it just stops being a
dead end when a question comes up.

## Why approval and execution transport are treated as separate concerns

It would be easy to conflate "cmux can launch the script" with "cmux launching it
counts as approval" — it doesn't. The explicit approval act (step 4) has to happen
first and separately, regardless of which transport executes the already-approved
script in step 5. Collapsing these two would let a dispatch happen without a human
ever having actually said yes, which is the exact failure mode `04`'s gate-2 design
(and its own retroactive discovery that `02`/`03` skipped a gate) already warned about.

## Why panes get named, and why the socket-vs-CLI question doesn't matter here

Both surfaced live during `12-e2e-proof`'s actual dispatch, not in design review. First:
`cmux new-pane` produces an unnamed pane — `list-panels` at the time showed multiple
indistinguishable `~/projects/multiagentdev` entries alongside a stray pane from an
earlier session, with nothing to tell them apart. `cmux rename-tab` right after
`new-pane` fixes this, and costs nothing extra (one more command in the same batched
script — see below). Second, the owner asked whether talking to cmux's Unix socket
directly (instead of the `cmux` CLI) would help — it wouldn't: the CLI already *is* the
socket client, so bypassing it just means hand-constructing the same RPC calls with
more tokens, not fewer, and per this project's own cost function (decision 1's
NFR1 framing) wall-clock speed was never the thing to optimize anyway. The actual waste
during the live run was issuing the routine, predictable steps (`new-pane`, name it,
send the launch command, send Enter) as separate `Bash` tool calls instead of one
script — each separate call costs a full round-trip of tokens for content that didn't
need independent inspection between steps. Batched into one script now.

## The real incident this formalizes

`01-system-readme`'s actual dispatch was done by hand: a manually-written
`handoff-01-system-readme.sh`, no `dispatched.local.md`/sentinel convention (didn't
exist yet), and a real tier mismatch — the ticket was tagged `complexity: small`
(resolving to `qwen3.5:9b`), but the accepted result actually came from a 32B-model run,
because the correctly-tiered run was started but cancelled before finishing (see
`01-system-readme/01-implement/tokens.local.md`). Step 1's tier-resolution-at-generation-time
is designed specifically to make that kind of drift visible rather than silent — the
script it generates is tagged with the resolved tier, so a mismatch between "what was
assigned" and "what actually ran" is a discrepancy anyone can check, not something only
discoverable by reading a transcript after the fact.
