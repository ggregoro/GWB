BeforeAll {
    . (Join-Path $PSScriptRoot "TestHelpers.ps1")
    . (Join-Path $Script:GwbLibDir "log.ps1")
    . (Join-Path $Script:GwbLibDir "packages.ps1")
    . (Join-Path $Script:GwbLibDir "modules.ps1")
    . (Join-Path $Script:GwbLibDir "export.ps1")
    . (Join-Path $Script:GwbLibDir "diff.ps1")
    . (Join-Path $Script:GwbLibDir "completions.ps1")
    . (Join-Path $Script:GwbLibDir "terminal.ps1")
    . (Join-Path $Script:GwbLibDir "profile.ps1")
    . (Join-Path $Script:GwbLibDir "repair.ps1")
    Import-Module PowerShellGet -ErrorAction Stop
}

Describe "Invoke-GwbRepair" {
    BeforeEach {
        $script:realProfile = $global:PROFILE
        $global:PROFILE = New-GwbTempProfilePath
        $GwbRoot = $Script:GwbRoot
        $script:profilesRoot = Join-Path $env:TEMP "gwb-pester-repair-$([guid]::NewGuid())"
        $script:profileDir = New-GwbTestProfile -Root $script:profilesRoot -Name "test" -Packages @("pkg")
        Mock winget { $global:LASTEXITCODE = 0 }
        Mock Get-Module { $null }
        Mock Install-Module { }
        # Invoke-GwbRepair goes through the real Invoke-GwbApplyProfile path -
        # mocked so this suite never touches the real ~/.config/starship.toml.
        Mock Install-GwbStarshipConfig { }
        # Same reasoning: Install-GwbNvimConfig is called unconditionally
        # (self-gated on Get-Command nvim, not a per-profile directory like
        # yazi's), so on a machine that actually has nvim installed this
        # would otherwise touch the real $env:LOCALAPPDATA\nvim on every
        # test in this suite - the exact class of leak Install-GwbStarshipConfig
        # itself caused here before it was mocked (see CHANGELOG.md).
        Mock Install-GwbNvimConfig { }
    }

    AfterEach {
        Remove-Item $global:PROFILE -Force -ErrorAction SilentlyContinue
        Remove-Item "$global:PROFILE.gwb-backup" -Force -ErrorAction SilentlyContinue
        Remove-Item $script:profilesRoot -Recurse -Force -ErrorAction SilentlyContinue
        $global:PROFILE = $script:realProfile
    }

    It "fails cleanly for a nonexistent profile" {
        Invoke-GwbRepair -ProfileName "nope" -ProfilesRoot $script:profilesRoot | Should -Be 1
    }

    It "reports healthy (0) when current state matches the profile" {
        Mock winget { $global:LASTEXITCODE = 0 }  # everything reports "installed"
        # For "healthy" to be true, $PROFILE's managed block content must
        # actually match the test profile's own profile-snippet.ps1 content
        # (New-GwbTestProfile's default snippet) - repair compares real state.
        Set-Content -Path $global:PROFILE -Value @(
            "# >>> GWB managed block >>>"
            "# test snippet"
            "Write-Host 'test'"
            "# <<< GWB managed block <<<"
        )
        Invoke-GwbRepair -ProfileName "test" -ProfilesRoot $script:profilesRoot | Should -Be 0
    }

    It "cleans up its ephemeral temp directory even when healthy" {
        # Regression: this test's name promised "even when healthy" but
        # never actually established a healthy $PROFILE the way "reports
        # healthy (0)" above does - $global:PROFILE is just BeforeEach's
        # fresh temp path, which doesn't match the test profile's real
        # snippet, so real drift was found every time this ran. That took
        # it into Invoke-GwbRepair's real (unmocked) Read-Host prompt -
        # confirmed live: this hung a real interactive `Invoke-Pester` run
        # waiting for actual keyboard input, harmless in a piped/CI context
        # (Read-Host throws there instead) but a real hazard here. Set up
        # the same genuinely-healthy state "reports healthy (0)" uses so
        # this test exercises the branch its name claims to.
        Mock winget { $global:LASTEXITCODE = 0 }
        Set-Content -Path $global:PROFILE -Value @(
            "# >>> GWB managed block >>>"
            "# test snippet"
            "Write-Host 'test'"
            "# <<< GWB managed block <<<"
        )
        $before = @(Get-ChildItem $env:TEMP -Filter "gwb-repair-*" -Directory -ErrorAction SilentlyContinue).Count
        Invoke-GwbRepair -ProfileName "test" -ProfilesRoot $script:profilesRoot | Should -Be 0
        $after = @(Get-ChildItem $env:TEMP -Filter "gwb-repair-*" -Directory -ErrorAction SilentlyContinue).Count
        $after | Should -Be $before
    }

    It "finds real drift, declines the fix via mocked Read-Host, and leaves the profile untouched" {
        $script:callCount = 0
        Mock winget {
            $script:callCount++
            # First call resolves the ephemeral export's own installed-check
            # for "pkg" (report not installed, so a real drift shows up).
            $global:LASTEXITCODE = 1
        }
        Mock Read-Host { "n" }
        $result = Invoke-GwbRepair -ProfileName "test" -ProfilesRoot $script:profilesRoot
        $result | Should -Be 1
        Should -Invoke Read-Host -Times 1
    }

    It "finds real drift, confirms the fix via mocked Read-Host, and applies the profile" {
        Mock winget { $global:LASTEXITCODE = 1 }
        Mock Read-Host { "y" }
        $GwbRoot = $Script:GwbRoot
        $result = Invoke-GwbRepair -ProfileName "test" -ProfilesRoot $script:profilesRoot
        $result | Should -Be 0
        (Test-Path $global:PROFILE) | Should -Be $true
    }

    It "treats Read-Host throwing (no input available) as a clean decline, not a crash" {
        Mock winget { $global:LASTEXITCODE = 1 }
        Mock Read-Host { throw "PowerShell is in NonInteractive mode" }
        { Invoke-GwbRepair -ProfileName "test" -ProfilesRoot $script:profilesRoot } | Should -Not -Throw
        Invoke-GwbRepair -ProfileName "test" -ProfilesRoot $script:profilesRoot | Should -Be 1
    }
}
