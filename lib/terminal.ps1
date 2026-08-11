# lib/terminal.ps1
# Optional Windows Terminal settings.json integration. Not wired into any
# shipped profile yet - GLB's own experience with managing a terminal
# emulator (WezTerm) turned into enough real trouble that it was removed
# from GLB's scope entirely. Kept here as an opt-in stub only, not applied
# unless a profile ships its own windows-terminal-settings.json.

function Install-GwbWindowsTerminalSettings {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$WhatIf
    )

    $wtSettingsPath = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"

    if (-not (Test-Path $wtSettingsPath)) {
        Write-Info "Windows Terminal settings.json not found, skipping (is WT installed?)"
        return
    }

    if ($WhatIf) {
        Write-Info "[WhatIf] Would merge $Path into Windows Terminal settings"
        return
    }

    # NOTE: a real implementation needs a careful JSON merge here
    # (profiles/colorSchemes are arrays keyed by guid/name), not a blind
    # overwrite. Not built - no shipped profile uses this yet.
    Write-Info "TODO: implement JSON merge instead of overwrite"
}
