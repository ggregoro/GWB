# tests/TestHelpers.ps1
# Shared setup for the Pester suite - dot-sourced by every *.Tests.ps1 file.
# Mirrors GLB's tests/test_helper.bash.

$Script:GwbRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$Script:GwbLibDir = Join-Path $GwbRoot "lib"

# Creates a profile-shaped directory under $Root for testing - packages.txt,
# optional modules.txt, profile-snippet.ps1, optional description.txt.
function New-GwbTestProfile {
    param(
        [Parameter(Mandatory)][string]$Root,
        [Parameter(Mandatory)][string]$Name,
        [string[]]$Packages = @(),
        [string[]]$Modules = @(),
        [string]$Snippet = "# test snippet`nWrite-Host 'test'",
        [string]$Description = ""
    )
    $dir = Join-Path $Root $Name
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
    Set-Content -Path (Join-Path $dir "packages.txt") -Value ($Packages -join "`n")
    if ($Modules.Count -gt 0) {
        Set-Content -Path (Join-Path $dir "modules.txt") -Value ($Modules -join "`n")
    }
    Set-Content -Path (Join-Path $dir "profile-snippet.ps1") -Value $Snippet
    if ($Description) {
        Set-Content -Path (Join-Path $dir "description.txt") -Value $Description
    }
    return $dir
}

# A path safe to assign to $PROFILE during a test - always under $env:TEMP,
# never the real one. Caller is responsible for restoring $PROFILE and
# deleting this path afterward (see the BeforeEach/AfterEach pattern used
# throughout this suite).
function New-GwbTempProfilePath {
    Join-Path $env:TEMP "gwb-pester-profile-$([guid]::NewGuid()).ps1"
}
