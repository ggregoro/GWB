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
    $hasEndMarker = $existing -match [regex]::Escape($EndMarker)

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

    # A start marker with no matching end marker means the block is
    # malformed (hand-edited, truncated, or corrupted some other way) -
    # confirmed for real, not hypothetical: a machine was found with its
    # end marker missing its trailing "<<<", which silently defeated the
    # regex replace below every single time (no match -> $existing came
    # back completely unchanged -> Set-Content wrote the identical content
    # right back -> Write-Ok still printed "updated" regardless). That let
    # a stale block survive an unknown number of "successful" restores
    # with zero indication anything was wrong. Fail loudly instead so this
    # is visible the moment it happens rather than staying invisible.
    if ($hasMarker -and -not $hasEndMarker) {
        Write-Fail "$Label block in `$PROFILE has a '$Marker' start marker but no matching '$EndMarker' end marker - the block looks corrupted or was hand-edited. Not touching it; fix or remove the stale marker manually, then re-run restore."
        return
    }

    if ($hasMarker) {
        $pattern = "(?s)$([regex]::Escape($Marker)).*?$([regex]::Escape($EndMarker))"
        $replacement = "$Marker`n$Content`n$EndMarker"
        # A MatchEvaluator, not a plain replacement string - the latter is
        # parsed as a .NET regex substitution template, where $ introduces
        # special sequences ($1, $&, $_ for the whole input string, etc.).
        # $Content is arbitrary PowerShell snippet text that legitimately
        # contains $ (e.g. $_.Trim(), $env:Path) - confirmed as a real risk
        # once profile-snippet content started including $_ (added for the
        # fzf.exe Ctrl+r/Ctrl+f fallback), not just a theoretical one. A
        # MatchEvaluator scriptblock returns its replacement literally, with
        # no substitution parsing at all.
        $updated = [regex]::Replace($existing, $pattern, { param($m) $replacement })
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

function Install-GwbStarshipConfig {
    param(
        [string]$ConfigPath = (Join-Path $env:USERPROFILE ".config\starship.toml"),
        [switch]$WhatIf
    )

    if (-not (Get-Command starship -ErrorAction SilentlyContinue)) { return }

    # Never touch an existing scan_timeout - only fill it in when absent,
    # the same "don't clobber what's already there" rule Set-GwbManagedBlock
    # follows for $PROFILE. Starship's own 30ms default times out scanning
    # large directories (e.g. C:\Windows\System32), printing a warning on
    # every prompt render.
    if ((Test-Path $ConfigPath) -and (Select-String -Path $ConfigPath -Pattern '^\s*scan_timeout\s*=' -Quiet -ErrorAction SilentlyContinue)) {
        return
    }

    if ($WhatIf) {
        Write-Info "[WhatIf] Would set scan_timeout in $ConfigPath"
        return
    }

    $configDir = Split-Path -Parent $ConfigPath
    if (-not (Test-Path $configDir)) {
        New-Item -ItemType Directory -Path $configDir -Force | Out-Null
    }

    if (-not (Test-Path $ConfigPath)) {
        Set-Content -Path $ConfigPath -Value "scan_timeout = 1000`n" -NoNewline
    } else {
        Add-Content -Path $ConfigPath -Value "`nscan_timeout = 1000"
    }
    Write-Ok "Starship config updated: $ConfigPath (scan_timeout = 1000)"
}

function Install-GwbYaziConfig {
    param(
        [Parameter(Mandatory)][string]$SourceDir,
        [string]$DestDir = (Join-Path $env:APPDATA "yazi\config"),
        [switch]$WhatIf
    )

    if (-not (Test-Path $SourceDir)) {
        Write-Fail "Yazi config source not found: $SourceDir"
        return
    }

    $backupDir = "$DestDir.gwb-backup"

    if ($WhatIf) {
        if (Test-Path $DestDir) {
            Write-Info "[WhatIf] Would replace yazi config at $DestDir"
        } else {
            Write-Info "[WhatIf] Would install yazi config to $DestDir"
        }
        return
    }

    # Preserve any real pre-existing config exactly once - same
    # backup-on-first-touch rule Set-GwbManagedBlock uses for $PROFILE -
    # never overwrite an existing backup on a later re-apply.
    if ((Test-Path $DestDir) -and -not (Test-Path $backupDir)) {
        Copy-Item -Path $DestDir -Destination $backupDir -Recurse -Force
        Write-Info "Backed up existing yazi config to $backupDir"
    }

    if (-not (Test-Path $DestDir)) {
        New-Item -ItemType Directory -Path $DestDir -Force | Out-Null
    }

    Copy-Item -Path (Join-Path $SourceDir "*") -Destination $DestDir -Recurse -Force
    Write-Ok "Yazi config installed: $DestDir"
}

function Undo-GwbRestore {
    param(
        [string]$YaziConfigPath = (Join-Path $env:APPDATA "yazi\config")
    )
    $profileBackupPath = "$PROFILE.gwb-backup"
    $yaziBackupPath = "$YaziConfigPath.gwb-backup"
    $restoredAny = $false

    if (Test-Path $profileBackupPath) {
        Copy-Item -Path $profileBackupPath -Destination $PROFILE -Force
        Write-Ok "Restored `$PROFILE from $profileBackupPath"
        $restoredAny = $true
    }

    if (Test-Path $yaziBackupPath) {
        if (Test-Path $YaziConfigPath) {
            Remove-Item -Path $YaziConfigPath -Recurse -Force
        }
        Copy-Item -Path $yaziBackupPath -Destination $YaziConfigPath -Recurse -Force
        Write-Ok "Restored yazi config from $yaziBackupPath"
        $restoredAny = $true
    }

    if (-not $restoredAny) {
        Write-Fail "No backup found - nothing to undo"
    }
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

    Write-Step "Configuring Starship"
    Install-GwbStarshipConfig -WhatIf:$WhatIf

    $yaziConfig = Join-Path $ProfileDir "yazi-config"
    if (Test-Path $yaziConfig) {
        Write-Step "Configuring yazi"
        Install-GwbYaziConfig -SourceDir $yaziConfig -WhatIf:$WhatIf
    }

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
