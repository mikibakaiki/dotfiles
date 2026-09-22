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
# NOT the MTP build: self-MTP measures ~13x slower than baseline on Apple Metal
# (llama.cpp #23011, still reproduced in #23752).
#
# Sizing: this quant is ~22.3 GB against a 24576 MB wired limit, so it will NOT fit at
# the 27B's 65536 context. It runs at 32768 with a q8_0 KV cache, which is what
# opencode.jsonc declares for this model. If it still OOMs on your machine, drop to a
# smaller quant rather than raising the context.
set -g __llm_fast_repo bartowski/Qwen_Qwen3.6-35B-A3B-GGUF:Q4_K_M
set -g __llm_fast_ctx 32768

function llm-status --description 'Is llama-server up, and which model is loaded?'
    # 5s, not 2: a cold start has to map ~17 GB off disk before it answers.
    if not curl -sf --max-time 5 $__llm_url/v1/models >/dev/null 2>&1
        echo "down  (if you just started it, give it a minute — the model has to load)"
        return 1
    end
    set -l id (curl -sf --max-time 5 $__llm_url/v1/models \
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
# Runs in the FOREGROUND and holds the terminal: Ctrl-C stops it and leaves you with no
# server at all, so run `llm-up` afterwards to get the default back.
function llm-fast --description 'Swap to the faster MoE model (foreground; Ctrl-C then llm-up)'
    llm-down >/dev/null
    echo "Loading $__llm_fast_repo at ctx $__llm_fast_ctx on :8080."
    echo "Holds this terminal. Ctrl-C to stop, then run llm-up for the default model."
    llama-server -hf $__llm_fast_repo \
        -c $__llm_fast_ctx -ngl all --host 127.0.0.1 --port 8080 -np 1 \
        -ctk q8_0 -ctv q8_0 -a qwen3.6-35b-a3b-local $argv
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
