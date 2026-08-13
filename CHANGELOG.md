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
- Decided, permanently, not to automate installing IPBan
  (`server`'s fail2ban equivalent): fetched and read the real, current
  install script directly rather than relying on earlier research, and
  confirmed it needs Administrator elevation (a first for anything
  GWB would install), sets up a persistent firewall-blocking Windows
  Service, and carries a real account-lockout risk. Added
  `docs/reference/ipban-manual-install.md` (install/verify/uninstall
  commands, plus the lockout-risk caution) and updated
  `profiles/server/description.txt` to point at it.
- Added a Pester test suite under `tests/` — GWB's analogue of GLB's
  `bats` suite. Installed modern Pester 6.0.1 (only the ancient
  bundled 3.4.0 was present). One file roughly per `lib/` module
  (`Packages`, `Modules`, `Profile`, `Diff`, `Export`, `Repair`,
  `Detect`) plus `Dispatcher.Tests.ps1` for real end-to-end coverage —
  dot-sources the actual `gwb.ps1` with `Mock`/`$PROFILE` overrides
  still active, confirmed directly that `gwb.ps1`'s own `exit 0`
  doesn't kill the Pester process when dot-sourced this way. 81/81
  tests pass, verified together (no cross-file interference) and
  confirmed the real repo/`$PROFILE` stay untouched after a full run.
- Fixed a real bug the new test suite caught on its first run:
  `Write-GwbSetDiff`'s `-SetA`/`-SetB` parameters (`lib/diff.ps1`) were
  `Mandatory` `[string[]]` with no `[AllowEmptyCollection()]` —
  PowerShell rejects an empty array passed to a mandatory array
  parameter as if no value were given at all. Every real profile has
  always had a non-empty `modules.txt`, so this never surfaced
  manually, but any profile-shaped directory without one would crash
  `gwb diff`/`gwb repair` outright. Confirmed the crash and the fix
  both for real (not just in Pester) with a scratch snapshot missing
  `modules.txt`.
- The repository went public. See `docs/PROJECT.md`'s Release Strategy
  for the full record — a pre-release content audit (commit
  authorship, secrets/keys, hardcoded IPs/paths, tracked `snapshots/`
  data) came back clean, so no fixes were needed first, unlike GLB's
  own pre-public cleanup.
- Added `install.ps1`, a curl/`irm`-style one-liner installer
  (`irm https://raw.githubusercontent.com/ggregoro/GWB/master/
  install.ps1 | iex`), mirroring GLB's `install.sh`. Two real platform
  forks, both driven by `irm | iex` running in the caller's live
  session rather than a disposable subshell the way `curl | bash`
  does: the whole script is wrapped in `& { ... }` so its variables
  don't leak into the interactive session, and it never calls `exit`
  (which would close the whole PowerShell window under `iex`) —
  error paths use non-terminating `Write-Error` plus an explicit
  `return` instead. Installs to `$env:LOCALAPPDATA\GWB`, the
  Windows-idiomatic per-user app-data location, rather than a literal
  port of GLB's `~/.local/share/glb`. See
  `docs/design/installer.md` for the full reasoning. Added
  `tests/Install.Tests.ps1` (6 tests: git-not-found, fresh clone,
  update-in-place, refuses to clobber an unrelated directory, failed
  pull/clone reporting cleanly, and the scope-isolation property
  itself). See `docs/design/installer.md` for the full reasoning.
- Verified `install.ps1` for real on Windows hardware, closing the one
  gap left from the cloud session that built it (no `pwsh` there to
  run anything). `Invoke-Pester -Path tests/Install.Tests.ps1`, run for
  the very first time, found a real bug — in the test file, not
  `install.ps1`: `*>&1`/`2>&1` applied directly to an
  `Invoke-Expression` call doesn't capture that call's own
  `Write-Error` output; wrapping the call in its own scriptblock and
  redirecting *that* does. Isolated with a minimal repro before fixing
  all 6 affected assertions. 7/7 pass now, 88/88 across the full suite.
  Then ran the real one-liner twice against the live public repo
  (fresh clone, then confirmed update-in-place instead of re-cloning),
  confirmed the fresh checkout resolves its own paths correctly from
  its new location, and completed the full chain with a real
  `gwb.ps1 restore default` from it. Version 1.0 is now fully complete.
- Fixed a real, user-visible bug found by Greg in a live terminal:
  `ls` showed PowerShell's default table output instead of `eza`'s
  icons, while `ll`/`la` worked fine. PowerShell ships a built-in
  `ls` -> `Get-ChildItem` alias, and alias resolution always wins over
  a same-named function - confirmed directly with a synthetic
  alias/function pair before touching the real code
  (`Get-Command ls -All` showed both registered, but bare `ls` only
  ever invoked the alias's target). `ll`/`la` don't collide with any
  built-in alias, which is why only `ls` was affected. Fixed in all
  three profiles' `profile-snippet.ps1` (`Remove-Item -Path Alias:ls
  -Force` before defining the function). Verified for real: restored
  `default`, dot-sourced the real `$PROFILE`, confirmed `Get-Command ls
  -All` now shows only the function and bare `ls` correctly invokes
  `eza`; confirmed idempotency across two restores.
- Bumped the `VERSION` file from `0.1.0` to `1.0.0`, matching
  `docs/ROADMAP.md`'s Version 1.0 (Stable Release) milestone that had
  already been reached and verified for real - the file itself had
  never been updated alongside it. Updated `docs/PROJECT.md`'s Release
  Strategy and `README.md`'s Status section to match. Verified for
  real: `gwb.ps1 version`/`gwb.ps1 help` now print `v1.0.0` live, full
  Pester suite still 88/88 (`Dispatcher.Tests.ps1` reads the real
  `VERSION` file directly rather than asserting a hardcoded string).
- Added a `far` function to `developer`/`server`'s `profile-snippet.ps1`
  so Far Manager launches with a bare `far` from the terminal, matching
  how every other profile tool works. Real gap found while walking
  through how to launch GWB's add-on programs: unlike its CLI tools
  (which winget shims onto `PATH` automatically, e.g. `fresh`), Far
  Manager installs as a registered GUI app with a Start Menu shortcut
  but no `PATH` entry - confirmed via its registry Uninstall key's
  `InstallLocation`. Verified for real: parse-checked both files, full
  Pester suite still 88/88, restored `developer` for real, dot-sourced
  the live `$PROFILE` in a fresh process and confirmed `Get-Command far
  -All` resolves to the function with the correct path and no leaked
  `$GwbFarExe` variable in scope.
- Added `Install-GwbStarshipConfig` (`lib/profile.ps1`), run by every
  `restore`/`repair`: ensures `~/.config/starship.toml` has
  `scan_timeout = 100` set, raised from Starship's own default of 30ms.
  Real gap Greg hit live: opening PowerShell showed a
  `Scanning current directory timed out` warning on every prompt when
  the shell's starting directory was `C:\Windows\System32` (a large
  system directory), something no shipped profile's Starship setup had
  ever addressed - GWB installs Starship but had never written it a
  config file at all. Idempotent and non-destructive: only fills in
  `scan_timeout` when the setting isn't already present, never
  overwriting a value the user set themselves, matching
  `Set-GwbManagedBlock`'s own "never clobber existing content" rule for
  `$PROFILE`. Verified for real: 5 new Pester tests (create, append to
  an existing config, don't-clobber, `-WhatIf`, starship-not-installed)
  plus a real `gwb.ps1 restore developer` against this machine's actual
  `$PROFILE` - confirmed `~/.config/starship.toml` created with
  `scan_timeout = 100`, and a second restore correctly left it
  untouched (idempotent).
- Added a guarded `Set-Location` at the top of all three profiles'
  `profile-snippet.ps1`: resets the shell to `$env:USERPROFILE` when it
  starts in `C:\Windows\System32`, and only then. Real gap Greg hit
  live, separate from the Starship fix above: his PowerShell taskbar
  icon turned out to be pinned to the MSIX-packaged
  `Microsoft.PowerShell_8wekyb3d8bbwe!App` (not Windows Terminal at
  all - confirmed by decoding the taskbar pin's registry data directly,
  after a `startingDirectory` edit to Windows Terminal's own
  `settings.json` had no effect), launched elevated. Elevated/packaged-
  app launches default their working directory to `System32`
  regardless of any shortcut or Windows Terminal setting - there's no
  shortcut-level fix for this, so the reset lives in `$PROFILE` itself,
  which always runs regardless of how the shell started. Verified for
  real: launched a real `pwsh` process with its working directory
  forced to `System32` (Windows still lands there for a fresh
  `pwsh -Command` invocation, same as the packaged-app/elevation case)
  and confirmed the live `$PROFILE` reset it to `$env:USERPROFILE`;
  launched a second real process starting in
  `C:\Users\ggreg\Projects` and confirmed that one was left alone,
  proving the guard doesn't clobber a deliberate starting directory
  elsewhere.
