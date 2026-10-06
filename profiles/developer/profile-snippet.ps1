# GWB developer profile snippet - same shared aliases as `default`,
# plus mise activation. Keep this idempotent and side-effect-free
# beyond function/alias/prompt definitions.

# The MSIX-packaged PowerShell app (and elevated/"Run as administrator"
# launches in general) can start the shell in C:\Windows\System32
# regardless of any shortcut or Windows Terminal startingDirectory
# setting - confirmed directly (a taskbar pin resolving to
# Microsoft.PowerShell_8wekyb3d8bbwe!App, no Windows Terminal settings
# involved at all). Reset only when that's literally where we landed, so
# a deliberate "start here" shortcut elsewhere is never overridden.
if ($PWD.Path -eq (Join-Path $env:SystemRoot "System32")) {
    Set-Location $env:USERPROFILE
}

if (Get-Command eza -ErrorAction SilentlyContinue) {
    # PowerShell ships a built-in `ls` -> Get-ChildItem alias, and alias
    # resolution always wins over a same-named function - confirmed
    # directly (a function alone silently never gets invoked via bare
    # `ls`, even though `Get-Command ls -All` shows both registered).
    # `ll`/`la` don't collide with any built-in alias, so they're fine.
    # `--hyperlink` (OSC 8, Ctrl-click to open) is on `ll`/`la` only, not
    # plain `ls` - mirrors GLB's own default (added there 2026-08-18).
    Remove-Item -Path Alias:ls -Force -ErrorAction SilentlyContinue
    function ls  { eza --icons --group-directories-first @args }
    function ll  { eza --icons --group-directories-first --hyperlink -lah @args }
    function la  { eza --icons --group-directories-first --hyperlink -a @args }
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    Set-Alias -Name cat -Value bat -Option AllScope -Force
}

if (Get-Command fzf -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"
}

