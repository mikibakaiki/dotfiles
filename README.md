# Dotfiles

My personal configuration files for development environments.

## Contents

- `.gitconfig` - Global Git configuration with aliases, colors, and best practices
- `Microsoft.PowerShell_profile.ps1` - PowerShell profile with Oh My Posh (amro theme), fnm, and UTF-8 encoding
- `windows-terminal-settings.json` - Windows Terminal settings with Duotone Dark theme and FiraCode Nerd Font
- `vscode-settings.json` - VS Code user settings with fonts, formatters, Copilot, and terminal config
- `.bashrc` - Bash shell configuration with .NET Core, aliases, and colorized output
- `.zshrc` - Zsh shell configuration with Oh My Zsh, NVM, pyenv, and .NET Core

## Prerequisites

### Windows

- [Oh My Posh](https://ohmyposh.dev/) - Prompt theme engine
- [FiraCode Nerd Font](https://www.nerdfonts.com/) - Font with programming ligatures and icons
- [fnm](https://github.com/Schniz/fnm) - Fast Node.js version manager (optional, for Node development)

### WSL/Linux

- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework (for zsh users)
- [NVM](https://github.com/nvm-sh/nvm) - Node Version Manager
- [pyenv](https://github.com/pyenv/pyenv) - Python version manager

## Installation

### Windows (PowerShell)

**1. Clone this repository**

```powershell
git clone git@github.com:mikibakaiki/dotfiles.git $HOME\dotfiles
```

**2. Create symlinks**

Run PowerShell as **Administrator**, then:

```powershell
# Git configuration
New-Item -ItemType SymbolicLink -Path $HOME\.gitconfig -Target $HOME\dotfiles\.gitconfig -Force

# PowerShell profile
New-Item -ItemType SymbolicLink -Path $PROFILE -Target $HOME\dotfiles\Microsoft.PowerShell_profile.ps1 -Force

# Windows Terminal settings
New-Item -ItemType SymbolicLink -Path $env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json -Target $HOME\dotfiles\windows-terminal-settings.json -Force

# VS Code settings
New-Item -ItemType SymbolicLink -Path $env:APPDATA\Code\User\settings.json -Target $HOME\dotfiles\vscode-settings.json -Force
```

**3. Verify**

```powershell
# Verify Git config
git config --global --list

# Verify PowerShell profile
Get-Content $PROFILE

# Verify Windows Terminal settings (restart Windows Terminal to see changes)
```

### macOS/Linux

**1. Clone this repository**

```bash
git clone git@github.com:mikibakaiki/dotfiles.git ~/dotfiles
```

**2. Create symlinks**

```bash
# Git configuration
ln -sf ~/dotfiles/.gitconfig ~/.gitconfig

# Bash configuration
ln -sf ~/dotfiles/.bashrc ~/.bashrc

# Zsh configuration (if using zsh)
ln -sf ~/dotfiles/.zshrc ~/.zshrc
```

**3. Verify**

```bash
# Verify Git config
git config --global --list

# Verify shell config (restart terminal to apply)
echo $SHELL
```

## Updating

After making changes to files in this repository:

```bash
cd ~/dotfiles  # or cd $HOME\dotfiles on Windows
git add .
git commit -m "Update configuration"
git push
```

On another machine, pull the latest changes:

```bash
cd ~/dotfiles  # or cd $HOME\dotfiles on Windows
git pull
```

The symlinks will automatically reflect the updated configurations.

## Git Configuration Highlights

- **Default branch**: `main` instead of `master`
- **Merge conflict style**: `diff3` for better context
- **Auto-prune**: Removes stale remote branches
- **Line endings**: Auto-converts for Windows compatibility
- **Editor**: VS Code with `--wait` flag
- **Useful aliases**: `st`, `co`, `br`, `lg`, `unstage`

## Customization

Before using these dotfiles, you may want to update:

1. **Email address** in `.gitconfig` - Consider using GitHub's private email (`username@users.noreply.github.com`)
2. **Name** in `.gitconfig` - Your preferred display name for commits

## Useful links

1. [Terminal Colors Inspiration](https://www.freecodecamp.org/news/windows-terminal-themes-color-schemes-powershell-customize/)

## License

Feel free to use and modify as needed.
