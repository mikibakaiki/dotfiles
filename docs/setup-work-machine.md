# Setup: work machine extras

**Only on the work MacBook.** Skip this entirely on a personal machine — nothing here is needed for
the wiki or the local models to work.

Everything on this page goes into **untracked, gitignored** files. This repo is public-adjacent and
nothing tracked in it should name an employer, an internal hostname, or a real person. These are
the slots where that content lives.

**Prerequisites:** [setup-local-llm.md](setup-local-llm.md) and
[setup-zettelkasten.md](setup-zettelkasten.md) done.

---

## What you need to supply

Gather these before you start — they're the only employer-specific values involved:

| Value | Example shape | Goes in |
| --- | --- | --- |
| Jira MCP server path | `~/.local/share/mcp/jira-mcp/.../server.js` | `~/.config/opencode/work.jsonc` |
| Confluence MCP server path | same shape | same |
| Jenkins MCP URL | `https://<jenkins-host>/mcp-server/mcp` | same |
| Private npm scope | `@<org>/jira-mcp` | `vscode/mcp.json` |
| Bitbucket / SCM host | `<host>/projects/<KEY>/repos/<SLUG>` | `~/.config/opencode/AGENTS.work.local.md` |
| Jira ticket types | e.g. `PCA story` / `PCA Bug` | same |
| Work git identity | `you@employer.example` | `~/.config/git/config.local` |
| Where your *personal* repos live | `~/dotfiles/` | `~/.config/git/config.local` |

---

## 1. OpenCode MCP servers

The work settings live in one untracked file, `~/.config/opencode/work.jsonc`, loaded as an extra
config layer through `OPENCODE_CONFIG`. `config.fish` sets that variable automatically whenever the
file exists, so creating the file is all it takes, and a machine without one is unaffected.

Why this file and not `~/.config/opencode/opencode.json`, which older notes suggested: verified
against OpenCode's source, it loads `config.json` → `opencode.json` → `opencode.jsonc` from that
directory with a plain deep merge, where later files win and **arrays are replaced**. The tracked
`opencode.jsonc` loads last, so its `instructions` would overwrite yours and your work rules would
never load, silently. `OPENCODE_CONFIG` is a separate layer that loads *after* those files and
merges arrays by concatenating them, so your entries add to the tracked ones instead of losing to
them.

Because stow runs with `--no-folding`, `~/.config/opencode` is a real directory on this machine and
`work.jsonc` never enters the repo. `.gitignore` lists it anyway, as a safety net.

Create `~/.config/opencode/work.jsonc`:

```json
{
  "mcp": {
    "jira-mcp": {
      "type": "local",
      "command": ["node", "/absolute/path/to/jira-mcp/build/server.js"],
      "environment": { "JIRA_PAT": "{env:JIRA_PAT}" }
    },
    "confluence-mcp": {
      "type": "local",
      "command": ["node", "/absolute/path/to/confluence-mcp/build/server.js"],
      "environment": { "CONFLUENCE_PAT": "{env:CONFLUENCE_PAT}" }
    },
    "jenkins": {
      "type": "remote",
      "url": "https://your-jenkins/mcp-server/mcp",
      "headers": { "Authorization": "Basic {env:JENKINS_TOKEN}" }
    }
  },
  "tools": {
    "jira-mcp*": false,
    "confluence-mcp*": false,
    "jenkins*": false
  },
  "agent": {
    "requirements-clarifier": {
      "tools": { "jira-mcp*": true, "confluence-mcp*": true, "jenkins*": true }
    },
    "explore": {
      "tools": { "jira-mcp*": true, "confluence-mcp*": true, "jenkins*": true }
    }
  }
}
```

> **Keep the server keyed `jira-mcp`.** MCP tool names are `<server-key>_<tool>`, and
> `requirements-clarifier.md` and `tech-lead.md` reference `jira-mcp_jira_get_issue` /
> `jira-mcp_*`. Rename the key and those agents silently lose their Jira tools — the calls just
> never resolve.

Tokens resolve from `~/.config/fish/conf.d/.env.work` via `{env:...}`. Don't hardcode them here
even though the file is gitignored.

---

