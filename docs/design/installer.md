# Design: `install.ps1` (the curl/`irm`-style one-liner installer)

**Status:** Built (2026-08-11) and now fully verified for real
(2026-08-11, same day, on Greg's real Windows 11 machine) — including a
real bug the first-ever run of its Pester suite caught, not present in
`install.ps1` itself. See "Verification" below.

## Purpose

Port GLB's `install.sh` — a standalone bootstrap script that gets the
tool onto a fresh machine before it exists there at all
(`irm <url>/install.ps1 | iex`), clones/updates the repo, and prints
the next command to run. Deliberately does not run `gwb restore`
itself, for the same reason GLB's `install.sh` doesn't run
`glb restore`: that's a separate, opinionated, interactive step
(package installs, `$PROFILE` changes) that shouldn't happen as a
surprise side effect of "get GWB onto my machine."

This was the one item left on `docs/ROADMAP.md`'s Version 1.0 list once
[public-release readiness](../PROJECT.md) was decided — and going
public is what actually unblocks it: like GLB's `install.sh`, a fresh
machine has no credentials to `git clone` a private repo, so this
couldn't have been meaningfully tested (or used) before the repo went
public earlier the same day.

## Real forks from GLB's `install.sh`

Unlike `from-manifest.md` (which found no real fork worth documenting),
this one has two genuine, non-obvious platform differences — worth
recording so a future session doesn't reintroduce either bug.

### 1. Install location: `$env:LOCALAPPDATA\GWB`, not a literal port of `~/.local/share/glb`

GLB clones into `~/.local/share/glb` — the XDG data-home convention.
Windows has its own equivalent per-user app-data convention,
`$env:LOCALAPPDATA` (`C:\Users\<name>\AppData\Local`), which is what a
Windows-native tool is expected to use. This is the same category of
deliberate platform-idiomatic divergence already made for the `gwb`
command itself (`lib/completions.ps1`) — a `.ps1` script isn't callable
by bare name on Windows the way a `PATH`-symlinked script is on Linux,
so that feature already needed a genuinely different mechanism, not a
literal port. Same reasoning here: mirroring GLB's literal path
(`$HOME\.local\share\gwb`) would work but would read as an artificial
Unix path grafted onto Windows, not something a Windows user would
expect.

Both the install directory and the repo URL are overridable via
environment variables (`$env:GWB_INSTALL_DIR`, `$env:GWB_REPO_URL`),
mirroring GLB's `GLB_INSTALL_DIR`/`GLB_REPO_URL` exactly — same
mechanism, same purpose (testability, and an escape hatch for anyone
who wants a different location).

### 2. `exit` is unsafe inside a script piped through `iex` — a real gotcha GLB's bash version never had to consider

`curl -fsSL <url> | bash` runs the piped script in a **disposable
subshell** — a new bash process. If that script calls `exit`, only
that subshell dies; the user's real interactive shell is untouched.
`install.sh` relies on this throughout (`exit 1` on every error path).

PowerShell's `irm <url> | iex` has no equivalent isolation.
`Invoke-Expression` evaluates the fetched text **in the caller's
current scope** — the same as dot-sourcing a file — which means it
runs inside the user's live, single-process interactive session, not a
child process. Calling `exit` anywhere in that text closes the whole
PowerShell window, not just the installer. Confirmed by reasoning
through PowerShell's own documented `iex`/scope semantics (not
empirically reproduced this session, since no `pwsh` was available
here) — this is exactly the kind of surprising, hard-to-reverse action
this project's own conventions warn against, so it was designed out
rather than risked.

Two consequences, both applied in `install.ps1`:

- **No `exit` anywhere in the file.** Error paths print via a plain,
  non-terminating `Write-Error` (the stderr stream, capturable and
  testable, but not a thrown exception) followed by an explicit
  `return` — which only unwinds the current scriptblock, safe under
  both `iex` and direct `.ps1` execution. `$ErrorActionPreference =
  "Stop"` is deliberately **not** set here either (unlike `gwb.ps1`'s
  own dispatcher convention in `docs/CODING_STANDARDS.md`), since that
  would turn `Write-Error` into a terminating exception with the same
  category of risk once it propagates past this script's boundary in
  some hosts. This is a documented, deliberate exception to that
  convention, not an oversight — the coding standard itself allows
  departing from it "unless there's a documented reason not to," and
  this is that reason.
