# ── XDG ───────────────────────────────────────────────────────────────────────
set -gx XDG_CONFIG_HOME "$HOME/.config"
set -gx XDG_DATA_HOME   "$HOME/.local/share"
set -gx XDG_CACHE_HOME  "$HOME/.cache"
set -gx XDG_STATE_HOME  "$HOME/.local/state"

set -g fish_greeting ""
# ── Git ────────────────────────────────────────────────────────────────────────
# Point git at the XDG config path (git 2.x reads this automatically,
# but setting it explicitly guarantees it across all tools and scripts)
set -gx GIT_CONFIG_GLOBAL "$HOME/.config/git/config"

# ── Homebrew ───────────────────────────────────────────────────────────────────
if test -x /opt/homebrew/bin/brew
    eval (/opt/homebrew/bin/brew shellenv)
end

# ── PATH ───────────────────────────────────────────────────────────────────────
fish_add_path "$HOME/.local/bin"
fish_add_path "$HOME/bin"

# ── Editor ─────────────────────────────────────────────────────────────────────
set -gx EDITOR "zed --wait"
set -gx VISUAL $EDITOR

# ── Pager ──────────────────────────────────────────────────────────────────────
set -gx MANPAGER "bat -l man -p"

# ── GPG ────────────────────────────────────────────────────────────────────────
set -gx GPG_TTY (tty)

# ── Starship ───────────────────────────────────────────────────────────────────
set -gx STARSHIP_CONFIG "$XDG_CONFIG_HOME/starship.toml"

# ── opencode ───────────────────────────────────────────────────────────────────
set -gx OPENCODE_CONFIG "$XDG_CONFIG_HOME/opencode/config.json"

# ── zoxide ─────────────────────────────────────────────────────────────────────
if command -q zoxide
    zoxide init fish | source
end

# ── conf.d/ is auto-sourced by fish after this file, alphabetically ────────────
# 20-env-public.fish   — non-sensitive env vars
# 30-env-secrets.fish  — loads .env.personal and .env.work (gitignored)
# 90-path-dedupe.fish  — deduplicates PATH last
# aliases.fish, fzf.fish, fnm.fish, prompt.fish, etc.