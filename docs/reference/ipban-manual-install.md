# IPBan (manual install)

IPBan ([DigitalRuby/IPBan](https://github.com/digitalruby/ipban)) is
the closest real Windows equivalent to fail2ban — `server`'s only
security-relevant gap left undecided by
[`docs/design/server-profile.md`](../design/server-profile.md). It's
**deliberately not automated by `gwb restore`** — see that doc for the
full reasoning. Two things set it apart from everything else GWB
installs:

- **It needs Administrator elevation.** `gwb.ps1` never requires this
  for anything else — every package/module install is user-scoped.
- **It's a persistent, always-running Windows Service** that monitors
  event logs and modifies Windows Firewall rules to block IPs after
  repeated failed logins (RDP, etc.) — not an inert tool you invoke,
  something that actively changes the machine's behavior continuously.

## Install

Run from an **Administrator** PowerShell prompt:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/DigitalRuby/IPBan/master/IPBanCore/Windows/Scripts/install_latest.ps1'))
```

The installer prompts interactively for a service startup type
(`delayed-auto` or `auto`) unless you pass `-silent $true`. To install
non-interactively:

```powershell
$script = (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/DigitalRuby/IPBan/master/IPBanCore/Windows/Scripts/install_latest.ps1')
& ([scriptblock]::Create($script)) -silent $true -startupType delayed-auto
```

## Verify

```powershell
Get-Service IPBan
```

## Uninstall

Re-run the same install command with an `uninstall` argument:

```powershell
$script = (New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/DigitalRuby/IPBan/master/IPBanCore/Windows/Scripts/install_latest.ps1')
& ([scriptblock]::Create($script)) uninstall
```

## Real safety caution

IPBan bans IPs after repeated failed login attempts. **This can lock
out legitimate access, including your own**, if you're administering
the machine remotely (RDP) and mistype a password a few times — the
network-level equivalent of the `pam_faillock` lockout GLB documented
on the Linux side (see GLB's own `CLAUDE.md` for that history). Before
relying on it on a machine you access remotely:

- Confirm you have an out-of-band way back in (console access, a
  hypervisor's own console, a second admin account) before you need it.
- Review IPBan's own config (`C:\Program Files\IPBan\ipban.config`
  after install) for whitelisting your own known IP(s) and adjusting
  the failed-attempt threshold before trusting it unattended.
