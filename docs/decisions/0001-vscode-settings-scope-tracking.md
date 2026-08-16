# 0001: What VS Code settings this repo tracks, and how machines find them

## Status

Accepted

## Context

This repo's VS Code files need to work across several machine shapes: a
genuine Linux desktop, a WSL distro, an SSH target, a Dev Container,
Codespaces, and a native Windows machine running VS Code Desktop (whether
or not that machine also has WSL). VS Code has two settings scopes that
matter here:

- **Local user scope** — `settings.json`/`keybindings.json`/`snippets`
  under `~/.config/Code/User` (Linux) or `%APPDATA%\Code\User` (Windows).
  Always in effect, on whichever machine is running the VS Code client.
- **Remote "[WSL/SSH/...]" machine scope** — a `settings.json` under
  `~/.vscode-server/data/Machine` on the *remote* side of a connection.
  VS Code layers this on top of local user scope only while connected to
  that specific machine, overriding it for the duration of the session.

## Decision

- Track only the local user scope (`vscode/settings.json`,
  `vscode/keybindings.json`, `vscode/snippets`) in this repo.
- `install.sh` is the single entry point for every machine shape above,
  including native Windows: it detects native Windows (Git Bash/MSYS/
  Cygwin, via `uname -s`) up front and branches to a VS-Code-only flow —
  link the three local-scope files into `%APPDATA%\Code\User` (path
  resolved via `cygpath`) — before the rest of the script, which assumes
  a genuine Linux `$HOME`, ever runs.
- Never track or touch the remote machine scope
  (`~/.vscode-server/data/Machine/settings.json`). VS Code creates and
  persists that file itself the moment any setting is set through its own
  Remote Settings UI (`Ctrl+Shift+P` → "Preferences: Open Remote Settings
  (JSON)") — confirmed on the machine this decision was made on, where
  that file already held real content (a terminal shell profile override)
  before this repo ever touched it. Its whole purpose is to hold overrides
  specific to *one* box, which by definition isn't shared, tracked content.

## Alternatives considered

1. **One `settings.json` symlinked to all three targets** (local scope +
   WSL machine scope + Windows local scope), with a manually-appended
   "never commit this line" block at the bottom for per-machine overrides.
   Rejected: VS Code layers remote machine scope *on top of* local scope,
   not as a peer of it, so forcing them into the same file — and therefore
   identical content — didn't match how VS Code actually resolves
   settings.
2. **WSL reaching into Windows over `/mnt/c`** (via `cmd.exe`/`wslpath`
   interop) to link the Windows-native local scope from inside a WSL
   `install.sh` run. Worked, but ties the Windows-side symlink's
   resolution to the WSL distro being bootable (it resolves through
   `\\wsl.localhost\<distro>\...`), and does nothing for a Windows machine
   used purely as an SSH client with no WSL at all. Reverted.
3. **`vscode/settings.machine.json`** — a tracked file for the remote
   machine scope, split into a "shared" section (committed) for
   hypothetical common remote-only settings and a "never commit" section
   for genuinely per-box ones. Rejected: in practice its content was 100%
   per-box, and VS Code already owns that file's lifecycle itself (see
   Decision above) — tracking it added a symlink and a speculative shared
   section this repo never actually needed.
4. **`install-windows.sh`** as a second entry point for native Windows.
   Worked, but two scripts to remember and run was more than needed;
   merged into `install.sh` as an early platform branch instead.

## Consequences

- `./install.sh` is the one command to run on any machine, Windows
  included (from Git Bash).
- A machine-specific VS Code Remote setting (e.g. a terminal shell profile
  default that only makes sense where that shell is installed) must be set
  by hand through VS Code's own Remote Settings UI on that machine — this
  repo has no visibility into it and never will.
- macOS's local user scope path
  (`~/Library/Application Support/Code/User`) still isn't handled.
