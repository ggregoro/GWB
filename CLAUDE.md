# CLAUDE.md — GWB (Greg's Windows Bootstrap)

## What this project is

GWB is a PowerShell CLI tool — the Windows sibling to
[GLB](https://github.com/ggregoro/GLB) — that installs a curated set of
terminal tools via winget and wires them into `$PROFILE` in one pass,
mirroring GLB's dispatcher + `lib/` architecture directly rather than
diverging from it.

- Repo: https://github.com/ggregoro/GWB (private)
- License: MIT
- Language: PowerShell 7+

This file lives at the repo root, matching GLB's own `CLAUDE.md` — so
Claude Code auto-loads it at the start of every session in this repo,
same as it does for GLB.

## Why it exists

Greg wanted "whatever could port over" from GLB to a Windows/PowerShell
equivalent for the Windows boxes in his machine rotation — not a
from-scratch design, a direct port of GLB's dispatcher-plus-lib-modules
shape and its `default`-profile-first approach.

## Test environments

- Greg's Windows 11 Pro machine (build 26200), PowerShell 7.6.4, winget
  present. All real verification so far has happened here — GWB hasn't
  been tested on a second machine/VM yet, unlike GLB's many.

## Current state (as of 2026-08-10)

- Commands: `help`, `version`, `info`, `install <pkg>`, `remove <pkg>`,
  `update`, `restore [profile] [--dry-run|--undo]`, `profiles`.
- Modules: `lib/banner.ps1`, `log.ps1`, `detect.ps1`, `packages.ps1`,
  `profile.ps1`, `terminal.ps1` (unused stub — see `docs/PHILOSOPHY.md`)
  — all dot-sourced by `gwb.ps1`.
- `profiles/default/` installs `eza`, `fzf`, `lf`, `ripgrep`, `fd`,
  `bat`, `starship` via winget, plus a `profile-snippet.ps1` injected
  into `$PROFILE` as a managed block (eza aliases, `bat` as `cat`, fzf
  options, Starship prompt init).
- **Verified for real on the Windows 11 machine above**, not just
  parsed: all 7 packages installed via winget and confirmed idempotent
  on rerun; `$PROFILE` managed-block injection confirmed idempotent
  across three consecutive restores (a real bug — `Set-Content` adding
  a trailing blank line on every re-apply — was caught and fixed during
  this same session); backup/`--undo` round-trip confirmed to preserve
  real pre-existing `$PROFILE` content across repeated restores (the
  PowerShell port of a backup-clobbering bug GLB itself hit and fixed);
  the resulting `ll`/`la`/`cat`/Starship-prompt behavior confirmed
  working live after dot-sourcing the real profile.
- Full documentation set added to match GLB's: `README.md`, `LICENSE`
  (MIT), `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
  `.gitignore`, and `docs/ROADMAP.md`/`ARCHITECTURE.md`/
  `CODING_STANDARDS.md`/`PHILOSOPHY.md`/`PROJECT.md`.

## Roadmap / in progress

See `docs/ROADMAP.md` for the full versioned plan. Nothing beyond the
initial `0.1.0` dispatcher/packages/profile build has shipped yet —
`developer`/`server` profiles, PSFzf/PSReadLine/Terminal-Icons-style
extras, `gwb` shell completions, and export/diff/repair are all still
planned, not started.

## Conventions

- PowerShell 7+ only — see `docs/CODING_STANDARDS.md`.
- **Verify for real before calling something done** — parse-check, then
  actually run the command, including running it twice to confirm
  idempotency for anything that touches `$PROFILE` or installed
  packages. This is the same discipline GLB's own `CLAUDE.md` documents
  repeatedly, and it's already caught one real bug in GWB's own first
  session (the `$PROFILE`-growth bug above).
- **End-of-session standing instruction, mirrored from GLB**: commit
  and push outstanding changes — code, docs, and this file — before
  ending a session, and update this file's Working notes with what
  changed and what's still open, so a future session (possibly on a
  different machine) has real continuity rather than having to
  re-derive context.

## Working notes

- **Session (2026-08-10): initial build.** Restructured an earlier
  ad-hoc PowerShell sketch (a single `restore-default.ps1` plus
  `lib/packages.ps1`/`dotfiles.ps1`) into the current dispatcher +
  `lib/` architecture, built out the `default` profile, verified
  everything for real on this machine (see "Current state" above),
  pushed the result to a new private GitHub repo, then added the full
  documentation set (README through `docs/PROJECT.md`) to bring GWB to
  parity with GLB's own docs. Nothing left mid-flight — working tree
  clean, everything pushed to `master` as of this note.
