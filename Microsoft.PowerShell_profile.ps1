# UTF-8 encoding setup
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:LC_ALL='C.UTF-8'

# fnm - node version manager
#fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

# oh-my-posh with custom theme
oh-my-posh init pwsh | Invoke-Expression
# --config "$env:POSH_THEMES_PATH\cobalt2.omp.json" | Invoke-Expression