# Design: PSFzf / PSReadLine / Terminal-Icons

**Status:** Decided and built (2026-08-11). Verified for real, including
one real bug caught and fixed — see "Verification" below.

## Purpose

`docs/ROADMAP.md` Version 0.4 flagged the PowerShell/`Install-Module`
analogue of GLB's `lib/extras.sh` (curl/Flatpak/font methods for
things a package manager doesn't carry): PSReadLine, PSFzf, and
Terminal-Icons, none of which are winget packages.

## Real technical risk, verified before building

`Install-Module` pulls from PSGallery, whose `InstallationPolicy` is
`Untrusted` by default — confirmed directly (`Get-PSRepository -Name
PSGallery`), even on a machine that's used `Install-Module` before.
Left unhandled, this is the PSGallery equivalent of the
`winget --accept-source-agreements` issue: a real risk of hanging on an
interactive confirmation prompt during an unattended restore. Verified
directly that `-Force` fully suppresses it (a real install of PSFzf
completed cleanly with no prompt) — no need to separately call `Set-
PSRepository -InstallationPolicy Trusted` first.

## Decided directly with Greg

1. **Scope**: all three profiles (`default`/`developer`/`server`) get
   PSFzf + Terminal-Icons + PSReadLine configuration — these are
   lightweight quality-of-life enhancements, not profile-specific
   tooling like `mise`/MinGW were.
2. **PSReadLine**: config only, no install step. Confirmed directly
   (`Get-Module -ListAvailable -Name PSReadLine`) that it already ships
   with PowerShell 7 on this machine (two versions present). Rather
   than list it in `modules.txt` as something to "install" (always a
   no-op), it's configured directly in `profile-snippet.ps1` — the same
   "activate, don't just install" treatment Starship/`mise` already
   get there.
3. **Manifest shape**: a flat `modules.txt`, one module name per line,
   mirroring `packages.txt` exactly. Every extra GWB has right now is
   the same method (`Install-Module`) — GLB's multi-method `extras.txt`
   format isn't needed yet; add it only if a second real method comes
   up (YAGNI, matching the project's own coding standards).

## Design

- **`lib/modules.ps1`** (new): `Install-GwbModule`/`Install-
  GwbModuleList`/`Test-GwbModuleInstalled`, structurally identical to
  `lib/packages.ps1` but wrapping `Install-Module -Scope CurrentUser
  -Force` instead of `winget install`.
- **`profiles/*/modules.txt`**: `PSFzf`, `Terminal-Icons` in all three
  profiles.
- **`Invoke-GwbApplyProfile`** (`lib/profile.ps1`): a new step between
  packages and the `$PROFILE` snippet, conditional on `modules.txt`
  existing (so snapshots/manifests without one don't error — same
  pattern as the optional Windows Terminal settings step).
- **`profile-snippet.ps1`** (all three profiles, identical addition):
  `Import-Module PSFzf` + `Set-PsFzfOption -PSReadlineChordProvider
  'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'` (both parameter
  names confirmed real via `(Get-Command Set-PsFzfOption).Parameters`,
  not guessed); `Import-Module Terminal-Icons`; and the PSReadLine
  `Set-PSReadLineOption -PredictionSource History -PredictionViewStyle
  ListView` block (see the real bug below for why it's wrapped in
  `try`/`catch`).

## Follow-up: closed (2026-08-11)

`export`/`diff`/`repair` originally only tracked packages known to some
profile's `packages.txt`, not `modules.txt` — flagged here as a real,
noted gap rather than bundled into this round to avoid scope creep.
Closed the same day: see the "Update" section in
[`docs/design/export-diff-repair.md`](export-diff-repair.md) for the
full writeup (generalized the existing package-scanning/diffing
helpers to also cover `modules.txt`, no new mechanism needed; `gwb
repair` needed zero changes since it already reuses those functions
directly).

## Verification

Built and verified for real on a real Windows 11 machine: `Install-
Module -Force` for PSFzf and Terminal-Icons both completed cleanly with
no prompt; a real `restore server` installed both modules and the
`modules.txt` step correctly reports "already installed" on rerun;
idempotent across two consecutive real restores (stable `$PROFILE`
length); dot-sourcing the live `$PROFILE` loads both modules and
confirms `Set-PsFzfOption`'s exact parameters are real, not guessed.

**One real bug found and fixed, not caught by parsing or the first
pass of verification**: the first version of the PSReadLine config used
`-ErrorAction SilentlyContinue`, on the assumption that would silence
the "predictive suggestion feature cannot be enabled" message this
harness's non-VT-capable console produces. It didn't — dot-sourcing the
real `$PROFILE` still printed the full red error text, confirmed
directly. `-ErrorAction Stop` wrapped in `try`/`catch` was tested
side-by-side and confirmed to suppress it completely; the shipped
`profile-snippet.ps1` uses that instead. A reminder that `-ErrorAction
SilentlyContinue` doesn't reliably suppress every message a cmdlet can
produce — worth checking for real rather than assuming it's equivalent
to `try`/`catch`.
