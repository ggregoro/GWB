# lib/completions.ps1
# Mirrors GLB's lib/completions.sh: puts `gwb` on the command line and
# registers tab-completion for it. Unlike GLB (which symlinks `glb`
# onto PATH), a .ps1 script isn't callable by bare name on Windows -
# the PowerShell-idiomatic equivalent is a wrapper function in
# $PROFILE, so that's what gets installed instead.

function Register-GwbCompletions {
    param([Parameter(Mandatory)][string]$GwbRoot)

    $commands = @(
        'help', 'version', 'info', 'install', 'remove', 'update',
        'restore', 'profiles', 'export', 'diff', 'repair'
    )

    Register-ArgumentCompleter -CommandName gwb -ScriptBlock {
        param($wordToComplete, $commandAst, $cursorPosition)
        $elements = $commandAst.CommandElements

        $candidates = if ($elements.Count -le 2) {
            $commands
        } elseif ($elements[1].Value -in @('restore', 'repair', 'diff')) {
            $names = [System.Collections.Generic.HashSet[string]]::new()
            Get-ChildItem -Path (Join-Path $GwbRoot "profiles") -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { [void]$names.Add($_.Name) }
            Get-ChildItem -Path (Join-Path $GwbRoot "snapshots") -Directory -ErrorAction SilentlyContinue |
                ForEach-Object { [void]$names.Add($_.Name) }
            $names
        } elseif ($elements[1].Value -in @('install', 'remove')) {
            $names = [System.Collections.Generic.HashSet[string]]::new()
            Get-ChildItem -Path (Join-Path $GwbRoot "profiles") -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                $pkgFile = Join-Path $_.FullName "packages.txt"
                if (Test-Path $pkgFile) {
                    Get-Content $pkgFile | Where-Object {
                        $_.Trim() -ne "" -and -not $_.Trim().StartsWith("#")
                    } | ForEach-Object { [void]$names.Add($_.Trim()) }
                }
            }
            $names
        } else {
            @()
        }

        $candidates | Where-Object { $_ -like "$wordToComplete*" } | Sort-Object |
            ForEach-Object { [System.Management.Automation.CompletionResult]::new($_) }
    }.GetNewClosure()
}

function Get-GwbSelfRegistrationContent {
    param([Parameter(Mandatory)][string]$GwbRoot)

    $completionsScript = Join-Path $GwbRoot "lib\completions.ps1"
    $gwbScript = Join-Path $GwbRoot "gwb.ps1"

    @"
. '$completionsScript'
Register-GwbCompletions -GwbRoot '$GwbRoot'
function gwb { & '$gwbScript' @args }
"@
}

function Install-GwbSelfRegistration {
    param([Parameter(Mandatory)][string]$GwbRoot, [switch]$WhatIf)

    $content = Get-GwbSelfRegistrationContent -GwbRoot $GwbRoot
    Set-GwbManagedBlock -Marker "# >>> GWB self >>>" -EndMarker "# <<< GWB self <<<" `
        -Content $content -Label "gwb self-registration" -WhatIf:$WhatIf
}
