# ADR-004: CLI name derived from symlink filename

Author: i-love-coffee-i-love-tea
Status: Accepted

## Context

The tool needs a name. Users may want different CLIs for different
purposes (e.g. `tf` for terraform shortcuts, `k` for kubectl, `deploy`
for deployment scripts). Each CLI has its own config file and completion
function.

## Decision

Derive the CLI name from the symlink filename. One script serves as many
CLIs as the user creates symlinks for.

```
ln -s ~/bin/audogombleed.sh ~/bin/tf
ln -s ~/bin/audogombleed.sh ~/bin/k
ln -s ~/bin/audogombleed.sh ~/bin/deploy
```

Each symlink resolves to a different config file (`~/.tf.conf`,
`~/.k.conf`, `~/.deploy.conf`) and registers its own tab completion
function. The name is extracted from `$BASH_SOURCE[0]` (bash) or `$0`
(zsh) at source time.

## Rationale

- No registration mechanism, no global state, no shared config. Each
  symlink is an independent CLI.
- The user creates a CLI by creating a symlink and a config file. No
  code changes, no plugins, no build step.
- Multiple CLIs can coexist in the same shell session without
  interference — each has its own `__CLI_PROGNAME` namespace for
  variables and its own completion function.

## Validation

The CLI name is validated to contain only letters, digits, and
underscores (`_cli_validate_progname`). Dots and dashes are rejected
because they break aliases and variable names.

## Consequences

- The script must not be called directly as `audogombleed.sh` — it
  detects this case and prints setup instructions.
- The symlink name is the CLI's identity for its entire lifetime.
  Renaming the CLI means creating a new symlink and config file.

## Changes

- 2026-08-08: i-love-coffee-i-love-tea - initial draft
- 2026-08-08: i-love-coffee-i-love-tea - accepted
- 2026-08-08: i-love-coffee-i-love-tea - already implemented
