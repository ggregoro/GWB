# Design: `export` / `diff` / `repair`

**Status:** Decided and built (2026-08-11). Verified for real — see
"Verification" below, including two real bugs caught and fixed.

## Purpose

GLB's Version 0.6 (Configuration Management) has three pieces:
`glb export` (snapshot a machine's current state), `glb diff`
(compare two profile-shaped things for drift), and `glb repair`
(check a machine against a profile, offer to fix drift). GWB's
`docs/ROADMAP.md` flags all three as the next candidate needing a real
design doc, same discipline as `developer-profile.md`/
`server-profile.md`.

## The real fork: winget has no manual-vs-dependency tracking

GLB's `export` works because every supported package manager (apt,
dnf, pacman, and — with a workaround via `/var/lib/zypp/AutoInstalled`
— even zypper) can distinguish a package the user explicitly installed
from one pulled in as a dependency. **`winget list` has no such
distinction at all**, confirmed directly (`winget list --help`, no
flag for it) — it flatly enumerates everything Windows considers
installed (any Win32 app with an uninstall registry entry, any
MSIX/Store package), regardless of how it got there. A real check on
this machine returned 80 entries mixing genuine user software
(Audacity, Claude, Foxit PDF Reader), OEM-bundled bloat (Dell Display
and Peripheral Manager, Apple Application Support, Creative App), and
GWB-managed CLI tools in one flat list with no metadata to tell them
apart.

**Decided directly with Greg**: scope `export`/`diff`/`repair`'s
package tracking to **only packages that appear somewhere in a
profile's `packages.txt`** (the union across `default`/`developer`/
`server`) — not a full machine inventory. This means `repair`/`diff`
answer "is this profile's tool list present and correct," not "what's
everything on this machine," which is honestly closer to what those
commands are actually for. The alternative (a raw, unfiltered `winget
list` dump) would make every diff/repair against a profile show a wall
of unrelated OEM/personal-app noise — not usable in practice.

**A nice simplification this enables, unlike GLB**: GLB's export has to
*reverse*-map an installed package's distro-specific name back to
GWB's... to GLB's canonical name (`_GLB_PACKAGE_OVERRIDES` run in
reverse). GWB never needs to do that — since the scope is already
"packages named in some profile," export just *forward*-resolves each
known logical name (`Resolve-GwbPackageId`, already built) and checks
whether it's currently installed (`Test-GwbPackageInstalled`, already
built). No new resolution logic needed at all.

## `$PROFILE` content: export only the GWB-managed block, not the whole file

`$PROFILE` may contain content GWB doesn't own — a user's own
customizations outside the `# >>> GWB managed block >>>` markers. Same
scoping principle as the packages decision: export captures only what
GWB actually manages (the text between the markers), not a blind
capture of the entire file. This mirrors GLB not doing a blind `$HOME`
scrape for its own dotfile export — it only captures the specific
relative paths a local profile already tracks.

## No `shell.txt` equivalent

GLB's `shell.txt` records which shell/prompt setup is active, because
GLB branches across bash/zsh/fish. GWB has no equivalent branching —
it's always PowerShell — so a `shell.txt` would carry no real signal
here. Skipped, not an oversight.

## Snapshot location: in-repo, inherited from GLB's decision

GLB's own `docs/design/state-export-import.md` weighed in-repo
snapshots (versioned, diffable across machines via the existing `git
fetch` workflow) against a separate per-machine location, and decided
in-repo. GWB inherits that decision directly rather than re-litigating
it — same reasoning applies identically (Greg works across multiple
machines/sessions, same as on the GLB side). `snapshots/<hostname>-
<date>/` under the repo root, matching GLB's path shape.

## Design

- **`gwb export`** (new `lib/export.ps1`): for each logical package
  name in the union of every `profiles/*/packages.txt`, resolve its
  winget ID and check `Test-GwbPackageInstalled`; write the installed
  subset to `snapshots/<hostname>-<date>/packages.txt` (logical names,
  same shape a profile's `packages.txt` already has — restorable the
  same way). Extract the current `$PROFILE`'s GWB-managed block content
  (reusing the same marker regex `Install-GwbProfileSnippet` already
  uses) into `snapshots/<hostname>-<date>/profile-snippet.ps1`. Write
  `metadata.yaml` (hostname, date, GWB version, PowerShell version, OS
  version).
