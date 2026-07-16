# `tracker-init` — rationale

See `../README.md` for cross-skill conventions (cloud-sync model, comment-only
discipline, NFR1 discipline). This file covers what's specific to `tracker-init`.

## Why `init` scaffolds memory/ and orchestration/, not just config.md

The first version of this skill only wrote `.agents/config.md` — and even that wasn't
strictly necessary, since the config file already defaults to `cloud: none` if absent.
The gap this missed: **nothing else in this system ever creates a new project's
`.agents/memory/` or `.agents/orchestration/`.** Both were hand-built exactly once,
specifically for `multiagentdev`, in that project's own `03-repo-bootstrap` and
`04-orchestration-backbone` slices — never turned into anything a *different* project
could reuse. Found only when the owner asked directly whether a new project's
memory/config would be created automatically — it wasn't, for two of the three things
that actually matter. Fixed: `init` now scaffolds both, making `tracker-init` the real
bootstrap entry point for a brand-new project, not just a `cloud:` setting.

## Why a new project's memory starts empty, never seeded from another project

`.agents/memory/` holds project-specific facts (see `.agents/memory/README.md`'s
placement criterion). Seeding a new project's memory from `multiagentdev`'s own — or
any other project's — would immediately violate that: a fresh project has no history
with `multiagentdev`'s role-matrix decisions or cmux posture, and pre-loading them
would look like established local fact rather than what it actually is (irrelevant
noise from an unrelated project). Only the *schema* (the `README.md` explaining the
frontmatter shape and placement rule) is shared; the *content* (`INDEX.md`) always
starts genuinely empty.

## Why `orchestration/` scaffolding pulls from `~/.agents/`, not a bundled template

The state machine, dependency rules, and locking convention are substantial (roughly
150 lines across three files) — inlining them into this skill would bloat `SKILL.md`
against NFR1 for content that's read on every `init` call regardless of whether it's
needed. Pulling from `~/.agents/orchestration/` (populated via `promote-to-chezmoi.sh
all`, chezmoi-managed) means the canonical copy lives in exactly one place. If nothing's
been promoted globally yet, `init` says so and stops rather than inventing backbone
content per project — this is real state-machine logic, not something to improvise.

## Why `init` matters even though `.agents/config.md` already defaults to `cloud: none`

The config-file step alone was never strictly required for a project to function — the
config file's own "if missing" fallback already covers it. `init`'s real value is the
memory/orchestration scaffolding above; recording the `cloud:` choice explicitly on
disk is a secondary benefit of the same step, not what makes `init` worth running.

## Why `upgrade` and `sync` are separate modes, not one

`upgrade` is a one-time migration: for tickets with *no* cloud mapping yet, it creates
the issue and replays history. `sync` is the opposite case: for tickets that *already
have* a mapping, it checks for drift. Collapsing them into one mode would mean the skill
has to guess whether a divergence means "never synced" or "synced then drifted" —
keeping them separate makes that distinction explicit instead of inferred.

## Why `sync` flags drift instead of resolving it

Same comment-only discipline as every other skill's cloud sync (see `../README.md`):
this skill can't know whether the local file or the cloud issue is the one that's
"right" after a divergence — that's a human call, not something to guess at
automatically in either direction.

## Linear support

Mirrors `gh` structurally but exact CLI/API syntax isn't fixed here, since it depends on
what's actually installed/authenticated in a given project — confirm with the user or
check for an existing Linear MCP/CLI before assuming a specific invocation. Not
exercised in this project (no Linear credentials) — designed, not tested.
