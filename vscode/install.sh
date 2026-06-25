#!/usr/bin/env bash
# Links VS Code user config into the expected macOS location.
# Run once after cloning dotfiles on a fresh machine.
set -euo pipefail

VSCODE_DIR="$HOME/Library/Application Support/Code/User"
DOTFILES_VSCODE="$HOME/dotfiles/vscode"

mkdir -p "$VSCODE_DIR"

link() {
    local src="$DOTFILES_VSCODE/$1"
    local dst="$VSCODE_DIR/$1"
    if [ -f "$dst" ] && [ ! -L "$dst" ]; then
        mv "$dst" "$dst.bak"
        echo "backed up: $dst"
    fi
    ln -sf "$src" "$dst"
    echo "linked: $dst → $src"
}

link "settings.json"
[ -f "$DOTFILES/mcp.json" ] && link mcp.json

