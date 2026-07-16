---
name: specify
description: Turn a clarified requirement into a concrete implementation spec (files touched, contracts, data changes, test plan) before any code is written. Use after clarify, or directly when requirements are already unambiguous. Follows the project's targeted-search rules to keep context usage low. Cloud-sync aware (gh/linear/none).
---

# Specify Skill

Convert a clarified requirement into a short, actionable spec — without reading more of
the repo than necessary.

## Invocation

Parse the input to extract:
- **REQUIREMENT**: the clarified requirement text, or a path to a clarify summary
- **--issue N**: optional GitHub/Linear issue number, if not already resolved via `clarify`'s state file
- **--feature SLUG**: optional explicit feature slug

If the requirement still contains open ambiguities, stop and suggest `clarify` instead
of guessing.

## Cloud sync (read once, at the start)

Read `.agents/config.md`'s `cloud:` field (`none | gh | linear`); default to `none` if
the file is absent. `00-spec/spec.local.md` is **always** written and is **always** the
local record, regardless of this setting — there's no separate "local mode" file
layout. `cloud` only decides whether that same file also gets a cloud mapping:

- **`none`**: no extra step.
- **Already mapped** (a `github_issue`/`linear_issue` field already exists on the
  *feature-level* requirement — e.g. `clarify` created it): reuse it as the **parent
  issue**. It stays open as the feature's tracking issue and is never the target of a
  `closes #N` from any single slice's branch/PR — see "One issue per mergeable branch"
  below.
- **Not yet mapped, `cloud: gh`**: `gh issue create --title "<feature-slug>" --body-file <spec-body>`
  and record the returned number as `github_issue: N` on the feature-level
  requirement — this becomes the parent issue. Only reached when `specify` is the
  *first* stage to touch this ticket (no prior `clarify` run, or `clarify` wasn't
  cloud-enabled at the time).
- **`linear`**: same pattern, `linear_issue: <ID>`. Exact Linear CLI/API syntax is
  project-dependent and not fixed by this skill — confirm with the user or check for an
  existing Linear MCP/CLI before assuming a specific invocation. If Linear sub-issues
  are supported, use them for the child-issue-per-slice model below; otherwise fall
  back to `none` behavior for child issues specifically, and flag that clearly rather
  than failing silently.
- **On completion**, whether newly created or already mapped: `gh issue comment N
  --body-file <spec-body>` on the **parent** issue, summarizing the slice list. Comment-
  only, same as `clarify` — never edit the issue body, so re-running `specify` on an
  already-mapped ticket can't silently overwrite something a human edited on GitHub
  directly.

## One issue per mergeable branch (new convention)

Every branch intended to merge independently must close exactly one issue, and every
issue must be closed by exactly one branch. Concretely:

- The **feature-level issue** (parent, from Cloud sync above) is an epic: it tracks the
  whole requirement and is closed only when every slice under it is done — never by a
  single slice's PR. Its body/comments never say "closes #N" for itself from a slice PR.
- **Each slice that will be merged independently gets its own child issue**, created
  during the Slicing step below, once the slice list is confirmed with the user.
