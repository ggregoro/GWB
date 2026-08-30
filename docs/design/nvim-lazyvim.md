# Neovim + LazyVim

**Decided and built**, 2026-08-30. Greg asked for Neovim + his existing
LazyVim setup to be installed together via GWB — "being novice, I can't
use Neovim without LazyVim."

## The real fork: vendor a static copy, or live-clone the config repo?

Every other GWB-managed config so far (`yazi-config/`, Starship's
`scan_timeout`) is either a static file vendored directly into this repo
or a single generated value — both effectively "done once, rarely
touched again." Greg's LazyVim setup is different: it's his own
actively-maintained personal config, already a separate private GitHub
repo (`github.com/ggregoro/nvim-config`), that he expects to keep
tweaking indefinitely. Vendoring a snapshot into GWB (the `yazi-config`
approach) would go stale the moment he changed anything there, and
require manually re-syncing a copy into this repo on every tweak — real
ongoing friction for something whose whole point is continuous
customization.

**Decided**: `Install-GwbNvimConfig` (`lib/profile.ps1`) treats
`nvim-config` as the living source of truth instead. On a fresh machine
it clones the repo straight to `$env:LOCALAPPDATA\nvim` (Neovim's real
Windows config path); on a later restore, if that directory is already
a clone of the same repo (checked via `git remote get-url origin`), it
just `git pull --ff-only`s it. Greg's future edits to `nvim-config` just
need a normal `git push` — no GWB change needed to pick them up. This is
a new pattern for GWB (restore reaching out to clone a *second*,
separate GitHub repo, not just install a package or write a static
file), made viable by the SSH access to that private repo set up the
same day (see `CLAUDE.md`'s Working notes).

Same backup-on-first-touch rule as every other GWB-managed config
(`Set-GwbManagedBlock`, `Install-GwbYaziConfig`): a real pre-existing
`$env:LOCALAPPDATA\nvim` that *isn't* already this clone gets moved
(not copied — `git clone` needs an empty/nonexistent destination) to
`$env:LOCALAPPDATA\nvim.gwb-backup` exactly once, and `gwb restore
--undo` restores it the same way `Undo-GwbRestore` already handles the
yazi config backup.

## Scope

All three profiles (`default`/`developer`/`server`) — Greg's call,
matching yazi's eventual scope, in case he edits files on a
server-profile machine too. Package: `nvim` -> `Neovim.Neovim` (winget),
added to `_GWB_PACKAGE_OVERRIDES` following the existing pattern.
`Install-GwbNvimConfig` self-gates on `Get-Command nvim` (same idiom as
`Install-GwbStarshipConfig`), so it's called unconditionally from
`Invoke-GwbApplyProfile` rather than being `Test-Path`-gated on a
per-profile directory the way `yazi-config/` is — there's no per-profile
directory here at all, since the config comes from the external repo,
not from anything shipped inside GWB itself.

## Not yet verified for real

Built in a cloud session with no `pwsh` at all (the same starting
position `installer.md`'s and the original yazi port's own build were
in) - every file was brace/paren-balance-checked and the Pester tests
mock `git`/`Get-Command` following this suite's existing conventions
(mirroring `Install-GwbYaziConfig`'s and `Install-GwbPackage`'s own
test style), but none of it has actually run. Needs, on a real Windows
machine with SSH access to `nvim-config` already set up:
`Invoke-Pester -Path tests/` to confirm the new tests actually pass (not
just parse), then a real `gwb.ps1 restore <profile>` to confirm Neovim
installs, `nvim-config` actually clones to `$env:LOCALAPPDATA\nvim`, and
`nvim` genuinely launches into a working LazyVim setup (plugins
installing on first launch, etc.) - not just that the right files landed
in the right place.
