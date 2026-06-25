# ── Better coreutils ───────────────────────────────────────────────────────────
if command -q eza
    abbr --add ls  'eza --icons'
    abbr --add ll  'eza -lh --icons --git'
    abbr --add la  'eza -lah --icons --git'
    abbr --add tree 'eza --tree --icons'
end

if command -q bat
    abbr --add cat  'bat'
    abbr --add catc 'bat --style=plain --paging=never'
end

if command -q rg
    abbr --add grep 'rg --color=auto'
end

# ── Navigation ─────────────────────────────────────────────────────────────────
abbr --add .. 'cd ..'
abbr --add ... 'cd ../..'
abbr --add dot 'cd ~/dotfiles'
abbr --add cfg 'cd ~/.config'

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

if command -q lazygit
    abbr --add lg lazygit
end

# ── Stow ───────────────────────────────────────────────────────────────────────
abbr --add stow-all 'cd ~/dotfiles && stow */'
abbr --add stow-sim 'cd ~/dotfiles && stow --simulate */'
abbr --add stow-re  'cd ~/dotfiles && stow -R */'

# ── Tools ──────────────────────────────────────────────────────────────────────
abbr --add oc    opencode
abbr --add occ   'opencode --continue'
abbr --add brup  'brew update && brew upgrade'