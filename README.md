# dotfiles

Personal configuration files managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each tool's config lives in this repo and gets symlinked into the correct location under `~`.

---

## Structure

```
dotfiles/
├── .gitignore
├── .stow-local-ignore        — excludes vscode from stow */
├── .stowrc                   — stow defaults: target=$HOME, verbose
├── bootstrap.sh              — fresh machine setup
├── README.md
│
├── fish/                     ← stow package → ~/.config/fish/
│   └── .config/fish/
│       ├── config.fish       — XDG, homebrew, PATH, editor, pager, git, zoxide
│       ├── ENV_VARS.md       — documents every custom env variable
│       ├── completions/
│       │   ├── copilot.fish
│       │   └── docker.fish
│       └── conf.d/
│           ├── 20-env-public.fish       — non-sensitive env vars
│           ├── 30-env-secrets.fish      — loader: reads .env.personal + .env.work
│           ├── 90-path-dedupe.fish      — deduplicates PATH, runs last
│           ├── aliases.fish             — abbreviations
│           ├── fish_frozen_theme.fish   — theme
│           ├── fnm.fish                 — Node version manager init
│           ├── fzf.fish                 — fuzzy finder + key bindings
│           ├── prompt.fish              — starship init
│           ├── pyenv.fish               — Python version manager init
│           ├── .env.personal.example    — template → copy to .env.personal
│           └── .env.work.example        — template → copy to .env.work
│
├── ghostty/                  ← stow package → ~/.config/ghostty/
│   └── .config/ghostty/
│       └── config            — font, theme (minimal — ghostty auto-detects fish)
│
├── git/                      ← stow package → ~/.config/git/
│   └── .config/git/
│       ├── config            — shared settings, aliases, delta, no [user] block
│       ├── config.local.example  — template → copy to config.local
│       └── ignore            — global gitignore
│
├── opencode/                 ← stow package → ~/.config/opencode/
│   ├── .stow-local-ignore    — excludes node_modules, skills, tui.json
│   └── .config/opencode/
│       ├── opencode.jsonc    — model, MCP servers, plugins
│       ├── dcp.jsonc         — DCP plugin config
│       ├── AGENTS.md         — agent usage guide
│       ├── agents/           — agent definition files (.md)
│       ├── commands/         — slash command definitions (.md)
│       └── plugins/
│           └── graphify.js   — graphify local plugin
│
├── ssh/                      ← stow package → ~/.ssh/
│   ├── .stow-local-ignore    — excludes private keys, known_hosts
│   └── .ssh/
│       └── config            — host aliases, key mappings (personal vs work)
│
├── starship/                 ← stow package → ~/.config/starship.toml
│   └── .config/
│       └── starship.toml     — catppuccin mocha prompt
│
├── vscode/                   ← NOT stowed, uses install.sh
│   ├── .stow-local-ignore
│   ├── install.sh            — symlinks into ~/Library/Application Support/Code/User/
│   ├── settings.json         — editor, terminal, extensions config
│   ├── mcp.json              — MCP servers for GitHub Copilot
│   └── settings.local.example — template for work-specific settings
│
└── zed/                      ← stow package → ~/.config/zed/
    ├── .stow-local-ignore    — excludes themes/, prompts/
    └── .config/zed/
        └── settings.json     — editor, terminal (fish), agent model
```

---

## How stow works

Each subdirectory is a stow **package**. The path inside mirrors `~/` exactly.
Running `stow fish` makes stow walk `fish/` and symlink every file relative to `$HOME`.

```
~/dotfiles/fish/.config/fish/config.fish
                 ↓ stow creates
~/.config/fish/config.fish  →  ~/dotfiles/fish/.config/fish/config.fish
```

Note: `ssh/` is an exception — it targets `~/.ssh/` directly, not `~/.config/`:

```
~/dotfiles/ssh/.ssh/config
                 ↓ stow creates
~/.ssh/config  →  ~/dotfiles/ssh/.ssh/config
```

---

## Fresh machine setup

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mikibakaiki/dotfiles/main/bootstrap.sh)
```

Or manually:

```bash
git clone git@github-personal:mikibakaiki/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow fish ghostty git opencode ssh starship zed
~/dotfiles/vscode/install.sh
```

---

## Stow commands

Run from `~/dotfiles`. The `.stowrc` sets `--target=$HOME` automatically.

```bash
stow fish           # symlink the fish package
stow -R fish        # restow (use after adding or moving files)
stow -D fish        # remove symlinks for one package
stow --simulate */  # dry run — shows what would happen
stow */             # stow all packages (vscode excluded via .stow-local-ignore)
```

If stow reports a conflict, a real file already exists at the target.
Move it into the repo first, then restow:

```bash
mv ~/.config/sometool ~/dotfiles/sometool/.config/sometool
cd ~/dotfiles && stow sometool
```

---

## Secrets

These files live **only on your machine** and are never committed:

| File                                  | Purpose                    | Template                |
| ------------------------------------- | -------------------------- | ----------------------- |
| `~/.config/fish/conf.d/.env.personal` | Personal API keys          | `.env.personal.example` |
| `~/.config/fish/conf.d/.env.work`     | Work URLs and tokens       | `.env.work.example`     |
| `~/.config/git/config.local`          | Git identity (name, email) | `config.local.example`  |
| `~/.ssh/id_ed25519_github_personal`   | Personal GitHub SSH key    | —                       |

Create them on a fresh machine:

```bash
# Fish secrets
cp ~/.config/fish/conf.d/.env.personal.example \
   ~/.config/fish/conf.d/.env.personal
