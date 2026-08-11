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
├── profiles/               # named profiles: packages.txt, profile-snippet.ps1, description.txt
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
`install`, `remove`, `update`, `restore`, `profiles`). Each branch is a
thin wrapper calling into the relevant `lib/` function — the dispatcher
itself has no business logic beyond argument parsing (e.g. `restore`'s
`--dry-run`/`--undo` flags, parsed from `$Rest` via
`ValueFromRemainingArguments`).

Scripts that end without an explicit `exit` inherit `$LASTEXITCODE` from
whatever native command (e.g. `winget`) last ran internally — `gwb.ps1`
ends with an explicit `exit 0` so a caller's `if ($LASTEXITCODE -eq 0)`
reflects the command's own outcome, not a stray exit code from an
internal `winget list` query several calls back.

## The installer

GLB has a standalone `install.sh` that clones the repo onto a fresh
machine before GLB itself exists there (`curl | bash`). GWB doesn't have
an equivalent yet — for now, getting GWB onto a machine means `git
clone` (see the README's Installation section). A PowerShell
`irm | iex`-style one-liner installer is a plausible future addition
(tracked informally, not yet in `docs/ROADMAP.md`) but hasn't been
scoped.

## Library modules (`lib/`)

| Module | Responsibility |
|---|---|
| `banner.ps1` | `Write-GwbBanner` — the banner shown at the start of every invocation. |
| `log.ps1` | `Write-Step`/`Write-Ok`/`Write-Info`/`Write-Fail` — consistent output; all user-facing messages go through here, not raw `Write-Host` elsewhere. |
| `detect.ps1` | Detects the OS version/name, whether `winget` is available, and the running PowerShell version. |
| `packages.ps1` | Package management: `Install-GwbPackage`/`Remove-GwbPackage`/`Install-GwbPackageList`, logical-name → winget-ID resolution (`_GWB_PACKAGE_OVERRIDES`), idempotent "already installed" checks (`Test-GwbPackageInstalled`, via `winget list --id <id> -e`), and `Update-GwbPackages` (`winget upgrade --all`). |
| `profile.ps1` | Applies a profile: packages, then the `$PROFILE` snippet (backup-on-first-touch + marked-block injection/replacement), the interactive profile picker, and `--undo` rollback. |
| `terminal.ps1` | Opt-in Windows Terminal `settings.json` merge (`Install-GwbWindowsTerminalSettings`). Not wired into any shipped profile — see `docs/ROADMAP.md` Version 0.4 for why this stays a stub rather than being built out. |

Every module is dot-sourced by `gwb.ps1` before the dispatcher's
`switch` block runs, so any module's functions are available to every
command branch.

## Profiles (`profiles/<name>/`)

A profile is a directory containing:

- **`packages.txt`** — one package per line (logical names; winget-ID
  overrides are resolved via `lib/packages.ps1`).
- **`profile-snippet.ps1`** — PowerShell injected into `$PROFILE`
  between `# >>> GWB managed block >>>` / `# <<< GWB managed block <<<`
  markers. The PowerShell/single-file analogue of GLB's `dotfiles/`
  directory (GLB symlinks multiple dotfiles into `$HOME`; GWB has one
  file, `$PROFILE`, to manage instead).
- **`description.txt`** *(optional)* — one line shown by the
  interactive picker.

`gwb restore <profile>` runs, in order: packages → `$PROFILE` snippet →
(optional) Windows Terminal settings, if the profile ships a
`windows-terminal-settings.json` (none do yet). `--dry-run` short-
circuits every actual install/write with a "Would ..." log line;
`--undo` restores `$PROFILE` from `$PROFILE.gwb-backup`, which is
written once on first touch and never overwritten by a later restore —
the PowerShell port of a real bug GLB hit (a second profile switch
silently destroyed the first restore's backup) and fixed by the same
"only back up if no backup already exists" rule applied here from the
start.

## Testing

No automated test suite yet (GLB's equivalent is a `bats` suite under
`tests/`). Every feature so far has instead been verified by actually
running `gwb.ps1` for real on a Windows 11 machine — real installs,
repeated restores to confirm idempotency, and the backup/undo round-trip
exercised against real `$PROFILE` content. See `CHANGELOG.md` and the
commit history for what's been verified this way. A Pester-based suite
(PowerShell's bats equivalent) is a reasonable future addition once the
module surface is large enough to be worth it.
