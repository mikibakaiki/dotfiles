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
| Jira MCP server path | `~/.local/share/mcp/jira-mcp/.../server.js` | `~/.config/opencode/opencode.json` |
| Confluence MCP server path | same shape | same |
| Jenkins MCP URL | `https://<jenkins-host>/mcp-server/mcp` | same |
| Private npm scope | `@<org>/jira-mcp` | `vscode/mcp.json` |
| Bitbucket / SCM host | `<host>/projects/<KEY>/repos/<SLUG>` | `~/.config/opencode/AGENTS.work.local.md` |
| Jira ticket types | e.g. `PCA story` / `PCA Bug` | same |
| Work git identity | `you@employer.example` | `~/.config/git/config.work` |

---

## 1. OpenCode MCP servers

OpenCode merges config from several places, later winning: global
`~/.config/opencode/opencode.jsonc` → a project-local `opencode.json`/`.jsonc` → `OPENCODE_CONFIG`
if set. Because stow runs with `--no-folding`, `~/.config/opencode` is a real directory on this machine,
so files you create there stay here and never enter the repo. `.gitignore` also lists
`**/opencode/opencode.json` (no `c`) and `**/opencode/AGENTS.*.local.md`, as a safety net for a
machine still on the old folded layout (see *Machines stowed before `--no-folding`* in the README).

Create `~/.config/opencode/opencode.json`:

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

Then point `instructions` at it — merge into the **same** `opencode.json` as the `mcp` block above,
one file, one JSON object:

```json
{ "instructions": ["style.md", "AGENTS.work.local.md"] }
```

Verify it merged, and that git still can't see it:

```bash
cd ~/dotfiles && git status --short    # nothing for opencode.json / AGENTS.*.local.md
opencode run --agent zettelkasten "list your available mcp tools"
```

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

The failure this prevents: a fresh clone has no repo-local identity, so the global one applies —
and on a work machine that's the work address. Author metadata is part of the commit, so it can't
be edited out afterwards without rewriting history.

Scope the work identity to work directories, and let personal be the default:

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

Check before your first commit in any clone:

```bash
cd ~/dotfiles && git config user.email    # must be the personal address
```

---

## A note on the vault

Nothing special to do here — but worth knowing why. On this machine the vault holds work content
by construction, because the machine *is* the boundary. That means ticket keys, internal hostnames
and client names are all fine in `~/code/Zettelkasten` here, and leaving the job is deleting a
directory on a laptop you hand back. Don't set up a personal vault alongside it; that's what the
desktop is for.
