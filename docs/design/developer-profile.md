# Design: `developer` profile

**Status:** Partially decided (containers, 2026-08-10) — remaining
questions (build toolchain, `mise`, resource monitor, Fresh) still
open; not yet built.

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

## Decided

### 1. Containers: dropped from scope entirely (2026-08-10)

GLB picked Podman over Docker deliberately (daemonless/rootless, fits
GLB's philosophy). On Windows, the mainstream options don't have a
non-WSL2 path:

- **Docker Desktop** requires the WSL2 backend (or Hyper-V) for Linux
  containers.
- **Podman Desktop** on Windows also runs containers inside a WSL2
  machine under the hood (`podman machine init`) — same dependency,
  different name.
- **Native Windows Containers** (process-isolated, no VM/WSL2 required)
  only run Windows Server Core/Nano Server-based images — not useful
  for the Linux-container workflows most dev tooling actually assumes.

**Ruled out per a hard constraint (Greg, 2026-08-10): no WSL2, and no
tooling that requires it.** WSL2 takes over the machine's virtualization
and breaks his existing VirtualBox VMs — this isn't a preference to
weigh against convenience, it's a standing "never install this"
constraint across GWB (and Windows tooling generally, see this
project's `CLAUDE.md`/memory). Since every mainstream Windows container
tool needs WSL2 (or Hyper-V, which has the same virtualization-takeover
problem), **no container tool is included in `developer`.** This is the
same category of decision as GLB leaving unattended security updates
out of `server` — a real gap with no clean answer, documented rather
than forced. Revisit only if a genuinely WSL2-free/Hyper-V-free Windows
container story emerges.

## Open questions — real forks, not yet decided

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
