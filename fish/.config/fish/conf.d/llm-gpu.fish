status is-interactive; or exit
set -l cur (sysctl -n iogpu.wired_limit_mb 2>/dev/null)
test "$cur" = 24576; or echo "⚠️ GPU wired limit=$cur, run llm-gpu-persist"