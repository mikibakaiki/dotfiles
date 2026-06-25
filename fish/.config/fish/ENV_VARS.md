# Fish Environment Variables Guide

Documents every custom variable in this config: where it lives, why, and how to manage it.

## How secrets work

Two files are **never committed to git**. They live only on your machine:

- `~/.config/fish/conf.d/.env.personal` — personal API keys (Anthropic, GitHub personal token, etc.)
- `~/.config/fish/conf.d/.env.work` — work URLs, tokens, anything job-specific

At shell startup, `30-env-secrets.fish` (which IS tracked) reads both files and exports
every key it finds. Format inside `.env` files:

```
KEY=value
KEY="value with spaces"
# comments are ignored
export KEY=value    # export keyword is handled
```

On a fresh machine, copy the examples and fill in real values:

```fish
cp ~/.config/fish/conf.d/.env.personal.example ~/.config/fish/conf.d/.env.personal
cp ~/.config/fish/conf.d/.env.work.example     ~/.config/fish/conf.d/.env.work
```

---

## File map

| File                           | Tracked in git | Purpose                                 |
| ------------------------------ | -------------- | --------------------------------------- |
| `config.fish`                  | ✓              | XDG, homebrew, PATH, editor, pager      |
| `conf.d/20-env-public.fish`    | ✓              | Non-sensitive env vars (currently none) |
| `conf.d/30-env-secrets.fish`   | ✓              | Loader only — reads `.env.*` files      |
| `conf.d/.env.personal`         | ✗              | Personal keys — create per machine      |
| `conf.d/.env.work`             | ✗              | Work keys + URLs — create per machine   |
| `conf.d/.env.personal.example` | ✓              | Template showing expected personal keys |
| `conf.d/.env.work.example`     | ✓              | Template showing expected work keys     |
| `conf.d/90-path-dedupe.fish`   | ✓              | Deduplicates PATH entries, runs last    |
| `conf.d/aliases.fish`          | ✓              | Abbreviations and aliases               |
| `conf.d/fnm.fish`              | ✓              | fnm (Node version manager) init         |
| `conf.d/fzf.fish`              | ✓              | fzf config and key bindings             |
| `conf.d/prompt.fish`           | ✓              | Starship init                           |
| `conf.d/pyenv.fish`            | ✓              | pyenv init                              |

---

## Current variables

### Personal (`.env.personal`)

| Variable            | Purpose                    |
| ------------------- | -------------------------- |
| `ANTHROPIC_API_KEY` | Claude / opencode          |
| `GITHUB_TOKEN`      | Personal GitHub API access |

### Work (`.env.work`)

| Variable               | Purpose                          |
| ---------------------- | -------------------------------- |
| `JIRA_BASE_URL`        | Jira instance URL                |
| `CONFLUENCE_BASE_URL`  | Confluence instance URL          |
| `JENKINS_BASE_URL`     | Jenkins instance URL             |
| `BITBUCKET_BASE_URL`   | Bitbucket instance URL           |
| `ARTIFACTORY_BASE_URL` | Artifactory instance URL         |
| `JIRA_PAT`             | Jira personal access token       |
| `CONFLUENCE_PAT`       | Confluence personal access token |
| `BITBUCKET_TOKEN`      | Bitbucket API token              |
| `JENKINS_TOKEN`        | Jenkins API token                |
| `ARTIFACTORY_TOKEN`    | Artifactory token                |

---

## Useful commands

### Inspect

```fish
env | sort                          # all exported vars
set -S VAR_NAME                     # detail for one var (scope, value, origin)
rg "set -gx" ~/.config/fish         # find all var definitions in config
```

### Add a new variable

1. Decide: is it a secret or work-specific? → `.env.personal` or `.env.work`
2. Add `KEY=value` to the right `.env` file
3. Add a row to the table above in this file
4. Reload: `source ~/.config/fish/conf.d/30-env-secrets.fish`

### Reload after edits

```fish
# Reload everything
for f in ~/.config/fish/conf.d/*.fish; source $f; end

# Reload just secrets
source ~/.config/fish/conf.d/30-env-secrets.fish
```

### Token rotation

```fish
# 1. Edit the .env file
zed ~/.config/fish/conf.d/.env.work

# 2. Reload
source ~/.config/fish/conf.d/30-env-secrets.fish

# 3. Verify
set -S JIRA_PAT

# 4. Open a new terminal to confirm clean state
```

### Remove a variable

```fish
set -e VAR_NAME                     # removes from current session
# also remove the line from .env.personal or .env.work
```
