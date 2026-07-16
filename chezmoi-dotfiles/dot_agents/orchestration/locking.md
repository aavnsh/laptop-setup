# Single-writer-per-ticket locking

Governs concurrent writes to the *same* ticket's files. This is a narrower problem than
amendments.md decision 8's cross-session decision drift (two sessions independently
resolving the *same open question* in *different* files with no shared awareness) —
that problem is addressed separately, by `ticket-schema.md`'s "handoff package generated
fresh from current spec + current amendments.md" rule. Locking only prevents two writers
racing on one ticket's own files at the same instant.

## Rule

Before writing any state-changing file for a ticket (advancing `states.md`'s transition
table, writing a verdict, flipping `status:`), an agent creates a lock:

```
mkdir <slice-dir>/.lock
```

`mkdir` is POSIX-atomic — exactly one concurrent caller succeeds, so this needs no
separate check-then-act race window. On success, the agent writes its identity into the
lock:

```
<slice-dir>/.lock/claim.md
---
agent_id: <string identifying the agent/session>
claimed_at: <ISO 8601 timestamp>
---
```

The agent removes `<slice-dir>/.lock` (the whole directory) when its write is complete.
Any agent that fails to `mkdir` (lock already held) must not write to the ticket; it
either waits or, if the lock's `claimed_at` is older than 30 minutes, may treat it as
stale and reclaim it (remove and recreate) — 30 minutes is long enough to cover a real
in-progress implementation run without indefinitely blocking on a crashed/abandoned one.

## Scope

This governs the *ticket's own* files (`00-spec/`, `01-implement/`, `02-review/`,
`03-retro/`, and the ticket's frontmatter). It does not cover feature-level shared files
like `SLICES.md` or `STATUS.md` (generated/derived views — safe to regenerate, so a race
there just means regenerating again, not data loss) or `00-requirement/amendments.md`
(a single, low-frequency, usually-human-mediated file where the practical mitigation is
the "fresh handoff package" rule, not locking).
