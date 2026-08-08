# ADR-008: Remove safe mode toggles

Author: i-love-coffee-i-love-tea
Status: Accepted
Note: Toggle code preserved in `security-toggles` branch for future whitelist integration.

Supersedes [005](005-safe-mode-toggles.md) and
[007](007-safety-toggles-shell-env-only.md).

## Context

The config file is shell code. It defines commands that execute arbitrary
programs, source external files, call user-defined functions, and eval
expressions. The `[env]` section is sourced into the running shell on every
tab completion and every command execution.

ADR-005 introduced a layered security model with five toggles
(`SAFE_MODE`, `ALLOW_ENV_CODE`, `ALLOW_CMD_SHELL_SYNTAX`,
`ALLOW_CMD_WORD_EXPANSION`, `ALLOW_ARG_EXPANSION`) that gate different
dynamic code execution paths. ADR-007 moved these toggles out of the config
file into shell environment variables, so an untrusted config cannot disable
them.

## Problem

The toggles block some dynamic code execution paths — `[env]` shell code,
`&function` expansion, `:arg:eval:` completions, shell metacharacters in
command expressions — but the commands themselves can do anything. A config
that passes all toggle checks can still define `rm -rf /` as a command
expression.

The toggles alone are not a security boundary.
They do not make an untrusted config safe.

## Decision

Remove the toggles from main for now. They add complexity without providing
the full boundary on their own. See [009](009-cli-name-whitelist.md) for
the proposed future approach that completes the security model.

## Changes

- 2026-08-08: i-love-coffee-i-love-tea - initial draft
- 2026-08-08: i-love-coffee-i-love-tea - accepted
- 2026-08-08: i-love-coffee-i-love-tea - implemented
