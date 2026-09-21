# Vault schema — work

This file defines the structure and conventions for this vault. The Work Librarian
(`@zettelkasten`) and the Archivist follow it strictly. Copy it to the vault root as `AGENTS.md`.

This is the work vault. It is a separate git repo from the personal vault and holds nothing but
work content, so it can be left behind or deleted outright when the job ends, without touching
anything you keep.

## Directories

```
raw/            Immutable source documents — handoffs written by /handoff with `facet: work`.
                Never edit the body of a file here; the only permitted change is adding
                `ingested: YYYY-MM-DD` to its frontmatter.
                To re-ingest a file after amending it, delete its `ingested:` line.
wiki/
  index.md      The catalog. Every page in the vault is reachable from here.
  log.md        Append-only record of what was ingested when.
  sources/      One page per ingested raw file — a structured summary of that handoff.
  notes/        Everything else: concepts, services, systems, projects, areas.
                One flat directory, deliberately (see "Why flat" below).
  tickets/      One rollup page per ticket key, with a running timeline.
```

There is **no local `tools/` directory in this vault.** Tool and version caveats are written to
the shared folder in the personal vault — see "Tool caveats" below.

## Why flat

`notes/` is one directory rather than a `concepts/` + `entities/` + `projects/` + `areas/` split.
This is deliberate:

- Retrieval here is search-driven, not browse-driven. The Archivist greps for error strings and
  reads `index.md`; directory nesting gives it nothing and adds paths to guess wrong.
- Obsidian's graph view and backlinks are built on `[[wikilinks]]`, not folders. Deep folder
  trees tend to *reduce* linking, because people navigate the tree instead.
- A five-way taxonomy means five filing decisions per ingest. That friction is the most common
  reason personal wikis get abandoned.

**Promotion rule:** when `notes/` exceeds roughly 75 pages *and* a cluster of 10+ related pages
is obvious, promote that cluster to its own directory and update this file. Promote on evidence,
never in advance.

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
- Ticket keys, system names, hostnames and internal URLs are fine here — this vault is work-only
  and never leaves the work machine. Keep them **out** of the shared `tools/` pages (below).

## index.md

Grouped by kind, one line each:

```markdown
## Sources
- [[source-name]] — one-line summary (YYYY-MM-DD)

## Notes
- [[note-name]] — one-line description

## Tickets
- [[TICKET-KEY]] — one-line description, status
```

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

## Tool caveats

Tool and version caveats do **not** go in this vault. They go to the shared folder in the
personal vault: `~/code/Zettelkasten/tools/<tool>.md`, kebab-case, each with a
`## Version caveats` section:

```markdown
## Version caveats
- **<version range>**: <symptom, with the verbatim error> → <fix>. Verify: <command>.
  Source: work: sources/<page>
```

Check whether the page already exists before creating it — the Personal Librarian may have
written it first. When a later source shows an issue fixed, annotate the entry with
"fixed in <version>" rather than deleting it. A version change is not a contradiction.

That folder is the only path outside this vault the Work Librarian can reach, and it is read by
both a cloud model and a local one. It therefore holds **public-grade technical facts only**: no
ticket keys, company, client or colleague names, internal hostnames, IPs, URLs, repo paths,
credentials, or personal details. Generalise ("a work repo", "a home server"), or leave the
caveat out of the shared page entirely and keep it in this vault's `wiki/sources/` page instead.

Links from this vault into `tools/` will not resolve — it is a separate Obsidian vault. Reference
tool pages as plain text (`tools/llama-cpp.md`), never as `[[wikilinks]]`.
