# Robustness Findings

Audited 2026-08-06. 103 findings across 10 categories, prioritized below.

## High-Impact

### 1. `read` missing `-r` flag

Lines 1486, 2145, 1824 — `while read env_line` / `while read cmd` eat backslashes
from config content. Silently corrupts paths, regex patterns, and command
expressions containing `\`.

### 2. Array slicing produces phantom empty element

`args=("${args[@]:1:${#args[@]}-1}")` at line 2072 and
`a_line=("${a_line[@]:1:${#a_line[@]}-1}")` at line 2462 produce `("")` instead
of `()` when the array has 1 element. One extra empty arg gets processed.

### 3. `_cli_count_matching_commands` uses return code as data

Lines 1449-1452 — exit codes are 0-255; >255 matching commands wraps modulo 256.
Unlikely in practice but a correctness bug.

### 4. `grep -P` for SSH_HOST completion

Line 2363 — PCRE flag doesn't exist on macOS BSD grep. Should use `grep -E` or
basic regex.

### 5. Dead code: `sysvdirs` undefined

Line 2377 — `compgen -W "${COMPREPLY[@]#${sysvdirs[0]}/}"` references an array
that's never defined. Copy-paste from bash-completion upstream; does nothing.

### 6. Trap only covers EXIT

Line 1388 — Ctrl-C during FIFO merge leaks the temp directory. Should be
`trap ... EXIT INT TERM`.

### 7. No `wait` for background FIFO writers

Lines 1390, 1406, 1408, 1416 — if a writer fails or is slow, `rm -rf "$tmpdir"`
at line 1422 removes files out from under them. Should `wait` before cleanup.

### 8. `set +o noglob` not reached if `eval` calls `exit`

Lines 2095-2098 — leaves noglob set in the caller's shell when sourced. Should
use a trap to restore it.

## Medium-Impact

### 9. `echo -e` portability

Line 1560 — behavior varies across shells. `printf '%b'` is safer.

### 10. `compgen` in `_cli_complete_arg` is bash-only

Lines 2300, 2309, etc. — when called from `_cli_expand_abbreviated_args` in zsh,
these silently produce no output. The zsh completion path uses `_values` instead,
but the abbreviation-expansion path doesn't.

### 11. Unquoted `for file in ${include_files[@]}`

Line 1393 — filenames with spaces break. Should be `"${include_files[@]}"`.

### 12. Unquoted echo-for-return values

Line 2608: `echo $matched_words`, line 2655: `echo $expanded_args $*` —
word-splitting/glob risk on return values.

### 13. `COMPREPLY` array assignment splits on whitespace

Line 2473: `COMPREPLY=($(_cli_getfirstwords "$word"))` — command substitution in
array assignment splits on whitespace and globs. Completion words with spaces get
corrupted.

### 14. `_cli_is_sourced` zsh regex too loose

Line 300 — `[[ "$zsh_eval_context" =~ .*?file* ]]` matches "file", "filex",
"filexyz" etc. Should be `[[ "$zsh_eval_context" =~ file ]]` or
`[[ "$zsh_eval_context" == *file* ]]`.

## Low-Impact

### 15. `mktemp` return unchecked

Line 315 — if it fails, `chmod` and `exec 3>` operate on empty path.

### 16. `source "$src_file"` exit code unchecked

Line 1501 — failing sourced scripts are silently ignored.

### 17. AWK `substr` index 0

Line 1157 — `substr(cmd_argvalue[arg], 0, 1)` is implementation-dependent
(POSIX AWK is 1-indexed).

### 18. `args` variable leaks via dynamic scope

Line 1697 in `_cli_args_are_complete` — relies on caller's `args` array rather
than receiving it as a parameter.

## Full Category Breakdown

| Category | Count |
|---|---|
| Unquoted variables (word splitting/globbing) | 18 |
| Missing error handling | 9 |
| Race conditions / orphan processes | 5 |
| Shell injection vectors | 8 |
| AWK parser edge cases | 9 |
| Portability issues | 13 |
| Signal handling gaps | 5 |
| Array handling issues | 10 |
| Echo-for-return (subshell fragility) | 12 |
| Additional issues | 14 |

### Shell Injection Vectors (by design — config is trusted input)

The script uses `eval` in several places to execute config-defined commands.
This is intentional: the config file is the user's own code. Key locations:

- Line 1462 — `eval "$(_awk output=commands command_filter="$1")"` (sourcing AWK output)
- Line 2096 — `eval $cmd_expr ${args[*]}` (executing command expression)
- Line 2299 — `arg_list=$(eval echo $arg_list)` (variable list expansion)
- Line 2337 — `arg_list=$(eval "$eval_cmd")` (function-based arg completion)
- Line 1560 — `source <(echo -e "$script")` (sourcing `[env]` section)

The trust boundary is: anyone who can write to `~/.yourcli.conf` can execute
arbitrary code. This is documented behavior but worth noting.

### AWK Parser Edge Cases

- `get_first_n_words` and `remove_last_word` use `parts[0]` from `split()`, which
  is undefined in standard AWK (1-indexed). Works in gawk but may fail on mawk/nawk.
- `substr(..., 0, 1)` at line 1157 — index 0 is gawk-specific.
- `command_filter` is not regex-escaped before use in `~` patterns (line 648).
- `split($0, cmd_arg, ":")` at line 602 breaks on config values containing colons.

### Portability

- `declare -g -A` requires bash 4.2+ (line 1144). macOS ships bash 3.2.
- `compgen` is bash-only; zsh paths fall through to `_values` but abbreviation
  expansion in zsh is broken for argument types.
- `grep -P` (PCRE) unavailable on macOS.
- `mapfile` requires bash 4.0+.
- `printf -v` is bash-specific.
- `${(z)...}`, `${(P)...}`, `${(@f)...}` are zsh-specific.

### Echo-for-Return Pattern

Functions that return values via `echo` (and callers that capture via `$()`)
fork a subshell each time (~2-5ms per call). Affected functions:

- `_cli_remove_last_word`, `_cli_remove_first_word`
- `_cli_get_shell_name`, `_cli_global`
- `_cli_getmatchingcommands`, `_cli_get_command_expr`
- `_cli_trim`, `_cli_lookup_command_desc`
- `_cli_get_last_word`, `_cli_get_first_word`

The pipe-to-while pattern (`_cli_get_command_args "$cmd" | while read arg`)
also creates a subshell, losing variable modifications inside the loop.
