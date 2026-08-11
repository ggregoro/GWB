# lib/diff.ps1
# Mirrors GLB's lib/diff.sh: compares two profile-shaped directories
# (a profile, a snapshot, or either against the other) for package,
# module, and $PROFILE-snippet drift. Simpler than GLB's dotfile diff
# since GWB has exactly one managed file (profile-snippet.ps1) per
# profile/snapshot, not a whole dotfiles/ tree.

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

# Shared by packages.txt and modules.txt - same flat-list shape.
function Get-GwbFlatListSet {
    param(
        [Parameter(Mandatory)][string]$Dir,
        [Parameter(Mandatory)][string]$FileName
    )

    $listFile = Join-Path $Dir $FileName
    if (-not (Test-Path $listFile)) { return @() }
    Get-Content $listFile | Where-Object {
        $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#")
    } | ForEach-Object { $_.Trim() }
}

# Reports one "<Label>:" drift section (packages or modules) between two
# sets. Returns $true if any drift was found.
function Write-GwbSetDiff {
    param(
        [Parameter(Mandatory)][string]$Label,
        # AllowEmptyCollection: Mandatory + [string[]] alone rejects a real,
        # meaningful empty array (e.g. a profile with no modules.txt) as if
        # no value were passed at all - confirmed directly, a real bug that
        # never surfaced manually since every real profile has always had a
        # non-empty modules.txt.
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$SetA,
        [Parameter(Mandatory)][string]$A,
        [Parameter(Mandatory)][AllowEmptyCollection()][string[]]$SetB,
        [Parameter(Mandatory)][string]$B
    )

    $onlyA = @($SetA | Where-Object { $SetB -notcontains $_ })
    $onlyB = @($SetB | Where-Object { $SetA -notcontains $_ })

    if ($onlyA.Count -eq 0 -and $onlyB.Count -eq 0) { return $false }

    Write-Host ""
    Write-Host "${Label}:"
    if ($onlyA.Count -gt 0) { Write-Host "  - $($onlyA -join ', ')  (only in $A)" -ForegroundColor Red }
    if ($onlyB.Count -gt 0) { Write-Host "  + $($onlyB -join ', ')  (only in $B)" -ForegroundColor Green }
    return $true
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

    $pkgSetA = @(Get-GwbFlatListSet -Dir $DirA -FileName "packages.txt")
    $pkgSetB = @(Get-GwbFlatListSet -Dir $DirB -FileName "packages.txt")
    if (Write-GwbSetDiff -Label "Packages" -SetA $pkgSetA -A $A -SetB $pkgSetB -B $B) { $found = $true }

    $modSetA = @(Get-GwbFlatListSet -Dir $DirA -FileName "modules.txt")
    $modSetB = @(Get-GwbFlatListSet -Dir $DirB -FileName "modules.txt")
    if (Write-GwbSetDiff -Label "Modules" -SetA $modSetA -A $A -SetB $modSetB -B $B) { $found = $true }

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
