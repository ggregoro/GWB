# Design: `developer` profile

**Status:** Decided and built (2026-08-10/11). Verified for real —
see "Verification" below.

## Purpose

GLB's `docs/ROADMAP.md` Version 0.3 built a `developer` profile for
"someone newer to development who wants a complete kit without
researching every tool choice themselves." GWB's own `docs/ROADMAP.md`
flagged a Windows `developer` profile as planned but explicitly *not* a
blind port — several of GLB's picks don't have a clean 1:1 Windows
equivalent, and porting them wrong would undercut the "solid default,
no research needed" goal this profile exists for.

This doc scoped those real forks before building, the same way GLB
scoped Podman-vs-Docker, mise-vs-per-language-managers, etc. before
building its own `developer` profile.

## What GLB's `developer` profile has

`packages.txt`: Podman (containers), gcc+make (build toolchain), jq,
`gh` (GitHub CLI), htop — plus `extras.txt`: mise (language version
manager), Fresh (terminal code editor). Plus the same shared shell/
prompt setup every GLB profile ships.

## Decisions

### 1. Containers: dropped from scope entirely (2026-08-10)

Docker Desktop and Podman Desktop both need WSL2 (or Hyper-V, same
underlying virtualization-takeover risk) for Linux containers on
Windows; native Windows Containers only run Windows-based images, not
useful for typical dev workflows. **Ruled out per a hard constraint
(Greg, 2026-08-10): no WSL2, and no tooling that requires it** — it
breaks his VirtualBox VMs. No container tool is included in
`developer`, documented as a known gap rather than forced (same
category as GLB leaving unattended security updates out of `server`).

### 2. Build toolchain: MinGW/gcc, not MSVC (2026-08-10, Greg's choice)

Both real options exist on winget: `BrechtSanders.WinLibs.POSIX.UCRT`
(MinGW/gcc) and `Microsoft.VisualStudio.2022.BuildTools` (MSVC). Greg
chose **MinGW/gcc** — lighter install, mirrors GLB's actual gcc+make
pick, POSIX-familiar. Someone who specifically needs MSVC (e.g. certain
native Rust/Python/Node extension builds) can add it themselves; not
worth the multi-GB default install for "someone newer to development."

### 3. Version manager: `mise` has real native Windows support (verified 2026-08-10)

Confirmed via web search and a direct `winget search`, not assumed:
`mise` is Rust-based and ships real Windows builds (`jdx.mise`, winget,
v2026.8.2 at verification time) — no WSL required. One narrow,
documented limitation: it can't install tools that require asdf plugins
on Windows, which doesn't affect mainstream languages (Node/Python/
Rust/Go all have native mise backends). **Included, matching GLB.**

### 4. Resource monitor: skipped (2026-08-10, Greg's choice)

`aristocratos.btop4win` is a real, actively-maintained winget package
(verified directly) — the option existed. Greg chose to **skip it**:
Windows already ships Task Manager as a first-class, always-available
GUI tool, so the gap `htop`/`btop` fills on Linux (no built-in monitor)
doesn't really exist here. The override entry (`"btop" =
"aristocratos.btop4win"`) stays in `lib/packages.ps1` regardless —
harmless, reusable infrastructure if this gets reconsidered later, same
pattern GLB used for keeping its unused `flatpak` extras method around.

### 5. Editor: Fresh confirmed available on Windows (verified 2026-08-10)

Confirmed via a direct `winget search fresh` on this machine: real
package `sinelaw.fresh-editor` (v0.4.7 at verification time). In scope
under GWB's "runs inside the terminal, not its own window" rule (see
`docs/PHILOSOPHY.md`). **Included, matching GLB.**

## Final package list

`profiles/developer/packages.txt`: the same shared foundation as
`default` (`git`, `eza`, `fzf`, `lf`, `ripgrep`, `fd`, `bat`,
`starship`) plus `jq`, `gh`, `mise`, `fresh`, `mingw`, `farmanager`
(2026-08-11, Greg's ask — Far Manager, a dual-pane console file
manager, real winget package `FarManager.FarManager`; the closer
Midnight Commander analogue, alongside `lf`'s Ranger-equivalent role
already in the shared foundation). Every one of these has a real
winget package — unlike GLB, GWB's `developer` needed no extras/
non-package-manager install mechanism at all, since winget happened to
carry everything decided on directly.

`profile-snippet.ps1`: same eza/bat/fzf/starship setup as `default`,
plus a guarded `mise activate pwsh` block.

## Verification

Built and verified for real on Greg's Windows 11 machine (not just
parsed): all 5 new packages (`jq`, `gh`, `mise`, `fresh` — already
present — and `mingw`) installed cleanly via `gwb.ps1 restore
developer`, confirmed idempotent on a second restore, and `gcc`/`gh`/
`jq`/`mise` all confirmed functional afterward.

**Real bug found and fixed during this verification**: the initial
`profile-snippet.ps1` used `Invoke-Expression (&mise activate pwsh)`,
copying the pattern already used for Starship — but `mise activate
pwsh` returns its output as a multi-line string *array*, not a single
string, and `Invoke-Expression`'s `-Command` parameter can't bind an
array (`Cannot convert 'System.Object[]' to the type 'System.String'`).
Fixed by joining the array into one string first:

```powershell
Invoke-Expression ((&mise activate pwsh) -join "`n")
```

Applied the same defensive join to the Starship line in **both**
`default` and `developer`'s snippets — it happened to work unjoined
only because Starship's init output comes back as a single string, not
because the pattern was actually safe.
