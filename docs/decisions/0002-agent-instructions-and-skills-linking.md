# 0002: How agent instructions and skills reach each tool

## Status

Accepted

## Context

`agents/` holds one set of global instructions and personal skills meant
to be shared by several coding agents (Claude Code, Codex CLI, GitHub
Copilot). Each tool looks for them in its own place:

- Global instructions: Claude Code reads `~/.claude/CLAUDE.md`, Codex CLI
  `~/.codex/AGENTS.md`, Copilot CLI `~/.copilot/copilot-instructions.md`.
- Skills (the [Agent Skills](https://agentskills.io/specification) format:
  a directory with a `SKILL.md`): Claude Code reads `~/.claude/skills`,
  Codex `~/.agents/skills`, and VS Code Copilot `~/.copilot/skills`,
  `~/.claude/skills` and `~/.agents/skills`
  ([Codex](https://learn.chatgpt.com/docs/build-skills),
  [VS Code](https://code.visualstudio.com/docs/agent-customization/agent-skills),
  checked 2026-10-08).

These directories are not only read: Claude Code also writes skills synced
from claude.ai into `~/.claude/skills/synced`.

## Decision

- Keep one instructions file, `agents/AGENTS.md`, and symlink it to each
  tool's path. It is named `AGENTS.md` for the tools that read that name
  natively; Claude Code follows a symlink named `CLAUDE.md` to it, so no
  `@AGENTS.md` import file is needed.
- Symlink each skill individually into a real directory at each skills
  path, rather than symlinking the whole `agents/skills` directory.
  `install.sh` also removes links to skills deleted from this repo.
- Keep skills to a plain `SKILL.md`. Tool-specific frontmatter (e.g.
  Claude Code's `disable-model-invocation`) may stay as a bonus, but the
  instructions themselves must hold without it, since other tools ignore
  it (Codex has its own `agents/openai.yaml` instead, not used here).

## Alternatives considered

1. **Symlink the whole `agents/skills` directory** (the original setup).
   Rejected: Claude Code's synced skills then landed inside this repo
   (hidden only by a `.gitignore` entry), and through the shared links
   became visible to the other tools too.
2. **Separate per-tool config** such as Codex's `agents/openai.yaml` to
   block implicit invocation. Not adopted while Codex isn't in use; the
   skill descriptions say they are for explicit invocation instead.

## Consequences

- Re-run `install.sh` after adding or removing a skill.
- VS Code Copilot may see each skill from three paths; whether that causes
  duplicates in practice hasn't been checked.
