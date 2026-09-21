# macOS setup guide — agent tooling, GPU limit, Zettelkasten vaults

Run this on the MacBook (work laptop), after pulling the dotfiles changes made in this session.
Everything here needs macOS tools (launchd, sysctl, opencode CLI, fish) that don't exist on the
machine the edits were made on, so none of it was run or verified for you. Go through it in order;
stop and check output at each numbered step before moving on.

```bash
cd ~/dotfiles   # or wherever this repo lives on the Mac
git pull
```

---

## 1. GPU LaunchDaemon (A1–A3)

Files already in the repo, unchanged from the brief:
- `llm/.config/llm/local.iogpu.wired-limit.plist` (just moved into the correct stow layout — was at the package root before, which would have symlinked to the wrong path)
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

Changed/added in this session:
- `opencode/.config/opencode/opencode.jsonc` — rewritten: adds `instructions: ["style.md"]`,
  `small_model`, the `llamacpp` provider (both Qwen models), the `external_directory` privacy
  wall, and pins DCP to `3.1.15`.
- `opencode/.config/opencode/style.md` — new, replaces the old caveman-style instructions (no
  `caveman.md` file existed in the repo to delete).
- `opencode/.config/opencode/agents/zettelkasten.md` — new, Work Librarian.
- `opencode/.config/opencode/agents/zettelkasten-personal.md` — new, Personal Librarian.
- `opencode/.config/opencode/agents/archivist.md` — overwritten with the new dual-vault version.
- `opencode/.config/opencode/agents/librarian.md`, `agents/wiki.md` — **deleted** (superseded by
  the two new Librarians; old single-vault design).
- `opencode/.config/opencode/commands/handoff.md` — rewritten: now facet-aware, routes to
  `Zettelkasten-work/raw/` vs `Zettelkasten/raw/`, and pinned to run on the local Qwen model
  regardless of what model the session itself used, so the write-up never hits Copilot billing.
  This makes the handoff's verbatim-accuracy instruction (copy errors/versions/flags exactly,
  never paraphrase) more load-bearing than usual — spot-check the first few real handoffs against
  their sessions to confirm the local model is holding that line.
- `fish/.config/fish/conf.d/zk.fish` — new: `zk`, `zk-ingest-work`, `zk-ingest-personal`,
  `zk-wall-test`.
- `zettelkasten.md` and `zettelkasten-personal.md` both gained a "keep the vault portable" rule:
  never write ticket keys, work tool/service names, company or colleague names, or
  `Zettelkasten-work` references into the personal vault (outside `tools/`) — see step 5.
- All three agent files (`zettelkasten.md`, `zettelkasten-personal.md`, `archivist.md`) gained
  ticket-rollup handling (`wiki/tickets/<KEY>.md`) — unrelated to the work/personal split, but
  touched in the same working tree.

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
loaded as-is either.

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
- pattern maps (glob-style keys) for `permission.external_directory` and `permission.task`
- `~` expansion inside those pattern keys (the config here relies on `~/code/Zettelkasten/**`
  resolving correctly)

If any of these aren't supported by your installed version:
- Upgrade OpenCode, **or**
- Adjust the patterns (e.g. expand `~` to the literal home path yourself in `opencode.jsonc`) and
  note the workaround in a handoff once the dry run (step 6) works.

If you did **not** set up the local `opencode.json` override in step 2 (no work MCP servers or
work-specific `AGENTS.md` instructions needed), check whether a stray one exists from before this
change and remove it so it can't shadow the new `opencode.jsonc`:

```bash
cat ~/.config/opencode/opencode.json 2>/dev/null   # inspect first — don't blindly delete
```

If step 2's override *is* what's there (your `mcp`/`instructions` block), leave it — that file is
supposed to exist now. Only delete it if it's leftover cruft unrelated to what step 2 asked for.

---

## 4. Migrate the vaults

Goal: two sibling vaults, separate git repos, no symlinks or nesting between them.

```bash
mkdir -p ~/code/Zettelkasten-work/raw ~/code/Zettelkasten-work/wiki
mkdir -p ~/code/Zettelkasten/tools   # raw/ and wiki/ should already exist if you have a vault today
```

1. **Move existing work content** out of the personal vault into the new work vault:
   ```bash
   # inspect first — figure out which raw/ and wiki/ files are actually work-facet before moving
   ls ~/code/Zettelkasten/raw
   ```
   Move files whose content/frontmatter is work-related into
   `~/code/Zettelkasten-work/raw/` and `~/code/Zettelkasten-work/wiki/`. Do this by hand or with
   `git mv`/`mv` per file — don't bulk-move without checking, since op has real content in it.

2. **Copy the wiki-root `AGENTS.md` schema** (the raw/wiki/tools structure and page-format rules —
   see the body of the old `wiki.md` agent for what that schema looked like) into
   `~/code/Zettelkasten-work/AGENTS.md`, adjusted to drop the `tools/` directory (work vault has no
   local `tools/`; it only writes into the personal vault's shared `tools/` per the new
   `zettelkasten.md` agent).

3. **Create `tools/`** in the personal vault if it doesn't exist yet:
   ```bash
   mkdir -p ~/code/Zettelkasten/tools
   ```

4. **Update schema paths** in each vault's `AGENTS.md` to reflect the new split (work vault has no
   `tools/`; personal vault's `AGENTS.md` should mention `tools/` alongside `raw/`/`wiki/`).