- **The entire script body is wrapped in a single `& { ... }`
  scriptblock.** `iex`-evaluated text runs at the *caller's* scope by
  default, so every top-level variable the installer sets
  (`$InstallDir`, `$RepoUrl`, ...) would otherwise leak into the
  user's interactive session once the one-liner finishes — a much
  smaller problem than the `exit` one, but still a real, avoidable bit
  of pollution. The `& { }` call operator gives the block its own
  child scope, so nothing escapes upward. A dedicated Pester test
  (`tests/Install.Tests.ps1`) asserts this directly: after invoking
  the installer's text via `Invoke-Expression` (the same mechanism
  `iex` uses), neither `$InstallDir` nor `$RepoUrl` exist in the
  caller's scope afterward.

## Testing approach

`install.ps1` has no reusable functions to dot-source (deliberately —
it must work before GWB/`lib/` exists on a machine, same boundary
GLB's `install.sh` has relative to `lib/logging.sh` etc.), so
`tests/Install.Tests.ps1` re-evaluates its raw text via
`Invoke-Expression` in each test — exactly how the real one-liner
invokes it. This keeps Pester's `Mock` working via its normal dynamic
scoping: a `Mock git`/`Mock Get-Command` defined in an `It` block is
still visible inside the script's nested `& { }` block, the same
mechanism `Packages.Tests.ps1` already relies on to mock `winget`.
Covers: git-not-found, fresh clone, update-in-place, refuses to
clobber an unrelated existing directory, a failed `git pull`/`git
clone` reporting cleanly, and the scope-isolation property itself.

## Verification

Run for real on Greg's Windows 11 machine, both the automated suite and
the live one-liner against the now-public repo:

- **`Invoke-Pester -Path tests/Install.Tests.ps1`**, executed for the
  first time ever. 4 of 7 tests failed on the first real run — **a
  real bug, but in the test file, not `install.ps1`**: every
  `$output = Invoke-Expression $Script:InstallScriptText *>&1 |
  Out-String` capture came back empty wherever `install.ps1` hit a
  `Write-Error` path. Isolated with a minimal repro rather than
  guessed at: `*>&1`/`2>&1` applied directly to an `Invoke-Expression`
  call does **not** capture that call's own error-stream writes, but
  wrapping the call in its own scriptblock and redirecting *that*
  (`& { Invoke-Expression $text } *>&1`) does. Confirmed this doesn't
  affect real interactive `irm | iex` usage — nothing redirects those
  streams there, so a real user always sees `Write-Error` output
  normally; it's purely a test-capture-technique gap. Fixed all 6
  affected assertions; 7/7 pass now, and the full suite (88 tests) still
  passes together with no cross-file interference.
- **The real one-liner**, run twice against the live public repo:
  `irm https://raw.githubusercontent.com/ggregoro/GWB/master/
  install.ps1 | iex`. First run: real fresh clone to
  `$env:LOCALAPPDATA\GWB`, confirmed via `Test-Path`. Second run:
  correctly reported "already installed... updating..." /
  "Already up to date" instead of re-cloning.
- **The fresh checkout's own path resolution**, confirmed from its new
  location (not the dev checkout at `Projects\GWB`): `gwb.ps1
  help`/`profiles` both work correctly, listing all three real
  profiles.
- **The full chain, completed end to end**: ran `gwb.ps1 restore
  default` from the fresh `$env:LOCALAPPDATA\GWB` checkout for real —
  packages/modules already installed, `$PROFILE` updated successfully.
  One real, expected consequence worth knowing: this makes the `gwb`
  function in `$PROFILE` point at the `$env:LOCALAPPDATA\GWB` copy
  going forward (the real "installed" copy `install.ps1` exists to
  provide), not the `Projects\GWB` dev checkout — correct, intended
  behavior, not a bug, but a visible change from earlier sessions where
  `gwb` pointed at the dev checkout.
- Not done: a genuinely fresh/clean machine (GLB's own install.sh was
  eventually verified on fresh VMs per package manager) — this was
  verified on Greg's one existing Windows 11 machine, which already had
  git and every dependency `install.ps1` needs. Consistent with GWB's
  overall single-machine testing history so far, not a new gap specific
  to this feature.
