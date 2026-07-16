# `retro` — rationale

See `../README.md` for cross-skill conventions. This file covers what's specific to
`retro`.

## Relationship to `claude-reflect` and `planning-with-files`

Both were reviewed as reference material (`amendments.md` decision 14) and both
validate real pieces of this design. `claude-reflect`: hook-captured corrections →
confidence-scored queue → human-reviewed sync to `CLAUDE.md`/`AGENTS.md` — this is
close to what Claude Code's own native auto-memory already does for live corrections
mid-session, which is *not* what `retro` duplicates; `retro` is specifically a
post-ticket reflection step, mining a completed unit of work's own record rather than
listening in real time. `planning-with-files`: its `PreCompact` hook (fires on
`/compact`/autoCompact, reminds to flush progress before compaction completes) and
`claude-reflect`'s `check_learnings.py` ("before compaction — backs up queue and
informs user") are the direct precedent for this skill's optional pre-compaction
trigger — both tools independently arrived at "flush before compaction" as the highest-
value automatic trigger point, which is strong validation it's not just this project's
idea.

## Why corrections and confirmations both matter

A system that only records what went wrong drifts toward excessive caution without
staying calibrated to what's actually working — the same reasoning already stated in
this project's own memory-writing principles (see the auto-memory system's own
guidance: "record from failure AND success"). `retro` applies that principle to the
ticket workflow specifically.

## Why the ADR destination is detected, not assumed

The first draft of this spec hardcoded `amendments.md` as *the* ADR destination —
wrong, because that's this project's own specific convention, not a general one. A
generic skill has to detect what a target project actually uses (`docs/adr/`,
`DECISIONS.md`, or nothing at all) rather than impose this project's shape everywhere.
This mirrors the same correction `optimize-context` and the core pipeline skills
(`clarify`/`specify`/`implement-here`) already went through earlier this session —
writing something specific to `multiagentdev` first, then generalizing once the mistake
was caught. Consistent pattern, not a one-off.

## Why global-worthy candidates are flagged, not written directly

Same as skill promotion (decision 10): this system never writes to `~/.agents/` itself.
`retro` proposes, the owner promotes — a candidate that's actually a cross-project
working-style fact gets `promote_to_global: true` in its draft and stays in project
memory until the owner decides to move it, same manual-act pattern used everywhere else
a global/local boundary exists in this project.
