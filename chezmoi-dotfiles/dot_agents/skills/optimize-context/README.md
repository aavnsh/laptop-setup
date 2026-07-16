# `optimize-context` — rationale

See `../README.md` for cross-skill conventions. This file covers what's specific to
`optimize-context`.

## Why scope is genuinely project-wide

The first draft of this skill's spec scoped it to `.agents/skills/*.md` — this
project's own convention — because that's the only place this project had actually
practiced the technique (passes 4 and 7). That was the mistake: FR8 is about a
project's markdown generally, and any real project's `README.md`/`CONTRIBUTING.md`/
`docs/**` are exactly the kind of files that accumulate the same bloat over time,
usually worse, since they're written by many contributors across years rather than one
disciplined session. Scoping to this project's own instance would have made the skill
useless for the thing it's actually for.

## Why splitting is as legitimate an action as trimming

NFR1 says "keep quality as high as possible *within* the token constraint" — it's not
"minimize length at any cost." A file mixing install instructions, a full API
reference, and contribution guidelines isn't fixed by deleting content; it's fixed by
separating concerns that different readers need at different times. Splitting is the
right tool exactly when trimming would mean losing real information a task needs.

## Why under-specification is flagged, not auto-filled

The failure mode this guards against: a file that's *too terse* looks the same as a
file that's *appropriately concise* until someone actually tries to use it and hits a
missing prerequisite or an unnamed script. This skill can tell something's probably
missing (a task the file claims to support has no concrete steps to follow), but it
can't know what's actually true — inventing plausible content would look authoritative
without being checked, which is worse than a visible gap a human notices and fills.

## Why the memory-log step is conditional on git being absent

The first draft always logged applied changes to `.agents/memory/`, unconditionally.
Wrong for any git-using project: a commit (with a descriptive message) already *is* the
durable "what changed and why" record — `git log`/`git blame` answer it authoritatively.
This project's own memory-hygiene rule (see `.agents/memory/README.md`) explicitly
excludes git-derivable content from memory for exactly this reason, and the first draft
violated its own stated principle without noticing, because this project itself has no
git to expose the redundancy. Fixed: log to memory only when the project doesn't use
git — the substitute for what a commit message would have captured, not a duplicate of
it.

## The worked example this design was validated against

This project's own `.agents/skills/README.md` "pass 4" (provenance blockquotes removed)
and "pass 7" (rationale clauses moved to per-skill READMEs) entries are real, solved
instances of the duplication/misplaced-rationale categories — this skill's detection
logic was checked against `clarify/SKILL.md` as it existed before pass 7 and confirmed
to flag the same clauses that were actually moved. The over-scoped/split and
under-specified categories have no real instance in this repo yet (this project's own
files were written under this session's NFR1 discipline from the start, so they don't
currently exhibit either failure mode) — validated only against a hypothetical generic
README and a hypothetical terse deploy doc, per the spec's test plan.
