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
  present. The original dev machine — most real verification has
  happened here.
- Greg's second Windows 11 Pro machine (build 26100) — a new laptop,
  GWB's first real second-machine verification (2026-08-21), closing
  the gap this section used to note ("hasn't been tested on a second
  machine/VM yet, unlike GLB's many"). Started with only Windows
  PowerShell 5.1 and no `pwsh` at all; `Documents` is OneDrive-redirected
  here, unlike the primary machine. See the Working notes entry below
  for the full account.

## Current state (as of 2026-08-13)

GWB is feature-complete against every GLB Version 0.1–0.6 equivalent,
plus a Pester test suite, and is at `VERSION` `1.0.0` (bumped this
session to match the Version 1.0 milestone, which had already been
complete since 2026-08-11). See `docs/ROADMAP.md` for the full versioned
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
- All three profiles ship `yazi-config/` (`yazi.toml`, `init.lua`, the
  vendored `yazi-rs/plugins:git` plugin, byte-identical across all
  three) — deployed by `Install-GwbYaziConfig` (`lib/profile.ps1`) into
  `$env:APPDATA\yazi\config`, wired into `Invoke-GwbApplyProfile`
  conditionally (only when a profile actually ships a `yazi-config/`
  directory, same `Test-Path`-gated pattern as `modules.txt` and
  `windows-terminal-settings.json`). Ported from GLB's own `default`
  profile, `default`-only at first, then to `developer`/`server` too —
  see the Working notes entries below for the full history: the port
  itself, its real verification, a real `file`-not-found bug found live
  and fixed (yazi's previewer needs the real `file` command for MIME
  detection; neither Git for Windows nor winget's own `GnuWin32.File`
  package puts it on `PATH`, so `profile-snippet.ps1` adds it
  explicitly, guarded, in all three profiles), and the developer/server
  port itself.
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
- A Pester test suite (`tests/`, 103 tests) mocks `winget`/
  `Install-Module` and overrides `$PROFILE`, including real
  dispatcher-level coverage (dot-sources `gwb.ps1` itself with `Mock`
  still active). Run with `Invoke-Pester -Path tests/`.
- `install.ps1` — a curl/`irm`-style one-liner installer
  (`irm https://raw.githubusercontent.com/ggregoro/GWB/master/
  install.ps1 | iex`), mirroring GLB's `install.sh`. Built once the
  repo went public; verified for real the same day (fresh clone,
  update-in-place, `gwb.ps1 restore` from the fresh checkout, all
  confirmed working against the live repo). See
  `docs/design/installer.md`.
- **Verified for real on the Windows 11 machine above** throughout —
  every feature above was actually run (not just parsed) before being
  considered done, including idempotency checks and, for anything
  touching `$PROFILE`, dot-sourcing the real file afterward to confirm
  it actually works live. See `CHANGELOG.md` for the full list of real
  bugs this caught (a `Set-Content` trailing-newline bug, a
  backup-clobbering edge case, a mixed-line-endings false-positive
  diff, `Read-Host` crashing instead of failing gracefully, an
  `Invoke-Expression` array-binding bug, `-ErrorAction SilentlyContinue`
  not actually suppressing a PSReadLine message, a `Mandatory`
  PowerShell array parameter rejecting a legitimate empty array, a real
  `ls`-vs-built-in-alias precedence bug Greg hit live, a missing
  `far` launcher found while walking through how to actually run GWB's
  add-on programs, a Starship `scan_timeout` warning Greg hit live in
  `C:\Windows\System32`, and that same directory turning out to be
  where his taskbar-pinned PowerShell icon always started).
- Full documentation set, matching GLB's: `README.md`, `LICENSE` (MIT),
  `CHANGELOG.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
  `.gitignore`, `docs/ROADMAP.md`/`ARCHITECTURE.md`/
  `CODING_STANDARDS.md`/`PHILOSOPHY.md`/`PROJECT.md`/`README.md`/
  `DOCS_CHANGELOG.md`/`troubleshooting.md`, `docs/design/` (one doc per
  real feature decision), `docs/reference/`.

## Roadmap / in progress

See `docs/ROADMAP.md` for the full versioned plan — kept up to date
after every feature, so it's the accurate source of truth, not a
summary to re-derive from here. **Version 1.0 (Stable Release) is now
fully complete and verified for real** — every stated goal is done,
including public-release readiness (repo went public 2026-08-11, see
`docs/PROJECT.md`'s Release Strategy) and the curl/`irm`-style
one-liner installer (`install.ps1` — built in a cloud session with no
`pwsh` at all, genuinely never executed there; verified for real the
same day on Greg's Windows 11 machine, see `docs/design/installer.md`
and the Working notes entry below for what that surfaced). GWB is
feature-complete against GLB's Version 0.1–0.6, publicly released, and
its own installer is confirmed working end to end on real hardware.

yazi (ported from GLB, built in a cloud session with no `pwsh`) is now
also **verified for real** — see the Working notes entry below.
**Nothing currently queued.**

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

- **Session (2026-08-21, Greg's second real Windows 11 machine, a new
  laptop): GWB's first real second-machine install, closing a gap
  documented since the project's very first session.** Greg asked to
  install GWB here, dry run first. No code in the repository changed
  this session — pure deployment plus this documentation pass.
  - **Real prerequisite gap found before anything else could run**:
    this laptop (build 26100, vs. the primary machine's 26200) had only
    Windows PowerShell 5.1 — no `pwsh` at all — and `gwb.ps1` declares
    `#Requires -Version 7.0`. Confirmed directly (`grep`) rather than
    assumed. Installed PowerShell 7 via `winget install --id
    Microsoft.PowerShell -e` (7.6.5.0) with Greg's confirmation first,
    since installing system-wide software is a real, if low-risk,
    mutation. **Real finding**: this winget install resolved to the
    MSIX-packaged app (`C:\Program Files\WindowsApps\
    Microsoft.PowerShell_7.6.5.0_x64__8wekyb3d8bbwe`, `pwsh.exe`
    reachable via an App Execution Alias on `PATH`), not the classic
    `C:\Program Files\PowerShell\7\pwsh.exe` MSI layout the primary
    machine likely has — confirmed by checking both locations directly
    rather than assuming the familiar path still applied.
  - **Dry run** (`gwb.ps1 restore developer --dry-run`): clean, all
    `[WhatIf]`, no errors — `git` already present, 14 packages + 2
    PowerShell modules queued, `$PROFILE` (didn't exist yet on this
    machine) and yazi config both correctly previewed.
  - Greg asked whether `developer` also gets everything `default` has.
    Checked directly rather than assumed: **no runtime inheritance** —
    `lib/profile.ps1` has no layering logic at all (confirmed via
    `grep`) — `developer`'s `packages.txt`/`modules.txt`/
    `profile-snippet.ps1` are each maintained as manual supersets of
    `default`'s (every `default` package duplicated verbatim, plus
    developer-specific extras). Worth remembering: keeping these two
    profiles in sync is a manual discipline, not something the code
    enforces.
  - **Real (non-dry-run) `gwb.ps1 restore developer`**, run in the
    background and watched to completion (exit code 0): 14 packages
    installed (`eza`, `fzf`, `lf`, `ripgrep`, `fd`, `bat`, `starship`,
    `jq`, `gh`, `mise`, `fresh`, `mingw`, `farmanager`, `yazi`, `file`),
    2 PowerShell modules (`PSFzf`, `Terminal-Icons`), `$PROFILE`
    created fresh and wired (packages + Starship `scan_timeout = 1000`
    + yazi config + `gwb` self-registration). Several UAC/installer
    elevation prompts appeared for real mid-install (the VC++
    Redistributable dependency `fd`/`bat`/`mise`/`yazi` all pull in,
    plus the `starship`/`gh`/`mingw` MSIs) — Greg approved each live;
    all were expected, none were GWB's own doing.
  - **A real gap in the verification tooling itself, worth remembering
    for future sessions**: the PowerShell tool used to drive this
    doesn't persist shell state (env vars, not just variables/functions
    as documented) between separate tool calls — refreshing `$env:Path`
    from the registry in one call and then spawning a child `pwsh` to
    test tools in a *following* call silently reverted to the stale
    PATH, which made `profile-snippet.ps1`'s own `Get-Command`-guarded
    tool detection silently skip defining `ll`/`ls`/`la` and made
    `PSFzf` fail to load — none of that was a real GWB bug, purely a
    verification-methodology artifact. Fixed by combining the PATH
    refresh and the actual test command into one call. A close cousin
    of the 2026-08-13 session's own "a Bash-tool-spawned `pwsh` process
    is not a reliable proxy for a real PowerShell session's `PATH`"
    note — same root cause, different tool this time.
  - **A related false alarm, chased down and resolved rather than
    written up as a bug**: `eza`/`ll` produced literally empty output
    when invoked via a semicolon-chained `pwsh -NoLogo -Command '...;
    ll'` string, but the *exact same* `eza --icons --group-directories-
    first -lah` call produced correct output both when invoked directly
    and via `pwsh -File <script>.ps1`. Isolated with a side-by-side
    repro before concluding anything — an artifact of that specific
    nested `-Command`-string invocation style, not a real `eza` or GWB
    bug.
  - **Verified for real, once the above was worked around**: a fresh
    `pwsh` session loads the profile with no errors; `gwb version`,
    `ll`/`ls`/`la` (full correct eza listing), `Get-Command ls -All`
    (resolves to `Function` only, confirming the built-in-alias-removal
    fix applies here too), `rg`, `gcc`, `yazi --version`, and `far`
    (resolves to the wrapper function) all work correctly.
  - Greg asked whether closing/reopening his terminal would now run
    PowerShell 7. Answered directly rather than assuming: **no** —
    installing PS7 via winget doesn't change any shortcut's or Windows
    Terminal profile's default; the GWB-managed `$PROFILE` was written
    to PS7's own profile path (`...\Documents\PowerShell\...`), a
    completely separate file from Windows PowerShell 5.1's untouched
    one (`...\Documents\WindowsPowerShell\...`) — and on this machine
    both actually resolve under a OneDrive-redirected `Documents`
    folder, a real difference from the primary dev machine worth
    remembering if a future session assumes the plain
    `C:\Users\ggreg\Documents` path.
  - **Set Windows Terminal's default profile to PowerShell 7** (Greg's
    explicit ask, and out of scope for `gwb restore` itself per
    `docs/PHILOSOPHY.md`'s "Enhance the Terminal You Have" boundary —
    done directly as a one-off machine-config change, not added to any
    GWB code). Found the Store-packaged `settings.json`
    (`%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\
    LocalState\settings.json`), backed it up
    (`settings.json.bak-20260821`) before editing, matching the same
    precedent from the 2026-08-13 System32 session. **A real gotcha hit
    live**: Windows Terminal was running throughout, and mid-edit it
    silently regenerated its own `settings.json` — it had auto-detected
    the new PS7 install and added its own dynamic `"PowerShell"`
    profile (`source: Windows.Terminal.PowershellCore`) — which
    overwrote the first manual `defaultProfile` edit before it could be
    verified. Caught by re-reading the file before the second edit
    rather than trusting the first one had stuck; used Windows
    Terminal's own auto-detected profile (rather than adding a
    duplicate manual entry) and pointed `defaultProfile` at its real
    `guid`. **Flagged to Greg, not independently verified this
    session**: Windows Terminal was still running at the time of the
    final edit, so a full close-and-reopen (not just a new tab) is
    needed to be certain the change isn't clobbered again by its own
    in-memory state on exit — left as something for Greg to confirm on
    his next real restart, the same "flag the real gap rather than
    assume it's fine" discipline this project applies throughout.
  - Working tree: only this documentation update touches the repo.
    Everything else this session (PS7 install, the real `restore`, the
    Windows Terminal edit) was live-machine state, not committed code.
    **Nothing queued.**

