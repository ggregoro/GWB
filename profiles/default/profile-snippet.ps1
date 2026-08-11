# GWB default profile snippet - injected into $PROFILE between the
# GWB managed-block markers. Keep this idempotent and side-effect-free
# beyond function/alias/prompt definitions.

if (Get-Command eza -ErrorAction SilentlyContinue) {
    function ls  { eza --icons --group-directories-first @args }
    function ll  { eza --icons --group-directories-first -lah @args }
    function la  { eza --icons --group-directories-first -a @args }
}

if (Get-Command bat -ErrorAction SilentlyContinue) {
    Set-Alias -Name cat -Value bat -Option AllScope -Force
}

if (Get-Command fzf -ErrorAction SilentlyContinue) {
    $env:FZF_DEFAULT_OPTS = "--height 40% --layout=reverse --border"
}

if (Get-Command starship -ErrorAction SilentlyContinue) {
    Invoke-Expression (&starship init powershell)
}
