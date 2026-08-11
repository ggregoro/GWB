# GWB server profile snippet - same shared aliases as `default`.
# No server-specific shell activation needed (restic needs none).
# Keep this idempotent and side-effect-free beyond function/alias/
# prompt definitions.

if (Get-Command eza -ErrorAction SilentlyContinue) {
    # PowerShell ships a built-in `ls` -> Get-ChildItem alias, and alias
    # resolution always wins over a same-named function - confirmed
    # directly (a function alone silently never gets invoked via bare
    # `ls`, even though `Get-Command ls -All` shows both registered).
    # `ll`/`la` don't collide with any built-in alias, so they're fine.
    Remove-Item -Path Alias:ls -Force -ErrorAction SilentlyContinue
    function ls  { eza --icons --group-directories-first @args }
    function ll  { eza --icons --group-directories-first -lah @args }
    function la  { eza --icons --group-directories-first -a @args }
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    Set-Alias -Name cat -Value bat -Option AllScope -Force
}

if (Get-Command fzf -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"
}

if (Get-Module -ListAvailable -Name PSFzf) {
    Import-Module PSFzf
    Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
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

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression ((&starship init powershell) -join "`n")
}
