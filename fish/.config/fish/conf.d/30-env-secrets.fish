# ── Secret environment variables ───────────────────────────────────────────────
# This file IS tracked in git. The .env files it reads are NOT.
#
# Create these files manually on each machine:
#   ~/.config/fish/conf.d/.env.personal   — personal API keys
#   ~/.config/fish/conf.d/.env.work       — work URLs, tokens, etc.
#
# Format inside those files:
#   KEY=value
#   KEY="value with spaces"
#   # lines starting with # are ignored
#   export KEY=value        (export keyword is handled)


function _load_env_file
    set -l env_file $argv[1]
    if not test -f $env_file
        return
    end
    while read -la line
        # skip empty lines and comments
        string match -qr '^\s*$|^\s*#' -- $line
        and continue
        # skip lines without =
        string match -qr '=' -- $line
        or continue
        # strip export keyword
        set line (string replace -r '^export\s+' '' -- $line)
        # split on first = only
        set -l parts (string split -m 1 '=' -- $line)
        test (count $parts) -lt 2; and continue
        set -l key   $parts[1]
        set -l value $parts[2]
        # strip surrounding quotes
        set value (string trim -c '"' -- $value)
        set value (string trim -c "'" -- $value)
        # only set if key looks valid (letters, numbers, underscore)
        string match -qr '^[A-Za-z_][A-Za-z0-9_]*$' -- $key
        and set -gx $key $value
    end < $env_file
end

_load_env_file "$__fish_config_dir/conf.d/.env.personal"
_load_env_file "$__fish_config_dir/conf.d/.env.work"

functions -e _load_env_file