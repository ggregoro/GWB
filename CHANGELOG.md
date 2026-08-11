# GWB Project Changelog

All notable changes to the GWB project will be documented in this file.

This project follows a simple versioning approach:

- Major releases introduce significant new functionality.
- Minor releases add features or enhancements.
- Patch releases fix bugs or documentation.

---

## [Unreleased]

### Added
- Created the GWB project as the PowerShell/Windows sibling to
  [GLB](https://github.com/ggregoro/GLB), mirroring its dispatcher +
  `lib/` modules + `profiles/` architecture.
- Added `gwb.ps1` dispatcher with `help`, `version`, `info`, `install`,
  `remove`, `update`, `restore`, and `profiles` commands.
- Added `lib/packages.ps1`: winget-based install/remove/list, with a
  logical-name → winget-ID override table (e.g. `fd` → `sharkdp.fd`).
- Added `lib/profile.ps1`: applies a profile (packages + `$PROFILE`
  snippet), an interactive profile picker, `restore --dry-run`, and
  `restore --undo` (restores `$PROFILE` from `$PROFILE.gwb-backup`).
  A pre-existing `$PROFILE` is backed up once on first touch and never
  clobbered by a later restore.
- Added `lib/detect.ps1` (OS/PowerShell/winget detection),
  `lib/banner.ps1`, and `lib/terminal.ps1` (an opt-in, not-yet-wired-up
  Windows Terminal `settings.json` merge stub).
- Added the `default` profile: `eza`, `fzf`, `lf`, `ripgrep`, `fd`,
  `bat`, `starship`, plus a `profile-snippet.ps1` injected into
  `$PROFILE` (eza aliases, `bat` as `cat`, fzf options, Starship prompt
  init).
- Verified end-to-end on real hardware: package installs and
  `$PROFILE` block injection are both idempotent across repeated
  restores, and the backup/undo round-trip preserves real pre-existing
  `$PROFILE` content.
- Added `README.md`, `LICENSE` (MIT, matching GLB), and `.gitignore`.
- Added the `developer` profile: same foundation as `default` plus
  `git`, `jq`, `gh`, `mise`, Fresh (editor), and MinGW/gcc (build
  toolchain) — all resolved to real winget packages, added to
  `_GWB_PACKAGE_OVERRIDES` in `lib/packages.ps1`. Deliberately excludes
  container tooling (Docker Desktop/Podman Desktop both require WSL2)
  and a resource monitor (Task Manager already covers it) — see
  `docs/design/developer-profile.md` for the full reasoning.
- Fixed a real bug in both `default` and `developer`'s
  `profile-snippet.ps1`: `Invoke-Expression` can't bind a multi-line
  string array (which `mise activate pwsh` returns), only a single
  string — `starship init powershell`'s line happened to work by
  coincidence of its own output shape. Both now join the array into a
  single newline-joined string before passing it to `Invoke-Expression`.
- Verified end-to-end on real hardware: all 5 new packages install
  cleanly and idempotently via `restore developer`, and `gcc`/`gh`/
  `jq`/`mise` are all confirmed functional afterward.
- Added the `server` profile: same foundation as `default` plus
  `restic` (backups, real native-Windows winget package, no WSL). No
  firewall tool (Windows Firewall already covers it), no fail2ban
  equivalent (IPBan is the real one but has no winget package —
  documented gap), no resource monitor (Task Manager covers it) — see
  `docs/design/server-profile.md` for the full reasoning. Verified
  end-to-end on real hardware: idempotent restore, `restic version`
  confirmed functional.
