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
