## Style

Be terse. No preamble or recap. Don't restate code I can see; show diffs, not whole files.

## User environment

- **Shell**: fish
- **OS**: macOS (darwin)

## Memory

Knowledge wiki: ~/code/Zettelkasten (raw/ = handoffs from /handoff, wiki/ = ingested pages).
Before debugging a tool or library issue: rg -il "<tool>|<error>" ~/code/Zettelkasten/wiki

## Work-specific instructions

Anything tied to an employer — SCM host, CLI conventions, ticket types, runtime and package
policies — belongs in an untracked override, not here. Create
`~/.config/opencode/AGENTS.work.local.md` (gitignored) and add it to `instructions` in
`~/.config/opencode/opencode.json`:

```json
{ "instructions": ["style.md", "AGENTS.work.local.md"] }
```

See `docs/setup-work-machine.md`.
