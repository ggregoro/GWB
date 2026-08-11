BeforeAll {
    . (Join-Path $PSScriptRoot "TestHelpers.ps1")
    . (Join-Path $Script:GwbLibDir "log.ps1")
    . (Join-Path $Script:GwbLibDir "packages.ps1")
    . (Join-Path $Script:GwbLibDir "modules.ps1")
    . (Join-Path $Script:GwbLibDir "export.ps1")
}

Describe "Get-GwbKnownNames" {
    BeforeEach {
        $script:profilesRoot = Join-Path $env:TEMP "gwb-pester-known-$([guid]::NewGuid())"
        New-GwbTestProfile -Root $script:profilesRoot -Name "p1" -Packages @("a", "b") | Out-Null
        New-GwbTestProfile -Root $script:profilesRoot -Name "p2" -Packages @("b", "c") | Out-Null
    }

    AfterEach {
        Remove-Item $script:profilesRoot -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "returns the deduped, sorted union across every profile" {
        $names = @(Get-GwbKnownNames -ProfilesRoot $script:profilesRoot -FileName "packages.txt")
        $names | Should -Be @("a", "b", "c")
    }

    It "returns an empty list for a filename no profile has" {
        @(Get-GwbKnownNames -ProfilesRoot $script:profilesRoot -FileName "modules.txt").Count | Should -Be 0
    }
}

Describe "Get-GwbProfileManagedBlockContent" {
    BeforeEach {
        $script:realProfile = $global:PROFILE
        $global:PROFILE = New-GwbTempProfilePath
    }

    AfterEach {
        Remove-Item $global:PROFILE -Force -ErrorAction SilentlyContinue
        $global:PROFILE = $script:realProfile
    }

    It "returns `$null when `$PROFILE doesn't exist" {
        Get-GwbProfileManagedBlockContent | Should -Be $null
    }

    It "returns `$null when `$PROFILE exists but has no managed block" {
        Set-Content -Path $global:PROFILE -Value "just some regular content"
        Get-GwbProfileManagedBlockContent | Should -Be $null
    }

    It "extracts real content between the markers" {
        Set-Content -Path $global:PROFILE -Value @(
            "# >>> GWB managed block >>>"
            "the real content"
            "# <<< GWB managed block <<<"
        )
        (Get-GwbProfileManagedBlockContent) | Should -Match "the real content"
    }
}

Describe "Export-GwbSnapshotContent" {
    BeforeEach {
        $script:realProfile = $global:PROFILE
        $global:PROFILE = New-GwbTempProfilePath
        Set-Content -Path $global:PROFILE -Value @(
            "# >>> GWB managed block >>>"
            "snapshot snippet content"
            "# <<< GWB managed block <<<"
        )
        $script:profilesRoot = Join-Path $env:TEMP "gwb-pester-exportcontent-$([guid]::NewGuid())"
        New-GwbTestProfile -Root $script:profilesRoot -Name "p1" -Packages @("installed-pkg", "missing-pkg") -Modules @("InstalledMod", "MissingMod") | Out-Null
        $script:targetDir = Join-Path $env:TEMP "gwb-pester-exporttarget-$([guid]::NewGuid())"

        Mock winget {
            if ($args -contains "installed-pkg") { $global:LASTEXITCODE = 0 } else { $global:LASTEXITCODE = 1 }
        }
        Mock Get-Module {
            param($ListAvailable, $Name)
            if ($Name -eq "InstalledMod") { [PSCustomObject]@{ Name = $Name } } else { $null }
        }
    }

    AfterEach {
        Remove-Item $global:PROFILE -Force -ErrorAction SilentlyContinue
        Remove-Item $script:profilesRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $script:targetDir -Recurse -Force -ErrorAction SilentlyContinue
        $global:PROFILE = $script:realProfile
    }

    It "writes only the installed subset of known packages and modules" {
        Export-GwbSnapshotContent -ProfilesRoot $script:profilesRoot -TargetDir $script:targetDir
        (Get-Content (Join-Path $script:targetDir "packages.txt")) | Should -Be @("installed-pkg")
        (Get-Content (Join-Path $script:targetDir "modules.txt")) | Should -Be @("InstalledMod")
    }

    It "captures the real `$PROFILE managed block content" {
        Export-GwbSnapshotContent -ProfilesRoot $script:profilesRoot -TargetDir $script:targetDir
        (Get-Content (Join-Path $script:targetDir "profile-snippet.ps1") -Raw) | Should -Match "snapshot snippet content"
    }
}

Describe "Export-GwbSnapshot" {
    BeforeEach {
        $script:realProfile = $global:PROFILE
        $global:PROFILE = New-GwbTempProfilePath
        Set-Content -Path $global:PROFILE -Value "# no managed block here"
        $script:profilesRoot = Join-Path $env:TEMP "gwb-pester-export-$([guid]::NewGuid())"
        New-GwbTestProfile -Root $script:profilesRoot -Name "p1" -Packages @("pkg") | Out-Null
        $script:snapshotsRoot = Join-Path $env:TEMP "gwb-pester-snapshots-$([guid]::NewGuid())"
        Mock winget { $global:LASTEXITCODE = 0 }
        $GwbVersion = "0.0.0-test"
    }

    AfterEach {
        Remove-Item $global:PROFILE -Force -ErrorAction SilentlyContinue
        Remove-Item $script:profilesRoot -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item $script:snapshotsRoot -Recurse -Force -ErrorAction SilentlyContinue
        $global:PROFILE = $script:realProfile
    }

    It "creates a real snapshot directory with packages.txt, modules.txt, and metadata.yaml" {
        $GwbVersion = "0.0.0-test"
        $dir = Export-GwbSnapshot -ProfilesRoot $script:profilesRoot -SnapshotsRoot $script:snapshotsRoot
        (Test-Path (Join-Path $dir "packages.txt")) | Should -Be $true
        (Test-Path (Join-Path $dir "modules.txt")) | Should -Be $true
        (Test-Path (Join-Path $dir "metadata.yaml")) | Should -Be $true
        (Get-Content (Join-Path $dir "metadata.yaml") -Raw) | Should -Match "0.0.0-test"
    }
}
