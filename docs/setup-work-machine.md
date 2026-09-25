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
| Folder that holds your work repos | e.g. `~/code/work/` | where the work `AGENTS.md` goes (§2) |
| Bitbucket / SCM host | `<host>/projects/<KEY>/repos/<SLUG>` | `<work repos folder>/AGENTS.md` |
| Jira ticket types | e.g. `PCA story` / `PCA Bug` | same |
| Work git identity | `you@employer.example` | `~/.config/git/config.local` |
| Where your *personal* repos live | `~/dotfiles/` | `~/.config/git/config.local` |

---

## 1. OpenCode MCP servers

The work settings live in one untracked file, `~/.config/opencode/work.jsonc`, loaded as an extra
config layer through `OPENCODE_CONFIG`. `config.fish` sets that variable automatically whenever the
file exists, so creating the file is all it takes, and a machine without one is unaffected.

Why this file and not `~/.config/opencode/opencode.json`, which older notes suggested: verified
against OpenCode V1's source, it loads `config.json` → `opencode.json` → `opencode.jsonc` from that
directory with a plain deep merge, where later files win and **arrays are replaced**. The tracked
`opencode.jsonc` loads last, so a same-named array in the override (it was `instructions` then; now
it would be `permissions`) loses to the tracked one, silently. `OPENCODE_CONFIG` is a separate layer
that loads *after* those files.

That reasoning was checked against V1. The V2 docs don't mention `OPENCODE_CONFIG` at all, so treat
it as unverified until the check at the end of this section passes. If it fails, V2's documented
fallback is a project config: V2 merges every `opencode.jsonc` from the directory you start in up to
the filesystem root, so the same content saved as `~/code/work/opencode.jsonc` (next to the work
`AGENTS.md` from §2) applies to every work repo.

Because stow runs with `--no-folding`, `~/.config/opencode` is a real directory on this machine and
`work.jsonc` never enters the repo. `.gitignore` lists it anyway, as a safety net.

Create `~/.config/opencode/work.jsonc`:

This is OpenCode V2's native format, matching the tracked `opencode.jsonc`. (V1 had the servers
directly under `mcp`, a `tools` on/off map, and a singular `agent` key. V2 still reads those, but
don't mix the two formats inside one agent entry.)

```jsonc
{
  "mcp": {
    "servers": {
      "jira-mcp": {
        "type": "local",
        "command": ["node", "/absolute/path/to/jira-mcp/build/server.js"],
        "environment": { "JIRA_PAT": "{env:JIRA_PAT}" },
        "codemode": false
      },
      "confluence-mcp": {
        "type": "local",
        "command": ["node", "/absolute/path/to/confluence-mcp/build/server.js"],
        "environment": { "CONFLUENCE_PAT": "{env:CONFLUENCE_PAT}" },
        "codemode": false
      },
      "jenkins": {
        "type": "remote",
        "url": "https://your-jenkins/mcp-server/mcp",
        "headers": { "Authorization": "Basic {env:JENKINS_TOKEN}" },
        "codemode": false
      }
    }
  },
  // Off for every agent by default. The last matching rule wins, so the per-agent allows below
  // override this.
  "permissions": [
    { "action": "jira-mcp_*", "resource": "*", "effect": "deny" },
    { "action": "confluence-mcp_*", "resource": "*", "effect": "deny" },
    { "action": "jenkins_*", "resource": "*", "effect": "deny" }
  ],
  "agents": {
    "requirements-clarifier": {
      "permissions": [
        { "action": "jira-mcp_*", "resource": "*", "effect": "allow" },
        { "action": "confluence-mcp_*", "resource": "*", "effect": "allow" },
        { "action": "jenkins_*", "resource": "*", "effect": "allow" }
      ]
    },
    "explore": {
      "permissions": [
        { "action": "jira-mcp_*", "resource": "*", "effect": "allow" },
        { "action": "confluence-mcp_*", "resource": "*", "effect": "allow" },
        { "action": "jenkins_*", "resource": "*", "effect": "allow" }
      ]
    }
  }
}
```

> **Keep the server keyed `jira-mcp`, and keep `"codemode": false`.** MCP tool names are
> `<server-key>_<tool>`, and `requirements-clarifier.md` and `tech-lead.md` reference
> `jira-mcp_jira_get_issue` / `jira-mcp_*`. Rename the key and those agents silently lose their
> Jira tools. V2 also defaults every server to Code Mode, which groups its tools behind one
> `execute` tool instead of exposing them under those names; `codemode: false` keeps the direct
> tools the agents ask for.
>
> Two things the V2 docs leave open, so check them here rather than assume: whether a `-` in a
> server key survives V2's tool-name normalization (if `opencode debug config` or the tool list
> shows `jira_mcp_…`, rename the rules and the agent references to match), and whether the
> built-in `explore` agent's own read-only policy still overrides these allows.

Tokens resolve from `~/.config/fish/conf.d/.env.work` via `{env:...}`. Don't hardcode them here
even though the file is gitignored.

---

## 2. Work-specific agent instructions

The tracked `opencode/.config/opencode/AGENTS.md` holds only generic content — style, shell, OS,
and the wiki pointer. Anything tied to an employer goes in an untracked file.

OpenCode V2 no longer loads files listed in `instructions` (it accepts the field and ignores its
entries), so the old `AGENTS.work.local.md` + `instructions` route is dead. What V2 does load is
every `AGENTS.md` from the directory you start it in up to `$HOME`. So put the work rules in an
`AGENTS.md` in the folder that holds your work repos, and every session in any of them picks it up.

Use a folder that holds **only** work repos, e.g. `~/code/work/`. Not `~/code/` itself: that would
also load these rules into the vault at `~/code/Zettelkasten`, and into anything else there.

Create `~/code/work/AGENTS.md` (adjust the folder):

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

Don't add an `instructions` key for it: V2 would accept it and load nothing. And don't put this
file under `~/dotfiles`; it lives with the work repos, outside this repo.

If you have an `~/.config/opencode/AGENTS.work.local.md` from the V1 setup, move its content here
and delete it, along with the `instructions` key in `work.jsonc` that pointed at it.

Verify, in a **new** fish shell so `OPENCODE_CONFIG` is set:

```bash
echo $OPENCODE_CONFIG                              # → ~/.config/opencode/work.jsonc, expanded
opencode debug config | grep -c jira-mcp           # non-zero: the MCP servers merged in
cd ~/dotfiles && git status --short                # nothing for work.jsonc
```

Then start `opencode` inside one work repo and ask "which default branch do we target?" — it should
answer `master` from the work `AGENTS.md`. Start it in `~/dotfiles` and ask again; it shouldn't know.

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
