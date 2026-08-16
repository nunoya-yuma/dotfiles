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
- `git/hooks/` — symlinked to `~/.githooks`, wired up via
  `core.hooksPath` in `git/gitconfig` so it applies to every repo on the
  machine.
  - `_chain.sh` — sourced by every hook below. Runs the target repo's
    own `.git/hooks/<name>` first, if one exists (e.g. installed by the
    `pre-commit` framework or Husky), and aborts with its exit code on
    failure. Needed because a global `core.hooksPath` makes git stop
    looking at `.git/hooks/*` at all, which would otherwise silently
    disable those tools.
  - `_secrets.sh` — sourced by `pre-commit`. Lightweight, dependency-free
    secret scan: blocks staged files matching a secret-filename pattern
    (`.env`, `id_rsa`, `credentials.json`, ...; `.env.example` and
    friends are allowlisted) and staged content matching a handful of
    high-confidence key formats (AWS, GitHub, Slack, Anthropic/OpenAI,
    PEM private key headers). Not a replacement for gitleaks/detect-secrets
    — just a cheap last line of defense. False positive? Adjust the
    patterns, or bypass once with `git commit --no-verify`.
  - `pre-commit` — after chaining and the secret scan, normalizes every
    staged text file to end with exactly one trailing newline: adds one
    if missing, collapses multiple trailing blank lines down to one.
    Only touches the very end of the file, never interior lines, so it
    can't disturb Markdown's trailing-two-spaces hard-break convention.
    Binary files (detected the same way `git diff --numstat` does —
    presence of a NUL byte) are left alone. Guards against files (often
    agent-edited) committed with no final newline, or several.
  - `pre-push` — chains only, no custom checks of its own yet.
- `vscode/settings.json` — VS Code's local user scope: genuinely common
  settings that should apply everywhere, independent of which machine is
  being connected to (or whether one is at all). `install.sh` symlinks it
  to `~/.config/Code/User/settings.json` on a genuine Linux desktop, and
  to `%APPDATA%\Code\User\settings.json` (resolved via `cygpath`) when run
  from Git Bash on native Windows instead — see "How it applies" below.
  macOS local paths aren't handled yet.
  - VS Code's other relevant scope, "Remote [WSL/SSH/...]" **machine
    scope**, is deliberately **not** tracked here, even though it's
    layered on top of local user scope while connected (so it could, in
    principle, hold shared overrides). VS Code creates and persists that
    file itself the moment any setting is set through the Remote Settings
    UI — it already existed with real content on this machine before this
    repo ever touched it. Its entire purpose is to hold overrides specific
    to *one* box (e.g. a terminal profile default that only makes sense on
    a machine with that shell installed), which by definition isn't
    shared, tracked content — `install.sh` doesn't touch
    `~/.vscode-server/data/Machine/settings.json` at all; set it directly
    through VS Code's own Remote Settings UI if you want one.
