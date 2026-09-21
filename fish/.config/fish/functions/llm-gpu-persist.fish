function llm-gpu-persist
    set -l src ~/.config/llm/local.iogpu.wired-limit.plist
    set -l dst /Library/LaunchDaemons/local.iogpu.wired-limit.plist
    sudo cp $src $dst; and sudo chown root:wheel $dst; and sudo chmod 644 $dst
    sudo launchctl bootout system $dst 2>/dev/null
    sudo launchctl bootstrap system $dst
    sysctl iogpu.wired_limit_mb
end