- **`gwb diff <a> <b>`** (new `lib/diff.ps1`): resolve each name
  against `profiles/` then `snapshots/` (same precedence GLB uses).
  Compare `packages.txt` for `+`/`-` drift (present in one, not the
  other). Compare `profile-snippet.ps1` content directly (a single
  file, not a tree like GLB's `dotfiles/` — so this is simpler: just
  "changed" or "unchanged," no per-path enumeration needed). Exit 0 if
  identical, 1 if any difference found, matching `diff`'s own
  convention — same as GLB.
- **`gwb repair <profile>`**: ephemeral export (packages + current
  `$PROFILE` block, to a `New-TemporaryFile`-style scratch directory,
  nothing saved to disk) diffed against the named profile's real
  directory, reusing `export`'s and `diff`'s own internals directly
  (same cross-module reuse pattern GLB's `glb_repair` uses). Reports
  drift in the same shape `gwb diff` does, then asks to re-run `gwb
  restore <profile>` if drift is found — same confirm-prompt pattern
  `Invoke-GwbRestoreInteractive` already uses.
- **`gwb restore --from-snapshot <name>`**: applies a snapshot the same
  way `restore <profile>` applies a profile — since a snapshot is the
  same shape as a profile (`packages.txt` + `profile-snippet.ps1`),
  this reuses `Invoke-GwbApplyProfile` directly rather than duplicating
  it (unlike GLB, which deliberately duplicates `glb_apply_profile`'s
  body for `glb_apply_snapshot` to avoid breaking existing bats
  assertions on exact log wording — GWB has no test suite yet holding
  it to specific wording, so there's no equivalent reason to duplicate
  here; reuse is the simpler, more maintainable choice).

## Verification

Built and verified for real on Greg's Windows 11 machine: `gwb export`
produces a real snapshot (verified `packages.txt`/`profile-snippet.ps1`/
`metadata.yaml` content by hand); `gwb diff` correctly reports real
package drift between `default`/`developer` and between a profile and a
live snapshot, and correctly reports "no drift" for a profile diffed
against itself; `gwb repair` correctly detects real drift against the
machine's actual state and, when declined, leaves the machine
untouched with the ephemeral scratch directory confirmed cleaned up;
`restore --from-snapshot` correctly reuses `Invoke-GwbApplyProfile`
(confirmed via `--dry-run`) and correctly errors on an unknown snapshot
name.

**Two real bugs found and fixed during this verification, not caught by
parsing alone:**

1. **A false-positive `gwb diff`/`repair` mismatch caused by mixed line
   endings.** `Set-Content`'s own auto-appended trailing newline uses
   the platform default (CRLF on Windows), while the rest of a
   `$PROFILE` managed block is built from `` `n ``-joined (LF) content —
   so the file ends up with LF throughout except its very last line,
   which is CRLF. This made `gwb diff server <its-own-snapshot>` report
   a spurious `profile-snippet.ps1` content difference even when the
   content was otherwise byte-identical. Root-caused by direct byte
   inspection (`cat -A` showing `^M$` only on the final line), not
   guessed at. Fixed at both write sites (`Install-GwbProfileSnippet`
   in `lib/profile.ps1`, `Export-GwbSnapshotContent` in
   `lib/export.ps1`) with `-NoNewline` plus an explicit, single trailing
   `` `n `` — and hardened `lib/diff.ps1`'s content comparison itself to
   normalize CRLF/LF and trailing whitespace before comparing, so a
   future writer inconsistency can't reproduce the same false positive.
2. **`Read-Host` crashing instead of failing gracefully with no
   interactive input available.** Both `Invoke-GwbRestoreInteractive`
   (`lib/profile.ps1`) and `Invoke-GwbRepair` (`lib/repair.ps1`) called
   `Read-Host` unprotected; in a non-interactive session this throws
   (`PowerShell is in NonInteractive mode`) as an uncaught, stack-trace-
   looking error rather than the clean "no input available, treat as
   decline/skip" behavior GLB's own `CLAUDE.md` documents as the
   standing convention for exactly this situation. Fixed by wrapping
   both `Read-Host` calls in `try`/`catch`, failing cleanly (`Write-
   Fail`/`Write-Info` plus a normal return) on no input.

Deleted the real test snapshot before committing, matching GLB's own
precedent (`docs/design/state-export-import.md`'s export entry) — not a
great first real-data commit. Snapshots are still tracked in-repo by
design (see above); also caught and fixed a real contradiction this
surfaced: `.gitignore` had `snapshots/` excluded from an earlier round,
directly contradicting this doc's in-repo-tracking decision.

## Not in scope for this doc

`gwb restore --from-manifest <path>` (GLB's "bring your own external
manifest" feature) — a smaller, separable addition once `--from-
snapshot` exists, not bundled into this round.
