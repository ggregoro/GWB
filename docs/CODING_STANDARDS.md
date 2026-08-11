# GWB Coding Standards

**Version:** 0.1
**Status:** Living Document

---

# Purpose

This document defines the coding standards used throughout the GWB
project — the PowerShell/Windows sibling to
[GLB](https://github.com/ggregoro/GLB), whose own
`docs/CODING_STANDARDS.md` this is adapted from.

The goal is to keep the codebase readable, maintainable, and consistent
regardless of who contributes to the project.

When in doubt:

> **Choose clarity over cleverness.**

---

# General Principles

* Every module has a single responsibility.
* Every function should do one job.
* Avoid duplicated code.
* Prefer readability over short code.
* Keep modules small and focused.
* Every new feature should be verified for real before it's considered
  done — see `CONTRIBUTING.md`.

---

# Project Structure

```
GWB/
├── docs/            # documentation, including future docs/design/ for
│                     #   feature design docs
├── lib/              # library modules, dot-sourced by the gwb.ps1 dispatcher
├── profiles/         # named profiles (default, ...), each with
│                     #   packages.txt/profile-snippet.ps1/description.txt
├── gwb.ps1
├── README.md
├── CHANGELOG.md
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── LICENSE
└── VERSION
```

New modules belong in the `lib/` directory unless there is a clear
reason otherwise.

---

# Naming Conventions

## Functions

PowerShell's own convention applies: **`Verb-Noun`** in PascalCase,
using an [approved
verb](https://learn.microsoft.com/en-us/powershell/scripting/developer/cmdlet/approved-verbs-for-windows-powershell-commands)
(`Get`, `Set`, `Install`, `Remove`, `Test`, `Write`, `Invoke`, ...).
Public functions carry a `Gwb` prefix on the noun to avoid colliding
with built-in cmdlets or another module's function of the same name —
this is GWB's equivalent of GLB's `glb_`-prefixed function names.

Examples:

```
Write-GwbBanner
Install-GwbPackage
Remove-GwbPackage
Test-GwbPackageInstalled
Get-GwbProfileList
Invoke-GwbApplyProfile
```

A function that's a genuinely private helper, only ever called from
within its own module, doesn't need the `Gwb` noun prefix — but GWB is
small enough right now that this hasn't come up; revisit if/when it
does.

---

# Variables

Script-scoped module state (e.g. a lookup table) uses `$Script:` scope
and PascalCase with a leading underscore-free `_GWB_`-style prefix only
where it mirrors a well-known GLB counterpart directly:

```powershell
$Script:_GWB_PACKAGE_OVERRIDES
```

Ordinary local variables use `camelCase`:

```powershell
$profileDir
$dryRun
```

---

# PowerShell Standards

* Target **PowerShell 7+** — declared via `#Requires -Version 7.0` at
  the top of `gwb.ps1`. No dependency on Windows PowerShell 5.1-only
  behavior.
* Set `$ErrorActionPreference = "Stop"` in the dispatcher unless there's
  a documented reason not to.
* Quote paths and values that may contain spaces; prefer `Join-Path`
  over manual string concatenation for filesystem paths.
* Use `[Parameter(Mandatory)]` on required function parameters rather
  than checking `$null`/empty by hand inside the function body.

---

# Function Design

Functions should:

* Perform one task.
* Return meaningful output (or nothing, for a pure side-effecting
  action) — avoid mixing "returns a value" and "writes to the host" in
  the same function where avoidable.
* Print through `lib/log.ps1`'s `Write-Step`/`Write-Ok`/`Write-Info`/
  `Write-Fail` rather than raw `Write-Host` elsewhere in the codebase.

Example:

```powershell
Write-Info "Installing $Name ($id)..."
```

instead of:

```powershell
Write-Host "Installing $Name ($id)..."
```

---

# Error Handling

Every module should:

* Validate inputs (`[Parameter(Mandatory)]`, explicit `Test-Path`
  checks before acting on a path).
* Fail loudly via `Write-Fail` plus an early `return`/`exit`, never
  silently.
* Prefer PowerShell's own error stream and `$LASTEXITCODE` checks after
  native commands (`winget`, etc.) over swallowing failures.

---

# Idempotency

Anything `restore` does should be safe to run twice:

* Check "already installed"/"already applied" before acting
  (`Test-GwbPackageInstalled`, the managed-block marker check in
  `Install-GwbProfileSnippet`).
* Re-running a command must not grow or duplicate state in a managed
  file — when writing back to `$PROFILE`, trim trailing whitespace
  before comparing/replacing so a repeated apply doesn't accumulate
  blank lines (a real bug caught and fixed during the initial build,
  see `CHANGELOG.md`).
* A backup (`*.gwb-backup`) is written once, on first touch, and never
  overwritten by a later restore.

---

# Module Design

Each library module should focus on one responsibility, matching GLB's
`lib/*.sh` split:

```
banner.ps1
log.ps1
detect.ps1
packages.ps1
profile.ps1
terminal.ps1
```

As GWB grows, following the same one-concern-per-module pattern:

```
extras.ps1      # Install-Module-based tools (PSFzf, PSReadLine, Terminal-Icons)
export.ps1
diff.ps1
repair.ps1
completions.ps1
```

---

# Comments

Every module begins with a short `# lib/<name>.ps1` header comment
naming its GLB counterpart where one exists (e.g. "Mirrors GLB's
lib/package.sh: ...").

Comments should explain **why**, not simply repeat **what** the code
does — a hidden constraint, a workaround, or a non-obvious invariant is
worth a comment; restating the next line in English is not.

---

# Git Workflow

Every development session follows the same pattern:

1. Review repository status.
2. Select one milestone (see `docs/ROADMAP.md`).
3. Implement one module or feature.
4. Verify it for real (parse-check, then actually run it — twice, if
   it should be idempotent).
5. Commit.
6. Update `CHANGELOG.md`.

---

# Development Philosophy

GWB is intended to be a reusable Windows/PowerShell terminal bootstrap
and customization tool, ported deliberately from GLB rather than
designed from scratch.

Every manual terminal setup step on Windows should eventually become an
automated GWB feature — the same standard GLB holds itself to.

The project values:

* Simplicity
* Reliability
* Repeatability
* Modularity
* Maintainability

over shortcuts or unnecessary complexity.

---

# Future Revisions

This document is expected to evolve as GWB grows. New standards should
improve consistency while preserving backward compatibility whenever
practical.
