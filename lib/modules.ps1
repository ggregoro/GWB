# lib/modules.ps1
# The PowerShell/Install-Module analogue of GLB's lib/extras.sh, scoped
# to what GWB actually needs today: a flat modules.txt (mirroring
# packages.txt exactly), one PowerShell Gallery module name per line.
# No multi-method format (GLB's extras.txt has curl/flatpak/font) since
# every extra GWB has right now is the same method - add one only if a
# second real method ever comes up.

function Test-GwbModuleInstalled {
    param([Parameter(Mandatory)][string]$Name)
    [bool](Get-Module -ListAvailable -Name $Name)
}

function Install-GwbModule {
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$WhatIf
    )

    if (Test-GwbModuleInstalled -Name $Name) {
        Write-Ok "Already installed: $Name"
        return
    }

    if ($WhatIf) {
        Write-Info "[WhatIf] Would install module $Name"
        return
    }

    Write-Info "Installing module $Name..."
    try {
        # -Force also suppresses PSGallery's untrusted-repository
        # confirmation prompt (verified directly - PSGallery's
        # InstallationPolicy is Untrusted by default even on a machine
        # that's used Install-Module before) - without it this would
        # hang waiting for input in a non-interactive restore.
        Install-Module -Name $Name -Scope CurrentUser -Force -ErrorAction Stop
        Write-Ok "$Name installed"
    } catch {
        Write-Fail "Failed to install module $Name - $($_.Exception.Message)"
    }
}

function Install-GwbModuleList {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$WhatIf
    )

    if (-not (Test-Path $Path)) {
        Write-Fail "Module list not found: $Path"
        return
    }

    Get-Content $Path | Where-Object {
        $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#")
    } | ForEach-Object {
        Install-GwbModule -Name $_.Trim() -WhatIf:$WhatIf
    }
}
