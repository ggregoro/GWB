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

- Greg's Windows 11 Pro machine (build 26200, hostname `PC-F2C15AL`) —
  a **ThinkPad** (confirmed directly by Greg, 2026-08-29; not
  previously recorded here), PowerShell 7.6.5 (was 7.6.4 as of the
  2026-08-13 sessions — updated since, confirmed directly via
  `$PSVersionTable` during the 2026-08-21 `$PROFILE`-fix session
  below), winget present. The original dev machine — most real
  verification has happened here. **`Documents` is now
  OneDrive-redirected here too** (confirmed directly, `$PROFILE`
  resolves under `C:\Users\ggreg\OneDrive\Documents\PowerShell\...`) —
  this section used to claim OneDrive redirection was unique to the
  second machine below; that was true when written but is stale now.
  Don't assume a plain `C:\Users\ggreg\Documents` path on either
  machine going forward. **Dev checkout path changed 2026-08-29**: was
  `C:\Users\ggreg\GWB` throughout every session up to and including the
  PSFzf/marker-corruption fixes earlier in this same file - moved to
  `C:\Users\ggreg\Projects\GWB` (Greg's general Projects folder, already
  home to the `proj` shortcut) as part of setting up SSH auth to GitHub
  for the first time on this machine. Verified for real: `gwb version`,
  `Get-Command gwb -All` (a single clean `Function` registration, no
  stale duplicate), and a fresh terminal all confirmed working from the
  new path. **Any future session/doc reference to `C:\Users\ggreg\GWB`
  below this point is historical** (accurate for when it was written,
  stale now) - don't assume that path still exists on this machine.
  `origin` also now uses an SSH remote (`git@github.com:ggregoro/GWB.git`)
  instead of HTTPS, authenticated via an ed25519 key
  (`ggregoro@gmail.com`) added to both the OpenSSH `ssh-agent` service
  (enabled/started - was disabled by default, needed an elevated
  PowerShell window) and https://github.com/settings/keys. Real gotchas
  hit setting this up, in case they recur: this machine's `ssh-keyscan.exe`
  is too old to negotiate GitHub's preferred KEX algorithm
  (`sntrup761x25519-sha512@openssh.com`) and fails silently with no
  fallback (unrelated `ssh.exe` itself connects fine); the interactive
  host-key-confirmation prompt from a plain `ssh -T git@github.com`
  didn't reliably accept typed input in this terminal, worked around
  with `ssh -o StrictHostKeyChecking=accept-new` instead of relying on
  `ssh-keyscan` or the interactive prompt; and `Move-Item` on the
  checkout folder fails with "item is in use" if run from a shell whose
  current directory is inside it - `cd` to the parent first.
