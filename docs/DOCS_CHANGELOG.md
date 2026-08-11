# GWB Documentation Changelog

This changelog records milestones in the GWB *project itself* — docs
structure, GitHub/dev-environment setup — distinct from the root
[`CHANGELOG.md`](../CHANGELOG.md), which tracks `gwb`'s actual
feature/code changes. Mirrors GLB's own `docs/DOCS_CHANGELOG.md`.

## [Unreleased]

(none since the initial build below)

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
