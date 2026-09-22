# dotfiles

Personal configuration files managed with [GNU Stow](https://www.gnu.org/software/stow/).
Each tool's config lives in this repo and gets symlinked into the correct location under `~`.

---

## Start here

Setting up a machine — new or existing — run these in order. Each is one sitting, and each states
its own prerequisites.

| # | Guide | Run it on | What you get |
| --- | --- | --- | --- |
| 1 | [docs/setup-local-llm.md](docs/setup-local-llm.md) | **every** machine | llama.cpp, the model, `llama-server` on `:8080` at login. Everything else depends on this. |
| 2 | [docs/setup-zettelkasten.md](docs/setup-zettelkasten.md) | every machine that captures notes | The vault, the Librarian and Archivist agents, `/handoff`, the `zk-*` commands. |
| 3 | [docs/setup-work-machine.md](docs/setup-work-machine.md) | **work MacBook only** | Jira/Confluence/Jenkins MCP servers, work agent instructions, work git identity — all in untracked files. |

The Raspberry Pi runs none of these: it can't host the model, and a second personal vault would
diverge from the desktop's with nothing to sync it.

Everything employer-specific lives in gitignored override files, never in tracked config. Guide 3
lists exactly which values you supply and where each one goes.

---

## Structure

```
dotfiles/
├── .gitignore
├── .stow-local-ignore        — excludes vscode and zettelkasten from stow */
├── .stowrc                   — stow defaults: target=$HOME, verbose
├── bootstrap.sh              — fresh machine setup
├── README.md
│
├── docs/                     — setup guides, run in order (see "Start here")
│   ├── setup-local-llm.md    — llama.cpp, model, llama-server
│   ├── setup-zettelkasten.md — vault, agents, zk commands
│   └── setup-work-machine.md — employer-specific overrides (work MacBook only)
│
├── fish/                     ← stow package → ~/.config/fish/
│   └── .config/fish/
│       ├── config.fish       — XDG, homebrew, PATH, editor, pager, git, zoxide
│       ├── ENV_VARS.md       — documents every custom env variable
│       ├── completions/
│       │   ├── copilot.fish
│       │   └── docker.fish
│       ├── functions/
│       │   └── llm-gpu-persist.fish     — installs the GPU wired-limit LaunchDaemon
│       └── conf.d/
│           ├── 20-env-public.fish       — non-sensitive env vars
│           ├── 30-env-secrets.fish      — loader: reads .env.personal + .env.work
│           ├── 90-path-dedupe.fish      — deduplicates PATH, runs last
│           ├── aliases.fish             — abbreviations
│           ├── fish_frozen_theme.fish   — theme
│           ├── fnm.fish                 — Node version manager init
│           ├── fzf.fish                 — fuzzy finder + key bindings
│           ├── llm.fish                 — llm-up/-down/-status/-fast, llm-serve-persist
│           ├── llm-gpu.fish             — startup warning if the GPU limit isn't set
│           ├── prompt.fish              — starship init
│           ├── pyenv.fish               — Python version manager init
│           ├── zk.fish                  — zk, zk-status, zk-ingest, zk-lint
│           ├── .env.personal.example    — template → copy to .env.personal
│           └── .env.work.example        — template → copy to .env.work
│
├── llm/                      ← stow package → ~/.config/llm/
│   └── .config/llm/
│       ├── local.iogpu.wired-limit.plist  — LaunchDaemon: GPU wired limit (root)
│       └── local.llama-server.plist       — LaunchAgent: llama-server at login (user)
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
│   ├── .stow-local-ignore    — excludes runtime files opencode manages itself
│   │                           (node_modules, skills, tui.json, package*.json)
│   │                           and opencode.json, the untracked local-override slot
│   └── .config/opencode/
│       ├── opencode.jsonc    — model, small_model, provider, privacy wall, plugins
│       ├── dcp.jsonc         — DCP plugin config
│       ├── style.md          — terse-chat / normal-English instructions
│       ├── AGENTS.md         — agent usage guide
│       ├── agents/           — agent definitions, incl. the Zettelkasten pair:
│       │                       zettelkasten (Librarian), archivist
│       └── commands/         — slash commands, incl. /handoff
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
│   ├── mcp.json.example      — template → copy to mcp.json (gitignored: names an org)
│   └── settings.local.example — template for work-specific settings
│
├── zed/                      ← stow package → ~/.config/zed/
│   ├── .stow-local-ignore    — excludes themes/, prompts/
│   └── .config/zed/
│       └── settings.json     — editor, terminal (fish), agent model
│
└── zettelkasten/             ← NOT stowed — copied into the vault root
    └── AGENTS.md             — schema for ~/code/Zettelkasten
```

The vault is its own git repo, so its schema is copied rather than symlinked — a symlink would
make vault content depend on this repo being checked out. One vault per machine, at the same path
on each: the machine decides whether it holds work or personal content. See
[docs/setup-zettelkasten.md](docs/setup-zettelkasten.md).

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
git config user.email "your.personal@email.com"   # before the first commit — see Git identity
stow fish ghostty git llm opencode ssh starship zed
~/dotfiles/vscode/install.sh
```

Then work through the guides in [Start here](#start-here) — stowing puts the files in place, but
the model, the vault and the launch agents still need setting up.

---

## Stow commands

Run from `~/dotfiles`. The `.stowrc` sets `--target=$HOME` automatically.

```bash
stow fish           # symlink the fish package
stow -R fish        # restow (use after adding or moving files)
stow -D fish        # remove symlinks for one package
stow --simulate */  # dry run — shows what would happen
stow */             # stow all packages (vscode, zettelkasten excluded via .stow-local-ignore)
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

### Do this immediately after cloning

A fresh clone has **no** repo-local identity, so the global one — which on a work machine is the
work identity — applies until you override it. Any commit made in that window is authored with a
work name and address, and since author metadata is part of the commit, it cannot be edited out
later without rewriting history. This repo's first commit went in that way.

Check before the first commit, every time you clone:

```bash
cd ~/dotfiles && git config user.email    # must be the personal address
```

### A durable guard

Rather than remembering per repo, scope the work identity to work directories with a conditional
include, and make personal the default:

```ini
# ~/.config/git/config.local  (gitignored)
[user]
    name  = Your Name
    email = your.personal@email.com

[includeIf "gitdir:~/work/"]
    path = config.work
```

```ini
# ~/.config/git/config.work  (gitignored)
[user]
    email = your.work@email.com
```

Now the work address is only ever used inside `~/work/`, and anything outside it — this repo
included — defaults to personal. Failing safe beats remembering.

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

| Plugin                    | Type | Purpose                                       |
| ------------------------- | ---- | ---------------------------------------------- |
| `@tarquinen/opencode-dcp` | npm  | Dynamic context pruning — reduces token usage |

Pinned to an exact version in `opencode.jsonc` (bumped deliberately, recorded in a handoff)
rather than tracking `@latest`.

`instructions: ["style.md"]` in `opencode.jsonc` replaces the old `opencode-caveman` plugin —
terse chat replies, normal English for anything written to disk. The `./plugins/graphify.js`
local plugin referenced here previously was never actually committed to the repo; dropped.

Work-specific MCP servers (Jira, Confluence, Jenkins, etc.) are **not** in the tracked
`opencode.jsonc` — they were hardcoded to a different machine's local paths and have been
removed. Add them back per-machine via an untracked, gitignored `~/.config/opencode/opencode.json`
override (same pattern as `.env.work` below), which OpenCode merges on top at startup. See
[docs/setup-work-machine.md](docs/setup-work-machine.md) for the exact override format. Credentials still come from
`{env:JIRA_PAT}` etc., values from `.env.work`, never hardcoded.

See [docs/setup-zettelkasten.md](docs/setup-zettelkasten.md) for the Zettelkasten agent system
(`zettelkasten.md`/`archivist.md`, `/handoff`, and the `zk-status`/`zk-ingest`/`zk`/`zk-lint` fish
functions).

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
