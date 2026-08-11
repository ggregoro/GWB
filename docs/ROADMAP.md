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
- **`developer`** (2026-08-11) — same foundation as `default` plus
  `git`, `jq`, `gh`, `mise`, Fresh (editor), MinGW/gcc (build
  toolchain). **No container tooling** — Docker Desktop/Podman Desktop
  both need WSL2 (or Hyper-V), a hard "never install" constraint on
  Greg's machines (breaks VirtualBox). No resource monitor either —
  Task Manager already covers it. See
  [`docs/design/developer-profile.md`](design/developer-profile.md)
  for the full scoping and real-machine verification, including a real
  `mise activate`/`Invoke-Expression` array-binding bug caught and
  fixed.
- **`server`** (2026-08-11) — same foundation as `default` plus
  `restic` (backups). No firewall tool (Windows Firewall already
  covers it), no fail2ban equivalent (IPBan is the real one, but has no
  winget package — documented gap, revisit once `lib/extras.ps1` exists
  for real reasons), no resource monitor. See
  [`docs/design/server-profile.md`](design/server-profile.md) for the
  full scoping and real-machine verification.

### Planned

(none — both planned profiles for this version are now built; a
`Minimal`/`Custom` profile concept was considered and dropped by GLB
for the same reason it would be here — no concrete scope behind it)

---

# Version 0.4 — PowerShell Environment Enhancements ✅

GLB's Version 0.4 covered shell frameworks (bash/zsh/fish) and vendored
zsh plugins framework-free. GWB's equivalent gap was PowerShell-native
modules that aren't installed via winget at all.

### Completed

- **`lib/modules.ps1`** (2026-08-11) — the PowerShell/`Install-Module`
  analogue of GLB's `lib/extras.sh`, scoped to a flat `modules.txt`
  (one module per line, mirroring `packages.txt`) since every extra
  right now is the same method. Installed in all three profiles:
  - **PSFzf** — wires `fzf` into `Ctrl+R`/`Ctrl+F` history search and
    provider completion.
  - **Terminal-Icons** — file-type icons in `Get-ChildItem`, alongside
    (not a replacement for) the `eza`-based `ll`/`la` aliases.
  - **PSReadLine** — already ships with PowerShell 7, so no install
    step; configured directly in `profile-snippet.ps1` (predictive
    IntelliSense) instead.

  See [`docs/design/psgallery-extras.md`](design/psgallery-extras.md)
  for the full scoping and real-machine verification, including a real
  bug caught and fixed (`-ErrorAction SilentlyContinue` didn't actually
  suppress a PSReadLine console message the way `try`/`catch` does).

### Deliberately not planned

- Managing a terminal emulator (Windows
  Terminal, WezTerm, etc.). `lib/terminal.ps1` exists as an unused stub
  only. GLB tried managing WezTerm, hit enough real trouble (Flatpak
  sandbox permissions, a shadowing config file, hard-to-diagnose
  crashes) that it was removed from GLB's scope entirely — see GLB's
  `docs/PHILOSOPHY.md` ("Enhance the Terminal You Have, Don't Replace
  It"). GWB starts from that same boundary rather than relearning it.

---

# Version 0.5 — User Experience ✅

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
- **Shell completions + a `gwb` command (2026-08-11)** — GLB symlinks
  `glb` onto `PATH` and installs bash/zsh/fish completions as part of
  every restore. A `.ps1` script isn't callable by bare name on
  Windows, so the PowerShell-idiomatic equivalent is a wrapper
  `function gwb { & '<path>\gwb.ps1' @args }` plus a
  `Register-ArgumentCompleter` block, both installed into `$PROFILE`
  automatically on every restore (matching GLB's own precedent).
  Commands, profile/snapshot names, and package names all tab-complete
  correctly, verified for real. See
  [`docs/design/shell-completions.md`](design/shell-completions.md).

### Planned

(none — Version 0.5 is now fully complete)

---

# Version 0.6 — Configuration Management

Improve reproducibility, mirroring GLB's export/diff/repair/manifest
feature set.

### Completed

- **`gwb export`** (2026-08-11) — snapshots the machine's installed
  subset of every profile's *known* packages (not a full inventory —
  winget has no manual-vs-dependency tracking at all, a harder gap than
  any GLB package manager faced) plus the current `$PROFILE`'s
  GWB-managed block, into `snapshots/<hostname>-<date>/`.
- **`gwb diff <a> <b>`** (2026-08-11) — compares two profiles/snapshots
  for package, module, and `profile-snippet.ps1` drift, exit 0/1
  matching `diff`'s convention. Module tracking (`modules.txt`) was
  added the same day as a follow-up once `lib/modules.ps1` existed —
  the same flat-list scan/diff logic, generalized to a second file, no
  new mechanism needed.
- **`gwb repair <profile>`** (2026-08-11) — ephemeral export + diff
  against a profile, offers to re-run `restore` if drift is found.
- **`gwb restore --from-snapshot <name>`** (2026-08-11) — applies a
  snapshot by reusing `Invoke-GwbApplyProfile` directly.
- **`gwb restore --from-manifest <path>`** (2026-08-11) — applies a
  profile-shaped directory from anywhere on disk. Turned out to need no
  new logic at all — `Invoke-GwbApplyProfile` already accepted an
  arbitrary path, the same trick `--from-snapshot` already used. See
  [`docs/design/from-manifest.md`](design/from-manifest.md).

See [`docs/design/export-diff-repair.md`](design/export-diff-repair.md)
for the full scoping and real-machine verification, including two real
bugs caught and fixed (a mixed-line-endings false-positive diff, and
`Read-Host` crashing instead of failing gracefully with no input).

### Planned

(none — Version 0.6 is now fully complete)

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
