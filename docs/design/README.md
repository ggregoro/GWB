# Design Docs

Mirrors GLB's `docs/design/` — this is where a feature gets scoped
*before* being built, when there's a real decision to make (multiple
candidate approaches, an open question worth writing down and getting
confirmed before code gets written), not for every small addition.

GLB's own `docs/design/` has examples of the shape these take:
`guided-wizard.md`, `installation-manifests.md`, `repair.md`,
`state-export-import.md`, `update-components.md` — each one scopes a
single feature, gets resolved (often via a direct question to Greg
before building), and then stays as a record of *why* the feature ended
up shaped the way it did, even after the feature ships.

## Current docs

- [`developer-profile.md`](developer-profile.md) — **Decided and
  built.** Scoped and resolved the real forks in porting GLB's
  `developer` profile to Windows: no container tooling (WSL2
  constraint), MinGW/gcc over MSVC, `mise` and Fresh both confirmed to
  have real Windows support, no resource monitor (Task Manager already
  covers it). Verified end-to-end on real hardware.
- [`server-profile.md`](server-profile.md) — **Decided and built.**
  No firewall tool (Windows Firewall already covers it), `restic` alone
  for backups (real, native, no WSL — `robocopy` already covers
  `rsync`'s role), no resource monitor. IPBan (fail2ban equivalent):
  revisited 2026-08-11 and **decided permanently manual, not
  automated** — needs Administrator elevation, installs a persistent
  firewall-blocking service, real lockout risk. See
  [`../reference/ipban-manual-install.md`](../reference/ipban-manual-install.md).
  Verified end-to-end on real hardware.
- [`export-diff-repair.md`](export-diff-repair.md) — **Decided and
  built.** Scoped package tracking to packages known to some profile
  (winget has no manual-vs-dependency tracking at all — a harder gap
  than any GLB package manager faced). `$PROFILE` export captures only
  the GWB-managed block, not the whole file. Verified end-to-end on
  real hardware, including two real bugs caught and fixed (a
  mixed-line-endings false-positive diff, `Read-Host` crashing instead
  of failing gracefully with no input).
- [`from-manifest.md`](from-manifest.md) — **Decided and built, no real
  fork found.** `Invoke-GwbApplyProfile` already accepted an arbitrary
  path, so `--from-manifest <path>` needed only argument parsing, no
  new logic. Verified end-to-end with a real scratch manifest.
- [`shell-completions.md`](shell-completions.md) — **Decided and
  built.** A wrapper function in `$PROFILE` (not a `PATH` symlink —
  `.ps1` scripts aren't callable by bare name on Windows) plus
  `Register-ArgumentCompleter`, verified to work correctly with a
  plain wrapper function via position-based AST inspection and
  `.GetNewClosure()`. Wired into every restore automatically. Verified
  end-to-end on real hardware, including real `TabExpansion2` results.
- [`psgallery-extras.md`](psgallery-extras.md) — **Decided and built.**
  PSFzf + Terminal-Icons in all three profiles; PSReadLine gets no
  install step (already ships with PowerShell 7), just configuration.
  Verified `-Force` suppresses PSGallery's untrusted-repository prompt.
  Verified end-to-end on real hardware, including a real bug caught
  and fixed (`-ErrorAction SilentlyContinue` didn't actually suppress
  a PSReadLine console message the way `try`/`catch` does).

- [`pester-test-suite.md`](pester-test-suite.md) — **Built.** Modern
  Pester 6.x (the only version present was the ancient bundled 3.4.0),
  `Mock` for `winget`/`Install-Module` (a proxy-function model, not
  GLB's `PATH`-shadowing), and real dispatcher-level coverage via
  dot-sourcing `gwb.ps1` itself with `Mock` still active. 81/81 tests
  at initial build (grew to 88/88 with `installer.md`'s tests), each
  round catching a real bug on its first run — first in `lib/diff.ps1`
  (a `Mandatory` array parameter silently rejecting a legitimate empty
  array), later in the test technique itself (see `installer.md`).
- [`installer.md`](installer.md) — **Built and verified for real.**
  `install.ps1`, the curl/`irm`-style one-liner installer, mirroring
  GLB's `install.sh`. Two genuine platform forks, both from `irm | iex`
  running in the caller's live session rather than a disposable
  subshell: no `exit` calls anywhere, and the whole script wrapped in
  `& { ... }` so its variables don't leak into the interactive session.
  Built in a cloud session with no `pwsh` at all, so genuinely never
  executed until verified for real afterward on a real Windows
  machine — which is where a real `Invoke-Expression`/`*>&1`
  capture bug in the test file (not `install.ps1` itself) was found
  and fixed.

- [`nvim-lazyvim.md`](nvim-lazyvim.md) — **Decided and built,**
  2026-08-30, **not yet verified for real.** The real fork: vendor a
  static copy of Greg's LazyVim setup (the `yazi-config/` approach), or
  have GWB live-clone/pull his separate, private `nvim-config` repo at
  restore time so it stays the actively-changing personal config it
  really is? Decided on the live-clone approach — a new pattern for GWB
  (restore reaching into a *second* GitHub repo, not just installing a
  package or writing a static file). All three profiles.

Everything else built so far (packages, `restore`/`--dry-run`/`--undo`,
the interactive picker) was small enough to build directly, without a
design doc. **Version 1.0 (Stable Release) is now fully complete** —
see [`docs/ROADMAP.md`](../ROADMAP.md).
