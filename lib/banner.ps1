# lib/banner.ps1
# Mirrors GLB's lib/banner.sh: the banner shown at the start of every invocation.

function Write-GwbBanner {
    param([Parameter(Mandatory)][string]$Version)
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor DarkCyan
    Write-Host " GWB - Greg's Windows Bootstrap  (v$Version)" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor DarkCyan
    Write-Host ""
}