- A slice's own `00-spec/spec.local.md` frontmatter records `github_issue: <child-id>`
  (that slice's own issue, not the parent) and `parent_issue: <feature-issue-number>`.
- If two slices are deliberately meant to land in one PR (not independently mergeable),
  they are not two slices for this purpose — merge them into a single spec/ticket
  instead of giving them separate issues that would both need the same "closes #N".
  Two independently-mergeable branches must never reference the same issue number in
  their "closes" line.

## Pipeline state file (mandatory)

Shares `.agents/features/<feature-slug>/` with `clarify` and `implement-here`. A
single-spec feature keeps one file under `00-requirement/`; a sliced feature has one
`<NN>-<slice-slug>/00-spec/spec.local.md` per slice.

### Determining the slug

1. If `--feature SLUG` was passed, use it.
2. Else if exactly one feature has `status: clarified` (not yet specified), use that one.
3. Else if multiple candidates exist, list them and ask the user directly which one.
4. Else derive fresh from the requirement text and confirm with the user before writing.

### Reading and writing state

1. If a clarified requirement exists, read it from `00-requirement/requirement.local.md`
   instead of re-deriving it — carry its Acceptance Criteria pairs verbatim into the
   Test plan. Discovery (below) still runs in full regardless.
2. If a spec already exists (`status: specified`), show it and ask whether to reuse or
   re-spec before doing any discovery work.
3. If no state file exists at all, create one fresh with `status: speccing`.
4. On completion, set `status: specified` under the relevant `00-spec/spec.local.md`,
   plus the complexity tag below, plus cloud sync per the section above (including the
   per-slice child issue, if applicable).

### Complexity tag (drives both model-tier selection and search budget)

Tag the spec frontmatter `complexity: small | default | complex` — consumed by a
project's role-matrix config (if one exists) to pick a cheaper implementer tier for
`small` work, and used below to bound how much searching this skill itself does.
Estimate from requirement scope: a doc/config-only change with no existing symbols
touched is `small`; a single-file behavior change is `default`; anything spanning
several files/layers or with real ambiguity in approach is `complex`.

## Token-lean discovery (do this, not a full scan)

**Search budget, tied to the complexity tag**: `small` — at most 2-3 targeted `rg`
calls before writing the spec; don't go looking for problems that aren't there.
`default` — normal discovery below, no artificial cap, but still targeted, not a full
repo read. `complex` — broader search is justified; still start targeted and widen only
as each result demands it, never start with a full-repo read.

1. Identify the affected area from the requirement wording alone — don't search yet.
2. **Check for a dependency graph first.** If `graphify-out/graph.json` exists at the
   repo root, query it before touching `rg` — it already encodes file relationships and
   community clusters, so one lookup often replaces several rounds of grep. Use the
   `graphify` CLI/skill if your agent has it available; otherwise parse `graph.json`
   directly (it's plain JSON — `jq`/`rg` against it works fine without a dedicated
   tool). Either way, use the result to seed "Files to change" directly rather than
   re-deriving relationships `rg` would take several calls to reconstruct.
3. If no graph exists, or it doesn't resolve the question, and the target file(s) are
   already obvious (named in the requirement, or 1-2 quick `rg` calls resolve it),
   search directly — don't over-delegate a lookup this cheap.
4. Otherwise, do the broader search yourself with `rg`, not a subagent — there's no
   separate lightweight delegate to hand it to in most non-Claude agents.
5. Read only what discovery points to: the target file(s), their nearest test file, and
   any scoped convention doc for that path. Don't read a whole file when a targeted
   search resolves the question.
6. For each target file, `rg -n '<symbol>'` to confirm current signatures before
   claiming a file needs changing — don't read the whole file if a targeted search
   resolves it. Skip this for files where no existing symbol is being modified.
7. If a targeted symbol's signature/behavior is changing, `rg -n '<symbol>'` across the
   repo for its call sites and list every result in **Callers to update**.
8. `rg` the affected area for one existing implementation that already does something
   similar and cite it in **Reference implementation** — pick the closest match, don't
   survey exhaustively.
9. For any change touching shared state or a permission/tenant boundary, enumerate the
   specific edge cases, race conditions, and guardrails that apply.
10. Do not read generated files or unrelated modules.

### `rg` patterns worth knowing

`-l` for existence-only checks, `-n` for content, combined patterns (`'a|b'`) in one
call over several sequential ones, `--files -g '<glob>'` over `find`. Batch independent
calls together. (Full examples in README if needed.)

## Output: the spec

Produce a single markdown block with:

```markdown
## Spec: <short title>

**Goal**: one sentence
**Out of scope**: explicit exclusions

**Files to change**:
- path/to/file:line — what changes and why (1 line each)
  - `functionName(param: Type): ReturnType` — new | modified | removed — 1-line behavior delta

**Callers to update**: only if a modified symbol's signature/behavior changes

**Reference implementation**: `file:line` of similar existing code to mirror

**Data / contract changes**: schema, types, API shape — only if applicable

**Test plan**: existing tests covering this, new tests needed, narrowest command to run them

**Seed data**: yes/no, per the project's own convention (N/A if no database)

**Risks / invariants to preserve**: for any shared-state or permission-boundary change,
name the specific edge case/race condition/guardrail relied on

**Acceptance Checklist**: one line per criterion, each tagged with the FR/US ID it
verifies and a concrete check to run/observe — this is what the reviewer (FR20) walks
before setting a verdict. Carry `clarify`'s Acceptance Criteria pass/fail pairs over as
the first entries when the source requirement has them; add one line per other
significant Files-to-change/Test-plan item. Omit only if the source requirement has no
FR/US IDs at all (a narrow fix, not a system/feature-level one) — in that case there's
nothing to tag a checklist item to.
- [ ] <FR/US ID> — <concrete check, e.g. "run X, observe Y">
```

## Rules

- Do not paste full file contents or long diffs into the spec — reference `file:line`.
- For any file that modifies, adds, or removes a function/component, name its signature
  and the one-line behavior delta.
- If a changed symbol has existing callers, list them in **Callers to update**.
- Cite a **Reference implementation** unless there's genuinely no precedent.
- Race conditions, guardrails, and edge cases are this skill's job to enumerate from the
  codebase, not a question to send back to `clarify` — reserve that for genuine business
  decisions.
- Do not propose refactors or cleanup beyond the requirement.
- Keep each slice's spec under ~40 lines; if it's longer, the slice boundary is
  probably wrong.
- If the source clarify doc has Functional Requirements, Non-Functional Requirements,
  or User Story IDs (FR*/NFR*/US*), trace each spec decision back to the ID it
  satisfies — one line per major decision, e.g. "Files to change: ... (FR2, US8)".
  This skill consumes and traces requirements; it never redefines or re-derives them —
  that's `clarify`'s job. Omit entirely if the source requirement has no such IDs (a
  narrow fix/bugfix input, not a system/feature-level one).
- **Priority is derived, not invented here.** If the cited FR/NFR/US IDs carry MoSCoW
  tags, the resulting ticket's `moscow` frontmatter field is the *highest* priority
  among them (`Must` beats `Should` beats `Could` beats `Won't` — a ticket satisfying
  even one Must-have FR is a Must-have ticket, regardless of what else it touches).
  Carry the matching `kano` tag the same way if present. Never set a ticket's priority
  independently of the requirement it traces to.
- **One issue per mergeable branch** (see dedicated section above) — never split a
  requirement into slices that would leave two independently-mergeable branches
  pointing "closes #N" at the same issue.

## Slicing (vertical/end-to-end, never layer-only — FR3)

A slice is a complete, independently-testable, end-to-end unit of the requirement — it
spans whatever layers it actually needs to work and be verified on its own. Never slice
"just the schema part" or "just the API part" as a standalone deliverable that can't be
tested by itself (see README for why this is FR3, not a style preference).

Split a requirement into multiple slices when:
- It's large enough that reviewing or verifying it as one unit is genuinely hard, or
- There's a real sequencing dependency (slice B assumes slice A already exists) that
  benefits from independent review/approval.

Don't split just because a change happens to touch several files or layers — that's
normal for a real end-to-end feature, not by itself a reason to fragment it. And don't
force a slice smaller than what's independently testable, either — a fragment that
can't stand on its own as a working, verifiable unit is too small, not well-scoped.
Bound size in both directions: not so large it's hard to review, not so small it stops
being a complete, testable thing.

1. Identify whether the requirement is one cohesive testable unit or genuinely several,
   during discovery, before writing the spec.
2. If several, determine explicit implementation order (a real dependency chain
   between slices, not a suggestion — e.g. slice 2 assumes slice 1's output exists).
3. Layout: one `<NN>-<slice-slug>/00-spec/spec.local.md` per slice under the feature's
   `.agents/features/<feature-slug>/` directory, `NN` zero-padded matching order.
4. Each slice's frontmatter records `order: N`, `depends_on: [<prior slug, ...>]` (a
   list — possibly empty, possibly cross-feature `<feature-slug>/<slice-slug>` entries;
   see `.agents/orchestration/ticket-schema.md`'s Dependency graph section), and
   `complexity`.
5. Present the full ordered slice list to the user before writing any files, so they
   can reorder, merge, or veto the split first.
6. A requirement that's genuinely one testable unit stays a single spec file — don't
   invent a split just to have one.
7. **After the slice list is confirmed** (per step 5) and only when `cloud: gh` (or a
   Linear sub-issue equivalent): create one child issue per slice —
   `gh issue create --title "<feature-slug> — <slice-slug>" --body-file <slice-spec-body>`.
   Record the returned number as that slice's own `github_issue: N` and the parent's
   number as `parent_issue: <feature-issue-number>` in the same frontmatter. Do not
   phrase the child issue body as "closes #<parent>" — that belongs to whichever
   branch/PR implements *this* slice, closing *this* child issue, not the parent (see
   "One issue per mergeable branch" above).
8. Once all child issues exist, comment on the **parent** issue listing them in order
   (`gh issue comment <parent> --body-file <slice-list-summary>`), so the epic shows
   its full breakdown without its body being edited.

## Completion

Present the spec(s), write each into its relevant `00-spec/spec.local.md`, run the cloud
sync appropriate to this project's setting (see "Cloud sync" and "Slicing" above,
including per-slice child issues), and ask the user to confirm before handing off to
`implement-here` (or a real handoff to another agent, if this project has an
orchestration backbone with a dispatch gate). Do not start coding in this skill.
