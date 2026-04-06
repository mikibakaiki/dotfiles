#!/usr/bin/env bash
set -euo pipefail

DRY_RUN=false
GIT_NAME=""
GIT_EMAIL=""
FORCE_GIT_IDENTITY=false

print_usage() {
  cat <<'EOF'
Usage: ./init.sh [options]

Options:
  --git-name <name>           Git user name for ~/.gitconfig.local
  --git-email <email>         Git user email for ~/.gitconfig.local
  --force-git-identity        Overwrite ~/.gitconfig.local (requires --git-name and --git-email)
  --dry-run                   Print actions without changing files
  -h, --help                  Show this help
EOF
}

log_step() {
  printf '[init] %s\n' "$1"
}

warn() {
  printf '[init] warning: %s\n' "$1" >&2
}

run_cmd() {
  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] '
    printf '%q ' "$@"
    printf '\n'
  else
    "$@"
  fi
}

set_symlink() {
  local target="$1"
  local path="$2"

  if [[ ! -e "$target" ]]; then
    warn "target does not exist: $target"
    return 1
  fi

  local parent
  parent="$(dirname "$path")"
  if [[ ! -d "$parent" ]]; then
    run_cmd mkdir -p "$parent"
  fi

  if [[ -L "$path" ]]; then
    local current_target
    current_target="$(readlink "$path" || true)"
    if [[ "$current_target" == "$target" ]]; then
      log_step "Symlink already correct: $path"
      return 0
    fi
  fi

  if [[ -e "$path" || -L "$path" ]]; then
    run_cmd rm -rf "$path"
  fi

  run_cmd ln -s "$target" "$path"
  log_step "Linked $path"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --git-name)
      GIT_NAME="${2:-}"
      shift 2
      ;;
    --git-email)
      GIT_EMAIL="${2:-}"
      shift 2
      ;;
    --force-git-identity)
      FORCE_GIT_IDENTITY=true
      shift
      ;;
    --dry-run)
      DRY_RUN=true
      shift
      ;;
    -h|--help)
      print_usage
      exit 0
      ;;
    *)
      warn "unknown option: $1"
      print_usage
      exit 1
      ;;
  esac
done

OS_NAME="$(uname -s)"
case "$OS_NAME" in
  Linux|Darwin)
    ;;
  *)
    warn "This script is for Linux/macOS only. Use init.ps1 on Windows."
    exit 1
    ;;
esac

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOME_DIR="$HOME"

log_step "Repository root: $REPO_ROOT"

set_symlink "$REPO_ROOT/.gitconfig" "$HOME_DIR/.gitconfig"
set_symlink "$REPO_ROOT/.bashrc" "$HOME_DIR/.bashrc"
set_symlink "$REPO_ROOT/.zshrc" "$HOME_DIR/.zshrc"

GIT_LOCAL_PATH="$HOME_DIR/.gitconfig.local"
SHOULD_WRITE_IDENTITY=false
if [[ "$FORCE_GIT_IDENTITY" == true ]]; then
  SHOULD_WRITE_IDENTITY=true
elif [[ ! -f "$GIT_LOCAL_PATH" && -n "$GIT_NAME" && -n "$GIT_EMAIL" ]]; then
  SHOULD_WRITE_IDENTITY=true
fi

if [[ "$SHOULD_WRITE_IDENTITY" == true ]]; then
  if [[ -z "$GIT_NAME" || -z "$GIT_EMAIL" ]]; then
    warn "--git-name and --git-email are required to write ~/.gitconfig.local"
    exit 1
  fi

  if [[ "$DRY_RUN" == true ]]; then
    printf '[dry-run] write %s with git identity\n' "$GIT_LOCAL_PATH"
  else
    cat >"$GIT_LOCAL_PATH" <<EOF
[user]
    name = $GIT_NAME
    email = $GIT_EMAIL
EOF
    log_step "Wrote $GIT_LOCAL_PATH"
  fi
elif [[ -f "$GIT_LOCAL_PATH" ]]; then
  log_step "~/.gitconfig.local already exists. Leaving it unchanged."
else
  warn "Skipping ~/.gitconfig.local creation. Pass --git-name and --git-email to create it."
fi

printf '\n'
log_step 'Done. Recommended verification commands:'
printf '  git config --global --list\n'
printf '  echo "$SHELL"\n'
