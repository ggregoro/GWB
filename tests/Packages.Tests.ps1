BeforeAll {
    . (Join-Path $PSScriptRoot "TestHelpers.ps1")
    . (Join-Path $Script:GwbLibDir "log.ps1")
    . (Join-Path $Script:GwbLibDir "packages.ps1")
}

Describe "Resolve-GwbPackageId" {
    It "resolves a known override" {
        Resolve-GwbPackageId -Name "fd" | Should -Be "sharkdp.fd"
    }

    It "resolves a known override with mixed real-world casing (eza)" {
        Resolve-GwbPackageId -Name "eza" | Should -Be "eza-community.eza"
    }

    It "passes an unknown name through unchanged" {
        Resolve-GwbPackageId -Name "totally-unknown-package" | Should -Be "totally-unknown-package"
    }
}

Describe "Test-GwbPackageInstalled" {
    It "returns true when winget exits 0" {
        Mock winget { $global:LASTEXITCODE = 0 }
        Test-GwbPackageInstalled -Id "fake.id" | Should -Be $true
    }

    It "returns false when winget exits non-zero" {
        Mock winget { $global:LASTEXITCODE = 1 }
        Test-GwbPackageInstalled -Id "fake.id" | Should -Be $false
    }
}

Describe "Install-GwbPackage" {
    It "does not attempt a real install when already installed" {
        Mock winget { $global:LASTEXITCODE = 0 }
        Install-GwbPackage -Name "fake"
        Should -Invoke winget -Times 1  # only the installed-check, not an install call
    }

    It "attempts a real install when not already installed" {
        $script:callCount = 0
        Mock winget {
            $script:callCount++
            if ($script:callCount -eq 1) { $global:LASTEXITCODE = 1 }  # installed-check: no
            else { $global:LASTEXITCODE = 0 }  # install itself: succeeds
        }
        Install-GwbPackage -Name "fake"
        Should -Invoke winget -Times 2
    }

    It "does not attempt any real action under -WhatIf" {
        Mock winget { $global:LASTEXITCODE = 1 }
        Install-GwbPackage -Name "fake" -WhatIf
        Should -Invoke winget -Times 1  # only the installed-check
    }

    It "fails cleanly (no exception) when the real install fails" {
        $script:callCount = 0
        Mock winget {
            $script:callCount++
            if ($script:callCount -eq 1) { $global:LASTEXITCODE = 1 }
            else { $global:LASTEXITCODE = 1 }  # install also fails
        }
        { Install-GwbPackage -Name "fake" } | Should -Not -Throw
    }
}

Describe "Install-GwbPackageList" {
    BeforeEach {
        $script:testDir = Join-Path $env:TEMP "gwb-pester-pkglist-$([guid]::NewGuid())"
        New-Item -ItemType Directory -Path $testDir -Force | Out-Null
    }

    AfterEach {
        Remove-Item -Path $script:testDir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "skips comments and blank lines" {
        $listPath = Join-Path $testDir "packages.txt"
        Set-Content -Path $listPath -Value @(
            "# a comment"
            ""
            "real-package"
            "   "
            "# another comment"
        )
        Mock winget { $global:LASTEXITCODE = 0 }
        Install-GwbPackageList -Path $listPath
        Should -Invoke winget -Times 1  # only "real-package" processed
    }

    It "fails cleanly when the list file doesn't exist" {
        Mock winget { $global:LASTEXITCODE = 0 }
        { Install-GwbPackageList -Path (Join-Path $testDir "does-not-exist.txt") } | Should -Not -Throw
        Should -Invoke winget -Times 0
    }
}

Describe "Update-GwbPackages" {
    It "returns true when winget upgrade succeeds" {
        Mock winget { $global:LASTEXITCODE = 0 }
        Update-GwbPackages | Should -Be $true
    }

    It "returns false when winget upgrade fails" {
        Mock winget { $global:LASTEXITCODE = 1 }
        Update-GwbPackages | Should -Be $false
    }
}
