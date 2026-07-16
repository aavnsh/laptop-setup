---
name: tracker-init
description: Bootstrap a brand-new project with this system (config.md, empty project memory, orchestration backbone), initialize its ticket tracker as cloud:none by default, upgrade an existing local-only project to sync with gh/linear once a remote exists (migrating tickets without data loss), or re-run as a sync/diff check against already-mapped tickets. Cloud-sync aware, agent-neutral.
---

# Tracker-init Skill

Owns the lifecycle of `.agents/config.md`'s `cloud:` setting and the cloud mapping on
every ticket under `.agents/features/**/*.local.md`. Also the entry point for
bootstrapping a brand-new project with this system's conventions — see README for why
this scaffolding step was missing until it was actually needed. Four modes (`init` now
does more than just `cloud:` setup, per that fix).

## `init`

Fresh project, no existing tickets to worry about. Three things, all additive, all
skippable if already present (re-running `init` on a partially-set-up project is safe):

1. Write `.agents/config.md` if absent:
   ```
   ---
   cloud: none
   ---
   ```
2. Scaffold an **empty** `.agents/memory/` if absent — `README.md` (the frontmatter
   schema + the project-vs-global placement criterion, same content as the reference
   project's `.agents/memory/README.md`) and an empty `INDEX.md` (just the header, no
   entries — a new project has no memory yet, and never inherits any from global; see
   README for why this must never be seeded from another project).
3. Scaffold `.agents/orchestration/{states.md,ticket-schema.md,locking.md}` if absent —
   copy from `~/.agents/orchestration/` if it exists (i.e. it's been promoted to global
   via chezmoi from a reference project); if `~/.agents/orchestration/` doesn't exist
   either, say so plainly and stop rather than inventing backbone content from
   scratch — these files define a real state machine, not something to improvise per
   project.

`.agents/config.md`'s own "if missing, defaults to `cloud: none`" fallback means step 1
alone was never strictly required for a project to function — `init`'s real value is
steps 2-3, which nothing else provides.

## `upgrade` (one-time migration)

Re-run once a remote exists. Ask the user which target (`gh` or `linear`) if not
already clear from context, then:

1. Set `.agents/config.md`'s `cloud:` field to the chosen target.
2. For every `.agents/features/**/00-spec/spec.local.md` **lacking** a `github_issue`/
   `linear_issue` field:
   a. Create the cloud issue with the ticket's spec content as the initial body
      (`gh issue create --title "<slice-slug>" --body-file <spec-file>`).
   b. Comment the ticket's existing history onto the same issue, **in phase order**
      (`01-implement/` evidence, then `02-review/verdict.local.md`, then `03-retro/` if
      present) — so a ticket that's already `done` arrives on the cloud tracker with
      its full trail, not just a bare spec.
   c. Record the returned issue number in the ticket's own frontmatter
      (`github_issue: N` / `linear_issue: ID`). One file, no separate migration log —
      consistent with amendments.md decision 11.
3. Report a summary: how many tickets migrated, any that failed and why.

**Never** touch a ticket that already has a `github_issue`/`linear_issue` field —
that's `sync`'s job, not `upgrade`'s.

## `sync` (ongoing drift check, re-runnable anytime)

For every ticket that **already has** a `github_issue`/`linear_issue` field:

1. `gh issue view N --json body,comments` and compare against the local
   `00-spec/spec.local.md` content (and, if present, the latest `01-implement`/
   `02-review`/`03-retro` evidence not yet reflected as a comment).
2. If they've diverged, **don't resolve it automatically in either direction** — post
   the current local content as a new comment (so the cloud side has what's missing)
   and report the diff to the user, letting a human decide which side is actually
   right. Same comment-only discipline as every other skill's cloud sync (never edit
   the issue body, never overwrite the local file from cloud content).
3. If they match, no action — report that the ticket is in sync.

`sync` is safe to run as a periodic sweep across every mapped ticket in a feature (or
the whole project); it never migrates anything new (that's `upgrade`'s job) and never
silently reconciles (that's a human call).

## Notes

`linear` support mirrors `gh` structurally but exact CLI/API syntax isn't fixed here —
confirm with the user or check for an existing Linear MCP/CLI first. If unavailable,
say so and stop rather than guessing at a command that doesn't exist.
