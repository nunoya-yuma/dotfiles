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

# vscode — Machine-scoped remote settings (applies to any client, incl. browser).
# keybindings.json has no such remote scope in VS Code, so it's not linked here;
# see README for manual setup.
link "$DOTFILES_DIR/vscode/settings.json" "$HOME/.vscode-server/data/Machine/settings.json"

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