#!/usr/bin/env bash
# Entry point auto-detected and run by GitHub Codespaces when this repo
# is registered as the account's dotfiles repository.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
    echo "Backed up existing $dst"
  fi
  ln -sfn "$src" "$dst"
  echo "Linked $dst -> $src"
}

# bash
link "$DOTFILES_DIR/bash/bash_aliases" "$HOME/.bash_aliases"

# Machine-specific overrides — never tracked by this repo, never overwritten.
LOCAL_ALIASES="$HOME/.bash_aliases.local"
if [ ! -e "$LOCAL_ALIASES" ]; then
  cat > "$LOCAL_ALIASES" <<'EOF'
# Machine-specific bash additions.
# Not tracked by the dotfiles repo — put secrets or one-off local
# settings here instead of in bash/bash_aliases.
# Sourced automatically by ~/.bash_aliases if present.
EOF
  echo "Created $LOCAL_ALIASES"
fi

# zsh isn't installed on every machine this repo targets, so only link it
# when it's actually present — an inert ~/.zshrc otherwise just adds
# clutter to a machine that never uses it.
if command -v zsh >/dev/null 2>&1; then
  link "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"

  ZSH_LOCAL="$HOME/.zshrc.local"
  if [ ! -e "$ZSH_LOCAL" ]; then
    cat > "$ZSH_LOCAL" <<'EOF'
# Machine-specific zsh additions.
# Not tracked by the dotfiles repo — put secrets or one-off local
# settings here instead of in zsh/zshrc.
# Sourced automatically by ~/.zshrc if present.
EOF
    echo "Created $ZSH_LOCAL"
  fi
fi

# git
link "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
link "$DOTFILES_DIR/git/ignore" "$HOME/.config/git/ignore"
link "$DOTFILES_DIR/git/hooks" "$HOME/.githooks"

# vscode
# A single machine can be used both as a local desktop and, at other times,
# as a vscode-server-backed remote target (WSL/SSH/Dev Containers) — the two
# aren't mutually exclusive, so both scopes are linked whenever relevant.

# Local user scope — always linked. VS Code creates ~/.config/Code itself on
# first local launch, but a fresh machine may not have run VS Code yet when
# this script runs, so create it if needed.
VSCODE_USER_DIR="$HOME/.config/Code/User"
link "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
link "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
link "$DOTFILES_DIR/vscode/snippets" "$VSCODE_USER_DIR/snippets"

# Machine-scoped remote settings (applies to any client, incl. browser,
# connecting to this machine over vscode-server). Only linked if
# ~/.vscode-server already exists — that dir is always created by the
# server itself before this script runs, so its presence means this
# machine has been used as a remote target; its absence means it hasn't,
# and there's no point creating it speculatively. keybindings.json has no
# such remote scope in VS Code, so it's not linked here; see README for
# manual setup.
if [ -d "$HOME/.vscode-server" ]; then
  link "$DOTFILES_DIR/vscode/settings.json" "$HOME/.vscode-server/data/Machine/settings.json"
fi

# Snippets, like keybindings.json above, have no remote/machine scope in VS
# Code — the docs classify snippets as a UI Extension resource, always run
# on the local client, so a remote session uses the connecting client's own
# local snippets rather than anything on the remote host. No remote link
# needed here.

# zsh isn't installed on every machine this repo targets, so its VS Code
# terminal profile default can't live in the tracked settings.json (a
# machine without zsh would fail to launch a terminal). Nudge instead: add
# it yourself to the machine-local section at the bottom of
# vscode/settings.json, and never commit that line.
if command -v zsh >/dev/null 2>&1 && ! grep -q '"terminal.integrated.defaultProfile.linux"' "$DOTFILES_DIR/vscode/settings.json"; then
  echo "zsh detected — add \"terminal.integrated.defaultProfile.linux\": \"zsh\" to the machine-local section at the bottom of vscode/settings.json (do not commit it)."
fi

# The `code` CLI only works once a client has actually connected — during
# Codespaces' automatic dotfiles provisioning (this script), no client is
# attached yet, so this reliably fails there. Re-run install.sh manually
# after connecting to actually install extensions this way.
if command -v code >/dev/null 2>&1 && [ -f "$DOTFILES_DIR/vscode/extensions.txt" ]; then
  while IFS= read -r ext; do
    [ -z "$ext" ] && continue
    code --install-extension "$ext" --force || echo "Skipped $ext (no VS Code client connected yet)"
  done < "$DOTFILES_DIR/vscode/extensions.txt"
fi

# Claude Code CLI
# Codespaces only — this script also runs as a plain manual ./install.sh on
# any other machine (see README), and installing an agentic CLI nobody asked
# for there would be a surprise. $CODESPACES=true is the env var GitHub sets
# in every Codespace container. Auth: if an ANTHROPIC_API_KEY development
# environment secret is registered for this repo at
# github.com/settings/codespaces, Claude Code picks it up automatically and
# skips the interactive browser login (see README). Without it, run `claude`
# once after connecting to log in interactively via a Pro/Max/Team/Enterprise
# account instead.
if [ "${CODESPACES:-}" = "true" ] && ! command -v claude >/dev/null 2>&1; then
  if curl -fsSL https://claude.ai/install.sh | bash; then
    echo "Installed Claude Code"
  else
    echo "Skipped Claude Code install (curl https://claude.ai/install.sh | bash failed)"
  fi
fi

# agents
# The canonical file is named AGENTS.md, not CLAUDE.md — Claude Code
# doesn't read AGENTS.md natively, but it does follow a symlink named
# CLAUDE.md to it, so linking here (rather than importing via an `@`
# line) keeps a single tracked file that both Claude Code and any
# AGENTS.md-native tool read unmodified.
link "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/agents/skills" "$HOME/.claude/skills"

# Codex CLI reads its own global personal instructions from
# ~/.codex/AGENTS.md (distinct from any AGENTS.md nearer a project root) —
# link the same file there too.
link "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.codex/AGENTS.md"

# GitHub Copilot's global personal instructions aren't named AGENTS.md —
# Copilot CLI reads ~/.copilot/copilot-instructions.md. (The VS Code
# extension's equivalent is skipped: community reports say it doesn't
# reliably pick up a global file yet.)
link "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"

# The same SKILL.md files also work unmodified under ~/.agents/skills, the
# universal directory read by Codex CLI, Cursor, Gemini CLI, and other
# tools that implement the open Agent Skills standard (agentskills.io) —
# link it too so skills written once are usable everywhere, whether or not
# those tools happen to be installed on this machine.
link "$DOTFILES_DIR/agents/skills" "$HOME/.agents/skills"

# GitHub Copilot reads personal (cross-project) skills from ~/.copilot/skills
# as well as ~/.agents/skills — link its own path explicitly too, since not
# every Copilot surface is guaranteed to check the universal one.
link "$DOTFILES_DIR/agents/skills" "$HOME/.copilot/skills"

echo "dotfiles install complete."
