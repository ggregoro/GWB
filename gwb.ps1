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
$LibDir      = Join-Path $GwbRoot "lib"

. (Join-Path $LibDir "log.ps1")
. (Join-Path $LibDir "banner.ps1")
. (Join-Path $LibDir "detect.ps1")
. (Join-Path $LibDir "packages.ps1")
. (Join-Path $LibDir "profile.ps1")
. (Join-Path $LibDir "terminal.ps1")

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
    Write-Host "  profiles                      List available profiles"
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

        foreach ($arg in $Rest) {
            switch -Regex ($arg) {
                '^--dry-run$' { $dryRun = $true }
                '^--undo$'    { $undo = $true }
                default       { $profileName = $arg }
            }
        }

        if ($undo) {
            Undo-GwbRestore
        } elseif (-not $profileName) {
            Invoke-GwbRestoreInteractive -ProfilesRoot $ProfilesRoot -WhatIf:$dryRun
        } else {
            $dir = Join-Path $ProfilesRoot $profileName
            Invoke-GwbApplyProfile -ProfileDir $dir -ProfileName $profileName -WhatIf:$dryRun
        }
    }

    "profiles" { Show-GwbProfiles }

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
