# macOS setup guide — agent tooling, GPU limit, the Zettelkasten vault

Run this on the machine that will hold the vault, after pulling the dotfiles changes. Everything
here needs macOS tools (launchd, sysctl, opencode CLI, fish) that don't exist on the machine the
edits were made on, so none of it was run or verified for you. Go through it in order; stop and
check output at each numbered step before moving on.

```bash
cd ~/dotfiles   # or wherever this repo lives on the Mac
git pull
```

---

## 1. GPU LaunchDaemon (A1–A3)

Files already in the repo:
- `llm/.config/llm/local.iogpu.wired-limit.plist`
- `fish/.config/fish/functions/llm-gpu-persist.fish`
- `fish/.config/fish/conf.d/llm-gpu.fish`

Stow them if not already:

```bash
stow llm fish
```

Install the daemon (asks for sudo — read `llm-gpu-persist.fish` first if you want to know exactly
what it does before running it):

```fish
llm-gpu-persist
```

Verify:

```bash
sysctl iogpu.wired_limit_mb
```

Expect `iogpu.wired_limit_mb: 24576`. Open a **new** shell and confirm the conf.d guard is silent
(no `⚠ GPU wired limit=...` warning). If the value doesn't stick after a reboot, check:

```bash
sudo launchctl print system/local.iogpu.wired-limit
```

---

## 2. OpenCode files

What each tracked file does:

- `opencode/.config/opencode/opencode.jsonc` — the main config: `instructions: ["style.md"]`,
  `small_model`, the `llamacpp` provider (both Qwen models), the `external_directory` privacy wall,
  and the DCP plugin pin.
- `opencode/.config/opencode/style.md` — terse chat replies, normal English for anything written to
  disk, and the `/handoff` capture nudge.
- `opencode/.config/opencode/agents/zettelkasten.md` — the Librarian. Ingests `raw/` into `wiki/`
  and runs lint passes. Local model, `bash` denied, `external_directory` denied.
- `opencode/.config/opencode/agents/archivist.md` — read-only Q&A over the wiki. Local model.
- `opencode/.config/opencode/commands/handoff.md` — writes a session handoff into the vault's
  `raw/`. Pinned to the local Qwen model regardless of what model the session itself used, so the
  write-up never hits Copilot billing. That makes its verbatim-accuracy instruction (copy errors,
  versions and flags exactly, never paraphrase) more load-bearing than usual — spot-check the first
  few real handoffs against their sessions to confirm the local model is holding that line.
- `fish/.config/fish/conf.d/zk.fish` — `zk`, `zk-status`, `zk-ingest`, `zk-lint`, plus the internal
  `zk-_pending`. All the local-model commands need `llama-server` up on `127.0.0.1:8080`; the
  header comment has the one-liner that checks it.
- `zettelkasten/AGENTS.md` — the vault schema template, copied into the vault root as `AGENTS.md`
  in section 4. Not stowed (excluded in `.stow-local-ignore`) — the vault is its own git repo and
  owns its copy.

Stow:

```bash
stow opencode fish
```

### Work MCP servers and AGENTS.md — local, untracked overrides

The old `opencode.jsonc` had Jira/Confluence/Jenkins MCP servers hardcoded to
`/Users/joao.campos/...` paths — clearly leftover from a different setup, not yours, and not part
of the brief. They were **removed** from the tracked file rather than guessed at. Likewise
`opencode/.config/opencode/AGENTS.md` still has stale Bitbucket/`bb`/NuGet/.NET content from that
same setup — left untouched in the tracked file (out of scope to edit blind), but you don't want it
loaded as-is either. (Only its `## Memory` section has been updated, to point at the vault rather
than a predecessor notes layout.)

OpenCode merges config from multiple places, later ones winning: global
`~/.config/opencode/opencode.jsonc` → a project-local `opencode.json`/`.jsonc` → `OPENCODE_CONFIG`
env var if set. `.gitignore` already reserves `**/opencode/opencode.json` (no `c`) and
`**/opencode/AGENTS.*.local.md` as untracked override slots that live right next to the tracked
files but never show up in `git status`. Use them instead of editing the tracked files:

**MCP servers** — create `~/.config/opencode/opencode.json`:

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

Fill in real paths/URLs for your actual MCP servers. `JIRA_PAT` etc. resolve from
`~/.config/fish/conf.d/.env.work` as usual — don't hardcode tokens into this file even though it's
gitignored.

**AGENTS.md instructions** — if you actually want work-specific standing instructions (Bitbucket
`bb` CLI conventions, ticket type rules, etc.), don't restore them into the tracked `AGENTS.md`.
Instead point `instructions` at a second untracked file via the same override:

```json
{
  "instructions": ["style.md", "AGENTS.work.local.md"]
}
```

(merge this into the same `opencode.json` as the `mcp` block above — one file, one JSON object)

