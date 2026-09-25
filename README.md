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

**Existing machine set up under the old two-vault system** (the work MacBook)? Do
[docs/migrate-existing-machine.md](docs/migrate-existing-machine.md) first. It's one ordered pass
covering the stow layout, the work override, the vault consolidation and the retired commands,
and it sends you into the guides above at the right point.

Everything employer-specific lives in gitignored override files, never in tracked config. Guide 3
lists exactly which values you supply and where each one goes.

---

## Structure

```
dotfiles/
├── .gitignore
├── .stow-local-ignore        — inert; real exclusions are per-package (see How stow works)
├── .stowrc                   — stow defaults: target=$HOME, --no-folding, verbose
├── migrate-to-no-folding.sh  — one-time fix for machines stowed before --no-folding
├── bootstrap.sh              — fresh machine setup
├── README.md
│
├── docs/                     — setup guides, run in order (see "Start here")
│   ├── setup-local-llm.md    — llama.cpp, model, llama-server
│   ├── setup-zettelkasten.md — vault, agents, zk commands
│   ├── setup-work-machine.md — employer-specific overrides (work MacBook only)
│   └── migrate-existing-machine.md — one-time move off the old two-vault system
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
│           ├── aliases.fish             — abbreviations
│           ├── fish_frozen_theme.fish   — theme
│           ├── fnm.fish                 — Node version manager init
│           ├── fzf.fish                 — fuzzy finder + key bindings
│           ├── llm.fish                 — llm-up/-down/-status/-fast, llm-serve-persist
│           ├── llm-gpu.fish             — startup warning if the GPU limit isn't set
│           ├── prompt.fish              — starship init
│           ├── pyenv.fish               — Python version manager init
│           ├── zk.fish                  — zk, zk-status, zk-ingest, zk-lint
│           ├── zz-path-dedupe.fish      — deduplicates PATH; zz- so it sources last
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
│   │                           (node_modules, skills, tui.json, cli.json, package*.json)
│   │                           and opencode.json (a pre-work.jsonc override name)
│   └── .config/opencode/
│       ├── opencode.jsonc    — V2 format: model, title agent, providers, privacy wall, plugins
│       ├── dcp.jsonc         — DCP plugin config
│       ├── AGENTS.md         — global instructions: terse-chat style, /handoff nudge, environment
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

### This repo uses `--no-folding`

`.stowrc` passes `--no-folding`, so stow links **individual files** and never whole directories.
`~/.config/fish`, `~/.config/opencode` and `~/.ssh` are real directories on your machine; only the
files this repo tracks are symlinks inside them.

That matters because apps write into their own config directories. Without `--no-folding`, stow
would make `~/.config/opencode` a symlink to the repo, so everything written there — SSH keys,
`fish_variables`, your `work.jsonc`, runtime caches — would physically land inside
`~/dotfiles`, one `git add -A` from being committed. With it, those stay on the machine.

(The explanation lives here because `.stowrc` can't hold comments — stow splits every line into
options, and a comment line becomes a string of unknown options that breaks every `stow` command.)

The one cost: **a file newly added to a package isn't linked until you restow it.** After a
`git pull` that adds files — a new agent, a new fish function — run `stow -R <package>`.

---

## Fresh machine setup

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/mikibakaiki/dotfiles/main/bootstrap.sh)
```

Or manually:

```bash
brew install stow fish opencode

# HTTPS, not the github-personal alias: that alias is defined in ssh/config, which only
# exists after this clone. Plain git@github.com: would use the WORK key (see ssh/config).
git clone https://github.com/mikibakaiki/dotfiles.git ~/dotfiles
cd ~/dotfiles
git config user.email "your.personal@email.com"   # before the first commit — see Git identity
stow fish ghostty git llm opencode ssh starship zed

# ssh/config is in place now, so switch to the personal key for future pushes
git remote set-url origin git@github-personal:mikibakaiki/dotfiles.git

~/dotfiles/vscode/install.sh
exec fish        # the conf.d/ functions (llm-*, zk-*) only load in a new fish shell
```

