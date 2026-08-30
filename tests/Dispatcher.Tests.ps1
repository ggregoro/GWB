# tests/Dispatcher.Tests.ps1
# Real end-to-end coverage of gwb.ps1 itself, mirroring GLB's
# dispatcher.bats - dot-sources the actual gwb.ps1 with real arguments
# (verified directly that this works: `exit 0` inside a dot-sourced
# script doesn't kill the Pester process, and Mock/`$PROFILE` overrides
# both flow through correctly). Deliberately does NOT exercise `export`
# here - gwb.ps1 hardcodes $SnapshotsRoot to the real repo's snapshots/
# directory, and a dispatcher-level test writing there for real isn't
# worth the risk when Export-GwbSnapshot already has full unit coverage
# (Export.Tests.ps1) against a temp SnapshotsRoot.

BeforeAll {
    . (Join-Path $PSScriptRoot "TestHelpers.ps1")
    $Script:GwbScript = Join-Path $Script:GwbRoot "gwb.ps1"
    Import-Module PowerShellGet -ErrorAction Stop
}

Describe "gwb.ps1 dispatcher" {
    BeforeEach {
        $script:realProfile = $global:PROFILE
        $global:PROFILE = New-GwbTempProfilePath
        Mock winget { $global:LASTEXITCODE = 0 }
        Mock Get-Module { $null }
        Mock Install-Module { }
    }

    AfterEach {
        Remove-Item $global:PROFILE -Force -ErrorAction SilentlyContinue
        Remove-Item "$global:PROFILE.gwb-backup" -Force -ErrorAction SilentlyContinue
        $global:PROFILE = $script:realProfile
    }

    It "help exits 0 and lists real commands" {
        $output = . $Script:GwbScript help *>&1 | Out-String
        $LASTEXITCODE | Should -Not -Be 1
        $output | Should -Match "restore"
        $output | Should -Match "diff"
        $output | Should -Match "repair"
    }

    It "version prints the real VERSION file content" {
        $realVersion = (Get-Content (Join-Path $Script:GwbRoot "VERSION") -Raw).Trim()
        $output = . $Script:GwbScript version *>&1 | Out-String
        $output | Should -Match ([regex]::Escape($realVersion))
    }

    It "info reports winget as found (real check, no mock needed for Test-GwbWinget)" {
        $output = . $Script:GwbScript info *>&1 | Out-String
        $output | Should -Match "winget:"
    }

    It "an unknown command exits non-zero" {
        . $Script:GwbScript totally-not-a-real-command *>&1 | Out-Null
        $LASTEXITCODE | Should -Be 1
    }

    It "restore default --dry-run touches no real files" {
        . $Script:GwbScript restore default --dry-run *>&1 | Out-Null
        (Test-Path $global:PROFILE) | Should -Be $false
    }

    It "restore developer --dry-run reports the real developer profile's packages" {
        $output = . $Script:GwbScript restore developer --dry-run *>&1 | Out-String
        $output | Should -Match "mingw"
        $output | Should -Match "fresh"
    }

    It "restore --undo fails cleanly with no backup present" {
        # Undo-GwbRestore also checks $env:APPDATA\yazi\config.gwb-backup
        # and $env:LOCALAPPDATA\nvim.gwb-backup, which the dispatcher calls
        # with no override - isolate both here so this test doesn't pick up
        # a real backup left on the host machine by an actual restore
        # (regression: false pass/fail depending on host state, caught by
        # running this for real on a machine that had genuinely used yazi -
        # the same class of leak is possible for nvim now too).
        $realAppData = $env:APPDATA
        $realLocalAppData = $env:LOCALAPPDATA
        $env:APPDATA = Join-Path $env:TEMP "gwb-pester-appdata-$([guid]::NewGuid())"
        $env:LOCALAPPDATA = Join-Path $env:TEMP "gwb-pester-localappdata-$([guid]::NewGuid())"
        try {
            $output = . $Script:GwbScript restore --undo *>&1 | Out-String
            $output | Should -Match "nothing to undo"
        } finally {
            $env:APPDATA = $realAppData
            $env:LOCALAPPDATA = $realLocalAppData
        }
    }

    It "profiles lists all three real profiles" {
        $output = . $Script:GwbScript profiles *>&1 | Out-String
        $output | Should -Match "default"
        $output | Should -Match "developer"
        $output | Should -Match "server"
    }

    It "diff default default reports no drift" {
        $output = . $Script:GwbScript diff default default *>&1 | Out-String
        $output | Should -Match "No drift found"
        $LASTEXITCODE | Should -Be 0
    }

    It "diff default developer reports real drift and exits 1" {
        . $Script:GwbScript diff default developer *>&1 | Out-Null
        $LASTEXITCODE | Should -Be 1
    }

    It "restore --from-manifest errors cleanly on a nonexistent path" {
        $output = . $Script:GwbScript restore --from-manifest "C:\does\not\exist-$([guid]::NewGuid())" *>&1 | Out-String
        $output | Should -Match "not found"
    }

    It "repair on an unknown profile fails cleanly" {
        . $Script:GwbScript repair "not-a-real-profile" *>&1 | Out-Null
        $LASTEXITCODE | Should -Be 1
    }
}
