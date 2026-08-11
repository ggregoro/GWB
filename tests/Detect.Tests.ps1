BeforeAll {
    . (Join-Path $PSScriptRoot "TestHelpers.ps1")
    . (Join-Path $Script:GwbLibDir "detect.ps1")
}

Describe "Detect functions" {
    It "Test-GwbWinget returns a boolean" {
        (Test-GwbWinget) | Should -BeOfType [bool]
    }

    It "Get-GwbOSVersion returns a real System.Version" {
        (Get-GwbOSVersion) | Should -BeOfType [System.Version]
    }

    It "Get-GwbOSName returns a non-empty string" {
        (Get-GwbOSName) | Should -Not -BeNullOrEmpty
    }

    It "Get-GwbShellVersion returns a non-empty string matching the running PowerShell version" {
        (Get-GwbShellVersion) | Should -Be $PSVersionTable.PSVersion.ToString()
    }
}