- `vscode/keybindings.json` — symlinked into every local user scope above
  (Linux or Windows, whichever `install.sh` detects). VS Code has no
  remote/machine scope for keybindings — when *this* machine is the one
  being connected *to* remotely, keybindings always come from the
  connecting client's own local profile instead, so this file has no
  effect in that direction. If the connecting client is a Windows machine
  that has run `install.sh` itself, that's already covered. When
  connecting from a client that hasn't (an SSH target, or a fresh browser
  tab with no synced profile), paste this file's contents into the
  Keyboard Shortcuts (JSON) editor (`Ctrl+Shift+P` → "Preferences: Open
  Keyboard Shortcuts (JSON)") to apply them manually.
- `vscode/snippets/` — global user snippets, symlinked as a directory into
  every local user scope above, same reasoning as `keybindings.json`.
  Each file uses VS Code's language-scoped naming (`<languageId>.json`,
  e.g. `python.json`, `shellscript.json` — the filename must match the
  language ID exactly or the snippets silently won't trigger). Like
  `keybindings.json`, snippets have no remote/machine scope in VS Code —
  they're classified as a UI Extension resource that always runs on the
  local client, so a remote session uses the connecting client's own
  local snippets automatically; covered already if that client has run
  `install.sh` itself, otherwise nothing to link on the remote host.
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
  one, so this one file is symlinked to several places instead of forking
  the content or using an `@AGENTS.md` import line: `~/.claude/CLAUDE.md`
  for Claude Code, `~/.codex/AGENTS.md` for Codex CLI's own global
  personal-instructions path, and `~/.copilot/copilot-instructions.md`
  for GitHub Copilot CLI (whose global personal instructions also aren't
  named `AGENTS.md`; the VS Code extension's equivalent isn't linked —
  community reports say it doesn't reliably pick up a global file yet).
  Cursor and Gemini CLI read `AGENTS.md` / `GEMINI.md` only per-project
  (repo root and below), not from a global, user-level path, so there's
  nothing global to link for them yet.
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
- Claude Code CLI itself — installed via the official native installer
  (`curl -fsSL https://claude.ai/install.sh | bash`), but only when
  `install.sh` detects it's running inside a Codespace (`$CODESPACES=true`).
  Not installed on other machines by this script — see [Codespaces](#codespaces)
  below for why, and for how to authenticate it without an interactive
  browser login. The installer puts the binary in `~/.local/bin`, so
  `bash/bash_aliases` and `zsh/zshrc` both add that to `PATH`.

## How it applies

Run `./install.sh` (idempotent — safe to re-run) — the one entry point for
every machine this repo targets: a genuine Linux desktop, a WSL distro, an
SSH target, a Dev Container, Codespaces, or native Windows via Git Bash.
It detects native Windows (Git Bash/MSYS/Cygwin, via `uname -s`) first and,
if so, only links the VS Code files into `%APPDATA%\Code\User` before
exiting — a Windows-only machine (e.g. one used purely as an SSH client
into a separate Linux box) has no `$HOME` dev environment here worth
linking, and creating a symlink there needs either an elevated
(Administrator) shell or Developer Mode enabled (Settings → Update &
Security → For developers). This applies whether or not that Windows
machine also uses WSL — the WSL side, run separately inside the distro,
only ever reaches its own Linux `$HOME`, never the Windows Desktop
client's local scope.

On every other machine, it symlinks the files above into `$HOME` (backing
up any pre-existing non-symlink file it would overwrite as
`<file>.bak.<timestamp>`), then attempts to install the VS Code extensions
(see caveat above).

### Codespaces

GitHub Codespaces automatically clones a repo named `dotfiles` under your
account into the container and runs `install.sh` (or `install`,
`bootstrap.sh`, etc.) if present — no manual step needed once this repo is
registered as your dotfiles repo in
[GitHub Settings → Codespaces](https://github.com/settings/codespaces).

This is also what triggers the Codespaces-only install of the Claude Code
CLI (see above). It still needs to authenticate, and the two ways to do
that trade off differently in an ephemeral container:

- **API key (no interactive step)** — register an `ANTHROPIC_API_KEY`
  [account-specific development environment
  secret](https://docs.github.com/en/codespaces/managing-your-codespaces/managing-your-account-specific-secrets-for-github-codespaces)
  scoped to this repo (or "All repositories") at
  [github.com/settings/codespaces](https://github.com/settings/codespaces).
  GitHub injects it as an env var into every Codespace automatically; when
  Claude Code sees it set, it skips the browser OAuth flow entirely. Billing
  is pay-per-token via the Anthropic Console, separate from a Claude
  subscription.
- **Subscription login (interactive, one-time per container)** — leave
  `ANTHROPIC_API_KEY` unset and run `claude` once after connecting to log in
  via a Pro/Max/Team/Enterprise account through the browser-based flow.
  Credentials persist on the container's disk across stop/restart, but a
  rebuilt or freshly-created Codespace needs this repeated.

## Secrets

Nothing sensitive (API keys, tokens, SSH private keys) belongs in this repo —
it's meant to be safe to keep public. The committed git identity here is
just a name/email, which is already public on every commit anyway.
