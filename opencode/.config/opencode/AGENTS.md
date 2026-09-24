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
policies — lives in untracked files on the work machine, not here: `~/.config/opencode/work.jsonc`
(loaded via `OPENCODE_CONFIG`) and the `AGENTS.work.local.md` it lists. See
`docs/setup-work-machine.md`.
