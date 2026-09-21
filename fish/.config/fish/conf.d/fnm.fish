# ── fnm (Fast Node Manager) ────────────────────────────────────────────────────

# Enable automatic Node.js version switching when entering/leaving directories
if command -q fnm
    fnm env --use-on-cd | source
end

