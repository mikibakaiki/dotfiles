# ── Better coreutils ───────────────────────────────────────────────────────────
if command -q eza
    abbr --add ls   'eza --icons'
    abbr --add ll   'eza -lh --icons --git'
    abbr --add la   'eza -lah --icons --git'
    abbr --add tree 'eza --tree --icons'
    abbr --add lt   'eza -lh --icons --git --sort=modified'  # sort by date
end

if command -q bat
    abbr --add cat  'bat'
    abbr --add catc 'bat --style=plain --paging=never'
end

if command -q rg
    abbr --add grep 'rg --color=auto'
end

if command -q fd
    abbr --add find 'fd'
end

# ── Navigation ─────────────────────────────────────────────────────────────────
abbr --add .. 'cd ..'
abbr --add ... 'cd ../..'
abbr --add dot 'cd ~/dotfiles'
abbr --add cfg 'cd ~/.config'

# ── zoxide — replaces cd ───────────────────────────────────────────────────────
# z is registered by zoxide init in config.fish
# zi = interactive picker (fzf)
# these teach muscle memory:
abbr --add zz 'z -'        # jump to previous directory (like cd -)

# ── Git ────────────────────────────────────────────────────────────────────────
abbr --add g    git
abbr --add gs   'git status -sb'
abbr --add ga   'git add'
abbr --add gap  'git add -p'
abbr --add gc   'git commit'
abbr --add gcm  'git commit -m'
abbr --add gp   'git push'
abbr --add gl   'git log --oneline --graph --decorate --all'
abbr --add gd   'git diff'
abbr --add gco  'git checkout'
abbr --add gsw  'git switch'
abbr --add gundo 'git reset --soft HEAD~1'
abbr --add gst  'git stash'
abbr --add gstp 'git stash pop'

if command -q lazygit
    abbr --add lg lazygit
end

if command -q delta
    abbr --add gdd 'git diff | delta'   # delta diff with pager
end

# ── Stow ───────────────────────────────────────────────────────────────────────
abbr --add stow-all 'cd ~/dotfiles && stow */'
abbr --add stow-sim 'cd ~/dotfiles && stow --simulate */'
abbr --add stow-re  'cd ~/dotfiles && stow -R */'

# ── Tools ──────────────────────────────────────────────────────────────────────
abbr --add oc    opencode
abbr --add occ   'opencode --continue'
abbr --add brup  'brew update && brew upgrade'
abbr --add brewc 'brew cleanup --prune=all'  # free up brew cache space