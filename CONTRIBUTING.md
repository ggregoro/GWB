# Contributing to GWB

GWB is currently a personal project (private repository), built and
maintained by its author as the PowerShell/Windows sibling to
[GLB](https://github.com/ggregoro/GLB). It's not yet open to outside
contributions, but is built with reasonably clean, documented code in
mind in case that changes later.

## Conventions

- **PowerShell 7+ only** — no dependency on Windows PowerShell 5.1-only
  behavior.
- **Mirror GLB's shape where it still applies.** `gwb.ps1` is a thin
  dispatcher; real logic lives in `lib/*.ps1`, one focused module per
  concern (packages, profile, detect, ...). A profile is a directory
  under `profiles/<name>/` (`packages.txt`, `profile-snippet.ps1`,
  `description.txt`), the PowerShell/winget equivalent of GLB's
  `packages.txt`/`extras.txt`/`dotfiles/`.
- **Idempotent by default.** Anything `restore` does should be safe to
  run twice — check "already installed"/"already applied" before
  acting, and don't let re-running a command grow the target file
  (e.g. `$PROFILE`) or duplicate state.
- **Never clobber a user's first backup.** `$PROFILE.gwb-backup` is
  written once, on first touch, and never overwritten by a later
  restore — it's the only path back to someone's real pre-GWB profile.
- **Verify for real, not just by reading the code.** Parse-check a
  script, then actually run the command — including running it twice
  to confirm idempotency, and exercising `--undo` for real if a change
  touches the backup/restore path. See `CHANGELOG.md`/commit history
  for the kind of real-machine verification expected before something
  is considered done.

See [`docs/CODING_STANDARDS.md`](docs/CODING_STANDARDS.md) for the full
style guide (naming conventions, error handling, module design).

## Reporting issues

Since this repository is currently private, issues and changes go
through its author directly rather than public GitHub Issues/PRs.
