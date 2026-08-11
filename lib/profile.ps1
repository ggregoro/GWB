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

function Install-GwbProfileSnippet {
    param(
        [Parameter(Mandatory)][string]$SnippetPath,
        [switch]$WhatIf
    )

    if (-not (Test-Path $SnippetPath)) {
        Write-Fail "Profile snippet not found: $SnippetPath"
        return
    }

    $marker = "# >>> GWB managed block >>>"
    $endMarker = "# <<< GWB managed block <<<"
    $snippetContent = (Get-Content $SnippetPath -Raw).TrimEnd()

    $existing = if (Test-Path $PROFILE) { (Get-Content $PROFILE -Raw).TrimEnd() } else { "" }
    $backupPath = "$PROFILE.gwb-backup"
    $hasMarker = $existing -match [regex]::Escape($marker)

    if ($WhatIf) {
        if ($hasMarker) {
            Write-Info "[WhatIf] Would replace GWB managed block in `$PROFILE"
        } else {
            Write-Info "[WhatIf] Would back up `$PROFILE to $backupPath (if it has content) and append GWB managed block"
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
        $pattern = "(?s)$([regex]::Escape($marker)).*?$([regex]::Escape($endMarker))"
        $replacement = "$marker`n$snippetContent`n$endMarker"
        $updated = $existing -replace $pattern, $replacement
    } else {
        $prefix = if ($existing -eq "") { "" } else { "$existing`n`n" }
        $updated = "$prefix$marker`n$snippetContent`n$endMarker"
    }

    Set-Content -Path $PROFILE -Value $updated
    Write-Ok "Profile updated: $PROFILE"
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

    Write-Step "Wiring up PowerShell profile"
    $snippet = Join-Path $ProfileDir "profile-snippet.ps1"
    Install-GwbProfileSnippet -SnippetPath $snippet -WhatIf:$WhatIf

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

    $choice = Read-Host "Choose a profile"
    if (-not ($choice -match '^\d+$') -or [int]$choice -lt 1 -or [int]$choice -gt $profiles.Count) {
        Write-Fail "Invalid choice: $choice"
        return
    }

    $chosen = $profiles[[int]$choice - 1]
    Invoke-GwbApplyProfile -ProfileDir $chosen.FullName -ProfileName $chosen.Name -WhatIf:$WhatIf
}
