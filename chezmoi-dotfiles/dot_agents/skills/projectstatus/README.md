# `projectstatus` — rationale

See `../README.md` for cross-skill conventions. This file covers what's specific to
`projectstatus` (named `visualize` in an earlier pass — renamed per owner direction,
since "projectstatus" more accurately describes a display step over ticket status than
a name that implies rendering diagrams).

## Why `gum table` over a graph renderer

The first draft of this skill's spec picked a Mermaid-diagram-in-markdown as the
rendering mechanism — a reasonable design, but more complexity than the requirement
actually needed yet. The owner's explicit direction ("could we start simpler") is real
prior art worth keeping in mind for future slices too: build the smallest thing that
clears the bar, add the richer version only once the simple one genuinely proves
insufficient. A `gum`-rendered table with a `Depends On` column satisfies FR12 ("local
visualization of tasks and their dependencies") without a diagramming layer or a new
generated artifact to keep in sync with anything else.

## Why this computes its own data instead of depending on `STATUS.md` existing

The first implementation pass had this skill fall back to reading `STATUS.md`'s file
when `gum` was unavailable — wrong, caught by the owner: `STATUS.md` is itself a
generated view a project may never have produced (a fresh project that hasn't run
`tracker-init`/`04`/`06`'s equivalent setup yet has no `STATUS.md` at all). Since this
skill already reads ticket frontmatter and computes buckets independently in steps 1-2,
depending on `STATUS.md`'s file for the no-`gum` fallback was an unnecessary, incorrect
dependency — fixed to always render its own freshly-computed data, with or without
`gum`, with or without `STATUS.md` ever having existed. Every additional file a skill
depends on existing is another way it can fail for a reason unrelated to what it's
actually trying to do; removing the dependency is better than working around it.

## A real bug found while implementing (not hypothetical)

`gum table -c 'Col1,Col2,...' -f file.csv` renders `file.csv`'s own header row as a
duplicate data row if the CSV includes one — `-c` already supplies the display names,
so the CSV itself must have none. Found by actually running this project's real ticket
data through `gum table` while implementing this skill, not by reading `gum`'s docs —
worth keeping as a concrete example of why this session has consistently preferred
live verification over documentation-only design (same discipline as checking
`cmux ping` before relying on it in `08`).

## Why the `Depends On` column, not visual edges

A dedicated column with every ticket's `depends_on` list, always present and always in
the same place, is what actually makes dependencies *visible* at a glance — the same
information a graph's edges would show, at a fraction of the implementation cost.
Worth revisiting only if a project accumulates enough tickets that reading a text list
stops being adequate — not a hypothetical to design around preemptively now.
