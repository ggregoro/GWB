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
