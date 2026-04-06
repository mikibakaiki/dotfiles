# Dotfiles

My personal configuration files for development environments.

## Disclaimer

Some files in this repository were brought over from previous setups and may be outdated. For additional historical context, see the legacy repo at https://github.com/mikibakaiki/linux_config, which may still contain useful ideas or files for this dotfiles collection.

## Contents

- `.gitconfig` - Global Git configuration with aliases, colors, and best practices
- `Microsoft.PowerShell_profile.ps1` - PowerShell profile with Oh My Posh (af-magic-improved theme), optional fnm loading, Terminal-Icons, PSReadLine, and UTF-8 encoding
- `af-magic-improved.omp.json` - Custom Oh My Posh theme used by the PowerShell profile
- `af-magic.omp.json` - Legacy/alternate Oh My Posh theme with af-magic styling
- `windows-terminal-settings.json` - Windows Terminal settings with Duotone Dark theme and FiraCode Nerd Font
- `vscode-settings.json` - VS Code user settings with fonts, formatters, Copilot, and terminal config
- `.bashrc` - Bash shell configuration with .NET PATH additions and colorized output
- `.zshrc` - Zsh shell configuration with Oh My Zsh, NVM, pyenv, and .NET Core

## Prerequisites

### Windows

- [Oh My Posh](https://ohmyposh.dev/) - Prompt theme engine
- [FiraCode Nerd Font](https://www.nerdfonts.com/) - Font with programming ligatures and icons
- [PowerShell 7.2+](https://github.com/PowerShell/PowerShell) - Recommended for best module compatibility
- [fnm](https://github.com/Schniz/fnm) - Fast Node.js version manager (optional, for Node development)

**Optional Enhancements:**

- [Terminal-Icons](https://github.com/devblackops/Terminal-Icons) - File and folder icons in terminal listings
- [PSReadLine](https://github.com/PowerShell/PSReadLine) - Predictive IntelliSense and command history

### WSL/Linux

- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework (for zsh users)
- [NVM](https://github.com/nvm-sh/nvm) - Node Version Manager
- [pyenv](https://github.com/pyenv/pyenv) - Python version manager

## Installation

### Windows (PowerShell)

#### 1. Clone this repository

```powershell
git clone git@github.com:mikibakaiki/dotfiles.git $HOME\GitHub\dotfiles
```

#### 2. Create symlinks

Run PowerShell as **Administrator**, then:

```powershell
# Git configuration
New-Item -ItemType SymbolicLink -Path $HOME\.gitconfig -Target $HOME\GitHub\dotfiles\.gitconfig -Force

# Personal Git identity (local-only, ignored by git)
@"
[user]
	name = Your Name
	email = you@users.noreply.github.com
"@ | Set-Content -Path $HOME\.gitconfig.local -Encoding UTF8

# PowerShell profile
New-Item -ItemType SymbolicLink -Path $PROFILE -Target $HOME\GitHub\dotfiles\Microsoft.PowerShell_profile.ps1 -Force

# Oh My Posh theme (copy to themes directory)
# First, find your Oh My Posh themes path:
# echo $env:POSH_THEMES_PATH
Copy-Item -Path $HOME\GitHub\dotfiles\af-magic-improved.omp.json -Destination $env:POSH_THEMES_PATH\af-magic-improved.omp.json -Force

# Windows Terminal settings
New-Item -ItemType SymbolicLink -Path $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json -Target $HOME\GitHub\dotfiles\windows-terminal-settings.json -Force

# VS Code settings
New-Item -ItemType SymbolicLink -Path $env:APPDATA\Code\User\settings.json -Target $HOME\GitHub\dotfiles\vscode-settings.json -Force
```

#### 3. Install optional PowerShell modules (recommended)

```powershell
# Terminal-Icons: Adds colorful icons to file/folder listings
Install-Module -Name Terminal-Icons -Repository PSGallery -Scope CurrentUser

# PSReadLine: Predictive IntelliSense and improved command history
Install-Module PSReadLine -AllowPrerelease -Scope CurrentUser -Force
```

After installing these modules, the profile loads them automatically, so no uncommenting is required.

#### 4. Verify

```powershell
# Verify Git config
git config --global --list

# Verify PowerShell profile
Get-Content $PROFILE

# Verify Oh My Posh theme path (should show the themes directory)
echo $env:POSH_THEMES_PATH
Test-Path "$env:POSH_THEMES_PATH\af-magic-improved.omp.json"

# Verify Windows Terminal settings (restart Windows Terminal to see changes)
```

### macOS/Linux

#### 1. Clone this repository

```bash
git clone git@github.com:mikibakaiki/dotfiles.git ~/dotfiles
```

#### 2. Create symlinks

```bash
# Git configuration
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig

# Personal Git identity (local-only, ignored by git)
cat > ~/.gitconfig.local <<'EOF'
[user]
	name = Your Name
	email = you@example.com
EOF

# Bash configuration
ln -sf ~/dotfiles/.bashrc ~/.bashrc

# Zsh configuration (if using zsh)
ln -sf ~/dotfiles/.zshrc ~/.zshrc
```

#### 3. Verify

```bash
# Verify Git config
git config --global --list

# Verify shell config (restart terminal to apply)
echo $SHELL
```

## Updating

After making changes to files in this repository:

```bash
cd ~/dotfiles  # or cd $HOME\GitHub\dotfiles on Windows
git add .
git commit -m "Update configuration"
git push
```

On another machine, pull the latest changes:

```bash
cd ~/dotfiles  # or cd $HOME\GitHub\dotfiles on Windows
git pull
```

The symlinks will automatically reflect the updated configurations.

## PowerShell Profile Configuration

The PowerShell profile includes several customization options:

### Oh My Posh Themes

The profile is configured to use the **af-magic-improved** theme by default. You can switch themes by commenting/uncommenting lines in the profile:

- **af-magic-improved**: Custom theme with git status, Python venv, and user@host display
- **cobalt2**: Built-in Oh My Posh theme
- **default**: Standard Oh My Posh theme

To use a different built-in theme, explore available themes:

```powershell
Get-PoshThemes
```

### Optional Modules

**Terminal-Icons**

- Adds colorful file and folder icons to `ls`/`dir` output
- Install: `Install-Module -Name Terminal-Icons -Repository PSGallery`
- The profile loads it automatically when the module is installed

**PSReadLine**

- Provides predictive IntelliSense based on command history
- Shows suggestions in a list view as you type
- Install: `Install-Module PSReadLine -AllowPrerelease -Force`
- The profile loads it automatically when the module is installed
- Note: Requires PowerShell 7.2+ for best experience with prerelease features

### fnm - Node Version Manager

- Loaded automatically when `fnm` is installed
- Enables automatic Node version switching based on `.nvmrc` or `.node-version` files

## Git Configuration Highlights

- **Default branch**: `main` instead of `master`
- **Merge conflict style**: `diff3` for better context
- **Auto-prune**: Removes stale remote branches
- **Line endings**: Auto-converts for Windows compatibility
- **Editor**: VS Code with `--wait` flag
- **Useful aliases**: `st`, `co`, `br`, `lg`, `unstage`

## Customization

Before using these dotfiles, create or update `~/.gitconfig.local` with your commit identity:

```ini
[user]
	name = Your Name
	email = you@example.com
```

That file is ignored by this repository because it matches `*.local` in [.gitignore](.gitignore).

## Useful links

1. [Terminal Colors Inspiration](https://www.freecodecamp.org/news/windows-terminal-themes-color-schemes-powershell-customize/)

## License

Feel free to use and modify as needed.
