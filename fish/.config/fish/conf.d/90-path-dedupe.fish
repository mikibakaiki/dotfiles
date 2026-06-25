# De-duplicate PATH entries while preserving order.
set -l _path_unique
for p in $PATH
    if not contains -- $p $_path_unique
        set _path_unique $_path_unique $p
    end
end
set -gx PATH $_path_unique
set -e _path_unique
