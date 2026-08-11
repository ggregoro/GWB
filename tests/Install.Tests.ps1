# tests/Install.Tests.ps1
# Tests for install.ps1, the curl/irm-install bootstrap script. Mirrors
# GLB's tests/install.bats. install.ps1 is standalone (no lib/ functions
# to dot-source - it must run before GWB exists on a machine at all), so
# each test re-evaluates its raw text via Invoke-Expression, exactly how
# the real `irm <url>/install.ps1 | iex` one-liner runs it. That keeps
# Mock's normal dynamic-scope interception working: install.ps1's own
# `& { ... }` wrapper is a child scope of wherever it's evaluated, so a
# Mock defined in this file's It block is still visible inside it - the
# same mechanism Packages.Tests.ps1 relies on to Mock winget.

BeforeAll {
    . (Join-Path $PSScriptRoot "TestHelpers.ps1")
    $Script:InstallScriptText = Get-Content -Path (Join-Path $Script:GwbRoot "install.ps1") -Raw
}

Describe "install.ps1" {
    BeforeEach {
        $Script:TestInstallDir = Join-Path $env:TEMP "gwb-install-test-$([guid]::NewGuid())"
        $env:GWB_INSTALL_DIR = $Script:TestInstallDir
        $env:GWB_REPO_URL = "https://example.test/GWB.git"
    }

    AfterEach {
        Remove-Item -Path $Script:TestInstallDir -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item Env:\GWB_INSTALL_DIR -ErrorAction SilentlyContinue
        Remove-Item Env:\GWB_REPO_URL -ErrorAction SilentlyContinue
    }

    It "errors cleanly when git is not available" {
        Mock Get-Command { $null } -ParameterFilter { $Name -eq "git" }

        $output = Invoke-Expression $Script:InstallScriptText *>&1 | Out-String

        $output | Should -Match "git is required"
        Test-Path $Script:TestInstallDir | Should -Be $false
    }

    It "clones fresh when the install dir doesn't exist yet" {
        Mock git {
            if ($args[0] -eq "clone") {
                New-Item -ItemType Directory -Path (Join-Path $args[-1] ".git") -Force | Out-Null
            }
            $global:LASTEXITCODE = 0
        }

        $output = Invoke-Expression $Script:InstallScriptText *>&1 | Out-String

        Should -Invoke git -ParameterFilter { $args[0] -eq "clone" }
        $output | Should -Match "gwb\.ps1.*restore"
    }

    It "updates an existing checkout instead of re-cloning" {
        New-Item -ItemType Directory -Path (Join-Path $Script:TestInstallDir ".git") -Force | Out-Null
        Mock git { $global:LASTEXITCODE = 0 }

        $output = Invoke-Expression $Script:InstallScriptText *>&1 | Out-String

        $output | Should -Match "already installed"
        Should -Invoke git -ParameterFilter { $args -contains "pull" }
        Should -Not -Invoke git -ParameterFilter { $args[0] -eq "clone" }
    }

    It "reports a clear error when git pull fails on an existing checkout" {
        New-Item -ItemType Directory -Path (Join-Path $Script:TestInstallDir ".git") -Force | Out-Null
        Mock git { $global:LASTEXITCODE = 1 }

        $output = Invoke-Expression $Script:InstallScriptText *>&1 | Out-String

        $output | Should -Match "git pull failed"
    }

    It "refuses to clone over an existing non-GWB directory" {
        New-Item -ItemType Directory -Path $Script:TestInstallDir -Force | Out-Null
        Set-Content -Path (Join-Path $Script:TestInstallDir "some-file.txt") -Value "unrelated"
        Mock git { $global:LASTEXITCODE = 0 }

        $output = Invoke-Expression $Script:InstallScriptText *>&1 | Out-String

        $output | Should -Match "isn't a GWB checkout"
        Should -Not -Invoke git
    }

    It "reports a clear error when git clone fails" {
        Mock git { $global:LASTEXITCODE = 1 }

        $output = Invoke-Expression $Script:InstallScriptText *>&1 | Out-String

        $output | Should -Match "git clone failed"
        Test-Path (Join-Path $Script:TestInstallDir ".git") | Should -Be $false
    }

    It "does not define any variables in the caller's scope (the & { } wrapper actually isolates)" {
        Mock git {
            if ($args[0] -eq "clone") {
                New-Item -ItemType Directory -Path (Join-Path $args[-1] ".git") -Force | Out-Null
            }
            $global:LASTEXITCODE = 0
        }

        Invoke-Expression $Script:InstallScriptText *>&1 | Out-Null

        Get-Variable -Name InstallDir -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
        Get-Variable -Name RepoUrl -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
    }
}