5. **Mark already-ingested raw files.** For every file in both vaults' `raw/` whose content is
   already reflected in `wiki/` (check `wiki/log.md`), add `ingested: YYYY-MM-DD` to its
   frontmatter (use the date it was actually ingested if you know it, otherwise today's date with
   a note).

6. **Confirm the vaults are properly separated:**
   ```bash
   # neither path should be inside the other
   realpath ~/code/Zettelkasten
   realpath ~/code/Zettelkasten-work
   # each should be its own git repo, not nested
   cd ~/code/Zettelkasten && git rev-parse --show-toplevel
   cd ~/code/Zettelkasten-work && git rev-parse --show-toplevel
   # confirm no symlinks between them
   find ~/code/Zettelkasten ~/code/Zettelkasten-work -type l
   ```

---

## 5. Fish wall test

The work/personal split here is about **organization, not a hard security boundary**: two vaults
so it's easy to navigate day to day, and so the work vault can be cleanly left behind (or deleted)
on your last day without touching or referencing your personal knowledge base. It is not defense
against a hostile or misbehaving model — that's a different, heavier problem (OS-level user
separation, sandboxing) that isn't needed here and isn't set up.

```bash
stow fish   # if not already done in step 1
```

Open a new shell, then:

```fish
zk-wall-test
```

This runs the Work Librarian (`zettelkasten.md`, Copilot model) **started correctly inside the work
vault**, and asks it to read `~/code/Zettelkasten/wiki/index.md` and grep
`~/code/Zettelkasten/raw` for `"the"` — both outside its cwd. This is mainly an accident-guard: it
catches ordinary misconfiguration or a relative-path typo sending a work session into your personal
notes, not deliberate circumvention.

**Both the read and the grep must be denied** by the `external_directory` permission wall in
`opencode.jsonc`. If either succeeds, check:
- OpenCode version doesn't support pattern-map `external_directory` (see step 3)
- `~` isn't expanding in the permission keys (see step 3 — you may need literal `/Users/<you>/...`
  paths instead of `~/...`)
- `zettelkasten.md`'s own `external_directory` override (`"~/code/Zettelkasten/tools/**": allow`)
  is too broad and accidentally matches more than `tools/`

The other side of "leaves cleanly" is content, not access: `zettelkasten-personal.md` and
`zettelkasten.md` both now carry an explicit rule to never write ticket keys, work tool/service
names, company or colleague names, or `Zettelkasten-work` references into the personal vault
(`tools/` excepted, which has its own public-grade rule). Spot-check this after a few real work
ingests — grep the personal vault's `wiki/` for anything that looks work-identifiable and correct
the agent's behavior if you find something:

```bash
grep -ril "ticket\|jira\|confluence" ~/code/Zettelkasten/wiki --include="*.md" | grep -v '/tools/'
```

---

## 6. Dry run

In a scratch OpenCode session (any facet — this just needs to produce some conversation to hand off):

```fish
opencode
# ... have a short conversation about anything ...
/handoff
```

Note the path it reports (`Written: <path>`). Open that file and review/amend it — check the
frontmatter (`facet`, `tickets`, `tools`, `tags`, `keywords`) and that no secrets/hostnames leaked
in verbatim error strings. Also check any error message or version string against what actually
appeared in the scratch session — `/handoff` runs on the local model now (for token cost), and a
paraphrased "close enough" error string defeats the grep-based search this wiki relies on.

Then ingest it:

```fish
# if facet: personal (or homelab/local-llm/dotfiles/other)
zk-ingest-personal

# if facet: work
zk-ingest-work
```

Check the Librarian's output: it should have written to `wiki/sources/`, updated `wiki/index.md`
and `wiki/log.md`, possibly touched `tools/<tool>.md`, and added `ingested: YYYY-MM-DD` to the raw
file's frontmatter.

Then ask a question about it:

```fish
zk "what did we do about <topic from the handoff>?"
```

Confirm the Archivist cites the page(s) the Librarian just created.

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
1. Pick a throwaway repo (not this dotfiles repo, not a vault).
2. Install Headroom there only.
3. Set `HEADROOM_BEACON=off` immediately — it phones home by default.
4. Measure actual token savings for your coding-agent workload (expect ~20%, not the 60–95%
   figures, which are for JSON/log-heavy workloads).
5. Check whether it helps or hurts local prefill speed — it can break llama.cpp's prompt cache,
   which would be a net loss on the local models.
6. It overlaps with DCP on conversation history — decide if it's additive or redundant once you
   have numbers.
7. Write up the trial as a handoff (`facet: local-llm` or `dotfiles`) either way, so the decision
   is recorded even if you don't adopt it.

---

## Notes on what this session could not verify

Made on a Windows machine with no `fish`, `opencode` CLI, or `launchd` installed — every command
above is written from the brief's spec but **none of it has been run**. Treat step numbers 1, 3, 5,
and 6 as the ones most likely to surface a real problem (version mismatches, pattern-matching
quirks, permission wall gaps) and go slowly through them.

Also: the brief mentions existing fish helpers `__llm_gpu_limit`, `__llm_serve`, `llm-up`,
`llm-fast` from an earlier session — none of these exist in the dotfiles repo. If you still use
them, they live somewhere not tracked here (or were never committed); check before assuming
`llm-gpu-persist` replaces them, since `llm-up`/`llm-fast` sound like they might start
`llama-server` itself, which is a different job.
