---
name: retro
description: After a ticket reaches done/escalated, or before context is lost to compaction, mine its evidence/verdict history into durable lessons — routed to project memory, global-memory-flagged, the project's own detected ADR convention, or a documentation update — with per-candidate human approval. Captures corrections and confirmations, not just failures. Generic — detects each project's own decision-log convention rather than assuming one.
---

# Retro Skill

Mines a completed ticket's own record into durable lessons, so they compound across
sessions instead of resetting. See `README.md` for the relationship to `claude-reflect`/
`planning-with-files` (validated prior art), why confirmations matter as much as
corrections, and why the ADR destination is detected per-project.

## Invocation

- `--feature SLUG --slice SLUG` — retro one completed ticket.
- `--feature SLUG` — retro every completed-but-not-yet-retro'd ticket in a feature.
- (no args) — retro everything not yet retro'd, project-wide. This is the shape a
  pre-compaction trigger calls it with.

## 1. Detect the project's ADR/decision-log convention (once, before mining)

Look for, in order: a `docs/adr/` directory, `DECISIONS.md`, `ADR.md`, or any other
project-specific decision-log pattern. If genuinely none exists, note that project
memory is the fallback destination for architecture-level candidates — **never invent
a new decision-log system** as a side effect of proposing one lesson. This step runs
once per retro invocation, not once per candidate.

## 2. Gather the ticket's record

Read the ticket's `evidence:` field (this project's own tickets already use it as an
unstructured revision history — e.g. "pass 1... pass 2... pass 6"), its
`02-review/verdict.local.md` if any, and cross-reference the detected decision log (step
1) for entries citing this ticket's slug.

## 3. Identify candidates — two categories

- **Corrections**: something was tried, found wrong, and fixed (a design reworked
  after feedback, a bug caught and corrected).
- **Confirmations**: an approach was validated as-is — worth remembering as "this
  pattern works, keep using it," not just cataloging what to avoid. Capture both; a
  corrections-only capture makes the system risk-averse without staying calibrated to
  what's actually working.

## 4. Classify each candidate's destination

- **Project memory** — a fact/pattern specific to this repo.
- **Global-memory-flagged** — a working-style fact true regardless of project. Set
  `promote_to_global: true` in the draft; **never write to `~/.agents/` directly** —
  promotion is the owner's own manual act (decision 10), same as skill promotion.
- **The detected ADR convention** (step 1) — the candidate revises or extends an
  architecture decision. Use whatever format that convention already has; don't impose
  this project's own `amendments.md` numbered-decision shape on a project that uses
  something else.
- **Project documentation** — the candidate reveals `README.md`/docs are stale or
  missing something (connects to `optimize-context`'s under-specification category).

Before finalizing a candidate, check whether it's **already recorded** in the detected
decision log — don't propose a duplicate entry for something that's already there.

## 5. Present for approval — per candidate, never bulk

Present each candidate individually with its proposed destination. Approve, edit, skip,
or redirect to a different destination — one at a time. A single "approve all" defeats
this gate; a lesson written wrong persists and misleads every future session that reads
it, which is worse than a bad diff since it's trusted context, not a visible change.

## 6. Apply

Write only what was explicitly approved, to its classified destination, in that
destination's own existing format.

## Optional trigger: PreCompact hook

If this project's Claude Code hooks are configured with a `PreCompact` hook, it may
invoke `retro` with no args before context is summarized away — mirroring
`claude-reflect`'s pre-compaction backup and `planning-with-files`' `PreCompact` hook.
This only ever starts the scan (step 1-4); it never bypasses the per-candidate approval
gate (step 5) — auto-triggering the read is fine, auto-approving the write is exactly
the kind of silent judgment call this system's orchestrator is deliberately kept out of
making. Degrades cleanly: `retro` works identically whether hook-triggered or invoked
manually, same posture as cmux (decision 1).
