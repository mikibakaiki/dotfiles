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

## Step 1: Read the session

Use `session_read` for the current session's full history (use `session_list` to find it if needed). This matters because context may have been pruned. If these tools don't exist, work from your current context and add `partial: true` to the frontmatter.

## Step 2: Extract

- **Tickets**: any ticket keys (PROJ-123, GitHub #123) with their goal. Optional.
- **What we did**: files, commands, configs, endpoints.
- **Problems & resolutions**: symptom, root cause, fix, and how to verify the fix. Copy error messages **verbatim**. Record the **tool + exact version** involved (run `<tool> --version` if unknown and cheap).
- **Decisions**: what was chosen, what was rejected, and why.
- **Open items / watch-outs.**

Never include secrets, tokens, credentials, personal data, or internal hostnames/URLs; write `<redacted>` instead.

## Step 3: Filename

`<ticket-or-topic-slug>-<YYYY-MM-DD>.md` in kebab-case, using today's date. If the file exists, append `-2`, `-3`.
Folder: `~/code/Zettelkasten/raw/`. If OpenCode asks for permission to write there, that's expected.

## Step 4: Write

Omit empty sections.

```markdown
---
date: YYYY-MM-DD
tickets: [PROJ-123]
tools: [llama.cpp b6xxx, opencode 1.x, fish 4.x]
tags: [<topic>, <topic>]
keywords: [<exact error fragments, flags, config keys worth grepping>]
---

# <Ticket — Title> or <Topic>

## Goal
<One or two lines.>

## What We Did
- <concrete item, with file/command>

## Problems & Resolutions
### 1. <title>
**Symptom:** `<verbatim error>`
**Env:** <tool + version, OS, relevant config>
**Root cause:** <why>
**Fix:** <what was done>
**Verify:** `<command that shows it's fixed>`

## Decisions
- **<decision>**: <why; alternatives rejected>

## Files Changed
| File | Change |
| ---- | ------ |

## Open / Watch Out
- <follow-ups, caveats, version-specific gotchas>
```

## Step 5: Report

Reply with the path and the frontmatter you wrote, nothing else:

> Written: `<full path>`
>
> ```
> tickets: [...]
> tools: [...]
> tags: [...]
> keywords: [...]
> ```

Echoing the frontmatter lets the user check the keywords — which decide whether this is findable
later — without opening the file. Then `zk-ingest` picks it up.

$ARGUMENTS
