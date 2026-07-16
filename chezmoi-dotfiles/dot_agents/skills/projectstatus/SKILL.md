---
name: projectstatus
description: Display the project's tickets as a bordered terminal table via gum, with a dedicated Depends On column making dependency relationships visible — computed fresh from ticket frontmatter, never dependent on STATUS.md/SLICES.md existing (works even in a fresh project where no rollup has been generated yet). Degrades to a plain markdown table if gum isn't installed, and reports cleanly if no tickets exist yet.
---

# Projectstatus Skill

A **display** step, not a generator — computes ticket status directly from frontmatter
and renders it readably, never a second source of truth, and never dependent on any
other generated file existing first. See `README.md` for why `gum table` was chosen
over a graph renderer, and why a `Depends On` column is what actually satisfies FR12's
"and their dependencies" clause.

## Invocation

- `--feature SLUG` — show one feature's tickets.
- (no args) — show every feature, repo-wide.

## 1. Discover and read ticket data

Find every `00-spec/spec.local.md` under `.agents/features/**` (or the relevant
feature's subtree). Read `status`, `moscow`, `depends_on` from each. **Never read
`STATUS.md`/`SLICES.md` as the data source** — those are themselves generated views a
human may not have run yet (e.g. a fresh project where `tracker-init` hasn't been run,
or `04`/`06` were never exercised); this skill must work identically whether or not
they exist, since it computes the same thing they do, independently, every time.

If no tickets are found at all (no `.agents/features/` directory, or it's empty),
report that cleanly — "no tickets found yet — run `specify` to create one" — rather
than erroring on an empty read.

## 2. Compute bucket

Apply `.agents/orchestration/states.md`'s existing bucket rules (`backlog | blocked |
ready | in_progress | waiting_human | done`) directly from the frontmatter just read —
the same computation `STATUS.md` uses, run independently, not read from `STATUS.md`
itself. If `.agents/orchestration/states.md` doesn't exist either (a project that never
ran `04-orchestration-backbone`'s equivalent setup), fall back to the ticket's own
`status:` field verbatim — best-effort display, not a hard requirement on other slices
having been implemented first.

## 3. Render

Check `which gum`.

**`gum` present**: build a CSV with **no header row** (join a multi-entry `depends_on`
list with `,` inside a quoted field), then:

```
gum table --print -s ',' -c 'Slice,Bucket,MoSCoW,Depends On,Notes' -f <csv-path>
```

`--print` renders statically (this is a display, not an interactive picker). Don't
write a header row into the CSV — `-c` already supplies the display column names, and
if the file also has its own header row, `gum table` renders it as a duplicate data
row (verified live while implementing this skill — a real bug, not hypothetical).

**`gum` absent**: render the same computed data as a plain markdown table directly —
never an error, never a missing-tool message blocking the user from seeing their
project status at all. Same degrade-cleanly posture as every other optional-tool
integration in this project (cmux, Linear).

## 4. Nothing is written to disk

This skill only displays. If a project also has `STATUS.md`/`SLICES.md`-style rollups,
those remain their own generated-file source of truth for whatever reads them — this
skill doesn't compete with them, produce a third copy, or require them to exist first.