## 2. Work-specific agent instructions

The tracked `opencode/.config/opencode/AGENTS.md` holds only generic content — style, shell, OS,
and the wiki pointer. Anything tied to an employer goes in an untracked override.

Create `~/.config/opencode/AGENTS.work.local.md`:

```markdown
## Runtime
- **Runtime**: .NET 8 (`net8.0`)

## NuGet packages
- Verify package compatibility with net8.0 before recommending or accepting upgrades.
- Check the package ships `lib/net8.0/` or a compatible TFM — don't assume netstandard2.0
  fallback is safe.

## Git & Source Control
- **SCM**: Bitbucket (not GitHub). Use `bb`, never `gh`.
- "open PR" means `bb pr create`.
- `bb pr create <PROJECT_KEY> <REPO_SLUG> --title "..." --from-branch "..." --to-branch "..."`
- Project key and repo slug are inferred from the git remote URL.
- Default target branch: `master`

## Jira
- Ticket issue type is always **PCA story** or **PCA Bug**, never generic Story/Bug.
```

Then add this key to the **same** `work.jsonc`, next to `mcp` (one file, one JSON object):

```json
"instructions": ["~/.config/opencode/AGENTS.work.local.md"]
```

Two details that matter. Use the `~/` path: OpenCode resolves a relative `instructions` entry against
the *project you're working in*, not the config directory, so a bare filename loads nothing. And
don't repeat `style.md`: this layer's array is added to the tracked one rather than replacing it.

Verify, in a **new** fish shell so `OPENCODE_CONFIG` is set:

```bash
echo $OPENCODE_CONFIG                              # → ~/.config/opencode/work.jsonc, expanded
opencode debug config | grep -A3 '"instructions"'  # both style.md and AGENTS.work.local.md
opencode debug config | grep -c jira-mcp           # non-zero: the MCP servers merged in
cd ~/dotfiles && git status --short                # nothing for work.jsonc or AGENTS.*.local.md
```

(Don't verify by asking the Zettelkasten agent to list its MCP tools. The config above deliberately
disables them for every agent except `requirements-clarifier` and `explore`, so it would honestly
report none even when everything works.)

---

## 3. VS Code MCP servers

`vscode/mcp.json` is gitignored — its package scope names the employer. Copy the template and fill
in your org:

```bash
cd ~/dotfiles
cp vscode/mcp.json.example vscode/mcp.json
$EDITOR vscode/mcp.json          # replace @your-org with the real scope
./vscode/install.sh              # links it into place
```

`install.sh` links `mcp.json` only if it exists, so it's safe to run on a personal machine too —
it just skips that step.

---

## 4. Work git identity

The failure this prevents: a fresh clone has no repo-local identity, so the global one applies.
Author metadata is part of the commit, so a wrong address can't be removed afterwards without
rewriting history. This repo's first commit was authored with a work address exactly that way.

**On the work Mac, make work the default and scope *personal* to where your personal repos live.**
That's the opposite of the personal desktop, and deliberately so. Work repos here are many and live
wherever a project puts them (`~/code/`, worktrees, clones of clones), so a rule like "work only
inside `~/work/`" misses some and they'd commit as you personally. Your personal repos on this
machine are few and in known places, starting with this one.

```ini
# ~/.config/git/config.local  (gitignored)
[user]
    name  = Your Name
    email = you@employer.example

[includeIf "gitdir:~/dotfiles/"]
    path = config.personal
```

```ini
# ~/.config/git/config.personal  (gitignored)
[user]
    email = your.personal@email.com
```

Add one `includeIf` per personal repo location. The trailing `/` matters: `gitdir:~/dotfiles/`
matches that repo and everything under it.

Check both sides:

```bash
cd ~/dotfiles && git config user.email                  # personal
cd <any work repo> && git config user.email             # work
```

---

## A note on the vault

Nothing special to do here — but worth knowing why. On this machine the vault holds work content
by construction, because the machine *is* the boundary. That means ticket keys, internal hostnames
and client names are all fine in `~/code/Zettelkasten` here, and leaving the job is deleting a
directory on a laptop you hand back. Don't set up a personal vault alongside it; that's what the
desktop is for.
