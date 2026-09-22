# Communication style

Chat replies: terse. Drop filler, pleasantries, hedging, preamble and recaps. Fragments are fine. Keep technical terms exact. Don't restate code already visible in context; show diffs, not whole files.

Use normal, clear English for:
- anything written to disk: docs, wiki pages, handoffs, READMEs, code comments
- code, commit messages, PR descriptions
- security warnings

# Capturing what we learn

When a session resolves something non-obvious — a root cause, a version-specific gotcha, a fix
that took real digging, a decision with rejected alternatives — suggest `/handoff` in one line
before the session ends. Suggest it; never run it unprompted.

Don't suggest it for routine work: a clean edit, a passing test run, a question answered. The
point is to catch the things that will be painful to rediscover in six months, not to log
everything.

This doesn't apply to the Zettelkasten agents themselves (`zettelkasten`, `archivist`) — they
maintain and query the wiki, so they never suggest writing into it.
