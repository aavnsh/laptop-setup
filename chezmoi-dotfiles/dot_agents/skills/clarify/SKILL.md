---
name: clarify
description: Start iterative requirement clarification loop. Use this skill when the user has a vague requirement and wants to clarify it through structured questioning. Transforms unclear requirements into precise, actionable specifications. Cloud-sync aware (gh/linear/none).
---

# Clarify Skill

## Cloud sync

Read `.agents/config.md`'s `cloud:` field (default `none`).

- If `--issue N` was passed, fetch the requirement from the issue itself
  (`gh issue view N --json title,body`) instead of requiring it be re-typed, and record
  `github_issue: N` (or `linear_issue: ID`) in the state file frontmatter immediately.
  This is the feature's **parent/epic issue** — see "Parent issue, not a slice issue"
  below.
- Else if `cloud` is enabled and this is a fresh clarify (no existing state file, no
  issue number given), create the issue now — `gh issue create --title "<slug>" --body "<original requirement>"`
  — and record the returned number. **Whichever pipeline stage runs first for a ticket
  owns creating its cloud issue**, not always `specify` (see README for why).
- If resuming and a `github_issue`/`linear_issue` field is already present, reuse it —
  never create a second issue for the same ticket.
- On completion (see below), post the clarified summary as `gh issue comment N --body-file <summary>`.
  Never edit the issue body — comment-only (see README for why).

### Parent issue, not a slice issue

The issue this skill creates or resolves is the **feature-level parent** — it tracks
the whole requirement, potentially across many slices `specify` will later carve out.
It is never closed by a single slice's branch/PR. Per-slice child issues (one per
independently-mergeable branch) are created later, by `specify`, once the slice list is
confirmed — see `specify/SKILL.md`'s "One issue per mergeable branch". Nothing in this
skill's own flow changes; this note exists so `--issue N` here is never mistaken for a
slice issue when a human passes one in.

## Efficiency note

This skill is almost entirely Q&A, not discovery — there's rarely a search-budget
concern here. The one place it matters: don't re-run environment/tooling recon (which
CLIs/credentials are available) more than once per session; cache what you found in the
first iteration and reuse it across question rounds instead of re-checking each time.

Transform vague requirements into precise specifications through structured questioning.

## Invocation

Parse the input to extract:
- **REQUIREMENT**: The vague requirement text — required, unless **--issue N** is given
- **--issue N**: optional GitHub/Linear issue number to pull the requirement from (see "Cloud sync")
- **--max-iterations N**: Maximum question rounds (default: 3)
- **--feature SLUG**: optional explicit feature slug (see below)

## Pipeline state file (mandatory)

All three skills (`clarify` → `specify` → `implement-here`) share one state file per
feature, under a per-feature parent directory `.agents/features/<feature-slug>/`. A
single-spec feature keeps `<feature-slug>.local.md` under `00-requirement/`; a sliced
feature has one `<NN>-<slice-slug>/00-spec/spec.local.md` per slice instead (this
project's phase-subdirectory convention — see `00-multi-agent-orchestration`'s own
`00-requirement/amendments.md` decision 6 for why).

### Determining the slug

1. If `--feature SLUG` was passed, use it verbatim.
2. Else derive it from context (branch name if this project ever adopts git; otherwise
   ask the user directly) — kebab-case the first 4-6 words of the requirement as a
   fallback.
3. Always state the resolved slug back to the user so they can correct it.

### Resume check

Before initializing, check if `.agents/features/<feature-slug>/` already exists:
- If a `00-requirement/` file exists with `status: clarified` or later, don't restart —
  tell the user clarification is already done and show the existing summary. Ask
  whether to re-clarify (overwrite) or proceed to `specify`.
- If it exists with `status: clarifying`, resume from its recorded progress instead of
  starting a fresh loop.

List any *other* feature directories under `.agents/features/` in one line, so the user
has visibility when juggling multiple features — but only act on the one matching this
slug.

## Initialization

1. Create `.agents/features/<feature-slug>/00-requirement/requirement.local.md`
   (creating parent directories as needed):
```
---
slug: [SLUG]
status: clarifying
iteration: 1
max_iterations: [MAX_ITERATIONS]
original_requirement: "[REQUIREMENT]"
started_at: "[ISO timestamp]"
---

## Original Requirement
"[REQUIREMENT]"

## Clarification Progress
(Decisions will be recorded as the loop progresses)
```

