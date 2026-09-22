---
description: Write a raw Zettelkasten handoff of this session to the Zettelkasten raw/ folder
model: llamacpp/qwen3.8-27b-local
---

You are writing a session handoff for the Zettelkasten wiki. Be terse and concrete.

You run on a local model regardless of what model the session itself used, to keep this write-up
off Copilot billing. This makes verbatim accuracy your job, not a given: when copying an error
message, config value, flag, or version string into the handoff, copy it character-for-character
from the session content — never paraphrase, reformat, or "clean up" a verbatim string. A slightly
reworded error message is useless for the grep-based search this wiki depends on.

**If you cannot find the exact string, write `<not captured>`.** Never reconstruct one from memory.
An honest gap is useful; a plausible-looking invented error string is worse than nothing, because
it will be trusted and it will never match a search.

## Step 1: Read the session

Use `session_read` for the current session's full history (use `session_list` to find it if
needed). This matters because context may have been pruned.

If the history is too large to read at once, read it in parts and prioritise the last two-thirds —
the resolution is usually near the end. Set `partial: true` in the frontmatter whenever you could
not see the whole session, for any reason: the tools don't exist, the history was too big, or it
had already been pruned. When you set it, say in `## Open / Watch Out` which part you could not
see, so a later reader knows what this handoff is missing.

## Step 2: Extract

- **Tickets**: any ticket keys (PROJ-123, GitHub #123) with their goal. Optional.
- **What we did**: files, commands, configs, endpoints. At most five bullets — concrete artifacts
  only, no narrative recap.
- **Problems & resolutions**: symptom, root cause, fix, and how to verify the fix. Copy error
  messages **verbatim**. Record the **tool + exact version** involved.
  Take the version from the session content. Only run `<tool> --version` if it appears nowhere in
  the session, and if you do, label it as the version *now* — a session that fixed something by
  upgrading will report the version that no longer has the problem, which files the caveat against
  the wrong one.
- **Decisions**: what was chosen, what was rejected, and why.
- **Open items / watch-outs.**

**Secrets only:** API keys, tokens, passwords, cookies, auth headers, and connection strings
containing credentials. Replace the secret value itself with `<redacted>` and keep everything
around it intact — `Authorization: Bearer <redacted>`.

Hostnames, absolute paths, usernames, internal URLs and ticket keys are **not** secrets here. This
vault is local to this machine and its schema explicitly keeps them. Never redact inside an error
string except for a literal credential: a redacted error is unsearchable, which defeats the point
of writing it down at all.

## Step 3: Filename

`<ticket-or-topic-slug>-<YYYY-MM-DD>.md` in kebab-case, using today's date. Get today's date by
running `date +%F` — do not infer it. If the file exists, append `-2`, `-3`.
Folder: `~/code/Zettelkasten/raw/`. If OpenCode asks for permission to write there, that's expected.

## Step 4: Write

Omit empty sections.

Before writing each `Symptom`, `Env`, and `keywords` entry, find the exact string in the session
history and copy it. If it isn't there, write `<not captured>`.

```markdown
---
date: YYYY-MM-DD
tickets: [PROJ-123]
tools: [llama.cpp b6xxx, opencode 1.x, fish 4.x]
tags: [<topic>, <topic>]
keywords: [<literal strings copied from the body — see below>]
---

# <Ticket — Title> or <Topic>

## Goal
<One or two lines.>

## What We Did
- <concrete item, with file/command>

## Problems & Resolutions
### 1. <title>
**Symptom:** the error exactly as it appeared — every line, original spacing and quoting:
```
<verbatim error output>
```
**Env:** <tool + version, OS, relevant config>
**Tried and rejected:** <what didn't work, and the error it gave — omit if nothing was tried>
**Root cause:** <why — or `not established` if the session never actually determined it>
**Fix:** <what was done>
**Verify:** `<a command that was actually run and showed the fix working — omit otherwise>`

## Decisions
- **<decision>**: <why; alternatives rejected>

## Files Changed
| File | Change |
| ---- | ------ |

## Open / Watch Out
- <follow-ups, caveats, version-specific gotchas>
```

**`keywords:` is the retrieval mechanism.** Every entry must be a literal substring that appears in
this file's body: error fragments, flag spellings (`--no-cache`), config keys, version strings,
symbol names. No topic words and no categories — those go in `tags:`. If an entry wouldn't appear
verbatim in a terminal, it belongs in `tags:`, not here. A keyword list of generic words looks
populated and matches nothing.

**Don't invent `Root cause` or `Verify`.** These are the two fields most likely to be filled in
with something plausible that never happened. A handoff that says `not established` is honest and
still useful; an invented verify command becomes a wiki caveat the Archivist will cite with
confidence.

## Step 5: Report

Reply with the path and the frontmatter you wrote, nothing else:

> Written: `<full path>`
>
> ```
> tickets: [...]
> tools: [...]
> tags: [...]
> keywords: [...]
> partial: <true if set, otherwise omit this line>
> ```

Echoing the frontmatter lets the user check the keywords — which decide whether this is findable
later — without opening the file. Then `zk-ingest` picks it up.

$ARGUMENTS
