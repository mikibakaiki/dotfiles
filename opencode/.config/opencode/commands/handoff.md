---
description: Create a Zettelkasten raw summary of this session — what was done, problems faced, decisions made — and write it to ~/code/Zettelkasten/raw/
---

You are writing a session handoff summary for the personal Zettelkasten wiki.

## Step 1: Read the session

Use the `session_read` tool to read the current session's full message history. If the session ID is not known, use `session_list` to find the most recent session.

## Step 2: Extract these items from the conversation

- **Jira tickets**: Any PROJ-XXX, or similar ticket keys mentioned. For each, note the title/goal if discussed.
- **What we did**: A clear summary of the work completed. Be concrete — mention files changed, features added, configs updated.
- **Problems & resolutions**: Every issue, error, or blocker encountered, and exactly how it was resolved. Include root causes where known.
- **Reasoning & decisions**: Why we chose one approach over another. Trade-offs discussed. Things we decided NOT to do and why.
- **Files changed**: If code was written, list the key files and what changed.
- **Anything else notable**: Discoveries, surprises, things to watch out for, follow-up items left open.

## Step 3: Determine filename

- If one or more Jira tickets were the primary focus: `<ticket-slug>-<YYYY-MM-DD>.md` (e.g. `proj-123-2026-06-17.md`)
- If multiple unrelated tickets: use the dominant one or a topic slug
- If no ticket (config work, research, tooling): derive a short kebab-case slug from the session topic (e.g. `omo-install-2026-07-09.md`)
- Date: today's date in YYYY-MM-DD format

## Step 4: Write the file

Write to `~/code/Zettelkasten/raw/<filename>`.

Use this structure (omit sections that don't apply):

```markdown
# <Ticket> — <Title> (or just # <Topic> if no ticket)

## Ticket

**Key:** <ticket key>
**Summary:** <one-line description>
**Status:** <status if known>

### Goal

<What the ticket was asking for, in plain language.>

---

## What We Did

<Concrete summary of work completed. Mention specific files, endpoints, configs, commands.>

---

## Problems & Resolutions

### 1. <Problem title>

**Problem:** <What went wrong or was unclear.>
**Root cause:** <Why it happened.>
**Fix:** <What was done to resolve it.>

(repeat for each problem)

---

## Reasoning & Decisions

- **<Decision>**: <Why this approach was chosen. What was considered and rejected.>

(one bullet per significant decision)

---

## Files Changed

| File           | Change      |
| -------------- | ----------- |
| `path/to/file` | Description |

---

## Notes

<Follow-up items, open questions, things to watch out for, discoveries worth remembering.>
```

## Step 5: Report

Tell the user the full path of the file written. Keep it to one line:

> Written: `~/code/Zettelkasten/raw/<filename>`

The file is intentionally left as raw markdown for the user to amend before running `@zettelkasten` to ingest it into the wiki.
