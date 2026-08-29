# Troubleshooting

Solutions to problems encountered using or developing GWB. Mirrors
GLB's own troubleshooting notes (currently scattered in `CLAUDE.md`
rather than a dedicated file there) — this is GWB's first dedicated
troubleshooting doc.

Each entry is marked **Confirmed** (actually hit and root-caused on a
real machine during this project's own build) or **Anticipated** (a
well-known Windows/PowerShell gotcha likely to come up, not yet
personally hit here) — see `CONTRIBUTING.md`'s "verify for real"
convention for why that distinction matters.

---

## `ls` shows the plain PowerShell table, not `eza`'s icon output

**Confirmed** — hit directly by Greg in a real terminal after restoring
(`ll`/`la` worked fine; only `ls` was affected).

**Symptom**: `ll`/`la` correctly show `eza`'s icon-based listing, but
bare `ls` shows PowerShell's default `Mode`/`LastWriteTime`/`Length`/
`Name` table instead, as if GWB's `ls` function were never defined.

**Cause**: PowerShell ships a built-in `ls` → `Get-ChildItem` **alias**,
and alias resolution always wins over a same-named **function** —
confirmed directly: even with both registered (`Get-Command ls -All`
shows both), calling bare `ls` invokes the alias's target, silently
ignoring the function. `ll`/`la` aren't affected because PowerShell
doesn't ship built-in aliases with those names, so there's nothing to
collide with — this is specific to `ls`. Fixed in `profiles/*/
profile-snippet.ps1` (`Remove-Item -Path Alias:ls -Force` before
defining the function); update by re-running `gwb restore <profile>`
if you're on an older checkout.

---

## A newly-installed tool isn't found on `PATH`

**Confirmed** — hit directly while building and verifying GWB.

**Symptom**: right after `gwb install starship` (or a `restore` that
installs it), running `starship` in the *same* PowerShell window fails
with `The term 'starship' is not recognized...`, even though winget
reported a successful install.

**Cause**: winget/MSI installers update the machine/user `PATH` in the
registry, but an already-running process keeps the `PATH` it started
with — nothing retroactively refreshes it.

**Fix**: open a new PowerShell window (simplest), or refresh the
current session's `PATH` from the registry without restarting it:

```powershell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" +
            [System.Environment]::GetEnvironmentVariable("Path","User")
```

---

## `gwb.ps1` won't run: "running scripts is disabled on this system"

**Anticipated** — a well-known PowerShell default, not yet personally
hit while building GWB (this machine's `LocalMachine` execution policy
is already `RemoteSigned`).

**Symptom**: running `.\gwb.ps1 ...` fails with something like `cannot
be loaded because running scripts is disabled on this system`.

**Cause**: PowerShell's execution policy defaults to `Restricted` on a
stock Windows install, which blocks all `.ps1` scripts, local or not.

**Fix**: allow locally-authored/cloned scripts to run (per-user, doesn't
need admin):

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

---

## `gwb.ps1` won't run after downloading as a ZIP: "is not digitally signed"

