# GWB Architecture

## Overview

GWB is a single `gwb.ps1` dispatcher script that dot-sources a set of
focused library modules from `lib/`, each responsible for one concern —
the same shape as [GLB](https://github.com/ggregoro/GLB)'s `glb`
dispatcher + `lib/*.sh`, ported to PowerShell. There is no build step or
compiled binary; `gwb.ps1` is run directly from the repo checkout.

```
GWB/
├── gwb.ps1                # dispatcher: parses the command, dot-sources lib/*.ps1, dispatches
├── VERSION                # current GWB version
├── lib/                   # library modules (see below)
├── profiles/               # named profiles: packages.txt, modules.txt,
│                           #   profile-snippet.ps1, description.txt
├── snapshots/               # gwb export output (machine-state snapshots), when present
├── tests/                   # Pester test suite (see Testing below)
├── docs/                   # this documentation, including docs/design/ for
│                           #   feature design docs and docs/reference/ for
│                           #   cheat sheets
├── CLAUDE.md               # session-continuity notes, auto-loaded by Claude Code
└── README.md, LICENSE, CHANGELOG.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md
```

## The dispatcher (`gwb.ps1`)

`gwb.ps1` resolves its own directory (`$PSScriptRoot`, PowerShell's
built-in equivalent of GLB's `readlink -f "${BASH_SOURCE[0]}"`
resolution), reads `VERSION`, dot-sources every `lib/*.ps1` module, then
dispatches on the first positional argument (`help`, `version`, `info`,
`install`, `remove`, `update`, `restore`, `profiles`, `export`, `diff`,
`repair`). Each branch is a thin wrapper calling into the relevant
`lib/` function — the dispatcher itself has no business logic beyond
argument parsing (e.g. `restore`'s `--dry-run`/`--undo`/`--from-
snapshot <name>`/`--from-manifest <path>` flags, parsed from `$Rest`
via `ValueFromRemainingArguments`).

Scripts that end without an explicit `exit` inherit `$LASTEXITCODE` from
whatever native command (e.g. `winget`) last ran internally — `gwb.ps1`
ends with an explicit `exit 0` so a caller's `if ($LASTEXITCODE -eq 0)`
reflects the command's own outcome, not a stray exit code from an
internal `winget list` query several calls back.

## The installer (`install.ps1`)

A standalone bootstrap script, independent of everything above — it
runs *before* GWB exists on a machine, so it can't dot-source `lib/` or
depend on `$GwbRoot`. `irm <url>/install.ps1 | iex` clones the repo into
`$env:LOCALAPPDATA\GWB` (or `git pull`s it if already there), then
prints the next command to run. It deliberately does not invoke
`gwb restore` itself — that's a separate, interactive, opinionated step
(package installs, `$PROFILE` changes), not something that should
happen as a side effect of "get GWB onto my machine." Requires the
source repo to be publicly reachable, since a fresh machine has no
GitHub credentials to clone a private one — this is why the installer
wasn't built until after the repo went public (see
[`docs/PROJECT.md`](PROJECT.md)'s Release Strategy).

Two real platform differences from GLB's `install.sh`, both driven by
`irm | iex` having no subshell isolation the way `curl | bash` does —
see [`docs/design/installer.md`](design/installer.md) for the full
reasoning: the entire script body is wrapped in `& { ... }` so its
variables don't leak into the caller's interactive session, and it
never calls `exit` (which would close the whole PowerShell window under
`iex`, not just the script) — error paths use non-terminating
`Write-Error` plus an explicit `return` instead.

## Library modules (`lib/`)

| Module | Responsibility |
|---|---|
| `banner.ps1` | `Write-GwbBanner` — the banner shown at the start of every invocation. |
| `log.ps1` | `Write-Step`/`Write-Ok`/`Write-Info`/`Write-Fail` — consistent output; all user-facing messages go through here, not raw `Write-Host` elsewhere. |
| `detect.ps1` | Detects the OS version/name, whether `winget` is available, and the running PowerShell version. |
| `packages.ps1` | Package management: `Install-GwbPackage`/`Remove-GwbPackage`/`Install-GwbPackageList`, logical-name → winget-ID resolution (`_GWB_PACKAGE_OVERRIDES`), idempotent "already installed" checks (`Test-GwbPackageInstalled`, via `winget list --id <id> -e`), and `Update-GwbPackages` (`winget upgrade --all`). |
| `modules.ps1` | PowerShell Gallery module installs (`Install-GwbModule`/`Install-GwbModuleList`), the `Install-Module`-based analogue of `packages.ps1` for things winget doesn't carry (PSFzf, Terminal-Icons). `-Force` suppresses PSGallery's untrusted-repository prompt. |
| `profile.ps1` | Applies a profile: packages, modules, then the `$PROFILE` snippet and self-registration block (both via the shared `Set-GwbManagedBlock` helper — backup-on-first-touch + marked-block injection/replacement), Starship's `~/.config/starship.toml` (`Install-GwbStarshipConfig` — fills in `scan_timeout` if absent, never overwrites an existing value), the interactive profile picker, and `--undo` rollback. |
| `completions.ps1` | Puts `gwb` on the command line — a wrapper function in `$PROFILE` (`.ps1` scripts aren't callable by bare name on Windows) — plus `Register-ArgumentCompleter` for commands, profile/snapshot names, and package names, all read live from disk. Installed automatically on every restore via its own managed block, separate from the profile-snippet block. |
| `terminal.ps1` | Opt-in Windows Terminal `settings.json` merge (`Install-GwbWindowsTerminalSettings`). Not wired into any shipped profile — see `docs/ROADMAP.md` Version 0.4 for why this stays a stub rather than being built out. |
| `export.ps1` | `Export-GwbSnapshot` captures the installed subset of every profile's *known* packages and modules (winget has no manual-vs-dependency tracking, so tracking is scoped to what some profile already lists) plus the current `$PROFILE`'s GWB-managed block, into `snapshots/<hostname>-<date>/`. |
| `diff.ps1` | `Invoke-GwbDiff` compares two profile-shaped directories (a profile, a snapshot, or either against the other) for package, module, and `profile-snippet.ps1` drift, exit 0/1 matching `diff`'s own convention. |
| `repair.ps1` | `Invoke-GwbRepair` does an ephemeral export + diff against a profile (nothing saved to disk), offering to re-run `restore` if drift is found. |

Every module is dot-sourced by `gwb.ps1` before the dispatcher's
`switch` block runs, so any module's functions are available to every
command branch.

## Profiles (`profiles/<name>/`)

A profile is a directory containing:

- **`packages.txt`** — one package per line (logical names; winget-ID
  overrides are resolved via `lib/packages.ps1`).
- **`modules.txt`** *(optional)* — one PowerShell Gallery module name
  per line, installed via `lib/modules.ps1`. Mirrors `packages.txt`
  exactly; not every profile-shaped directory has one (snapshots and
  manifests don't).
- **`profile-snippet.ps1`** — PowerShell injected into `$PROFILE`
  between `# >>> GWB managed block >>>` / `# <<< GWB managed block <<<`
  markers. The PowerShell/single-file analogue of GLB's `dotfiles/`
  directory (GLB symlinks multiple dotfiles into `$HOME`; GWB has one
  file, `$PROFILE`, to manage instead).
- **`description.txt`** *(optional)* — one line shown by the
  interactive picker.

`gwb restore <profile>` runs, in order: packages → modules (if
`modules.txt` exists) → `$PROFILE` snippet → `gwb` self-registration
(command + tab-completion, its own separate managed block) →
(optional) Windows Terminal settings, if the profile ships a
`windows-terminal-settings.json` (none do yet). `--dry-run` short-
circuits every actual install/write with a "Would ..." log line;
`--undo` restores `$PROFILE` from `$PROFILE.gwb-backup`, which is
written once on first touch (by whichever managed block is first to
need it) and never overwritten by a later restore — the PowerShell
port of a real bug GLB hit (a second profile switch silently destroyed
the first restore's backup) and fixed by the same "only back up if no
backup already exists" rule applied here from the start.

`--from-snapshot <name>` and `--from-manifest <path>` both reuse
`Invoke-GwbApplyProfile` directly rather than duplicating it — the
function was always written to accept an arbitrary directory, not just
one under `profiles/`.

## Testing

A [Pester](https://pester.dev/) suite under `tests/`, GWB's analogue of
GLB's `bats` suite — one file roughly per `lib/` module
(`Packages`/`Modules`/`Profile`/`Diff`/`Export`/`Repair`/`Detect`) plus
`Dispatcher.Tests.ps1` for real end-to-end command coverage (dot-sources
the actual `gwb.ps1` with real arguments — `Mock`/`$PROFILE` overrides
both stay active across the dot-source, and `gwb.ps1`'s own `exit 0`
doesn't kill the test process, confirmed directly). `tests/TestHelpers.ps1`
provides shared setup, mirroring `test_helper.bash`. `winget`/
`Install-Module` calls are mocked via Pester's `Mock` (a proxy-function
model, not GLB's `PATH`-shadowing); `$PROFILE` is safely overridden to a
temp path per test. Run with:

```powershell
Import-Module Pester -MinimumVersion 5.0
Invoke-Pester -Path tests/
```

See [`docs/design/pester-test-suite.md`](design/pester-test-suite.md)
for the real technical questions verified before building this (which
Pester version, whether `Mock` can intercept an external `.exe`, whether
dispatcher-level dot-sourcing actually works) and a real bug the suite
caught on its first run (a `Mandatory` PowerShell array parameter
silently rejecting a legitimate empty array). Every feature before this
suite existed was verified by actually running `gwb.ps1` for real on a
Windows 11 machine — that real-machine verification discipline continues
alongside the test suite, not instead of it; see `CHANGELOG.md` and the
commit history.
