# Design: Pester test suite

**Status:** Built (2026-08-11). Verified for real — 81/81 tests pass,
including a real bug the suite caught on its very first run.

## Purpose

GLB has a `bats` suite under `tests/` (roughly one file per `lib/`
module plus `dispatcher.bats`), run against an isolated `GLB_ROOT`/
`HOME` with `sudo`/package managers stubbed via fake executables on
`PATH`. GWB had no equivalent — this builds one with Pester, the
PowerShell analogue.

## Real technical questions, verified before building

1. **Which Pester?** Only the ancient bundled Pester **3.4.0**
   (Windows PowerShell's built-in version, from `C:\Program
   Files\WindowsPowerShell\Modules`) was present — confirmed directly
   via `Get-Module -ListAvailable`. Not something to build a real 2026
   suite on (a completely different, older assertion/mocking syntax).
   Installed modern **Pester 6.0.1** via `Install-Module` instead.
2. **Can Pester `Mock` intercept `winget` (an external `.exe`), not
   just PowerShell functions/cmdlets?** GLB's bats stubs work by
   shadowing executables on `PATH`; Pester's mocking model is
   different (proxy functions injected into the calling scope). Verified
   directly, not assumed: `Mock winget { ... }` works, and — more
   importantly — GWB's real `Test-GwbPackageInstalled` correctly
   respects the mock when called normally (not just a standalone
   toy example).
3. **Can `$PROFILE` be safely overridden for a test without touching
   the real file?** Verified directly: `$global:PROFILE = <temp
   path>` before a test, restored in `AfterEach`, works cleanly since
   `$PROFILE` is just a global-scope automatic variable GWB's
   functions reference by its bare name.
4. **Can `gwb.ps1` itself be exercised at the dispatcher level with
   mocking still active** (real end-to-end coverage, matching GLB's
   `dispatcher.bats`), or is unit-testing `lib/*.ps1` functions in
   isolation the practical ceiling? Verified directly, and the answer
   was better than expected: dot-sourcing `gwb.ps1` with real
   arguments (`. $Script:GwbScript restore default --dry-run`) from
   *inside* a Pester `It` block keeps `Mock`/the `$PROFILE` override
   active, and `gwb.ps1`'s own `exit 0` does **not** kill the Pester
   process — `exit` inside a dot-sourced script only terminates that
   script's own execution when the calling context is itself a script
   (not the top-level interactive host), not documented anywhere GWB
   relied on before this, confirmed by direct experiment. This means
   `tests/Dispatcher.Tests.ps1` gets real dispatcher-level coverage,
   not just unit tests.

## Design

- **`tests/TestHelpers.ps1`**: `New-GwbTestProfile` (builds a
  profile-shaped temp directory), `New-GwbTempProfilePath` (a safe,
  always-`$env:TEMP` path for `$PROFILE` overrides). Dot-sourced by
  every test file, mirroring `test_helper.bash`.
- **One file roughly per `lib/` module** (`Packages`, `Modules`,
  `Profile`, `Diff`, `Export`, `Repair`, `Detect`) plus
  `Dispatcher.Tests.ps1` for real end-to-end command coverage — same
  shape as GLB's `tests/`.
- **`Dispatcher.Tests.ps1` deliberately skips `export`** — `gwb.ps1`
  hardcodes `$SnapshotsRoot` to the real repo's `snapshots/`
  directory, and a dispatcher-level test writing there for real isn't
  worth the risk when `Export-GwbSnapshot` already has full unit
  coverage against a temp `SnapshotsRoot` in `Export.Tests.ps1`.
- **Not covered, deliberately**: `completions.ps1`'s actual
  tab-completion behavior (already verified manually via
  `TabExpansion2` when the feature was built — see
  `docs/design/shell-completions.md` — and genuinely hard to unit-test
  meaningfully in Pester), `banner.ps1`/`log.ps1` (trivial output
  formatting), `terminal.ps1` (an unused stub).

## Real bug found and fixed, first run

`Write-GwbSetDiff`'s `-SetA`/`-SetB` parameters were `[Parameter
(Mandatory)][string[]]` with no `[AllowEmptyCollection()]`. PowerShell
rejects an **empty array** passed to a mandatory array parameter as if
no value were given at all — a well-known but easy-to-miss gotcha.
Every real profile (`default`/`developer`/`server`) has always had a
non-empty `modules.txt`, so this never surfaced manually. But any
profile-shaped directory *without* one — a hand-written manifest, or a
snapshot from before `modules.txt` tracking existed — would crash
`gwb diff`/`gwb repair` outright (`ParameterBindingValidationException`)
instead of correctly reporting "no modules on either side."

Caught immediately by `Diff.Tests.ps1`'s tests that build profiles via
`New-GwbTestProfile` without specifying `-Modules` (so no `modules.txt`
is created at all). Fixed with `[AllowEmptyCollection()]` on both
parameters. **Confirmed for real, not just in Pester**: reproduced the
crash on the actual `gwb.ps1` with a real scratch snapshot directory
missing `modules.txt`, confirmed the fix resolves it, no other
`Mandatory` + array-type parameter exists elsewhere in the codebase
(checked directly via `grep`).

## Verification

81/81 tests pass, run together (not just individually — confirmed no
cross-file state leakage). No real files touched: confirmed the real
repo's `snapshots/` directory and the real `$PROFILE` are both
untouched after a full suite run.
