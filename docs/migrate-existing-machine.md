# Migrate a machine set up under the old system

**For the work MacBook** — or any machine set up before this rework: two vaults, the
`zk-ingest-work` / `zk-ingest-personal` commands, a folded stow layout, an
`~/.config/opencode/opencode.json` override. A new machine doesn't need this; start at the README's
*Start here*.

Do the steps **in order**. Several of them exist because the obvious order loses something.

## What changed, briefly

| Before | Now | Why |
| --- | --- | --- |
| Two vaults on the work Mac (`Zettelkasten` personal, `Zettelkasten-work`) | One vault per machine at `~/code/Zettelkasten`; the machine decides what's in it | Leaving the job is handing back a laptop whose vault is work-only by construction |
| Work Librarian on Copilot, personal on local | One Librarian, local | Privacy by construction, no Copilot cost for wiki work |
| `zk-ingest-work`, `zk-ingest-personal`, `zk-lint-work`, `zk-sync` | `zk-ingest`, `zk-lint` (commit is automatic) | One vault, one command each |
| `facet:`, `refused:`, shared `tools/` folder | Gone. Tool caveats are ordinary notes | They only existed to route between two vaults |
| stow folded whole directories into the repo | `--no-folding`: directories are real, only tracked files are links | Keys, tokens and overrides were landing inside `~/dotfiles` |
| Work override in `~/.config/opencode/opencode.json` | `~/.config/opencode/work.jsonc` via `OPENCODE_CONFIG` | The old file's `instructions` were overwritten, so work rules never loaded |
| `instructions: ["style.md"]` | Style text merged into the global `AGENTS.md`; `style.md` deleted | A relative path never loaded, and OpenCode V2 loads no `instructions` entries at all |
| Work rules in the tracked `AGENTS.md` | Untracked `AGENTS.md` in the folder holding the work repos | This repo is public; V2 loads `AGENTS.md` files on the way up to `$HOME` |
| OpenCode V1 config keys (`provider`, `permission`, `plugin`, `small_model`) | Native V2 keys (`providers`, `permissions`, `plugins`, `agents.title`) | OpenCode V2; see the README's OpenCode section |
| `vscode/mcp.json` tracked | `mcp.json.example` tracked, real file ignored | It named the employer's package scope |
| No local LLM setup | `llm-*` functions, a LaunchAgent, `docs/setup-local-llm.md` | Every agent depends on `llama-server` |

---

## 0. Before you pull

While everything is still in its old place:

```bash
cd ~/dotfiles
git status                                   # commit or stash anything of yours first
cp vscode/mcp.json ~/mcp.json.keep 2>/dev/null   # the pull DELETES this tracked file
ls -d ~/code/Zettelkasten*                   # note which vaults exist — step 5 depends on it
pkill -f llama-server                        # if you run one some other way; the new setup starts its own
```

The `cp` matters: `vscode/mcp.json` was tracked and is now only an `.example`, so pulling removes
your real one from the working tree. (If you've already pulled, it's still in history. In fish:
`git show (git rev-list -n 1 HEAD -- vscode/mcp.json)^:vscode/mcp.json > ~/mcp.json.keep`.)

Also **quit Zed**. Step 2 moves its prompt library.

## 1. Pull

```bash
git pull
```

## 2. Convert the stow layout

```bash
./migrate-to-no-folding.sh           # read the list: your keys, .env.work, overrides, caches
./migrate-to-no-folding.sh --apply
exec fish
```

Run `--apply` **even if it says nothing is stranded**. It also links files the pull added
(`llm.fish`, the llama-server LaunchAgent, `zz-path-dedupe.fish`) and removes links a rename left
dangling. It simulates first and changes nothing if that would conflict, and it never overwrites a
file already in `$HOME`.

Then give Zed back its prompt library. It's a live database that was being written inside the
repo, and stow no longer links it:

```bash
cp -R ~/dotfiles/zed/.config/zed/prompts ~/.config/zed/prompts.new
rm -rf ~/.config/zed/prompts && mv ~/.config/zed/prompts.new ~/.config/zed/prompts
```

(The copy is taken from the repo first, so the `rm` only ever removes links or an empty
directory.) The database is still tracked in git; untracking it is a separate decision, because a
commit that deletes it would delete it on any machine that pulls it while still folded.

## 3. Retire the old helpers

Old notes mention `llm-up`, `llm-fast` and `__llm_serve` defined somewhere untracked. The repo now
defines `llm-up` and `llm-fast` itself, and a local definition sourced later would silently win:

```bash
grep -rln 'function llm-up\|function llm-fast\|function __llm_serve' ~/.config/fish
```

Anything listed other than `conf.d/llm.fish` — delete it, or rename the functions.

## 4. Work config

