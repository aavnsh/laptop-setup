# `implement-here` — rationale

See `../README.md` for cross-skill conventions (cloud-sync model, comment-only
discipline, NFR1 discipline). This file covers what's specific to `implement-here`.

## Why it checks for git rather than assuming it's absent

An earlier revision hardcoded "this project doesn't use git." Generalized: this skill
checks (`git rev-parse --is-inside-work-tree` or `.git/` existence) rather than
assuming, since not every project using this skill copy is non-git.

## Why it holds at `pending_done_approval` instead of self-writing `status: done`

Two tickets in this project (`02-role-matrix-config`, `03-repo-bootstrap`) were marked
`done` directly by the implementing agent, skipping the human-approval gate entirely —
discovered while implementing `04-orchestration-backbone`, which formalized the gate
this skill now follows. Presenting the result and waiting for an explicit approval is
the fix; self-declaring completion is exactly the failure mode that gate exists to
prevent. See `.agents/orchestration/states.md`'s retroactive note for the full incident.

## Fixed bugs (2026-07-15, prompted by owner review)

- Step 2 ("Test-first is mandatory...") briefly contained a stray project-specific
  aside ("as most of multiagentdev's own tickets have been so far") — directly
  contradicting this file's own stated purpose of being project-agnostic. Removed.
