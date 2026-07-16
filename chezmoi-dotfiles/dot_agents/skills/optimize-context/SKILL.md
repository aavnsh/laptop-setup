---
name: optimize-context
description: Scan a project's authored markdown files for duplication, misplaced rationale, over-scoped files, and under-specified ones, and propose fixes (remove, move, split, or flag-for-expansion) as a per-finding reviewable diff — never applied without explicit human approval. Generic — scans any project's docs, not just agent/skill files.
---

# Optimize-context Skill

Right-sizes a project's markdown: not just shorter, but the right amount of context in
the right file. Works on any project's documentation — `README.md`, `CONTRIBUTING.md`,
`docs/**`, agent/skill instruction files — not only this project's own conventions.
See `README.md` for why scope is project-wide, why splitting is as legitimate an action
as trimming, and the worked example this design was validated against.

## 1. Discovery

`rg --files -g '*.md'` from the project root — respects `.gitignore` automatically
(excludes `node_modules`/`vendor`/`dist`/`build` for free). Exclude:

- **Ticket/task-tracking working files** — the audit trail for a specific unit of work,
  not general documentation. Generically: files under a directory whose own convention
  marks them ephemeral/ticket-scoped. (This project's instance: `.agents/features/**`.)
- **Generated/derived files** — any file whose own text already carries a "generated
  view, not a source of truth" disclaimer (or equivalent). Nothing authored there to
  right-size. (This project's instances: `STATUS.md`, `SLICES.md`.)
- **`LICENSE`/`LICENSE.md`** and other legal/generated-boilerplate files — never
  touched, outside this skill's domain entirely.
- **`CHANGELOG.md`** — lower priority, historical record. Scan for outright
  duplication only; don't propose structural changes (splits, moves) to it.

## 2. Finding categories

Evaluate each remaining file, and relationships between files:

1. **Duplication** — the same information stated in multiple files, or repeated within
   one.
2. **Misplaced rationale** — historical/"why" content mixed into what should be
   operational/hot-path instructions. Applies to any instruction file (`SKILL.md`,
   `AGENTS.md`, a CLI tool's usage doc), not only this project's skill files.
3. **Over-scoped** — a single file mixing concerns that don't need to be read
   together (e.g. install instructions + full API reference + contribution
   guidelines all in one `README.md`). Candidate for splitting.
4. **Under-specified** — a file too terse to actually serve the task someone would
   read it for — missing a load-bearing detail (a command, a path, a prerequisite),
   not just brief. Flag it; don't fill it in.

## 3. Actions (one per finding)

- **Remove** — genuinely redundant or dead content.
- **Move** — to a more appropriate existing or new companion file (e.g. rationale to
  a README, mirroring this project's own pass-4/pass-7 pattern).
- **Split** — an over-scoped file into multiple purpose-specific files, cross-linked
  to each other.
- **Flag-for-expansion** — under-specified content: record the gap, propose no text.
  This skill doesn't know what's actually true, only that something looks missing —
  inventing plausible-sounding content would be worse than leaving the gap visible.

## 4. Gate — propose, never apply directly

For remove/move: produce a diff. For split: produce a proposed new file layout plus a
move-map (what content goes where). Stop and present **every finding individually** for
human review — approve, reject, or edit each one. **Never bulk-approve** — a single
"approve all" defeats the purpose of this gate (this is the exact risk
`amendments.md`'s remaining-gaps list named this skill over: "quietly destructive... if
it prunes something load-bearing").

## 5. Apply and record

Apply only what was explicitly approved, finding by finding.

Check whether the project uses git. **If it does**, the durable record is the commit
itself — present (don't run) a commit with a descriptive message covering what changed
and why; no separate log needed, and writing one would duplicate what `git log`/`git
blame` already answer authoritatively (memory is for what isn't otherwise derivable —
see `.agents/memory/README.md`'s placement criterion). **If it doesn't** (this project's own case),
there's no commit history to serve as that record, so log what changed and why into
`.agents/memory/` (type: `project`) instead — the substitute for what a commit message
would have captured.
