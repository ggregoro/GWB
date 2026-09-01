# CLAUDE.md — GWB (Greg's Windows Bootstrap)

Guidance for Claude Code (and contributors) working in this repo.

> **Detailed session history is not in this file.** The running
> roadmap, the test-environment notes, and the session-by-session work
> log live in a local, git-ignored **`CLAUDE.local.md`** on the
> maintainer's machines — kept out of the public repo deliberately.
> Design rationale that *is* public lives in [`docs/`](docs/). This file
> is the durable, public orientation only.

## What this project is

GWB is a PowerShell CLI — the Windows sibling to
[GLB](https://github.com/ggregoro/GLB) — that installs a curated set of
terminal tools via **winget** and wires them into **`$PROFILE`** in one
pass. It mirrors GLB's dispatcher + `lib/` architecture directly rather
than diverging from it.

- Repo: <https://github.com/ggregoro/GWB> (public)
- License: MIT
- Language: PowerShell 7+
- **Default branch: `master`.**

## Why it exists

A direct port of GLB to Windows/PowerShell — same "bootstrap a terminal
setup in one command" goal, same dispatcher-plus-`lib`-modules shape and
`default`-profile-first approach, adapted to winget + `$PROFILE` instead
of a Linux package manager + dotfiles.

## Architecture

`gwb.ps1` dot-sources focused modules from `lib/` (`banner`, `log`,
`detect`, `packages`, `modules` (PowerShell Gallery), `profile`
(includes the shared `Set-GwbManagedBlock` helper), `completions`,
`export`, `diff`, `repair`), driven by per-profile directories under
`profiles/`:

```
profiles/<name>/
  packages.txt          # winget installs
  modules.txt           # PowerShell Gallery modules (Install-Module)
  profile-snippet.ps1   # merged into $PROFILE as a managed block
  yazi-config/          # yazi.toml + init.lua + vendored git plugin (optional)
  description.txt
```

Full module breakdown: [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

**Commands:** `help` · `version` · `info` · `install <pkg>` ·
`remove <pkg>` · `update` · `restore [profile]`
(`--dry-run` / `--undo` / `--from-snapshot <name>` /
`--from-manifest <path>`) · `profiles` · `export` · `diff <a> <b>` ·
`repair <profile>`.

A `gwb` command + tab-completion is installed into `$PROFILE`
automatically on every restore (a managed block separate from the
profile snippet).

## Profiles

`default` · `developer` · `server` — each with `packages.txt`,
`modules.txt`, `profile-snippet.ps1`, `description.txt`, and optionally
`yazi-config/`. Per-profile decisions (no WSL2-dependent container
tooling, MinGW over MSVC, IPBan staying a manual install, …) are in
[`docs/design/developer-profile.md`](docs/design/developer-profile.md)
and [`server-profile.md`](docs/design/server-profile.md).

**IPBan** (`server`'s fail2ban equivalent) is a deliberate, permanent
non-goal for automation — it needs Administrator elevation, installs a
persistent firewall-blocking service, and carries real lockout risk.
Manual install: [`docs/reference/ipban-manual-install.md`](docs/reference/ipban-manual-install.md).

## Status

The repo is **public**; the current version is in
[`VERSION`](VERSION), and what shipped when is in
[`CHANGELOG.md`](CHANGELOG.md). Direction and progress are in
[`docs/ROADMAP.md`](docs/ROADMAP.md). GWB is feature-complete against
GLB's Version 0.1–0.6 equivalents.

## Testing

`tests/` is a Pester suite that mocks `winget` / `Install-Module` and
overrides `$PROFILE`, including dispatcher-level coverage (it
dot-sources `gwb.ps1` itself with `Mock` still active):

```powershell
Invoke-Pester -Path tests/
```

## Conventions

- **PowerShell 7+ only** — see
  [`docs/CODING_STANDARDS.md`](docs/CODING_STANDARDS.md).
- **Verify for real before calling something done** — parse-check, then
  actually run the command, twice for anything that touches `$PROFILE`
  or installed packages (idempotency), and run `Invoke-Pester -Path
  tests/` for anything touching `lib/`. This discipline has caught
  several real bugs — see `CHANGELOG.md`.
- Keep GWB a faithful mirror of GLB's shape — port decisions, don't
  reinvent them.
- Don't hardcode anything specific to one person's setup unless it's
  clearly an example/default others would edit. Reference docs must
  stay generic — no real hostnames, IPs, usernames, or machine-specific
  paths (see [`docs/reference/README.md`](docs/reference/README.md)).

## Docs map

| File | Contents |
|---|---|
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Module-by-module breakdown |
| [`docs/PHILOSOPHY.md`](docs/PHILOSOPHY.md) | Guiding principles, scope, non-goals |
| [`docs/PROJECT.md`](docs/PROJECT.md) | Overview, release strategy, non-goals |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | Direction and progress |
| [`docs/CODING_STANDARDS.md`](docs/CODING_STANDARDS.md) | Style rules |
| [`docs/troubleshooting.md`](docs/troubleshooting.md) | Common issues (PowerShell 5.1 vs 7, OneDrive `$PROFILE`, …) |
| [`docs/design/`](docs/design/) | One doc per feature decision |
| [`docs/reference/`](docs/reference/) | Manual-install references |
