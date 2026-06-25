# ── fzf ────────────────────────────────────────────────────────────────────────
# Requires: fzf >= 0.48, fd, bat
# Key bindings loaded by this file:
#   Ctrl+R  — search command history
#   Ctrl+T  — fuzzy file picker (includes hidden files)
#   Alt+C   — cd into a directory
#   Ctrl+F  — fuzzy file picker (excludes hidden files, custom)

if not command -q fzf
    return
end

# Use fd as the default finder — faster than find, respects .gitignore
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --strip-cwd-prefix --exclude .git'
set -gx FZF_CTRL_T_COMMAND  $FZF_DEFAULT_COMMAND

# UI
set -gx FZF_DEFAULT_OPTS '
  --height=60%
  --layout=reverse
  --border=rounded
  --prompt="  "
  --pointer="  "
  --preview-window=right:65%:wrap:border-left
'

# bat preview for Ctrl+T
set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=plain,numbers --line-range=:500 {}'"

# Load fzf fish key bindings and completions (fzf >= 0.48)
fzf --fish | source