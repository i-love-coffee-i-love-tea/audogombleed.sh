# Config File Grammar

Formal specification for audogombleed config files. The notation is
ABNF-like (RFC 5234 semantics, but not strict ABNF).

See [ADR-006](dev/adr/006-config-file-structure.md) for the design
rationale, and [02-configuration.md](02-configuration.md) for the
user-facing reference with examples.


## File structure

    config-file = *blank-line
                  [ env-section ]
                  commands-section

    env-section     = "[env]" newline *env-line
    commands-section = "[commands]" newline *command-line

A config file MUST contain `[commands]`. `[env]` is optional. If present,
`[env]` MUST precede `[commands]`.


## [env] section

    env-line = comment / source-directive / include-directive /
               cli-config-assignment / export-assignment /
               simple-assignment / shell-code / blank-line

    source-directive       = "source" SP path
    include-directive      = "include_commands_from" SP path SP parent-command
    cli-config-assignment  = "__CLI_CFG_" identifier "=" value
    export-assignment      = "export" SP identifier "=" value
    simple-assignment      = identifier "=" value
    comment                = "#" *CHAR

- `source` loads an external file (~ expanded to $HOME).
- `include_commands_from` merges a file's `[commands]` under
  `parent-command`. Use `ROOT` to merge at the top level.
- `__CLI_CFG_*` sets CLI behaviour (see [02-configuration.md](02-configuration.md)).
- All other lines are evaluated as shell code.
- Function definitions (`function name() { ... }`) are valid shell code
  and span multiple lines.


## [commands] section

    command-line = comment / detail-comment /
                   command-group / command / argument / blank-line

### Comments

    comment        = "#" (not "#") *CHAR     ; single-hash — help text
    detail-comment = "##" *CHAR              ; double-hash — detail text

`#` and `##` comments are valid at any indentation level — on top-level
groups, on intermediate command words, and on leaf commands. They serve
as help text for the nearest following command or group at the same
indentation level:

    [commands]
    # top-level group help
    deploy
        # intermediate group help
        staging
            # leaf command help
            deploy: ./deploy.sh staging

All three `#` lines are associated with their respective tree nodes and
appear in help output (`mycli deploy ?`, `mycli deploy staging ?`).

`##` comments provide extra detail shown in per-command help (`mycli cmd ?`).

Consecutive `#` lines at the top of `[commands]`, before any command or
group, terminated by a blank line, form the **global header** (displayed
at the top of `mycli ?`).

### Command groups

    command-group = [indent] identifier newline

A command group is a line containing a single word (no colon). It creates
a level in the command tree.

    identifier = (ALPHA / DIGIT / "-" / "_" / ".") *CHAR

Identifiers may contain letters, digits, hyphens, underscores, and dots.

### Indentation

    indent = 1*N(SP / HTAB)

Tabs count as 4 spaces. The first non-zero indentation detected sets the
unit width for the rest of the file. All subsequent indentation MUST be an
integer multiple of this unit.

### Commands

    command = [indent] command-word ":" SP shell-expression
    command-word = identifier / dynamic-word

A command is a word followed by a colon and a shell expression. The colon
MUST be present.

### Dynamic command words

    dynamic-word = variable-ref / function-ref / list-expansion
    variable-ref   = "$" identifier
    function-ref   = "&" identifier
    list-expansion = word 1*("|" word)

Dynamic words expand one definition into many commands.

### Arguments

    argument = [indent] ":" arg-name ":" arg-type
               [":" arg-value] [":" description]

    arg-name  = identifier
    arg-type  = simple-type / value-type [optional-marker]
    optional-marker = "?"

**Simple types** (no value field):

    simple-type = "STRING" / "INTEGER" / "FILE" / "DIR" /
                  "ENVVAR" / "USER" / "GROUP" /
                  "SSH_HOST" / "BLKDEV" / "SERVICE" /
                  "IP" / "MAC"

Syntax: `:name:type` or `:name:type:description`

**Value types** (require a value field):

    value-type = "list" / "int_range" / "eval" / "value"

Syntax: `:name:type:value` or `:name:type:value:description`

| Type | Value format | Example |
|------|-------------|---------|
| list | `val1\|val2\|...` or `$VAR` or empty | `:env:list:staging\|prod` |
| eval | function name | `:pod:eval:get_pods` |
| int_range | `min-max` | `:port:int_range:1-65535` |
| value | default string | `:name:value:world` |

**Optional arguments** — append `?` to the type. Optional arguments MUST
follow all required arguments.

### Shell expression placeholders

    placeholder = "\0" / "\1" / "\2" / ...

`\0` is replaced by the last word of the command path.
`\1`, `\2`, ... are replaced by user-supplied arguments in order.


## Whitespace rules

- Blank lines separate command groups and flush pending commands.
- Leading/trailing whitespace on identifiers is stripped.
- The indentation unit is detected from the first non-zero indentation
  and must be consistent for the rest of the file.
