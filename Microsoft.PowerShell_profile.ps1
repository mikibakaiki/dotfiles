# UTF-8 encoding setup
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$env:LC_ALL='C.UTF-8'

# fnm - node version manager
#fnm env --use-on-cd --shell powershell | Out-String | Invoke-Expression

# oh-my-posh with custom theme

# default theme
# oh-my-posh init pwsh | Invoke-Expression 

# cobalt2 theme
# --config "$env:POSH_THEMES_PATH\cobalt2.omp.json" | Invoke-Expression

# af-magic theme
oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\af-magic.omp.json" | Invoke-Expression

# https://www.hanselman.com/blog/my-ultimate-powershell-prompt-with-oh-my-posh-and-the-windows-terminal
# To install, run Install-Module -Name Terminal-Icons -Repository PSGallery
Import-Module -Name Terminal-Icons

# https://www.hanselman.com/blog/adding-predictive-intellisense-to-my-windows-terminal-powershell-prompt-with-psreadline
# Install-Module PSReadLine -AllowPrerelease -Force
Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -EditMode Windows