# ── Starship prompt ────────────────────────────────────────────────────────────
if command -q starship
    set -gx VIRTUAL_ENV_DISABLE_PROMPT 1
    starship init fish | source
end