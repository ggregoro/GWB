# lib/export.ps1
# Mirrors GLB's lib/export.sh, scoped to what winget can actually tell
# us: captures the machine's currently-installed subset of every
# profile's known packages and PowerShell Gallery modules (not a full
# machine inventory - see docs/design/export-diff-repair.md for why)
# plus the current $PROFILE's GWB-managed block, into a profile-shaped
# snapshot.

# Shared by both packages.txt and modules.txt - same flat-list shape,
# same "union across every profile" scanning logic, just a different
# filename and installed-check.
function Get-GwbKnownNames {
    param(
        [Parameter(Mandatory)][string]$ProfilesRoot,
        [Parameter(Mandatory)][string]$FileName
    )

    $names = [System.Collections.Generic.HashSet[string]]::new()
    Get-ChildItem -Path $ProfilesRoot -Directory -ErrorAction SilentlyContinue | ForEach-Object {
        $listFile = Join-Path $_.FullName $FileName
        if (Test-Path $listFile) {
            Get-Content $listFile | Where-Object {
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

    $knownPackages = Get-GwbKnownNames -ProfilesRoot $ProfilesRoot -FileName "packages.txt"
    $installedPackages = $knownPackages | Where-Object { Test-GwbPackageInstalled -Id (Resolve-GwbPackageId -Name $_) }
    # -NoNewline + explicit `n: Set-Content's own auto-appended newline uses
    # the platform default (CRLF on Windows), which would mix with the LF
    # endings already in the joined content - see lib/profile.ps1 for the
    # same fix and the real bug it caused (a false-positive gwb diff).
    Set-Content -Path (Join-Path $TargetDir "packages.txt") -Value (($installedPackages -join "`n") + "`n") -NoNewline

    $knownModules = Get-GwbKnownNames -ProfilesRoot $ProfilesRoot -FileName "modules.txt"
    $installedModules = $knownModules | Where-Object { Test-GwbModuleInstalled -Name $_ }
    Set-Content -Path (Join-Path $TargetDir "modules.txt") -Value (($installedModules -join "`n") + "`n") -NoNewline

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
