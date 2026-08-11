# Design: `developer` profile

**Status:** Proposed — not yet decided or built.

## Purpose

GLB's `docs/ROADMAP.md` Version 0.3 built a `developer` profile for
"someone newer to development who wants a complete kit without
researching every tool choice themselves." GWB's own `docs/ROADMAP.md`
flags a Windows `developer` profile as planned but explicitly *not* a
blind port — several of GLB's picks don't have a clean 1:1 Windows
equivalent, and porting them wrong would undercut the "solid default,
no research needed" goal this profile exists for.

This doc scopes those real forks before anything gets built, the same
way GLB scoped Podman-vs-Docker, mise-vs-per-language-managers, etc.
before building its own `developer` profile.

## What GLB's `developer` profile has

`packages.txt`: Podman (containers), gcc+make (build toolchain), jq,
`gh` (GitHub CLI), htop — plus `extras.txt`: mise (language version
manager), Fresh (terminal code editor). Plus the same shared shell/
prompt setup every GLB profile ships.

## Direct ports (no real fork)

- **`gh`** — GitHub CLI has a winget package (`GitHub.cli`). Direct
  port, same as GLB.
- **`jq`** — winget has `jqlang.jq`. Direct port.

## Open questions — real forks, not yet decided

### 1. Containers: what replaces Podman?

GLB picked Podman over Docker deliberately (daemonless/rootless, fits
GLB's philosophy). On Windows, both Docker Desktop and Podman Desktop
exist, but:

- **Docker Desktop** typically requires the WSL2 backend (or
  Hyper-V). Greg avoids WSL on at least one machine specifically
  because it breaks VirtualBox there — a hard constraint any container
  choice needs to respect, not just a preference.
- **Podman Desktop** on Windows also generally runs containers inside a
  WSL2 machine under the hood (`podman machine init`), so it may not
  actually sidestep the WSL constraint just by being Podman.
- A genuinely rootless/daemonless, non-WSL container story on Windows
  may not exist in the same way it does on Linux — worth confirming
  before assuming either option is viable everywhere GWB might run.

**Not decided.** Needs a direct answer from Greg on whether requiring
WSL for containers specifically (as opposed to as a general dev
environment) is acceptable, since that changes which option is even in
play.

### 2. Build toolchain: what replaces gcc+make?

GLB used plain `gcc`+`make` (real, unambiguous packages on every Linux
package manager). Windows native development typically uses the MSVC
toolchain instead, not gcc:

- **MinGW-w64/gcc** — winget has ports of gcc for Windows
  (e.g. `BrechtSanders.WinLibs.POSIX.UCRT`), which would be the more
  literal port of GLB's choice.
- **Visual Studio Build Tools (MSVC)** — winget has
  `Microsoft.VisualStudio.2022.BuildTools`, the more idiomatic "native
  Windows C/C++ toolchain" choice, but a much heavier install and a
  different toolchain than what any GLB-side project would be built
  with.

**Not decided.** Depends on what "someone newer to development on
Windows" is actually likely to build — worth asking rather than
guessing.

### 3. Version manager: does `mise` even work on Windows?

GLB chose `mise` over per-language managers (nvm/pyenv/rustup) for one
universal tool/mental model. `mise`'s Windows support needs to be
verified before assuming it ports directly — if it's limited or
experimental there, the Windows-native alternative is probably just
`rustup` (already Windows-native) plus per-language installers
(`nvm-windows`, `pyenv-win`), which reintroduces the exact
juggling-multiple-tools problem `mise` was chosen to avoid.

**Not decided. Not yet verified.**

### 4. Resource monitor: does this profile need one at all?

GLB added `htop` to `default` (not `developer` specifically) because no
profile had a live process monitor and Linux terminals don't have one
built in. Windows already ships Task Manager as a first-class,
always-available GUI tool — the gap `htop` fills on Linux may not exist
the same way on Windows.

**Not decided.** Options: skip it entirely (Task Manager already
covers this), or add a terminal-based monitor anyway for
terminal-only workflows (e.g. `btop4win`, if a real winget package for
it exists) for parity with GLB's `default`.

### 5. Editor: does Fresh support Windows?

GLB's `default`/`developer` profiles both include Fresh
(getfresh.dev), a terminal-based code editor — in scope under GWB's own
"runs inside the terminal, not its own window" rule (see
`docs/PHILOSOPHY.md`) if it has a real Windows build.

**Not yet verified** whether Fresh ships a Windows binary/installer at
all, or whether it's Linux/macOS-only.

## Not in scope for this doc

Deciding these — this doc exists to surface the real questions before
anyone (Claude or Greg) picks an answer unilaterally, matching the
project's own convention of confirming forks like this via a direct
question rather than guessing. See `CONTRIBUTING.md`.
