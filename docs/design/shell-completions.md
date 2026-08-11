# Design: shell completions for `gwb`

**Status:** Decided and built (2026-08-11). Verified for real — see
"Verification" below.

## Purpose

GLB ships bash/zsh/fish completions for `glb` itself
(`completions/`, `lib/completions.sh`), symlinked onto `PATH` alongside
`glb` during every restore. GWB's `docs/ROADMAP.md` flagged the same
gap for `gwb`.

## Real technical questions, verified before building

1. **How does `gwb` get onto the command line at all?** GLB symlinks
   `glb` into `~/.local/bin/glb`. A `.ps1` script isn't callable by
   bare name on Windows the same way — even with its directory on
   `PATH`, typing `gwb` won't resolve to `gwb.ps1` (PowerShell requires
   the exact filename including extension for script files, unlike
   cmdlets). The PowerShell-idiomatic equivalent is a wrapper
   **function** in `$PROFILE`: `function gwb { & '<path>\gwb.ps1'
   @args }`.
2. **Does `Register-ArgumentCompleter` work for a plain wrapper
   function with no formal parameters (just `@args`)?** Verified
   directly, not assumed: yes — a completer scriptblock can inspect
   `$commandAst.CommandElements` by position (`$elements[1].Value` for
   the subcommand, etc.) instead of relying on named-parameter
   binding, which only needs the command to exist, not have typed
   parameters.
3. **Does a completer scriptblock registered inside a function actually
   see that function's parameter values when the completion engine
   invokes it later (potentially in a different scope)?** Verified
   directly: yes, but only with `.GetNewClosure()` — without it, the
   scriptblock doesn't reliably capture the enclosing variable.

## Decided directly with Greg

Wired into **every** `gwb restore` automatically (matching GLB's own
precedent — nothing previously put `glb`/`gwb` on the command line, a
real gap worth closing by default), rather than a separate opt-in
`gwb completions install` command.

## Design

- **`lib/completions.ps1`** (new): `Register-GwbCompletions -GwbRoot
  <path>` registers the completer (commands for position 1; profile +
  snapshot names, read live from `profiles/`/`snapshots/`, for
  `restore`/`repair`/`diff`; package names, read live from every
  profile's `packages.txt`, for `install`/`remove`). `Get-
  GwbSelfRegistrationContent` builds the small text block written into
  `$PROFILE`: dot-source `lib/completions.ps1`, call `Register-
  GwbCompletions`, define the `gwb` function. `Install-
  GwbSelfRegistration` writes that block.
- **A second, separate managed block in `$PROFILE`** (`# >>> GWB self
  >>>` / `<<<`), distinct from the profile's own `# >>> GWB managed
  block >>>`. Refactored the shared backup/replace-in-place logic out
  of `Install-GwbProfileSnippet` into a new `Set-GwbManagedBlock`
  helper (`lib/profile.ps1`) so both blocks go through identical,
  tested logic rather than duplicating it. Both blocks share the same
  `$PROFILE.gwb-backup` — whichever one is first to add a genuinely new
  marker triggers the one real backup; the other correctly sees it
  already exists and skips.
- Wired into `Invoke-GwbApplyProfile` (`lib/profile.ps1`) right after
  the profile-snippet step, so it runs for every restore path
  (profile, snapshot, manifest) with no special-casing needed.

## Verification

Built and verified for real on Greg's Windows 11 machine: dry-run
correctly reports both blocks; a real `restore server` adds the new
self-registration block cleanly (confirmed via direct file inspection);
three consecutive restores produce a byte-stable file length
(idempotent); dot-sourcing the live `$PROFILE` in a real session makes
`gwb version` work through the new function; tab-completion confirmed
working for commands (`gwb r` → `remove, repair, restore`), profile
names (`gwb restore d` → `default, developer`, correctly excluding
`server`), package names (`gwb install f` → `farmanager, fd, fresh,
fzf`), and snapshot names (`gwb diff serv` → `server`; `gwb restore
--from-snapshot WIN` → the real snapshot name, confirming completion
also works correctly for values after a flag, not just bare positional
arguments).
