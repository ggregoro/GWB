# GWB Documentation Changelog

This changelog records milestones in the GWB *project itself* — docs
structure, GitHub/dev-environment setup — distinct from the root
[`CHANGELOG.md`](../CHANGELOG.md), which tracks `gwb`'s actual
feature/code changes. Mirrors GLB's own `docs/DOCS_CHANGELOG.md`.

## [Unreleased]

(none since the `developer` profile build below)

---

## 2026-08-11

### Documentation

- Finished `docs/design/developer-profile.md`: resolved the remaining
  open questions (build toolchain → MinGW/gcc, resource monitor →
  skipped, `mise`/Fresh Windows support → both confirmed real via
  `winget search`) and marked it Decided/Built. Updated
  `docs/ROADMAP.md`'s `developer` bullet from Planned to Completed and
  `CHANGELOG.md` with the actual feature addition.

### Development Environment

- Verified `mise`, Fresh, and MinGW's real winget package IDs directly
  on this machine (`jdx.mise`, `sinelaw.fresh-editor`,
  `BrechtSanders.WinLibs.POSIX.UCRT`) rather than assuming from the
  earlier design doc's placeholders.

---

## 2026-08-10

### Documentation

- Added `docs/design/developer-profile.md` — scoped the real forks in
  porting GLB's `developer` profile to Windows (containers, gcc/MinGW
  vs. MSVC, `mise`'s Windows support, whether a resource monitor is
  needed alongside Task Manager, Fresh's Windows availability).
- Resolved the containers question the same day: no container tooling
  in `developer` at all, since Docker Desktop/Podman Desktop both need
  WSL2 (or Hyper-V) and Greg has a hard "never install WSL2" constraint
  (breaks his VirtualBox VMs).

---

## 2026-08-10

### Documentation

- Created the `docs/` directory structure.
- Added `docs/README.md` (doc index, mirroring GLB's).
- Added `docs/PROJECT.md`, `docs/PHILOSOPHY.md`, `docs/ARCHITECTURE.md`,
  `docs/ROADMAP.md`, `docs/CODING_STANDARDS.md`.
- Added `docs/design/` (feature-scoping docs, currently just a README —
  nothing scoped this way yet).
- Added `docs/DOCS_CHANGELOG.md` (this file) and
  `docs/troubleshooting.md` (real/anticipated gotchas: `PATH` not
  refreshing after install, PowerShell execution-policy and
  downloaded-file-blocking errors, missing Nerd Font glyphs).
- Added `docs/reference/` (tool/config cheat sheets, currently just a
  README — nothing written yet).
- Added root-level `README.md`, `LICENSE` (MIT, matching GLB),
  `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `.gitignore`.
- Added `CLAUDE.md` at the repo root (not under `docs/`, so Claude Code
  auto-loads it at the start of every session, matching GLB).

### Git & GitHub

- Restructured an earlier ad-hoc PowerShell sketch
  (`restore-default.ps1` + `lib/packages.ps1`/`dotfiles.ps1`) into the
  `gwb.ps1` dispatcher + `lib/` architecture.
- Initialized the GWB git repository (previously untracked/uncommitted).
- Created the private `ggregoro/GWB` GitHub repository and pushed the
  initial commit.
- Confirmed the repo is genuinely private (an unauthenticated fetch
  returns 404) before writing `docs/PROJECT.md`'s Release Strategy
  section.

### Development Environment

- Verified the whole build for real on Greg's Windows 11 Pro machine
  (PowerShell 7.6.4, winget present) — the only environment GWB has
  been tested on so far, unlike GLB's many real machines/VMs.
