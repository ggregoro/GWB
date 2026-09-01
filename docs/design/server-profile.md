# Design: `server` profile

**Status:** Decided and built (2026-08-11). Verified for real — see
"Verification" below.

## Purpose

GLB's `docs/ROADMAP.md` Version 0.3 built a `server` profile for
"someone newer to server administration who wants a solid, complete
kit without researching every tool choice themselves." GWB's own
`docs/ROADMAP.md` flagged a Windows `server` profile as planned but
explicitly not a blind port, matching the same discipline applied to
`developer` (see `docs/design/developer-profile.md`).

## What GLB's `server` profile has

`packages.txt`: ufw (firewall), rsync, restic (backup), fail2ban
(intrusion prevention), htop (resource monitor) — plus the same shared
shell/prompt setup every GLB profile ships.

## Decisions

### 1. Firewall: no tool installed — Windows Firewall already covers it (2026-08-11)

GLB picked `ufw` because raw `iptables` is hard to use directly; `ufw`
exists specifically to make firewall rules approachable. Windows
doesn't have that gap: Windows Firewall ships built-in, enabled by
default, with modern, genuinely usable tooling already in the box
(`New-NetFirewallRule`/`Get-NetFirewallRule` PowerShell cmdlets, or the
older `netsh advfirewall` for scripting). There's no mainstream
"ufw-for-Windows" package solving a problem that doesn't exist here.
**No firewall tool included** — same shape as `developer`'s resource-
monitor decision (skip a tool when the OS already provides the thing it
would exist to add).

### 2. Backup: `restic` alone, no `rsync` equivalent needed (2026-08-11)

Verified directly via `winget search`: `restic.restic` is a real,
native Windows package — no WSL required, same tool GLB uses. GLB
paired `rsync` alongside `restic` for general file-sync tasks; on
Windows, `robocopy` (confirmed already present at
`C:\WINDOWS\system32\Robocopy.exe`) covers that role natively, so
nothing needs to be installed for it. **`restic` included; no separate
sync tool added.**

### 3. Intrusion prevention: no fail2ban equivalent — decided permanently manual (revisited and closed 2026-08-11)

Originally left as a revisit-later gap (Version 0.4 didn't exist yet at
the time — see history below). Revisited once `lib/modules.ps1`
(Version 0.4) existed, which was the trigger condition this doc
originally set for reconsidering it.

**Real facts pulled directly from the current install script**
(`https://raw.githubusercontent.com/DigitalRuby/IPBan/master/IPBanCore/Windows/Scripts/install_latest.ps1`,
fetched and read in full, not summarized) rather than assumed from the
earlier research:

- **Requires Administrator elevation** — explicit in the script's own
  header comment, confirmed by what it does: writes to `C:\Program
  Files\IPBan`, registers/deletes a Windows Service via `sc.exe`,
  modifies system audit policy via `auditpol.exe`. `gwb.ps1` has never
  needed elevation for anything else — every package/module install so
  far is user-scoped.
- **Installs a persistent, always-running Windows Service** that
  monitors event logs and modifies Windows Firewall rules to block
  IPs — categorically different from every other extra GWB has
  automated (PSFzf/Terminal-Icons/`mise`/Fresh are all inert tools you
  invoke; this actively changes system behavior continuously).
- **Real lockout risk**: bans IPs after repeated failed logins. If
  misconfigured, or if the machine is administered remotely (RDP) and
  a password gets mistyped a few times, this can lock out legitimate
  access — the network-level equivalent of the `pam_faillock` lockout
  GLB documented and fixed on the Linux side.

**Decided directly with Greg, presented with the real elevation/
service/lockout facts above: keep it a documented manual step,
permanently, not automated by `gwb restore` at all** — not "revisit
once a mechanism exists" anymore, since the blocker was never really
"GWB lacks an extras mechanism" (that's since been built, see
`docs/design/psgallery-extras.md`) — it's that this specific tool's
risk profile (elevation + persistent security service + real lockout
risk) is a genuinely different kind of thing than what `gwb restore`
should be doing unattended, unlike PSFzf/Terminal-Icons/`mise`/Fresh.
See [`docs/reference/ipban-manual-install.md`](../reference/ipban-manual-install.md)
for the real install/verify/uninstall commands and the lockout-risk
caution, and `profiles/server/description.txt` for the pointer to it.

<details>
<summary>Original entry (2026-08-11, before this revisit) — kept for history</summary>

Researched properly before deciding: **IPBan**
([DigitalRuby/IPBan](https://github.com/digitalruby/ipban)) is a real,
actively-maintained "fail2ban for Windows" (blocking brute-force
RDP/SSH/etc. attempts since 2011) — genuinely the right tool, not a
weak substitute. But it has **no winget package**; its only documented
install path is a PowerShell download-and-run script, which is exactly
the kind of thing GLB's `extras.txt`/`lib/extras.sh` mechanism exists
for — and GWB doesn't have an equivalent yet (`lib/extras.ps1` is still
just a `docs/ROADMAP.md` Version 0.4 item, not built).

Presented three real options (skip and document / pull Version 0.4
forward to build a minimal extras mechanism just for this / document as
a manual post-restore step) — **Greg chose to skip it and document the
gap**, same category of decision as GLB leaving unattended security
updates out of its own `server` profile: a real gap with no clean
answer *yet*, left honest rather than forced into a half-built
mechanism for one tool. Revisit once `lib/extras.ps1` gets built for
real reasons (see `docs/ROADMAP.md` Version 0.4) — IPBan should be
reconsidered then, not before.

</details>

### 4. Resource monitor: skipped, consistent with `developer` (2026-08-11)

Same reasoning as `developer`'s decision: Task Manager already covers
this on Windows, so `btop4win` isn't included here either, for
consistency across profiles.

## Final package list

`profiles/server/packages.txt`: the same shared foundation as `default`
(`git`, `eza`, `fzf`, `lf`, `ripgrep`, `fd`, `bat`, `starship`) plus
`restic` and `farmanager` (2026-08-11, Greg's ask — Far Manager,
`FarManager.FarManager` via winget; genuinely useful on a server profile
for browsing a remote/headless machine's filesystem without leaving the
terminal). Otherwise notably smaller than GLB's `server` — three of
GLB's four server-specific picks (`ufw`, `rsync`, `fail2ban`) don't
carry over, each for a documented reason above, not by oversight.

`profile-snippet.ps1`: identical to `default`'s (eza/bat/fzf/starship) —
`restic` needs no shell activation, so there's nothing server-specific
to add.

## Verification

Built and verified for real on a real Windows 11 machine: `restic`
installed cleanly via `gwb.ps1 restore server`, confirmed idempotent on
a second restore, and `restic version` confirmed functional afterward.
