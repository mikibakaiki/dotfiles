# Project Guidelines

## Scope

This repository contains personal dotfiles and environment configuration. Keep changes small, platform-aware, and limited to the relevant config files.

## Code Style

Match the style already used in each file. Preserve ordering, comments, indentation, and platform-specific conventions in [README.md](../README.md).

## Conventions

- Treat Windows and Unix shell configs as separate surfaces.
- Preserve Git identity and defaults in [.gitconfig](../.gitconfig) unless the user asks to change them.
- Keep optional PowerShell imports guarded by availability checks in [Microsoft.PowerShell_profile.ps1](../Microsoft.PowerShell_profile.ps1).
- Prefer symlink-friendly updates and avoid hardcoding machine-specific paths unless the file already does so.

## Build and Test

There is no build system. Verify changes manually by checking the affected shell, terminal, or editor configuration and reviewing the diff.
