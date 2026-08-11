BeforeAll {
    . (Join-Path $PSScriptRoot "TestHelpers.ps1")
    . (Join-Path $Script:GwbLibDir "log.ps1")
    . (Join-Path $Script:GwbLibDir "diff.ps1")
}

Describe "Resolve-GwbDiffDir" {
    BeforeEach {
        $script:root = Join-Path $env:TEMP "gwb-pester-resolve-$([guid]::NewGuid())"
        $script:profilesRoot = Join-Path $script:root "profiles"
        $script:snapshotsRoot = Join-Path $script:root "snapshots"
        New-GwbTestProfile -Root $script:profilesRoot -Name "real-profile" | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:snapshotsRoot "real-snapshot") -Force | Out-Null
    }

    AfterEach {
        Remove-Item $script:root -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "resolves a real profile name" {
        Resolve-GwbDiffDir -Name "real-profile" -ProfilesRoot $script:profilesRoot -SnapshotsRoot $script:snapshotsRoot |
            Should -Be (Join-Path $script:profilesRoot "real-profile")
    }

    It "resolves a real snapshot name" {
        Resolve-GwbDiffDir -Name "real-snapshot" -ProfilesRoot $script:profilesRoot -SnapshotsRoot $script:snapshotsRoot |
            Should -Be (Join-Path $script:snapshotsRoot "real-snapshot")
    }

    It "prefers a profile over a snapshot of the same name" {
        New-GwbTestProfile -Root $script:profilesRoot -Name "shared-name" | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:snapshotsRoot "shared-name") -Force | Out-Null
        Resolve-GwbDiffDir -Name "shared-name" -ProfilesRoot $script:profilesRoot -SnapshotsRoot $script:snapshotsRoot |
            Should -Be (Join-Path $script:profilesRoot "shared-name")
    }

    It "returns `$null for an unresolvable name" {
        Resolve-GwbDiffDir -Name "nope" -ProfilesRoot $script:profilesRoot -SnapshotsRoot $script:snapshotsRoot |
            Should -Be $null
    }
}

Describe "Get-GwbFlatListSet" {
    BeforeEach {
        $script:dir = Join-Path $env:TEMP "gwb-pester-flatlist-$([guid]::NewGuid())"
        New-Item -ItemType Directory -Path $script:dir -Force | Out-Null
    }

    AfterEach {
        Remove-Item $script:dir -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "parses real entries and skips comments/blanks" {
        Set-Content -Path (Join-Path $script:dir "packages.txt") -Value @("# comment", "", "one", "two", "  ")
        $set = @(Get-GwbFlatListSet -Dir $script:dir -FileName "packages.txt")
        $set | Should -Be @("one", "two")
    }

    It "returns an empty array when the file doesn't exist" {
        @(Get-GwbFlatListSet -Dir $script:dir -FileName "modules.txt").Count | Should -Be 0
    }
}

Describe "Write-GwbSetDiff" {
    It "reports no drift and returns false for identical sets" {
        Write-GwbSetDiff -Label "Packages" -SetA @("a", "b") -A "left" -SetB @("a", "b") -B "right" | Should -Be $false
    }

    It "reports drift and returns true when sets differ" {
        Write-GwbSetDiff -Label "Packages" -SetA @("a") -A "left" -SetB @("a", "b") -B "right" | Should -Be $true
    }
}

Describe "Invoke-GwbDiffDirs" {
    BeforeEach {
        $script:root = Join-Path $env:TEMP "gwb-pester-diffdirs-$([guid]::NewGuid())"
        New-Item -ItemType Directory -Path $script:root -Force | Out-Null
    }

    AfterEach {
        Remove-Item $script:root -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "returns 0 (no drift) for two identical directories" {
        $dirA = New-GwbTestProfile -Root $script:root -Name "a" -Packages @("x", "y") -Snippet "same content"
        $dirB = New-GwbTestProfile -Root $script:root -Name "b" -Packages @("x", "y") -Snippet "same content"
        Invoke-GwbDiffDirs -A "a" -DirA $dirA -B "b" -DirB $dirB | Should -Be 0
    }

    It "returns 1 when package sets differ" {
        $dirA = New-GwbTestProfile -Root $script:root -Name "a" -Packages @("x") -Snippet "same"
        $dirB = New-GwbTestProfile -Root $script:root -Name "b" -Packages @("x", "y") -Snippet "same"
        Invoke-GwbDiffDirs -A "a" -DirA $dirA -B "b" -DirB $dirB | Should -Be 1
    }

    It "returns 1 when module sets differ" {
        $dirA = New-GwbTestProfile -Root $script:root -Name "a" -Packages @("x") -Modules @("Mod1") -Snippet "same"
        $dirB = New-GwbTestProfile -Root $script:root -Name "b" -Packages @("x") -Modules @("Mod1", "Mod2") -Snippet "same"
        Invoke-GwbDiffDirs -A "a" -DirA $dirA -B "b" -DirB $dirB | Should -Be 1
    }

    It "returns 1 when the profile-snippet content differs" {
        $dirA = New-GwbTestProfile -Root $script:root -Name "a" -Packages @("x") -Snippet "content-1"
        $dirB = New-GwbTestProfile -Root $script:root -Name "b" -Packages @("x") -Snippet "content-2"
        Invoke-GwbDiffDirs -A "a" -DirA $dirA -B "b" -DirB $dirB | Should -Be 1
    }

    It "ignores a pure CRLF-vs-LF difference in the snippet (regression: false-positive diff bug)" {
        $dirA = New-GwbTestProfile -Root $script:root -Name "a" -Packages @("x") -Snippet "line1`nline2"
        $dirB = New-GwbTestProfile -Root $script:root -Name "b" -Packages @("x") -Snippet "line1`r`nline2"
        Invoke-GwbDiffDirs -A "a" -DirA $dirA -B "b" -DirB $dirB | Should -Be 0
    }
}
