BeforeAll {
    . (Join-Path $PSScriptRoot "TestHelpers.ps1")
    . (Join-Path $Script:GwbLibDir "log.ps1")
    . (Join-Path $Script:GwbLibDir "packages.ps1")
    . (Join-Path $Script:GwbLibDir "modules.ps1")
    . (Join-Path $Script:GwbLibDir "completions.ps1")
    . (Join-Path $Script:GwbLibDir "terminal.ps1")
    . (Join-Path $Script:GwbLibDir "profile.ps1")
    Import-Module PowerShellGet -ErrorAction Stop
}

Describe "Set-GwbManagedBlock" {
    BeforeEach {
        $script:realProfile = $global:PROFILE
        $global:PROFILE = New-GwbTempProfilePath
    }

    AfterEach {
        Remove-Item $global:PROFILE -Force -ErrorAction SilentlyContinue
        Remove-Item "$global:PROFILE.gwb-backup" -Force -ErrorAction SilentlyContinue
        $global:PROFILE = $script:realProfile
    }

    It "creates `$PROFILE and appends the block when it doesn't exist" {
        Set-GwbManagedBlock -Marker "# >>> A >>>" -EndMarker "# <<< A <<<" -Content "content-A" -Label "A"
        $content = Get-Content $global:PROFILE -Raw
        $content | Should -Match "# >>> A >>>"
        $content | Should -Match "content-A"
        $content | Should -Match "# <<< A <<<"
    }

    It "replaces the block in place on a second apply, without duplicating it" {
        Set-GwbManagedBlock -Marker "# >>> A >>>" -EndMarker "# <<< A <<<" -Content "first" -Label "A"
        Set-GwbManagedBlock -Marker "# >>> A >>>" -EndMarker "# <<< A <<<" -Content "second" -Label "A"
        $content = Get-Content $global:PROFILE -Raw
        ($content -split "# >>> A >>>").Count | Should -Be 2  # marker appears exactly once
        $content | Should -Match "second"
        $content | Should -Not -Match "first"
    }

    It "is byte-idempotent: applying identical content twice produces an identical file (regression: growing blank line)" {
        Set-GwbManagedBlock -Marker "# >>> A >>>" -EndMarker "# <<< A <<<" -Content "stable-content" -Label "A"
        $lengthAfterFirst = (Get-Content $global:PROFILE -Raw).Length
        Set-GwbManagedBlock -Marker "# >>> A >>>" -EndMarker "# <<< A <<<" -Content "stable-content" -Label "A"
        $lengthAfterSecond = (Get-Content $global:PROFILE -Raw).Length
        Set-GwbManagedBlock -Marker "# >>> A >>>" -EndMarker "# <<< A <<<" -Content "stable-content" -Label "A"
        $lengthAfterThird = (Get-Content $global:PROFILE -Raw).Length
        $lengthAfterFirst | Should -Be $lengthAfterSecond
        $lengthAfterSecond | Should -Be $lengthAfterThird
    }

    It "produces consistent LF-only line endings, never mixing in a CRLF (regression: false-positive diff bug)" {
        Set-GwbManagedBlock -Marker "# >>> A >>>" -EndMarker "# <<< A <<<" -Content "line1`nline2" -Label "A"
        $raw = Get-Content $global:PROFILE -Raw
        # No bare CR anywhere - every CR must be immediately followed by LF,
        # and since we never intentionally emit CRLF, there should be none.
        $raw -match "`r" | Should -Be $false
    }

    It "backs up an existing non-empty `$PROFILE exactly once, on first touch" {
        Set-Content -Path $global:PROFILE -Value "pre-existing user content"
        Set-GwbManagedBlock -Marker "# >>> A >>>" -EndMarker "# <<< A <<<" -Content "content-A" -Label "A"
        $backupPath = "$global:PROFILE.gwb-backup"
        (Test-Path $backupPath) | Should -Be $true
        (Get-Content $backupPath -Raw) | Should -Match "pre-existing user content"
    }

    It "never overwrites an existing backup on a later apply of a DIFFERENT block (regression: backup-clobbering bug)" {
        Set-Content -Path $global:PROFILE -Value "the real original content"
        Set-GwbManagedBlock -Marker "# >>> A >>>" -EndMarker "# <<< A <<<" -Content "content-A" -Label "A"
        # A second, distinct managed block gets added (simulates e.g. the
        # self-registration block being added alongside the profile snippet).
        Set-GwbManagedBlock -Marker "# >>> B >>>" -EndMarker "# <<< B <<<" -Content "content-B" -Label "B"
        $backupPath = "$global:PROFILE.gwb-backup"
        (Get-Content $backupPath -Raw) | Should -Match "the real original content"
        (Get-Content $backupPath -Raw) | Should -Not -Match "content-A"
    }

    It "does not write anything under -WhatIf" {
        Set-GwbManagedBlock -Marker "# >>> A >>>" -EndMarker "# <<< A <<<" -Content "content-A" -Label "A" -WhatIf
        (Test-Path $global:PROFILE) | Should -Be $false
    }
}

