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
- `vscode/settings.json` — where it's linked depends on how `install.sh`
  is running:
  - **Remote** (WSL, SSH, Dev Containers, Codespaces — detected by a
    pre-existing `~/.vscode-server`): symlinked to
    `~/.vscode-server/data/Machine/settings.json`, VS Code's
    *remote-scoped* settings file. It applies inside any
    vscode-server-backed connection, independent of which local client
    connects.
  - **Local machine** (no `~/.vscode-server`, e.g. a fresh Linux/WSL
    install with VS Code installed directly): symlinked to
    `~/.config/Code/User/settings.json`, VS Code's normal user settings
    file. macOS/Windows local paths aren't handled yet.
- `vscode/keybindings.json` — **local machine only.** Symlinked to
  `~/.config/Code/User/keybindings.json` when running locally (see above).
  In the remote case it's **reference only, not applied automatically** —
  VS Code has no remote/machine scope for keybindings, they always come
  from the connecting client's own local profile (e.g. the desktop app's
  `%APPDATA%\Code\User\keybindings.json`), which `install.sh` running
  inside the container/Codespace has no way to reach. When opening a
  Codespace from a local VS Code Desktop install, your existing local
  keybindings already apply automatically — nothing to do. When opening a
  Codespace from a fresh browser tab with no synced profile, paste this
  file's contents into the Keyboard Shortcuts (JSON) editor
  (`Ctrl+Shift+P` → "Preferences: Open Keyboard Shortcuts (JSON)") to
  apply them manually.
- `vscode/extensions.txt` — extension IDs to install via
  `code --install-extension` (one per line). **Not installed automatically
  by Codespaces' dotfiles provisioning** — at that point in the container
  lifecycle no VS Code client has connected yet, so the `code` CLI has
  nothing to talk to and the install silently fails (`install.sh` logs
  this and moves on rather than aborting). To actually install them,
  re-run `./install.sh` manually after connecting, or rely on VS Code's
  Settings Sync. For extensions a specific *project* always needs
  regardless of who opens it, use that project's own
  `devcontainer.json` → `customizations.vscode.extensions` instead — that
  installs automatically because the connecting client (not this script)
  is what triggers it.

## How it applies

Run `./install.sh` (idempotent — safe to re-run). It symlinks the files
above into `$HOME` (backing up any pre-existing non-symlink file it would
overwrite as `<file>.bak.<timestamp>`), then attempts to install the VS
Code extensions (see caveat above). `vscode/keybindings.json` is skipped
in the remote case — see above.

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
