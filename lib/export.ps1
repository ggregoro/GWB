# lib/export.ps1
# Mirrors GLB's lib/export.sh, scoped to what winget can actually tell
# us: captures the machine's currently-installed subset of every
# profile's known packages (not a full machine inventory - see
# docs/design/export-diff-repair.md for why) plus the current
# $PROFILE's GWB-managed block, into a profile-shaped snapshot.

function Get-GwbKnownPackageNames {
    param([Parameter(Mandatory)][string]$ProfilesRoot)

    $names = [System.Collections.Generic.HashSet[string]]::new()
    Get-ChildItem -Path $ProfilesRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $pkgFile = Join-Path $_.FullName "packages.txt"
        if (Test-Path $pkgFile) {
            Get-Content $pkgFile | Where-Object {
                $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#")
            } | ForEach-Object { [void]$names.Add($_.Trim()) }
        }
    }
    $names | Sort-Object
}

function Get-GwbProfileManagedBlockContent {
    $marker = "# >>> GWB managed block >>>"
    $endMarker = "# <<< GWB managed block <<<"

    if (-not (Test-Path $PROFILE)) { return $null }

    $content = Get-Content $PROFILE -Raw
    $pattern = "(?s)$([regex]::Escape($marker))\r?\n(.*?)\r?\n$([regex]::Escape($endMarker))"
    $match = [regex]::Match($content, $pattern)
    if (-not $match.Success) { return $null }
    return $match.Groups[1].Value
}

function Export-GwbSnapshotContent {
    param(
        [Parameter(Mandatory)][string]$ProfilesRoot,
        [Parameter(Mandatory)][string]$TargetDir
    )

    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    $known = Get-GwbKnownPackageNames -ProfilesRoot $ProfilesRoot
    $installed = $known | Where-Object { Test-GwbPackageInstalled -Id (Resolve-GwbPackageId -Name $_) }
    # -NoNewline + explicit `n: Set-Content's own auto-appended newline uses
    # the platform default (CRLF on Windows), which would mix with the LF
    # endings already in the joined content - see lib/profile.ps1 for the
    # same fix and the real bug it caused (a false-positive gwb diff).
    Set-Content -Path (Join-Path $TargetDir "packages.txt") -Value (($installed -join "`n") + "`n") -NoNewline

    $snippet = Get-GwbProfileManagedBlockContent
    if ($null -ne $snippet) {
        Set-Content -Path (Join-Path $TargetDir "profile-snippet.ps1") -Value "$snippet`n" -NoNewline
    }
}

function Export-GwbSnapshot {
    param([Parameter(Mandatory)][string]$ProfilesRoot, [Parameter(Mandatory)][string]$SnapshotsRoot)

    $hostname = $env:COMPUTERNAME
    $date = Get-Date -Format "yyyy-MM-dd"
    $name = "$hostname-$date"
    $dir = Join-Path $SnapshotsRoot $name

    Write-Step "Exporting snapshot: $name"
    Export-GwbSnapshotContent -ProfilesRoot $ProfilesRoot -TargetDir $dir

    $metadata = @(
        "hostname: $hostname"
        "date: $date"
        "gwb_version: $GwbVersion"
        "powershell_version: $($PSVersionTable.PSVersion.ToString())"
        "os_version: $([System.Environment]::OSVersion.Version.ToString())"
    )
    Set-Content -Path (Join-Path $dir "metadata.yaml") -Value $metadata

    Write-Ok "Snapshot written: snapshots/$name"
    return $dir
}
