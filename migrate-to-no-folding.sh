#!/usr/bin/env bash
# migrate-to-no-folding.sh — one-time move from folded stow links to --no-folding.
#
# Before .stowrc had --no-folding, stow linked whole directories (~/.config/opencode,
# ~/.config/fish, ~/.ssh, ...) into this repo. So everything written under them — a work
# opencode.json override, SSH keys, .env.work, fish_variables — physically landed inside
# ~/dotfiles. Restowing with --no-folding alone would leave those files stranded in the
# repo, where the apps no longer look: no error, the settings just silently vanish.
#
# This moves them back out to $HOME first, then restows.
#
#   ./migrate-to-no-folding.sh           list what would move; changes nothing
#   ./migrate-to-no-folding.sh --apply   check, unstow, move files out, restow
#
# List mode exits 1 if anything is stranded, so bootstrap.sh can refuse to restow over it.
set -euo pipefail
cd "$(dirname "$0")"   # .stowrc supplies --target=$HOME and --no-folding from here

apply=0
[[ "${1:-}" == "--apply" ]] && apply=1

pkgs=()
for d in */; do
    d="${d%/}"
    case "$d" in vscode|docs|zettelkasten) continue ;; esac
    pkgs+=("$d")
done

# Files git does not track that physically sit inside a package. Under folding, that is
# exactly where anything an app wrote into a linked directory ended up. Untracked and
# ignored directories are reported as one entry, so node_modules moves as a unit.
strays=()
while IFS= read -r -d '' entry; do
    state="${entry:0:2}"
    path="${entry:3}"
    [[ "$state" == "!!" || "$state" == "??" ]] || continue
    path="${path%/}"
    [[ "$(basename "$path")" == ".DS_Store" ]] && continue
    strays+=("$path")
done < <(git status --porcelain -z --ignored --untracked-files=normal -- "${pkgs[@]}")

if [ "${#strays[@]}" -eq 0 ]; then
    echo "Nothing stranded inside the packages."
else
    echo "Untracked files living inside the repo (left there by the old folded layout):"
    for p in "${strays[@]}"; do
        echo "  $p  ->  ~/${p#*/}"
    done
fi

if [ "$apply" -eq 0 ]; then
    [ "${#strays[@]}" -eq 0 ] && exit 0
    echo ""
    echo "Nothing changed. Run with --apply to move these out and restow."
    exit 1
fi

# Preflight: simulate the full restow before touching anything. A real file sitting where
# stow wants a link would abort the restow halfway, leaving configs unstowed.
if ! stow -n -R "${pkgs[@]}" >/dev/null 2>&1; then
    echo ""
    echo "Stopped before changing anything — a simulated restow failed:"
    stow -n -R "${pkgs[@]}" 2>&1 | grep -v 'simulation mode' || true
    echo "Resolve those (see Conflicts in the README), then run this again."
    exit 1
fi

echo ""
echo "Unstowing: ${pkgs[*]}"
stow -D "${pkgs[@]}"

skipped=0
if [ "${#strays[@]}" -gt 0 ]; then
    for p in "${strays[@]}"; do
        dest="$HOME/${p#*/}"
        if [ -e "$dest" ] || [ -L "$dest" ]; then
            echo "  SKIP  $dest already exists — left in the repo at $p"
            skipped=1
            continue
        fi
        mkdir -p "$(dirname "$dest")"
        mv "$p" "$dest"
        echo "  moved $p -> $dest"
    done
fi

echo "Restowing with --no-folding"
if ! stow "${pkgs[@]}"; then
    echo "Restow failed. Your moved files are safe in \$HOME. Fix the conflicts above, then:"
    echo "  cd $(pwd) && stow ${pkgs[*]}"
    exit 1
fi

# stow creates ~/.ssh with the default umask; ssh wants it private.
[ -d "$HOME/.ssh" ] && chmod 700 "$HOME/.ssh"

echo ""
if [ "$skipped" -eq 1 ]; then
    echo "Done, but some files were skipped — compare each SKIP pair and keep the right one."
else
    echo "Done. Directories under \$HOME are real now; only tracked files are links."
fi
