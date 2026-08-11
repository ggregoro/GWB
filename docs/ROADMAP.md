# GWB Roadmap

## Purpose

This roadmap outlines the planned evolution of Greg's Windows Bootstrap
(GWB), the PowerShell/Windows sibling to
[GLB](https://github.com/ggregoro/GLB).

The roadmap is intended to communicate the long-term direction of the
project rather than serve as a strict schedule. Priorities may change
as the project evolves, and — same as GLB's own roadmap — this file is
expected to track real, verified work, not aspirations.

---

# Version 0.1 — Foundation ✅

Establish the core architecture, mirroring GLB's dispatcher + `lib/`
shape.

### Completed

- Project structure (`gwb.ps1` dispatcher, `lib/`, `profiles/`)
- Git repository, pushed to GitHub
- `lib/log.ps1` (step/ok/info/fail output), `lib/banner.ps1`
- `lib/detect.ps1` — OS version, winget presence, PowerShell version
- Command dispatcher: `help`, `version`, `info`, `install`, `remove`,
  `update`, `restore`, `profiles`
- README, LICENSE (MIT), CHANGELOG, CONTRIBUTING, CODE_OF_CONDUCT,
  `.gitignore`

---

# Version 0.2 — Installation Engine ✅

Develop the core winget-based installation framework.

### Completed

- `lib/packages.ps1`: install/remove a single package, install a
  `packages.txt` list, idempotent "already installed" checks via
  `winget list --id <id> -e`.
- Logical-name → winget-package-ID override table
  (`_GWB_PACKAGE_OVERRIDES`), the PowerShell equivalent of GLB's
  per-distro `_GLB_PACKAGE_OVERRIDES` (e.g. `fd` → `sharkdp.fd`,
  `ripgrep` → `BurntSushi.ripgrep.MSVC`).
- `gwb update` — `winget upgrade --all`.
- Verified for real on Windows 11: individual installs, a full profile
  restore installing 7 real packages, and idempotent re-runs.

### Not applicable (unlike GLB, which supports 4 package managers)

- GWB targets winget only — no Chocolatey/Scoop abstraction layer is
  planned unless a real need for one shows up (e.g. a package winget
  doesn't carry). Revisit only if that happens, same as GLB never
  built a redundant abstraction it didn't need.

---

# Version 0.3 — Profiles

Introduce additional profiles beyond `default`, mirroring GLB's
developer/server split.

### Completed

- `default` — core CLI toolkit: `eza`, `fzf`, `lf`, `ripgrep`, `fd`,
  `bat`, `starship`, plus a `$PROFILE` snippet (eza aliases, `bat` as
  `cat`, fzf options, Starship prompt init).

### Planned

- **`developer`** — GLB's equivalent picked Podman, gcc+make, jq, `gh`,
  htop, mise, Fresh. Windows equivalents need their own pass rather
  than a blind port (e.g. Docker Desktop vs. Podman Desktop, WSL-based
  tooling questions) — not scoped yet.
- **`server`** — GLB's equivalent picked ufw, rsync+restic, fail2ban,
  htop. Windows Server has a very different security/firewall/backup
  model (Windows Firewall, Windows Backup, etc.) — needs its own
  scoping pass, not a direct port.

---

# Version 0.4 — PowerShell Environment Enhancements

GLB's Version 0.4 covered shell frameworks (bash/zsh/fish) and vendored
zsh plugins framework-free. GWB's equivalent gap is PowerShell-native
modules that aren't installed via winget at all.

### Planned

- A `lib/extras.ps1` module (the PowerShell/`Install-Module` analogue of
  GLB's `lib/extras.sh` curl/Flatpak/font methods) for things winget
  doesn't carry:
  - **PSReadLine** — better line editing (usually already present in
    PowerShell 7, but pin/upgrade explicitly).
  - **PSFzf** — wires `fzf` into `Ctrl+R` history search and tab
    completion, the PowerShell equivalent of fzf shell integration.
  - **Terminal-Icons** — file-type icons in `Get-ChildItem`, alongside
    (not a replacement for) the `eza`-based `ll`/`la` aliases already
    in `profile-snippet.ps1`.
- Deliberately **not planned**: managing a terminal emulator (Windows
  Terminal, WezTerm, etc.). `lib/terminal.ps1` exists as an unused stub
  only. GLB tried managing WezTerm, hit enough real trouble (Flatpak
  sandbox permissions, a shadowing config file, hard-to-diagnose
  crashes) that it was removed from GLB's scope entirely — see GLB's
  `docs/PHILOSOPHY.md` ("Enhance the Terminal You Have, Don't Replace
  It"). GWB starts from that same boundary rather than relearning it.

---

# Version 0.5 — User Experience ✅ (core), planned (completions)

Improve the installation experience.

### Completed

- **Dry-run preview (`restore --dry-run`)** — threaded through package
  installs and the `$PROFILE` snippet write; verified to produce zero
  real side effects.
- **Rollback/undo (`restore --undo`)** — restores `$PROFILE` from
  `$PROFILE.gwb-backup`. The backup is written once, on first touch,
  and never overwritten by a later restore — the PowerShell port of a
  real bug GLB hit and fixed (a second profile switch silently
  destroyed the first backup). Verified for real: pre-existing profile
  content survives multiple restores and comes back correctly via
  `--undo`.
- **Interactive profile picker** — `restore` with no profile name lists
  profiles with descriptions and applies whichever one is chosen.

### Planned

- **Shell completions for `gwb` itself** — GLB ships bash/zsh/fish
  completions (`completions/`, `lib/completions.sh`). PowerShell's
  equivalent is a `Register-ArgumentCompleter` block, not yet built.
- **Self-symlink / `PATH` setup** — GLB symlinks `glb` onto `PATH` and
  wires it into the shell's own completion system as part of restore.
  GWB currently has to be run via `.\gwb.ps1` from the repo directory;
  putting it on `PATH` (or as a PowerShell function/alias in the
  managed `$PROFILE` block) isn't built yet.

---

# Version 0.6 — Configuration Management

Improve reproducibility, mirroring GLB's export/diff/repair/manifest
feature set.

### Planned

- **`gwb export`** — snapshot the current machine's explicitly-installed
  winget packages (reverse-mapped through
  `_GWB_PACKAGE_OVERRIDES`) and `$PROFILE` content into a profile-shaped
  directory, the same role GLB's `glb export` plays.
- **`gwb diff <a> <b>`** — compare two profiles/snapshots for package
  and `$PROFILE`-content drift.
- **`gwb repair <profile>`** — ephemeral export + diff against a
  profile, offering to re-run `restore` if drift is found.
- **`gwb restore --from-manifest <path>`** — apply a profile-shaped
  directory from anywhere on disk, without adding it to the repo.

None of this is built yet — GLB's own design docs
(`docs/design/state-export-import.md`, `repair.md`,
`installation-manifests.md` in the GLB repo) are the reference to scope
from when this version is picked up.

---

# Version 1.0 — Stable Release

Deliver the first stable version of GWB.

### Goals

- Stable installation engine (done)
- Profile system beyond `default`
- PowerShell-native "extras" (PSFzf/PSReadLine/Terminal-Icons)
- Shell completions for `gwb` itself
- Configuration management (export/diff/repair)
- Comprehensive documentation

---

# Long-Term Vision

GWB aims to be the same thing for a Windows/PowerShell terminal that GLB
is for a Linux one: a curated, reproducible, one-command setup for a
modern, pleasant command-line environment — built by integrating mature
existing tools (`eza`, `bat`, `fzf`, `ripgrep`, `fd`, `lf`, Starship)
rather than reinventing them, and consciously avoiding the scope creep
(managing terminal emulators, GUI apps) that GLB tried and walked back.

---

# Guiding Philosophy

Inherited directly from GLB:

- User Experience First
- Curate, Don't Reinvent
- Modular by Design
- Profiles Over Package Lists
- Idempotent and Safe to Re-run
- Enhance the Terminal You Have, Don't Replace It

---

> **Note:** This roadmap reflects the current vision of GWB. It is
> intentionally flexible and will continue to evolve as the project
> grows and new ideas emerge.
