#!/usr/bin/env bash
# Entry point auto-detected and run by GitHub Codespaces when this repo is
# registered as the account's dotfiles repository. Also the one entry
# point for every other machine this repo targets, native Windows included
# (run from Git Bash there) — see the platform branch below.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dst="$2"
  mkdir -p "$(dirname "$dst")"
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    mv "$dst" "$dst.bak.$(date +%Y%m%d%H%M%S)"
    echo "Backed up existing $dst"
  fi
  if ! ln -sfn "$src" "$dst" 2>/dev/null; then
    echo "Failed to create a symlink at $dst." >&2
    echo "On native Windows, this requires either an elevated (Administrator) shell or Developer Mode enabled (Settings > Update & Security > For developers)." >&2
    exit 1
  fi
  echo "Linked $dst -> $src"
}

# Native Windows (Git Bash/MSYS/Cygwin) only needs VS Code Desktop's own
# local user scope (%APPDATA%\Code\User) from this repo — see
# docs/decisions/0001-vscode-settings-scope-tracking.md. Branch here and
# exit rather than running the rest of this script, which assumes a
# genuine Linux $HOME.
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*)
    if [ -z "${APPDATA:-}" ]; then
      echo "APPDATA is not set — run this from Git Bash on native Windows, not WSL or Linux." >&2
      exit 1
    fi
    # APPDATA is a native Windows path (e.g. C:\Users\me\AppData\Roaming);
    # cygpath (bundled with Git for Windows) converts it to the
    # POSIX-style path Git Bash's own tools expect.
    if command -v cygpath >/dev/null 2>&1; then
      WIN_APPDATA="$(cygpath -u "$APPDATA")"
    else
      WIN_APPDATA="$APPDATA"
    fi
    VSCODE_USER_DIR="$WIN_APPDATA/Code/User"
    link "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
    link "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
    link "$DOTFILES_DIR/vscode/snippets" "$VSCODE_USER_DIR/snippets"
    echo "Windows VS Code local user scope linked."
    exit 0
    ;;
esac

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
# Local user scope — always linked. VS Code creates ~/.config/Code itself on
# first local launch, but a fresh machine may not have run VS Code yet when
# this script runs, so create it if needed.
VSCODE_USER_DIR="$HOME/.config/Code/User"
link "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
link "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
link "$DOTFILES_DIR/vscode/snippets" "$VSCODE_USER_DIR/snippets"

# vscode/extensions.txt is intentionally not installed automatically here —
# not every extension wanted on one machine is wanted (or allowed) on
# another. See README for how to install from it manually when wanted.

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
