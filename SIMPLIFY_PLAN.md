# Plan: one vault per machine, one Librarian, everything local

**Self-contained.** Everything needed to execute this is in this file. You should not need the
conversation that produced it, or the git history.

**Branch:** work on `claude/simplify-plan-review-vly1cn`. PR #2 (`zettelkasten-dual-vault`) is
already **merged** into `main` as of `e34db18` — the dual-vault system this plan collapses is the
current state of `main`, not an open proposal. Do not try to reuse that branch or that PR.

---

## Why

The system works, but it is about three times the size it needs to be: ~1,078 lines across agent
prompts, schema files, fish functions and the setup guide. Two Librarian agents are ~95% identical
prose and have already drifted from each other for no reason.

It grew that way because each review round found a plausible failure in a vault with roughly zero
pages, and answered it with a rule instead of a deletion. Most of those rules defend a boundary
that a simpler arrangement gives away for free.

### The premise, stated correctly

An earlier draft of this plan claimed "device separation already gives the work/personal split,"
which contradicted the setup guide (it creates *both* vaults on the work MacBook, and section 5
exists precisely to test a same-machine wall). That contradiction is now resolved in favour of
device separation, as an explicit decision about how the machines are used:

- **Work MacBook** → `~/code/Zettelkasten` holds work content.
- **Personal desktop** → `~/code/Zettelkasten` holds personal content.
- **Raspberry Pi** → not a capture device. No vault, no `/handoff`, no Librarian. (It cannot run
  the 27B model anyway, and a second personal vault would silently diverge from the desktop's.)

Same path everywhere, so nothing in the config is machine-aware. **The machine is the facet.** That
is the entire privacy model, and it is stronger than what it replaces:

- **Leaving the job is `rm -rf` on a laptop you hand back.** The work vault is 100% work content by
  construction — there is nothing personal in it to rescue first. The old two-vault design promised
  this via a "portability rule"; the machine split delivers it without a rule.
- **`facet:` carries no information** once the machine decides the content, so it goes entirely —
  schema, `/handoff`, and frontmatter carry-through. One fewer field for a 27B to guess wrong.
- **No routing decision exists**, so no refusal logic is needed to catch a bad routing decision.

### What this does not protect against

State it plainly rather than implying more than is true:

- A local backup or sync tool covering `~/code` (Time Machine, corporate backup, iCloud, Dropbox)
  sends vault content wherever that tool sends things. This is a setup-guide warning, not a
  mechanism.
- A misbehaving or hostile model. It never did. OS-level sandboxing is the answer to that and is
  not set up.

### What goes

Eight defensive mechanisms exist only because there were two vaults and a cloud model in the loop.
All of them go: the cross-vault `tools/` folder and its public-grade denylist, the plain-path link
convention, the `external_directory` allow-hole for the work vault, the no-concurrent-ingest
constraint, the re-read-before-append protocol, the `refused:` stamp and its refusal triggers, the
portability rule, and the privacy-wall check.

**The blanket `external_directory` deny on the vault stays.** It is one line, it costs nothing
operationally (the `zk` commands run from *inside* the vault, where it is not an external
directory), and the top-level opencode agent is still Copilot-backed — so it is the only thing
stopping a cloud session in a work repo from reading vault content directly. Downgrading it to
`ask` was an unrelated loosening bundled into an earlier draft; it is not part of this plan.

---

## Target state

```
~/code/Zettelkasten/          one git repo, one Obsidian vault, one per capture-capable machine
  AGENTS.md                   the schema (~65 lines), copied from zettelkasten/AGENTS.md
  raw/                        handoffs, immutable except for the `ingested:` stamp
  wiki/
    index.md                  the catalog — everything is linked from here
    log.md                    append-only ingest log
    sources/                  one page per ingested handoff
    notes/                    everything else, flat: concepts, tools, services, projects,
                              tickets, people, areas
```

- **Agents: 2.** `zettelkasten` (Librarian, local) and `archivist` (local, read-only).
- **Commands: 1.** `/handoff`, local.
- **Fish functions: 5** — four you type (`zk`, `zk-status`, `zk-ingest`, `zk-lint`) plus one
  internal helper (`zk-_pending`). See section 4 for why the helper stays a function.
- **Stamps: 1.** `ingested:`.
- **Frontmatter fields a human ever thinks about: 0.** `/handoff` writes them; nothing asks you.
- **Concepts the human holds: 3.** capture, file, ask.

Expected result: ~1,078 → ~460 lines. No new components — this plan only deletes, merges and
corrects.

---

## Decisions already made (don't relitigate)

| Decision | Rationale |
|---|---|
| One vault per machine, same path everywhere | The machine is the facet. Gives work/personal separation and clean job-exit structurally, with no rule to enforce and no config to make machine-aware. |
| Pi is not a capture device | It cannot run the 27B, and a second personal vault would diverge from the desktop's with no sync story. |
| All models local | Satisfies the privacy goal by construction; zero Copilot cost for wiki ops. |
| `facet:` deleted entirely | Machine identity determines content, so the field is always the same value within a vault and nothing reads it. Deleting it removes a guess `/handoff` was making and could get wrong. |
| Blanket `external_directory` deny on the vault **stays** | One line, no operational cost, and the top-level agent is still cloud-backed. Not entailed by the vault merge. |
| `refused:` stamp and refusal triggers go | They existed to catch a bad facet-routing guess. With no routing decision, there is nothing to refuse. |
| `tools/` folds into `wiki/notes/` | Its only reason to be separate was cross-vault sharing between two Librarians. A tool page is now `wiki/notes/llama-cpp.md` with a `## Version caveats` section. |
| Ticket rollups stay **eager**, simplified | Moves work from the weak-link operation (multi-file synthesis at query time, hard for a 27B) to the easy one (append one line at write time). Now `wiki/notes/<KEY>.md` like any other note — no separate directory, no `status:` field, no dedicated index section. |
| `zk-lint` survives | It is the only thing that would catch a silent capture failure — the failure mode that actually killed the first attempt. It shrinks a lot, since most of its checks lost their subject. |
| `log.md` survives | `git log` was proposed as a replacement, but commit messages don't attribute pages to source handoffs. Keep it. |
| `zk-_pending` stays a function | An earlier draft said "inline it" while shipping code that didn't, claiming 4 functions for a 5-function file. Inlining would duplicate the frontmatter-parsing `sed` in two callers — worse to maintain, and that `sed` is a known-subtle bug fix. It stays one function, and the count is stated honestly. |

**Noted for later, not now:** if after a few months most `wiki/notes/<TICKET>.md` pages have exactly
one timeline line, drop eager rollups and let the Archivist assemble from `tickets:` frontmatter on
demand. Cheap, evidence-based reversal. (This applies to ticket rollups only. The vault arrangement
is a separate, deliberately structural choice — see **Why** — not something to revisit on a whim.)

---

## Changes, file by file

Thirteen files. Sections 8, 11 and 12 cover files an earlier draft either never named or wrongly
marked "no change"; they are where its own verification step was guaranteed to fail.

### 1. `zettelkasten/AGENTS.md` — new, replaces both schema files

Delete `zettelkasten/AGENTS.personal.md` (156 lines) and `zettelkasten/AGENTS.work.md` (148 lines).
Write one `zettelkasten/AGENTS.md`, ~115 lines, containing exactly:

- A one-line statement that this is the schema, that the Librarian and Archivist follow it
  strictly, and that it is copied to the vault root as `AGENTS.md`.
- The directory layout from **Target state** above.
- The "why flat" rationale, trimmed to ~3 lines. It is correct and hard-won — keep the
  search-not-browse point and keep *"don't pre-plan the split; split when flatness actually
  hurts."*
- **Page frontmatter — this exact field set**, which must match section 2's ingest step:
  ```markdown
  ---
  tags: [lowercase, hyphenated]
  sources: [raw-filename-without-extension]
  tools: [llama.cpp b6xxx]      # optional, carried from the raw file
  keywords: [...]               # optional, carried from the raw file
  updated: YYYY-MM-DD
  ---
  ```
  No `created:` (git has it). No `facet:` (deleted everywhere). No `status:`.
- Page rules: `[[wikilinks]]` for every cross-reference; a page with no inbound link is a bug, link
  it from `index.md` at minimum; **filenames lowercase, hyphens for spaces, no dates in the name
  except in `sources/`**; `updated` changes on every edit; one subject per page, and when unsure
  whether to create or extend, extend; **written in English, keeping Portuguese terms where they
  are the natural name for something.**
- The rule that `raw/` is immutable except for the `ingested:` stamp, and that deleting that line
  re-ingests the file.
- `index.md` format: `## Sources`, `## Notes`. Two sections only — ticket and tool pages are notes.
- `log.md` format, newest at the bottom: `## [YYYY-MM-DD] ingest | <title>` plus a
  `Pages touched:` line.
- **Ticket pages**, since they are a real convention and the schema is the contract:
  `wiki/notes/<KEY>.md`, frontmatter adds `ticket: <KEY>`, body is a one-line goal plus a
  `## Timeline` of `- YYYY-MM-DD: <what happened> — [[<source-page>]]`.
- **Version caveats**, the highest-value content this vault holds, as a `## Version caveats`
  section inside the relevant `wiki/notes/<tool>.md`:
  `- **<version range>**: <symptom, with verbatim error> → <fix>. Verify: <command>. Source: [[sources/<page>]]`
  Newest first. When a later source shows an issue fixed, annotate "fixed in X" rather than
  deleting — a version change is not a contradiction.

Cut entirely: the public-grade denylist, the plain-path-not-wikilink convention, the whole `tools/`
section, the `tickets/` directory and its `status:` field, the `refused:` stamp, the `facet:` field,
the work/personal divergence, and the duplicated "why flat" essay.

### 2. `opencode/.config/opencode/agents/zettelkasten.md` — the single Librarian

Delete `zettelkasten-personal.md`. Rewrite `zettelkasten.md` (currently 82 lines, ~65 after),
keeping the filename so `zk-ingest` and `zk-lint` don't change.

Frontmatter:
```yaml
---
description: Maintains the knowledge wiki in the current directory. Ingests raw/ handoffs into wiki/ pages. Run via `zk-ingest`. Also handles lint passes.
mode: all
model: llamacpp/qwen3.8-27b-local
permission:
  read: allow
  grep: allow
  glob: allow
  list: allow
  edit: allow
  bash: deny
  task: deny
  webfetch: deny
  external_directory: deny
---
```

Note `external_directory: deny` flat (was an allow-map for `tools/`), `task: deny` (was
`explore: allow`), no `variant`, and **no `dna-ai-lab-jira_*` key** — that last one was inert
config naming the user's employer in a file the docs insisted must stay portable.

**Replace the 11-step ingest with 5 steps.** The current version is ~900 words the model must hold
alongside the schema, the raw file and every page it is updating. Target:

```markdown
## On ingest
1. For each file in `raw/` whose frontmatter has no `ingested:` stamp, read it fully.
2. Write or update a summary page in `wiki/sources/`, and pages in `wiki/notes/` for what the
   handoff teaches. Extend existing pages rather than creating near-duplicates. Scale to what's
   actually in the file — a thin handoff correctly produces just a source page and an index
   line. Don't create pages for passing mentions.
   Carry `tools`, `tags` and `keywords` through from the raw frontmatter, so exact error strings
   and versions stay greppable.
   Version-specific caveats are the highest-value content here: record the version range, the
   verbatim error, the fix, and a command that verifies it. Never paraphrase an error string.
3. If the raw file has `tickets:` keys, create or update `wiki/notes/<KEY>.md` for each: append
   `- YYYY-MM-DD: <what happened> — [[<source-page>]]` to its `## Timeline`, skipping the append
   if a line for that date and source is already there.
4. Add a `[[wikilink]]` and one-line description to `wiki/index.md` for every page you created,
   and append to `wiki/log.md`: `## [YYYY-MM-DD] ingest | <title>` plus a `Pages touched:` line.
5. Last, add `ingested: YYYY-MM-DD` to the raw file's frontmatter. Change nothing else in it.
   This is last on purpose: an ingest that dies partway leaves the file unstamped and the next
   run redoes it, which step 3's dedupe check makes safe.
   Then report what you touched and anything that contradicts an existing page.
```

Shrink `## On lint` to the checks that still have a subject:
- Raw files with no `ingested:` stamp (the backlog).
- Files stamped `ingested:` with no matching `wiki/log.md` entry (a run that died at the last step).
- Orphan pages with no inbound links.
- Contradictions between pages.
- Caveats with no "fixed in" status on tools that have newer sources since.

Cut: the unindexed-tool-pages check, both refused-files checks, the ticket-page-not-linked check,
and "find concepts mentioned but lacking their own page" (invites page inflation).

Constraints: keep *"follow `AGENTS.md` strictly, stop if it's missing"*, *"normal clear English,
never terse chat style"*, *"never answer questions directly"*, *"never delete pages without
confirmation"*. Cut the `tools/` portability bullet.

### 3. `opencode/.config/opencode/agents/archivist.md` — trim

The best-written of the three, but it has **nine** dual-vault references, not the three an earlier
draft listed. Every one is itemized here by its current line number:

- **Line 2** (`description`): drop "(personal + work + shared tool caveats)" and "so it runs inside
  the personal vault" → "Start it with `zk`."
- **Lines 16-18** (`external_directory`): replace the map with flat `external_directory: deny`.
- **Line 21**: "You run inside the personal vault (`~/code/Zettelkasten`)" → "the vault".
- **Line 24**: keep, dropping the "Personal vault:" label — sources are just `wiki/`.
- **Line 25**: delete the `tools/` entry.
- **Line 26**: ticket rollups → `wiki/notes/<KEY>.md`, drop the work-vault path.
- **Line 27**: delete the work-vault entry.
- **Line 30**: "(`wiki/tickets/<KEY>.md`, or the work vault's)" → "(`wiki/notes/<KEY>.md`)".
- **Line 31**: "For tool or version issues, start with `tools/`" → "start with `wiki/notes/`"; and
  **delete** "Search the work vault too unless the question is clearly personal."
- **Line 32**: "Widen with the two index files" → "Widen with `wiki/index.md`".
- **Line 34**: delete "with the vault prefix for work pages".
- **Line 35**: "Suggest `zk-ingest-work` or `zk-ingest-personal`" → "Suggest `zk-ingest`".
- **Line 40**: "do list `raw/` in both vaults" → "do list `raw/`"; and "suggest
  `zk-ingest-personal` or `zk-ingest-work`" → "suggest `zk-ingest`".

**Keep, in substance, the two best instructions in the repo.** Note that line 40 is one of them and
still needs the edit above — "keep unchanged" was the earlier draft's mistake, and following it
literally would reintroduce two deleted function names:

- The **stale-caveat warning** ("a caveat that is real but no longer applies is the most damaging
  answer you can give, because it looks correctly sourced"), plus asking for the user's version,
  since the Archivist has no `bash`.
- The **`raw/` handling**: don't cite it, but do list it and name an un-ingested file rather than
  falling back to general knowledge while the answer sits unprocessed.

### 4. `fish/.config/fish/conf.d/zk.fish` — 9 functions to 5

The current file has **9** functions (`zk`, `zk-ingest-work`, `zk-ingest-personal`, `zk-ingest`,
`zk-_pending`, `zk-status`, `zk-lint`, `zk-lint-work`, `zk-sync`), not 8.

Keep: `zk`, `zk-status`, `zk-ingest`, `zk-lint`, and `zk-_pending` as an internal helper.
Delete: `zk-ingest-work`, `zk-ingest-personal`, `zk-lint-work`, and `zk-sync` as a separate public
function (fold the commit into `zk-ingest`).

Replace the file's entire contents with this:

```fish
# ~/.config/fish/conf.d/zk.fish
# conf.d, not functions/: fish only autoloads one function per file, and this file holds five.
#
# One vault per machine at ~/code/Zettelkasten. The machine decides what's in it — work content on
# the work laptop, personal content on the personal desktop. No facet, no routing, no sync: that
# is the whole privacy model. Each command runs OpenCode inside the vault, which is what makes the
# external_directory deny in opencode.jsonc work without getting in the way.
#
# zk, zk-ingest and zk-lint all need llama-server up on 127.0.0.1:8080. If it's down you get a raw
# connection error from the openai-compatible provider, not a useful message:
#   curl -sf http://127.0.0.1:8080/v1/models >/dev/null; or echo "llama-server is down"
# The pin is by endpoint, not by name: llama-server answers with whichever model is loaded.

function zk --description 'Archivist: query the wiki'
    pushd ~/code/Zettelkasten; or return 1
    opencode --agent archivist $argv
    popd
end

function zk-status --description 'What is captured but not yet ingested?'
    set -l pending (zk-_pending)
    if test (count $pending) -gt 0
        echo (count $pending)" pending:"
        for f in $pending
            echo "  "(basename $f)
        end
    else
        echo "clear"
    end
end

function zk-ingest --description 'Ingest pending raw files, then commit'
    if test (count (zk-_pending)) -eq 0
        echo "Nothing pending."
        return 0
    end
    pushd ~/code/Zettelkasten; or return 1
    opencode run --agent zettelkasten "Ingest new files in raw/. $argv"
    set -l rc $status
    popd
    if test $rc -eq 0
        git -C ~/code/Zettelkasten add -A
        git -C ~/code/Zettelkasten diff --cached --quiet
        or git -C ~/code/Zettelkasten commit -m "ingest: "(date +%Y-%m-%d)
    end
    return $rc
end

function zk-lint --description 'Librarian: health-check the vault'
    pushd ~/code/Zettelkasten; or return 1
    opencode run --agent zettelkasten "Run a lint pass over this vault. $argv"
    popd
end

# Raw files with no `ingested:` stamp. Only the leading --- block counts, so a verbatim error
# string in the body that starts with "ingested:" can't mark a file done.
function zk-_pending --description 'Internal: list unprocessed raw files'
    test -d ~/code/Zettelkasten/raw; or return 0
    for f in ~/code/Zettelkasten/raw/*.md
        test -e $f; or continue
        sed -n '1{/^---$/!q}; 1d; /^---$/q; p' $f | grep -qE '^ingested:'; or echo $f
    end
end
```

Four things to preserve, each a bug fix that cost a review round — do not reintroduce them:

- `set -l rc $status` must come immediately after `opencode run`, before `popd` clobbers it.
  `popd` runs a command and overwrites `$status`.
- `git diff --cached --quiet` exits **1** when there ARE staged changes, so `; or git commit` is
  correct, not inverted.
- The `sed` in `zk-_pending` reads only the leading `---` block. A body line starting `ingested:`
  — e.g. a verbatim error string — must not mark a file done.
- The header comment explaining **why this lives in `conf.d/` and not `functions/`** (fish
  autoloads one function per file) stays. It is the reason the file is shaped this way.

The `grep -qE` pattern drops `refused` and matches `^ingested:` only, since the `refused:` stamp is
gone. **Migration consequence, verified:** any raw file currently stamped `refused:` becomes pending
again and will be ingested on the next run. That is the correct behaviour — the refusal concept no
longer exists — but check `grep -rl '^refused:' ~/code/Zettelkasten/raw/` on each machine before the
first post-refactor `zk-ingest` so nothing arrives as a surprise. Delete the old header comments about concurrent ingests (moot with one ingest command) and
the trailing `zk-wall-test` note (the wall check is deleted outright, not relocated). The
llama-server endpoint note **stays in this file** — an earlier draft said it "moves to the setup
guide" and then never placed it anywhere.

### 5. `opencode/.config/opencode/commands/handoff.md` — drop facet and routing

`facet` appears in **seven** places. All go:

- **Line 2** (`description`): drop "(any facet: work, homelab, local-llm, dotfiles, personal)".
- **Line 6**: "for the Zettelkasten wiki — personal or work, whichever facet this session was" →
  "for the Zettelkasten wiki".
- **Line 21**: delete the whole `**Facet**` bullet from Step 2's extract list. (Capitalised, so a
  case-sensitive grep for `facet` misses it — this is why the check below uses `-i`.)
- **Line 33** (Step 3): "Folder: `~/code/Zettelkasten-work/raw/` if facet is `work`, otherwise
  `~/code/Zettelkasten/raw/`" → "Folder: `~/code/Zettelkasten/raw/`". Keep "If OpenCode asks for
  permission to write there, that's expected."
- **Line 42**: delete `facet: <facet>` from the frontmatter template.
- **Line 83**: delete `facet: <facet>` from the Step 5 report block.
- **Lines 90-92**: "lets the user check the facet (which decides the vault) and the keywords" →
  "lets the user check the keywords (which decide whether this is findable later) without opening
  the file. Then `zk-ingest` picks it up." Delete "whichever vault it landed in" — there is one
  vault.

Keep everything else, especially the **verbatim-accuracy instruction** (lines 9-13) — it is more
load-bearing now that a 27B writes every handoff — and the frontmatter echo in Step 5. Keep
`model: llamacpp/qwen3.8-27b-local`.

### 6. `opencode/.config/opencode/opencode.jsonc` — simplify permissions

Replace **both the 7-line comment at lines 38-44 and the permission block at lines 45-53** —
the comment describes a dual-vault wall and contains the literal string `public-grade`, which the
verification grep below checks for. Rewriting only the JSON leaves a comment that contradicts the
three lines beneath it, and fails verification.

```jsonc
  // Privacy wall for every session outside the vault (e.g. Copilot agents in work repos).
  // Last matching rule wins. The vault is off-limits, except raw/ so /handoff can write there —
  // you get a prompt; approve "once", never "always". That prompt is also the signal that
  // something wrote a handoff you didn't expect; /handoff echoing its frontmatter is the other.
  // The zk-* functions run OpenCode from inside the vault, so this never gets in their way.
  "permission": {
    "external_directory": {
      "*": "ask",
      "~/code/Zettelkasten/**": "deny",
      "~/code/Zettelkasten/raw/**": "ask"
    }
  },
```

The `tools/` carve-out and the work-vault rule go; the blanket `deny` **stays** (see **Why**). Keep
`small_model`, the `llamacpp` provider block, the DCP pin, `instructions: ["style.md"]` and the
trailing work-MCP-servers note exactly as they are.

### 7. `opencode/.config/opencode/style.md` — one edit

Line 20-21: change the agent exclusion list from three agents to two — `zettelkasten` and
`archivist`. Everything else stays. This file is the highest-value 20 lines in the repo and
directly addresses the cause of the first attempt's abandonment.

### 8. `opencode/.config/opencode/AGENTS.md` — fix the stale memory pointer

**Not named in any earlier draft.** Lines 30-33 point every OpenCode session at a predecessor
system that no longer exists:

```
## Memory

Notes: ~/notes/agent (zk/ = atomic caveats, handoffs/ = sessions).
Before debugging a tool or library issue: rg -il "<tool>|<error>" ~/notes/agent
```

Replace with:

```
## Memory

Knowledge wiki: ~/code/Zettelkasten (raw/ = handoffs from /handoff, wiki/ = ingested pages).
Before debugging a tool or library issue: rg -il "<tool>|<error>" ~/code/Zettelkasten/wiki
```

Change nothing else in this file here — see **Flagged, out of scope** below for the rest of it.

### 9. `MACOS_SETUP_zettelkasten.md` — 451 lines to ~180

The guide is stale beyond the vault change; rewrite it as a clean setup guide rather than patching.
Current sections: 1 GPU LaunchDaemon, 2 OpenCode files (with a `### Work MCP servers` subsection at
line 91), 3 Verify OpenCode version, 4 Set up the vaults, 5 Privacy wall check, 6 Dry run,
7 Recurring maintenance, 8 Optional, plus a closing "Notes on what this session could not verify".

- **Title** (line 1): "Zettelkasten vaults" → "the Zettelkasten vault".
- **Section 1** (GPU LaunchDaemon): keep as-is. Unrelated to the wiki and still accurate.
- **Section 2** (OpenCode files): currently a session-by-session changelog, stale the moment it is
  written. Rewrite as a plain description of what each file is and does.
  **Preserve the `### Work MCP servers and AGENTS.md` subsection (lines 91-171) verbatim.** It
  documents the gitignored local-override mechanism for Jira/Confluence/Jenkins, has nothing to do
  with the vault, and is still correct. Do not let "rewrite section 2" sweep it away.
- **Section 3** (verify OpenCode version): keep, fixing the internal "(step 6)" cross-reference at
  line 188 to match the new numbering.
- **Section 4** (vault setup): one vault.
  `mkdir -p ~/code/Zettelkasten/{raw,wiki/{sources,notes}}`, copy `zettelkasten/AGENTS.md` to the
  vault root, seed `index.md` and `log.md`, `git init`. Delete its step 7 ("Confirm the vaults are
  properly separated") — there is one vault.
  **Add the machine-is-the-facet statement**: this vault holds whatever this machine is for; run
  this guide on the work MacBook for work and on the personal desktop for personal; do not set up a
  vault on the Pi.
  **Add the backup warning**: if anything syncs or backs up `~/code` (Time Machine, corporate
  backup, iCloud, Dropbox), vault content goes wherever that tool sends it. "Local" is an assumption
  about this machine, not a mechanism.
- **Section 5** (privacy wall check): **delete the whole section.** It tested a boundary that no
  longer exists.
- **Section 6** (dry run): `/handoff` → `zk-status` → `zk-ingest` → `zk`. Keep the two watch-outs
  (the `zk` positional-argument question, and checking the local model didn't paraphrase an error
  string) — but bound the second: *"check the first three handoffs, then stop."*
- **Section 7** (maintenance): reduce to one row — `zk-lint`, monthly-ish. The post-work-ingest
  `tools/` audit and the six-month `tools/` review both die with their subject. Commits are
  automatic.
- **Section 8** (Optional: omo-slim, Headroom): keep as-is.
- **Closing notes**: keep the honesty about what has not been verified.
- **Renumber the remaining sections contiguously** after deleting section 5 (so 6→5, 7→6, 8→7) and
  fix every internal "step N" / "section N" cross-reference to match. Do not leave a numbering gap.

### 10. `README.md` — four spots, not three

- **Lines 57-58** (structure tree, agents): "the Zettelkasten trio: zettelkasten (work),
  zettelkasten-personal, archivist" → two agents, `zettelkasten` and `archivist`.
- **Lines 82-84** (structure tree, `zettelkasten/`): now holds one `AGENTS.md`, not two. Drop the
  `AGENTS.personal.md` / `AGENTS.work.md` lines and the "vault roots" plural.
- **Line 13**: check the `.stow-local-ignore` description still reads correctly.
- **Lines 273-275**: the prose sentence "the Zettelkasten dual-vault agent system
  (`zettelkasten.md`/`zettelkasten-personal.md`/`archivist.md`, `/handoff`, and the
  `zk-status`/`zk-ingest`/`zk` fish functions, plus `zk-lint` and `zk-sync`)". Drop "dual-vault",
  drop `zettelkasten-personal.md`, drop `zk-sync`. **An earlier draft's three bullets did not cover
  this sentence** — it is in a different part of the file from the tree.

### 11. `.stow-local-ignore` — comment fix (an earlier draft wrongly said "no change")

Lines 4-6 currently read:

```
# zettelkasten/ holds vault schema templates that get *copied* into the vault roots
# (~/code/Zettelkasten, ~/code/Zettelkasten-work), not symlinked into $HOME.
# The vaults are their own git repos; a symlink would make their schema a dotfiles dependency.
```

Both the plural "vault roots"/"vaults" and `Zettelkasten-work` are wrong under one vault, and
`Zettelkasten-work` is on the verification grep list — so "no change" guarantees the plan's own
self-check fails. Rewrite to singular:

```
# zettelkasten/ holds the vault schema template that gets *copied* into the vault root
# (~/code/Zettelkasten), not symlinked into $HOME.
# The vault is its own git repo; a symlink would make its schema a dotfiles dependency.
```

The ignore rules themselves (`^vscode$`, `^zettelkasten$`) do not change.

### 12. `opencode/.config/opencode/agents/tech-lead.md` — one paragraph

**Not named in any earlier draft**, and the only file outside the ten the earlier plan listed that
its own verification grep would have flagged. Lines 684-688, in "Worktree closing — knowledge
capture", describe both the deleted vault routing and the deleted `facet` field:

> It writes a raw note to the correct vault — work or personal, based on the session — with the
> full frontmatter schema (`facet`, `tickets`, `tools`, `keywords`) …

Replace that clause with: writes a raw note to `~/code/Zettelkasten/raw/` with the full frontmatter
schema (`tickets`, `tools`, `tags`, `keywords`). Keep the surrounding paragraph — especially *"don't
write a handoff file yourself with a different structure; always go through `/handoff`"*, which
protects the verbatim-copy rule from being bypassed. Change nothing else in this 32k file.

### 13. `SIMPLIFY_PLAN.md` — delete in the last commit

Its content is captured by the files it produced. Git history holds the reasoning.

---

## What must survive this refactor

Each of these was either the point of the system or a bug fix that cost a review round. The section
that carries each one is named, so none of them survives only by accident:

| Must survive | Carried by |
|---|---|
| The **verbatim-copy rule** in `/handoff` — goal 2's version caveats are worthless if a 27B paraphrases the error | §5, "keep everything else, especially lines 9-13" |
| The **`style.md` capture nudge** — the only component aimed at the failure that actually happened | §7, "everything else stays" |
| **`keywords:` and frontmatter carry-through** — the retrieval mechanism | §1 field set + §2 ingest step 2 |
| The **Archivist's stale-caveat warning** and asking for the user's version | §3, "keep in substance" |
| The **Archivist's `raw/` handling** — list it, name an un-ingested file, don't fall back to general knowledge | §3, line 40 (edited, not "unchanged") |
| **`ingested:` stamped last**, with the dedupe check making re-runs safe — reverted once already, don't move it again | §2 ingest step 5 |
| The **frontmatter-only stamp check** (`sed` expression) in `zk-_pending` | §4, preserve-list |
| **`set -l rc $status` before `popd`**, and the `git diff --cached --quiet` polarity | §4, preserve-list |
| **Flat `notes/`** and a short version of why | §1, "why flat", trimmed to ~3 lines |
| **Filename convention** (lowercase, hyphens, no dates except `sources/`) | §1, page rules |
| **English with Portuguese terms** where they are the natural name | §1, page rules |
| **Ticket rollup format** (`wiki/notes/<KEY>.md`, `## Timeline`) — a real convention, so it belongs in the schema, not only in the Librarian's prompt | §1, ticket pages + §2 ingest step 3 |
| The **`conf.d/` not `functions/` rationale** | §4, preserve-list |
| The **llama-server endpoint note** | §4, header comment |
| The **Work MCP servers override mechanism** (~80 unrelated lines) | §9, "preserve verbatim" |
| The **blanket `external_directory` deny** | §6 |

---

## Verification

No `fish` or `opencode` in the editing environment, so these are static checks. **The real test is
`fish -n ~/.config/fish/conf.d/zk.fish` and the dry run on the Mac afterwards.**

1. **No dead references anywhere.** This must print nothing:
   ```bash
   grep -rniE "Zettelkasten-work|zettelkasten-personal|AGENTS\.(personal|work)\.md|zk-(ingest|lint)-(work|personal)|zk-sync|zk-wall-test|wiki/tickets|public-grade|refused:|~/notes/agent|\bfacet\b|dual-vault" \
     --include="*.md" --include="*.fish" --include="*.jsonc" --include="*.json" \
     --include=".stow-local-ignore" . \
     | grep -vE "^\./(SIMPLIFY_PLAN|brief)\.md"
   ```
   Two things that are easy to get wrong here, both verified:
   - `-i` is required: `handoff.md:21` capitalises the field as `**Facet**`.
   - `--include=".stow-local-ignore"` is required: that file has no extension, so the other
     `--include` filters silently skip it — and it is one of the files that actually needs
     changing (§11).

   Run it against the current tree *before* starting. It hits **14 files**, which map exactly onto
   the 13 sections above (§1 and §2 each cover two files). Any file it flags with no section is a
   gap in this plan, not a stray — that is how §8 and §12 were found.

   An earlier draft's grep omitted `AGENTS.personal` / `AGENTS.work` (the very filenames it
   deleted), `facet`, `~/notes/agent` and `dual-vault`, and included `tools/`, which false-positives
   on unrelated prose. Check `tools/` narrowly instead:
   ```bash
   grep -nE "(^|[^a-z])tools/" zettelkasten/AGENTS.md \
     opencode/.config/opencode/agents/{zettelkasten,archivist}.md
   ```
2. **Function count is exactly 5, with 4 public.** Both must hold:
   ```bash
   grep -c '^function ' fish/.config/fish/conf.d/zk.fish        # → 5
   grep -c '^function zk-_' fish/.config/fish/conf.d/zk.fish    # → 1
   ```
   Do **not** rely on an `awk` `function`/`end` balance check: `/^end$/` only matches flush-left
   `end` lines, so it passes by accident of indentation and says nothing about the count.
3. **Frontmatter field sets match.** The field list in `zettelkasten/AGENTS.md` and the fields named
   in the Librarian's ingest step 2 must be the same set. `facet` must appear in neither.
4. **The three directory layouts agree** — the schema's tree, the Librarian's ingest steps, and the
   setup guide's `mkdir` all name `raw/`, `wiki/index.md`, `wiki/log.md`, `wiki/sources/`,
   `wiki/notes/` and nothing else.
5. **Cross-references resolve.** Every "see step N" in the agent files resolves against the new
   5-step list, and every "step N" / "section N" inside `MACOS_SETUP_zettelkasten.md` resolves
   against its renumbered sections:
   ```bash
   grep -nE "\b(step|section) [0-9]+" MACOS_SETUP_zettelkasten.md \
     opencode/.config/opencode/agents/*.md
   ```
6. **No second vault, wall test, or cloud model doing ingests** survives in
   `MACOS_SETUP_zettelkasten.md`, and its `### Work MCP servers` subsection is still present and
   intact.
7. **JSONC still parses.** `opencode.jsonc` has balanced braces and no trailing comma after the
   `permission` block.

---

## Suggested commits

All thirteen sections are assigned, none twice:

1. `feat(zettelkasten): single vault schema` — §1 (new `AGENTS.md`, delete both old schema files).
2. `refactor(zettelkasten): one local Librarian, 5-step ingest` — §2, §3, §7 (merge the agents,
   trim the Archivist, update `style.md`).
3. `refactor(zettelkasten): four commands, drop facet, simplify permissions` — §4, §5, §6, §8, §12
   (`zk.fish`, `handoff.md`, `opencode.jsonc`, the OpenCode `AGENTS.md` memory pointer, and the
   `tech-lead.md` handoff paragraph).
4. `docs: rewrite setup guide for the single-vault system` — §9, §10, §11, §13 (setup guide,
   README, `.stow-local-ignore`, and delete this plan file).

---

## Flagged, out of scope — needs a separate decision

Found while verifying this plan. **Do not fix as part of this refactor**; it is unrelated to the
vault system and deserves its own call.

Six tracked files in this public repo contain employer identifiers — the Bitbucket host
`oakdvcs.dna.fi`, the project prefix `dna-ai-lab`, and a real name in an absolute path
(`/Users/joao.campos/.pyenv/shims/bb`):

```
MACOS_SETUP_zettelkasten.md
SIMPLIFY_PLAN.md
opencode/.config/opencode/AGENTS.md
opencode/.config/opencode/agents/requirements-clarifier.md
opencode/.config/opencode/agents/tech-lead.md
opencode/.config/opencode/agents/zettelkasten.md
vscode/mcp.json
```

§2 of this plan removes the `dna-ai-lab-jira_*` key from `zettelkasten.md` as a side effect of
rewriting that file, and §9's rewrite may or may not touch the setup guide's instance. The other
four files are untouched by this plan. The same `.env.work`-style gitignored-override pattern the
repo already uses for MCP servers would work here.
