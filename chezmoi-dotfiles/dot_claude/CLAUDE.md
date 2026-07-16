# Personal Claude Code Preferences

## Style

- Concise responses, no filler
- Use conventional commits
- Shell: 2-space indent, set -euo pipefail
- Lua: stylua formatting
- When writing commit messages, NEVER auto-add your name as co-author
- When doing bug-fixes, start by reproducing the bug in an E2E setting that matches 
what the user will see as closely as possible before starting to plan the fix
- When doing E2E testing be obsessed about pixel perfectness. If something is clearly off even if it is not related to something you are working on - fix it.
- Apply same high standards level to engineering excellence: lint, test failures, test flakiness, code smells. If you see one even if not caused by what you are working on right now, get it fixed.
- When making technical decisions, do not put much weight to development cost. Instead prefer quality, robustness, simplicity, scalability and long-term maintainability. 

## Handing over commands

Whenever I need to run shell steps myself (signed-commit flows
where your Bash tool can't reach my ssh-agent, interactive
prompts, anything destructive that needs my eyes first), hand
them over as ONE runnable script FILE that I can invoke by path
— never a fenced copy-paste block, never scattered one-liners.

- Write the script to disk: `.git/<name>.sh` for repo-local
  work, or another path outside the working tree.
- `chmod +x` it so I can run it directly: `./.git/<name>.sh`.
- Shebang `#!/usr/bin/env bash`, first line of body
  `set -euo pipefail`.
- Quote heredocs (`<<'EOF'`) so commit messages don't
  interpolate.
- Normalise cwd up front: `cd "$(git rev-parse --show-toplevel)"`
  (or an explicit absolute path).
- Multi-phase work goes in one script with labelled sections,
  not multiple scripts I have to chain.
- After the script, one line on what it does and what to tell
  you next.

A fenced ```bash block in chat is NOT a script — it's a
copy-paste instruction. Write the file.

Applies to every project, not just the one this preference was
captured in.

## Tools

- Package manager: mise (not asdf, not nvm)
- Shell: zsh (primary), fish, bash
- Editor: Neovim with lazy.nvim
- Dotfiles: chezmoi-managed
