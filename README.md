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
- `zsh/zshrc` — symlinked to `~/.zshrc`, but only if zsh is actually
  installed on the machine (`install.sh` checks `command -v zsh`) — zsh
  isn't installed on every machine this repo targets, and an inert
  `~/.zshrc` on a machine that never runs zsh just adds clutter. Aliases,
  `EDITOR`/`VISUAL`, history, completion, keybindings, and a
  git-aware prompt (via `vcs_info`). Kept in sync with
  `bash/bash_aliases` wherever zsh has an equivalent. Sources
  `~/.zshrc.local` if present, for machine-specific additions that
  shouldn't be committed (created empty by `install.sh` on first run,
  never overwritten after — same pattern as `~/.bash_aliases.local`).
  - `zsh-autosuggestions` and `zsh-syntax-highlighting` are **not**
    fetched or managed by this repo (cloning third-party code
    automatically isn't appropriate on every machine, e.g. ones
    requiring license/approval review first) — `zsh/zshrc` only
    `source`s them if already present at `~/.zsh/zsh-autosuggestions`
    and `~/.zsh/zsh-syntax-highlighting`. Install them yourself if you
    want them:
    ```
    git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
    git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.zsh/zsh-syntax-highlighting
    ```
- `git/gitconfig` — symlinked to `~/.gitconfig`.
- `git/ignore` — symlinked to `~/.config/git/ignore`, git's default global
  excludes file (read automatically, no `core.excludesFile` needed).
- `vscode/settings.json` — a single machine can be a local desktop and, at
  other times, a vscode-server-backed remote target (WSL/SSH/Dev
  Containers), so both scopes are linked whenever relevant, not
  either/or:
  - **Local user scope** (always linked): symlinked to
    `~/.config/Code/User/settings.json`, VS Code's normal user settings
    file. macOS/Windows local paths aren't handled yet.
  - **Remote machine scope** (linked only if `~/.vscode-server` already
    exists): symlinked to `~/.vscode-server/data/Machine/settings.json`.
    That dir is always created by the server itself before `install.sh`
    runs, so its presence means this machine has been used as a remote
    target at least once; its absence means `install.sh` skips this link
    rather than creating the dir speculatively. Applies inside any
    vscode-server-backed connection, independent of which local client
    connects.
- `vscode/keybindings.json` — always symlinked to
  `~/.config/Code/User/keybindings.json` (local user scope, same
  reasoning as settings.json above). VS Code has no remote/machine scope
  for keybindings — when *this* machine is the one being connected *to*
  remotely, keybindings always come from the connecting client's own
  local profile instead (e.g. the desktop app's
  `%APPDATA%\Code\User\keybindings.json`), so this file has no effect in
  that direction. When opening a remote connection from a local VS Code
  Desktop install, your existing local keybindings already apply
  automatically — nothing to do. When connecting from a fresh browser tab
  with no synced profile, paste this file's contents into the Keyboard
  Shortcuts (JSON) editor (`Ctrl+Shift+P` → "Preferences: Open Keyboard
  Shortcuts (JSON)") to apply them manually.
- `vscode/snippets/` — global user snippets, symlinked as a directory to
  `~/.config/Code/User/snippets` (local user scope, same reasoning as
  settings.json above). Each file uses VS Code's language-scoped naming
  (`<languageId>.json`, e.g. `python.json`, `shellscript.json` — the
  filename must match the language ID exactly or the snippets silently
  won't trigger). Like `keybindings.json`, snippets have no remote/machine
  scope in VS Code — they're classified as a UI Extension resource that
  always runs on the local client, so a remote session uses the connecting
  client's own local snippets automatically; nothing to link on the remote
  host.
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

- `agents/AGENTS.md` — global user instructions (applies across every
  project, distinct from a per-project instructions file). Named
  `AGENTS.md`, not `CLAUDE.md`: Claude Code doesn't read `AGENTS.md`
  natively, but it does follow a symlink named `CLAUDE.md` that points to
  one, so it's symlinked to `~/.claude/CLAUDE.md` rather than forking the
  content or using an `@AGENTS.md` import line.
- `agents/skills/` — symlinked as a directory to `~/.claude/skills`
  (same reasoning as `vscode/snippets` above), Claude Code's global user
  skills. Each subdirectory follows the
  [Agent Skills](https://agentskills.io) open standard (a `SKILL.md` with
  YAML frontmatter), which is also read by Codex CLI, Cursor, Gemini CLI,
  GitHub Copilot, and other compatible tools — so `install.sh` links the
  same directory twice more: to `~/.agents/skills`, the universal path
  most of those tools look for, and to `~/.copilot/skills`, GitHub
  Copilot's own explicit path (not every Copilot surface is guaranteed to
  check the universal one) — making every skill here usable outside
  Claude Code too without any format changes.

## How it applies

Run `./install.sh` (idempotent — safe to re-run). It symlinks the files
above into `$HOME` (backing up any pre-existing non-symlink file it would
overwrite as `<file>.bak.<timestamp>`), then attempts to install the VS
Code extensions (see caveat above).

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