- **Session (2026-08-13, real Windows 11 machine, second follow-up):
  fixed a real bug in yazi's previewer, found by Greg using it live
  minutes after the verification pass directly below confirmed
  everything working.** Greg launched `yazi` directly and hit
  `Cannot find 'file' to detect the file's MIME type.` on every file
  (screenshot). Root-caused precisely rather than assumed:
  - yazi's previewer shells out to the real `file` command for
    MIME-type detection — nothing in GWB guaranteed it existed on
    `PATH`. Git for Windows *does* bundle a working `file.exe`
    (`Git\usr\bin\file.exe`), but its installer only ever adds
    `Git\cmd` to `PATH`, never `Git\usr\bin` — confirmed against the
    real persisted registry `PATH`
    (`[Environment]::GetEnvironmentVariable("Path", "User"/"Machine")`),
    not just the current process's inherited one. That distinction
    mattered directly: an initial `Get-Command file` check from this
    session's own shell falsely reported success, because it inherited
    git-bash's own internal `PATH` (which always includes `usr\bin`
    regardless of the real system `PATH`) — only checking the
    registry-persisted values directly (simulating what a genuinely
    new terminal window actually starts with) revealed the truth.
    Worth remembering for any future PATH-related check in this
    project: a Bash-tool-spawned `pwsh` process is not a reliable proxy
    for a real, independent PowerShell session's `PATH`.
  - Even `developer` (which does install `git`) wouldn't have fixed
    this, since Git's `usr\bin` still isn't on `PATH` there either.
  - **Fixed**: added `file` → `GnuWin32.File` to
    `_GWB_PACKAGE_OVERRIDES` and `default`'s `packages.txt`. winget
    installs it but — confirmed directly — doesn't add it to `PATH`
    either (an Inno Setup installer, not one of winget's PATH-shimmed
    CLI-tool installers), so `profile-snippet.ps1` also adds its
    install directory to `PATH` explicitly, guarded and idempotent —
    the exact same "winget doesn't PATH-shim this" pattern already
    handled for Far Manager, just via a raw `PATH` entry instead of a
    function wrapper, since `file` needs to be found by *yazi's own
    child-process spawn*, not invoked directly by the user — a
    PowerShell function/alias would be invisible to that.
  - **Fixed Greg's actual live machine state directly, not just the
    repo** — his real `$PROFILE` is `developer`, which doesn't (and,
    as scoped, shouldn't) carry yazi/`file` at all, so the
    `profile-snippet.ps1` fix alone wouldn't reach him without
    switching profiles. Persisted the `GnuWin32\bin` directory onto his
    real **User** `PATH` directly via
    `[Environment]::SetEnvironmentVariable`, independent of any GWB
    profile — confirmed via the same registry-reconstruction technique
    that `file.exe` now resolves and produces correct output.
  - Verified for real: full Pester suite still 103/103;
    `gwb.ps1 restore default --dry-run` correctly reports `file`
    alongside `yazi` (both "Already installed", since the real winget
    install from the verification pass below already covers `file`
    too); `Resolve-GwbPackageId -Name 'file'` returns `GnuWin32.File`
    correctly.
  - yazi was `default`-only at this point — Greg is on `developer`, so
    this session fixed his actual live usage directly rather than via
    a profile restore. **Resolved immediately after, same session**:
    Greg asked for it on `developer`/`server` too — see the next entry
    up top for the port.

