# Project-level agent-neutral skills

`SKILL.md` files here use the same filename/frontmatter shape as Claude Code's own
`.claude/skills/<name>/SKILL.md` — just rooted under `.agents/` instead of `.claude/`,
so any agent (not only Claude Code) can read them directly (e.g. via `--message-file`
or `--read`), without needing the `Skill` tool or slash-command mechanism.

- **Project scope** (here): `.agents/skills/<name>/SKILL.md`.
- **Global scope**: `~/.agents/skills/<name>/SKILL.md`, chezmoi-managed — populated by
  the owner manually copying a project skill over once it's ready to be used across
  projects (amendments.md decision 10). This system never writes to `~/.agents/`
  itself.

Each skill's own folder has its own `README.md` for rationale specific to that skill —
this file only covers what's genuinely cross-cutting.

## Skills in this tree

Mirrored from a Claude-original (adapted, not identical — see "Known drift risk"):
- [`clarify/`](clarify/SKILL.md) ([rationale](clarify/README.md))
- [`specify/`](specify/SKILL.md) ([rationale](specify/README.md))
- [`implement-here/`](implement-here/SKILL.md) ([rationale](implement-here/README.md)) — renamed from the Claude original's `implement`

New — no Claude-original counterpart (this project's own FR2/FR7/FR8/FR9/FR12/FR21 deliverables):
- [`tracker-init/`](tracker-init/SKILL.md) ([rationale](tracker-init/README.md))
- [`handoff/`](handoff/SKILL.md) ([rationale](handoff/README.md))
- [`optimize-context/`](optimize-context/SKILL.md) ([rationale](optimize-context/README.md))
- [`retro/`](retro/SKILL.md) ([rationale](retro/README.md)) — optional `PreCompact` hook trigger not yet wired up; see `retro/README.md`
- [`projectstatus/`](projectstatus/SKILL.md) ([rationale](projectstatus/README.md)) — renamed from `visualize`

## Cross-skill: cloud-sync model (`cloud: none | gh | linear`)

Read from `.agents/config.md`. Local storage is always on — `.local.md` is always the
ticket record, regardless of `cloud`. `cloud` is an orthogonal field on that *same*
file: whichever stage runs first for a ticket creates the cloud mapping
(`github_issue`/`linear_issue` in the ticket's own frontmatter), no separate sync file,
no separate directory (amendments.md decision 11, simplified from an initial
two-file-family design).

## Cross-skill: comment-only discipline

Every skill's cloud sync only ever posts comments — none of them edit the issue body.
This means no stage, re-run any number of times, can silently overwrite something a
human edited on GitHub directly. The original ask (or spec, or evidence) stays intact
as the body; everything this system adds becomes part of the comment thread instead.

## Cross-skill: NFR1 discipline (token spend is the only cost)

Two rounds of trimming applied to all four files: provenance/changelog blockquotes
("adapted from the Claude original, here's what differs") were removed entirely — that
content is read on every invocation but only matters to someone doing archaeology, and
mostly duplicated what the body already said. Inline rationale clauses ("here's *why*
this rule exists") were trimmed to a "see README" pointer, with the actual rationale
preserved in each skill's own `README.md` instead of the hot-path `SKILL.md`. Same
principle both times: the *rule* stays in `SKILL.md` because every invocation needs it;
the *justification* moves to a README because only someone questioning the rule does.

## Known drift risk

These are hand-synced from the Claude-specific originals at `~/.claude/skills/<name>/SKILL.md`,
not auto-generated. No sync tooling exists yet (amendments.md's "single-source skills"
gap, still open). Per amendments.md decision 16, updating the Claude originals
themselves is out of this project's scope — a global change affecting every project,
left to the owner's own judgment, not bundled into this project's work.
