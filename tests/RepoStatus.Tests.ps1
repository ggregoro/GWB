# Tests for the repo-status function shipped in the default and developer
# profile snippets. Every repo here is a throwaway one under $env:TEMP
# with a local bare repo as its remote - no test reads a real ~\Projects
# or touches the network. Mirrors GLB's tests/repo_status.bats.

BeforeDiscovery {
    $script:snippetProfiles = @("default", "developer")
}

BeforeAll {
    . (Join-Path $PSScriptRoot "TestHelpers.ps1")

    # The snippet as a whole can't be dot-sourced here (it starts the
    # prompt, loads modules, ...), so pull out just the one function.
    function Get-RepoStatusDefinition {
        param([Parameter(Mandatory)][string]$ProfileName)
        $path = Join-Path $Script:GwbRoot "profiles\$ProfileName\profile-snippet.ps1"
        $ast = [System.Management.Automation.Language.Parser]::ParseFile($path, [ref]$null, [ref]$null)
        $function = $ast.Find({
                param($node)
                $node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $node.Name -eq "repo-status"
            }, $true)
        return $function.Extent.Text
    }

    # A clone with one pushed commit.
    function New-SyncedRepo {
        param([Parameter(Mandatory)][string]$Name)
        $bare = Join-Path $script:root "$Name.git"
        $clone = Join-Path $script:projects $Name
        git init -q --bare $bare
        git clone -q $bare $clone 2>$null
        git -C $clone commit -q --allow-empty -m one
        git -C $clone push -q -u origin HEAD 2>$null
        return $clone
    }

    # Strip the color codes so assertions read as plain text.
    function Get-PlainOutput {
        param([string[]]$Lines)
        return (($Lines -join "`n") -replace "`e\[[0-9;]*m", "")
    }
}

Describe "repo-status (<_> profile)" -ForEach $snippetProfiles {
    BeforeAll {
        $definition = Get-RepoStatusDefinition -ProfileName $_
        . ([scriptblock]::Create($definition))
    }

    BeforeEach {
        $script:root = Join-Path $env:TEMP "gwb-pester-repostatus-$([guid]::NewGuid())"
        $script:projects = Join-Path $script:root "Projects"
        New-Item -ItemType Directory -Path $script:projects -Force | Out-Null

        # An empty config file, so the machine's own git settings and
        # identity play no part.
        $emptyConfig = Join-Path $script:root "gitconfig"
        New-Item -ItemType File -Path $emptyConfig | Out-Null
        $script:savedEnv = @{}
        $testEnv = @{
            GIT_CONFIG_GLOBAL   = $emptyConfig
            GIT_CONFIG_SYSTEM   = $emptyConfig
            GIT_AUTHOR_NAME     = "t"
            GIT_AUTHOR_EMAIL    = "t@example.com"
            GIT_COMMITTER_NAME  = "t"
            GIT_COMMITTER_EMAIL = "t@example.com"
        }
        foreach ($name in $testEnv.Keys) {
            $script:savedEnv[$name] = [Environment]::GetEnvironmentVariable($name)
            [Environment]::SetEnvironmentVariable($name, $testEnv[$name])
        }
    }

    AfterEach {
        foreach ($name in $script:savedEnv.Keys) {
            [Environment]::SetEnvironmentVariable($name, $script:savedEnv[$name])
        }
        Remove-Item $script:root -Recurse -Force -ErrorAction SilentlyContinue
    }

    It "shows a clean, pushed repo as clean and in sync" {
        New-SyncedRepo -Name "alpha" | Out-Null
        $out = Get-PlainOutput (repo-status -Path $script:projects)
        $out | Should -Match "alpha.*clean.*in sync"
        $out | Should -Match "1 repos, 0 with changes"
    }

    It "shows uncommitted work as has changes and counts it" {
        $clone = New-SyncedRepo -Name "alpha"
        New-Item -ItemType File -Path (Join-Path $clone "new-file") | Out-Null
        $out = Get-PlainOutput (repo-status -Path $script:projects)
        $out | Should -Match "alpha.*has changes"
        $out | Should -Match "1 repos, 1 with changes"
    }

    It "shows unpushed commits as ahead" {
        $clone = New-SyncedRepo -Name "alpha"
        git -C $clone commit -q --allow-empty -m two
        git -C $clone commit -q --allow-empty -m three
        Get-PlainOutput (repo-status -Path $script:projects) | Should -Match "↑2 ↓0"
    }

    It "says no upstream for a branch that was never pushed, with no git errors" {
        git init -q (Join-Path $script:projects "local-only")
        $out = Get-PlainOutput (repo-status -Path $script:projects 2>&1)
        $out | Should -Match "local-only.*no upstream"
        $out | Should -Not -Match "fatal"
        $LASTEXITCODE | Should -Be 0
    }

    It "skips folders that are not git repos" {
        New-SyncedRepo -Name "alpha" | Out-Null
        New-Item -ItemType Directory -Path (Join-Path $script:projects "just-a-folder") | Out-Null
        $out = Get-PlainOutput (repo-status -Path $script:projects)
        $out | Should -Not -Match "just-a-folder"
        $out | Should -Match "1 repos, 0 with changes"
    }

    It "keeps every row of the table the same width" {
        New-SyncedRepo -Name "alpha" | Out-Null
        git init -q (Join-Path $script:projects "local-only")
        $rows = (Get-PlainOutput (repo-status -Path $script:projects)) -split "`n" |
            Where-Object { $_ -match "^\s+[┌├└│]" }
        ($rows | ForEach-Object { $_.Length } | Select-Object -Unique).Count | Should -Be 1
    }
}

Describe "repo-status across profiles" {
    It "is identical in the default and developer snippets" {
        (Get-RepoStatusDefinition -ProfileName "default") |
            Should -BeExactly (Get-RepoStatusDefinition -ProfileName "developer")
    }
}
