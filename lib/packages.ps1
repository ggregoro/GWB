# lib/packages.ps1
# Mirrors GLB's lib/package.sh: a flat packages.txt of logical tool names,
# resolved to winget package IDs via an override table, plus install/remove/
# list wrapping winget itself.

$Script:_GWB_PACKAGE_OVERRIDES = @{
    "eza"      = "eza-community.eza"
    "fzf"      = "junegunn.fzf"
    "lf"       = "gokcehan.lf"
    "ripgrep"  = "BurntSushi.ripgrep.MSVC"
    "fd"       = "sharkdp.fd"
    "bat"      = "sharkdp.bat"
    "zoxide"   = "ajeetdsouza.zoxide"
    "git"      = "Git.Git"
    "wezterm"  = "wez.wezterm"
    "ghostty"  = "ghostty.ghostty"
    "starship" = "Starship.Starship"
    "jq"       = "jqlang.jq"
    "gh"       = "GitHub.cli"
    "mise"     = "jdx.mise"
    "fresh"    = "sinelaw.fresh-editor"
    "mingw"    = "BrechtSanders.WinLibs.POSIX.UCRT"
    "restic"   = "restic.restic"
    "btop"     = "aristocratos.btop4win"
    "farmanager" = "FarManager.FarManager"
    "yazi"     = "sxyazi.yazi"
    "file"     = "GnuWin32.File"
}

function Resolve-GwbPackageId {
    param([Parameter(Mandatory)][string]$Name)
    if ($Script:_GWB_PACKAGE_OVERRIDES.ContainsKey($Name)) {
        return $Script:_GWB_PACKAGE_OVERRIDES[$Name]
    }
    return $Name
}

function Test-GwbPackageInstalled {
    param([Parameter(Mandatory)][string]$Id)
    $null = winget list --id $Id -e --accept-source-agreements 2>&1
    return ($LASTEXITCODE -eq 0)
}

function Install-GwbPackage {
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$WhatIf
    )

    $id = Resolve-GwbPackageId -Name $Name

    if (Test-GwbPackageInstalled -Id $id) {
        Write-Ok "Already installed: $Name"
        return
    }

    if ($WhatIf) {
        Write-Info "[WhatIf] Would install $Name -> $id"
        return
    }

    Write-Info "Installing $Name ($id)..."
    winget install --id $id --silent --accept-package-agreements --accept-source-agreements -e
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Failed to install $Name ($id) - exit $LASTEXITCODE"
    } else {
        Write-Ok "$Name installed"
    }
}

function Remove-GwbPackage {
    param([Parameter(Mandatory)][string]$Name)

    $id = Resolve-GwbPackageId -Name $Name
    Write-Info "Removing $Name ($id)..."
    winget uninstall --id $id -e --accept-source-agreements
    if ($LASTEXITCODE -ne 0) {
        Write-Fail "Failed to remove $Name ($id) - exit $LASTEXITCODE"
    } else {
        Write-Ok "$Name removed"
    }
}

function Install-GwbPackageList {
    param(
        [Parameter(Mandatory)][string]$Path,
        [switch]$WhatIf
    )

    if (-not (Test-Path $Path)) {
        Write-Fail "Package list not found: $Path"
        return
    }

    $names = Get-Content $Path | Where-Object {
        $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#")
    }

    foreach ($name in $names) {
        Install-GwbPackage -Name $name.Trim() -WhatIf:$WhatIf
    }
}

function Update-GwbPackages {
    Write-Info "Running winget upgrade --all..."
    winget upgrade --all --silent --accept-package-agreements --accept-source-agreements
    return ($LASTEXITCODE -eq 0)
}
