# Vault schema — personal

This file defines the structure and conventions for this vault. The Personal Librarian
(`@zettelkasten-personal`) and the Archivist follow it strictly. Copy it to the vault root as
`AGENTS.md`.

## Directories

```
raw/            Immutable source documents — handoffs written by /handoff. Never edit the body
                of a file here; the only permitted change is adding `ingested: YYYY-MM-DD` to
                its frontmatter.
wiki/
  index.md      The catalog. Every page in the vault is reachable from here.
  log.md        Append-only record of what was ingested when.
  sources/      One page per ingested raw file — a structured summary of that handoff.
  notes/        Everything else: concepts, services, people, projects, areas, and general
                notes about a tool (what it is, how you use it, how it's configured).
                One flat directory, deliberately (see "Why flat" below).
                Version-specific caveats do NOT go here — they go in `tools/`. A page about
                how you run llama.cpp is `notes/llama-cpp.md`; "b6xxx broke the prompt cache
                with <this error>" is an entry in `tools/llama-cpp.md`.
  tickets/      One rollup page per ticket key, with a running timeline.
tools/          One page per tool, each with a `## Version caveats` section.
                Shared with the work vault — see "The tools/ folder".
```

## Why flat

`notes/` is one directory rather than the usual `concepts/` + `entities/` + `projects/` +
`areas/` split. This is a deliberate choice, not an oversight:

- Retrieval here is search-driven, not browse-driven. The Archivist greps for error strings and
  reads `index.md`; directory nesting gives it nothing and adds paths to guess wrong.
- Obsidian's graph view and backlinks are built on `[[wikilinks]]`, not folders. Deep folder
  trees tend to *reduce* linking, because people navigate the tree instead.
- On a small vault, a five-way taxonomy means five filing decisions per ingest. That friction
  is the most common reason personal wikis get abandoned.

**Promotion rule:** when `notes/` exceeds roughly 75 pages *and* a cluster of 10+ related pages
is obvious, promote that cluster to its own directory (`notes/homelab/`, etc.) and update this
file. Promote on evidence, never in advance.

## Page format

Every page under `wiki/` uses this frontmatter:

```markdown
---
tags: [lowercase, hyphenated]
sources: [raw-filename-without-extension]
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# Page Title

Body, with [[wikilinks]] to related pages.

## See Also
- [[related-page]]
```

Rules:
- `[[wikilinks]]` for every cross-reference. A page with no inbound links is a bug — link it
  from `index.md` at minimum.
- Filenames: lowercase, hyphens for spaces, no dates in the name except in `sources/`.
- `updated` changes whenever the page is edited.
- One subject per page. When unsure whether to create a new page or extend an existing one,
  extend the existing one.
- Carry `facet`, `tools`, `tags` and `keywords` from the raw file's frontmatter into pages you
  create from it, so exact error strings and version numbers stay greppable. Extend the raw
  file's `tags` rather than inventing a fresh set.
- Written in English. Keep Portuguese terms where they are the natural name for something.

## index.md

Grouped by kind, one line each:

```markdown
## Sources
- [[source-name]] — one-line summary (YYYY-MM-DD)

## Notes
- [[note-name]] — one-line description

## Tickets
- [[TICKET-KEY]] — one-line description, status

## Tools
- tools/tool-name.md — one-line description
```

Tool pages are listed as plain paths, not `[[wikilinks]]` — see below for why.

## log.md

Append-only, newest at the bottom:

```markdown
## [YYYY-MM-DD] ingest | <title>
Pages touched: [[page1]], [[page2]]
```

## tickets/

One page per ticket key (`wiki/tickets/PROJ-123.md`), created on the first ingest that carries
that key in its `tickets:` frontmatter:

```markdown
---
ticket: PROJ-123
status: open | closed | unknown
created: YYYY-MM-DD
updated: YYYY-MM-DD
---

# PROJ-123

<One-line goal, from the first handoff that mentioned it.>

## Timeline
- YYYY-MM-DD: <what happened> — sources/<source-page>
```

`status` only changes when a session explicitly says the ticket closed or reopened. Never infer
it from anything else; `unknown` is an honest answer.

## The tools/ folder

One page per tool (`tools/llama-cpp.md`, kebab-case), holding version-specific caveats:

```markdown
## Version caveats
- **<version range>**: <symptom, with the verbatim error> → <fix>. Verify: <command>.
  Source: personal: sources/<page>
```

When a later source shows an issue fixed, annotate the entry with "fixed in <version>" rather
than deleting it. A version change is not a contradiction.

Two things make this folder different from the rest of the vault:

1. **It is shared with the work vault.** The Work Librarian — which runs on a cloud model —
   reads and writes it. So it holds public-grade technical facts only: no ticket keys, company,
   client or colleague names, internal hostnames, IPs, URLs, repo paths, credentials, or
   personal details. Generalise ("a work repo", "a home server"), or keep the caveat out of the
   shared page and put it in your own `wiki/sources/` page instead.
2. **Links into it don't resolve from the work vault**, since that's a separate Obsidian vault.
   Reference tool pages as plain text (`tools/llama-cpp.md`), not `[[wikilinks]]`, so the
   convention is identical from both sides.

It starts empty and stays empty until a real caveat appears. Don't create placeholder pages for
tools that haven't caused a problem yet — an empty `tools/` is the correct state for a new vault,
and if it's still nearly empty in six months, that is useful evidence that the shared-folder idea
isn't earning its complexity.
