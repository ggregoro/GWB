# Greg's Windows Bootstrap (GWB)

The PowerShell/Windows sibling to [GLB](https://github.com/ggregoro/GLB) —
same idea, ported from apt/dnf/pacman/zypper + dotfiles to winget +
PowerShell's `$PROFILE`. One command installs a curated set of terminal
tools and wires up your PowerShell profile, instead of doing it by hand
every time a machine gets reimaged.

## Why GWB?

GLB solves this for Linux; GWB solves it for the Windows boxes in the
same rotation — a modern `ls`/`cat` (`eza`, `bat`), fuzzy search (`fzf`),
fast search (`ripgrep`, `fd`), a terminal file manager (`lf`), and a
clean prompt (Starship), applied in one pass as a reusable **profile**: a
package list plus a `$PROFILE` snippet.

## Architecture

GWB mirrors GLB's shape directly: a `gwb.ps1` dispatcher sources focused
modules from `lib/` (`banner`, `log`, `detect`, `packages`, `profile`,
`terminal`) and applies per-profile `packages.txt` + `profile-snippet.ps1`
under `profiles/`. Packages are winget IDs resolved from logical names via
an override table (e.g. `fd` → `sharkdp.fd`); the snippet is injected into
`$PROFILE` between marked `# >>> GWB managed block >>>` / `<<<` lines so a
re-apply replaces it cleanly instead of duplicating it.

## Features

- **winget-based package installs**, with logical-name → package-ID
  overrides handled automatically.
- **`$PROFILE` management** — injects a managed, idempotent block into
  your PowerShell profile; re-running `restore` replaces it in place.
- **Backup on first touch, never clobbered after** — a pre-existing
  `$PROFILE` is backed up to `$PROFILE.gwb-backup` before GWB ever
  touches it, and later restores never overwrite that original backup.
- **Dry-run previews** (`restore --dry-run`) and **rollback** (`restore
  --undo`, restores `$PROFILE` from the backup).
- **Interactive profile picker** — `restore` with no profile name lists
  available profiles with descriptions and lets you choose.

## Installation

```powershell
git clone https://github.com/ggregoro/GWB.git
cd GWB
.\gwb.ps1 restore default
```

Running `restore` with no profile name shows an interactive picker
instead of assuming `default`.

## Usage

```
gwb help                    Show all commands
gwb version                 Show GWB version
gwb info                    Show OS/PowerShell/winget info
gwb install <package>       Install a single package
gwb remove <package>        Remove a package
gwb update                  Upgrade all winget-managed packages
gwb restore [profile]       Apply a profile (packages + $PROFILE)
gwb restore --dry-run       Preview a restore without changing anything
gwb restore --undo          Undo the last restore's $PROFILE changes
gwb profiles                List available profiles
```

## Profiles

| Profile | Installs |
|---|---|
| `default` | `eza`, `fzf`, `lf`, `ripgrep`, `fd`, `bat`, `starship` + a `$PROFILE` snippet (eza aliases, `bat` as `cat`, fzf options, Starship prompt init). |

Only `default` exists so far — `developer`/`server`-style profiles (see
GLB's equivalents) haven't been ported yet.

## Requirements

- Windows 10/11 with PowerShell 7+
- [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
  (`App Installer` from the Microsoft Store)

## Status

Early — v0.1.0. The dispatcher, package installs, and `$PROFILE`
management are built and verified with real restores on a real machine
(including idempotency and the backup/undo round-trip). Not yet ported
from GLB: `export`/`diff`/`repair`, non-winget "extras" installs (GLB's
curl/Flatpak/font equivalent — likely `Install-Module`-based tools like
PSFzf/PSReadLine/Terminal-Icons on Windows), shell completions for `gwb`
itself, and additional profiles.

## Related

- [GLB](https://github.com/ggregoro/GLB) — the Linux original this
  project ports from.
