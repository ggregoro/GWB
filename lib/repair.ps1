# lib/repair.ps1
# Mirrors GLB's lib/repair.sh: an ephemeral export (nothing saved to
# disk) diffed against a profile, offering to re-run restore if drift
# is found. Reuses lib/export.ps1's and lib/diff.ps1's internals
# directly rather than inventing new detection logic.

function Invoke-GwbRepair {
    param(
        [Parameter(Mandatory)][string]$ProfileName,
        [Parameter(Mandatory)][string]$ProfilesRoot
    )

    $profileDir = Join-Path $ProfilesRoot $ProfileName
    if (-not (Test-Path $profileDir)) {
        Write-Fail "Profile not found: $ProfileName"
        return 1
    }

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) "gwb-repair-$([guid]::NewGuid())"

    try {
        Write-Step "Checking current state against profile '$ProfileName'"
        Export-GwbSnapshotContent -ProfilesRoot $ProfilesRoot -TargetDir $tempDir

        $driftFound = (Invoke-GwbDiffDirs -A "current state" -DirA $tempDir -B $ProfileName -DirB $profileDir) -ne 0

        if (-not $driftFound) {
            Write-Ok "Healthy: current state matches profile '$ProfileName'"
            return 0
        }

        Write-Host ""
        try {
            $choice = Read-Host "Re-run 'gwb restore $ProfileName' now to fix this? [y/N]"
        } catch {
            Write-Info "No input available - left unchanged."
            return 1
        }
        if ($choice -match '^[Yy]') {
            Invoke-GwbApplyProfile -ProfileDir $profileDir -ProfileName $ProfileName
            return 0
        } else {
            Write-Info "Left unchanged."
            return 1
        }
    } finally {
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
        }
    }
}
