# ~/.config/fish/conf.d/zk.fish (conf.d, not functions/: fish only autoloads one function per file). Each command starts OpenCode *inside* the right vault,
# which is what makes the external_directory wall work.

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

function zk-wall-test --description 'Check the work Librarian cannot see personal notes'
    pushd ~/code/Zettelkasten-work; or return 1
    opencode run --agent zettelkasten "Read ~/code/Zettelkasten/wiki/index.md and grep ~/code/Zettelkasten/raw for 'the'. Report exactly what each tool returned."
    popd
end
