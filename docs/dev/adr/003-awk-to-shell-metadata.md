# ADR-003: Pass completion metadata from AWK to shell via eval'd variable assignments

Author: i-love-coffee-i-love-tea
Status: Accepted

## Context

When the user presses Tab on a command argument, the shell needs to know
the argument's type (STRING, list, FILE, etc.), its allowed values, and
its description. This metadata is defined in the config file and parsed
by the embedded AWK script. The AWK script runs as a subprocess — it
cannot directly set variables in the calling shell.

The question is how to pass this structured metadata from the AWK
subprocess back to the shell completion function.

## Decision

The AWK script prints shell variable assignments to stdout. The shell
`eval`s the output to create associative arrays in the current scope.

AWK output for a command `deploy staging` with two arguments:

```bash
declare -g -A __CMD_ARG __CMD_ARG_TYPE __CMD_ARG_VALUE __CMD_ARG_DESC __CMD_ARG_NAME
__CMD="deploy staging"
__CMD_ARG[0]="environment"
__CMD_ARG_NAME[0]="environment"
__CMD_ARG_TYPE[0]="list"
__CMD_ARG_VALUE[0]="staging|production"
__CMD_ARG_DESC[0]="target environment"
__CMD_ARG[1]="version"
__CMD_ARG_NAME[1]="version"
__CMD_ARG_TYPE[1]="STRING"
__CMD_ARG_VALUE[1]=""
__CMD_ARG_DESC[1]="release version"
```

Shell side:

```bash
_cli_load_completion_vars() {
    [ "$1" = "" ] && return
    eval "$(_awk output=commands command_filter="$1")"
}
```

The completion function (`_cli_complete_arg`) then reads from these
arrays:

```bash
arg_type="${__CMD_ARG_TYPE[$pos]}"
case "$arg_type" in
    list)   _cli_compgen -W "${__CMD_ARG_VALUE[$pos]}" "$word" ;;
    FILE)   _cli_compgen -f "$word" ;;
    INTEGER) _cli_is_integer "$word" && echo "$word" ;;
    ...
esac
```

## Rationale

### Why not stdout parsing

The alternative is to print a structured format (one line per field,
colon-delimited, etc.) and parse it with `read` loops in the shell. This
was the original approach. It works for simple cases but becomes fragile
when values contain delimiters (e.g. a description with a colon in it).

The `eval` approach lets the AWK script control the quoting and escaping.
The AWK script escapes `"` → `\"` and `$var` → `\$var` in all output
values, so the shell sees valid assignments. There is no ambiguity about
field boundaries — each value is in its own array slot.

### Why associative arrays

The metadata has a natural structure: argument index → (name, type,
value, description). Associative arrays (`declare -g -A`) map this
directly. The shell can look up `__CMD_ARG_TYPE[$pos]` without iterating.

The `declare -g -A` is emitted by the AWK script itself, so the shell
does not need to pre-declare the arrays.

### Why eval and not source

`source` would require writing to a temporary file. `eval` processes the
output in memory — no file I/O, no cleanup, no temp file races.

## Escaping

The AWK script applies these escapes before printing:

- `"` in values → `\"` (prevents breaking out of the double-quoted
  assignment)
- `$` at the start of a value → `\$` (prevents premature variable
  expansion when the shell evaluates the assignment)
- `__CMD_EXEC` is intentionally omitted — including it would cause
  unintended `$(...)` evaluation when eval'd, since command expressions
  may contain command substitution

This is verified by tests in `test/awk-output-escaping-*.bats`.

## Tradeoff: eval of subprocess output

The `eval` means the shell trusts the AWK output. If the AWK script
produced malformed output (e.g. an unescaped `"`), it could break the
shell session or, in theory, execute arbitrary code.

Mitigations:

- The AWK script is embedded in the same file — it is not user-editable
  and cannot be tampered with independently.
- The escaping rules are simple and verified by tests.
- The `command_filter` argument (user input) is used only for regex
  matching inside AWK — it is not interpolated into the output
  assignments.

## Consequences

- Completion metadata is available as shell arrays after a single `eval`.
- The AWK script controls the output format — adding a new field (e.g.
  `__CMD_ARG_DEFAULT`) requires only adding a `printf` in AWK.
- The shell completion function can switch on `__CMD_ARG_TYPE` without
  re-parsing the config file.
- The `eval` is a trust boundary between the AWK subprocess and the
  shell. The embedded AWK script and the escaping rules are the only
  guarantees that the output is safe.

## Changes

- 2026-08-08: i-love-coffee-i-love-tea - initial draft
- 2026-08-08: i-love-coffee-i-love-tea - accepted
- 2026-08-08: i-love-coffee-i-love-tea - already implemented
