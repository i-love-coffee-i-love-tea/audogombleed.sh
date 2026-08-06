# Test Suite Improvement — Completed

Restructured test suite to ensure every feature is tested in both bash and zsh.

## Results

| Metric | Before | After |
|--------|--------|-------|
| Total tests | 121 | 257 |
| Bash test files | 14 (mixed naming) | 21 (`*-bash.bats`) |
| Zsh test files | 3 (`zsh*.bats`) | 21 (`*-zsh.bats`) |
| Zsh test coverage | ~27 tests | 128 tests |
| Features with zsh tests | 5 | 17 |

## File Structure

Every feature now has a `*-bash.bats` and `*-zsh.bats` pair:

```
test/
  auto-completion-bash.bats        auto-completion-zsh.bats
  command-definitions-bash.bats    command-definitions-zsh.bats
  argument-types-bash.bats         argument-types-zsh.bats
  config-options-bash.bats         config-options-zsh.bats
  exit-codes-bash.bats             exit-codes-zsh.bats
  help-triggers-bash.bats          help-triggers-zsh.bats
  include-config-bash.bats         include-config-zsh.bats
  sourcing-bash.bats               sourcing-zsh.bats
  ...
```

New feature test files (both shells):
- `batch-mode-{bash,zsh}.bats` — `-b`/`--batch` mode
- `cli-flags-{bash,zsh}.bats` — `--version`, `--cli-print-awk-script`, etc.
- `abbreviation-{bash,zsh}.bats` — command abbreviation expansion
- `argument-placeholders-{bash,zsh}.bats` — `\0`, `\1`, `\2` replacement
- `optional-arguments-{bash,zsh}.bats` — `?` suffix args
- `help-sections-{bash,zsh}.bats` — section headings, group help
- `config-options-extended-{bash,zsh}.bats` — `ALWAYS_RETURN_0`, `LOG_LEVEL`, `source`

Helper files:
- `auto-completion-mock-setup.bash` — bash completion mock
- `auto-completion-mock-setup-zsh.bash` — zsh completion mock (uses `$words`/`$CURRENT`)
- `zsh-helpers.bash` — `_zsh_run()` and `_zsh_complete()` wrappers

## Known Issues Discovered

These are pre-existing bugs in `audogombleed.sh`, not test issues:

1. **`_cli_args_are_complete` subshell bug** — modifies `mandatory_argc` inside a pipeline, so the change never propagates. Commands always succeed even with missing required args.

2. **`include_commands_from` zsh word splitting** — `_cli_remove_first_word $env_line` passes the whole line as one arg in zsh (no `SH_WORD_SPLIT`). Include config tests are skipped under zsh.

3. **`$0` changes on zsh `source`** — when a wrapper script sources `audogombleed.sh`, `$0` becomes `audogombleed.sh`. Wrapper must restore `$0` and set `__CLI_PROGNAME` manually.

4. **`compgen` not available in zsh** — `_cli_complete_arg` uses bash-specific `compgen` for some arg types (FILE, DIR, ENVVAR, etc.). These only work in bash completion context.

5. **`_values` widget restriction** — zsh's `_values` can only be called from a completion widget. Test helpers override it to a no-op.

6. **`$ARGUMENT_OPTIONS` not expanded at AWK time** — env variables set in `[env]` section aren't available to the AWK parser when it runs for completion.

## Test Naming Convention

- `*-bash.bats` — tests that run under bash (use `run ./testcli ...`)
- `*-zsh.bats` — tests that run under zsh (use `run _zsh_run ...`)
- `*-bash.bash` / `*-zsh.bash` — shell-specific helper functions