2. Confirm activation to the user, stating: the original requirement, max questions,
   and the state file path.

## Clarification Methodology

You are now in a **Clarify Loop**. Transform the vague requirement into a precise,
actionable specification through iterative questioning.

### Your Task

1. **Environment/tooling recon first** (before asking anything scope-affecting): check
   what's actually available — installed CLIs, credentials, integrations relevant to
   the requirement — so questions aren't wasted asking the user to choose between
   options that turn out to be unavailable.
2. **Analyze** the original requirement and list every ambiguity that would actually
   change what gets built or how it's verified. Ignore ambiguities that don't affect
   implementation.
3. **Early exit**: if zero ambiguities block implementation, skip questioning entirely.
4. **Flag new skills/tooling as a deliverable**: if the clarified requirement implies
   building new skills or tooling (not just using existing ones), say so explicitly
   before finalizing the summary — don't let it surface only implicitly in the Scope
   text (see README for why this matters).
5. **Ask only as many questions as there are real ambiguities**, up to 4, in one round,
   directly to the user (however your own interface presents questions — no specific
   tool is assumed). Don't invent filler questions to pad the round to 4.
6. **Record** all answers immediately in the state file's `## Clarification Progress`
   section (bump `iteration`) — so if the session ends mid-loop, the next one resumes
   instead of re-asking.
7. **Check completion**: always offer "Clarification complete - proceed with current
   understanding" as the last option of the last question round.
8. **Repeat** only if unresolved blocking ambiguities remain, until the user confirms
   completion OR max iterations reached.

### Question Design Guidelines

- Ask **only as many questions as needed** (1-4).
- Order questions by how much they block implementation — most-blocking first.
- Use **neutral framing** without bias toward any option.
- Cover **different ambiguity categories** per round — don't ask two questions about
  the same category at once.

### Ambiguity Categories to Probe

Scope, Behavior (edge cases/errors), Interface, Data, Constraints, Priority, Reason
(why/jobs-to-be-done), Success (how to verify), Authorization (who can/cannot).

For any requirement touching roles, permissions, ownership, or tenant boundaries,
always derive the paired positive/negative case (who **can**, who **cannot**) — a
business decision only the user can confirm. Don't leave the negative case implicit.

## Completion Rules

When the user confirms completion OR max iterations is reached:

1. Output the final clarified requirement:

```markdown
## Requirement Clarification Summary

### Before (Original)
"{original requirement verbatim}"

### After (Clarified)
**Goal**: [precise description]
**Reason**: [the ultimate purpose]
**Scope**: [what's included and excluded]
**Constraints**: [limitations, requirements]
**Success Criteria**: [how to verify]

**Decisions Made**:
| Question | Decision |
|----------|----------|
| [ambiguity 1] | [chosen option] |

**Acceptance Criteria (pass/fail pairs)**: for every authorization/role/tenant boundary
touched, list the positive and its negative counterpart together — omit entirely if the
requirement has no such boundary.
```

1a. **If the requirement describes a system/feature** (not a narrow fix/bugfix), also
   structure the output with explicit **Functional Requirements** (FR1, FR2, ...),
   **Non-Functional Requirements** (NFR1, NFR2, ...), and **User Stories** (US1: "As a
   <role>, I need to <action> so that <goal>", ...) sections, each with a stable ID —
   `specify` traces its spec decisions back to these IDs, so they need to exist and be
   stable once assigned. Skip this entirely for a narrow fix where Goal/Scope above
   already says everything needed.
   Tag each FR/NFR/US with a **MoSCoW** category (`Must | Should | Could | Won't`) and,
   optionally, a **Kano** category (`Basic | Performance | Delighter`) — prioritization
   belongs at the requirement level, not invented later at the ticket level. Ask the
   user for these tags as part of the same clarification round if they're not obvious
   from context; don't guess silently on a Must vs. Should call.

2. State plainly that clarification is complete — no special completion tag needed for
   a non-Claude agent's own harness.
3. Update the state file: set `status: clarified`, replace `## Clarification Progress`
   with the final summary above. Keep the file — `specify` reads it next.
4. Run the Cloud sync completion step above, if `cloud` is enabled.
5. Suggest the next step: run `specify` for `<slug>`.

**Do not claim clarification is complete before it genuinely is.**
