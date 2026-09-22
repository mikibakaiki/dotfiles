# Plan: collapse the Zettelkasten system to one vault, one Librarian, all local

**For a fresh session to execute.** Everything needed is in this file; you shouldn't need the
conversation that produced it.

Branch: `zettelkasten-dual-vault`, currently at `3df9151`, five commits ahead of `origin/main`
(PR #2 open). Do this work on the same branch unless the PR has been merged, in which case branch
from `main`.

---

## Why

The system works but is roughly three times the size it needs to be. It grew through several
review rounds, each finding a real-but-hypothetical failure in a vault with approximately zero
pages, and each answering with a rule rather than a deletion. Current size: 1,078 lines across
agent prompts, schemas, fish functions and the setup guide — two Librarian agents that are ~95%
identical text and have already drifted from each other gratuitously.

Two decisions collapse most of it:

1. **One vault, not two.** The user's files are local with no syncing, and the work MacBook and
   the personal desktop/Pi each have their own checkout. Device separation already gives the
   work/personal split physically; the system doesn't need to enforce what the filesystem
   already does.
2. **Everything local, no cloud model.** The Librarian, the Archivist and `/handoff` all run on
   llama.cpp. This satisfies the privacy goal by construction rather than by a permission map
   plus a sanitization rule plus a manual audit habit, and removes all Copilot billing for wiki
   operations.

Nine defensive mechanisms exist *only* because there were two vaults and a cloud model in the
loop. They all go: the cross-vault `tools/` folder and its public-grade rule, the plain-path
link convention, the `external_directory` allow-hole, the no-concurrent-ingest constraint, the
re-read-before-append protocol, the `refused:` stamp and its refusal triggers, the portability
rule, the wall check, and the post-work-ingest audit.

---

## Target state

```
~/code/Zettelkasten/          one git repo, one Obsidian vault, one per machine
  AGENTS.md                   the schema (~60 lines), copied from zettelkasten/AGENTS.md
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
- **Fish functions: 4.** `zk`, `zk-status`, `zk-ingest`, `zk-lint`.
- **Stamps: 1.** `ingested:`.
- **Concepts the human holds: 3.** capture, file, ask.

Expected result: roughly 1,078 → ~450 lines. No new components — this plan only deletes and
merges.

---

## Decisions already made (don't relitigate)

| Decision | Rationale |
|---|---|
| One vault | Device separation already provides work/personal separation. Files are local, no syncing. |
| All models local | Satisfies the privacy goal by construction; zero Copilot cost for wiki ops. |
| `facet:` survives as a plain frontmatter tag | Useful for Obsidian filtering and a possible `grep -rl 'facet: work' \| xargs rm` cleanup. No routing, no rules, no refusal logic. |
| `tools/` folds into `wiki/notes/` | Its only reason to be separate was cross-vault sharing between two Librarians. A tool page is now `wiki/notes/llama-cpp.md` with a `## Version caveats` section. |
| Ticket rollups stay **eager**, simplified | Moves work from the weak-link operation (multi-file synthesis at query time, hard for a 27B) to the easy one (append one line at write time). Now `wiki/notes/<KEY>.md` like any other note — no separate directory, no `status:` field, no dedicated index section. |
| `zk-lint` survives | The simplification critic wanted it cut, but it's the only thing that would catch a silent capture failure — the failure mode that actually killed the user's first attempt. It shrinks a lot, since most of its checks had nothing left to check. |
| `log.md` survives | `git log` was proposed as a replacement, but `zk-sync`-style commits don't attribute pages to source handoffs. Keep it. |

**Noted for later, not now:** if after a few months most `wiki/notes/<TICKET>.md` pages have
exactly one timeline line, drop eager rollups and let the Archivist assemble from `tickets:`
frontmatter on demand. Cheap, evidence-based reversal.

---

## Changes, file by file

### 1. `zettelkasten/AGENTS.md` — new, replaces both schema files

Delete `zettelkasten/AGENTS.personal.md` (156 lines) and `zettelkasten/AGENTS.work.md` (148
lines). Write one `zettelkasten/AGENTS.md`, target ~60 lines, containing:

- The directory layout from **Target state** above.
- The "why flat" rationale, once — keep it, it's correct and hard-won, but trim to ~3 lines. Keep
  "don't pre-plan the split; split when flatness actually hurts."
- Page frontmatter: `tags`, `sources`, `updated`. (Drop `created` — git has it.)
- The rule that `raw/` is immutable except for the `ingested:` stamp, and that deleting that line
  re-ingests the file.
- `index.md` format: `## Sources`, `## Notes`. (No `## Tickets`, no `## Tools` — ticket and tool
  pages are notes.)
- `log.md` format: `## [YYYY-MM-DD] ingest | <title>` plus a `Pages touched:` line.
- Version caveats: what they look like inside a note page, since they're the highest-value
  content this vault holds:
  `- **<version range>**: <symptom, with verbatim error> → <fix>. Verify: <command>. Source: sources/<page>`
  Annotate "fixed in X" rather than deleting. Newest first.
- `[[wikilinks]]` everywhere — no plain-path exception any more, since there's one vault.

Cut entirely: the public-grade denylist, the plain-path-not-wikilink convention, the `tools/`
section, the `tickets/` frontmatter schema, the work/personal divergence, and the duplicated
"why flat" essay.

### 2. `opencode/.config/opencode/agents/zettelkasten.md` — rewrite as the single Librarian

Delete `zettelkasten-personal.md`. Rewrite `zettelkasten.md` (currently 82 lines, target ~40),
keeping the filename so `zk-ingest` doesn't change.

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

Note `external_directory: deny` (was an allow-map for `tools/`), `task: deny` (was
`explore: allow`), no `variant`, no `dna-ai-lab-jira_*` key — that last one was inert config
naming the user's employer in a file the docs insisted must stay portable.

**Replace the 11-step ingest with 5 steps.** The current version is ~900 words the model must
hold alongside the schema, the raw file and every page it's updating. Target:

```markdown
## On ingest
1. For each file in `raw/` whose frontmatter has no `ingested:` stamp, read it fully.
2. Write or update a summary page in `wiki/sources/`, and pages in `wiki/notes/` for what the
   handoff teaches. Extend existing pages rather than creating near-duplicates. Scale to what's
   actually in the file — a thin handoff correctly produces just a source page and an index
   line. Don't create pages for passing mentions.
   Carry `facet`, `tools`, `tags` and `keywords` through from the raw frontmatter, so exact
   error strings and versions stay greppable.
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

Cut: the unindexed-tool-pages check, the refused-files checks, the ticket-page-not-linked check,
and "find concepts mentioned but lacking their own page" (invites page inflation).

Constraints section: keep "follow `AGENTS.md` strictly, stop if it's missing", "normal clear
English, never terse chat style", "never answer questions directly", "never delete pages without
confirmation". Cut the `tools/` portability bullet.

### 3. `opencode/.config/opencode/agents/archivist.md` — trim

Keep the file; it's already the smallest and best-written of the three. Changes:

- `external_directory: deny` flat — delete the work-vault allow-map.
- Sources list: just `wiki/` (index at `wiki/index.md`, summaries in `sources/`, everything else
  flat in `notes/`). Delete the work-vault and `tools/` entries.
- Delete "with the vault prefix for work pages" from the citation step.
- **Keep**, unchanged, the two best instructions in the repo: the version-caveat warning ("a
  caveat that is real but no longer applies is the most damaging answer you can give, because it
  looks correctly sourced" — plus asking for the user's version, since it has no `bash`), and the
  `raw/` handling (don't cite it, but do list it and name an un-ingested file rather than falling
  back to general knowledge).
- For ticket questions, point at `wiki/notes/<KEY>.md` instead of `wiki/tickets/<KEY>.md`.

### 4. `fish/.config/fish/conf.d/zk.fish` — 8 functions to 4

Keep: `zk`, `zk-status`, `zk-ingest`, `zk-lint`.
Delete: `zk-ingest-work`, `zk-ingest-personal`, `zk-lint-work`, `zk-_pending` (inline it),
`zk-sync` as a separate public function (fold the commit into `zk-ingest`).

```fish
# One vault per machine, all local models. Each command runs OpenCode inside the vault.

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
    test (count (zk-_pending)) -gt 0; or begin
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

Two things to preserve when rewriting — both were bugs found by review and fixed, don't
reintroduce them:
- `set -l rc $status` must come immediately after `opencode run`, before `popd` clobbers it.
- `git diff --cached --quiet` exits **1** when there ARE staged changes, so `; or git commit` is
  correct, not inverted.

Delete the header comments about never running two ingests concurrently and about the endpoint
pin — the first is moot with one ingest command, the second moves to the setup guide.

### 5. `opencode/.config/opencode/commands/handoff.md` — simplify routing

- Step 3: always write to `~/code/Zettelkasten/raw/`. Delete the facet-based vault routing.
- Step 2: keep `facet:` in the extracted fields — it stays as a tag.
- Keep everything else, especially the verbatim-accuracy instruction (it's more load-bearing now
  that a 27B writes it) and the frontmatter echo in step 5.
- Keep `model: llamacpp/qwen3.8-27b-local`.

### 6. `opencode/.config/opencode/opencode.jsonc` — simplify permissions

Replace the `external_directory` block with:

```jsonc
"permission": {
  "external_directory": {
    "*": "ask",
    "~/code/Zettelkasten/raw/**": "ask"
  }
}
```

The blanket `deny` on the vault, the `tools/` carve-out and the work-vault rule all go. `"*":
"ask"` already catches the stray-write case, which is all this was ever doing once the split
stopped being a security boundary. Keep `small_model`, the `llamacpp` provider block, the DCP
pin and `instructions: ["style.md"]` as they are.

### 7. `opencode/.config/opencode/style.md` — one edit

In the capture-nudge section, change the agent exclusion list from three agents to two:
`zettelkasten` and `archivist`. Everything else stays — this file is the highest-value 20 lines
in the repo and directly addresses the abandonment cause.

### 8. `MACOS_SETUP_zettelkasten.md` — 451 lines to ~180

- **Section 4** (vault setup): one vault. `mkdir -p ~/code/Zettelkasten/{raw,wiki/{sources,notes}}`,
  copy `zettelkasten/AGENTS.md` to the vault root, seed `index.md` and `log.md`, `git init`.
- **Section 5** (privacy wall check): **delete the whole section.** It tested a boundary that no
  longer exists, and the docs already said it wasn't a security boundary.
- **Section 7** (maintenance table): reduce to one row — `zk-lint`, monthly-ish. The
  post-work-ingest `tools/` audit and the six-month `tools/` review both die with their subject.
  Commits are automatic.
- **Section 6** (dry run): `/handoff` → `zk-status` → `zk-ingest` → `zk`. Keep the two watch-outs
  (the `zk` positional-argument question, and checking that the local model didn't paraphrase an
  error string) — but bound the second: "check the first three handoffs, then stop."
- **Section 2** (changelog of what changed): rewrite as a plain description of what the files are.
  It's currently a session-by-session changelog, which is stale the moment it's written.
- **Sections 1 and 8** (GPU LaunchDaemon; omo-slim and Headroom): keep as-is. They're unrelated to
  the wiki and still accurate.
- Keep the honesty about what hasn't been verified.

### 9. `README.md` — small edits

- Structure tree: `zettelkasten/` now holds one `AGENTS.md`, not two.
- Agents line: two Zettelkasten agents, not three.
- Command list: `zk-status`/`zk-ingest`/`zk`/`zk-lint`.

### 10. `.stow-local-ignore`

No change — `zettelkasten/` stays excluded. Verify the comment still reads correctly.

---

## Verification

Nothing here can be executed on a Windows machine — no `fish`, no `opencode`, no vault. The
checks that *can* be done at edit time:

1. `grep -rn "Zettelkasten-work\|zettelkasten-personal\|tools/\|refused:\|zk-ingest-work\|zk-ingest-personal\|zk-lint-work\|zk-sync\|public-grade\|wiki/tickets" --include="*.md" --include="*.fish" --include="*.jsonc" .`
   should return nothing outside `brief.md` (untracked historical input) and this plan file.
2. Every "see step N" cross-reference in the agent files resolves against the new 5-step list.
3. `awk '/^function/{f++} /^end$/{e++} END{print f, e}'` on `zk.fish` returns equal counts.
4. The schema's directory layout, the Librarian's ingest steps, and the setup guide's `mkdir`
   all name the same directories.
5. `MACOS_SETUP_zettelkasten.md` has no reference to a second vault, a wall test, or a cloud
   model doing ingests.

On the Mac afterwards: the dry run in section 6 of the setup guide is the real test.

---

## Suggested commits

1. `feat(zettelkasten): single vault schema` — the merged `AGENTS.md`, delete the two old ones.
2. `refactor(zettelkasten): one local Librarian, 5-step ingest` — merge the agents, trim the
   Archivist, update `style.md`.
3. `refactor(zettelkasten): four fish commands, simplify permissions` — `zk.fish`,
   `opencode.jsonc`, `handoff.md`.
4. `docs: rewrite setup guide for the single-vault system` — the setup guide and README.

Delete this plan file in the last commit, or leave it — it's a reasonable record of why the
system shrank.

---

## What must survive this refactor

Easy to lose while deleting. Each of these was either the point of the system or a bug fix that
cost a review round to find:

- **The verbatim-copy rule** in `/handoff`. Goal 2's "version-specific caveats" are worthless if
  a 27B paraphrases the error. This is the most load-bearing prose in the repo.
- **The `style.md` capture nudge.** The only component aimed at the failure that actually
  happened — the user abandoned their first attempt because nothing prompted them to capture.
- **`keywords:` and the frontmatter carry-through.** The retrieval mechanism.
- **The Archivist's stale-caveat warning** and its asking for the user's version.
- **The Archivist's `raw/` handling** — don't cite it, but do list it rather than falling back to
  general knowledge while an un-ingested file holds the answer.
- **`ingested:` stamped last**, with the dedupe check making re-runs safe. This was reverted once
  after being moved early; don't move it again.
- **The frontmatter-only stamp check** in `zk-_pending` (the `sed` expression). A body line
  starting `ingested:` must not mark a file done.
- **`set -l rc $status` before `popd`**, and the `git diff --cached --quiet` polarity.
- **Flat `notes/`** and a short version of why.
