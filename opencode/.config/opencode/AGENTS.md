## Style

Be terse. No preamble or recap. Don't restate code I can see; show diffs, not whole files.

## User environment

- **Shell**: fish
- **OS**: macOS (darwin)
- **Runtime**: .NET 8 (`net8.0`)

## NuGet packages

- Always verify NuGet package version compatibility with net8.0 before recommending or accepting upgrades.
- Check that the package ships a `lib/net8.0/` or compatible TFM — do not assume netstandard2.0 fallback is safe.

## Git & Source Control

- **SCM**: Bitbucket (not GitHub)
- **CLI tool**: `bb` (Bitbucket CLI, at `/Users/joao.campos/.pyenv/shims/bb`)
- Use `bb` for PRs — never `gh` (GitHub CLI)
- When user says "open PR", use `bb pr create`
- PR create syntax: `bb pr create <PROJECT_KEY> <REPO_SLUG> --title "..." --from-branch "..." --to-branch "..." --description "..."`
- Project key and repo slug inferred from git remote URL: `oakdvcs.dna.fi/projects/<PROJECT_KEY>/repos/<REPO_SLUG>`
- Default target branch: `master`

## Jira

- When creating Jira tickets, issue type is always **PCA story** or **PCA Bug** (never generic Story/Bug).

## Memory

Knowledge wiki: ~/code/Zettelkasten (raw/ = handoffs from /handoff, wiki/ = ingested pages).
Before debugging a tool or library issue: rg -il "<tool>|<error>" ~/code/Zettelkasten/wiki