Describe "Install-GwbProfileSnippet" {
    BeforeEach {
        $script:realProfile = $global:PROFILE
        $global:PROFILE = New-GwbTempProfilePath
        $script:snippetDir = Join-Path $env:TEMP "gwb-pester-snippet-$([guid]::NewGuid())"
        New-Item -ItemType Directory -Path $script:snippetDir -Force | Out-Null
    }

    AfterEach {
        Remove-Item $global:PROFILE -Force -ErrorAction SilentlyContinue
        Remove-Item "$global:PROFILE.gwb-backup" -Force -ErrorAction SilentlyContinue
        Remove-Item $script:snippetDir -Recurse -Force -ErrorAction SilentlyContinue
        $global:PROFILE = $script:realProfile
    }

    It "applies real snippet content into `$PROFILE" {
        $snippetPath = Join-Path $script:snippetDir "profile-snippet.ps1"
        Set-Content -Path $snippetPath -Value "function test-alias { 'hi' }"
        Install-GwbProfileSnippet -SnippetPath $snippetPath
        (Get-Content $global:PROFILE -Raw) | Should -Match "test-alias"
    }

    It "fails cleanly when the snippet file doesn't exist" {
        { Install-GwbProfileSnippet -SnippetPath (Join-Path $script:snippetDir "missing.ps1") } | Should -Not -Throw
        (Test-Path $global:PROFILE) | Should -Be $false
    }
}

