# GWB Documentation Changelog

This changelog records milestones in the GWB *project itself* — docs
structure, GitHub/dev-environment setup — distinct from the root
[`CHANGELOG.md`](../CHANGELOG.md), which tracks `gwb`'s actual
feature/code changes. Mirrors GLB's own `docs/DOCS_CHANGELOG.md`.

## [Unreleased]

(none since the screenshots/README session below)

---

## 2026-08-15 (live-machine session)

### Documentation

- Added `docs/images/` (`fastfetch-banner.png`, `yazi-file-browser.png`
  — real screenshots from Greg's own machine) and a new `README.md`
  Screenshots section referencing them. Caught and fixed two real
  inaccuracies while writing captions: `fastfetch` and `ranger` both
  appeared in the screenshots' command history/output but neither is
  actually a GWB-managed package (confirmed via `grep` across every
  profile's `packages.txt` and `_GWB_PACKAGE_OVERRIDES`) — captions
  worded to not imply GWB installs either. Also fixed a real,
  longer-standing gap: `README.md`'s "Why GWB?" intro, Features list,
  and Profiles table had never been updated across any of the three
  separate sessions that added `yazi` to GWB — now mention it, its
  `git.yazi` plugin, and its `file` MIME-detection dependency.

---

## 2026-08-13 (live-machine session)

### Documentation

- Added two new `docs/troubleshooting.md` entries (both Confirmed):
  Starship's `Scanning current directory timed out` warning, and
  PowerShell always starting in `C:\Windows\System32`. Updated
  `docs/ARCHITECTURE.md`'s `profile.ps1` row to mention
  `Install-GwbStarshipConfig`, and `README.md`'s test count (88 → 93).
  See `CHANGELOG.md` for the two features themselves.

---

## 2026-08-12 (live-machine verification session)

### Documentation

- Bumped `VERSION` from `0.1.0` to `1.0.0` — `docs/ROADMAP.md`'s
  Version 1.0 milestone had been complete since 2026-08-11, but the
  file itself was never updated alongside it, so `gwb.ps1 version`/
  `help` were still printing the old number. Updated
  `docs/PROJECT.md`'s Release Strategy and `README.md`'s Status section
  to match, plus `CHANGELOG.md` with the actual fix.
- Added a `far` function to `developer`/`server`'s
  `profile-snippet.ps1` — found while walking through how to actually
  launch GWB's add-on programs live: Far Manager installs as a
  registered GUI app (Start Menu shortcut) with no `PATH` entry, unlike
  its CLI tools which winget shims onto `PATH` automatically (`fresh`
  confirmed working bare already). Updated `CHANGELOG.md` with the
  actual fix.

### Development Environment

- Ran a full live verification pass on the real Windows 11 machine
  with no code changes intended going in: re-ran the Pester suite,
  walked through `help`/`version`/`info`/`profiles`/`export`/`diff`
  against the real machine, and did a real `gwb.ps1 restore developer`
  (idempotent, confirmed via a second run) — this surfaced both real
  gaps above along the way, neither of which was previously flagged as
  an open bug.
- Confirmed Far Manager's real install location
  (`Program Files\Far Manager\Far.exe`) via its registry Uninstall
  key's `InstallLocation` before hardcoding the path, rather than
  guessing from the Start Menu shortcut alone.
- Investigated an apparent `ll` regression (a `Get-ChildItem`-style
  table appeared after the `ls` fix) that turned out to be a
  misdiagnosis, not a bug: `eza`'s `-h` flag means "add a header row,"
  not "human-readable" like GNU `ls` — `eza -lah` was correctly
  rendering its own long/table view. Caught by reading `eza --help`
  directly instead of assuming GNU `ls` semantics carried over.

## 2026-08-11 (real-hardware `ls` bug report)

### Documentation

- Added `docs/troubleshooting.md`'s new first entry, "`ls` shows the
  plain PowerShell table, not `eza`'s icon output" — a real bug Greg
  hit and reported live via screenshots (`ll`/`la` worked, bare `ls`
  fell back to `Get-ChildItem`'s default table). Updated `CHANGELOG.md`
  with the actual fix.

### Development Environment

- Root-caused with a synthetic repro before touching real code: a
  throwaway `Set-Alias`/`function` pair with the same name, confirmed
  the alias always wins even when `Get-Command -All` shows both
  registered. Fixed all three profiles' `profile-snippet.ps1`
  (`Remove-Item -Path Alias:ls -Force` before defining the function).
  Verified for real: restored `default`, dot-sourced the live
  `$PROFILE`, confirmed `Get-Command ls -All` now shows only the
  function and bare `ls` correctly invokes `eza`; confirmed
  idempotency across two restores; full Pester suite still 88/88.

---

## 2026-08-11 (real-hardware installer verification)

### Documentation

- Updated `docs/design/installer.md`'s Status/Verification sections to
  record the real Windows-hardware run (a cloud session had built
  `install.ps1` and `docs/design/installer.md`/`b125063`/`3d1727c`/
  `a4e5ad7` without ever executing anything — no `pwsh` there at all).
  Updated `docs/ROADMAP.md`'s Version 1.0 to mark it verified and
  `CHANGELOG.md` with the real bug found and fixed.

### Development Environment

- Isolated a real `Invoke-Expression`/`*>&1` capture gotcha with a
  minimal repro before touching the test file — confirmed it doesn't
  affect real interactive `irm | iex` usage, only the test's own
  output-capture technique.

---

## 2026-08-11 (continued once more again)

### Documentation

- Added `docs/design/pester-test-suite.md` — documents the real
  technical questions verified before building (which Pester version,
  whether `Mock` can intercept an external `.exe`, whether
  dispatcher-level dot-sourcing actually works) and the real bug the
  suite caught on its first run. Updated `docs/ARCHITECTURE.md`'s
  Testing section (previously "no automated test suite yet") and its
  project-tree diagram, `docs/CODING_STANDARDS.md`'s stale project
  tree and Git Workflow step, `CONTRIBUTING.md` with how to run the
  suite, `docs/ROADMAP.md`'s Version 1.0 goals (most were already done
  but unmarked), and `README.md`/`CHANGELOG.md` with the actual
  addition.

### Development Environment

- Verified Pester's real mocking mechanics (external-command `Mock`,
  `$PROFILE` override safety, dispatcher-level dot-sourcing with
  `Mock` still active) in isolated scratch probe scripts before
  writing any real test file, same discipline used for
  `TabExpansion2`/`Register-ArgumentCompleter` earlier this project.

---

## 2026-08-11 (continued still further)

### Documentation

- Added `docs/reference/ipban-manual-install.md` — the first real
  content in `docs/reference/`. Updated `docs/design/server-profile.md`
  to record the final, permanent "keep manual" decision (superseding
  its original "revisit once an extras mechanism exists" note),
  `docs/PROJECT.md`'s Non-Goals with a durable principle-level
  statement (not just an IPBan-specific note), and
  `docs/ROADMAP.md`/`README.md`/`CHANGELOG.md` to match.

### Development Environment

- Fetched and read IPBan's real, current install script directly
  (`Invoke-WebRequest`, not an AI-summarized fetch) before deciding
  anything — confirmed it needs Administrator elevation and installs a
  persistent Windows Service, rather than relying on the earlier
  research summary from the `server-profile.md` round.

---

## 2026-08-11 (continued once more still)

### Documentation

- Updated `docs/design/export-diff-repair.md` and
  `docs/design/psgallery-extras.md` to record the modules.txt
  drift-tracking follow-up as closed, cross-linked between the two
  docs. Updated `docs/ROADMAP.md` and `CHANGELOG.md` with the actual
  feature addition.

---

## 2026-08-11 (continued yet again)

### Documentation

- Added `docs/design/psgallery-extras.md` — documents the real
  PSGallery-untrusted-repository risk (verified `-Force` suppresses
  it), the three decisions made directly with Greg (scope to all
  profiles, PSReadLine config-only, flat `modules.txt`), and the real
  `-ErrorAction SilentlyContinue` bug caught during verification.
  Updated `docs/ROADMAP.md`'s Version 0.4 to fully complete and
  `CHANGELOG.md` with the actual feature addition.

### Development Environment

- Verified `Set-PsFzfOption`'s exact parameter names via `(Get-Command
  Set-PsFzfOption).Parameters` before writing the profile-snippet
  config, rather than guessing from memory.

---

## 2026-08-11 (continued once more)

### Documentation

- Added `docs/design/shell-completions.md` — documents three real
  technical questions verified before building (how a `.ps1` script
  becomes callable by bare name on Windows, whether
  `Register-ArgumentCompleter` works for a plain wrapper function,
  whether a completer scriptblock captures its enclosing function's
  parameters without `.GetNewClosure()`), plus the decision to wire it
  into every restore automatically. Updated `docs/ROADMAP.md`'s
  Version 0.5 to fully complete and `CHANGELOG.md` with the actual
  feature addition.

### Development Environment

- Verified `TabExpansion2`/`Register-ArgumentCompleter` mechanics
  empirically (position-based AST completion, `.GetNewClosure()`
  requirement) in isolated test sessions before writing any real code,
  rather than assuming how PowerShell's completion engine behaves.

---

## 2026-08-11 (continued further)

### Documentation

- Added `docs/design/from-manifest.md` — found and documented that
  `restore --from-manifest <path>` needed no new logic at all,
  `Invoke-GwbApplyProfile` already accepted an arbitrary path. Updated
  `docs/ROADMAP.md`'s Version 0.6 to fully complete and `CHANGELOG.md`
  with the actual feature addition.

---

## 2026-08-11 (continued)

### Documentation

- Added `docs/design/export-diff-repair.md`, scoped and built in one
  pass: `export`/`diff`/`repair`/`restore --from-snapshot`, scoped to
  packages known to some profile (winget has no manual-vs-dependency
  tracking at all — a harder real gap than any GLB package manager
  faced, confirmed by checking `winget list --help` directly and
  seeing 80 unfiltered entries mixing OEM bloat with real tools).
  Updated `docs/ROADMAP.md`'s Version 0.6 from Planned to Completed
  and `CHANGELOG.md` with the actual feature addition.
- Added Far Manager to `developer` and `server` (Greg's ask, following
  a question about Ranger/Midnight-Commander equivalents on Windows —
  `lf` already covered the Ranger role in every profile; Far Manager
  fills the closer Midnight Commander/dual-pane role). Updated both
  design docs' Final package list sections, `CHANGELOG.md`, and both
  profiles' `description.txt`.

### Development Environment

- Root-caused a real mixed-line-endings bug by direct byte inspection
  (`cat -A` on the live `$PROFILE`) rather than guessing — confirmed
  `Set-Content`'s platform-default trailing newline was the cause, not
  assumed.
- Fixed a real `.gitignore` contradiction (`snapshots/` was excluded
  despite the in-repo-tracking design decision) found while cleaning
  up a real test snapshot before committing.

---

## 2026-08-11

### Documentation

- Finished `docs/design/developer-profile.md`: resolved the remaining
  open questions (build toolchain → MinGW/gcc, resource monitor →
  skipped, `mise`/Fresh Windows support → both confirmed real via
  `winget search`) and marked it Decided/Built. Updated
  `docs/ROADMAP.md`'s `developer` bullet from Planned to Completed and
  `CHANGELOG.md` with the actual feature addition.
- Added `docs/design/server-profile.md`, scoped and resolved in one
  pass: no firewall tool (Windows Firewall covers it), `restic` alone
  for backups (verified real, native Windows, no WSL; `robocopy`
  already covers `rsync`'s role), no fail2ban equivalent (IPBan is
  real but has no winget package — a genuine gap, documented rather
  than forced after Greg chose that option directly over building a
  minimal extras mechanism early or documenting a manual step), no
  resource monitor. Updated `docs/ROADMAP.md`'s `server` bullet from
  Planned to Completed and `CHANGELOG.md` with the actual feature
  addition.

### Development Environment

- Verified `mise`, Fresh, and MinGW's real winget package IDs directly
  on this machine (`jdx.mise`, `sinelaw.fresh-editor`,
  `BrechtSanders.WinLibs.POSIX.UCRT`) rather than assuming from the
  earlier design doc's placeholders.
- Verified `restic`'s real winget package ID (`restic.restic`) and
  confirmed `robocopy` is already present in `C:\WINDOWS\system32`
  before ruling out a separate `rsync`-equivalent install.

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