- Greg's second Windows 11 Pro machine (build 26100) — a **Dell
  Desktop** (confirmed directly by Greg, 2026-08-29; this section
  previously called it "a new laptop," which was wrong - corrected
  here). GWB's first real second-machine verification (2026-08-21),
  closing the gap this section used to note ("hasn't been tested on a
  second machine/VM yet, unlike GLB's many"). Started with only
  Windows PowerShell 5.1 and no `pwsh` at all; `Documents` is
  OneDrive-redirected here too. See the Working notes entry below for
  the full account (note: that entry's own prose still says "laptop"
  throughout, describing the same real session accurately in every
  other respect - just carrying the same since-corrected assumption
  about form factor).

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

**Open items**:
1. `fastfetch`/`cpufetch` (2026-08-21, `c3752ef`) and `eza --hyperlink`
   on `ll`/`la` are committed and pushed, but not yet verified for real
   — no live OSC 8 hyperlink check in a real terminal (Ctrl-click to
   open a file). See the 2026-08-21 Working notes entry below for
   detail.
2. **The `# >>> GWB self >>>` block in `$PROFILE` isn't safe for
   two-machine OneDrive sync** — Greg's `$PROFILE` is the same
   physical file synced (via OneDrive-redirected `Documents`) between
   this machine and his second Windows laptop, but `gwb.ps1 restore`
   unconditionally bakes in whatever local path it was invoked from,
   so restoring on one machine silently breaks the other's self-
   registration on next sync. Hit for real twice now (2026-08-21,
   2026-08-23 — see that entry below for the full root-cause trail).
   **Next session, on the second machine**: find its actual GWB
   install path, then implement the discussed fix — resolve the GWB
   root dynamically at each `$PROFILE` load from a short list of
   candidate paths, instead of hardcoding the last restore's
   invocation path. Verify for real on both machines before closing
   out.

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

- **Session (2026-08-30, cloud session, no `pwsh` available - same
  conversation as the Desktop pull/CI-cleanup and the ThinkPad SSH
  setup below): built Neovim + LazyVim support at Greg's request** -
  "being novice, I can't use Neovim without LazyVim." Two real design
  decisions asked and confirmed directly before building (not assumed):
  (1) all three profiles, not just `developer`; (2) live-clone/pull
  Greg's own private `nvim-config` repo at restore time, rather than
  vendoring a static copy into GWB the way `yazi-config/` works - his
  LazyVim setup is an actively-changing personal config, and a vendored
  snapshot would go stale the moment he tweaked it. Full reasoning in
  the new `docs/design/nvim-lazyvim.md`.
  - Added `nvim` -> `Neovim.Neovim` to `_GWB_PACKAGE_OVERRIDES` and all
    three `packages.txt`. New `Install-GwbNvimConfig`
    (`lib/profile.ps1`): self-gates on `Get-Command nvim` (same idiom
    as `Install-GwbStarshipConfig`, so it's called unconditionally from
    `Invoke-GwbApplyProfile` rather than `Test-Path`-gated on a
    per-profile directory), clones/pulls
    `git@github.com:ggregoro/nvim-config.git` to
    `$env:LOCALAPPDATA\nvim`, and backs up any real pre-existing config
    exactly once (a *move*, not a copy, since `git clone` needs an
    empty/nonexistent destination) before taking the directory over -
    same backup-on-first-touch rule every other GWB-managed config
    follows. `Undo-GwbRestore`/`gwb restore --undo` extended to restore
    that backup too.
  - **Real test-isolation care taken up front, not found the hard way
    this time**: since `Install-GwbNvimConfig` is called
    unconditionally (unlike yazi's per-profile-directory gate), it
    would touch the real `$env:LOCALAPPDATA\nvim` on any machine that
    actually has `nvim` installed unless mocked - the exact class of
    leak that bit `Install-GwbStarshipConfig` for real early in this
    project (see `CHANGELOG.md`). Mocked it in both
    `Invoke-GwbApplyProfile`'s and `Invoke-GwbRepair`'s test suites
    up front, and extended `Dispatcher.Tests.ps1`'s real
    `restore --undo` test to isolate `$env:LOCALAPPDATA` the same way
    it already isolated `$env:APPDATA` for yazi's backup path.
  - Added a full Pester `Describe` block for `Install-GwbNvimConfig`
    (8 tests: not-installed gates for `nvim`/`git`, fresh clone,
    pull-not-reclone for an existing own-clone, backup-on-first-touch,
    never-re-backup, `-WhatIf`), mocking `git`/`Get-Command` following
    this suite's existing `winget`-mocking conventions - `git`'s mock
    dispatches on `$args[2]` rather than `$args[0]` for the `-C <path>
    <subcommand>` invocations (`remote`/`pull` both start with the
    literal `-C`, so dispatching on `$args[0]` alone can't tell them
    apart - caught and fixed while writing the mock itself, not left as
    a latent bug). Extended `Undo-GwbRestore`'s existing Pester block
    with nvim-backup cases too.
  - Added `docs/design/nvim-lazyvim.md` (the real vendor-vs-live-clone
    fork and why it was decided the way it was) and a
    `docs/troubleshooting.md` entry (Anticipated - the private-repo
    clone needs the SSH access set up in the entry below, so a machine
    without that yet will hit it). Updated `CHANGELOG.md` and
    `docs/design/README.md`'s index.
  - **Verified for real, same conversation, on both real Windows
    machines - genuinely closed out.** First Pester run on the Dell
    Desktop found two real bugs (both unrelated to the core feature): 5
    new `Install-GwbNvimConfig` tests threw `RuntimeException: No mock
    for command 'Get-Command' matched the call` (a `Get-Command` mock
    filtered to `"nvim"` only, but the function also calls `Get-Command
    git` - Pester needs an explicit match per call once any mock is
    registered for a command, no implicit fallback to the real cmdlet);
    and `Repair.Tests.ps1`'s `"cleans up its ephemeral temp directory
    even when healthy"` test - a genuinely pre-existing, unrelated bug -
    never actually established healthy state, so it hit real drift and
    hung Greg's actual terminal on the real, unmocked `Read-Host` for
    ~2 minutes. Both fixed (PR #8, `43f83b3`): the mock got a default
    fallback covering both `Get-Command` lookups, and the repair test
    now sets up the same healthy state its neighbor test uses.
    Re-ran clean: `Tests Passed: 114, Failed: 0` in 5.26s (down from
    133.66s on the hung run). Then a real `gwb.ps1 restore developer`
    reported `[OK] nvim-config updated: C:\Users\ggreg\AppData\Local\nvim`
    (not "cloned" - it correctly detected Greg's pre-existing manual
    LazyVim clone at that path and just `git pull`ed it in place,
    exactly the "already set up" case working as designed), and Greg
    confirmed `nvim` opens cleanly into a working LazyVim setup.
    **Independently reconfirmed on the ThinkPad too**, same day - Greg
    pulled and restored there on his own (not walked through
    step-by-step) and confirmed Neovim + LazyVim work fine there as
    well. Both Windows machines verified, not just one.
  - Working tree: `lib/profile.ps1`, `lib/packages.ps1`,
    `profiles/{default,developer,server}/packages.txt`,
    `tests/Profile.Tests.ps1`, `tests/Repair.Tests.ps1`,
    `tests/Dispatcher.Tests.ps1`, `docs/design/nvim-lazyvim.md`,
    `docs/design/README.md`, `docs/troubleshooting.md`, `CHANGELOG.md`,
    and this file - all merged to `master` via PR #7 and PR #8, both
    confirmed working live on both machines. **Nothing queued** from
    this feature. (A separate, cross-session note worth knowing about:
    `nvim-config` itself is still essentially the stock LazyVim starter
    template with no real personal customization yet, and there's an
    open question - not GWB's to resolve alone - about `lazy-lock.json`
    drift if Greg runs `:Lazy update` on one machine without pushing
    before the next restore's `git pull` elsewhere; see the
    `claude-memory` repo's `project_gwb.md` for the full detail if this
    comes up.)

- **Session (2026-08-29, same conversation as the PSFzf fix below,
  continued on the real ThinkPad): set up SSH auth to GitHub for the
  first time on this machine, and moved the dev checkout from
  `C:\Users\ggreg\GWB` to `C:\Users\ggreg\Projects\GWB` at Greg's
  request.** Not a bug session - a real infrastructure change, verified
  end to end on real hardware.
  - **SSH key setup**: generated an ed25519 key for `ggregoro@gmail.com`
    (`ssh-keygen -t ed25519`), registered it at
    https://github.com/settings/keys. Two real snags along the way,
    both resolved without guessing: (1) `Set-Service`/`Start-Service` on
    `ssh-agent` needs an elevated PowerShell window - the service is
    disabled by default on a stock Windows 11 install and a non-admin
    shell just gets "Access is denied"; (2) the plain interactive
    `ssh -T git@github.com` host-key-confirmation prompt
    (`(yes/no/[fingerprint])`) didn't reliably accept typed input in
    this terminal - chased down via `ssh-keyscan.exe` first (a dead
    end: this machine's copy is too old to negotiate GitHub's preferred
    `sntrup761x25519-sha512@openssh.com` KEX algorithm and fails
    silently with no fallback, confirmed via `-v` verbose output, even
    though the *real* `ssh.exe` binary connects fine), then fixed
    directly with `ssh -o StrictHostKeyChecking=accept-new` instead,
    which accepts-and-records a first-time host key without needing the
    interactive prompt at all. Confirmed genuinely working via a live
    `Hi ggregoro! You've successfully authenticated...` response - not
    just "should work."
  - **Moved the checkout**: `git status` confirmed a clean tree first,
    then `Move-Item C:\Users\ggreg\GWB -> C:\Users\ggreg\Projects\GWB`
    (Greg's call, to live alongside other projects under the existing
    `proj` shortcut's folder rather than directly under the user
    profile). One real gotcha hit live: the first `Move-Item` attempt
    failed with "item is in use" because the shell's current directory
    was still inside the folder being moved (a normal Windows file-lock
    behavior, not a GWB bug) - fixed by `cd`-ing to the parent first.
    Switched `origin` from HTTPS to the SSH URL
    (`git@github.com:ggregoro/GWB.git`) before the move, so it came
    along automatically as part of the folder's own `.git` config.
  - **Re-ran `gwb.ps1 restore developer` from the new location** -
    critical, and directly informed by this same session's earlier
    `Set-GwbManagedBlock` bug hunt: this is exactly the self-registration
    path problem documented at length in the entries below (whichever
    location `restore` runs from gets baked into the `# >>> GWB self >>>`
    block), so skipping this step would have left `gwb`/tab-completion
    silently pointing at the now-nonexistent `C:\Users\ggreg\GWB`.
    **Verified for real, not just trusted the "OK" message** (the same
    healthy skepticism this session's earlier `Set-GwbManagedBlock` bug
    now warrants permanently) - `Select-String -Path $PROFILE -Pattern
    "GWB self"` confirmed the block genuinely rewrote to
    `C:\Users\ggreg\Projects\GWB` in all three places (completions
    dot-source path, `Register-GwbCompletions -GwbRoot`, and the `gwb`
    function itself), then a **fresh** PowerShell window confirmed
    `gwb version` and `Get-Command gwb -All` (a single clean `Function`
    registration, no stale duplicate) both work correctly from the new
    path.
  - Updated the Test environments section above with the new path, the
    SSH remote, and the real gotchas hit, so a future session doesn't
    assume `C:\Users\ggreg\GWB` still exists on this machine. Nothing in
    `lib/`/`profiles/` needed to change - this was a pure
    infrastructure/location change, no code involved. **Nothing
    queued** from this part of the session; the still-open OneDrive-sync
    self-registration design fix (entry below) remains open and is now
    *more* relevant given the path just changed again - worth keeping in
    mind next time that's picked up.

- **Session (2026-08-29, cloud session, no `pwsh` available): fixed a
  real, user-reported PSFzf load failure — genuinely distinct from the
  OneDrive-sync `$PROFILE` bug below, not a recurrence of it.** Greg
  reported new errors on shell startup; the error text (`Import-Module:
  ... Could not load file or assembly '...\PSFzf.dll'. An Application
  Control policy has blocked this file. (0x800711C7)`, cascading into
  `Set-PsFzfOption` also failing, plus "Loading personal and system
  profiles took 18454ms") is unrelated to the 2026-08-21/23 stale-path
  bug below — confirmed by reading the actual error rather than
  assuming a recurrence, since on the surface both are "errors on every
  new PowerShell window." Root cause here: Windows Defender Application
  Control / Smart App Control / a similar endpoint-security policy is
  blocking `PSFzf.dll` itself from loading at the code-integrity level
  — `PSFzf` installed fine (`Get-Module -ListAvailable` sees it), the
  policy blocks the *load*, not the install. This is a machine/org
  security decision, not a GWB or PSFzf bug, and explicitly not GWB's
  to work around — same stance already established for IPBan in
  `docs/PROJECT.md`'s Non-Goals.
  - **Fixed**: wrapped `Import-Module PSFzf` (and the `Set-PsFzfOption`
    call that depends on it) in a `try`/`catch` in all three profiles'
    `profile-snippet.ps1`, mirroring the existing PSReadLine guard
    already in the same files for a similar "can fail in some
    environments, fail quietly" case. A blocked policy now silently
    skips `Ctrl+f`/`Ctrl+r` fuzzy search for that session instead of
    printing errors (and adding load time) on every single startup.
  - Added a new `docs/troubleshooting.md` entry (Confirmed) with the
    real error text, root cause, and what to actually do about it (get
    an exception from whoever manages the Application Control policy —
    still outside GWB's control). Updated `CHANGELOG.md` and
    `docs/DOCS_CHANGELOG.md`.
  - **Same-session follow-up, prompted by Greg asking whether the fix
    would "just break again": clarified this is a different failure
    class from the OneDrive-sync bug (static template code baked into
    every future restore, not a per-machine path that can be
    clobbered), then went further and restored the actual feature, not
    just silenced the errors.** Greg asked how to be sure `fzf` itself
    (not just PSFzf) actually works, since `Ctrl+r` still didn't. Walked
    him through a real, isolated test independent of PSFzf/PSReadLine:
    `fzf --version` (confirms the binary loads at all) then
    `Get-ChildItem -Name | fzf` (confirms the real interactive UI
    launches and works). **Greg ran it and sent a real screenshot**:
    `fzf`'s interactive picker opened cleanly over a real directory
    listing (22/22 items, fuzzy filter prompt, `.cache` highlighted) —
    genuine, first-hand confirmation that the signed `fzf.exe` binary is
    completely unaffected by the Application Control policy; only the
    `PSFzf.dll` module assembly is blocked.
  - **Built a real fallback on the strength of that confirmation**: when
    `PSFzf` fails to load but `fzf.exe` is on `PATH`, all three
    `profile-snippet.ps1` files now wire up `Ctrl+r`/`Ctrl+f` by hand via
    `Set-PSReadLineKeyHandler`, shelling out to `fzf.exe` directly
    instead of through the blocked DLL — `Ctrl+r` fuzzy-searches
    PSReadLine's history file and replaces the current line with the
    selection (`--tac` for most-recent-first, matching normal
    reverse-search feel); `Ctrl+f` fuzzy-searches the current directory
    (non-recursive, deliberately simpler than PSFzf's own
    recursive/provider-aware search — a fallback, not a full
    reimplementation) and inserts the selection at the cursor. Updated
    `docs/troubleshooting.md` and `CHANGELOG.md` to describe the
    fallback, not just the quiet-failure fix.
  - **Real verification attempt (same session, PR #1 opened and merged
    to `master`) surfaced a second, genuinely deeper bug — not in the
    PSFzf fix at all, in `Set-GwbManagedBlock` itself.** Walked Greg
    through `git pull origin master` + `gwb.ps1 restore developer` on
    his real machine; it reported full success (`[OK] Profile updated`)
    but a fresh window still showed the exact old, unwrapped PSFzf
    block. Root-caused over several rounds of real diagnostic output
    (not guessed at) rather than assuming a recurrence of anything
    already-documented: `Get-Content $PROFILE` dumped the live file and
    a `-match [regex]::Escape(...)` boolean check (screenshotted, to
    rule out the chat's own rendering possibly eating `<<<` as an HTML
    tag) confirmed definitively - his `$PROFILE`'s end marker had been
    silently corrupted to `# <<< GWB managed block <` (missing its
    trailing `<<`) at some unknown prior point, same for
    `# <<< GWB self <`. `Set-GwbManagedBlock`'s regex replace requires
    finding the *exact* end marker text; with it malformed, the replace
    matched nothing, silently wrote the identical content straight back,
    and `Write-Ok` printed "updated" regardless - a bug that had
    apparently been making every restore on this machine a complete,
    invisible no-op for an unknown length of time, never caught because
    nothing ever verified the replace actually changed anything.
  - **Fixed both bugs this exposed, not just Greg's one broken file**:
    `Set-GwbManagedBlock` (`lib/profile.ps1`) now detects a start marker
    with no matching end marker and fails loudly (`[FAIL] ... not
    touching it`) instead of silently no-op'ing. Also switched its
    `-replace` from a plain string replacement (which .NET parses as a
    regex substitution template, where `$1`/`$&`/`$_` etc. are special -
    a real corruption risk now that snippet content legitimately
    contains `$` via this session's own `$_.Trim()` fallback code, not
    hypothetical) to `[regex]::Replace(...)` with a `MatchEvaluator`
    scriptblock, which treats the replacement as fully literal text.
    Added two new Pester tests (`tests/Profile.Tests.ps1`) covering both
    regressions directly. Documented the whole failure mode in a new
    `docs/troubleshooting.md` entry and in `CHANGELOG.md`.
  - **Verified for real, same conversation, on Greg's actual machine —
    genuinely closed out, not just code-reviewed.** Walked him through
    the real repair end to end: backed up `$PROFILE`
    (`$PROFILE.pre-marker-fix-backup`), manually patched the two
    corrupted end markers with a negative-lookahead `-replace` (guarded
    so it only touches a marker with *exactly* one trailing `<`, safe to
    run even if a marker were already correct), confirmed both fixed via
    an unambiguous `-match [regex]::Escape(...)` boolean check
    (screenshotted - `True`/`True`), then `git pull origin master` +
    `gwb.ps1 restore developer`. This time `Get-Content $PROFILE |
    Select-String -Pattern "GwbPsFzfLoaded"` (screenshotted) confirmed
    the new code genuinely landed - the block actually changed, not
    another silent no-op. **Greg then opened a real new terminal and
    confirmed directly**: no more PSFzf/Application-Control errors, and
    `Ctrl+r`/`Ctrl+f` both work via the fzf.exe fallback. Both PR #1
    (the PSFzf fallback) and PR #2 (the `Set-GwbManagedBlock` fix) are
    merged to `master` and confirmed working end to end on real
    hardware - not just "should work."
  - Pester suite (`Invoke-Pester -Path tests/`, confirming the two new
    regression tests actually pass) was **not** run this session - the
    live-machine verification above covered the actual user-facing
    symptom directly, and Greg's time was better spent confirming that
    than re-running a suite this session has no way to watch execute.
    Worth running next time `lib/` changes for any other reason, just
    not flagged as urgently open on its own.
  - **Still open, not root-caused**: *how* did the end marker get
    corrupted in the first place? Not investigated this session -
    flagged for later if it recurs on either machine (worth checking
    first: whether it happened during one of the many prior sessions
    that hand-edited `$PROFILE` directly, e.g. the personal `proj`/
    `sys32` additions or the OneDrive-conflict-copy incidents
    documented in the entries below).
  - Working tree: `profiles/{default,developer,server}/
    profile-snippet.ps1`, `lib/profile.ps1`, `tests/Profile.Tests.ps1`,
    `docs/troubleshooting.md`, `CHANGELOG.md`, `docs/DOCS_CHANGELOG.md`,
    and this file - all merged to `master` via PR #1 and PR #2, both
    confirmed working live. **Nothing queued from this session** beyond
    the open "how did it corrupt" curiosity above, on top of the
    still-open OneDrive-sync `$PROFILE` design fix from the entry
    directly below (unrelated - that one's about the self-registration
    *path*, not marker corruption).

- **Session (2026-08-23, real Windows 11 machine — `PC-F2C15AL`): the
  exact same stale "GWB self" `$PROFILE` bug from 2026-08-21
  recurred, fixed the same way.** Greg reported the identical error
  pair on every new PowerShell 7.6.5 window — dot-sourcing
  `C:\Users\ggreg\AppData\Local\GWB\lib\completions.ps1` failing (file
  not found) cascading into `Register-GwbCompletions` unrecognized —
  this time from line 83/84 of
  `...\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1`.
  - **Confirmed directly, not assumed, that it's the same root cause**:
    `C:\Users\ggreg\AppData\Local\GWB` still doesn't exist on this
    machine, and the `# >>> GWB self >>>` block was again pointing at
    it instead of the real dev checkout `C:\Users\ggreg\GWB`. **Did
    not** track down what re-triggered it this time (unlike the
    2026-08-21 entry below, which pinned the cause to a restore having
    once run from the `install.ps1`/`$env:LOCALAPPDATA\GWB` location) —
    worth remembering this can recur from *any* `gwb.ps1 restore`
    invoked from somewhere other than `C:\Users\ggreg\GWB` (an
    `irm | iex` re-run of `install.ps1`, a restore from a fresh clone
    elsewhere, etc.), and there's currently no guard against it — every
    restore unconditionally self-registers to its own invocation path.
    If this keeps recurring, worth considering a real fix (e.g. pin
    self-registration to a known-good dev-checkout path, or warn if
    invoked from an unexpected location) rather than just re-fixing it
    by hand each time.
  - **Fixed the same way, with Greg's confirmation before rewriting his
    live `$PROFILE`**: ran `pwsh -NoLogo -NoProfile -Command
    "& './gwb.ps1' restore developer"` from `C:\Users\ggreg\GWB`.
    Completed cleanly (`-NoProfile` avoided even the one-time
    re-triggering of the broken profile's own errors that the
    2026-08-21 session saw). Confirmed directly afterward, by reading
    the profile file back, that the `# >>> GWB self >>>` block now
    reads `C:\Users\ggreg\GWB` in all three lines.
  - **Confirmed by Greg directly**, in a real new terminal window: no
    errors, matching this session's own fix.
  - **Follow-up, same session: found the real root cause of the
    recurrence — this is a two-machine OneDrive sync conflict, not a
    one-off.** Checked `...\OneDrive\Documents\PowerShell\` directly
    and found a OneDrive conflict copy,
    `Microsoft.PowerShell_profile-PC-F2C15AL.ps1` (OneDrive's standard
    "couldn't reconcile with the cloud" naming), **born 2026-08-23
    01:08** — i.e. created *this morning*, containing the *correct*
    2026-08-21 fix (pointing at `C:\Users\ggreg\GWB`). That means
    OneDrive detected a conflicting cloud write, preserved this
    machine's good copy under the conflict name, and let the *other*
    (broken) version become the live file. Ruled out a scheduled task
    as an alternative cause first (`Get-ScheduledTask` shows only
    OneDrive's own standard sync tasks, nothing GWB-related). **Greg
    confirmed directly**: he uses the same OneDrive account on his
    second Windows machine (the build-26100 laptop from the
    2026-08-21 second-machine session above), and that machine also
    has `Documents` OneDrive-redirected — so both machines' `$PROFILE`
    is the *same physical synced file*. Every `gwb.ps1 restore` on
    either machine unconditionally bakes in its own local invocation
    path into the shared `# >>> GWB self >>>` block
    (`Set-GwbManagedBlock`/`lib/completions.ps1`'s self-registration
    logic, `lib/profile.ps1`) — so whichever machine restores *last*
    silently breaks the other one the next time OneDrive syncs. This
    is a real, structural GWB design gap (self-registration assumes
    `$PROFILE` is local-only, which OneDrive Known Folder Move
    violates on this household's setup), not something either machine
    did wrong.
  - **Not yet fixed at the design level — genuinely queued for the
    next session on the second machine**, since fixing it needs
    information only obtainable there: what path GWB is actually
    installed/cloned to on that laptop (a dev checkout like this
    machine's `C:\Users\ggreg\GWB`, or the `install.ps1`/
    `$env:LOCALAPPDATA\GWB` path — the 2026-08-21 second-machine
    session didn't record which). Leading fix candidate discussed with
    Greg: make the `# >>> GWB self >>>` block resolve its own GWB root
    **dynamically at each `$PROFILE` load** (check a short list of
    known candidate paths on disk, e.g. `C:\Users\ggreg\GWB` and
    `$env:LOCALAPPDATA\GWB`, and use whichever actually exists locally)
    instead of hardcoding whatever path `restore` last ran from — that
    way the shared synced file works correctly no matter which machine
    wrote it last, without having to fight OneDrive's Documents
    redirection (Greg wants to keep that, not disable it). Needs a
    `lib/profile.ps1`/`lib/completions.ps1` code change plus updated
    Pester coverage for the new resolution logic, tested for real on
    *both* machines before calling it done.
  - Working tree: only this documentation update touches the repo this
    session — the immediate fix was a live `$PROFILE` rewrite via
    `gwb.ps1 restore`, same as 2026-08-21, not a code change. **The
    OneDrive-sync design fix above is queued for next session, to be
    picked up on the second machine.**

- **Session (2026-08-21, real Windows 11 machine — `PC-F2C15AL`,
  the primary dev machine, follow-up): fixed a real, user-reported
  `$PROFILE` breakage — stale "GWB self" block pointing at a
  since-removed install directory.** Greg reported two errors on every
  new `pwsh` window: dot-sourcing
  `C:\Users\ggreg\AppData\Local\GWB\lib\completions.ps1` failed (file
  not found), which cascaded into `Register-GwbCompletions` also being
  unrecognized.
  - **Root cause, confirmed directly rather than guessed**:
    `C:\Users\ggreg\AppData\Local\GWB` (the `install.ps1` install
    location, `$env:LOCALAPPDATA\GWB`) doesn't exist on this machine at
    all — checked directly. The real dev checkout has always been
    `C:\Users\ggreg\GWB`. The `# >>> GWB self >>>` block in `$PROFILE`
    gets rewritten by *every* `gwb.ps1 restore` to point at wherever
    that particular `gwb.ps1` was invoked from (documented already in
    the 2026-08-11 install.ps1-verification entry below as expected
    behavior) — at some point a restore ran from the `LOCALAPPDATA`
    install, and that install directory was later removed without a
    follow-up restore from the dev checkout to re-point `$PROFILE` back.
    The rest of `$PROFILE` (the `# >>> GWB managed block >>>` aliases/
    mise/etc.) was untouched and fine — only the self-registration tail
    was broken.
  - **Fixed**: ran `gwb.ps1 restore developer` explicitly from
    `C:\Users\ggreg\GWB` (Greg confirmed before running, since it
    rewrites his live `$PROFILE`). The broken-profile errors printed
    once more during that very invocation (expected — `pwsh -Command`
    still loads the existing broken profile before running anything),
    then the restore completed cleanly and rewrote both the `$PROFILE`
    managed block and the `gwb` self block to `C:\Users\ggreg\GWB`.
  - **Verified for real**: a fresh `pwsh -NoLogo` process (no `-Command`
    this time, so nothing masked residual errors) loads with **zero**
    errors; `gwb version` reports `1.0.0` correctly; `Get-Command gwb
    -All` resolves cleanly to the function with no leftover stale
    registration. `ll` output looked empty in this same check, but
    that's the same non-tty `eza`/automation-tooling artifact already
    documented at length elsewhere in this file (2026-08-21 second-
    machine and Windows-Terminal-restart entries) — not a new bug,
    flagged for Greg to eyeball in a real terminal.
  - **Confirmed by Greg directly, in a real new terminal window**: no
    error message, profile loads clean — "Loads profile in 1292ms."
    Closes this out with genuine end-user confirmation, not just an
    automated check.
  - **Same-session finding, worth noting for future path assumptions**:
    this machine's `Documents` is now OneDrive-redirected too (`
    $PROFILE` resolves under `...\OneDrive\Documents\PowerShell\...`),
    and PowerShell itself is at `7.6.5` now (was `7.6.4` as of the
    2026-08-13 sessions) — both updated in the Test environments
    section above.
  - Working tree: only this documentation update touches the repo —
    the actual fix was a live `$PROFILE` rewrite via `gwb.ps1 restore`,
    not a code change. **Nothing queued.**

- **Session (2026-08-21, real Windows 11 machine, follow-up): installed
  `cpufetch` for real, and caught/fixed a real mistake doing it.** Greg
  reported `fastfetch` had installed (from the earlier dry-run's "check
  what's pending" implication) but `cpufetch` hadn't, and asked to run
  it. First attempt ran `gwb.ps1 restore default` for real to get
  `cpufetch` installed — worked (`Dr-Noob.cpufetch` v1.07, confirmed via
  `cpufetch --version` and a real `cpufetch` run showing this machine's
  actual CPU, an Intel i5-8365U), but as a real side effect also
  switched this laptop's live `$PROFILE` from `developer` to `default`,
  silently dropping the `mise` activation and `far` wrapper `developer`
  adds — the exact class of mistake this project's own 2026-08-13 yazi
  verification session already documented and deliberately avoided
  (calling `Install-GwbYaziConfig` directly instead of a full `restore`
  for the same reason). Caught immediately after, not left for a future
  session to find: re-ran `gwb.ps1 restore developer` for real,
  confirmed via a fresh `pwsh` process that `far`/`mise` are back
  (`Get-Command far -All`/`mise -All` both resolve to `Function`, `mise
  --version` runs) and `cpufetch` still works globally (it's a winget
  install, not profile-scoped). **Lesson worth remembering for next
  time a single package needs installing outside the active profile**:
  reach for `winget install` directly, or `Install-GwbPackage` in
  isolation, not a full `restore` of a different profile than the one
  actually live on the machine.
  - Working tree otherwise unchanged from the entry below at the time —
    this entry records the real package-install/profile-restore side
    effect, not a code change. (Greg reviewed and approved the pending
    edits from the entry below shortly after; see its closing note for
    the commit.)

- **Session (2026-08-21, real Windows 11 machine, follow-up): added
  `fastfetch`/`cpufetch` to `default` and `eza --hyperlink` to the
  shared alias config, ported from GLB. Reviewed and committed/pushed
  as [`c3752ef`](https://github.com/ggregoro/GWB/commit/c3752ef26b49dba5d28beb87d428b72e5d461036).**
  - **`fastfetch`/`cpufetch` added to `profiles/default/packages.txt`**
    (system-info banner tools, mirroring GLB's own `default` profile).
    Winget IDs confirmed directly via `winget search` rather than
    assumed — `fastfetch`'s real ID is `Fastfetch-cli.Fastfetch` (note
    the casing differs from the `fastfetch-cli.fastfetch` first
    suggested; winget IDs matched case-sensitively against the override
    table elsewhere in this project, e.g. `BurntSushi.ripgrep.MSVC`, so
    used the exact casing winget reports), `cpufetch`'s is
    `Dr-Noob.cpufetch` — both single, unambiguous native winget
    packages, no per-distro-style override complexity like GLB
    sometimes hits. Added to `_GWB_PACKAGE_OVERRIDES`
    (`lib/packages.ps1`) following the existing pattern. Only
    `default` per Greg's explicit ask — not ported to `developer`/
    `server`.
  - **`eza --hyperlink` added to `ll`/`la` (not plain `ls`) in all three
    profiles' `profile-snippet.ps1`**, mirroring GLB's own 2026-08-18
    change exactly: OSC 8 hyperlinks (Ctrl-click to open a file) on the
    long-listing-style aliases only, `ls` left untouched. One real
    divergence from GLB worth recording: GLB's `la` is `-la` (a true
    long listing); GWB's `la` has always been `-a` only, no `-l` — the
    "mirror the named aliases GLB touched (`ll`/`la`), not `ls`" reading
    was used rather than "mirror flag-for-flag," since GWB has no
    separate `l` alias and this project has no `--git` flag on eza at
    all (never added it, unlike GLB) so there was no `--git`-preservation
    concern to carry over either. Added a comment above the block in all
    three files explaining the `ll`/`la`-only choice and pointing back
    at GLB's change for context.
  - **Verified so far**: all four edited files parse clean
    (`[System.Management.Automation.Language.Parser]::ParseFile`), full
    Pester suite still 103/103, and `gwb.ps1 restore default --dry-run`
    resolves both new packages correctly (`fastfetch` reports "Already
    installed" - it's already on this machine from earlier ad hoc use;
    `cpufetch` correctly previews `Would install: cpufetch ->
    Dr-Noob.cpufetch`). **`cpufetch` itself was installed for real
    immediately after, same session** — see the entry above (out of
    chronological order in this file: that entry was written first but
    describes work that happened after this one). **Still not verified
    for real**: no live `ll`/`la` hyperlink check in a real terminal
    (this session's own automation tooling still can't confirm OSC 8
    escape sequences render/Ctrl-click visually, the same class of gap
    the 2026-08-13 session's yazi work hit) — flagged for Greg to
    eyeball directly. Greg reviewed this change and approved committing
    it; pushed as
    [`c3752ef`](https://github.com/ggregoro/GWB/commit/c3752ef26b49dba5d28beb87d428b72e5d461036).

- **Session (2026-08-21, real Windows 11 machine, follow-up): confirmed
  the flagged Windows Terminal restart, closing out the one open item
  from earlier today.** Greg closed and fully reopened Windows Terminal
  (not just a new tab) and confirmed PowerShell 7 loads as the default
  profile — the in-memory-state clobbering risk the entry below flagged
  did not recur. Independently re-verified from this session too:
  `defaultProfile` in the real `settings.json` resolves to the
  auto-detected `"PowerShell"` entry (`source:
  Windows.Terminal.PowershellCore`); a fresh `pwsh` process (registry
  PATH refresh and the test command combined into one call, per this
  same session's own methodology note below) confirms `$PROFILE`
  resolves correctly under the OneDrive-redirected path, loads with no
  errors, `Get-Command ll -All`/`ls -All` each resolve to `Function`
  only (no built-in-alias regression), and `rg`/`yazi --version`/`far`/
  `gwb version` all work.
  - **A new instance of the same automation-tooling artifact already
    documented below, not a real bug**: `eza`/`ll` again produced empty
    output when invoked through this session's own non-interactive
    PowerShell tool calls — this time reproduced even via `-File`
    (previously noted as a workaround), and isolated further: bare
    `eza`/`eza -1` are silently empty specifically in this tool's
    non-tty automation context, while `Get-ChildItem` against the exact
    same real directory and `eza --version` (needs no terminal-size
    detection) both work fine. Points at eza's own terminal-width/tty
    detection under non-interactive invocation, not a `gwb`/profile bug
    — flagged for Greg to eyeball `ll` in a real terminal to be certain,
    since this environment still can't visually confirm it. Nothing in
    the repo changed for this.
  - Working tree still clean (verification-only). **Nothing queued.**

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