- **Session (2026-08-13, real Windows 11 machine, third follow-up):
  ported yazi + `file` to `developer`/`server`, closing out the open
  question the previous entry left.** Greg's call — he's actually on
  `developer` day to day, and asked directly.
  - Added `yazi`/`file` to both profiles' `packages.txt` (same
    explanatory comments as `default`'s). Copied `yazi-config/` into
    both profile directories — raw byte copy from `default`'s, not
    hand-typed (`diff -rq` confirms byte-identical, avoiding any risk
    of the kind of content-corruption GLB's own `starship.toml` history
    documents at length, even though these particular files don't carry
    the specific glyph-range risk that bug was about). Added the same
    guarded `file`-on-PATH block to both profiles' `profile-snippet.ps1`.
  - Verified for real: full Pester suite still 103/103;
    `restore developer`/`restore server --dry-run` both correctly
    report `yazi`/`file`. Then, since `developer` is this machine's
    actual live profile, ran a real (non-dry-run)
    `gwb.ps1 restore developer` — `$PROFILE` updated with the new PATH
    guard, yazi config deployed to `$env:APPDATA\yazi\config`,
    confirmed idempotent on a second real run.
  - **Real, direct visual confirmation from Greg**: a screenshot of
    `yazi` browsing this repo showed `CLAUDE.md` rendering correctly in
    the preview pane (syntax-highlighted, scrollable) — genuine
    end-user confirmation the `file`-detection fix actually works, not
    just a clean exit code.
  - All three profiles now carry yazi/`file` identically. Working tree
    clean, everything pushed to `master` as of this note. **Nothing
    queued.**

