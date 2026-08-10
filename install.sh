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

echo "dotfiles install complete."
