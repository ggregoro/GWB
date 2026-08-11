# lib/detect.ps1
# Mirrors GLB's lib/detect.sh: detects the OS version, package manager
# availability, and current shell.

function Test-GwbWinget {
    [bool](Get-Command winget -ErrorAction SilentlyContinue)
}

function Get-GwbOSVersion {
    [System.Environment]::OSVersion.Version
}

function Get-GwbOSName {
    (Get-CimInstance -ClassName Win32_OperatingSystem).Caption
}

function Get-GwbShellVersion {
    $PSVersionTable.PSVersion.ToString()
}
