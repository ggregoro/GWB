<#
.SYNOPSIS
    GWB (Greg's Windows Bootstrap) - the PowerShell/Windows sibling to GLB.
    Installer: irm <url>/install.ps1 | iex

.DESCRIPTION
    Clones GWB into $env:LOCALAPPDATA\GWB (or updates it in place if
    already there) and prints the next command to run. Deliberately
    does not run `gwb restore` itself - that is a separate, opinionated,
    interactive step (package installs, $PROFILE changes) that should
    not happen as a surprise side effect of "get GWB onto my machine."
    Mirrors GLB's install.sh in spirit and behavior.

    $env:LOCALAPPDATA\GWB (not a literal port of GLB's ~/.local/share/glb)
    is the Windows-idiomatic per-user app-data location - the same kind
    of platform-appropriate divergence already made for the `gwb`
    command itself (lib/completions.ps1), which can't be a PATH symlink
    on Windows the way GLB's `glb` is.

    Everything below is wrapped in one `& { ... }` scriptblock. That is
    not decorative: `irm <url> | iex` runs this file's raw text through
    Invoke-Expression, which executes in the CALLER's current scope -
    the same as dot-sourcing a file. Without the wrapper, every
    variable set below would leak into the user's interactive session.
    The `& { }` call operator gives the block its own child scope, so
    nothing escapes upward.

    This script deliberately does NOT set $ErrorActionPreference =
    "Stop" and never calls `exit`, unlike gwb.ps1's own dispatcher
    convention (see docs/CODING_STANDARDS.md). Under `iex`, `exit`
    closes the whole PowerShell window, not just this script - unlike
    GLB's install.sh, where `curl | bash` runs in a disposable subshell
    and `exit` only ends that subshell. A terminating error would carry
    the same risk once it escapes this block in some hosts. Error paths
    below use plain, non-terminating Write-Error (stderr) followed by
    an explicit `return`, which only unwinds this `& { }` block - safe
    whether this file is piped through `iex` or run directly as a .ps1.
#>

& {
    if (-not $env:LOCALAPPDATA) {
        Write-Error "GWB requires Windows (`$env:LOCALAPPDATA is not set)."
        return
    }

    $InstallDir = if ($env:GWB_INSTALL_DIR) { $env:GWB_INSTALL_DIR } else { Join-Path $env:LOCALAPPDATA "GWB" }
    $RepoUrl = if ($env:GWB_REPO_URL) { $env:GWB_REPO_URL } else { "https://github.com/ggregoro/GWB.git" }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Error "git is required to install GWB. Please install git and try again."
        return
    }

    if (Test-Path (Join-Path $InstallDir ".git")) {
        Write-Host "GWB is already installed at $InstallDir - updating..."
        git -C $InstallDir pull --ff-only
        if ($LASTEXITCODE -ne 0) {
            Write-Error "git pull failed in $InstallDir - resolve manually and try again."
            return
        }
    } elseif (Test-Path $InstallDir) {
        Write-Error "$InstallDir already exists and isn't a GWB checkout. Move it aside or set `$env:GWB_INSTALL_DIR to a different location and try again."
        return
    } else {
        Write-Host "Cloning GWB to $InstallDir..."
        git clone --depth 1 $RepoUrl $InstallDir
        if ($LASTEXITCODE -ne 0) {
            Write-Error "git clone failed."
            return
        }
    }

    Write-Host ""
    Write-Host "GWB installed. Run this to set up your `$PROFILE:"
    Write-Host ""
    Write-Host "    & `"$InstallDir\gwb.ps1`" restore"
    Write-Host ""
    Write-Host "(After that first run, 'gwb' itself will be available in new PowerShell"
    Write-Host "sessions, so you can just run 'gwb restore', 'gwb update', etc. directly.)"
}
