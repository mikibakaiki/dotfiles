# ~/.config/fish/conf.d/llm.fish
# conf.d, not functions/: fish only autoloads one function per file, and this file holds five.
#
# llama-server listens on 127.0.0.1:8080 and answers with whichever model is currently loaded.
# OpenCode's llamacpp provider pins the *endpoint*, not the model name, so swapping models is just
# "stop one, start the other on the same port" — no config edit needed.
#
# A LaunchAgent starts the default model at login (see llm-serve-persist). These functions are the
# manual override for when you want it down, restarted, or running the faster MoE instead.

set -g __llm_label local.llama-server
set -g __llm_plist ~/.config/llm/local.llama-server.plist
set -g __llm_agent ~/Library/LaunchAgents/local.llama-server.plist
set -g __llm_url http://127.0.0.1:8080

# The MoE. Faster for reading many pages (the Archivist), weaker for careful writing.
# NOT the MTP build: self-MTP is ~13x slower than baseline on Apple Metal (llama.cpp #23011).
set -g __llm_fast_repo bartowski/Qwen_Qwen3.6-35B-A3B-GGUF:Q4_K_M

function llm-status --description 'Is llama-server up, and which model is loaded?'
    if not curl -sf --max-time 2 $__llm_url/v1/models >/dev/null 2>&1
        echo "down"
        return 1
    end
    set -l id (curl -sf --max-time 2 $__llm_url/v1/models \
        | string match -gr '"id"\s*:\s*"([^"]+)"' | head -n1)
    if test -n "$id"
        echo "up — $id"
    else
        echo "up"
    end
end

function llm-up --description 'Start the llama-server LaunchAgent'
    if not test -f $__llm_agent
        echo "Agent not installed. Run llm-serve-persist first."
        return 1
    end
    launchctl bootstrap gui/(id -u) $__llm_agent 2>/dev/null
    or launchctl kickstart -k gui/(id -u)/$__llm_label
    echo "Starting — first run downloads the model, which takes a while."
    echo "Watch: tail -f /tmp/llama-server.err.log"
end

function llm-down --description 'Stop llama-server'
    launchctl bootout gui/(id -u)/$__llm_label 2>/dev/null
    # Also catch a foreground/llm-fast instance the agent doesn't own.
    pkill -f 'llama-server .*--port 8080' 2>/dev/null
    echo "stopped"
end

# Swaps the loaded model without touching OpenCode config, since the provider pins the endpoint.
function llm-fast --description 'Swap to the faster MoE model on the same port'
    llm-down >/dev/null
    echo "Loading $__llm_fast_repo on :8080 — llm-up returns you to the default."
    llama-server -hf $__llm_fast_repo \
        -c 65536 -ngl all --host 127.0.0.1 --port 8080 -np 1 $argv
end

function llm-serve-persist --description 'Install the llama-server LaunchAgent'
    if not type -q llama-server
        echo "llama-server not found. brew install llama.cpp"
        return 1
    end
    mkdir -p ~/Library/LaunchAgents
    cp $__llm_plist $__llm_agent; or return 1
    launchctl bootout gui/(id -u)/$__llm_label 2>/dev/null
    launchctl bootstrap gui/(id -u) $__llm_agent; or return 1
    echo "Installed. First start downloads the model (~17 GB)."
    echo "Watch: tail -f /tmp/llama-server.err.log"
end