Then work through the guides in [Start here](#start-here) — stowing puts the files in place, but
the model, the vault and the launch agents still need setting up.

---

## Stow commands

Run from `~/dotfiles`. The `.stowrc` sets `--target=$HOME` automatically.

```bash
stow fish           # symlink the fish package
stow -R fish        # restow — REQUIRED after adding files (see --no-folding)
stow -D fish        # remove symlinks for one package
stow --simulate */  # dry run — shows what would happen
stow */             # stow all packages (docs, vscode, zettelkasten are no-ops — see below)
```

### Conflicts

A conflict means a **real file** already sits where stow wants to put a symlink — the usual case on
a machine that was configured before it was stowed. Stow refuses the whole package, changes
nothing, and exits 1:

```
WARNING! stowing opencode would cause conflicts:
  * existing target is neither a link nor a directory: .config/opencode/opencode.jsonc
All operations aborted.
```

Nothing is lost at that point. Pick one:

```bash
# 1. Keep the repo's version: move aside only the file stow named (safest)
mv ~/.config/opencode/opencode.jsonc ~/.config/opencode/opencode.jsonc.bak
stow opencode

# 2. Keep the MACHINE's version and pull it into the repo
git status                  # must be clean first — see below
stow --adopt sometool
git diff                    # this is the machine's file overwriting yours; keep or revert
```

Move the file stow names, not its directory. With `--no-folding` that directory also holds
machine-local files (`.env.work`, `work.jsonc`, `fish_variables`) that have nothing to do with the
conflict, and moving the directory would take them with it.

`--adopt` runs in the direction most people don't expect. Stow's own help calls it
*"(Use with care!) Import existing files into stow package from target"* — the target file wins and
**your tracked version is overwritten**. On a clean tree that's recoverable and `git diff` shows
exactly what changed; on a dirty tree you can't tell your edits from the machine's. Never run it
without checking `git status` first.

### Machines stowed before `--no-folding`

If this machine was set up before `.stowrc` gained `--no-folding`, its directories are still
folded — and files your apps wrote there (keys, `.env.work`, a work `opencode.json`) are sitting
*inside* `~/dotfiles`. Restowing alone would leave them stranded in the repo, where the apps no
longer look: your settings would silently disappear.

Run the migration once. It lists first and changes nothing:

```bash
cd ~/dotfiles
./migrate-to-no-folding.sh           # what would move, and where to
./migrate-to-no-folding.sh --apply   # move those files out to $HOME, then restow
```

It simulates the restow before touching anything and stops if that would conflict, and it never
overwrites a file that already exists in `$HOME` — it skips it and tells you to compare.
`bootstrap.sh` refuses to run on a folded machine until this has been done. It's step 2 of
[docs/migrate-existing-machine.md](docs/migrate-existing-machine.md), which covers the rest of
moving an old machine over.

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

# SSH key — generate fresh, never copy private keys between machines.
# ~/.ssh is a real directory (stow --no-folding), so the key stays on this machine.
chmod 700 ~/.ssh
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

Private keys never enter the repo. `~/.ssh` is a real directory (stow `--no-folding`), so keys
generated there stay on the machine, and `.gitignore` allowlists only `ssh/.ssh/config` in case one
ever lands in the package anyway.

---

## Git identity

The `git/` package puts everything under `~/.config/git/` (XDG-compliant).
`GIT_CONFIG_GLOBAL` is set in `config.fish` to ensure git always finds it.

No `[user]` block in the tracked config — identity is per-machine via `config.local`
(gitignored, like every `config.*` file here except the `.example` template):

```ini
# ~/.config/git/config.local
[user]
    name  = Your Name
    email = you@example.com
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

Rather than remembering per repo, make the right identity the default for the machine:

- **Personal machines:** `config.local` holds only your personal identity. There's no work
  identity on the machine to leak.
- **Work Mac:** work is the default, and personal is scoped to `~/dotfiles/` (and any other
  personal repo) with an `includeIf`. It's that way round because work repos there are many and
  scattered, while personal ones are few and in known places; a rule like "work only inside
  `~/work/`" misses repos and commits them under your personal address. The exact config is in
  [docs/setup-work-machine.md](docs/setup-work-machine.md#4-work-git-identity).

Either way, failing safe beats remembering.

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

The global `AGENTS.md` replaces the old `opencode-caveman` plugin: terse chat replies, normal
English for anything written to disk, and the `/handoff` capture nudge. That text used to live in a
separate `style.md` loaded through `instructions`, but OpenCode V2 accepts `instructions` and does
not currently load any of its entries, so it moved into `AGENTS.md`, the one instruction file V2 always loads.
The `./plugins/graphify.js` local plugin referenced here previously was never actually committed to
the repo; dropped.

The config is in OpenCode's native V2 format (`providers`, `permissions`, `plugins`, and
`agents.title`/`agents.summary` in place of `small_model`; agent frontmatter uses `permissions:` lists and
`request.body.temperature`). V2 still reads the V1 keys, but a nested entry has to stay entirely in
one format, so don't paste V1 snippets into an existing agent or provider. Web search is denied for
every agent by default. The pinned DCP plugin is a known failure on V2 (see
[docs/setup-zettelkasten.md](docs/setup-zettelkasten.md)).

Work-specific MCP servers (Jira, Confluence, Jenkins) and work rules are **not** in tracked config.
On the work Mac the MCP servers go in an untracked `~/.config/opencode/work.jsonc`, which
`config.fish` loads as an extra layer via `OPENCODE_CONFIG` whenever the file exists, and the work
rules go in an untracked `AGENTS.md` in the folder that holds the work repos. See
[docs/setup-work-machine.md](docs/setup-work-machine.md). Credentials still come from
`{env:JIRA_PAT}` etc., values from `.env.work`, never hardcoded.

See [docs/setup-zettelkasten.md](docs/setup-zettelkasten.md) for the Zettelkasten agent system
(`zettelkasten.md`/`archivist.md`, `/handoff`, and the `zk-status`/`zk-ingest`/`zk`/`zk-lint` fish
functions).

Runtime files (`node_modules/`, `skills/`, `tui.json`, `cli.json`) excluded via
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

# 2. Move in only the files you want tracked — not the whole directory. It also holds caches,
#    state and sometimes credentials, which belong on this machine.
mv ~/.config/TOOL/config.toml ~/dotfiles/TOOL/.config/TOOL/

# 3. Stow it (with --no-folding this links that one file back into the real directory)
cd ~/dotfiles && stow TOOL

# 4. Review, then add the file by name — `git add TOOL` would take everything in the package
git status --short TOOL
git add TOOL/.config/TOOL/config.toml
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
Fish sources `conf.d/` alphabetically, and digits sort before letters — so a `90-` prefix
does **not** run last. `zz-path-dedupe.fish` is named that way so it genuinely sources after
`fnm.fish` and `pyenv.fish`, both of which prepend to PATH.