Describe "Install-GwbStarshipConfig" {
    BeforeEach {
        $script:configPath = Join-Path $env:TEMP "gwb-pester-starship-$([guid]::NewGuid())\starship.toml"
    }

    AfterEach {
        Remove-Item (Split-Path -Parent $script:configPath) -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "creates the config file with scan_timeout when none exists" {
        Install-GwbStarshipConfig -ConfigPath $script:configPath
        (Get-Content $script:configPath -Raw) | Should -Match "scan_timeout = 1000"
    }

    It "appends scan_timeout to an existing config that lacks it" {
        New-Item -ItemType Directory -Path (Split-Path -Parent $script:configPath) -Force | Out-Null
        Set-Content -Path $script:configPath -Value "add_newline = false"
        Install-GwbStarshipConfig -ConfigPath $script:configPath
        $content = Get-Content $script:configPath -Raw
        $content | Should -Match "add_newline = false"
        $content | Should -Match "scan_timeout = 1000"
    }

    It "never overwrites an existing scan_timeout (regression: don't clobber user customization)" {
        New-Item -ItemType Directory -Path (Split-Path -Parent $script:configPath) -Force | Out-Null
        Set-Content -Path $script:configPath -Value "scan_timeout = 500"
        Install-GwbStarshipConfig -ConfigPath $script:configPath
        $content = Get-Content $script:configPath -Raw
        $content | Should -Match "scan_timeout = 500"
        ([regex]::Matches($content, "scan_timeout")).Count | Should -Be 1
    }

    It "does not write anything under -WhatIf" {
        Install-GwbStarshipConfig -ConfigPath $script:configPath -WhatIf
        (Test-Path $script:configPath) | Should -Be $false
    }

    It "does nothing when starship isn't installed" {
        Mock Get-Command { $null } -ParameterFilter { $Name -eq "starship" }
        Install-GwbStarshipConfig -ConfigPath $script:configPath
        (Test-Path $script:configPath) | Should -Be $false
    }
}

Describe "Get-GwbProfileList / Get-GwbProfileDescription" {
    BeforeEach {
        $script:profilesRoot = Join-Path $env:TEMP "gwb-pester-profiles-$([guid]::NewGuid())"
        New-Item -ItemType Directory -Path $script:profilesRoot -Force | Out-Null
        New-GwbTestProfile -Root $script:profilesRoot -Name "zeta" -Description "the zeta profile"
        New-GwbTestProfile -Root $script:profilesRoot -Name "alpha"  # no description
    }

    AfterEach {
        Remove-Item $script:profilesRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "lists profiles sorted by name" {
        $profiles = @(Get-GwbProfileList -ProfilesRoot $script:profilesRoot)
        $profiles.Count | Should -Be 2
        $profiles[0].Name | Should -Be "alpha"
        $profiles[1].Name | Should -Be "zeta"
    }

    It "reads a real description" {
        $dir = Join-Path $script:profilesRoot "zeta"
        Get-GwbProfileDescription -ProfileDir $dir | Should -Be "the zeta profile"
    }

    It "falls back to empty string when description.txt is absent" {
        $dir = Join-Path $script:profilesRoot "alpha"
        Get-GwbProfileDescription -ProfileDir $dir | Should -Be ""
    }

    It "returns an empty list when the profiles root doesn't exist" {
        @(Get-GwbProfileList -ProfilesRoot (Join-Path $env:TEMP "does-not-exist-$([guid]::NewGuid())")).Count | Should -Be 0
    }
}

Describe "Undo-GwbRestore" {
    BeforeEach {
        $script:realProfile = $global:PROFILE
        $global:PROFILE = New-GwbTempProfilePath
    }

    AfterEach {
        Remove-Item $global:PROFILE -Force -ErrorAction SilentlyContinue
        Remove-Item "$global:PROFILE.gwb-backup" -Force -ErrorAction SilentlyContinue
        $global:PROFILE = $script:realProfile
    }

    It "fails cleanly when no backup exists" {
        { Undo-GwbRestore } | Should -Not -Throw
    }

    It "restores real backup content" {
        Set-Content -Path "$global:PROFILE.gwb-backup" -Value "original content"
        Set-Content -Path $global:PROFILE -Value "modified content"
        Undo-GwbRestore
        (Get-Content $global:PROFILE -Raw) | Should -Match "original content"
    }
}

Describe "Invoke-GwbApplyProfile" {
    BeforeEach {
        $script:realProfile = $global:PROFILE
        $global:PROFILE = New-GwbTempProfilePath
        $GwbRoot = $Script:GwbRoot
        $script:profilesRoot = Join-Path $env:TEMP "gwb-pester-apply-$([guid]::NewGuid())"
        New-Item -ItemType Directory -Path $script:profilesRoot -Force | Out-Null
        $script:profileDir = New-GwbTestProfile -Root $script:profilesRoot -Name "test" -Packages @("fake-pkg") -Modules @("FakeModule")
        Mock winget { $global:LASTEXITCODE = 0 }
        Mock Get-Module { $null }
        Mock Install-Module { }
        # Real behavior is covered by its own Describe block below with an
        # explicit -ConfigPath - mocked here so this block never touches the
        # real machine's ~/.config/starship.toml.
        Mock Install-GwbStarshipConfig { }
    }

    AfterEach {
        Remove-Item $global:PROFILE -Force -ErrorAction SilentlyContinue
        Remove-Item "$global:PROFILE.gwb-backup" -Force -ErrorAction SilentlyContinue
        Remove-Item $script:profilesRoot -Recurse -Force -ErrorAction SilentlyContinue
        $global:PROFILE = $script:realProfile
    }

    It "fails cleanly for a nonexistent profile directory" {
        { Invoke-GwbApplyProfile -ProfileDir (Join-Path $script:profilesRoot "nope") -ProfileName "nope" } | Should -Not -Throw
        Should -Invoke winget -Times 0
    }

    It "installs packages, installs modules, and applies the snippet + self-registration block" {
        $GwbRoot = $Script:GwbRoot
        Invoke-GwbApplyProfile -ProfileDir $script:profileDir -ProfileName "test"
        Should -Invoke winget -Times 1  # installed-check only - the mock reports it as already installed
        Should -Invoke Install-Module -Times 1 -ParameterFilter { $Name -eq "FakeModule" }
        $content = Get-Content $global:PROFILE -Raw
        $content | Should -Match "# >>> GWB managed block >>>"
        $content | Should -Match "# >>> GWB self >>>"
        $content | Should -Match "function gwb"
    }

    It "does not touch `$PROFILE or install anything under -WhatIf" {
        $GwbRoot = $Script:GwbRoot
        Invoke-GwbApplyProfile -ProfileDir $script:profileDir -ProfileName "test" -WhatIf
        Should -Invoke Install-Module -Times 0
        (Test-Path $global:PROFILE) | Should -Be $false
    }
}
