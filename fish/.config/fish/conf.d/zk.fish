# ~/.config/fish/conf.d/zk.fish
# conf.d, not functions/: fish only autoloads one function per file, and this file holds five.
#
# One vault per machine at ~/code/Zettelkasten. The machine decides what's in it — work content on
# the work laptop, personal content on the personal desktop. Nothing routes by content and nothing
# syncs: that is the whole privacy model. Each command runs OpenCode inside the vault, which is
# what makes the external_directory deny in opencode.jsonc work without getting in the way.
#
# zk, zk-ingest and zk-lint all need llama-server up on 127.0.0.1:8080. If it's down you get a raw
# connection error from the openai-compatible provider, not a useful message:
#   curl -sf http://127.0.0.1:8080/v1/models >/dev/null; or echo "llama-server is down"
# The pin is by endpoint, not by name: llama-server answers with whichever model is loaded.

function zk --description 'Archivist: query the wiki'
    pushd ~/code/Zettelkasten; or return 1
    opencode --agent archivist $argv
    popd
end

function zk-status --description 'What is captured but not yet ingested?'
    set -l pending (zk-_pending)
    if test (count $pending) -gt 0
        echo (count $pending)" pending:"
        for f in $pending
            echo "  "(basename $f)
        end
    else
        echo "clear"
    end
end

function zk-ingest --description 'Ingest pending raw files, then commit'
    if test (count (zk-_pending)) -eq 0
        echo "Nothing pending."
        return 0
    end
    pushd ~/code/Zettelkasten; or return 1
    opencode run --agent zettelkasten "Ingest new files in raw/. $argv"
    set -l rc $status
    popd
    if test $rc -eq 0
        git -C ~/code/Zettelkasten add -A
        git -C ~/code/Zettelkasten diff --cached --quiet
        or git -C ~/code/Zettelkasten commit -m "ingest: "(date +%Y-%m-%d)
    end
    return $rc
end

function zk-lint --description 'Librarian: health-check the vault'
    pushd ~/code/Zettelkasten; or return 1
    opencode run --agent zettelkasten "Run a lint pass over this vault. $argv"
    popd
end

# Raw files with no `ingested:` stamp. Only the leading --- block counts, so a verbatim error
# string in the body that starts with "ingested:" can't mark a file done.
function zk-_pending --description 'Internal: list unprocessed raw files'
    test -d ~/code/Zettelkasten/raw; or return 0
    for f in ~/code/Zettelkasten/raw/*.md
        test -e $f; or continue
        sed -n '1{/^---$/!q}; 1d; /^---$/q; p' $f | grep -qE '^ingested:'; or echo $f
    end
end
