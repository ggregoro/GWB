# CLAUDE.md — GWB (Greg's Windows Bootstrap)

## What this project is

GWB is a PowerShell CLI tool — the Windows sibling to
[GLB](https://github.com/ggregoro/GLB) — that installs a curated set of
terminal tools via winget and wires them into `$PROFILE` in one pass,
mirroring GLB's dispatcher + `lib/` architecture directly rather than
diverging from it.

- Repo: https://github.com/ggregoro/GWB (public as of 2026-08-11)
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

## Current state (as of 2026-08-11)

GWB is feature-complete against every GLB Version 0.1–0.6 equivalent,
plus a Pester test suite. See `docs/ROADMAP.md` for the full versioned
breakdown — this section is a snapshot, that file is the source of truth.

- Commands: `help`, `version`, `info`, `install <pkg>`, `remove <pkg>`,
  `update`, `restore [profile] [--dry-run|--undo|--from-snapshot
  <name>|--from-manifest <path>]`, `profiles`, `export`, `diff <a> <b>`,
  `repair <profile>`.
- Modules (`lib/`, all dot-sourced by `gwb.ps1`): `banner.ps1`,
  `log.ps1`, `detect.ps1`, `packages.ps1`, `modules.ps1` (PowerShell
  Gallery/`Install-Module`), `profile.ps1` (includes the shared
  `Set-GwbManagedBlock` helper used by both the profile snippet and the
  `gwb` self-registration block), `completions.ps1` (the `gwb` function
  + tab-completion), `terminal.ps1` (unused stub — see
  `docs/PHILOSOPHY.md`), `export.ps1`, `diff.ps1`, `repair.ps1`.
- Three profiles: `default`, `developer`, `server` — each with
  `packages.txt`, `modules.txt`, `profile-snippet.ps1`,
  `description.txt`. Real per-profile decisions (WSL2 exclusion,
  MinGW-over-MSVC, IPBan staying manual, etc.) are in
  `docs/design/developer-profile.md`/`server-profile.md`, not repeated
  here.
- A `gwb` command + tab-completion is installed into `$PROFILE`
  automatically on every restore (a separate managed block from the
  profile snippet) — commands, profile/snapshot names, and package
  names all complete, reading live from disk.
- `gwb export`/`diff`/`repair` track both `packages.txt` and
  `modules.txt` drift (scoped to packages/modules known to some
  profile — winget has no manual-vs-dependency tracking at all, a
  harder gap than any GLB package manager faced).
- IPBan (`server`'s fail2ban equivalent) is a **deliberate, permanent
  non-goal** for automation — needs Administrator elevation, installs
  a persistent firewall-blocking service, real lockout risk. Manual
  install documented in `docs/reference/ipban-manual-install.md`.
  Recorded as a durable principle in `docs/PROJECT.md`'s Non-Goals, not
  just a one-off note.
- A Pester test suite (`tests/`, 81 tests) mocks `winget`/
  `Install-Module` and overrides `$PROFILE`, including real
  dispatcher-level coverage (dot-sources `gwb.ps1` itself with `Mock`
  still active). Run with `Invoke-Pester -Path tests/`.
- **Verified for real on the Windows 11 machine above** throughout —
  every feature above was actually run (not just parsed) before being
  considered done, including idempotency checks and, for anything
  touching `$PROFILE`, dot-sourcing the real file afterward to confirm
  it actually works live. See `CHANGELOG.md` for the full list of real
  bugs this caught (a `Set-Content` trailing-newline bug, a
  backup-clobbering edge case, a mixed-line-endings false-positive
  diff, `Read-Host` crashing instead of failing gracefully, an
  `Invoke-Expression` array-binding bug, `-ErrorAction SilentlyContinue`
  not actually suppressing a PSReadLine message, and a `Mandatory`
  PowerShell array parameter rejecting a legitimate empty array).
- Full documentation set, matching GLB's: `README.md`, `LICENSE` (MIT),
  `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
  `.gitignore`, `docs/ROADMAP.md`/`ARCHITECTURE.md`/
  `CODING_STANDARDS.md`/`PHILOSOPHY.md`/`PROJECT.md`/`README.md`/
  `DOCS_CHANGELOG.md`/`troubleshooting.md`, `docs/design/` (one doc per
  real feature decision), `docs/reference/`.

## Roadmap / in progress

See `docs/ROADMAP.md` for the full versioned plan — kept up to date
after every feature this session, so it's the accurate source of
truth, not a summary to re-derive from here. Short version: **every
stated Version 0.1–1.0 goal is now done**, including public-release
readiness (repo went public 2026-08-11, see `docs/PROJECT.md`'s
Release Strategy) and the curl/`irm`-style one-liner installer
(`install.ps1`, built the same day right after — see
`docs/design/installer.md`). **The one thing left before either can be
called fully verified: `install.ps1` hasn't been run on real Windows
hardware yet** — it was built and Pester-tested from the repo alone in
a cloud session with no `pwsh` available. Next session on the real
Windows 11 machine should run `irm https://raw.githubusercontent.com/
ggregoro/GWB/master/install.ps1 | iex` for real and
`Invoke-Pester -Path tests/Install.Tests.ps1` before this is
considered done, not just built.

## Conventions

- PowerShell 7+ only — see `docs/CODING_STANDARDS.md`.
- **Verify for real before calling something done** — parse-check, then
  actually run the command, including running it twice to confirm
  idempotency for anything that touches `$PROFILE` or installed
  packages, and (since the suite exists now) run `Invoke-Pester -Path
  tests/` for anything touching `lib/`. This is the same discipline
  GLB's own `CLAUDE.md` documents repeatedly, and it's caught several
  real bugs across GWB's own sessions so far — see `CHANGELOG.md` for
  the full list, or the Working notes below for the session-by-session
  account.
- **End-of-session standing instruction, mirrored from GLB**: commit
  and push outstanding changes — code, docs, and this file — before
  ending a session, and update this file's Working notes with what
  changed and what's still open, so a future session (possibly on a
  different machine) has real continuity rather than having to
  re-derive context.

## Working notes

- **Session wrap-up (2026-08-11, cloud session) — pausing here by
  Greg's choice; next session picks up on his real Windows 11
  machine.** Everything is committed and pushed to `master` —
  `3d1727c` is the latest commit as of this note, working tree clean.
  This session made the public-release decision (`b125063`) and built
  `install.ps1`, the curl/`irm` one-liner installer (`3d1727c`) — see
  the two entries directly below for full detail.
  - **Next session's first job, before anything else: verify
    `install.ps1` for real.** It was built and Pester-tested from the
    repo alone in this cloud session, which has no `pwsh` at all —
    genuinely never executed, not just "not run against real
    hardware." Two concrete things to run, both already called out in
    `docs/design/installer.md`:
    1. `Invoke-Pester -Path tests/Install.Tests.ps1` — the 6 new tests
       may well surface real PowerShell syntax/logic mistakes, since
       nothing in this file has been parsed by an actual PowerShell
       engine yet.
    2. `irm https://raw.githubusercontent.com/ggregoro/GWB/master/
       install.ps1 | iex` for real, confirming it clones to
       `$env:LOCALAPPDATA\GWB`, then running it a second time to
       confirm the update-in-place path works, then following its own
       printed instructions (`& "$env:LOCALAPPDATA\GWB\gwb.ps1"
       restore`) to confirm the whole chain actually works end to end
       on a real machine.
  - Nothing else outstanding needs a specific machine — this is the
    only open item anywhere in the project right now.
- **`install.ps1` built (2026-08-11, cloud session, immediately after
  the going-public decision below).** The one remaining Version 1.0
  item once the repo went public — a fresh machine has no credentials
  to clone a private repo, the same blocker GLB's own `install.sh` had
  before *its* repo went public.
  - Two genuine platform forks from GLB's `install.sh`, not just a
    syntax port, both stemming from one real difference: `curl | bash`
    runs the piped script in a disposable subshell, but PowerShell's
    `irm <url> | iex` evaluates the fetched text in the *caller's own
    live session* (the same as dot-sourcing) — there is no subshell to
    contain it. Worked through the consequences carefully rather than
    porting `install.sh`'s structure directly:
    1. The entire script body is wrapped in one `& { ... }`
       scriptblock, so its variables (`$InstallDir`, `$RepoUrl`) get
       their own child scope instead of leaking into the user's
       interactive session once the one-liner finishes.
    2. **No `exit` call appears anywhere in the file** — under `iex`,
       `exit` would close the user's entire PowerShell window, not
       just the installer, unlike `bash`'s subshell-scoped `exit 1`.
       Error paths use plain, non-terminating `Write-Error` (stderr)
       plus an explicit `return`, which only unwinds the `& { }`
       block regardless of whether the file is piped through `iex` or
       run directly. Deliberately did **not** set
       `$ErrorActionPreference = "Stop"` either, despite that being
       `gwb.ps1`'s own dispatcher convention — doing so would turn
       `Write-Error` into a terminating exception carrying the same
       kind of escape risk. Documented as an intentional, explained
       exception to that convention (which `docs/CODING_STANDARDS.md`
       itself allows), not an oversight.
  - Installs to `$env:LOCALAPPDATA\GWB` — the Windows-idiomatic
    per-user app-data location — rather than literally porting GLB's
    `~/.local/share/glb` path structure onto Windows. Same category of
    platform-appropriate divergence already made for the `gwb` command
    itself (`lib/completions.ps1`), which couldn't be a `PATH` symlink
    the way GLB's `glb` is. `$env:GWB_INSTALL_DIR`/`$env:GWB_REPO_URL`
    overrides mirror GLB's `GLB_INSTALL_DIR`/`GLB_REPO_URL` exactly.
    Deliberately does not run `gwb restore` itself, same reasoning as
    GLB's `install.sh`.
  - Full writeup, including the reasoning trail for both forks, in
    `docs/design/installer.md`.
  - Added `tests/Install.Tests.ps1` (6 tests, mirroring GLB's
    `tests/install.bats` one-for-one plus an explicit scope-isolation
    test for the `& { }` wrapper). Since `install.ps1` has no
    dot-sourceable functions (deliberately — it must work before
    GWB/`lib/` exists on a machine), tests re-evaluate its raw text via
    `Invoke-Expression` in each case, exactly how the real one-liner
    invokes it — this keeps Pester's `Mock` working through normal
    dynamic scoping, the same mechanism `Packages.Tests.ps1` already
    relies on for `winget`.
  - **Not yet verified on real Windows hardware, and the new Pester
    tests have never actually been run** — this cloud session has no
    `pwsh` at all (`pwsh --version` fails), so nothing here could be
    executed, only carefully reasoned through and written. This is a
    real gap, not a minor caveat: every other GWB feature built so far
    was verified for real (parse-check, then actually run, per this
    project's own standing discipline) before being called done. This
    one hasn't cleared that bar yet. Flagging clearly rather than
    calling it finished: next session on the real Windows 11 machine
    needs to (1) run `Invoke-Pester -Path tests/Install.Tests.ps1` and
    fix whatever the (untested) PowerShell syntax/logic gets wrong,
    and (2) actually run the real one-liner against the now-public
    repo and confirm it clones, updates in place on a second run, and
    prints working instructions.
- **Going-public decision made (2026-08-11, cloud session, follow-up to
  the feature-completion session earlier the same day).** Before
  deciding, audited the repo for anything that would become
  permanently, publicly exposed on visibility change: commit
  authorship (all `Gregory Gregorowicz <ggregoro@gmail.com>`, same as
  GLB — Greg already accepted this being public there), secrets/keys/
  tokens/passwords (none — grep hits were just prose mentioning
  "password"/"secrets" conceptually in design docs), hardcoded IPs or
  `C:\Users\<name>`/`/home/<name>` paths (none), and whether any real
  `snapshots/` export data was accidentally tracked (none — the
  directory is deliberately un-gitignored by design, matching GLB, but
  nothing's actually been exported into it yet). **Unlike GLB's own
  pre-public audit** (which found and had to fix a hardcoded personal
  git identity in `.gitconfig` and a leaked home-server IP in a
  reference doc), GWB's scan came back completely clean — no edits
  were needed before flipping visibility. Greg made the call to go
  public immediately after hearing the clean result, without waiting
  for GLB's own more cautious "vetted across multiple real machines"
  bar — GWB has only ever been tested on Greg's one Windows 11 machine.
  Updated `docs/PROJECT.md`'s Release Strategy (now records the actual
  public date and the audit outcome, instead of the old "stays
  private" stance) and `docs/ROADMAP.md`'s Version 1.0 goals (public
  release now marked done; noted that this actually unblocks the
  still-open curl/`irm`-installer item, the same way GLB's own
  `install.sh` needed a public repo before it could be verified
  end-to-end on a fresh machine). No code changed this session —
  docs-only.
- **Session (2026-08-11): took GWB from `default`-only to
  feature-complete against GLB's Version 0.1–0.6, plus a test suite.**
  Long session, one feature per round, each verified for real and
  committed/pushed separately (see `git log`/`CHANGELOG.md` for the
  full sequence — this is a synthesis, not a replacement for either):
  - **`developer` and `server` profiles.** Real forks researched and
    resolved rather than guessed: no container tooling in `developer`
    (Docker Desktop/Podman Desktop both need WSL2, and Greg has a hard
    "never install WSL2" rule — it breaks his VirtualBox VMs; saved as
    a standing memory entry, not just a one-off note) — MinGW/gcc
    chosen over MSVC Build Tools; `mise`/Fresh both confirmed to have
    real native Windows support via direct `winget search`, not
    assumed. `server` got `restic` (real, native, no WSL) with
    `robocopy` covering `rsync`'s role and Windows Firewall covering
    `ufw`'s; IPBan (fail2ban equivalent) was the one open question,
    resolved at the very end of the session (see below). Far Manager
    added to both later, prompted by a question about Ranger/Midnight
    Commander equivalents on Windows (`lf` already covered Ranger).
  - **`export`/`diff`/`repair`/`restore --from-snapshot`/`restore
    --from-manifest`.** The real fork: winget has *no*
    manual-vs-dependency package tracking at all (confirmed via
    `winget list --help` and a real 80-entry unfiltered list mixing
    OEM bloat with actual tools) — a harder gap than any GLB package
    manager faced, even zypper. Scoped tracking to packages/modules
    known to some profile rather than a full machine inventory.
    `--from-manifest` turned out to need zero new logic —
    `Invoke-GwbApplyProfile` already accepted an arbitrary path.
  - **A `gwb` command + tab-completion.** PowerShell-idiomatic
    equivalent of GLB's `PATH` symlink: a wrapper function in
    `$PROFILE` (`.ps1` scripts aren't callable by bare name on
    Windows), verified to support real position-based tab-completion
    via `Register-ArgumentCompleter` and `.GetNewClosure()` — both
    mechanics tested empirically before writing the real module.
  - **PSFzf/Terminal-Icons/PSReadLine.** PSGallery's
    `InstallationPolicy` is `Untrusted` by default (confirmed
    directly) — the PSGallery equivalent of the
    `winget --accept-source-agreements` issue; `-Force` suppresses it,
    verified with a real install. PSReadLine gets config only, no
    install step, since it already ships with PowerShell 7.
  - **`modules.txt` drift tracking**, added as a same-day follow-up
    once `lib/modules.ps1` existed — generalized the existing
    package-scanning/diffing helpers rather than duplicating them;
    `lib/repair.ps1` needed zero changes since it already reuses those
    functions directly.
  - **IPBan decided as a permanent, deliberate non-goal.** Pulled the
    real, current install script directly (not summarized) and
    confirmed it needs Administrator elevation (a first for anything
    GWB would install), sets up a persistent firewall-blocking Windows
    Service, and carries a real account-lockout risk — categorically
    different from every other extra GWB automates. Recorded as a
    durable principle in `docs/PROJECT.md`'s Non-Goals, not just an
    IPBan-specific note. Manual install steps in
    `docs/reference/ipban-manual-install.md`.
  - **A Pester test suite (81 tests).** Only the ancient bundled
    Pester 3.4.0 was present; installed modern 6.0.1. Verified three
    real mechanics in scratch probes before writing any real test:
    `Mock` works against an external `.exe` (`winget`), `$PROFILE` can
    be safely overridden per-test, and `gwb.ps1` itself can be
    dot-sourced with real arguments inside a mocked Pester scope
    without its own `exit 0` killing the test process — giving real
    dispatcher-level coverage, not just `lib/*.ps1` unit tests. The
    suite caught a real bug on its very first run (a `Mandatory`
    PowerShell array parameter silently rejecting a legitimate empty
    array — `gwb diff`/`repair` would have crashed on any
    `modules.txt`-less profile) that no amount of this session's own
    extensive manual testing had surfaced, since every real profile
    has always had a non-empty `modules.txt`.
  - **Real bugs caught and fixed this session** (beyond the Pester one
    above), each confirmed on the real machine, not just reasoned
    about: a `Set-Content` trailing-newline/mixed-line-endings bug
    (found twice, in two different write sites, causing a false-
    positive `gwb diff`); a `Read-Host` crash instead of a graceful
    decline with no interactive input, in two places; an
    `Invoke-Expression` array-binding bug (`mise activate pwsh`'s
    output is an array, not a string, unlike Starship's); and
    `-ErrorAction SilentlyContinue` not actually suppressing a
    PSReadLine console message the way `try`/`catch` does.
  - **Nothing left mid-flight** — working tree clean, everything
    pushed to `master` (`514cbda` is `HEAD` as of this note). Next
    session should start from `docs/ROADMAP.md`'s Version 1.0 section:
    the one real open item is deciding public-release readiness
    (repo visibility), which is explicitly Greg's call, not something
    to pick up unprompted.

- **Session (2026-08-10): initial build.** Restructured an earlier
  ad-hoc PowerShell sketch (a single `restore-default.ps1` plus
  `lib/packages.ps1`/`dotfiles.ps1`) into the current dispatcher +
  `lib/` architecture, built out the `default` profile, verified
  everything for real on this machine, pushed the result to a new
  private GitHub repo, then added the full documentation set (README
  through `docs/PROJECT.md`) to bring GWB to parity with GLB's own
  docs. Nothing left mid-flight — working tree clean, everything
  pushed to `master` as of this note.
