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

GWB enhances the terminal you already have — it doesn't install or
replace it. See [`docs/PHILOSOPHY.md`](docs/PHILOSOPHY.md) for why.

## Architecture

GWB mirrors GLB's shape directly: a `gwb.ps1` dispatcher sources focused
modules from `lib/` (`banner`, `log`, `detect`, `packages`, `profile`,
`terminal`) and applies per-profile `packages.txt` + `profile-snippet.ps1`
under `profiles/`. Packages are winget IDs resolved from logical names via
an override table (e.g. `fd` → `sharkdp.fd`); the snippet is injected into
`$PROFILE` between marked `# >>> GWB managed block >>>` / `<<<` lines so a
re-apply replaces it cleanly instead of duplicating it. See
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for the full module
breakdown.

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
- **State export/diff/repair** — `gwb export` snapshots the machine's
  installed subset of known packages plus the current `$PROFILE` block;
  `gwb diff <a> <b>` compares two profiles/snapshots for drift; `gwb
  repair <profile>` checks the machine against a profile and offers to
  fix it; `gwb restore --from-snapshot <name>` reapplies a snapshot.

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
gwb restore --from-snapshot <name>  Apply a snapshot captured by 'gwb export'
gwb profiles                List available profiles
gwb export                  Snapshot this machine's known packages + $PROFILE
gwb diff <a> <b>            Compare two profiles/snapshots for drift
gwb repair <profile>        Check this machine against a profile
```

## Profiles

| Profile | Installs |
|---|---|
| `default` | `eza`, `fzf`, `lf`, `ripgrep`, `fd`, `bat`, `starship` + a `$PROFILE` snippet (eza aliases, `bat` as `cat`, fzf options, Starship prompt init). |
| `developer` | `default`'s foundation + `git`, `jq`, `gh`, `mise`, Fresh (editor), MinGW/gcc (build toolchain), Far Manager (file manager). No container tooling — see [`docs/design/developer-profile.md`](docs/design/developer-profile.md). |
| `server` | `default`'s foundation + `restic` (backups), Far Manager (file manager). No firewall/fail2ban/resource-monitor tooling — see [`docs/design/server-profile.md`](docs/design/server-profile.md). |

## Requirements

- Windows 10/11 with PowerShell 7+
- [winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
  (`App Installer` from the Microsoft Store)

## Status

Early — v0.1.0. The dispatcher, package installs, `$PROFILE`
management, all three profiles (`default`/`developer`/`server`), and
`export`/`diff`/`repair`/`restore --from-snapshot` are all built and
verified with real restores on a real machine (including idempotency,
the backup/undo round-trip, and real drift detection). Not yet ported
from GLB: `restore --from-manifest`, non-winget "extras" installs
(GLB's curl/Flatpak/font equivalent — likely `Install-Module`-based
tools like PSFzf/PSReadLine/Terminal-Icons on Windows, plus IPBan for
`server` once this exists), and shell completions for `gwb` itself.

## Project

Vision, target audience, goals, non-goals, and release strategy are
tracked in [`docs/PROJECT.md`](docs/PROJECT.md).

## Roadmap

GWB's direction and current progress are tracked in
[`docs/ROADMAP.md`](docs/ROADMAP.md).

## Contributing

GWB is currently a personal project (private repository) built and
tested by its author on a real Windows 11 machine, documented in detail
in [`CLAUDE.md`](CLAUDE.md). See [`CONTRIBUTING.md`](CONTRIBUTING.md)
for conventions and [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md).

## Related

- [GLB](https://github.com/ggregoro/GLB) — the Linux original this
  project ports from.

## License

MIT — see [`LICENSE`](LICENSE).
