# Vault schema

This file defines the structure and conventions for this vault. The Librarian (`@zettelkasten`)
and the Archivist (`@archivist`) follow it strictly. It lives at the vault root as `AGENTS.md`,
copied from `zettelkasten/AGENTS.md` in the dotfiles repo.

One vault per machine, always at `~/code/Zettelkasten`. The machine decides what is in it — work
content on the work laptop, personal content on the personal desktop. Ticket keys, hostnames and
internal URLs are fine here: the vault holds only what this machine is for, and it never leaves the
machine.

## Directories

```
raw/            Immutable source documents — handoffs written by /handoff. Never edit the body of
                a file here; the only permitted change is adding `ingested: YYYY-MM-DD` to its
                frontmatter. To re-ingest a file after amending it, delete its `ingested:` line.
                Frontmatter MUST open on line 1. The tooling reads only the leading `---` block,
                so a file starting with anything else — a stray "Here is the handoff:" line — has
                no frontmatter it can see, can never be marked done, and would be re-ingested on
                every run. Repairing that is the one other permitted edit; see the Librarian.
wiki/
  index.md      The catalog. Every page in the vault is reachable from here.
  log.md        Append-only record of what was ingested when.
  sources/      One page per ingested raw file — a structured summary of that handoff.
  notes/        Everything else, flat: concepts, tools, services, projects, tickets, people,
                areas. See "Why flat".
```

## Why flat

Retrieval here is search-driven, not browse-driven: the Archivist greps for error strings and reads
`index.md`, so nesting gives it nothing and adds paths to guess wrong. Obsidian's graph and
backlinks are built on `[[wikilinks]]`, not folders. And a five-way taxonomy means five filing
decisions per ingest — that friction is the most common reason personal wikis get abandoned.

Don't pre-plan the split. If `notes/` ever gets big enough that flatness genuinely hurts, split a
subdirectory out then, with the actual pages in front of you.

## Page format

```markdown
---
tags: [lowercase, hyphenated]
sources: [raw-filename-without-extension]
tools: [llama.cpp b6xxx]      # optional, carried from the raw file
keywords: [...]               # optional, carried from the raw file
updated: YYYY-MM-DD
---

# Page Title

Body, with [[wikilinks]] to related pages.

## See Also
- [[related-page]]
```

- `[[wikilinks]]` for every cross-reference. A page with no inbound links is a bug — link it from
  `index.md` at minimum.
- Filenames: lowercase, hyphens for spaces, no dates in the name except in `sources/`.
- A tool's page is named for the tool alone, with punctuation hyphenated and the version dropped:
  `tools: [llama.cpp b6xxx]` gives `wiki/notes/llama-cpp.md`, never `llama.cpp-b6xxx.md`. There is
  one page per tool, holding every version's caveats; the version belongs in the caveat entry.
- `updated` changes whenever the page is edited.
- One subject per page. When unsure whether to create a new page or extend an existing one, extend
  the existing one.
- Carry `tools`, `tags` and `keywords` from the raw file's frontmatter into pages you create from
  it, so exact error strings and version numbers stay greppable. Extend the raw file's `tags`
  rather than inventing a fresh set.
- Written in English. Keep Portuguese terms where they are the natural name for something.

## index.md

Grouped by kind, one line each. Two sections only — ticket and tool pages are notes.

```markdown
## Sources
- [[source-name]] — one-line summary (YYYY-MM-DD)

## Notes
- [[note-name]] — one-line description
```

The date on a `## Sources` line is the handoff's own `date:` — when the session happened — not the
day it was ingested. Every page under `wiki/` appears here exactly once; a page that is updated
rather than created still needs its line, and must not get a second one.

## log.md

Append-only, newest at the bottom:

```markdown
## [YYYY-MM-DD] ingest | <title>
Pages touched: [[page1]], [[page2]]
```

## Ticket pages

One page per ticket key at `wiki/notes/<KEY>.md`, created on the first ingest carrying that key in
its `tickets:` frontmatter. Normal note frontmatter plus `ticket: <KEY>`, then:

```markdown
# PROJ-123

<One-line goal, from the first handoff that mentioned it.>

## Timeline
- YYYY-MM-DD: <what happened> — [[<source-page>]]
```

The timeline date is the handoff's `date:`, so a backlog ingested in one run still reads in the
order things actually happened, and re-running an ingest produces an identical line rather than a
duplicate.

## Version caveats

The highest-value content this vault holds. They live in a `## Version caveats` section inside the
relevant tool's note page (`wiki/notes/llama-cpp.md`), newest first:

```markdown
## Version caveats
- **<version>** on <OS / relevant config>: <symptom, with the verbatim error> → <fix>.
  Verify: <command>. Source: [[<source-page>]]
```

Carry the environment from the handoff's `Env:` line. Without it a macOS-only, Metal-only or
config-specific problem reads as universal, and the Archivist will apply it to a machine it never
affected.

Write the version the handoff actually observed. If later sources show the same problem on more
versions, widen it to a range then — but never guess a range from one observation, because the
Archivist compares that range against the user's version and will confidently apply a caveat that
was only ever seen somewhere else.

Link the source as a bare `[[<source-page>]]`, the same form used everywhere else in this file.
Not `[[sources/<page>]]` — wikilinks resolve against the vault root, so that path form points at
nothing and the caveat loses its only route back to the evidence.

Never paraphrase an error string — the point is that it stays greppable. When a later source shows
an issue fixed, annotate the entry "fixed in <version>" rather than deleting it. A version change
is not a contradiction.
