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
- Added Far Manager (`farmanager` → `FarManager.FarManager`) to both
  `developer` and `server` — a dual-pane console file manager, the
  closer Midnight Commander analogue alongside `lf`'s existing
  Ranger-equivalent role. Verified installed for real and idempotent
  across both profiles.
- Added `gwb export`, `gwb diff <a> <b>`, `gwb repair <profile>`, and
  `gwb restore --from-snapshot <name>` (new `lib/export.ps1`,
  `lib/diff.ps1`, `lib/repair.ps1`) — scoped to packages known to some
  profile (winget has no manual-vs-dependency tracking at all, unlike
  every GLB-supported package manager) plus the current `$PROFILE`'s
  GWB-managed block. See `docs/design/export-diff-repair.md` for the
  full design and real-machine verification.
- Fixed a real bug: `Set-Content`'s platform-default trailing newline
  (CRLF on Windows) mixing with the LF endings already built into
  `$PROFILE`/snapshot content caused a false-positive `gwb diff`. Fixed
  at both write sites (`lib/profile.ps1`, `lib/export.ps1`) and
  hardened `lib/diff.ps1`'s comparison to normalize line endings.
- Fixed a real bug: `Read-Host` in `Invoke-GwbRestoreInteractive` and
  `Invoke-GwbRepair` crashed with an uncaught exception in a
  non-interactive session instead of failing gracefully. Both now
  treat "no input available" as a clean decline, matching GLB's own
  documented convention for this exact situation.
- Fixed `.gitignore`: it excluded `snapshots/` from an earlier round,
  directly contradicting the (inherited-from-GLB) decision to track
  snapshots in-repo for cross-machine diffing.
- Added `gwb restore --from-manifest <path>` — applies a profile-shaped
  directory from anywhere on disk. No new logic needed:
  `Invoke-GwbApplyProfile` already accepted an arbitrary directory
  path, the same trick `--from-snapshot` already used. Verified for
  real with a scratch manifest directory outside the repo, both
  `--dry-run` and applied for real; a nonexistent path errors cleanly.
  Version 0.6 (Configuration Management) is now fully complete.
- Added a `gwb` command and tab-completion (new `lib/completions.ps1`),
  installed automatically on every restore — the PowerShell-idiomatic
  equivalent of GLB's `PATH` symlink + bash/zsh/fish completions
  (`.ps1` scripts aren't callable by bare name on Windows the same
  way). Refactored `Install-GwbProfileSnippet`'s backup/replace logic
  into a shared `Set-GwbManagedBlock` helper (`lib/profile.ps1`) so
  the new self-registration block and the existing profile-snippet
  block both go through identical, tested logic instead of
  duplicating it. Completes/tab-completes commands, profile/snapshot
  names, and package names, all reading live from disk rather than a
  baked-in list. Verified end-to-end on real hardware, including
  idempotency and real tab-completion results (`TabExpansion2`).
  Version 0.5 (User Experience) is now fully complete.
- Added `lib/modules.ps1` (`Install-Module`-based extras, the
  PowerShell analogue of GLB's `lib/extras.sh`) and `modules.txt`
  (PSFzf, Terminal-Icons) to all three profiles. PSReadLine gets no
  install step (already ships with PowerShell 7) but is configured in
  `profile-snippet.ps1` (predictive IntelliSense) alongside the new
  PSFzf/Terminal-Icons activation. Verified `-Force` suppresses
  PSGallery's untrusted-repository prompt for real before relying on
  it. Verified end-to-end on real hardware: idempotent installs, both
  modules load correctly after dot-sourcing `$PROFILE`.
- Fixed a real bug: the PSReadLine config's `-ErrorAction
  SilentlyContinue` did not actually suppress a console message this
  harness's non-VT-capable console produces — confirmed directly by
  dot-sourcing the real `$PROFILE` and seeing the error text still
  print. `try`/`catch` with `-ErrorAction Stop` was tested side-by-side
  and confirmed to suppress it completely; shipped that instead.
  Version 0.4 (PowerShell Environment Enhancements) is now fully
  complete.
- Extended `gwb export`/`diff`/`repair` to also track `modules.txt`
  drift, closing a gap flagged the same day. Generalized
  `Get-GwbKnownPackageNames` into `Get-GwbKnownNames -FileName`
  (`lib/export.ps1`) and `Get-GwbPackageSet` into `Get-GwbFlatListSet
  -FileName` (`lib/diff.ps1`), used for both `packages.txt` and
  `modules.txt` — no new detection mechanism. `gwb repair` needed zero
  changes, since it already calls both functions directly. Verified
  for real: a synthetic snapshot with `Terminal-Icons` deliberately
  removed correctly reported the drift via `gwb diff`.
