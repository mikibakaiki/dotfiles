[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$GitName,
    [string]$GitEmail,
    [switch]$InstallOptionalModules,
    [switch]$ForceGitIdentity
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Step {
    param([string]$Message)
    Write-Host "[init] $Message" -ForegroundColor Cyan
}

function Test-IsWindows {
    return $PSVersionTable.PSVersion.Major -ge 6 ? $IsWindows : $true
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Resolve-ThemePath {
    if ($env:POSH_THEMES_PATH -and (Test-Path -LiteralPath $env:POSH_THEMES_PATH)) {
        return $env:POSH_THEMES_PATH
    }

    $ompCommand = Get-Command oh-my-posh -ErrorAction SilentlyContinue
    if ($ompCommand) {
        $candidate = Join-Path -Path (Split-Path -Path $ompCommand.Source -Parent) -ChildPath 'themes'
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return $null
}

function Remove-PathIfExists {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        $item = Get-Item -LiteralPath $Path -Force
        if ($item.PSIsContainer) {
            Remove-Item -LiteralPath $Path -Recurse -Force
        }
        else {
            Remove-Item -LiteralPath $Path -Force
        }
    }
}

function Set-Symlink {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$Target
    )

    $resolvedTarget = (Resolve-Path -LiteralPath $Target).Path
    $parent = Split-Path -Path $Path -Parent
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        if ($PSCmdlet.ShouldProcess($parent, 'Create parent directory')) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }
    }

    $shouldCreate = $true
    if (Test-Path -LiteralPath $Path) {
        try {
            $current = Get-Item -LiteralPath $Path -Force
            if ($current.LinkType -eq 'SymbolicLink' -and $current.Target -eq $resolvedTarget) {
                Write-Step "Symlink already correct: $Path"
                $shouldCreate = $false
            }
            else {
                if ($PSCmdlet.ShouldProcess($Path, 'Replace existing file with symlink')) {
                    Remove-PathIfExists -Path $Path
                }
            }
        }
        catch {
            if ($PSCmdlet.ShouldProcess($Path, 'Replace existing file with symlink')) {
                Remove-PathIfExists -Path $Path
            }
        }
    }

    if ($shouldCreate -and $PSCmdlet.ShouldProcess($Path, "Create symlink -> $resolvedTarget")) {
        New-Item -ItemType SymbolicLink -Path $Path -Target $resolvedTarget -Force | Out-Null
        Write-Step "Linked $Path"
    }
}

if (-not (Test-IsWindows)) {
    throw 'This script is for Windows PowerShell setup only. Use manual setup for macOS/Linux from README.md.'
}

$repoRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$homeDir = $HOME

Write-Step "Repository root: $repoRoot"
if (-not (Test-IsAdmin)) {
    Write-Warning 'Not running as Administrator. Symlink creation may fail unless Developer Mode is enabled.'
}

# 1) Core symlinks
Set-Symlink -Path (Join-Path $homeDir '.gitconfig') -Target (Join-Path $repoRoot '.gitconfig')
Set-Symlink -Path $PROFILE -Target (Join-Path $repoRoot 'Microsoft.PowerShell_profile.ps1')
Set-Symlink -Path (Join-Path $env:LOCALAPPDATA 'Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json') -Target (Join-Path $repoRoot 'windows-terminal-settings.json')
Set-Symlink -Path (Join-Path $env:APPDATA 'Code\User\settings.json') -Target (Join-Path $repoRoot 'vscode-settings.json')

# 2) Git local identity (optional or forced)
$gitLocalPath = Join-Path $homeDir '.gitconfig.local'
$shouldWriteIdentity = $ForceGitIdentity.IsPresent -or ((-not (Test-Path -LiteralPath $gitLocalPath)) -and $GitName -and $GitEmail)
if ($shouldWriteIdentity) {
    if (-not $GitName -or -not $GitEmail) {
        throw 'Both -GitName and -GitEmail are required when writing .gitconfig.local.'
    }

    $localConfig = @"
[user]
    name = $GitName
    email = $GitEmail
"@

    if ($PSCmdlet.ShouldProcess($gitLocalPath, 'Write Git local identity file')) {
        Set-Content -Path $gitLocalPath -Value $localConfig -Encoding UTF8
        Write-Step "Wrote $gitLocalPath"
    }
}
elseif (Test-Path -LiteralPath $gitLocalPath) {
    Write-Step '.gitconfig.local already exists. Leaving it unchanged.'
}
else {
    Write-Warning 'Skipping .gitconfig.local creation. Pass -GitName and -GitEmail to create it.'
}

# 3) Oh My Posh theme copy
$themeSource = Join-Path $repoRoot 'af-magic-improved.omp.json'
$themePath = Resolve-ThemePath
if ($themePath) {
    $themeDest = Join-Path $themePath 'af-magic-improved.omp.json'
    if ($PSCmdlet.ShouldProcess($themeDest, "Copy theme from $themeSource")) {
        Copy-Item -Path $themeSource -Destination $themeDest -Force
        Write-Step "Copied Oh My Posh theme to $themeDest"
    }
}
else {
    Write-Warning 'Could not determine POSH_THEMES_PATH. Install Oh My Posh and rerun the script for theme copy.'
}

# 4) Optional modules
if ($InstallOptionalModules) {
    Write-Step 'Installing optional PowerShell modules (Terminal-Icons, PSReadLine prerelease)...'
    if ($PSCmdlet.ShouldProcess('Terminal-Icons', 'Install module')) {
        Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser -Force
    }
    if ($PSCmdlet.ShouldProcess('PSReadLine', 'Install module')) {
        Install-Module PSReadLine -AllowPrerelease -Scope CurrentUser -Force
    }
}
else {
    Write-Step 'Skipping optional module installation. Use -InstallOptionalModules to include this step.'
}

Write-Host ''
Write-Host 'Done. Recommended verification commands:' -ForegroundColor Green
Write-Host '  git config --global --list'
Write-Host '  Get-Content $PROFILE'
Write-Host '  echo $env:POSH_THEMES_PATH'
Write-Host '  Test-Path "$env:POSH_THEMES_PATH\af-magic-improved.omp.json"'
