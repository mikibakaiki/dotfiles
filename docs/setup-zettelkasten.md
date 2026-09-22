# Setup: the Zettelkasten wiki

**Run this on every machine that should capture notes** — the work MacBook, the personal desktop.
Not the Pi.

**Prerequisite:** [setup-local-llm.md](setup-local-llm.md). Every agent here runs on
`llama-server`; if it isn't up, nothing on this page works. Check with `llm-status` before
starting.

Takes about 20 minutes including the dry run.

```bash
cd ~/dotfiles
git pull
```

Run the `zk-*` and `llm-*` commands below from a **fish** shell — they're fish functions, loaded
from `conf.d/` at shell start, so a shell opened before stowing won't have them.

---

## 1. OpenCode files

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
  in section 3. Not stowed (excluded in `.stow-local-ignore`) — the vault is its own git repo and
  owns its copy.

Stow:

```bash
stow opencode fish
exec fish          # picks up the newly stowed conf.d/ functions
```

## 2. Install OpenCode and verify its version

```bash
brew install opencode      # skip if bootstrap.sh already did
opencode --version
opencode auth login        # the top-level agent runs on Copilot; the zk agents are local
```

`opencode auth login` is easy to skip and hard to diagnose: without it the dry run in section 4
fails on its first message with an auth error, even though every Zettelkasten agent itself runs
locally.

Check against the OpenCode changelog/docs for:
- `opencode.jsonc` (JSONC, not just `opencode.json`) support
- `--agent` flag on both `opencode` (interactive) and `opencode run`
- pattern maps (glob-style keys) for `permission.external_directory`
- `~` expansion inside those pattern keys (the config here relies on `~/code/Zettelkasten/**`
  resolving correctly)

If any of these aren't supported by your installed version:
- Upgrade OpenCode, **or**
- Adjust the patterns (e.g. expand `~` to the literal home path yourself in `opencode.jsonc`) and
  note the workaround in a handoff once the dry run (section 4) works.

If you did **not** set up the local `opencode.json` override in setup-work-machine.md, check whether a stray
one exists from before this change and remove it so it can't shadow the new `opencode.jsonc`:

```bash
cat ~/.config/opencode/opencode.json 2>/dev/null   # inspect first — don't blindly delete
```

If that override *is* what's there (your `mcp`/`instructions` block), leave it — that file
is supposed to exist now. Only delete it if it's leftover cruft unrelated to that.

---

## 3. Set up the vault

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

6. **Initialise git**, if it isn't a repo already. Guard it, so re-running this guide on an
   existing vault doesn't commit work-in-progress under a misleading message:
   ```bash
   cd ~/code/Zettelkasten
   test -d .git || git init
   git config user.email    # must print something — see "Git identity" in the README
   git add -A && git commit -m "Vault structure"
   ```
   The identity check matters: a fresh machine has no repo-local identity, so this commit would be
   authored with whatever global identity is configured — on a work machine, the work address.
   Its own repo, deliberately — so it can be deleted or left behind wholesale.

---

## 4. Dry run

In a scratch OpenCode session (this just needs to produce some conversation to hand off):

```fish
opencode
# ... have a short conversation about anything ...
/handoff
```

Note the path it reports (`Written: <path>`). Open that file and review it. Two things to look at:

- **`keywords:`** should be literal strings you could paste into a terminal — error fragments,
  flags, config keys. If it reads `[docker, networking, timeout]`, the model gave you topic words,
  and a search six months from now will match nothing.
- **Error strings and versions** should match the session character-for-character. `/handoff` runs
  on the local model, and a paraphrased "close enough" error defeats the grep-based search this
  whole wiki relies on.

Note that only **credentials** should be redacted. Hostnames, paths and ticket keys belong in the
vault — it never leaves this machine — and redacting them out of an error string is what makes it
unsearchable.

**Check the first three handoffs that actually contain an error string**, then spot-check whenever
a session involved a multi-line error or a stack trace. A clean session proves nothing, and this
dry run in particular has no error strings in it at all — so it doesn't count as one of the three.

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

## 5. Recurring maintenance

Nothing in this system schedules itself. This is the one job it assumes you'll do — if it never
happens, the vault degrades quietly rather than breaking loudly.

| When | Do | Why |
| ---- | -- | --- |
| Monthly-ish | `zk-lint` | Finds orphan pages, contradictions, unprocessed `raw/` files, stamped-but-unlogged files from a died-late ingest, and caveats missing a "fixed in" status. This is the system's only self-healing mechanism. |

Committing isn't on this list: `zk-ingest` commits on success. Commit by hand only if you've edited
vault files directly.

---

## 6. Optional

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
spec and **none of it has been run**. What *was* checked statically: the fish file's structure, the
frontmatter stamp detection (against a body line starting `ingested:`, a file with no frontmatter,
and a legacy `refused:` stamp), and that `opencode.jsonc` parses with its permission map intact.
Nothing else. Treat sections 2 and 4 as the ones most likely to surface a real problem — version
mismatches and pattern-matching quirks — and go slowly through them.

Run this once after stowing; it's the real syntax check and it couldn't be done from here:

```bash
fish -n ~/.config/fish/conf.d/zk.fish
```

---

**Next, only on the work MacBook:** [setup-work-machine.md](setup-work-machine.md)