if (Get-Module -ListAvailable -Name PSFzf) {
    # An Application Control policy (Windows Defender Application Control,
    # Smart App Control, or a similar third-party policy) can block
    # PSFzf.dll from loading (Import-Module fails with 0x800711C7) even
    # though the module installed fine - a machine security policy GWB
    # can't and shouldn't work around (same "not GWB's to fix" stance as
    # IPBan in the server profile). Fail quietly so a blocked policy
    # doesn't throw errors on every shell startup.
    $GwbPsFzfLoaded = $false
    try {
        Import-Module PSFzf -ErrorAction Stop
        Set-PsFzfOption -PSReadlineChordProvider 'Ctrl+f' -PSReadlineChordReverseHistory 'Ctrl+r'
        $GwbPsFzfLoaded = $true
    } catch {
        # Blocked by policy (or some other load failure) - fall through to
        # the plain fzf.exe fallback below instead of losing Ctrl+f/Ctrl+r
        # entirely.
    }

    # Confirmed directly: when Application Control blocks PSFzf.dll, the
    # signed fzf.exe binary itself still runs fine - only the PowerShell
    # module assembly fails the policy's code-integrity check. So when the
    # module didn't load, wire up the same two keybindings by hand,
    # shelling out to fzf.exe directly instead of going through PSFzf's
    # own DLL. Deliberately simpler than PSFzf's real behavior (current
    # directory only for Ctrl+f, not a full recursive/provider-aware
    # search) - a fallback, not a reimplementation.
    if (-not $GwbPsFzfLoaded -and (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Set-PSReadLineKeyHandler -Key Ctrl+r -ScriptBlock {
            $GwbHistoryPath = (Get-PSReadLineOption).HistorySavePath
            if (-not (Test-Path $GwbHistoryPath)) { return }
            $GwbSelection = Get-Content $GwbHistoryPath | Where-Object { $_.Trim() } |
                Select-Object -Unique | fzf --height 40% --layout=reverse --border --tac
            if ($GwbSelection) {
                [Microsoft.PowerShell.PSConsoleReadLine]::RevertLine()
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($GwbSelection)
            }
        }
        Set-PSReadLineKeyHandler -Key Ctrl+f -ScriptBlock {
            $GwbSelection = Get-ChildItem -Name -ErrorAction SilentlyContinue |
                fzf --height 40% --layout=reverse --border
            if ($GwbSelection) {
                [Microsoft.PowerShell.PSConsoleReadLine]::Insert($GwbSelection)
            }
        }
    }
    Remove-Variable -Name GwbPsFzfLoaded -ErrorAction SilentlyContinue
}

if (Get-Module -ListAvailable -Name Terminal-Icons) {
    Import-Module Terminal-Icons
}

# PSReadLine ships with PowerShell 7 - nothing to install, just
# configure it. Predictive text needs a console with virtual-terminal
# support, which not every context has (e.g. output redirected/piped).
# Confirmed directly: -ErrorAction SilentlyContinue alone does NOT
# suppress the resulting message there (PSReadLine writes it in a way
# that bypasses the normal error-record pipeline) - only promoting it
# to a terminating error via -ErrorAction Stop and catching it does.
if (Get-Module -ListAvailable -Name PSReadLine) {
    try {
        Set-PSReadLineOption -PredictionSource History -PredictionViewStyle ListView -ErrorAction Stop
    } catch {
        # No VT-capable console here - leave PSReadLine at its defaults.
    }
}

if (Get-Command mise -ErrorAction SilentlyContinue) {
    Invoke-Expression ((&mise activate pwsh) -join "`n")
}

# winget installs Far Manager as a registered GUI app, not a PATH entry
# (unlike its CLI tools, which winget shims onto PATH automatically) -
# confirmed via its registry Uninstall key's InstallLocation.
$GwbFarExe = Join-Path $env:ProgramFiles "Far Manager\Far.exe"
if (Test-Path $GwbFarExe) {
    function far { & $GwbFarExe @args }
}
Remove-Variable -Name GwbFarExe -ErrorAction SilentlyContinue

# winget installs the `file` MIME-type-detection tool (needed by
# yazi's previewer - without it, every preview fails with "Cannot find
# 'file' to detect the file's MIME type.") but does not add it to PATH -
# confirmed directly (it's an Inno Setup installer, not PATH-shimmed the
# way winget's CLI-tool installers are). Add its directory explicitly,
# same "winget doesn't PATH-shim this" pattern already handled for Far
# Manager - guarded so this is a no-op if it isn't installed or its
# directory is already on PATH.
$GwbFileBin = Join-Path ${env:ProgramFiles(x86)} "GnuWin32\bin"
if ((Test-Path (Join-Path $GwbFileBin "file.exe")) -and ($env:Path -notlike "*$GwbFileBin*")) {
    $env:Path = "$env:Path;$GwbFileBin"
}
Remove-Variable -Name GwbFileBin -ErrorAction SilentlyContinue

if (Get-Command git -ErrorAction SilentlyContinue) {
    # Show the state of every git repo under ~\Projects as a colored
    # table: branch, clean or has changes, and whether it is in sync with
    # its remote. It fetches but never pulls, so running it changes
    # nothing. Ported from GLB's default profile (.local/bin/repo-status)
    # - same columns, colors and wording.
    function repo-status {
        param([string]$Path = (Join-Path $HOME "Projects"))

        # Colors. They use the terminal's own palette, so they follow
        # the theme.
        $bold = "`e[1m"
        $dim = "`e[2m"
        $red = "`e[31m"
        $green = "`e[32m"
        $yellow = "`e[33m"
        $blue = "`e[34m"
        $cyan = "`e[36m"
        $reset = "`e[0m"

        # The box. The lines are exactly as wide as the columns below:
        # 30, 10, 14 and 11 characters, plus one space of padding on
        # each side.
        $widths = 32, 12, 16, 13
        $segments = $widths | ForEach-Object { "─" * $_ }
        $top = "┌" + ($segments -join "┬") + "┐"
        $mid = "├" + ($segments -join "┼") + "┤"
        $bot = "└" + ($segments -join "┴") + "┘"
        $bar = "$dim│$reset"
        $head = "$bold$blue"

        ""
        "  $dim$top$reset"
        "  $bar $head$("REPO".PadRight(30))$reset $bar $head$("BRANCH".PadRight(10))$reset $bar $head$("STATE".PadRight(14))$reset $bar $head$("SYNC".PadRight(11))$reset $bar"
        "  $dim$mid$reset"

        $total = 0
        $dirty = 0

        foreach ($dir in Get-ChildItem -Path $Path -Directory -ErrorAction SilentlyContinue) {
            if (-not (Test-Path (Join-Path $dir.FullName ".git") -PathType Container)) {
                continue
            }

            [string]$branch = git -C $dir.FullName branch --show-current
            $changes = git -C $dir.FullName status --porcelain

            # 2>$null hides git's error text. With no network the fetch
            # fails, and a branch that was never pushed has no upstream
            # ("@{u}") to compare with; in that case $ahead stays empty.
            git -C $dir.FullName fetch --quiet 2>$null
            $ahead = git -C $dir.FullName rev-list --count '@{u}..HEAD' 2>$null
            $behind = git -C $dir.FullName rev-list --count 'HEAD..@{u}' 2>$null

            if ($changes) {
                $mark = "●"
                $state = "has changes"
                $stateColor = $yellow
                $dirty++
            } else {
                $mark = "✓"
                $state = "clean"
                $stateColor = $green
            }

            if (-not $ahead) {
                $sync = "no upstream"
                $syncColor = $yellow
            } elseif ($ahead -eq 0 -and $behind -eq 0) {
                $sync = "in sync"
                $syncColor = $dim
            } else {
                $sync = "↑$ahead ↓$behind"
                $syncColor = $red
            }

            # Pad each cell to its column width first, then color it -
            # the color codes are invisible but would count as characters.
            "  $bar $bold$($dir.Name.PadRight(30))$reset $bar $cyan$($branch.PadRight(10))$reset $bar $stateColor$mark $($state.PadRight(12))$reset $bar $syncColor$($sync.PadRight(11))$reset $bar"

            $total++
        }

        "  $dim$bot$reset"
        "  $dim$total repos, $dirty with changes$reset"
        ""

        # A repo with no upstream leaves git's failure code behind; the
        # table itself printed fine, so don't report that as an error.
        $global:LASTEXITCODE = 0
    }
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression ((&starship init powershell) -join "`n")
}