then create `~/.config/opencode/AGENTS.work.local.md` with only the content you actually still
need. Don't just copy the old stale file over — it referenced a different person's machine paths
and may not even be your workflow (Bitbucket vs. GitHub, `bb` vs `gh`, etc.); write it fresh.

Verify the override is being picked up and still invisible to git:

```bash
cd ~/dotfiles && git status --short   # should show nothing for opencode.json / AGENTS.*.local.md
opencode run --agent zettelkasten "list your available mcp tools"   # or similar, to confirm merge
```

---

## 3. Verify your OpenCode version supports what the config needs

```bash
opencode --version
```

Check against the OpenCode changelog/docs for:
- `opencode.jsonc` (JSONC, not just `opencode.json`) support
- `--agent` flag on both `opencode` (interactive) and `opencode run`
- pattern maps (glob-style keys) for `permission.external_directory`
- `~` expansion inside those pattern keys (the config here relies on `~/code/Zettelkasten/**`
  resolving correctly)

If any of these aren't supported by your installed version:
- Upgrade OpenCode, **or**
- Adjust the patterns (e.g. expand `~` to the literal home path yourself in `opencode.jsonc`) and
  note the workaround in a handoff once the dry run (section 5) works.

If you did **not** set up the local `opencode.json` override in section 2, check whether a stray
one exists from before this change and remove it so it can't shadow the new `opencode.jsonc`:

```bash
cat ~/.config/opencode/opencode.json 2>/dev/null   # inspect first — don't blindly delete
```

If section 2's override *is* what's there (your `mcp`/`instructions` block), leave it — that file
is supposed to exist now. Only delete it if it's leftover cruft unrelated to what section 2 asked
for.

---

## 4. Set up the vault

**One vault per machine, always at `~/code/Zettelkasten`.** The machine decides what's in it: run
this guide on the work MacBook and the vault holds work content; run it on the personal desktop and
it holds personal content. Don't set one up on the Pi — it can't run the 27B, and a second personal
vault would silently diverge from the desktop's with no sync story.

That's the whole privacy model, and it's worth being clear about what it does and doesn't buy you:

- **It does** make leaving the job clean. The work machine's vault is work-only by construction, so
  there's nothing personal in it to rescue before you hand the laptop back.
- **It doesn't** survive a sync tool. If anything backs up or syncs `~/code` — Time Machine,
  corporate backup, iCloud, Dropbox — vault content goes wherever that tool sends it. "Local" is an
  assumption about this machine, not a mechanism. Check before you start.
- **It isn't** defence against a hostile or misbehaving model. That's a different, heavier problem
  (OS-level user separation, sandboxing) that isn't needed here and isn't set up.

