# Role matrix: cascade, tiers, and vendor boundary

Defines how an agent+model gets assigned to a pipeline role (FR17). No resolver code
consumes this yet — that's `04-orchestration-backbone` / `08-handoff-implement-here`.
This file states the contract those slices must implement against.

## Cascade precedence

`runtime override > project config (.agents/role-matrix.project.json) > system default (.agents/role-matrix.default.json)`

A later layer only needs to specify the roles/tiers it changes — anything it omits
falls through to the next layer down.

## Tier fallback

Each role's `tiers` map may define `small`, `default`, and `complex`. `default` is
mandatory; `small`/`complex` are optional and fall back to that role's own `default`
tier when absent. See `role-matrix.default.json`: only `implementer` currently defines
a distinct `small` tier (the rest are identical across tiers, so they only bother
defining `default`).

## Tier contract (amendments.md decision 9)

`specify` tags each slice's spec frontmatter `complexity: small | default | complex`.
A slice with no tag resolves to `default`. The `dispatch_pending_approval` human gate
(amendments.md decision 2) is the point where a person can override the resolved
tier/model before a handoff actually runs.

## Vendor-boundary invariant (FR17a) — and its scope

No tier of a **Claude-vendor role** (`orchestrator`, `code_reviewer`, `spec_reviewer`,
`security_reviewer` — all `vendor: anthropic` by system default) may silently resolve
to a non-Claude vendor without that tier carrying an explicit `cross_vendor_opt_in`
(system default) or the winning layer itself directly setting a non-Claude
`agent`/`vendor` (project config or runtime override — see the `spec_reviewer` example
in `role-matrix.project.json.example`). Either form counts as the "explicit choice at
some layer" FR17a requires.

This invariant does **not** apply to the `implementer` role. `implementer` is
non-Claude (`aider` / `ollama-local`) by system default, by design — FR17 explicitly
delegates implementation to a cheaper/local agent. There is no Claude vendor boundary
for it to silently cross, since Claude was never its default vendor to begin with.
Any future audit of this file for FR17a compliance should check Claude-vendor roles
only, not treat `implementer`'s non-Claude default as a violation.
