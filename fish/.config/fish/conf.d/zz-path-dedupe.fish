# De-duplicate PATH entries while preserving order.
#
# Named zz- so it actually sources LAST. Fish sources conf.d/ alphabetically and digits
# sort before letters, so the old name (90-path-dedupe.fish) ran third of twelve —
# before fnm.fish and pyenv.fish, both of which prepend to PATH via `... | source`.
# The dedupe therefore never saw the entries it exists to remove.
set -l _path_unique
for p in $PATH
    if not contains -- $p $_path_unique
        set _path_unique $_path_unique $p
    end
end
set -gx PATH $_path_unique
set -e _path_unique
