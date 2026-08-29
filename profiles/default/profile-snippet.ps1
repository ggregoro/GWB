# GWB default profile snippet - injected into $PROFILE between the
# GWB managed-block markers. Keep this idempotent and side-effect-free
# beyond function/alias/prompt definitions.

# The MSIX-packaged PowerShell app (and elevated/"Run as administrator"
# launches in general) can start the shell in C:\Windows\System32
# regardless of any shortcut or Windows Terminal startingDirectory
# setting - confirmed directly (a taskbar pin resolving to
# Microsoft.PowerShell_8wekyb3d8bbwe!App, no Windows Terminal settings
# involved at all). Reset only when that's literally where we landed, so
# a deliberate "start here" shortcut elsewhere is never overridden.
if ($PWD.Path -eq (Join-Path $env:SystemRoot "System32")) {
    Set-Location $env:USERPROFILE
}

if (Get-Command eza -ErrorAction SilentlyContinue) {
    # PowerShell ships a built-in `ls` -> Get-ChildItem alias, and alias
    # resolution always wins over a same-named function - confirmed
    # directly (a function alone silently never gets invoked via bare
    # `ls`, even though `Get-Command ls -All` shows both registered).
    # `ll`/`la` don't collide with any built-in alias, so they're fine.
    # `--hyperlink` (OSC 8, Ctrl-click to open) is on `ll`/`la` only, not
    # plain `ls` - mirrors GLB's own default (added there 2026-08-18).
    Remove-Item -Path Alias:ls -Force -ErrorAction SilentlyContinue
    function ls  { eza --icons --group-directories-first @args }
    function ll  { eza --icons --group-directories-first --hyperlink -lah @args }
    function la  { eza --icons --group-directories-first --hyperlink -a @args }
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    Set-Alias -Name cat -Value bat -Option AllScope -Force
}

if (Get-Command fzf -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"
}

if (Get-Module -ListAvailable -Name PSFzf) {
    # An Application Control policy (Windows Defender Application Control,
    # Smart App Control, or a similar third-party policy) can block
    # PSFzf.dll from loading (Import-Module fails with 0x800711C7) even
    # though the module installed fine - a machine security policy GWB
    # can't and shouldn't work around (same "not GWB's to fix" stance as
    # IPBan in the server profile). Fail quietly so a blocked policy
    # doesn't throw errors on every shell startup.
    try {
        Import-Module PSFzf -ErrorAction Stop
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
    } catch {
        # Blocked by policy (or some other load failure) - Ctrl+f/Ctrl+r
        # fuzzy history/provider search just won't be available this session.
    }
}

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

# PSReadLine ships with PowerShell 7 - nothing to install, just
# configure it. Predictive text needs a console with virtual-terminal
# support, which not every context has (e.g. output redirected/piped).
# Confirmed directly: -ErrorAction SilentlyContinue alone does NOT
# suppress the resulting message there (PSReadLine writes it in a way
# that bypasses the normal error-record pipeline) - only promoting it
# to a terminating error via -ErrorAction Stop and catching it does.
if (Get-Module -ListAvailable -Name PSReadLine) {
    try {
        Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView -ErrorAction Stop
    } catch {
        # No VT-capable console here - leave PSReadLine at its defaults.
    }
}

# winget installs the `file` MIME-type-detection tool (needed by
# yazi's previewer - without it, every preview fails with "Cannot find
# 'file' to detect the file's MIME type.") but does not add it to PATH -
# confirmed directly (it's an Inno Setup installer, not PATH-shimmed the
# way winget's CLI-tool installers are). Add its directory explicitly,
# same "winget doesn't PATH-shim this" pattern already handled for Far
# Manager - guarded so this is a no-op if it isn't installed or its
# directory is already on PATH.
$GwbFileBin = Join-Path ${env:ProgramFiles(x86)} "GnuWin32\bin"
if ((Test-Path (Join-Path $GwbFileBin "file.exe")) -and ($env:Path -notlike "*$GwbFileBin*")) {
    $env:Path = "$env:Path;$GwbFileBin"
}
Remove-Variable -Name GwbFileBin -ErrorAction SilentlyContinue

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression ((&starship init powershell) -join "`n")
}
