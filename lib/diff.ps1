# lib/diff.ps1
# Mirrors GLB's lib/diff.sh: compares two profile-shaped directories
# (a profile, a snapshot, or either against the other) for package and
# $PROFILE-snippet drift. Simpler than GLB's dotfile diff since GWB has
# exactly one managed file (profile-snippet.ps1) per profile/snapshot,
# not a whole dotfiles/ tree.

function Resolve-GwbDiffDir {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][string]$ProfilesRoot,
        [Parameter(Mandatory)][string]$SnapshotsRoot
    )

    $profileDir = Join-Path $ProfilesRoot $Name
    if (Test-Path $profileDir) { return $profileDir }

    $snapshotDir = Join-Path $SnapshotsRoot $Name
    if (Test-Path $snapshotDir) { return $snapshotDir }

    return $null
}

function Get-GwbPackageSet {
    param([Parameter(Mandatory)][string]$Dir)

    $pkgFile = Join-Path $Dir "packages.txt"
    if (-not (Test-Path $pkgFile)) { return @() }
    Get-Content $pkgFile | Where-Object {
        $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#")
    } | ForEach-Object { $_.Trim() }
}

function Invoke-GwbDiff {
    param(
        [Parameter(Mandatory)][string]$A,
        [Parameter(Mandatory)][string]$B,
        [Parameter(Mandatory)][string]$ProfilesRoot,
        [Parameter(Mandatory)][string]$SnapshotsRoot
    )

    $dirA = Resolve-GwbDiffDir -Name $A -ProfilesRoot $ProfilesRoot -SnapshotsRoot $SnapshotsRoot
    $dirB = Resolve-GwbDiffDir -Name $B -ProfilesRoot $ProfilesRoot -SnapshotsRoot $SnapshotsRoot

    if (-not $dirA) { Write-Fail "Could not resolve '$A' as a profile or snapshot"; return 1 }
    if (-not $dirB) { Write-Fail "Could not resolve '$B' as a profile or snapshot"; return 1 }

    return Invoke-GwbDiffDirs -A $A -DirA $dirA -B $B -DirB $dirB
}

function Invoke-GwbDiffDirs {
    param(
        [Parameter(Mandatory)][string]$A,
        [Parameter(Mandatory)][string]$DirA,
        [Parameter(Mandatory)][string]$B,
        [Parameter(Mandatory)][string]$DirB
    )

    $found = $false

    $setA = @(Get-GwbPackageSet -Dir $DirA)
    $setB = @(Get-GwbPackageSet -Dir $DirB)
    $onlyA = @($setA | Where-Object { $setB -notcontains $_ })
    $onlyB = @($setB | Where-Object { $setA -notcontains $_ })

    if ($onlyA.Count -gt 0 -or $onlyB.Count -gt 0) {
        $found = $true
        Write-Host ""
        Write-Host "Packages:"
        if ($onlyA.Count -gt 0) { Write-Host "  - $($onlyA -join ', ')  (only in $A)" -ForegroundColor Red }
        if ($onlyB.Count -gt 0) { Write-Host "  + $($onlyB -join ', ')  (only in $B)" -ForegroundColor Green }
    }

    $snippetA = Join-Path $DirA "profile-snippet.ps1"
    $snippetB = Join-Path $DirB "profile-snippet.ps1"
    $existsA = Test-Path $snippetA
    $existsB = Test-Path $snippetB

    if ($existsA -and -not $existsB) {
        $found = $true
        Write-Host "profile-snippet.ps1: only in $A" -ForegroundColor Red
    } elseif ($existsB -and -not $existsA) {
        $found = $true
        Write-Host "profile-snippet.ps1: only in $B" -ForegroundColor Green
    } elseif ($existsA -and $existsB) {
        # Normalize line endings before comparing - different writers (git's
        # autocrlf, Set-Content's platform-default newline) can produce
        # LF-vs-CRLF-only differences that aren't a real content change.
        $contentA = (Get-Content $snippetA -Raw) -replace "`r`n", "`n" -replace "`r", "`n"
        $contentB = (Get-Content $snippetB -Raw) -replace "`r`n", "`n" -replace "`r", "`n"
        $contentA = $contentA.TrimEnd("`n")
        $contentB = $contentB.TrimEnd("`n")
        if ($contentA -ne $contentB) {
            $found = $true
            Write-Host "~ profile-snippet.ps1 differs between $A and $B" -ForegroundColor Yellow
        }
    }

    if (-not $found) {
        Write-Ok "No drift found between $A and $B"
        return 0
    }
    return 1
}
