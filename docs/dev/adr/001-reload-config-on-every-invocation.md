# ADR-001: Reload config on every completion and execution

Author: i-love-coffee-i-love-tea
Status: Accepted

## Context

Every tab completion and every command execution runs the full config
loading pipeline:

1. `_cli_init_global_vars` — reset defaults
2. `_cli_load_config_environment` — parse and execute the `[env]` section
3. `_cli_load_command_word_functions` — call `&function` command words
4. `_cli_read_command_list` — run the AWK config parser

This means the config file (`~/.NAME.conf`) and any `source` or
`include_commands_from` files are re-read on every invocation.

## Decision

Reload the full config on every completion and execution. Cache only
what is safe to cache:

- **AWK script**: cached permanently in a shell variable (it is a
  constant embedded in the source code).
- **Command list** (`_cli_read_command_list`): cached by the config
  file's mtime. If the modification time has not changed, the AWK parse
  is skipped and the previous result is reused.
- **Command structure** (`_cli_read_command_structure`): cached by the
  config file's mtime. Returns command names with `&function`
  placeholders preserved (no function calls).
- **`[env]` section**: NOT cached. Re-executed on every invocation.
- **`&function` command words**: Scoped to the relevant command using
  scoped &function loading. Only the `&function`(s) for the matched
  command are called, not all `&function` entries in the config. See
  ADR-010 for details.

## Rationale

### Why `[env]` is reloaded every time

The `[env]` section is shell code that runs in the current shell
session. It is not a static key-value store — it may reference,
read, or depend on shell variables that change between invocations.

Use cases:

- **Environment-aware config**: an `[env]` entry may reference
  `$KUBECONFIG`, `$RUNTIME_CONTEXT`, or other variables to set
  different completion options depending on the active profile.
  These variables change in the shell as the user switches contexts.
- **Computed variables**: an `[env]` entry may call a command
  (e.g. `` export REPO_ROOT=`git rev-parse --show-toplevel` ``)
  whose output depends on the current working directory.

Caching `[env]` output would mean these changes are invisible until
the cache is invalidated. Since `[env]` entries can depend on
arbitrary shell state, there is no reliable invalidation signal —
mtime of the config file does not capture changes in environment
variables or command output.

### Why `&function` command words are re-called every time

`&function` entries are user-defined shell functions that return
completion options. They are expected to query live state:

- `get_deployments` calling `kubectl get deployments` — picks up
  deployments created since the last completion.
- `get_databases` querying a running database cluster — reflects
  the current inventory.
- `list_branches` calling `git branch` — shows branches including
  ones created by other processes.

The whole point of `&function` entries is that they are dynamic.
Caching their output would defeat this.

### Why the command list IS cached

The AWK-parsed command list is a pure function of the config file
content. It does not depend on shell state, environment variables, or
external systems. The mtime check is a correct invalidation signal:
if the file has not changed, the parse result is the same.

## Alternatives considered

### Cache `[env]` with mtime

Would work for simple `VAR=value` assignments but breaks every use
case where `[env]` entries reference shell variables, call commands,
or source external files.

### Cache everything, invalidate on mtime

Same problem: mtime does not capture changes in environment
variables, sourced files, or external state.

### Cache with TTL (time-based expiry)

Adds a timer mechanism that does not exist in the current codebase.
Would need to work across both bash and zsh, and across sourced vs
direct execution. Does not solve the fundamental problem — there is
no correct TTL for arbitrary shell state.

### One-time load (cache forever)

Breaks the editing workflow. The tool is designed for iterative
config authoring: edit the config, press Tab, see the result.

## Performance

The pipeline runs on every Tab press and every command execution.
The AWK parse (the most expensive step) is skipped when the config
file has not changed. `[env]` loading and `&function` calls always
run.

Performance depends on the config: a minimal config with a few
`VAR=value` entries is fast. A config that sources large files or
calls slow external commands (e.g. `kubectl get pods` over a VPN)
will be slower. This is inherent to the design — the user controls
what runs.

## Script version updates

When the derakht.sh script itself is updated (git pull, package
upgrade), two caches may serve stale data:

1. **AWK script** (`__CLI_AWK_SCRIPT`): cached in a shell variable.
   A new version of the script has a different embedded AWK parser,
   but the in-memory variable still holds the old one. The user must
   re-source the CLI (`source ~/bin/mycli`) for the new AWK parser
   to take effect.

2. **Command list** (`__CLI_CONFIG`): cached by the config file's
   mtime. If only the script changed (not the config), the mtime
   check passes and the old command list is reused — even though the
   new AWK parser might produce different output.

Both issues are resolved by re-sourcing, which is the expected
workflow after updating a sourced script. This is the same as
updating `.bashrc` — changes do not take effect until the next shell
or `source ~/.bashrc`.

The `_cli_read_command_list` cache does not key on the script
version. This is a deliberate simplification — adding a second mtime
check (on the script itself) would add complexity for an edge case
that only occurs once per upgrade and is resolved by re-sourcing.

## Consequences

- Changes to shell variables, sourced files, and external state are
  reflected immediately on the next Tab press.
- No cache invalidation logic needed for `[env]` or functions.
- The AWK parse is skipped when the config file has not changed,
  avoiding the most expensive step during rapid completions.
- After updating the script, the user must re-source for changes to
  take effect. This is standard behavior for sourced scripts.

## Changes

- 2026-08-08: i-love-coffee-i-love-tea - initial draft
- 2026-08-08: i-love-coffee-i-love-tea - accepted
- 2026-08-08: i-love-coffee-i-love-tea - already implemented