- **Session (2026-08-13, real Windows 11 machine, follow-up): verified
  the yazi port for real, closing out the one thing the cloud session
  below flagged as unverified.** Pulled `f06ae92` from GitHub (the
  cloud session's push had genuinely made it up, despite an earlier
  false alarm this same day about it not being pushed — see below).
  - `Invoke-Pester -Path tests/`: **103/103**, up from 93 — all 10 new
    yazi tests pass for real, not just parse-reviewed.
  - Installed `yazi` for real via `winget install sxyazi.yazi` (clean
    machine, nothing pre-installed) — `26.5.6`, confirmed via
    `yazi --version`.
  - Deployed the config for real by calling `Install-GwbYaziConfig`
    directly with an explicit `-SourceDir` (the function's own
    `-ConfigPath`-style isolation parameter, same pattern
    `Install-GwbStarshipConfig` already established) — deliberately
    **not** via a full `gwb.ps1 restore default`, since that would have
    switched this machine's live `$PROFILE` from `developer` to
    `default`, a real disruptive side effect well beyond what
    "verify yazi" actually needed. `Install-GwbYaziConfig` itself never
    touches `$PROFILE` at all, so this was safe to call in isolation.
    Confirmed the deployed files at `$env:APPDATA\yazi\config` are
    byte-identical to the source (`diff -rq`, zero output).
  - **Confirmed the config genuinely loads, not just that the files
    exist**: `yazi --debug` reports `Init` (39 chars) and `Yazi`
    (177 chars) loaded from the real deployed paths, sizes matching the
    source files exactly, and the full debug dump completes with no
    Lua/plugin error — meaning `init.lua`'s `require("git"):setup{...}`
    genuinely executed. No pty available in this environment to
    visually confirm the git-status icons render in the live TUI, but
    this is real confirmation the config parses and the plugin loads,
    not just that files landed in the right place.
  - **Verified the backup-on-first-touch and never-clobber-an-existing-
    backup behavior for real**, not just via the Pester tests that
    already cover it in isolation: called `Install-GwbYaziConfig` a
    second time (config now existed) and confirmed
    `config.gwb-backup` was created; planted a canary file inside that
    backup, called it a third time, and confirmed the canary survived
    untouched — matching `Set-GwbManagedBlock`'s own rule for
    `$PROFILE`, now genuinely confirmed for yazi's backup path too, not
    just asserted by a test double. Canary cleaned up afterward; the
    real yazi install and deployed config were deliberately left in
    place rather than torn down, matching how every other GWB feature
    in this file has been verified (a real install left in a real
    working state, not undone after the check).
  - **Deliberately did not exercise `Undo-GwbRestore`'s new yazi-restore
    branch live** — it also unconditionally restores `$PROFILE` from
    `$PROFILE.gwb-backup` with no way to isolate just the yazi half,
    and this machine's real `$PROFILE` is the live `developer` setup
    from earlier today; calling it for real would have silently
    reverted that. Covered by the Pester suite only, same as the
    original cloud session's own build.
  - **A real test-isolation bug this verification pass itself
    surfaced, caught by re-running the full suite after leaving the
    real yazi install/config in place**: `Dispatcher.Tests.ps1`'s
    "restore --undo fails cleanly with no backup present" test started
    failing (102/103) right after the backup-preservation check above
    left a genuine `$env:APPDATA\yazi\config.gwb-backup` on this
    machine. Root cause: that test calls the real `gwb.ps1` script,
    which calls `Undo-GwbRestore` with no `-YaziConfigPath` override at
    all (`gwb.ps1` line 136) — so it resolves the *real* host path,
    unlike `Profile.Tests.ps1`'s own `Undo-GwbRestore` tests, which were
    already correctly isolated via `-YaziConfigPath` by the cloud
    session that built this. A textbook instance of this project's own
    recurring "real machine state leaks into a test that assumed a
    clean host" pattern (same class as GLB's many documented
    `fresh`-on-`PATH` gaps) — except this time the leak was created by
    this very session's own real verification, and caught within
    minutes by simply re-running the suite afterward rather than
    trusting the earlier clean pass. Fixed by scoping `$env:APPDATA` to
    a fresh temp directory for just that one test; 103/103 confirmed
    stable across two more runs, and the real yazi backup on disk was
    confirmed untouched by the fix.
  - **Earlier the same day, a real false alarm, now resolved**: Greg
    reported the yazi work as not pushed after a prior "close it out"
    checkpoint; a direct `git fetch`/`pull` here found it actually was
    on `origin/master` all along (`f06ae92`) — a miscommunication
    about what had landed, not a real lost-work incident. Worth noting
    only so a future session doesn't go looking for a genuine gap that
    never existed.
  - **`yazi` is now genuinely available and configured on this
    machine** as a real side effect of this verification pass — not
    wired into the live `$PROFILE` (that only happens via a real
    `gwb.ps1 restore default`, deliberately not run this session for
    the reason above), but `yazi` itself works from any shell right now
    with the git-status plugin active.
  - Working tree clean, everything pushed to `master` as of this note
    (see the commit this note ships in). **Nothing queued.**

