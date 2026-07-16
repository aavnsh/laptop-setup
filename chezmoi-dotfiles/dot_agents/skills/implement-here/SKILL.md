---
name: implement-here
description: Implement a spec (from specify, a clarify summary, or an issue) with minimal, best-practice diffs and low token usage, in the same session/agent that wrote the spec. Use once requirements are unambiguous and the files/approach are already known — not for exploring unclear requirements, and not for handing off to a different agent (that's a real handoff, not this skill). Cloud-sync aware (gh/linear/none).
---

# Implement-here Skill

## Git awareness

Check whether the current project uses git (e.g. `git rev-parse --is-inside-work-tree`
or simply whether `.git/` exists). If it does, follow the Claude original's branch-safety
check and end-of-run commit/push/PR presentation (never run destructive git commands
yourself — present them for the user to run). If it doesn't, completion is signaled
purely by the ticket's own `status:`/`evidence:` frontmatter — no branch/commit concept
applies.

### Issue-closing discipline (one issue per branch)

When presenting the PR description, the "Closes #N" (or "Fixes #N") line must reference
**this ticket's own `github_issue`** — the slice's own child issue, if this ticket has a
`parent_issue` field (sliced feature) — never the `parent_issue` itself. The parent/epic
issue is closed manually by whoever confirms every slice is done, not by any single
slice's PR. If this ticket's frontmatter has no `parent_issue` field, there's nothing
else to check — `github_issue` is both the ticket's own issue and the only one in scope.

If a `parent_issue` field is present, also post a short progress note there on
completion (see Cloud sync below) so the epic reflects progress without ever being
closed by this branch.

## Cloud sync (mirrors `specify`'s)

Read `.agents/config.md`'s `cloud:` field (default `none`). On completion (see below):
- **`none`**: no extra step — the ticket's own frontmatter is the record.
- **`gh`**: `gh issue comment <github_issue> --body-file <evidence-file>` with what was
  delivered and how it was checked, using the `github_issue` number already recorded in
  this ticket's own frontmatter by `specify` — same file, no separate cache to refresh.
  If this ticket also has a `parent_issue` field, additionally
  `gh issue comment <parent_issue> --body-file <short-progress-note>` — a brief "slice
  `<slug>` done, see #<github_issue>" note, never the full evidence, and never a
  "closes" reference (see "Issue-closing discipline" above).
- **`linear`**: same pattern via Linear's CLI/API/MCP if available, using the ticket's
  `linear_issue` field (and `parent_issue`'s Linear equivalent, e.g. a parent/sub-issue
  link, if the project models one); if unavailable, say so and fall back to `none`
  behavior for this run rather than failing silently.

Execute an already-clarified, already-specced change with the smallest diff that
satisfies it, in the same agent/session that wrote (or is reading) the spec.

## Invocation

Parse the input to extract:
- **SPEC**: a spec block, or a requirement + file list already agreed with the user
- **--feature SLUG**: optional explicit feature slug

If no spec exists and the requirement is non-trivial, run `specify` first rather than
guessing at scope.

## Pipeline state file (mandatory)

Shares `.agents/features/<feature-slug>/` with `clarify` and `specify`. A slice's spec
lives at `<NN>-<slice-slug>/00-spec/spec.local.md`; this skill's own output belongs
under that same slice's `01-implement/` subdirectory (evidence, any generated
handoff/log files) and, once reviewed, `02-review/verdict.local.md`.

### Determining the slug

1. If `--feature SLUG` was passed, use it.
2. Else if exactly one slice has `status: specified` (ready, not yet started), use that.
3. Else if multiple candidates exist, list them (slug, status, `order`/`depends_on`) and
   ask the user directly which one.
4. Else, this skill needs a spec — run `specify` first, or accept an inline spec and
   create the state file fresh.

### Slice ordering gate

If the resolved ticket has a `depends_on:` field, check that dependency's status first:
- If it isn't `done`, stop and tell the user this slice can't be implemented yet,
  and ask whether to switch to the dependency instead.
- Slices implement in `order` sequence — never let a later slice jump ahead of an
  unimplemented earlier one.

### Reading and writing state

1. If `status: specified`, read the spec from `00-spec/spec.local.md` instead of
   requiring it be re-pasted.
2. On start, note progress internally (files edited so far, checks run so far) so a
   dropped session can resume.
3. On completion of the work itself, write your evidence (what was written, what was
   validated, matching this project's ticket-schema.md `implemented`-state contract)
   and present it to the user — **do not write `status: done`**. Hold at
   `pending_done_approval` and explicitly ask for approval first.
4. Only once the user approves, set `status: done` with the `evidence:` field
   summarizing what was delivered and how it was checked.
5. If completion fails (checks don't pass, work is left unfinished), leave `status`
   as-is with a partial-progress note so the next session can resume.

## Before writing code (or content)

1. Re-read only the files named in the spec — they may have changed since specced.
2. **Test-first is mandatory when the change is testable.** Write or adjust the
   test(s) from the spec's Test plan before touching implementation. The only
   exception is when the spec's Test plan explicitly says no test is warranted (e.g.
   a pure config/docs change).
3. If unrelated cleanup/refactor opportunities surface, note them separately rather
   than folding them into this change.

## Red → green → refactor (when there's a test to run)

1. **Red**: run the new/adjusted test(s), confirm they fail for the expected reason
   (missing behavior), not an unrelated error.
2. **Green**: write the minimum implementation to pass. Re-run after each edit.
3. **Refactor**: once green, clean up only what this change touched. Re-run to confirm
   still green.
4. **Guardrail**: never mark a test passing without having just run it and read its
   actual output. Don't skip, loosen, or fake a pass — surface a genuine blocker to the
   user instead of working around it.

## Implementation rules (best practices)

- Match existing patterns in the file being edited; don't introduce a new pattern for
  one call site.
- No speculative abstraction, config flags, or error handling for cases that can't occur.
- Prefer targeted edits over rewriting a file; smaller diffs are cheaper to review.

## Token-saving discipline while implementing

- Don't re-read a file immediately after editing it if your tool already confirms success.
- Don't paste full file contents back to the user; reference `file:line` and describe
  the change in one line.
- Batch independent reads/searches instead of doing them one at a time.
- If unsure whether related code/config already exists, `rg -n '<symbol>'` for it before
  re-reading whole files to check — a targeted search is cheaper than a full read.
- `rg -l '<pattern>'` when you only need to know a file exists/matches, not its content.
- Run the narrowest check/test command that exercises the change first; only broaden if
  it passes.
- Avoid dumping command output verbatim when a one-line summary (pass/fail, N tests)
  suffices.

## Completion

1. Run whatever checks the spec's Test plan calls for.
2. Report: files changed, checks run, results, anything unverified.
3. Run the tracker-mode evidence sync above, if applicable (including the parent-issue
   progress note, if this ticket has a `parent_issue` field).
4. Update the ticket's evidence, hold at `pending_done_approval` (if the project defines
   that gate), and explicitly ask the user to approve before writing `status: done` —
   the human-approval intent applies regardless of whether the project uses git.
5. Once approved, suggest (don't run) `retro` for this ticket, if the project has that
   skill — a suggestion only, same as `specify` suggesting `implement-here` as its own
   next step.