**Anticipated** — a well-known Windows gotcha for anything downloaded
via a browser, not yet personally hit (this repo has only ever been
`git clone`d here, which doesn't trigger it).

**Symptom**: even with `RemoteSigned` set, `.\gwb.ps1 ...` fails with
`File ... cannot be loaded. The file ... is not digitally signed.`

**Cause**: Windows tags files extracted from a browser-downloaded ZIP
with a "downloaded from the internet" mark (an NTFS alternate data
stream), and `RemoteSigned` requires internet-origin scripts to be
signed. A plain `git clone` doesn't set this mark, which is why it
hasn't come up here — but a ZIP download from GitHub's web UI would.

**Fix**: unblock the files after extracting, before running anything:

```powershell
Get-ChildItem -Recurse -Filter *.ps1 | Unblock-File
```

Or just use `git clone` instead of downloading a ZIP, per the README's
Installation instructions.

---

## Starship prints `Scanning current directory timed out` on every prompt

**Confirmed** — hit directly by Greg in a real terminal.

**Symptom**: every new PowerShell window prints
`[WARN] - (starship::context): Scanning current directory timed out.`
before the prompt, most often when the shell starts in a large
directory like `C:\Windows\System32` (e.g. an elevated/Administrator
shell, which defaults there).

**Cause**: Starship scans the current directory on every prompt render
to decide which language/tool modules to show, with a default
`scan_timeout` of just 30ms — too tight for a large or cold-cache
directory.

**Fix**: as of the `Install-GwbStarshipConfig` step added to
`restore`/`repair` (see `CHANGELOG.md`), GWB writes
`scan_timeout = 1000` into `~/.config/starship.toml` automatically if
it isn't already set. Re-run `gwb restore <profile>` (or `gwb repair
<profile>`) on an older checkout to pick it up. To set it manually:

```powershell
Add-Content "$env:USERPROFILE\.config\starship.toml" "scan_timeout = 1000"
```

**Note on the value**: an earlier version of this fix shipped
`scan_timeout = 100`, which turned out to still be too tight for
`System32` on real hardware (measured at ~305ms per scan directly via
`starship prompt --path`, three consecutive runs, no caching tricks) -
confirmed live, not assumed. `Install-GwbStarshipConfig` never
overwrites an *existing* `scan_timeout`, by design (it might be a real
user customization) - if you picked up the `100` value from an older
GWB checkout, you'll need to bump it manually with the command above;
`gwb restore`/`repair` won't touch it for you.

If you're consistently launching into `System32`, see the next entry —
GWB now handles the most common cause of that automatically.

---

## PowerShell always starts in `C:\Windows\System32`

**Confirmed** — hit directly by Greg via a taskbar-pinned icon.

**Symptom**: every new shell starts in `C:\Windows\System32` instead of
your home directory, regardless of any shortcut "Start in" field or
Windows Terminal `startingDirectory` setting.

**Cause**: the MSIX-packaged PowerShell app
(`Microsoft.PowerShell_8wekyb3d8bbwe!App`, distinct from Windows
Terminal) and elevated ("Run as administrator") launches in general
default their working directory to `System32` — there's no
shortcut-level setting that overrides this for a packaged or elevated
launch, unlike a classic `.lnk`'s "Start in" field.

**Fix**: as of the guard added to `profile-snippet.ps1` (see
`CHANGELOG.md`), GWB resets to `$env:USERPROFILE` automatically
whenever a shell starts in `System32`, and only then — any other
starting directory (including a deliberate one from a real shortcut) is
left alone. Re-run `gwb restore <profile>` on an older checkout to pick
it up. If you want to jump to a specific working directory instead
(e.g. a projects folder), add your own function/alias directly to
`$PROFILE` **outside** the `# >>> GWB managed block >>>` markers so it
survives future restores untouched.

---

## `gwb.ps1` fails immediately with a PowerShell version error

**Confirmed** — hit directly on a second real machine, a new laptop
with only Windows PowerShell 5.1 installed.

**Symptom**: running `.\gwb.ps1 ...` (any command at all) fails
immediately, before any GWB banner or output, with something like
`The script 'gwb.ps1' cannot be run because it contained a "#requires"
statement for PowerShell version 7.0`.

**Cause**: `gwb.ps1` declares `#Requires -Version 7.0` at the top, and
Windows doesn't ship PowerShell 7 by default — only the older, separate
Windows PowerShell 5.1 engine. GWB is PowerShell 7+ only by design (see
`CLAUDE.md`'s Language line and `docs/CODING_STANDARDS.md`).

**Fix**: install PowerShell 7 first (a one-time step, independent of
GWB itself), then always invoke `gwb.ps1`/`gwb` via `pwsh`, not
`powershell`:

```powershell
winget install --id Microsoft.PowerShell -e
```

Confirmed live: this installs PowerShell 7 as an MSIX package
(`C:\Program Files\WindowsApps\Microsoft.PowerShell_...`, resolved on
`PATH` via an App Execution Alias) rather than the classic
`C:\Program Files\PowerShell\7\pwsh.exe` MSI layout — either way,
`pwsh` resolves correctly on `PATH` once installed, and no further
configuration is needed for `gwb.ps1` itself to run.

---

## New terminal windows still open PowerShell 5.1 after installing PowerShell 7

**Confirmed** — hit directly on the same new laptop, right after
installing PowerShell 7 to unblock the issue above.

**Symptom**: PowerShell 7 is installed and `pwsh` works when typed
explicitly, but closing and reopening a terminal still lands back in
Windows PowerShell 5.1 — a different, separate profile from the one
`gwb restore` just configured.

**Cause**: installing PowerShell 7 via winget adds it alongside Windows
PowerShell 5.1 — it doesn't become the default shell for any shortcut,
Start menu entry, or Windows Terminal profile automatically. The two
engines also have entirely separate `$PROFILE` files (Windows
PowerShell 5.1 uses `...\Documents\WindowsPowerShell\...`; PowerShell 7
uses `...\Documents\PowerShell\...` — on a machine where `Documents` is
OneDrive-redirected, both live under that synced path instead of
directly under `C:\Users\<name>\Documents`), so `gwb restore`'s changes
are invisible from the 5.1 profile.

**Fix**: launch PowerShell 7 explicitly (Start menu → "PowerShell 7",
or type `pwsh` in an existing window), or set it as Windows Terminal's
default profile so new tabs/windows use it automatically:

1. Install PowerShell 7 (see the entry above) — Windows Terminal
   auto-detects it and adds its own `"PowerShell"` profile
   (`source: Windows.Terminal.PowershellCore`) to `settings.json` the
   next time it enumerates profiles.
2. Set that profile's `guid` as `defaultProfile` in Windows Terminal's
   `settings.json` (for the Store-packaged install:
   `%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\
   LocalState\settings.json`).
3. **Fully close every Windows Terminal window before relying on the
   change** — if Windows Terminal is left running while `settings.json`
   is edited externally, it can overwrite the file again from its own
   in-memory state. Confirmed live: an in-progress manual edit was
   silently overwritten mid-session when Windows Terminal itself
   regenerated the file after detecting the new PowerShell 7 install.

This is a Windows Terminal / PowerShell configuration detail, not
something `gwb restore` manages — see `docs/PHILOSOPHY.md` ("Enhance
the Terminal You Have, Don't Replace It").

---

## PSFzf fails to load: "An Application Control policy has blocked this file"

**Confirmed** — hit directly by Greg in a real terminal.

**Symptom**: every new PowerShell window prints something like:

```
Import-Module: ...\Microsoft.PowerShell_profile.ps1:35
     | Could not load file or assembly '...\Modules\PSFzf\<version>\PSFzf.dll'.
     | An Application Control policy has blocked this file. (0x800711C7)
Set-PsFzfOption: ...
     | The 'Set-PsFzfOption' command was found in the module 'PSFzf', but the module could not be loaded...
```

optionally followed by a much slower-than-usual "Loading personal and
system profiles took ...ms." line.

**Cause**: Windows Defender Application Control, Smart App Control, or a
similar third-party Application Control policy blocked `PSFzf.dll` from
loading — `PSFzf` installed successfully (`Install-Module` and
`Get-Module -ListAvailable` both see it fine), but the *.dll* itself
didn't pass the machine's code-integrity policy at load time. This is a
machine/organization security policy decision, not a GWB or PSFzf bug —
the same category as IPBan's Administrator-elevation requirement
(`docs/PROJECT.md`'s Non-Goals): GWB won't try to work around a security
control the machine owner (or their org) has deliberately put in place.

**Fix**: as of the `try`/`catch` added around `Import-Module PSFzf` in
all three `profile-snippet.ps1` files (see `CHANGELOG.md`), a blocked
policy now fails quietly instead of printing errors (and adding load
time) on every single shell startup. Re-run `gwb restore <profile>` (or
`gwb repair <profile>`) on an older checkout to pick it up.

**`Ctrl+f`/`Ctrl+r` themselves are also restored**, not just silenced —
confirmed directly that when the policy blocks `PSFzf.dll`, the signed
`fzf.exe` binary itself still runs fine (its interactive UI opens and
works normally; only the PowerShell module *assembly* fails the
code-integrity check). So when `PSFzf` fails to load but `fzf.exe` is on
`PATH`, `profile-snippet.ps1` now wires up the same two keybindings by
hand via `Set-PSReadLineKeyHandler`, shelling out to `fzf.exe` directly
instead of going through the blocked DLL — `Ctrl+r` fuzzy-searches
PSReadLine's history file, `Ctrl+f` fuzzy-searches the current
directory's contents (non-recursive — deliberately simpler than PSFzf's
own recursive/provider-aware search; a fallback, not a
reimplementation). To get the *real* PSFzf module working again (its
fuller feature set), the policy itself still needs to allow
`PSFzf.dll` — check with whoever manages Application Control on the
machine (a home-grown WDAC policy, an MDM-pushed Smart App Control
setting, or org-wide endpoint security software) about an exception;
GWB has no part in that decision or process.

---

## `eza`/Starship icons render as boxes or blanks

**Anticipated** — the same class of issue GLB documents extensively for
its own Linux terminal emulators, not yet personally hit here (this
machine's terminal already has a Nerd Font configured).

**Cause**: `eza --icons` and Starship's default symbols need a
[Nerd Font](https://www.nerdfonts.com/) — the glyphs simply don't exist
in an ordinary font.

**Fix**: install a Nerd Font (e.g. via `winget install
DEVCOM.JetBrainsMonoNerdFont`) and set it as the font for whichever
terminal you're using (Windows Terminal, VS Code's integrated terminal,
etc.) — GWB doesn't manage the terminal emulator itself, see
`docs/PHILOSOPHY.md`.

---

> Add entries here as real problems come up — keep the
> Confirmed/Anticipated distinction honest rather than presenting a
> guess as verified.