- **Session (2026-08-13, cloud session, no `pwsh` available): ported
  yazi from GLB — `default` profile only, alongside `lf` (not
  replacing it).** Greg had just gone through the process of adding
  yazi to GLB's `default` profile (new `snap` extras method, since
  yazi has no apt package on Debian/Ubuntu-family distros; the
  `yazi-rs/plugins:git` status plugin vendored as static, byte-for-byte
  config rather than fetched via `ya pkg add` at restore time, since
  GLB's snap build doesn't reliably expose the `ya` CLI on PATH — see
  GLB's own `CLAUDE.md`) and asked to port the same addition here.
  - **`ya`-on-PATH isn't actually a problem on Windows** — winget/scoop
    both ship `ya` normally (unlike GLB's snap build), so
    `ya pkg add yazi-rs/plugins:git` would work fine here. Vendored the
    plugin as static config anyway, for consistency with GLB and
    because the exact same byte-identical files were already sitting in
    GLB's repo to copy from (`diff -r` confirmed identical) — no reason
    to introduce a live network fetch at restore time when a
    known-good static copy already exists.
  - **Real architecture gap this exposed**: unlike GLB, GWB has no
    generic "arbitrary app config file" deployment mechanism — only a
    bespoke, single-purpose one for Starship's `scan_timeout`
    (`Install-GwbStarshipConfig`). Rather than build a new generic
    system prematurely (GWB's own stated minimalism principle in
    `lib/modules.ps1`'s header comment: "add [a second method] only if
    a second real method ever comes up"), added a second bespoke
    function, `Install-GwbYaziConfig` (`lib/profile.ps1`, right after
    `Install-GwbStarshipConfig`) — copies a profile's `yazi-config/`
    directory into `$env:APPDATA\yazi\config`, backing up any real
    pre-existing content to `<path>.gwb-backup` exactly once (same
    backup-on-first-touch rule `Set-GwbManagedBlock` already uses for
    `$PROFILE`), wired into `Invoke-GwbApplyProfile` conditionally
    (only when a profile ships a `yazi-config/` dir — same
    `Test-Path`-gated pattern as `modules.txt`/
    `windows-terminal-settings.json`). If a *third* app-config-file need
    ever comes up, that's the point to generalize this into a real
    mechanism, not before.
  - **Real gap caught while wiring this up, fixed in the same pass**:
    `Install-GwbYaziConfig` creates a `.gwb-backup`, but the existing
    `Undo-GwbRestore` only knew about `$PROFILE`'s backup — that new
    backup would have been silently unrestorable via `gwb restore
    --undo`. Extended `Undo-GwbRestore` to also check for and restore
    the yazi config backup (same "remove current, copy backup over"
    logic, not just a file copy since it's a whole directory), added a
    `-YaziConfigPath` parameter defaulting to the real path so tests
    can isolate it exactly the way `$PROFILE` already gets swapped to a
    temp path in tests — this machine (Windows, in real use) could
    plausibly have a genuine yazi backup sitting in `$env:APPDATA`, and
    a unit test must never touch that.
  - Added `yazi` to `profiles/default/packages.txt` (kept `lf`, not
    replaced — same "alternative, not replacement" framing as GLB's
    `ranger`) and `"yazi" = "sxyazi.yazi"` to `_GWB_PACKAGE_OVERRIDES`
    (`lib/packages.ps1`) — yazi's official winget package ID.
  - 10 new Pester tests: 1 in `tests/Packages.Tests.ps1` (override
    resolution), 9 in `tests/Profile.Tests.ps1` (a new
    `Install-GwbYaziConfig` `Describe` block mirroring
    `Install-GwbStarshipConfig`'s existing style — create/backup/
    never-re-backup/-WhatIf/missing-source cases; new `Undo-GwbRestore`
    cases for the yazi-config restore path, isolated via
    `-YaziConfigPath` pointed at a temp directory rather than the real
    `$env:APPDATA`; two new `Invoke-GwbApplyProfile` cases confirming
    the conditional wiring - not called when a profile ships no
    `yazi-config/`, called with the right `-SourceDir` when it does).
  - **Not yet verified for real, same situation `install.ps1` was
    originally in** — this cloud session has no `pwsh` at all (checked
    directly: `command -v pwsh` fails; `sudo snap install powershell`
    is available but blocked by no-TTY sudo in this sandbox, the same
    limitation documented throughout GLB's own `CLAUDE.md`). Every file
    was hand-reviewed for syntax (brace-balance checked, structure
    compared line-by-line against the existing
    `Install-GwbStarshipConfig`/`Undo-GwbRestore` patterns it mirrors)
    but **never actually executed**. Needs, on Greg's real Windows 11
    machine: `Invoke-Pester -Path tests/` to confirm the new tests
    actually pass (not just parse), then a live `gwb.ps1 restore
    default` to confirm `Install-GwbYaziConfig` really deploys the
    config to `$env:APPDATA\yazi\config` and that yazi picks up the
    git-status plugin correctly (mirroring how GLB's own yazi port was
    confirmed by Greg looking at the real yazi display afterward).
- **Session (2026-08-13, real Windows 11 machine, follow-up): `100ms`
  wasn't actually enough for `System32`.** Right after the session
  below shipped, Greg used the new `sys32` shortcut to `cd` into
  `System32` mid-session and the Starship warning came right back -
  the `$PROFILE` startup guard doesn't fire here (it only moves *away*
  from `System32` at load time, and `sys32` is a deliberate manual `cd`
  afterward), so the scan still runs, and apparently the earlier
  session's own "verified for real" check (via `starship prompt
  --path`) had been against an already cache-warmed directory from its
  own repeated test invocations - a real gap in that verification, not
  a fluke. This time measured the actual scan cost directly instead of
  just checking pass/fail: `starship prompt --path
  C:\Windows\System32` took ~305ms across three consecutive runs, well
  over the shipped `100`ms budget. Raised `Install-GwbStarshipConfig`'s
  default to `1000`ms (still imperceptible on an interactive prompt,
  and irrelevant for any normal directory that already scans in single-
  digit ms). Updated the two Pester assertions checking the literal
  value; 93/93 still passes. Verified for real, properly this time: a
  fresh `pwsh` process started at home, `cd`'d into `System32`
  mid-session (reproducing the exact `sys32` scenario), rendered a
  prompt there - stderr genuinely empty, no warning. Manually bumped
  this machine's own real `~/.config/starship.toml` from `100` to
  `1000`, since `Install-GwbStarshipConfig`'s own "never touch an
  existing value" rule means `gwb restore` won't do that automatically
  - documented as a real, known limitation (not silently papered over)
  in `docs/troubleshooting.md` for anyone upgrading from the earlier
  same-day default.

- **Session (2026-08-13, real Windows 11 machine): fixed two real,
  user-reported prompt/shell-startup issues.**

  **1. Starship's `scan_timeout` warning** (`5e8ceb0`). Greg reported it
  live from a real terminal: every new PowerShell window printed
  `[WARN] - (starship::context): Scanning current directory timed out.`
  before the prompt (shell was starting in `C:\Windows\System32`, a
  large directory). Root cause: Starship scans the cwd on every prompt
  render to pick language/tool modules, with a default `scan_timeout`
  of only 30ms — GWB installs Starship in every profile but had never
  written it a config file at all, so it always ran on that bare
  default. Added `Install-GwbStarshipConfig` (`lib/profile.ps1`), wired
  into `Invoke-GwbApplyProfile` (runs on every `restore`/`repair`):
  writes `scan_timeout = 100` into `~/.config/starship.toml`, only when
  the setting isn't already present — never clobbers a value the user
  set themselves. Verified for real: 5 new Pester tests (93/93 across
  the full suite), then a real `gwb.ps1 restore developer` against this
  machine's actual `$PROFILE` — confirmed `~/.config/starship.toml` was
  created with `scan_timeout = 100`, and a second restore correctly
  left it untouched (idempotent).
  - **A real test-isolation bug caught along the way, not by Pester
    itself**: the first Pester run genuinely wrote to this machine's
    real `~/.config/starship.toml` — `Repair.Tests.ps1` also
    dot-sources `lib/profile.ps1` and calls the real
    `Invoke-GwbApplyProfile` path (via `Invoke-GwbRepair`) without
    mocking the new function, unlike `Profile.Tests.ps1`'s own
    `Invoke-GwbApplyProfile` block, which was mocked correctly on the
    first pass. Caught by noticing the real file appear on disk after
    the first full-suite run, not from any test failure (all 93 tests
    passed even with the leak). Fixed by adding
    `Mock Install-GwbStarshipConfig { }` to `Repair.Tests.ps1`'s
    `BeforeEach`; deleted the stray real file and re-ran the full suite
    to confirm no `~/.config` directory gets created anymore as a test
    side effect.

  **2. PowerShell always starting in `System32`** (`dd8e0ae`). Greg
  separately asked whether PowerShell can start in `C:\Users\ggreg`
  instead. First attempt (a `startingDirectory` edit to Windows
  Terminal's own `settings.json`, `profiles.defaults`) had no effect —
  real diagnosis, not a guess, found why: decoded the raw
  `HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband`
  `Favorites` registry blob (Windows 11's taskbar no longer stores pins
  as simple `.lnk` files) and found the actual pinned icon resolves to
  `Microsoft.PowerShell_8wekyb3d8bbwe!App` — the separately
  MSIX-packaged PowerShell 7 app, not Windows Terminal at all, launched
  elevated (matching the persistent 🔒 Greg's prompt was showing). No
  shortcut-level fix exists for an elevated/packaged launch's working
  directory, so fixed it at the `$PROFILE` level instead: a guarded
  `Set-Location $env:USERPROFILE` at the very top of all three
  `profile-snippet.ps1` files, firing only when `$PWD.Path` is exactly
  `System32`. Also added two personal shortcuts (`proj` →
  `C:\Users\ggreg\Projects`, `sys32` → back to `C:\Windows\System32`
  on demand) directly to the real `$PROFILE`, deliberately placed
  *outside* the `# >>> GWB managed block >>>`/`# >>> GWB self >>>`
  markers so `gwb restore` never touches them — they're Greg's own
  folder convention, not something that belongs in the portable,
  publicly-shared `profile-snippet.ps1`.
  - Verified for real, not just parse-checked: launched actual `pwsh`
    processes via `Start-Process -WorkingDirectory` (the same mechanism
    that reproduces both the elevated-launch and packaged-app cases) —
    one starting in `System32` confirmed the live `$PROFILE` resets to
    `$env:USERPROFILE`, a second starting in
    `C:\Users\ggreg\Projects` confirmed it's left alone (the guard
    doesn't clobber a real starting directory elsewhere), and two more
    confirmed `proj`/`sys32` themselves both work. Full Pester suite
    still 93/93 after the `profile-snippet.ps1` edits (their runtime
    behavior isn't covered by the suite at all — snippet content is
    only ever written verbatim by `Install-GwbProfileSnippet`'s tests,
    never executed — so this class of change can only be verified for
    real, matching this project's own `far`/`ls` precedent).
  - The Windows Terminal `settings.json` edit from earlier in the
    session was left in place (harmless, and still correct if Greg ever
    does use Windows Terminal for something) — a backup
    (`settings.json.bak-20260813`) was saved alongside it before
    editing.

  Working tree clean, everything pushed to `master` as of this note.
  **Nothing else queued.**

- **Session (2026-08-12, real Windows 11 machine): live verification
  pass + two real gaps found and fixed.** Started with no specific bug
  to chase — Greg asked to run GWB live since he doesn't have a second
  Windows box to test on. Re-ran the full Pester suite (88/88), then
  walked through `help`/`version`/`info`/`profiles`/`export`/`diff`
  against the real machine (all correct — `diff default <snapshot>`
  correctly showed drift from `developer`/`server` extras already
  installed here, exit code 1 on detected drift is by design, not a
  bug), then a real `gwb.ps1 restore developer` (idempotent, confirmed
  via a second run; dot-sourcing the live `$PROFILE` afterward in a
  fresh process confirmed `mise activate pwsh` and `ll` both still work
  correctly). Two real, previously-unflagged gaps turned up along the
  way:
  1. **`VERSION` file was stale at `0.1.0`** despite Version 1.0 having
     been complete and verified since 2026-08-11 — `gwb.ps1 version`/
     `help` were printing the wrong number live. Bumped to `1.0.0`,
     updated `docs/PROJECT.md`'s Release Strategy and `README.md`'s
     Status section to match. `Dispatcher.Tests.ps1` reads the real
     `VERSION` file directly, so no test changes were needed; 88/88
     confirmed after.
  2. **No way to launch Far Manager by name.** Asked live "how do I
     launch the add-on programs" — `fresh` already worked bare
     (winget shims CLI tools onto `PATH` automatically), but Far
     Manager installs as a registered GUI app with a Start Menu
     shortcut and no `PATH` entry (confirmed via its registry
     Uninstall key's `InstallLocation`, not guessed). Added a `far`
     function to `developer`/`server`'s `profile-snippet.ps1` wrapping
     the real install path, guarded by `Test-Path` matching every
     other tool's detection idiom in these files. Verified for real:
     restored `developer`, dot-sourced the live `$PROFILE` in a fresh
     process, confirmed `Get-Command far -All` resolves to the
     function with the correct path and no leaked `$GwbFarExe`
     variable in scope. Didn't actually invoke `far` from automation
     (it's a full-screen interactive console app that would hang a
     non-interactive session) — Greg confirmed it launches correctly
     from a real terminal separately.
  - **A near-miss worth remembering, not a bug**: right after the `ls`
    fix below, `ll` briefly looked broken again (a `Mode`/`Size`/`Date
    Modified` table that resembled the old `Get-ChildItem` fallback).
    Root cause: `eza`'s `-h` flag means "add a header row," not
    "human-readable" like GNU `ls` — `eza -lah` was correctly
    rendering its own long/table view all along. Caught by reading
    `eza --help` directly rather than assuming GNU `ls` flag semantics
    carried over; no code change was needed.
  - Updated `docs/DOCS_CHANGELOG.md` and `CHANGELOG.md` with both real
    fixes. Working tree clean, everything pushed to `master`
    (`f9e0fd3`) as of this note. **Nothing queued.**

- **Session (2026-08-11, real Windows 11 machine): fixed a real,
  user-reported `ls` bug.** Greg reported it live via two screenshots
  from an actual terminal: `ll`/`la` correctly showed `eza`'s icon
  output with Starship's prompt, but bare `ls` fell back to plain
  PowerShell `Get-ChildItem` table output. Root-caused with a
  synthetic repro before touching real code — a throwaway
  `Set-Alias`/`function` pair sharing the name `lstest` confirmed
  PowerShell's built-in `ls` → `Get-ChildItem` alias always wins over
  a same-named function in command resolution, even though
  `Get-Command ls -All` shows both registered. `ll`/`la` aren't
  affected since PowerShell ships no built-in aliases with those
  names. Fixed in all three profiles' `profile-snippet.ps1`
  (`Remove-Item -Path Alias:ls -Force -ErrorAction SilentlyContinue`
  before defining the function). Verified for real: parse-checked all
  three files, ran the full Pester suite (88/88), restored `default`
  for real, dot-sourced the live `$PROFILE`, confirmed `Get-Command ls
  -All` now shows only the function and bare `ls` correctly invokes
  `eza`, confirmed idempotency across two restores (byte-identical
  `$PROFILE` output). Updated `docs/troubleshooting.md` (new first
  entry, marked Confirmed), `CHANGELOG.md`, and
  `docs/DOCS_CHANGELOG.md`. Also added `testResults.xml` to
  `.gitignore` — a stray Pester `-CI` output artifact found untracked
  while checking `git status` before committing.
  Working tree clean, everything pushed to `master` as of this note.

- **Session (2026-08-11, real Windows 11 machine): verified
  `install.ps1` for real, closing the one gap the previous cloud
  session flagged.** Started by fetching/pulling — found 3 commits on
  `origin/master` not yet local (`b125063`/`3d1727c`/`a4e5ad7`, all
  from a cloud session with no `pwsh` available): the public-release
  decision and `install.ps1` itself, built but never executed. Did
  exactly what that session's own Working notes entry asked for:
  1. `Invoke-Pester -Path tests/Install.Tests.ps1`, run for the very
     first time — 4 of 7 tests failed immediately. **Real bug, but in
     the test file, not `install.ps1`**: every assertion capturing
     `install.ps1`'s `Write-Error` output via `Invoke-Expression $text
     *>&1 | Out-String` came back empty. Isolated with a minimal repro
     rather than guessed at: `*>&1`/`2>&1` applied directly to an
     `Invoke-Expression` call does not capture that call's own
     error-stream writes; wrapping the call in its own scriptblock and
     redirecting *that* (`& { Invoke-Expression $text } *>&1`) does.
     Confirmed this doesn't affect real interactive `irm | iex` usage
     at all (nothing redirects those streams there) — purely a
     test-capture-technique gap. Fixed all 6 affected assertions; 7/7
     pass now, 88/88 across the full suite, run together.
  2. The real one-liner, run twice against the live public repo: fresh
     clone to `$env:LOCALAPPDATA\GWB` (confirmed via `Test-Path`), then
     correct update-in-place behavior on a second run ("already
     installed... Already up to date" instead of re-cloning). Confirmed
     the fresh checkout resolves its own paths correctly from its new
     location (`gwb.ps1 help`/`profiles` both work), then completed the
     full chain with a real `gwb.ps1 restore default` from it.
  - **Real, expected consequence worth knowing**: that last `restore`
    means the `gwb` function in `$PROFILE` now points at
    `$env:LOCALAPPDATA\GWB\gwb.ps1` (the fresh install), not
    `C:\Users\ggreg\Projects\GWB\gwb.ps1` (the dev checkout this
    project has always been built from). Identical code right now
    (same commit), but new terminal windows run the installed copy
    going forward unless `restore` is re-run from the dev checkout.
    This is correct, intended behavior — `install.ps1` exists
    specifically to be the real end-user install path — not a bug.
  - Updated `docs/design/installer.md`/`pester-test-suite.md`,
    `docs/design/README.md`, `docs/ROADMAP.md`, `CHANGELOG.md`, and
    `docs/DOCS_CHANGELOG.md` to record the verification (the cloud
    session hadn't touched `docs/design/README.md` or
    `docs/DOCS_CHANGELOG.md` at all, so those needed real content
    added, not just a status flip).
  - **Version 1.0 (Stable Release) is now fully complete and verified
    for real.** Nothing queued. Working tree clean, everything pushed
    to `master` as of this note.

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
