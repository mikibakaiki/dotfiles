#!/usr/bin/env bash
# bootstrap.sh — fresh macOS setup
# Usage: bash <(curl -fsSL https://raw.githubusercontent.com/mikibakaiki/dotfiles/main/bootstrap.sh)
set -euo pipefail

DOTFILES_REPO="git@github.com:mikibakaiki/dotfiles.git"
DOTFILES_DIR="$HOME/dotfiles"

info()  { printf "\033[0;34m→\033[0m  %s\n" "$*"; }
ok()    { printf "\033[0;32m✓\033[0m  %s\n" "$*"; }
warn()  { printf "\033[0;33m!\033[0m  %s\n" "$*"; }

# ── 1. Xcode CLI tools ─────────────────────────────────────────────────────────
if ! xcode-select -p &>/dev/null; then
    info "Installing Xcode CLI tools..."
    xcode-select --install
    read -rp "Press enter once Xcode tools are installed..."
fi

# ── 2. Homebrew ────────────────────────────────────────────────────────────────
if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    ok "Homebrew already installed"
fi

# ── 3. Core tools ──────────────────────────────────────────────────────────────
info "Installing tools..."
brew install \
    stow \
    fish \
    starship \
    git-delta \
    fzf \
    fd \
    bat \
    eza \
    ripgrep \
    zoxide \
    lazygit \
    pyenv \
    fnm

brew install --cask ghostty      2>/dev/null || warn "ghostty not in brew — install from https://ghostty.org"
brew install --cask zed          2>/dev/null || warn "zed not in brew — install from https://zed.dev"
brew install --cask visual-studio-code 2>/dev/null || warn "vscode not in brew — install from https://code.visualstudio.com"

if ! command -v opencode &>/dev/null; then
    brew install opencode 2>/dev/null || warn "opencode: install from https://opencode.ai"
fi

# ── 4. Fonts ───────────────────────────────────────────────────────────────────
info "Installing fonts..."
fonts=(
    font-fira-code-nerd-font
    font-caskaydia-cove-nerd-font
    font-jetbrains-mono-nerd-font
)
for font in "${fonts[@]}"; do
    if brew list --cask "$font" &>/dev/null; then
        ok "$font already installed"
    else
        brew install --cask "$font" && ok "installed $font"
    fi
done

# ── 5. Clone dotfiles ──────────────────────────────────────────────────────────
if [ ! -d "$DOTFILES_DIR" ]; then
    info "Cloning dotfiles..."
    git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
else
    ok "dotfiles already present at $DOTFILES_DIR"
fi

# ── 6. Backup conflicting real files ───────────────────────────────────────────
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$BACKUP"

backup_if_real() {
    [ -e "$1" ] && [ ! -L "$1" ] && mv "$1" "$BACKUP/" && warn "Backed up: $1"
}

backup_if_real "$HOME/.config/fish"
backup_if_real "$HOME/.config/ghostty"
backup_if_real "$HOME/.config/git"
backup_if_real "$HOME/.config/opencode"
backup_if_real "$HOME/.config/starship.toml"
backup_if_real "$HOME/.config/zed"
backup_if_real "$HOME/.gitconfig"

# ── 7. Stow packages (all except vscode) ───────────────────────────────────────
info "Stowing packages..."
cd "$DOTFILES_DIR"
for pkg in */; do
    pkg="${pkg%/}"
    # vscode uses install.sh, not stow
    [[ "$pkg" == "vscode" ]] && continue
    stow --restow "$pkg" && ok "stowed: $pkg" || warn "conflicts in $pkg — fix manually then: stow -R $pkg"
done

# ── 8. VS Code settings ────────────────────────────────────────────────────────
if [ -d "/Applications/Visual Studio Code.app" ]; then
    info "Linking VS Code settings..."
    bash "$DOTFILES_DIR/vscode/install.sh" && ok "VS Code settings linked"
else
    warn "VS Code not found — run ~/dotfiles/vscode/install.sh after installing it"
fi

# ── 9. Git identity ────────────────────────────────────────────────────────────
GIT_LOCAL="$HOME/.config/git/config.local"
if [ ! -f "$GIT_LOCAL" ]; then
    cp "$DOTFILES_DIR/git/.config/git/config.local.example" "$GIT_LOCAL"
    warn "Created $GIT_LOCAL — edit it to add your name and email"
else
    ok "git identity already exists"
fi

# ── 10. Fish secrets ───────────────────────────────────────────────────────────
PERSONAL="$HOME/.config/fish/conf.d/.env.personal"
WORK="$HOME/.config/fish/conf.d/.env.work"

if [ ! -f "$PERSONAL" ]; then
    cp "$HOME/.config/fish/conf.d/.env.personal.example" "$PERSONAL"
    warn "Created .env.personal — fill in your personal API keys"
else
    ok ".env.personal already exists"
fi

if [ ! -f "$WORK" ]; then
    cp "$HOME/.config/fish/conf.d/.env.work.example" "$WORK"
    warn "Created .env.work — fill in your work URLs and tokens"
else
    ok ".env.work already exists"
fi

# ── 11. Register fish and set as default shell ─────────────────────────────────
FISH_PATH="$(brew --prefix)/bin/fish"
if ! grep -qF "$FISH_PATH" /etc/shells 2>/dev/null; then
    info "Registering fish in /etc/shells..."
    echo "$FISH_PATH" | sudo tee -a /etc/shells
fi
if [ "$SHELL" != "$FISH_PATH" ]; then
    info "Setting fish as default shell..."
    chsh -s "$FISH_PATH"
else
    ok "fish is already default shell"
fi

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
ok "Bootstrap complete — open a new terminal"
echo ""
echo "  Remaining manual steps:"
echo "  1. Edit ~/.config/git/config.local       → your name + email"
echo "  2. Edit ~/.config/fish/conf.d/.env.personal → personal API keys (Anthropic, GitHub)"
echo "  3. Edit ~/.config/fish/conf.d/.env.work     → work URLs and tokens"
echo "  4. For work-specific VS Code settings, see ~/dotfiles/vscode/settings.local.example"
echo "  5. opencode plugins install automatically on first run"
echo "  6. Tag this state: cd ~/dotfiles && git tag fresh-$(date +%Y%m%d) && git push origin --tags"