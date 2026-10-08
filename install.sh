#!/usr/bin/env bash
# The one entry point for every machine, native Windows (Git Bash) included.
# Codespaces runs it automatically. See README.
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1" dst="$2"
  # Skip correct links so re-runs on Windows don't need the symlink privilege.
  if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
    echo "Already linked $dst"
    return
  fi
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

# Native Windows only gets the VS Code files (docs/decisions/0001).
case "$(uname -s)" in
  MINGW* | MSYS* | CYGWIN*)
    if [ -z "${APPDATA:-}" ]; then
      echo "APPDATA is not set — run this from Git Bash on native Windows, not WSL or Linux." >&2
      exit 1
    fi
    # Convert the native Windows path to the POSIX form Git Bash expects.
    if command -v cygpath >/dev/null 2>&1; then
      WIN_APPDATA="$(cygpath -u "$APPDATA")"
    else
      WIN_APPDATA="$APPDATA"
    fi
    VSCODE_USER_DIR="$WIN_APPDATA/Code/User"
    # Git Bash's `ln -s` silently copies by default; fail instead.
    export MSYS="winsymlinks:nativestrict${MSYS:+ $MSYS}"
    link "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
    link "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
    link "$DOTFILES_DIR/vscode/snippets" "$VSCODE_USER_DIR/snippets"
    echo "Windows VS Code local user scope linked."
    exit 0
    ;;
esac

# bash
link "$DOTFILES_DIR/bash/bash_aliases" "$HOME/.bash_aliases"

# Loaded on demand by bash-completion, if installed.
link "$DOTFILES_DIR/bash/completions/just" "$HOME/.local/share/bash-completion/completions/just"
link "$DOTFILES_DIR/bash/completions/ju" "$HOME/.local/share/bash-completion/completions/ju"

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

# zsh: only where it's installed.
if command -v zsh >/dev/null 2>&1; then
  link "$DOTFILES_DIR/zsh/zshrc" "$HOME/.zshrc"
  link "$DOTFILES_DIR/zsh/completions" "$HOME/.zsh/completions"

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
link "$DOTFILES_DIR/git/hooks" "$HOME/.githooks"

# nvim
link "$DOTFILES_DIR/nvim" "$HOME/.config/nvim"

# vscode (local user scope; extensions.txt is installed manually)
VSCODE_USER_DIR="$HOME/.config/Code/User"
link "$DOTFILES_DIR/vscode/settings.json" "$VSCODE_USER_DIR/settings.json"
link "$DOTFILES_DIR/vscode/keybindings.json" "$VSCODE_USER_DIR/keybindings.json"
link "$DOTFILES_DIR/vscode/snippets" "$VSCODE_USER_DIR/snippets"

# Claude Code CLI: Codespaces only, so other machines get no surprise install.
if [ "${CODESPACES:-}" = "true" ] && ! command -v claude >/dev/null 2>&1; then
  if curl -fsSL https://claude.ai/install.sh | bash; then
    echo "Installed Claude Code"
  else
    echo "Skipped Claude Code install (curl https://claude.ai/install.sh | bash failed)"
  fi
fi

# agents: one instructions file and the skills, linked into each tool's
# path (docs/decisions/0002).
link "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.claude/CLAUDE.md"
link "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.codex/AGENTS.md"
link "$DOTFILES_DIR/agents/AGENTS.md" "$HOME/.copilot/copilot-instructions.md"

# Skills are linked one by one, since tools write their own skills into
# these directories too.
link_skills() {
  local dst_dir="$1" skill_md skill entry
  # Older installs linked the whole directory; replace that link with a
  # real directory (rm on a symlink removes only the link).
  if [ -L "$dst_dir" ]; then
    rm "$dst_dir"
    echo "Replaced directory link $dst_dir with a real directory"
  fi
  mkdir -p "$dst_dir"
  for skill_md in "$DOTFILES_DIR"/agents/skills/*/SKILL.md; do
    skill="$(dirname "$skill_md")"
    link "$skill" "$dst_dir/$(basename "$skill")"
  done
  # Drop links to skills since removed from this repo.
  for entry in "$dst_dir"/*; do
    if [ -L "$entry" ] && [ ! -e "$entry" ] &&
      [[ "$(readlink "$entry")" == "$DOTFILES_DIR/agents/skills/"* ]]; then
      rm "$entry"
      echo "Removed stale link $entry"
    fi
  done
}

link_skills "$HOME/.claude/skills"
link_skills "$HOME/.agents/skills"
link_skills "$HOME/.copilot/skills"

echo "dotfiles install complete."