The vault gets an `AGENTS.md` at its root defining its structure — the schema both the Librarian
and the Archivist are told to follow strictly. The template is tracked in this repo at
`zettelkasten/AGENTS.md`. It is **copied** into the vault root, not stowed: the vault is its own
git repo, and a symlink would make its schema a dotfiles dependency. (`zettelkasten/` is excluded
in `.stow-local-ignore` so a bare `stow` can't do this by accident.)

Read the template before running this — it's short, and it's the actual contract the agents work to.

1. **Create the directories:**
   ```bash
   mkdir -p ~/code/Zettelkasten/{raw,wiki/{sources,notes}}
   ```

2. **Install the schema into the vault root:**
   ```bash
   cp ~/dotfiles/zettelkasten/AGENTS.md ~/code/Zettelkasten/AGENTS.md
   ```
   If you later change the schema, edit the tracked template and re-copy — don't diverge the vault
   copy silently.

3. **Seed the two index files**, so the Librarian has something to append to rather than inventing
   structure on first run:
   ```bash
   printf '# Index\n\n## Sources\n\n## Notes\n' > ~/code/Zettelkasten/wiki/index.md
   printf '# Log\n' > ~/code/Zettelkasten/wiki/log.md
   ```

4. **If you already set up two vaults under the old design**, consolidate now. On the work MacBook
   the work vault's content is the one to keep:
   ```bash
   ls ~/code/Zettelkasten ~/code/Zettelkasten-work 2>/dev/null
   ```
   Move `raw/` and `wiki/` content from `~/code/Zettelkasten-work` into `~/code/Zettelkasten`, file
   by file — don't bulk-move. Ticket rollups move from `wiki/tickets/<KEY>.md` to
   `wiki/notes/<KEY>.md`, and any `tools/<tool>.md` pages become ordinary notes at
   `wiki/notes/<tool>.md`, keeping their `## Version caveats` section. Then remove the empty
   `~/code/Zettelkasten-work` and the now-unused `tools/` and `wiki/tickets/` directories.

5. **Check for stale `refused:` stamps**, which no longer exist as a concept:
   ```bash
   grep -rl '^refused:' ~/code/Zettelkasten/raw/ 2>/dev/null
   ```
   Anything listed becomes pending again and will be ingested on your next `zk-ingest`. That's the
   intended behaviour — just don't be surprised by it. If you'd rather it stay skipped, replace the
   stamp with `ingested: YYYY-MM-DD`.

6. **Initialise git**, if it isn't a repo already:
   ```bash
   cd ~/code/Zettelkasten && git init && git add -A && git commit -m "Initial vault structure"
   ```
   Its own repo, deliberately — so it can be deleted or left behind wholesale.

---

## 5. Dry run

In a scratch OpenCode session (this just needs to produce some conversation to hand off):

```fish
opencode
# ... have a short conversation about anything ...
/handoff
```

Note the path it reports (`Written: <path>`). Open that file and review/amend it — check the
frontmatter (`tickets`, `tools`, `tags`, `keywords`) and that no secrets or hostnames leaked into
verbatim error strings. Also check any error message or version string against what actually
appeared in the scratch session: `/handoff` runs on the local model, and a paraphrased "close
enough" error string defeats the grep-based search this wiki relies on. **Check the first three
handoffs this way, then stop** — you're confirming the model holds the line, not auditing forever.

Then ingest it:

```fish
zk-status    # what's pending
zk-ingest    # ingest it, then auto-commit
```

Check the Librarian's output: it should have written to `wiki/sources/`, updated `wiki/index.md`
and `wiki/log.md`, and added `ingested: YYYY-MM-DD` to the raw file's frontmatter.

Then ask a question about it:

```fish
zk "what did we do about <topic from the handoff>?"
```

Confirm the Archivist cites the page(s) the Librarian just created.

Two things to watch on this first run:

- `zk` passes the question positionally to interactive `opencode --agent archivist`, which is
  unverified against your OpenCode version. If that build doesn't accept a free-text question that
  way, you'll get an empty session with the question dropped. If so, change `zk` to use
  `opencode run --agent archivist "$argv"` — at the cost of losing the interactive follow-up, which
  is most of the point of the Archivist.
- Check the raw file's `ingested:` stamp landed. It's written last, after the log entry, so an
  ingest that dies partway leaves the file unstamped and the next run redoes it — the dedupe check
  on ticket timelines makes that safe. The one narrow window left is a run that dies between the
  log append and the stamp; `zk-lint` catches that as a file stamped `ingested:` with no matching
  `wiki/log.md` entry.

Finally, run a lint pass to confirm the health-check path works at all:

```fish
zk-lint
```

---

## 6. Recurring maintenance

Nothing in this system schedules itself. This is the one job it assumes you'll do — if it never
happens, the vault degrades quietly rather than breaking loudly.

| When | Do | Why |
| ---- | -- | --- |
| Monthly-ish | `zk-lint` | Finds orphan pages, contradictions, unprocessed `raw/` files, stamped-but-unlogged files from a died-late ingest, and caveats missing a "fixed in" status. This is the system's only self-healing mechanism. |

Committing isn't on this list: `zk-ingest` commits on success. Commit by hand only if you've edited
vault files directly.

---

## 7. Optional

### omo-slim (oh-my-opencode-slim)

Install it, then:
- Disable unused agents: Designer, Council, Observer.
- Disable unused bundled skills.
- Check how GitHub Copilot bills/counts each subagent call under omo-slim's orchestration — this
  matters since Copilot is billed per request.
- Note: no parallelism on local models — subagents that would run concurrently on Copilot will
  serialize against the single local `llama-server`.

### Headroom — trial only, not adopted

Don't wire it into the main config. If you want to measure it:
1. Pick a throwaway repo (not this dotfiles repo, not the vault).
2. Install Headroom there only.
3. Set `HEADROOM_BEACON=off` immediately — it phones home by default.
4. Measure actual token savings for your coding-agent workload (expect ~20%, not the 60–95%
   figures, which are for JSON/log-heavy workloads).
5. Check whether it helps or hurts local prefill speed — it can break llama.cpp's prompt cache,
   which would be a net loss on the local models.
6. It overlaps with DCP on conversation history — decide if it's additive or redundant once you
   have numbers.
7. Write it up as a handoff either way, so the decision is recorded even if you don't adopt it.

---

## Notes on what this session could not verify

Written on Linux with no `fish`, `opencode` CLI, or `launchd` — every command above comes from the
spec and **none of it has been run**. The fish file's structure, the frontmatter stamp detection
and the JSONC parse were checked statically; nothing else was. Treat sections 1, 3 and 5 as the
ones most likely to surface a real problem (version mismatches, pattern-matching quirks) and go
slowly through them.

Run `fish -n ~/.config/fish/conf.d/zk.fish` once after stowing — that's the real syntax check, and
it couldn't be run here.

Also: the brief mentions existing fish helpers `__llm_gpu_limit`, `__llm_serve`, `llm-up`,
`llm-fast` from an earlier session — none of these exist in the dotfiles repo. If you still use
them, they live somewhere not tracked here (or were never committed); check before assuming
`llm-gpu-persist` replaces them, since `llm-up`/`llm-fast` sound like they might start
`llama-server` itself, which is a different job.