- **Override.** If step 2 moved an `opencode.json` override out of the repo, rename it; don't copy
  it:
  ```bash
  mv ~/.config/opencode/opencode.json ~/.config/opencode/work.jsonc
  ```
  Then delete its `instructions` key (V2 loads nothing from it) and convert the rest to the V2
  shape in [setup-work-machine.md §1](setup-work-machine.md#1-opencode-mcp-servers): `mcp.servers`,
  `permissions`, `agents`. If you never had one, create `work.jsonc` from that section.
- **Work rules.** The pull stripped them from the tracked `AGENTS.md`. Create an `AGENTS.md` in the
  folder that holds your work repos. The content and the folder choice are in
  [setup-work-machine.md §2](setup-work-machine.md#2-work-specific-agent-instructions).
- **Dangling link.** `style.md` was deleted from the repo, so its stow link now points at nothing.
  Remove it: `rm ~/.config/opencode/style.md` (or `stow -R` the `opencode` package).
- **VS Code MCP:** `cp ~/mcp.json.keep ~/dotfiles/vscode/mcp.json && ~/dotfiles/vscode/install.sh`
- **Git identity:** [setup-work-machine.md §4](setup-work-machine.md#4-work-git-identity). On this
  machine, work is the default and personal is scoped to `~/dotfiles/`.

Check it in a **new** fish shell:

```bash
exec fish
opencode debug config | grep -c jira-mcp            # non-zero
```

## 5. Consolidate the vaults

On this machine `~/code/Zettelkasten` was the **personal** vault, so the work vault can't simply be
poured into it. Personal content leaves this machine; the work vault takes over the path.

**If only `~/code/Zettelkasten-work` exists:**
```bash
mv ~/code/Zettelkasten-work ~/code/Zettelkasten
```

**If both exist:**

1. See what personal content there is:
   ```bash
   ls ~/code/Zettelkasten/raw ~/code/Zettelkasten/wiki/notes ~/code/Zettelkasten/tools 2>/dev/null
   ```
2. Copy personal handoffs and pages to the **desktop**. Dropping `raw/` files into the desktop
   vault's `raw/` re-ingests them there. They don't stay on the work Mac.
3. Swap. The work vault keeps its git history:
   ```bash
   mv ~/code/Zettelkasten ~/code/Zettelkasten-old-personal
   mv ~/code/Zettelkasten-work ~/code/Zettelkasten
   ```
4. Bring over the old `tools/` pages. Those were public-grade caveats by rule, so they're fine here.
   Don't overwrite a note of the same name: under the old schema, `notes/llama-cpp.md` and
   `tools/llama-cpp.md` could both exist.
   ```bash
   cd ~/code/Zettelkasten
   bash -c 'for f in ~/code/Zettelkasten-old-personal/tools/*.md; do
       [ -e "$f" ] || continue
       if [ -e "wiki/notes/$(basename "$f")" ]; then echo "merge by hand: $f"; else cp "$f" wiki/notes/; fi
   done'
   ```
   (Wrapped in `bash -c` because this loop is bash syntax, and your default shell is fish.)
   For each "merge by hand", paste that file's `## Version caveats` section into the note.

**Either way, then:**

```bash
cd ~/code/Zettelkasten
mkdir -p wiki/notes && [ -d wiki/tickets ] && mv wiki/tickets/*.md wiki/notes/ && rmdir wiki/tickets
cp ~/dotfiles/zettelkasten/AGENTS.md AGENTS.md            # the schema is a template; overwrite it
grep -rl '^refused:' raw/                                 # these re-ingest next time; that's intended
git config user.email                                     # check the identity before committing
git add -A && git commit -m "Consolidate to single-vault layout"
```

Old pages keep their old format (`created:`, `status:`, plain `sources/...` links). That's fine;
there's no need to rewrite them. New ingests use the new schema.

Then run `zk-lint` once. The ticket and tool pages you just moved aren't in `index.md` yet, and it
will list them.

Finally, once the personal content is safely on the desktop:
`rm -rf ~/code/Zettelkasten-old-personal`. Don't leave it lying around: the `external_directory`
privacy wall covers `~/code/Zettelkasten/**`, not this renamed copy.

## 6. Local LLM

Follow [setup-local-llm.md](setup-local-llm.md) from **step 2**. The GPU limit is probably already
set (`sysctl iogpu.wired_limit_mb` → `24576`); then steps 3 and 4.

## 7. Verify

```bash
fish -n ~/.config/fish/conf.d/llm.fish && fish -n ~/.config/fish/conf.d/zk.fish
llm-status                                   # up — qwen3.8-27b-local
zk-status
```

Then one real cycle: `/handoff` → `zk-ingest` → `zk`, as in
[setup-zettelkasten.md §4](setup-zettelkasten.md#4-dry-run).

**Commands that no longer exist:** `zk-ingest-work`, `zk-ingest-personal`, `zk-lint-work`,
`zk-sync`. Use `zk-ingest` and `zk-lint`. Committing happens inside `zk-ingest`.

---

**The personal desktop**, if it was set up under the old system: steps 0–3, then step 5 with the
roles reversed. Its `~/code/Zettelkasten` is personal and stays; it should never have had a work
vault. Skip step 4.
