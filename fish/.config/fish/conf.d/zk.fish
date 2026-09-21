# ~/.config/fish/conf.d/zk.fish (conf.d, not functions/: fish only autoloads one function per file). Each command starts OpenCode *inside* the right vault,
# which is what makes the external_directory wall work.
#
# Never run zk-ingest-work and zk-ingest-personal at the same time. Both Librarians can write
# tools/<tool>.md in the personal vault, there is no locking, and a concurrent write is a silent
# last-writer-wins overwrite. Run one, let it finish, then run the other.
#
# zk, zk-ingest-personal and zk-lint all need llama-server up on 127.0.0.1:8080. If it isn't,
# you get a raw connection error from the openai-compatible provider rather than a useful message:
#   curl -sf http://127.0.0.1:8080/v1/models >/dev/null; or echo "llama-server is down"
# Note the pin is by endpoint, not by name: llama-server answers with whichever model is loaded,
# so these run on the fast MoE model if that's what you have up.

function zk --description 'Archivist: query the wiki'
    pushd ~/code/Zettelkasten; or return 1
    opencode --agent archivist $argv
    popd
end

function zk-ingest-work --description 'Work Librarian: ingest raw/ in the work vault'
    pushd ~/code/Zettelkasten-work; or return 1
    opencode run --agent zettelkasten "Ingest new files in raw/. $argv"
    popd
end

function zk-ingest-personal --description 'Personal Librarian: ingest raw/ in the personal vault'
    pushd ~/code/Zettelkasten; or return 1
    opencode run --agent zettelkasten-personal "Ingest new files in raw/. $argv"
    popd
end

function zk-lint --description 'Personal Librarian: health-check the personal vault'
    pushd ~/code/Zettelkasten; or return 1
    opencode run --agent zettelkasten-personal "Run a lint pass over this vault. $argv"
    popd
end

function zk-lint-work --description 'Work Librarian: health-check the work vault'
    pushd ~/code/Zettelkasten-work; or return 1
    opencode run --agent zettelkasten "Run a lint pass over this vault. $argv"
    popd
end

# The vaults are the only recovery path if an ingest clobbers something, so commit them regularly.
function zk-sync --description 'Commit both vaults'
    for vault in ~/code/Zettelkasten ~/code/Zettelkasten-work
        if test -d $vault/.git
            git -C $vault add -A
            git -C $vault diff --cached --quiet; or git -C $vault commit -m "zk-sync: "(date +%Y-%m-%d)
        end
    end
end

function zk-wall-test --description 'Check the work Librarian cannot see personal notes'
    pushd ~/code/Zettelkasten-work; or return 1
    opencode run --agent zettelkasten "Read ~/code/Zettelkasten/wiki/index.md and grep ~/code/Zettelkasten/raw for 'the'. Report exactly what each tool returned."
    popd
end