cp ~/.config/fish/conf.d/.env.work.example \
   ~/.config/fish/conf.d/.env.work

# Git identity
cp ~/.config/git/config.local.example \
   ~/.config/git/config.local

# SSH key — generate fresh, never copy private keys between machines
ssh-keygen -t ed25519 -C "your.personal@email.com" -f ~/.ssh/id_ed25519_github_personal
ssh-add --apple-use-keychain ~/.ssh/id_ed25519_github_personal
# then add the public key to github.com/settings/ssh/new
```

See `fish/.config/fish/ENV_VARS.md` for the full list of expected env keys.

---

## SSH config

`~/.ssh/config` (tracked at `ssh/.ssh/config`) defines host aliases so different
SSH keys can be used for different GitHub accounts:

```
Host github-personal        → uses id_ed25519_github_personal
Host github.com             → uses work key (default)
```

Clone personal repos using the alias:

```bash
git clone git@github-personal:mikibakaiki/reponame.git
```

Private keys are excluded via `ssh/.stow-local-ignore` and never committed.

---

## Git identity

The `git/` package puts everything under `~/.config/git/` (XDG-compliant).
`GIT_CONFIG_GLOBAL` is set in `config.fish` to ensure git always finds it.

No `[user]` block in the tracked config — identity is per-machine via `config.local`:

```ini
# ~/.config/git/config.local  (gitignored)
[user]
    name  = Your Name
    email = your.work@email.com
```

For the dotfiles repo itself, a personal identity is set repo-locally:

```bash
cd ~/dotfiles
git config user.name  "Your Name"
git config user.email "your.personal@email.com"
```

This writes to `~/dotfiles/.git/config` and overrides the global identity
only for this repo.

---

## VS Code

VS Code stores config in `~/Library/Application Support/Code/User/` on macOS,
not in `~/.config/`, so stow can't manage it directly.

`vscode/install.sh` creates the symlinks manually:

```bash
~/dotfiles/vscode/install.sh
```

For work-specific settings (Jira JQL queries, internal URLs), see
`vscode/settings.local.example` — set these manually in VS Code on each
work machine, not committed.

---

## opencode

Plugins:

| Plugin                    | Type  | Purpose                                       |
| ------------------------- | ----- | --------------------------------------------- |
| `@tarquinen/opencode-dcp` | npm   | Dynamic context pruning — reduces token usage |
| `opencode-caveman`        | npm   | Token compression                             |
| `./plugins/graphify.js`   | local | Knowledge graph / RAG over codebases          |

MCP servers (Jira, Confluence) are in `opencode.jsonc`.
Credentials injected via `{env:JIRA_PAT}` — values from `.env.work`, never hardcoded.

Runtime files (`node_modules/`, `skills/`, `tui.json`) excluded via
`.stow-local-ignore` — opencode manages these itself.

---

## Tool stack

| Tool                                                | Purpose                 | Config                 |
| --------------------------------------------------- | ----------------------- | ---------------------- |
| [fish](https://fishshell.com)                       | Shell                   | `fish/`                |
| [starship](https://starship.rs)                     | Prompt                  | `starship/`            |
| [ghostty](https://ghostty.org)                      | Terminal                | `ghostty/`             |
| [zed](https://zed.dev)                              | Editor                  | `zed/`                 |
| [VS Code](https://code.visualstudio.com)            | Editor                  | `vscode/`              |
| [opencode](https://opencode.ai)                     | AI coding assistant     | `opencode/`            |
| [fnm](https://github.com/Schniz/fnm)                | Node version manager    | `conf.d/fnm.fish`      |
| [pyenv](https://github.com/pyenv/pyenv)             | Python version manager  | `conf.d/pyenv.fish`    |
| [fzf](https://github.com/junegunn/fzf)              | Fuzzy finder            | `conf.d/fzf.fish`      |
| [fd](https://github.com/sharkdp/fd)                 | Better `find`           | fzf backend            |
| [bat](https://github.com/sharkdp/bat)               | Better `cat`            | fzf preview, man pages |
| [eza](https://github.com/eza-community/eza)         | Better `ls`             | via aliases            |
| [ripgrep](https://github.com/BurntSushi/ripgrep)    | Better `grep`           | via aliases            |
| [zoxide](https://github.com/ajeetdsouza/zoxide)     | Smarter `cd`            | `config.fish`          |
| [delta](https://github.com/dandavison/delta)        | Better git diffs        | `git/config`           |
| [lazygit](https://github.com/jesseduffield/lazygit) | Git TUI                 | via `lg` alias         |
| [GNU Stow](https://www.gnu.org/software/stow/)      | Dotfile symlink manager | `.stowrc`              |

---

## Adding a new tool

```bash
# 1. Create the package directory
mkdir -p ~/dotfiles/TOOL/.config/TOOL

# 2. Move existing config in (stow refuses to overwrite real files)
mv ~/.config/TOOL ~/dotfiles/TOOL/.config/TOOL

# 3. Stow it
cd ~/dotfiles && stow TOOL

# 4. Commit
git add TOOL
git commit -m "feat: add TOOL"
```

## Adding a new fish conf.d file

```bash
# 1. Create in the repo
cat > ~/dotfiles/fish/.config/fish/conf.d/mymodule.fish << 'EOF'
# content
EOF

# 2. Restow
cd ~/dotfiles && stow -R fish

# 3. Commit
git add fish/.config/fish/conf.d/mymodule.fish
git commit -m "feat(fish): add mymodule"
```

Prefix with a number only if load order matters.
Fish sources `conf.d/` alphabetically — `90-path-dedupe.fish` must run last.
