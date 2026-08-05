# Shell Compatibility

This document covers bash/zsh differences relevant to both users and
contributors. It describes what runs in the user's shell, what runs in a
subprocess, and where the script branches for shell-specific behavior.

## Execution model

The script has two entry points depending on how it is invoked:

### Sourced (registration only)

When the user runs `source ~/bin/mycli`, the script:

1. Detects it is sourced (`_cli_is_sourced`)
2. Sets `__CLI_PROGNAME` from the symlink name
3. Registers the tab-completion function (`complete -F` in bash, `compdef` in zsh)
4. Returns — no commands are executed

This always runs in the **current shell**. That is how completion functions
and `[env]` definitions become available to the shell.

### Executed (command handling)

When the user runs `mycli some-command`, two paths are possible:

| | No alias (`mycli cmd`) | With alias (`alias mycli='_cli_execute'`) |
|--|------------------------|------------------------------------------|
| Entry point | Script runs as subprocess, calls `_cli_execute "$@"` | `_cli_execute` runs directly in current shell |
| `[env]` section | Sourced in subprocess | Sourced in current shell |
| Command execution | `eval` in subprocess | `eval` in current shell |
| `cd` / `export` | no effect on user's shell | affects user's shell |
| User's shell functions | not available to commands | available to commands |

**Tab completion always runs in the current shell** regardless of mode.
The completion function is registered via `source` and invoked by the
shell's completion system directly.

## Bash/zsh differences in the script

### Variable indirection

Reading a variable by name (e.g. `__CLI_mycli_CFG_EXEC_SILENT`) requires
different syntax:

- Bash: `${!var_name}`
- Zsh: `${(P)var_name}`

Used in: `_cli_global`, `_cli_global_equals`, `_cli_global_is_positive_bool`,
`_cli_global_is_negative_bool`, `_cli_global_is_log_level`.

### Array splitting

Reading the AWK command list into an array:

- Bash: `mapfile -t __CLI_CONFIG < <(_awk ...)`
- Zsh: `__CLI_CONFIG=("${(@f)$(_awk ...)}")`

Used in: `_cli_read_command_list`.

### Extended globbing

Collapsing multiple spaces in help output:

- Bash: `shopt -s extglob` then `${1//+([ ])/ }`
- Zsh: `setopt extendedglob` then `${1// ##/ }`

Used in: `_cli_collapse_spaces`.

### Word splitting

Zsh does not word-split unquoted variable expansion by default. The script
uses `setopt SH_WORD_SPLIT` at specific call sites where this is needed.
See [SH_WORD_SPLIT requirement](#sh_word_split-requirement) below.

### Completion registration

- Bash: `complete -F _cli_complete_ "$__CLI_PROGNAME"`
- Zsh: `compdef _cli_complete_ "$__CLI_PROGNAME"`

Zsh requires `compinit` to be loaded first (user must add `autoload
bashcompinit; bashcompinit` to `.zshrc`).

### Sourcing detection

Detecting whether the script was sourced or executed directly:

- Bash: checks `BASH_SOURCE[0]` against `$0`
- Zsh: checks `$zsh_eval_context` for the `file` token

### Argument splitting for help

Splitting `cmd_args` into an array for last-argument detection:

- Bash: `read -a a_cmd_args <<<"$cmd_args"`
- Zsh: `a_cmd_args=("${(z)cmd_args}")`

### Completion descriptions

Zsh supports `[description]` suffixes in completion candidates. Bash does
not. The script adds descriptions via `_values` in zsh completions.

### Array iteration in completions

Reading completion results into `COMPREPLY`:

- Bash: `mapfile -t COMPREPLY < <(_awk ...)`
- Zsh: `COMPREPLY=("${(@f)$(_awk ...)}")`

## `SH_WORD_SPLIT` requirement

Zsh does not word-split unquoted variable expansion by default (bash does).
The script uses `setopt SH_WORD_SPLIT` at specific call sites where
word splitting is required. If you add or modify code that passes an
unquoted variable to a function expecting multiple arguments (space-separated
words), you must enable `SH_WORD_SPLIT` at the call site.

### Affected code paths

| Call site | Function | Why word splitting is needed |
|-----------|----------|------------------------------|
| `_cli_load_config_environment` — `include_commands_from` handler | `_cli_remove_first_word`, `_cli_get_first_word`, `_cli_get_last_word` | Parses `include_commands_from <file> <parent>` into its three words |
| `_cli_execute` — help output path | `_cli_remove_last_word` | Strips the `?`/`-h` argument to get the command path for help display |

### Pattern

Save and restore the option around the affected block:

```bash
local _had_shwordsplit=false
_cli_shell_is_zsh && { [[ -o SH_WORD_SPLIT ]] && _had_shwordsplit=true || setopt SH_WORD_SPLIT; }

# ... code that needs word splitting ...

_cli_shell_is_zsh && { $_had_shwordsplit || unsetopt SH_WORD_SPLIT; }
```

Do NOT set `SH_WORD_SPLIT` globally or in the helper functions — it would
affect all variable expansions and break quoting-dependent code elsewhere.

### Why not set it in the functions?

`setopt` inside `_cli_remove_first_word` etc. does NOT affect how the
caller's arguments are already expanded. Word splitting happens at the
call site, before the function body runs. The fix must be where the
unquoted variable is expanded.

## Known limitations

- **`zsh -c` sourcing** — `$zsh_eval_context` loses the `file` token
  after sourcing completes. This causes `exit` instead of `return` on
  errors when the CLI is invoked via `zsh -c 'source ./cli; ...'`.
  Workaround: use the alias or invoke directly (`zsh ./cli cmd args`).

- **`compgen` not available in zsh** — some argument types (FILE, DIR,
  ENVVAR, USER, GROUP, SSH_HOST, BLKDEV, SERVICE) use bash's `compgen`
  for completion. These only work in bash completion context. In zsh,
  the script uses alternative completion mechanisms.
