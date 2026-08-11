#Requires -Version 7.0
<#
.SYNOPSIS
    GWB (Greg's Windows Bootstrap) - the PowerShell/Windows sibling to GLB.
    Bootstraps a curated terminal setup (winget packages + PowerShell
    $PROFILE) in one pass, mirroring GLB's dispatcher + lib/ shape.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)][string]$Command,
    [Parameter(Position = 1, ValueFromRemainingArguments = $true)][string[]]$Rest
)

$ErrorActionPreference = "Stop"
$GwbRoot     = $PSScriptRoot
$GwbVersion  = (Get-Content (Join-Path $GwbRoot "VERSION") -Raw).Trim()
$ProfilesRoot = Join-Path $GwbRoot "profiles"
$SnapshotsRoot = Join-Path $GwbRoot "snapshots"
$LibDir      = Join-Path $GwbRoot "lib"

. (Join-Path $LibDir "log.ps1")
. (Join-Path $LibDir "banner.ps1")
. (Join-Path $LibDir "detect.ps1")
. (Join-Path $LibDir "packages.ps1")
. (Join-Path $LibDir "profile.ps1")
. (Join-Path $LibDir "terminal.ps1")
. (Join-Path $LibDir "export.ps1")
. (Join-Path $LibDir "diff.ps1")
. (Join-Path $LibDir "repair.ps1")

function Show-GwbHelp {
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  gwb <command>"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  help                          Show this help message"
    Write-Host "  version                       Show GWB version"
    Write-Host "  info                          Show system information"
    Write-Host "  install <pkg>                 Install a package"
    Write-Host "  remove <pkg>                  Remove a package"
    Write-Host "  update                        Upgrade all winget-managed packages"
    Write-Host "  restore [profile]             Apply a profile (packages + `$PROFILE)"
    Write-Host "  restore                       With no profile name, choose one interactively"
    Write-Host "  restore --dry-run             Preview what a restore would do"
    Write-Host "  restore --undo                Undo the last restore's `$PROFILE changes"
    Write-Host "  restore --from-snapshot <name> Apply a snapshot captured by 'gwb export'"
    Write-Host "  profiles                      List available profiles"
    Write-Host "  export                        Snapshot this machine's known packages + `$PROFILE"
    Write-Host "  diff <a> <b>                  Compare two profiles/snapshots for drift"
    Write-Host "  repair <profile>              Check this machine against a profile"
    Write-Host ""
}

function Show-GwbInfo {
    Write-Host ""
    Write-Host "System Information"
    Write-Host "------------------"
    Write-Host "OS:              $(Get-GwbOSName)"
    Write-Host "OS Version:      $(Get-GwbOSVersion)"
    Write-Host "PowerShell:      $(Get-GwbShellVersion)"
    Write-Host "winget:          $(if (Test-GwbWinget) { 'found' } else { 'NOT FOUND' })"
    Write-Host ""
}

function Show-GwbProfiles {
    $profiles = @(Get-GwbProfileList -ProfilesRoot $ProfilesRoot)
    if ($profiles.Count -eq 0) {
        Write-Fail "No profiles found in $ProfilesRoot"
        return
    }
    Write-Host ""
    Write-Host "Available profiles:"
    foreach ($p in $profiles) {
        $desc = Get-GwbProfileDescription -ProfileDir $p.FullName
        $line = "  $($p.Name)"
        if ($desc) { $line += " - $desc" }
        Write-Host $line
    }
    Write-Host ""
}

Write-GwbBanner -Version $GwbVersion

switch ($Command) {
    "help"    { Show-GwbHelp }
    "version" { Write-Host "GWB Version $GwbVersion" }
    "info"    { Show-GwbInfo }

    "install" {
        if (-not $Rest -or -not $Rest[0]) { Write-Fail "Usage: gwb install <package>"; break }
        Install-GwbPackage -Name $Rest[0]
    }

    "remove" {
        if (-not $Rest -or -not $Rest[0]) { Write-Fail "Usage: gwb remove <package>"; break }
        Remove-GwbPackage -Name $Rest[0]
    }

    "update" {
        $ok = Update-GwbPackages
        if (-not $ok) { exit 1 }
    }

    "restore" {
        $dryRun = $false
        $undo = $false
        $profileName = $null
        $snapshotName = $null

        $i = 0
        while ($i -lt $Rest.Count) {
            $arg = $Rest[$i]
            switch -Regex ($arg) {
                '^--dry-run$' { $dryRun = $true }
                '^--undo$'    { $undo = $true }
                '^--from-snapshot$' {
                    $i++
                    $snapshotName = $Rest[$i]
                }
                default       { $profileName = $arg }
            }
            $i++
        }

        if ($undo) {
            Undo-GwbRestore
        } elseif ($snapshotName) {
            $dir = Join-Path $SnapshotsRoot $snapshotName
            if (-not (Test-Path $dir)) {
                Write-Fail "Snapshot not found: $snapshotName"
            } else {
                Invoke-GwbApplyProfile -ProfileDir $dir -ProfileName $snapshotName -WhatIf:$dryRun
            }
        } elseif (-not $profileName) {
            Invoke-GwbRestoreInteractive -ProfilesRoot $ProfilesRoot -WhatIf:$dryRun
        } else {
            $dir = Join-Path $ProfilesRoot $profileName
            Invoke-GwbApplyProfile -ProfileDir $dir -ProfileName $profileName -WhatIf:$dryRun
        }
    }

    "profiles" { Show-GwbProfiles }

    "export" {
        Export-GwbSnapshot -ProfilesRoot $ProfilesRoot -SnapshotsRoot $SnapshotsRoot | Out-Null
    }

    "diff" {
        if (-not $Rest -or $Rest.Count -lt 2) { Write-Fail "Usage: gwb diff <a> <b>"; break }
        $result = Invoke-GwbDiff -A $Rest[0] -B $Rest[1] -ProfilesRoot $ProfilesRoot -SnapshotsRoot $SnapshotsRoot
        if ($result -ne 0) { exit $result }
    }

    "repair" {
        if (-not $Rest -or -not $Rest[0]) { Write-Fail "Usage: gwb repair <profile>"; break }
        $result = Invoke-GwbRepair -ProfileName $Rest[0] -ProfilesRoot $ProfilesRoot
        if ($result -ne 0) { exit $result }
    }

    default {
        if ($Command) {
            Write-Fail "Unknown command: $Command"
        }
        Show-GwbHelp
        if ($Command) { exit 1 }
    }
}

# Scripts that end without an explicit `exit` inherit $LASTEXITCODE from
# whatever native command (e.g. winget) last ran internally - reset it here
# so a caller's `if ($LASTEXITCODE -eq 0)` reflects gwb's own outcome, not
# an unrelated winget query several calls back.
exit 0
