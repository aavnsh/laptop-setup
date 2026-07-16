# `clarify` — rationale

See `../README.md` for cross-skill conventions (cloud-sync model, comment-only
discipline, NFR1 discipline). This file covers what's specific to `clarify`.

## Why step 4 flags new skills/tooling as a deliverable

This project's own requirement doc is the proof it matters: it needed a 7-skill
deliverable set (`clarify`, `specify`, `implement-here`, `handoff`, `optimize-context`,
`retro`, `tracker-init`), and that needed to be surfaced as its own decision point
during clarification — not discovered implicitly later while writing specs, where it's
much more expensive to back out of a wrong assumption.

## Why "whichever stage runs first owns the cloud issue"

Earlier revisions made `specify` the sole cloud-issue creator, leaving `clarify` unable
to create or sync one. That meant a ticket starting at `clarify` had zero cloud
visibility until `specify` ran — possibly much later, or never in the same session.
Fixed: `clarify` now creates the issue itself when it's genuinely the first stage to
touch a ticket, mirroring `specify`'s own logic (see `../specify/README.md`).

## Known upstream gap (not fixed here)

The actual Claude-original `~/.claude/skills/clarify/SKILL.md` has no `--issue N`
invocation flag at all, unlike `specify`/`implement` — an oversight predating this
project, not introduced by it. This project's copy fixes it locally
(`amendments.md` decision 12); per decision 16, propagating the fix to the global
original is the owner's own call, out of this project's scope.

## Fixed bugs (2026-07-15, `07-clarify-specify-updates`)

- "Your Task" numbered list had a gap (`1,2,3,5,6,7,8` — item 4 missing), introduced
  when the environment-recon step was inserted in an earlier pass. Renumbered clean.
