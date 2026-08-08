# ADR-007: Safety toggles are shell-environment-only, not config-settable

Author: i-love-coffee-i-love-tea
Status: Superseded by [008](008-remove-safe-mode-toggles.md)

## Context

Safety toggles (`SAFE_MODE`, `ALLOW_ENV_CODE`, `ALLOW_CMD_SHELL_SYNTAX`,
`ALLOW_CMD_WORD_EXPANSION`, `ALLOW_ARG_EXPANSION`) control whether the
tool executes dynamic code from the config file. They were originally
settable in the `[env]` section of the config file alongside other
settings.

The problem: the config file is the thing being protected against. If
an untrusted config can set `__CLI_CFG_SAFE_MODE=n`, the safety toggles
are meaningless — the thing you're defending against controls the
defenses.

## Decision

Move safety toggles out of the config file. They can only be set via
shell variables in `.bashrc` / `.zshrc`. The config file is rejected if
it attempts to assign them.

Two levels of env var, checked in priority order:

1. **Global** — `__CLI_SAFE_MODE` (applies to all CLIs)
2. **Per-CLI** — `__CLI_mycli_SAFE_MODE` (applies to one CLI)
3. **Default** — hard-coded in the script

The config file cannot set these at all.

## Rationale

### Threat model

The user downloads or copies a config file from an untrusted source
(e.g. a shared repository, a blog post, a colleague). The config may
contain:

- Malicious `[env]` entries that run arbitrary code
- `source` directives that load attacker-controlled files
- Command expressions designed to exfiltrate data or damage the system

The safety toggles are the user's defense. If the config can disable
them, there is no defense.

### Why shell variables

Everything runs in the current shell (by design — the tool is sourced).
Shell variables set in `.bashrc` are under the user's control and cannot
be modified by the config file. The config file's `[env]` section runs
after `.bashrc`, so it could theoretically overwrite variables — but the
tool rejects safety toggle assignments in `[env]` and restores the
original values after config loading as defense-in-depth.

### Why not a separate config file

A separate safety config file (e.g. `~/.mycli.safe.conf`) would add a
second file to manage and a path resolution mechanism. Shell variables
are simpler — the user already has `.bashrc`, and `export` is
well-understood.

### Global vs per-CLI

Global `__CLI_SAFE_MODE` protects all CLIs regardless of symlink name.
Per-CLI `__CLI_mycli_SAFE_MODE` protects a specific CLI. This allows
the user to lock down individual CLIs they download configs for, while
keeping other CLIs unrestricted.

Global takes precedence over per-CLI, so the user can set a global
default and override for specific CLIs.

## Defense in depth

Two layers protect against the config file circumventing the toggles:

1. **Rejection** — `_cli_load_config_environment()` checks every
   `__CLI_CFG_*` assignment. If the variable name is a safety toggle,
   the assignment is rejected with an error message.

2. **Save-restore** — after config loading, the tool restores safety
   toggle values to what they were before the config was loaded. This
   catches indirect injection (e.g. a `source` directive that sets the
   variable).

## Consequences

- Existing configs that set safety toggles in `[env]` will produce
  errors on load. Users must move these settings to `.bashrc`.
- The config file has no control over safety settings. This is the
  point.
- Per-CLI vars are keyed on the symlink name. This is documented
  behavior — the user controls the names of their symlinks.

## Changes

- 2026-08-08: i-love-coffee-i-love-tea - initial draft
- 2026-08-08: i-love-coffee-i-love-tea - accepted
- 2026-08-08: i-love-coffee-i-love-tea - superseded by [008](008-remove-safe-mode-toggles.md)
