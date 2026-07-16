# `specify` — rationale

See `../README.md` for cross-skill conventions (cloud-sync model, comment-only
discipline, NFR1 discipline). This file covers what's specific to `specify`.

## Why vertical slicing, never horizontal (FR3)

"Just the schema part" or "just the API part" as a standalone deliverable can't be
independently tested — that's exactly the horizontal slicing FR3 rejects. A slice must
be a complete, end-to-end, verifiable unit on its own, spanning whatever layers it
actually needs — never split *because* a change touches multiple layers, only split for
genuine size or real sequencing reasons. The first draft of this skill copy-adapted the
Claude original's layer-scoped slicing language near-verbatim (correct for whatever
project that original targets, wrong for this project's FR3) — see `amendments.md`
decision 13 for the full incident.

## Why the Acceptance Checklist exists (FR5/FR20)

FR5 requires "an acceptance checklist per slice, tagged with the FR/US ID it verifies
and a concrete check to run/observe"; FR20's review step depends on walking it. An
earlier revision of this skill produced spec output with no such section at all, so the
review step described in `ticket-schema.md` had nothing to walk. Fixed in
`07-clarify-specify-updates`.

## Why `depends_on` is a list

Every ticket up through `05-memory-skills-convention` only ever had one dependency, so
the frontmatter stayed a single slug. `06-ticket-tracker-local` generalized it to a list
(supporting multiple dependencies and cross-feature references) — this skill's own
Slicing section was briefly stale after that change, fixed in `07`.

## Why complexity tiers bound the search budget

Mirrors `02-role-matrix-config`'s implementer tiers: a `small` (docs/config-only) spec
shouldn't cost as many `rg` calls as a `complex` one, the same way it shouldn't cost as
many implementer tokens. Bounding discovery cost by the same signal that bounds
implementation cost keeps the two consistent instead of independently guessed.

## `rg` patterns (full list — `SKILL.md` keeps only a one-liner)

- `rg -l '<pattern>'` — file list only, when you just need to know *whether* something
  exists, not read it yet (cheaper than `-n` when you don't need line numbers).
- `rg -n '<patternA>|<patternB>'` — one call covering multiple related symbols instead
  of several sequential single-pattern calls.
- `rg --files -g '<glob>'` — find files by name/pattern instead of `find` (respects
  `.gitignore` automatically, faster on large repos).
- Batch independent `rg`/read calls together in one turn rather than issuing them
  sequentially one at a time when they don't depend on each other's results.

## Why graphify-first

If `graphify-out/graph.json` exists, it already encodes file relationships and
community clusters — one query often replaces several rounds of `rg` needed to
reconstruct the same relationships by hand.
