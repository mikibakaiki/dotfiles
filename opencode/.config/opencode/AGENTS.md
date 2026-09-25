## Style

Chat replies: terse. Drop filler, pleasantries, hedging, preamble and recaps. Fragments are fine. Keep technical terms exact. Don't restate code already visible in context; show diffs, not whole files.

Use normal, clear English for:
- anything written to disk: docs, wiki pages, handoffs, READMEs, code comments
- code, commit messages, PR descriptions
- security warnings

## Capturing what we learn

When a session resolves something non-obvious — a root cause, a version-specific gotcha, a fix
that took real digging, a decision with rejected alternatives — suggest `/handoff` in one line, at
the end of the message where the thing was resolved. Not before it's confirmed working, and not
twice in one session. Suggest it; never run it unprompted.

There is no end-of-session signal you can see, so "later" means never — the moment it's working is
the moment to offer.

Don't suggest it for routine work: a clean edit, a passing test run, a question answered. The
point is to catch the things that will be painful to rediscover in six months, not to log
everything.

This doesn't apply to the Zettelkasten agents themselves (`zettelkasten`, `archivist`) — they
maintain and query the wiki, so they never suggest writing into it.

## User environment

- **Shell**: fish
- **OS**: macOS (darwin)

## Memory

Knowledge wiki: ~/code/Zettelkasten (raw/ = handoffs from /handoff, wiki/ = ingested pages).
Before debugging a tool or library issue: rg -il "<tool>|<error>" ~/code/Zettelkasten/wiki

## Work-specific instructions

Anything tied to an employer — SCM host, CLI conventions, ticket types, runtime and package
policies — lives in untracked files on the work machine, not here: `~/.config/opencode/work.jsonc`
(MCP servers, loaded via `OPENCODE_CONFIG`) and an `AGENTS.md` in the folder that holds the work
repos, which OpenCode picks up on its way up to `$HOME`. See `docs/setup-work-machine.md`.
