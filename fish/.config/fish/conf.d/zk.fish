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
    set -l rc $status
    popd
    test $rc -eq 0; and zk-sync
    return $rc
end

function zk-ingest-personal --description 'Personal Librarian: ingest raw/ in the personal vault'
    pushd ~/code/Zettelkasten; or return 1
    opencode run --agent zettelkasten-personal "Ingest new files in raw/. $argv"
    set -l rc $status
    popd
    test $rc -eq 0; and zk-sync
    return $rc
end

# Ingest whichever vaults actually have unprocessed files, so you don't have to know the facet.
function zk-ingest --description 'Ingest any vault with pending raw files'
    set -l did 0
    if test (count (zk-_pending ~/code/Zettelkasten)) -gt 0
        zk-ingest-personal $argv; set did 1
    end
    if test (count (zk-_pending ~/code/Zettelkasten-work)) -gt 0
        zk-ingest-work $argv; set did 1
    end
    test $did -eq 1; or echo "Nothing pending. (zk-status)"
end

# Raw files with neither an `ingested:` nor a `refused:` stamp.
function zk-_pending --description 'Internal: list unprocessed raw files in a vault'
    test -d $argv[1]/raw; or return 0
    for f in $argv[1]/raw/*.md
        test -e $f; or continue
        grep -qE '^(ingested|refused):' $f; or echo $f
    end
end

function zk-status --description 'What is captured but not yet ingested?'
    for vault in ~/code/Zettelkasten ~/code/Zettelkasten-work
        set -l pending (zk-_pending $vault)
        set -l name (basename $vault)
        if test (count $pending) -gt 0
            echo "$name: "(count $pending)" pending"
            for f in $pending
                echo "  "(basename $f)
            end
        else
            echo "$name: clear"
        end
    end
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

# The vaults are the only recovery path if an ingest clobbers something. Runs automatically after
# each ingest; also safe to run by hand any time.
function zk-sync --description 'Commit both vaults'
    for vault in ~/code/Zettelkasten ~/code/Zettelkasten-work
        if test -d $vault/.git
            git -C $vault add -A
            git -C $vault diff --cached --quiet; or git -C $vault commit -m "zk-sync: "(date +%Y-%m-%d)
        end
    end
end

# The external_directory wall check that used to live here as `zk-wall-test` is a one-time setup
# step, not something to re-run, and it tested a boundary that was never meant to be a security
# boundary. It's in step 5 of MACOS_SETUP_zettelkasten.md instead.
