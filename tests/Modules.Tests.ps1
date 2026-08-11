BeforeAll {
    . (Join-Path $PSScriptRoot "TestHelpers.ps1")
    . (Join-Path $Script:GwbLibDir "log.ps1")
    . (Join-Path $Script:GwbLibDir "modules.ps1")
    # Install-Module isn't resolvable as a mockable command until
    # PowerShellGet is actually loaded into the session - confirmed
    # directly (Mock fails with CommandNotFoundException otherwise).
    Import-Module PowerShellGet -ErrorAction Stop
}

Describe "Test-GwbModuleInstalled" {
    It "returns true when Get-Module -ListAvailable finds it" {
        Mock Get-Module { [PSCustomObject]@{ Name = "FakeModule" } }
        Test-GwbModuleInstalled -Name "FakeModule" | Should -Be $true
    }

    It "returns false when Get-Module -ListAvailable finds nothing" {
        Mock Get-Module { $null }
        Test-GwbModuleInstalled -Name "FakeModule" | Should -Be $false
    }
}

Describe "Install-GwbModule" {
    It "does not attempt Install-Module when already installed" {
        Mock Get-Module { [PSCustomObject]@{ Name = "FakeModule" } }
        Mock Install-Module { }
        Install-GwbModule -Name "FakeModule"
        Should -Invoke Install-Module -Times 0
    }

    It "calls Install-Module with -Scope CurrentUser -Force when not installed" {
        Mock Get-Module { $null }
        Mock Install-Module { }
        Install-GwbModule -Name "FakeModule"
        Should -Invoke Install-Module -Times 1 -ParameterFilter {
            $Name -eq "FakeModule" -and $Scope -eq "CurrentUser" -and $Force -eq $true
        }
    }

    It "does not attempt any real action under -WhatIf" {
        Mock Get-Module { $null }
        Mock Install-Module { }
        Install-GwbModule -Name "FakeModule" -WhatIf
        Should -Invoke Install-Module -Times 0
    }

    It "fails cleanly (no exception) when Install-Module throws" {
        Mock Get-Module { $null }
        Mock Install-Module { throw "network error" }
        { Install-GwbModule -Name "FakeModule" } | Should -Not -Throw
    }
}

Describe "Install-GwbModuleList" {
    BeforeEach {
        $script:testDir = Join-Path $env:TEMP "gwb-pester-modlist-$([guid]::NewGuid())"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    }

    AfterEach {
        Remove-Item -Path $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "skips comments and blank lines" {
        $listPath = Join-Path $testDir "modules.txt"
        Set-Content -Path $listPath -Value @(
            "# a comment"
            ""
            "RealModule"
            "   "
        )
        Mock Get-Module { $null }
        Mock Install-Module { }
        Install-GwbModuleList -Path $listPath
        Should -Invoke Install-Module -Times 1 -ParameterFilter { $Name -eq "RealModule" }
    }
}
