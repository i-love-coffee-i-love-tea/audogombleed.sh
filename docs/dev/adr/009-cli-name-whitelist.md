# ADR-009: CLI-name whitelist + lockdown toggles

Author: i-love-coffee-i-love-tea
Status: Proposed

## Context

ADR-008 removed the security toggles from main because they did not
provide a full security boundary on their own — the commands section
could still invoke arbitrary programs, which defeats the purpose in the use case of downloading untrusted user's configs from the internet and be reasonably safe with them. This ADR proposes a complete
solution: a command whitelist derived from the CLI name, combined with
the security toggles restored from the `security-toggles` branch.

## Proposal

### Command whitelist derived from CLI name

The CLI name (from the symlink) already determines the config file path.
It would also determine the allowed program: `kubectl` only allows
`kubectl`, `git-tools` only allows `git`. No additional configuration
needed — the security boundary is implicit in the name.

A config can define many commands, all invoking the same whitelisted
program:

    [commands]
    pods: kubectl get pods -o wide
    services: kubectl get svc
    restart: kubectl rollout restart deployment/\1
    logs: kubectl logs -f deployment/\1 --tail=50

The whitelist restricts which program can be invoked.
common pattern of wrapping a complex tool into a set of shortcuts.

### Lockdown toggles

Combined with the CLI-name whitelist, security toggles provide a full
lockdown mode:

| Toggle | Default | Effect |
|--------|---------|--------|
| `SAFE_MODE` | `n` | Master switch — enables all restrictions |
| `ALLOW_ENV_CODE` | `y` | When `n`, `[env]` restricted to `VAR=value` |
| `ALLOW_CMD_SHELL_SYNTAX` | `y` | When `n`, no pipes/redirects in commands |
| `ALLOW_CMD_WORD_EXPANSION` | `y` | When `n`, no `&function` expansion |
| `ALLOW_ARG_EXPANSION` | `y` | When `n`, no `:arg:eval:` completions |

With `SAFE_MODE=y` and a CLI-name whitelist, an untrusted config can
only: set variables, and define simple commands using the whitelisted
program. That is a real security boundary.

### Implementation

The toggle code is preserved in the `security-toggles` branch. The
whitelist would be a new feature that validates the program in each
command expression against the CLI name (or a configured override).

## Consequences

- The "download a config from the internet" use case becomes safe with
  `SAFE_MODE=y`
- The `[env]` section is still unrestricted when `ALLOW_ENV_CODE=y`
  (the default), which is acceptable: users define their own helpers

## Changes

- 2026-08-08: i-love-coffee-i-love-tea - initial draft
