# GWB Project

## Project Vision

Make the Windows terminal the easiest, most approachable part of using
Windows for command-line work — not a blank blue window with no hints,
no color, and no context. GWB gets there by configuring a curated
prompt and set of CLI tools with a single command, instead of manually
reinstalling the same packages and rewriting the same `$PROFILE` every
time a machine gets reimaged or a new one gets set up. Same mission as
[GLB](https://github.com/ggregoro/GLB), ported to Windows.

## Mission

Build the PowerShell terminal experience Greg would want on every
Windows machine he touches, and make it reproducible enough to run
again on any Windows 10/11 box with confidence it produces the same
result.

## Core Principles

- **User experience first.** Clear defaults beat a wall of configuration
  options.
- **Curate, don't reinvent.** GWB integrates mature open-source projects
  (Starship, eza, bat, fzf, ripgrep, fd, lf) rather than duplicating
  their functionality.
- **Profiles over package lists.** Users choose a complete terminal
  experience (`default`, and eventually `developer`/`server`), not an
  à la carte list of packages.
- **Modular by design.** Each concern — package installation, `$PROFILE`
  management, detection — lives in its own focused `lib/` module.
- **Consistent with GLB.** Where the two projects solve the same
  problem, GWB should feel like GLB's sibling, not a different tool:
  same command names, same profile shape, same idempotent/safe-to-rerun
  behavior.
- **Opinionated but customizable.** GWB ships a real, working `default`
  profile — not a placeholder — while leaving room to fork or edit a
  profile for anyone who wants something different.

See [`PHILOSOPHY.md`](PHILOSOPHY.md) for the full guiding philosophy
behind these principles.

## Target Audience

- **Greg**, first and foremost — GWB exists because the Windows
  machines in his rotation needed the same one-command terminal setup
  GLB already gives his Linux machines.
- **People newer to PowerShell** who want a solid, curated starting
  point (modern `ls`/`cat`, fuzzy search, a real prompt) without
  researching every tool choice themselves.
- **Anyone for whom PowerShell itself is unfamiliar** — the default
  prompt gives no hints at all; GWB's shared `$PROFILE` setup is built
  to fix that regardless of which profile someone picks, the same way
  GLB's shared shell setup does on Linux.
- Potentially a **wider audience** later, if there's interest — built
  with reasonably clean, documented code in mind for that possibility,
  same stance GLB takes.

## Supported Platforms

GWB targets Windows 10/11 with PowerShell 7+ and
[winget](https://learn.microsoft.com/en-us/windows/package-manager/winget/)
available. Unlike GLB (four package managers across many distros), GWB
has exactly one target package manager — winget is effectively
universal on modern Windows, so there's no per-machine package-manager
detection/abstraction layer to build.

## Project Goals

- A single command (`gwb restore <profile>`) that reliably reproduces a
  complete terminal setup — packages and `$PROFILE` — on any Windows
  10/11 machine with winget.
- Idempotent, safe-to-rerun behavior: restoring the same profile twice
  should always converge to a clean state, never duplicate work or
  clobber user changes without a backup.
- A path from "something's wrong" back to a known-good state: dry-run
  previews (done) and rollback/undo (done) now; drift detection and
  one-shot repair (GLB's `diff`/`repair`) are planned, see
  `docs/ROADMAP.md`.
- Real-world verification, not just "the code looks right" — every
  feature shipped so far has been run for real on Greg's own Windows 11
  machine (real installs, repeated restores to confirm idempotency, a
  real backup/undo round-trip) before being considered done.

## Non-Goals

- **Not a general-purpose configuration management system.** Same
  boundary GLB draws — no templating, no encrypted secrets, no plugin
  ecosystem.
- **Not a dependency on other languages.** Core functionality stays
  PowerShell-only; no Python/Node/etc. runtime requirement for `gwb.ps1`
  itself.
- **Not a fork or replacement of the tools it curates.** GWB brings
  together existing, mature open-source projects rather than
  reimplementing what they already do well.
- **Not a GUI application or terminal-emulator installer.** GWB installs
  and configures things that run inside whatever terminal is already
  there. It does not install Windows Terminal, browsers, editors with
  their own window, or any other application with a window of its own.
  See `PHILOSOPHY.md` ("Enhance the Terminal You Have, Don't Replace
  It") — this is inherited directly from a real lesson GLB learned
  (a WezTerm-management detour it built and then reversed), not
  something GWB needs to relearn on its own.
- **Not an installer for Administrator-elevated, persistent background
  services.** Every package/module `gwb restore` installs is
  user-scoped and inert until invoked. Something that needs elevation
  *and* runs continuously changing system behavior (the concrete case:
  IPBan, `server`'s fail2ban equivalent, which also carries a real
  account-lockout risk if misconfigured) is a different kind of thing
  than what unattended `gwb restore` should be doing — decided
  directly with Greg (2026-08-11) to keep as a documented manual step
  permanently, not a scope gap to eventually close. See
  `docs/reference/ipban-manual-install.md`.

## Release Strategy

GWB is at `0.1.0` — the initial dispatcher/packages/profile build.
Development happens directly against `master`, with features tracked in
`docs/ROADMAP.md` and itemized as they ship in `CHANGELOG.md`'s
`[Unreleased]` section.

**The repository went public on 2026-08-11**, Greg's own decision once
GWB reached feature parity with GLB's Version 0.1–0.6 equivalents and a
pre-release content audit (commit authorship, secrets/keys, hardcoded
IPs/paths/usernames, tracked `snapshots/` data) came back clean — no
edits were needed before flipping visibility, unlike GLB, which had two
real findings (a hardcoded personal git identity, a leaked home-server
IP) to fix first. Unlike GLB's own "stays private until vetted" stance,
GWB didn't wait for real-hardware verification beyond Greg's single
Windows 11 machine — the bar he applied here was feature completeness
plus a clean audit, not GLB's more cautious multi-machine track record.

## Long-Term Vision

GWB aims to become the Windows/PowerShell counterpart to everything GLB
is on Linux: a curated, opinionated terminal builder that gets a fresh
Windows machine to a polished, personalized command-line environment
through either an express install (`gwb restore <profile>` directly) or
a guided picker (`gwb restore` with no arguments, already built). See
`docs/ROADMAP.md`'s Long-Term Vision section for the fuller statement of
direction.
