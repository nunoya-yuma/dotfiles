# dotfiles

Personal environment setup, reproducible on Linux/WSL, GitHub Codespaces
and (VS Code only) native Windows.

## Setup

Run `./install.sh` (idempotent). It symlinks the files below into `$HOME`,
backing up any existing non-symlink file as `<file>.bak.<timestamp>`.

- **Native Windows** (from Git Bash): links only the VS Code files into
  `%APPDATA%\Code\User`. Needs an Administrator shell or Developer Mode to
  create symlinks.
- **Codespaces**: runs automatically once this repo is registered as your
  dotfiles repo in [GitHub Settings → Codespaces](https://github.com/settings/codespaces).
  It also installs Claude Code there; authenticate it either with an
  `ANTHROPIC_API_KEY` [Codespaces secret](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces)
  (pay-per-token, no login step) or by running `claude` once to log in with
  a subscription (repeated for each new Codespace).

## What's managed

| Path | Linked to | Notes |
|---|---|---|
| `bash/bash_aliases` | `~/.bash_aliases` | Aliases, PATH, fzf. Machine-specific additions go in `~/.bash_aliases.local` (created empty on first run) |
| `zsh/zshrc` | `~/.zshrc` (only if zsh is installed) | Mirrors the bash setup. Machine-specific additions go in `~/.zshrc.local` |
| `git/gitconfig` | `~/.gitconfig` | |
| `git/hooks/` | `~/.githooks` (global `core.hooksPath`) | Runs the repo's own hook first, then a secret scan (`pre-commit`) and trailing-newline fix. Bypass once with `--no-verify` |
| `nvim/` | `~/.config/nvim` | Trial config for the VS Code Neovim extension |
| `vscode/settings.json`, `keybindings.json`, `snippets/` | VS Code local user scope (Linux or Windows) | Remote machine scope is not managed ([0001](docs/decisions/0001-vscode-settings-scope-tracking.md)). Snippet files must be named `<languageId>.json` |
| `vscode/extensions.txt` | — | Not installed automatically (see below) |
| `agents/AGENTS.md` | `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, `~/.copilot/copilot-instructions.md` | Global instructions shared by coding agents ([0002](docs/decisions/0002-agent-instructions-and-skills-linking.md)) |
| `agents/skills/*` | Each skill into `~/.claude/skills`, `~/.agents/skills`, `~/.copilot/skills` | Re-run `install.sh` after adding or removing a skill ([0002](docs/decisions/0002-agent-instructions-and-skills-linking.md)) |

## Optional tools

Not installed by `install.sh`; the config works without them.

- **just** (for the `ju` alias, which runs `.private-scratch/justfile`):
  - Debian/Ubuntu: `apt install just`
  - Any Linux/macOS: `curl --proto '=https' --tlsv1.2 -sSf https://just.systems/install.sh | bash -s -- --to ~/.local/bin`
  - Rust toolchain: `cargo install just`
  - Native Windows: `winget install --id Casey.Just --exact`
- **fzf 0.48+** (key bindings and `**<Tab>` completion):
  - Debian/Ubuntu: apt's package is too old; use the official installer:
    ```sh
    git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf
    ~/.fzf/install --bin
    ln -sf ~/.fzf/bin/fzf ~/.local/bin/fzf
    ```
  - macOS, or Linux with Homebrew: `brew install fzf`
  - Native Windows: `winget install -e --id junegunn.fzf`
- **zsh plugins** (sourced only if present):
  ```sh
  git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
  git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
  ```
- **VS Code extensions**:
  ```sh
  while IFS= read -r ext; do code --install-extension "$ext"; done < vscode/extensions.txt
  ```
- **VS Code Neovim extension** in a Remote-WSL/SSH window: install it on
  the remote side (`code --install-extension asvetliakov.vscode-neovim`
  from that side's terminal); it uses that side's `nvim`.

## Secrets

Nothing sensitive (API keys, tokens, SSH private keys) belongs in this repo —
it's meant to be safe to keep public. The committed git identity here is
just a name/email, which is already public on every commit anyway.

## Design decisions

[`docs/decisions/`](docs/decisions/) records choices that took real
back-and-forth — check there before changing something that looks odd.
