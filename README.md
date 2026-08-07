# dotfiles

Personal environment setup, managed so it can be reproduced automatically on
[GitHub Codespaces](https://docs.github.com/en/codespaces/setting-up-your-project-for-codespaces/personalizing-github-codespaces-for-your-account).

## What's managed here

- `bash/bash_aliases` — sourced as `~/.bash_aliases` by the distro-default
  `~/.bashrc` (unmodified). Aliases, PATH, `EDITOR`/`VISUAL`, shell
  ergonomics (`autocd`, history search, cross-terminal history sync).
  Sources `~/.bash_aliases.local` if present, for machine-specific
  additions that shouldn't be committed (created empty by `install.sh` on
  first run, never overwritten after).
- `git/gitconfig` — symlinked to `~/.gitconfig`.
- `git/ignore` — symlinked to `~/.config/git/ignore`, git's default global
  excludes file (read automatically, no `core.excludesFile` needed).
- `vscode/settings.json` — symlinked to
  `~/.vscode-server/data/Machine/settings.json`. This is VS Code's
  *remote-scoped* settings file: it applies inside any vscode-server-backed
  connection (WSL, SSH, Dev Containers, Codespaces — including a
  browser-based Codespace), independent of which local client connects.
- `vscode/extensions.txt` — extension IDs installed via
  `code --install-extension` (one per line).
- `vscode/keybindings.json` — **reference only, not applied automatically.**
  VS Code has no remote/machine scope for keybindings — they always come
  from the connecting client's own local profile (e.g. the desktop app's
  `%APPDATA%\Code\User\keybindings.json`), which `install.sh` running
  inside the container/Codespace has no way to reach. When opening a
  Codespace from a local VS Code Desktop install, your existing local
  keybindings already apply automatically — nothing to do. When opening a
  Codespace from a fresh browser tab with no synced profile, paste this
  file's contents into the Keyboard Shortcuts (JSON) editor
  (`Ctrl+Shift+P` → "Preferences: Open Keyboard Shortcuts (JSON)") to
  apply them manually.

## How it applies

Run `./install.sh` (idempotent — safe to re-run). It symlinks the files
above into `$HOME` (backing up any pre-existing non-symlink file it would
overwrite as `<file>.bak.<timestamp>`), then installs the VS Code
extensions. `vscode/keybindings.json` is skipped — see above.

### Codespaces

GitHub Codespaces automatically clones a repo named `dotfiles` under your
account into the container and runs `install.sh` (or `install`,
`bootstrap.sh`, etc.) if present — no manual step needed once this repo is
registered as your dotfiles repo in
[GitHub Settings → Codespaces](https://github.com/settings/codespaces).

## Secrets

Nothing sensitive (API keys, tokens, SSH private keys) belongs in this repo —
it's meant to be safe to keep public. The committed git identity here is
just a name/email, which is already public on every commit anyway.
