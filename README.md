# dotfiles

Personal configuration files managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each tool's config lives in this repo and gets symlinked into the correct location under `~`.

---

## Structure

```
dotfiles/
├── .gitignore
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
│           ├── fnm.fish                 — Node version manager
│           ├── fzf.fish                 — fuzzy finder + key bindings
│           ├── pyenv.fish               — Python version manager
│           ├── .env.personal.example    — template → copy to .env.personal
│           └── .env.work.example        — template → copy to .env.work
│
├── ghostty/                  ← stow package → ~/.config/ghostty/
│   └── .config/ghostty/
│       └── config            — terminal, fish integration, font, theme
│
├── git/                      ← stow package → ~/.config/git/
│   └── .config/git/
│       ├── config            — shared settings, aliases, delta, no [user] block
│       ├── config.local.example  — template → copy to config.local
│       └── ignore            — global gitignore (DS_Store, node_modules, etc.)
│
├── opencode/                 ← stow package → ~/.config/opencode/
│   ├── .stow-local-ignore
│   └── .config/opencode/
│       ├── opencode.jsonc    — model, MCP servers, plugins
│       ├── dcp.jsonc         — DCP plugin config
│       ├── AGENTS.md         — agent usage guide
│       ├── agents/           — agent definition files (.md)
│       ├── commands/         — slash command definitions (.md)
│       └── plugins/
│           └── graphify.js   — graphify local plugin
│
├── starship/                 ← stow package → ~/.config/starship.toml
│   └── .config/
│       └── starship.toml     — catppuccin mocha prompt
│
├── vscode/                   ← NOT stowed, uses install.sh
│   ├── install.sh            — creates symlinks into ~/Library/Application Support/Code/User/
│   ├── settings.json         — editor, terminal, extensions config
│   ├── mcp.json              — MCP servers for GitHub Copilot
│   ├── settings.local.example — template for work-specific settings (Jira JQL etc.)
│   └── .stow-local-ignore
│
└── zed/                      ← stow package → ~/.config/zed/
    ├── .stow-local-ignore
    └── .config/zed/
        ├── settings.json     — editor, terminal (fish), agent model
        └── themes/
```

---

## How stow works

Each subdirectory is a stow **package**. The path inside it mirrors `~/` exactly.
Running `stow fish` makes stow walk `fish/` and create a symlink for every file,
placing it relative to `$HOME`.

Example:

```
~/dotfiles/fish/.config/fish/config.fish
                 ↓ stow creates
~/.config/fish/config.fish  →  ~/dotfiles/fish/.config/fish/config.fish
```

The actual files live in the repo. The tools see them at the paths they expect.

---

## Fresh machine setup

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/YOU/dotfiles/main/bootstrap.sh)
```

Or manually:

```bash
git clone git@github.com:YOU/dotfiles.git ~/dotfiles
cd ~/dotfiles
stow fish ghostty git opencode starship zed
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
```

Fill in real values. See `fish/.config/fish/ENV_VARS.md` for the full list
of expected keys and what each one is for.

The secret loader (`conf.d/30-env-secrets.fish`) silently skips missing `.env`
files — a fresh machine works before secrets are populated.

---

## VS Code

VS Code stores its config in `~/Library/Application Support/Code/User/` (macOS),
not in `~/.config/`, so stow can't manage it directly.

The `vscode/install.sh` script creates the symlinks manually:

```bash
~/dotfiles/vscode/install.sh
```

For work-specific settings (Jira JQL queries, internal URLs), see
`vscode/settings.local.example` — these are set manually in VS Code on each
work machine and are not committed.

---

## opencode

Plugins used:

| Plugin                    | Type  | Purpose                                       |
| ------------------------- | ----- | --------------------------------------------- |
| `@tarquinen/opencode-dcp` | npm   | Dynamic context pruning — reduces token usage |
| `opencode-caveman`        | npm   | Token compression                             |
| `./plugins/graphify.js`   | local | Knowledge graph / RAG over codebases          |

MCP servers (Jira, Confluence) are configured in `opencode.jsonc`.
Credentials are injected at runtime via `{env:JIRA_PAT}` — values come
from `~/.config/fish/conf.d/.env.work`, never hardcoded.

Runtime files (`node_modules/`, `skills/`, `tui.json`, `package.json`) are
excluded via `.stow-local-ignore` and `.gitignore` — opencode manages these itself.

---

## Git config

The `git/` package puts everything under `~/.config/git/` (XDG-compliant).
Git 2.x reads this location automatically. `GIT_CONFIG_GLOBAL` is also set
explicitly in `config.fish` as a belt-and-suspenders guarantee.

There is no `[user]` block in the tracked config — identity is per-machine:

```bash
# ~/.config/git/config.local  (gitignored)
[user]
    name  = Your Name
    email = you@example.com
```

Tracked config includes: delta diffs, `zdiff3` conflict style,
`push.autoSetupRemote`, rebase-by-default pull, branch cleanup aliases,
SSH URL rewrites for GitHub.

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

Prefix with a number only if load order matters (`90-path-dedupe.fish` must
run last). Otherwise plain names are fine — fish sources `conf.d/` alphabetically.
