# lib/profile.ps1
# Mirrors GLB's lib/profile.sh: applies a profile (packages + $PROFILE
# snippet), the interactive picker, and --undo rollback.

function Get-GwbProfileList {
    param([Parameter(Mandatory)][string]$ProfilesRoot)
    if (-not (Test-Path $ProfilesRoot)) { return @() }
    Get-ChildItem -Path $ProfilesRoot -Directory | Sort-Object Name
}

function Get-GwbProfileDescription {
    param([Parameter(Mandatory)][string]$ProfileDir)
    $descPath = Join-Path $ProfileDir "description.txt"
    if (Test-Path $descPath) {
        return (Get-Content $descPath -Raw).Trim()
    }
    return ""
}

# Shared by Install-GwbProfileSnippet and (lib/completions.ps1's)
# Install-GwbSelfRegistration - each owns its own marker pair so the
# two concerns never collide, but both go through the same
# backup-on-first-touch + idempotent replace-in-place logic. Whichever
# one runs first creates $PROFILE.gwb-backup; the other sees it already
# exists and correctly skips re-backing-up.
function Set-GwbManagedBlock {
    param(
        [Parameter(Mandatory)][string]$Marker,
        [Parameter(Mandatory)][string]$EndMarker,
        [Parameter(Mandatory)][string]$Content,
        [Parameter(Mandatory)][string]$Label,
        [switch]$WhatIf
    )

    $existing = if (Test-Path $PROFILE) { (Get-Content $PROFILE -Raw).TrimEnd() } else { "" }
    $backupPath = "$PROFILE.gwb-backup"
    $hasMarker = $existing -match [regex]::Escape($Marker)

    if ($WhatIf) {
        if ($hasMarker) {
            Write-Info "[WhatIf] Would replace $Label block in `$PROFILE"
        } else {
            Write-Info "[WhatIf] Would back up `$PROFILE to $backupPath (if it has content) and append $Label block"
        }
        return
    }

    # Preserve the true pre-GWB profile exactly once - never overwrite an
    # existing backup on a later re-apply (see GLB's dotfile-backup fix).
    if (-not $hasMarker -and $existing.Trim() -ne "" -and -not (Test-Path $backupPath)) {
        Copy-Item -Path $PROFILE -Destination $backupPath -Force
        Write-Info "Backed up existing `$PROFILE to $backupPath"
    }

    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    if ($hasMarker) {
        $pattern = "(?s)$([regex]::Escape($Marker)).*?$([regex]::Escape($EndMarker))"
        $replacement = "$Marker`n$Content`n$EndMarker"
        $updated = $existing -replace $pattern, $replacement
    } else {
        $prefix = if ($existing -eq "") { "" } else { "$existing`n`n" }
        $updated = "$prefix$Marker`n$Content`n$EndMarker"
    }

    # -NoNewline plus an explicit trailing `n: Set-Content's own auto-appended
    # newline uses the platform default (CRLF on Windows), which would mix
    # with the LF line endings already built into $updated via `n - giving
    # a file with inconsistent line endings (harmless to PowerShell, but a
    # real mismatch for anything that compares file content byte-for-byte,
    # like `gwb export`/`gwb diff`).
    Set-Content -Path $PROFILE -Value "$updated`n" -NoNewline
    Write-Ok "$Label updated: $PROFILE"
}

function Install-GwbProfileSnippet {
    param(
        [Parameter(Mandatory)][string]$SnippetPath,
        [switch]$WhatIf
    )

    if (-not (Test-Path $SnippetPath)) {
        Write-Fail "Profile snippet not found: $SnippetPath"
        return
    }

    $snippetContent = (Get-Content $SnippetPath -Raw).TrimEnd()
    Set-GwbManagedBlock -Marker "# >>> GWB managed block >>>" -EndMarker "# <<< GWB managed block <<<" `
        -Content $snippetContent -Label "Profile" -WhatIf:$WhatIf
}

function Undo-GwbRestore {
    $backupPath = "$PROFILE.gwb-backup"
    if (-not (Test-Path $backupPath)) {
        Write-Fail "No backup found at $backupPath - nothing to undo"
        return
    }
    Copy-Item -Path $backupPath -Destination $PROFILE -Force
    Write-Ok "Restored `$PROFILE from $backupPath"
}

function Invoke-GwbApplyProfile {
    param(
        [Parameter(Mandatory)][string]$ProfileDir,
        [Parameter(Mandatory)][string]$ProfileName,
        [switch]$WhatIf
    )

    if (-not (Test-Path $ProfileDir)) {
        Write-Fail "Profile not found: $ProfileName"
        return
    }

    Write-Step "Installing packages from profile '$ProfileName'"
    Install-GwbPackageList -Path (Join-Path $ProfileDir "packages.txt") -WhatIf:$WhatIf

    $modulesFile = Join-Path $ProfileDir "modules.txt"
    if (Test-Path $modulesFile) {
        Write-Step "Installing PowerShell modules from profile '$ProfileName'"
        Install-GwbModuleList -Path $modulesFile -WhatIf:$WhatIf
    }

    Write-Step "Wiring up PowerShell profile"
    $snippet = Join-Path $ProfileDir "profile-snippet.ps1"
    Install-GwbProfileSnippet -SnippetPath $snippet -WhatIf:$WhatIf

    Write-Step "Registering 'gwb' command + tab-completion"
    Install-GwbSelfRegistration -GwbRoot $GwbRoot -WhatIf:$WhatIf

    $wtSettings = Join-Path $ProfileDir "windows-terminal-settings.json"
    if (Test-Path $wtSettings) {
        Write-Step "Applying Windows Terminal settings"
        Install-GwbWindowsTerminalSettings -Path $wtSettings -WhatIf:$WhatIf
    }

    if (-not $WhatIf) {
        Write-Ok "Profile applied: $ProfileName"
    }
}

function Invoke-GwbRestoreInteractive {
    param(
        [Parameter(Mandatory)][string]$ProfilesRoot,
        [switch]$WhatIf
    )

    $profiles = @(Get-GwbProfileList -ProfilesRoot $ProfilesRoot)
    if ($profiles.Count -eq 0) {
        Write-Fail "No profiles found in $ProfilesRoot"
        return
    }

    Write-Host ""
    Write-Host "Available profiles:"
    for ($i = 0; $i -lt $profiles.Count; $i++) {
        $desc = Get-GwbProfileDescription -ProfileDir $profiles[$i].FullName
        $line = "  [$($i + 1)] $($profiles[$i].Name)"
        if ($desc) { $line += " - $desc" }
        Write-Host $line
    }
    Write-Host ""

    try {
        $choice = Read-Host "Choose a profile"
    } catch {
        Write-Fail "No input available - cancelled"
        return
    }
    if (-not ($choice -match '^\d+$') -or [int]$choice -lt 1 -or [int]$choice -gt $profiles.Count) {
        Write-Fail "Invalid choice: $choice"
        return
    }

    $chosen = $profiles[[int]$choice - 1]
    Invoke-GwbApplyProfile -ProfileDir $chosen.FullName -ProfileName $chosen.Name -WhatIf:$WhatIf
}
