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

# git
link "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"
link "$DOTFILES_DIR/git/ignore" "$HOME/.config/git/ignore"

# vscode
# A pre-existing ~/.vscode-server means install.sh is running inside a
# vscode-server-backed connection (WSL, SSH, Dev Containers, Codespaces) —
# that dir is created by the server itself, before this script ever runs.
# Otherwise, this is a plain local machine and VS Code's own User dir is
# directly reachable, so everything can be symlinked normally.
if [ -d "$HOME/.vscode-server" ]; then
  # Machine-scoped remote settings (applies to any client, incl. browser).
  # keybindings.json has no such remote scope in VS Code, so it's not
  # linked here; see README for manual setup.
  link "$DOTFILES_DIR/vscode/settings.json" "$HOME/.vscode-server/data/Machine/settings.json"
else
  VSCODE_USER_DIR="$HOME/.config/Code/User"
  link "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
  link "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
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
