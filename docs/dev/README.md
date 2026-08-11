# Developer Guide

This document explains how derakht.sh works internally. It covers the
architecture, the embedded AWK config parser, the tab-completion pipeline,
command execution, and development workflows.

All features work in bash and zsh, apart from one: in zsh, autocompletions
can additionally use description labels, which aren't supported in bash.


## Table of contents

- [Architecture overview](#architecture-overview)
- [Multiple CLIs in the same shell](#multiple-clis-in-the-same-shell)
- [Naming conventions](#naming-conventions)
- [Global variables](#global-variables)
- [Global functions](#global-functions)
- [The AWK config parser](#the-awk-config-parser)
  - [What the parser does](#what-the-parser-does)
  - [Output modes](#output-modes)
  - [How the parser reads the config file](#how-the-parser-reads-the-config-file)
  - [Flattening the tree](#flattening-the-tree)
  - [Dynamic command expansion](#dynamic-command-expansion)
  - [Help text extraction](#help-text-extraction)
  - [Command word formatting for help](#command-word-formatting-for-help)
- [Tab completion pipeline](#tab-completion-pipeline)
  - [Registration: what happens on `source`](#registration-what-happens-on-source)
  - [The completion function `_cli_complete_`](#the-completion-function-_cli_complete_)
  - [How the AWK parser returns completion metadata to the shell](#how-the-awk-parser-returns-completion-metadata-to-the-shell)
  - [Command-word completion](#command-word-completion)
  - [Argument completion](#argument-completion)
  - [Zsh description labels](#zsh-description-labels)
- [Command execution pipeline](#command-execution-pipeline)
- [The `[env]` loading pipeline](#the-env-loading-pipeline)
- [Include files and FIFO merging](#include-files-and-fifo-merging)
- [Caching and performance](#caching-and-performance)
- [AWK script development cycle](#awk-script-development-cycle)
- [Linting](#linting)
- [Performance tips](#performance-tips)
- [Tracing](#tracing)
- [Bats test automation](#bats-test-automation)
- [Glossary](#glossary)


## Architecture overview

```
                    ┌──────────────┐
                    │  Config File │
                    │  (.NAME.conf)│
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  [env]       │  ← shell code: exports, functions,
                    │  section     │    CLI options
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  [commands]  │  ← parsed by embedded AWK script
                    │  section     │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
     ┌────────▼───┐ ┌──────▼─────┐ ┌───▼──────────┐
     │ Completion │ │  Help      │ │  Execution   │
     │ (Tab key)  │ │  (? / -h)  │ │  (Enter key) │
     └────────────┘ └────────────┘ └──────────────┘
```

Derakht.sh is a single-file shell script (~3200 lines) that serves
two completely different roles depending on how it is invoked:

```
source ~/bin/mycli          # role 1: register tab completion
mycli some-command args     # role 2: execute a command
```

**Role 1 — Sourced (registration).** When sourced, the script detects it
is sourced (`_cli_is_sourced`), sets `__CLI_PROGNAME` from the symlink
name, registers the completion function with the shell, and returns.
No commands are parsed or executed. This runs in the current shell, which
is how completion functions and `[env]` definitions become available.

**Role 2 — Executed (command handling).** When executed directly (or via
an alias), the script calls `_cli_execute "$@"`. This loads the config,
parses the command line, expands abbreviations, substitutes arguments,
and runs the matched command expression through `eval`.

The main flow for each role:

```
source ~/bin/mycli
  └─ _cli_is_sourced == true
     └─ bash: complete -F _cli_complete_ "$__CLI_PROGNAME"
     └─ zsh:  compdef _cli_complete_ "$__CLI_PROGNAME"

mycli cmd args
  └─ _cli_is_sourced == false
     └─ _cli_execute "$@"
        ├─ _cli_init_global_vars
        ├─ _cli_open_logfile
        ├─ _cli_read_awk_script
        ├─ _cli_load_config_environment   ← sources [env], processes includes
        ├─ _cli_load_command_word_functions
        ├─ _cli_read_command_list          ← calls AWK, caches flattened commands
        └─ _cli_execute_command "$cmd_args"
           ├─ _cli_expand_abbreviated_command
           ├─ _cli_is_command_complete
           ├─ _cli_get_command_expr
           ├─ placeholder substitution (\0, \1, \2...)
           └─ eval $cmd_expr ${args[*]}
```

The AWK parser is the bridge between the config file (a human-readable
tree) and the shell (which needs flat, queryable data). It runs as a
subprocess each time the config is loaded.


## Multiple CLIs in the same shell

Users can create multiple CLIs from the same script:

    source ~/bin/cli1    # registers completion for "cli1"
    source ~/bin/cli2    # registers completion for "cli2"

Both work independently. This seems impossible at first glance — sourcing
`cli2` overwrites `__CLI_PROGNAME` to `"cli2"`, so how does `cli1` still
work?

The answer is that `__CLI_PROGNAME` at source time is **only used for one
thing**: the `complete -F` (or `compdef`) registration on lines 3179-3183.
After that, the source-time value is irrelevant.

Bash's `complete` registry maps each CLI name to the shared function
independently:

    complete -F _cli_complete_ "cli1"   # registered when cli1 was sourced
    complete -F _cli_complete_ "cli2"   # registered when cli2 was sourced

When the user types `cli1 <TAB>`, bash calls `_cli_complete_` with
`COMP_WORDS[0]="cli1"`. The function **re-derives** `__CLI_PROGNAME`
from `COMP_WORDS` at the top of every call (lines 2735-2743):

```bash
if _cli_shell_is_zsh; then
    __CLI_PROGNAME="$(basename "${COMP_WORDS[1]}")"
else
    __CLI_PROGNAME="$(basename "${COMP_WORDS[0]}")"
fi
```

Then builds the config path from the fresh value:

```bash
_cli_global CONFIG_FILE "$HOME/.${__CLI_PROGNAME}.conf"
```

The same re-derivation happens in `_cli_execute()` (lines 3019-3027).

So the architecture is:

- **Source time** — `__CLI_PROGNAME` is ephemeral, used only to register
  the completion function name with the shell.
- **Completion time** — `__CLI_PROGNAME` is re-read from `COMP_WORDS`
  on every Tab press. The correct config file is loaded, the correct
  command list is built.
- **Execution time** — same re-derivation. Each invocation gets its own
  config.

The `__CLI_CONFIG` array (cached flattened command list) and per-CLI
namespaced variables (`__CLI_mycli_CFG_*`) are all reloaded at the top
of every `_cli_complete_` and `_cli_execute` call, so stale data from a
different CLI is never used.


## Naming conventions

### Variables

All global variables begin with `__CLI_`. Per-CLI variables are namespaced
as `__CLI_${PROGNAME}_${SETTING}`. For example, the `CFG_LOG_LEVEL` for
a CLI named `mycli` is stored in `__CLI_mycli_CFG_LOG_LEVEL`.

Three variables are treated specially:
- `__CLI_VERSION` — script version string, set once
- `__CLI_AWK_SCRIPT` — the embedded AWK script, read once and cached
- `__CLI_PROGNAME` — the CLI name; set at source time for registration,
  then **re-derived on every completion and execution call** (see below)

All other `__CLI_` variables are initialized during each completion or
execution call by `_cli_init_global_vars`.

To list all active variables at runtime:

    compgen -A variable | grep ^__CLI_

### Functions

All functions begin with `_cli_`. Functions are loaded by sourcing the
script (which happens on `source ~/bin/mycli`).

Registered completion functions can be listed by calling `complete` without
arguments:

    $ complete | grep ^_cli

### Glossary note: 'completion' vs. 'expansion'

The code uses 'expand' instead of 'complete' in variable and function
naming to differentiate between:

- **completion** — auto-completion during typing (Tab key)
- **expansion** — expanding submitted abbreviated commands for execution

This distinction matters because the two operations share the same command
list but have different user-facing behavior.


## Global variables

All used variables begin with `__CLI_`.

All but `__CLI_VERSION`, `__CLI_AWK_SCRIPT` and `__CLI_PROGNAME` are
initialized during completion and command execution.


## Global functions

All functions begin with `_cli_`.

Functions are loaded by sourcing the cli script.

Registered completion functions can be listed by calling complete without
arguments:

    $ complete | grep ^_cli


## The AWK config parser

The config parser is an embedded AWK script stored as a here-document
inside `_cli_read_awk_script()` (line ~460 of derakht.sh). It is
written to be POSIX-compatible AWK — no gawk extensions, no `PROCINFO`,
no `gensub`. This is deliberate: macOS ships BWK awk, and the script
must work there without installing gawk.

### What the parser does

The parser serves five distinct purposes, selected by the `output=`
parameter:

1. **Flatten the tree** — converts the indentation-based config tree
   into one flat line per command, suitable for shell-side array storage
2. **Query commands** — finds a specific command and returns its metadata
   as shell variable assignments
3. **List command names** — returns a list of all command names (optionally
   filtered by prefix)
4. **Extract help text** — parses `#` and `##` comments and formats them
   for display
5. **Extract `[env]`** — passes through the `[env]` section verbatim

### Output modes

The parser is invoked with parameters on the AWK command line:

    awk -f script.awk config.conf output=<mode> [command_filter="..."] [do_format=...]

The parameters are read from `ARGV[]` in the `BEGIN` block:

    output_type  = _extract_after(ARGV[2], "output=")
    command_filter = _extract_after(ARGV[3], "command_filter=")
    do_format    = _extract_after(ARGV[4], "do_format=")

Here are the modes in detail:

#### `output=env`

Prints every line in the `[env]` section verbatim. The shell script reads
this output and sources it. No parsing or formatting — just pass-through.

#### `output=command_names`

Prints one command name per line. Each name is a space-separated path
through the tree (e.g., `install jar from file`). Dynamic commands
(`$variable`, `&function`, `val1|val2`) are expanded — one line per
expanded variant.

When `command_filter` is set, only commands whose name starts with the
filter are printed. This is the primary mode for tab completion of
command words.

Example:

    $ cli --cli-run-awk-script output=command_names command_filter="install jar"
    install jar from file
    install jar from maven

#### `output=commands` (no filter)

Prints each command on a single line, formatted as:

    <command-name-padding-to-30-chars>, <arg1> <arg2> ..., <execution-expression>

This is the "flat" representation loaded into the `__CLI_CONFIG` shell
array. The shell script reads this array to match user input against
known commands without calling AWK again.

Example:

    $ cli --cli-run-awk-script output=commands
    install jar from file             , <jar-file>, echo
    install jar from maven            , <mvn-coords>, echo

Dynamic commands are expanded: if the last word of a command is
`$variable`, `&function`, or `val1|val2`, the parser expands it into
one line per variant.

#### `output=commands command_filter="<exact command>"`

When a filter is given and it exactly matches a command, the parser
**does not print the flat format**. Instead, it prints shell variable
assignments that can be `eval`'d. For a config like:

    echo: echo \2 \1
        :first-arg:list:one|two|three:first positional argument
        :second-arg:list:alpha|beta|gamma:second positional argument

The output is:

    declare -g -A __CMD_ARG __CMD_ARG_TYPE __CMD_ARG_VALUE __CMD_ARG_DESC __CMD_ARG_NAME
    __CMD="echo"
    __CMD_EXEC=" echo \2 \1"
    __CMD_ARG[0]="list"
    __CMD_ARG_NAME[0]="first-arg"
    __CMD_ARG_TYPE[0]="list"
    __CMD_ARG_DESC[0]="first positional argument"
    __CMD_ARG_VALUE[0]="one|two|three"
    __CMD_ARG[1]="list"
    __CMD_ARG_NAME[1]="second-arg"
    __CMD_ARG_TYPE[1]="list"
    __CMD_ARG_DESC[1]="second positional argument"
    __CMD_ARG_VALUE[1]="alpha|beta|gamma"

Note: `__CMD_ARG` contains only the type (`list`, `int_range`, etc.),
not the full field. The name, description, and value are split into
their own variables. `__CMD_ARG_NAME` is the `:name:` field from the
config; `__CMD_ARG_DESC` is the optional trailing description.

If no match is found, the parser exits with code 1 and prints nothing.

This is how the shell gets completion metadata — see
[How the AWK parser returns completion metadata to the shell](#how-the-awk-parser-returns-completion-metadata-to-the-shell).

#### `output=help command_filter="<command>"`

Prints formatted help text for the matching command. If `do_format=1` is
set, command names include brackets showing the minimum unambiguous prefix:

    $ cli ? 
      deployment commands
        d[eploy] p[rod]          deploy to production
        d[eploy] s[taging]       deploy to staging

Without `do_format`, command names are printed in full.

#### `output=command_word_functions`

Prints the names of functions used with `&` expansion. The shell script
calls these functions and captures their output into environment variables
so the AWK parser can access them via `ENVIRON[]` during subsequent calls.

### How the parser reads the config file

The config file is passed as `ARGV[1]` to the AWK script. The parser
reads it line by line, tracking state:

```
cfg_section  — "" → "env" → "commands"  (set by [section] headers)
type         — "command_group" | "command" | "arg" | "cmd_help" | ...
cmd          — accumulates the current command path words
fullcmd      — the complete command name including the current word
indentation  — spaces + 4*tabs (detected from the first indented line)
```

The parser distinguishes three kinds of lines in `[commands]`:

1. **Parent node** — a line matching `/^[ \t]{0,}[a-zA-Z0-9\-_.]+[ \t]{0,}$/`
   (a single word, no colon). This is a tree node that groups child commands.

2. **Command node** — a line matching `/^[ \t]{0,}[$&]?[a-zA-Z0-9\-_.|]+:.*$/`
   (a word followed by a colon). This defines a command and its execution
   expression.

3. **Argument specification** — a line matching `/^[ \t]{0,}:[a-zA-Z0-9\-_].*$/`
   (starts with colon). This defines an argument for the preceding command.

When the parser encounters a new command or an empty line, it calls
`print_command()` to emit the previous command's data, then
`cache_command_names()` to register it in the `command_names` array.

### Flattening the tree

The key insight is that the parser builds command paths incrementally:

```
install          → cmd = "install"
  jar            → cmd = "install jar"
    from         → cmd = "install jar from"
      file: echo → fullcmd = "install jar from file", exec = "echo"
```

When indentation decreases (moving back up the tree), `cmd` is trimmed
by removing trailing words:

```
      maven: echo  → cmd is trimmed: "install jar from" + "maven"
                     → fullcmd = "install jar from maven", exec = "echo"
```

The `remove_last_word()` and `get_first_n_words()` functions handle
the tree traversal logic.

### Dynamic command expansion

When a command's last word is a dynamic reference, the parser expands it:

- `$VARIABLE` — looks up `ENVIRON[variable_name]`, splits on spaces
- `&function` — looks up `ENVIRON["_cli_" funcname "_result"]`, splits on spaces
- `val1|val2|val3` — splits on `|`

The `expand_dynamic_commands()` function handles all three cases. It
generates one command variant per expanded word, each getting its own
line in the output.

### Help text extraction

Comments in the config file are parsed differently depending on the
output mode. Only `output=help` processes comments.

The parser tracks four levels of help text:

1. **Global header** — consecutive `#` lines at the top of `[commands]`,
   before any command. Accumulated into `global_help_header`. Terminated
   by a blank line.

2. **Section heading** — a `#` line at the top level, after the first
   command. Stored in `section_headings[first_word]`. Displayed above
   the command group in global help.

3. **Command help** — `#` lines immediately before a command at the same
   indentation level. Stored in `cmd_help[]`, then transferred to
   `cmd_help_by_cmd[command, index]` by `cache_cmd_help()`.

4. **Detail help** — `##` lines (double hash). Stored in
   `v_cmd_details_help[command, index]`. Displayed when viewing a
   specific command's help.

### Command word formatting for help

When `do_format=1` is set, the `format_commands()` function computes the
minimum unambiguous prefix for each word position. It compares each
command word character-by-character against all other command words at
the same position (considering only commands with matching prefix words).

The result is formatted with brackets showing optional characters:

    deploy → d[eploy]       (if no other command starts with 'd')
    deploy → de[ploy]       (if 'debug' also exists)

This is purely cosmetic — it shows the user how much they need to type
for an unambiguous match.


## Tab completion pipeline

### Registration: what happens on `source`

When the user runs `source ~/bin/mycli`:

1. `_cli_is_sourced` returns true (bash checks `BASH_SOURCE[0] != $0`,
   zsh checks `$zsh_eval_context` for the `file` token)

2. `__CLI_PROGNAME` is set from `${BASH_SOURCE[0]##*/}` (bash) or
   `${0##*/}` (zsh)

3. The completion function is registered:
   - Bash: `complete -F _cli_complete_ "$__CLI_PROGNAME"`
   - Zsh: `compdef _cli_complete_ "$__CLI_PROGNAME"`

4. The script returns. No config is loaded yet — that happens on the
   first Tab press or command execution.

### The completion function `_cli_complete_`

This is the function the shell calls on every Tab press. It is the
central orchestrator of the completion pipeline. Here is the full flow:

```
_cli_complete_()
│
├─ 1. Set __CLI_PROGNAME from COMP_WORDS
├─ 2. Set CONFIG_FILE = ~/.${__CLI_PROGNAME}.conf
│
├─ 3. _cli_init_global_vars()          ← set defaults
├─ 4. _cli_open_logfile()              ← if log level > 0
├─ 5. _cli_read_awk_script()           ← load embedded AWK (cached)
├─ 6. _cli_load_config_environment()   ← source [env], process includes
├─ 7. _cli_load_command_word_functions()← run &functions (no cache)
├─ 8. _cli_read_command_list()         ← AWK → __CLI_CONFIG[] array
│
├─ 9. Read COMP_LINE, COMP_CWORD, COMP_WORDS (bash)
│      or $words, $CURRENT (zsh)
│
├─ 10. First word? (COMP_CWORD == 1)
│       └─ _cli_getfirstwords()        ← fast path for first command word
│
├─ 11. Deeper position? (COMP_CWORD > 1)
│       ├─ _cli_is_command_complete()   ← find which command matches
│       ├─ Command is complete + cursor past it?
│       │   └─ _cli_complete_arg()     ← complete arguments
│       └─ Command not yet complete?
│           └─ _cli_complete_command()  ← complete next command word
│
├─ 12. Zsh: _values to present results with descriptions
└─ 13. _cli_close_logfile()
```

### How the AWK parser returns completion metadata to the shell

This is the most interesting part of the architecture. The AWK parser
runs as a subprocess, and the shell needs structured metadata about
commands and their arguments. The bridge between the two is a set of
**shell variable assignments** that the AWK script prints to stdout
and the shell `eval`s.

Here is the exact mechanism, step by step:

#### Step 1: The shell calls AWK with `output=commands command_filter="<cmd>"`

When the shell needs argument metadata for a command, it calls:

    _awk output=commands command_filter="echo"

This invokes:

    echo "$__CLI_AWK_SCRIPT" | awk -f - "$CONFIG_FILE" \
        output=commands command_filter="echo"

#### Step 2: The AWK parser finds the exact match and prints variable assignments

In the `print_command()` function, when `command_filter` exactly matches
a full command, the parser calls `print_command_environment_vars()`.
This function prints:

```awk
function print_command_environment_vars(fullcmd, cmd_exec) {
    print "declare -g -A __CMD_ARG __CMD_ARG_TYPE __CMD_ARG_VALUE __CMD_ARG_DESC __CMD_ARG_NAME"
    printf "__CMD=\"%s\"\n", fullcmd
    printf "__CMD_EXEC=\"%s\"\n", cmd_exec
    arg=0
    while (arg in cmd_args) {
        printf "__CMD_ARG[%s]=\"%s\"\n", arg, cmd_args[arg]
        printf "__CMD_ARG_NAME[%s]=\"%s\"\n", arg, cmd_argname[arg]
        printf "__CMD_ARG_TYPE[%s]=\"%s\"\n", arg, cmd_argtype[arg]
        printf "__CMD_ARG_DESC[%s]=\"%s\"\n", arg, cmd_argdesc[arg]
        printf "__CMD_ARG_VALUE[%s]=\"%s\"\n", arg, cmd_argvalue[arg]
        arg++
    }
}
```

The output is a valid shell script that, when sourced, populates these
variables:

| Variable | Content |
|----------|---------|
| `__CMD` | The matched command name (e.g., `"echo"`) |
| `__CMD_EXEC` | The execution expression |
| `__CMD_ARG[n]` | The argument type (e.g., `"list"`, `"int_range"`) |
| `__CMD_ARG_NAME[n]` | The argument name (e.g., `"first-arg"`) |
| `__CMD_ARG_TYPE[n]` | Same as `__CMD_ARG[n]` — the argument type |
| `__CMD_ARG_VALUE[n]` | The argument value (e.g., `"one\|two\|three"`) |
| `__CMD_ARG_DESC[n]` | The argument description (e.g., `"first positional argument"`) |

#### Step 3: The shell `eval`s the output

The shell captures this output and runs it through `eval`:

    _cli_load_completion_vars() {
        [ "$1" = "" ] && return
        eval "$(_awk output=commands command_filter="$1")"
    }

After `eval`, the shell has `__CMD`, `__CMD_ARG`, `__CMD_ARG_TYPE`,
`__CMD_ARG_VALUE`, etc. as local variables — ready for the completion
function to use.

#### Step 4: The completion function uses the metadata

In `_cli_complete_arg()`, the shell reads the metadata arrays to
determine how to complete:

    arg_type="${__CMD_ARG_TYPE[$pos]%%\?}"   # strip optional marker

Then dispatches based on type:

    case "$arg_type" in
        list)     _cli_compgen -W "$arg_list" "$word" ;;
        int_range) _cli_seq $arg_min $arg_max ;;
        eval)     eval "$eval_cmd" | _cli_compgen -W "" "$word" ;;
        FILE)     _cli_compgen -f "$word" ;;
        DIR)      _cli_compgen -d "$word" ;;
        # ... etc
    esac

This is the full round-trip: config file → AWK parser → shell variables
→ completion logic → `COMPREPLY` array → shell displays candidates.

#### Why this design?

The alternative would be to parse the config file in pure shell (bash/zsh
string manipulation). This was rejected because:

1. **The config grammar is complex** — indentation-based trees, multiple
   argument types, dynamic expansion, help text extraction. AWK is
   well-suited for this; pure shell would be fragile and slow.

2. **AWK runs as a subprocess anyway** — the config file is read from
   disk, which requires a subprocess in POSIX shell. Adding the parsing
   to that subprocess is free.

3. **The variable-assignment output format is self-describing** — the
   shell doesn't need to know the AWK output format. It just `eval`s
   whatever comes out. This decouples the parser from the shell logic.

4. **The same AWK script serves multiple purposes** — command listing,
   help formatting, env extraction, and completion metadata all share
   the same parser, just with different `output=` modes.

### Command-word completion

When the user types `mycli in<TAB>`, the shell needs to suggest command
words. Two paths exist:

**First word (fast path):** `_cli_getfirstwords()` calls:

    _awk output=command_names command_filter="$word"

This returns all command names starting with the prefix. The function
extracts the first word of each match, deduplicates, and returns them.
In zsh, it also looks up help-text descriptions and appends them as
`[description]` suffixes.

**Deeper words:** `_cli_complete_command()` calls the same AWK command
but extracts the word at position `$COMP_CWORD` from each matching
command name:

    _awk output=command_names command_filter="$line"

Then for each result, reads the word at the current position and adds
it to `COMPREPLY` (with deduplication).

### Argument completion

When the command is complete and the cursor is past the last command
word, the shell switches to argument completion:

1. `_cli_is_command_complete` identifies the matched command
2. `_cli_load_completion_vars` calls AWK with the exact command name,
   gets back the `__CMD_ARG_*` metadata
3. `_cli_complete_arg` reads the argument type at the current position
   and dispatches to the appropriate completion generator

The argument position is calculated as:

    arg_pos = line_word_count - cmd_word_count

So if the command is `install jar from file` (4 words) and the user
has typed `mycli install jar from file my<TAB>` (6 words), `arg_pos = 2`,
which maps to the second `:name:type:source` definition.

### Zsh description labels

Zsh supports `[description]` suffixes on completion candidates. The
script adds these in two places:

1. **Command words:** `_cli_getfirstwords()` calls
   `_cli_get_command_help_texts()` which runs `_awk output=help` and
   extracts one description per first-word command. These are appended
   as `word[description]` in the `_zsh_results` array.

2. **Arguments:** `_cli_complete_arg()` appends the argument description
   (from `__CMD_ARG_DESC`) or a type-based default (e.g., "file" for
   FILE, "integer" for INTEGER) to each completion candidate.

The final presentation uses zsh's `_values` function:

    _values "$description" "${COMPREPLY[@]}"


## Command execution pipeline

When the user runs `mycli some-command args`:

```
_cli_execute "$@"
│
├─ Parse CLI flags (--batch, --version, --cli-*)
├─ _cli_init_global_vars
├─ _cli_open_logfile
├─ _cli_read_awk_script
├─ _cli_load_config_environment
├─ _cli_load_command_word_functions
├─ _cli_read_command_list
│
├─ Handle ? / -h → _awk output=help
│
└─ _cli_execute_command "$cmd_args"
   │
   ├─ _cli_expand_abbreviated_command
   │   └─ For each word: find unique match in __CLI_CONFIG
   │
   ├─ _cli_is_command_complete "$cmdline"
   │   └─ Iteratively removes last word until a match is found
   │      Returns: __CLI_CMD_WORDS = matched command (no args)
   │
   ├─ Extract args: args = cmdline minus command words
   │
   ├─ Optional: _cli_expand_abbreviated_args
   │
   ├─ Check: enough args? (exit 53 if required args missing)
   │
   ├─ _cli_get_command_expr "$cmd"
   │   └─ Searches __CLI_CONFIG for the matching line,
   │      extracts field 3 (the execution expression)
   │
   ├─ Placeholder substitution:
   │   cmd_expr = cmd_expr with \0 → last command word
   │   cmd_expr = cmd_expr with \1 → args[0]
   │   cmd_expr = cmd_expr with \2 → args[1]
   │   ... etc
   │
   ├─ Optional: confirm expanded command (y/n prompt)
   │
   └─ eval $cmd_expr ${args[*]}
```

The `eval` at the end is the core execution mechanism. The command
expression from the config (e.g., `kubectl logs -f -n \1`) has its
placeholders replaced with the user's arguments, then the whole string
is evaluated by the shell. See `docs/SECURITY.md` for implications.


## The `[env]` loading pipeline

`_cli_load_config_environment()` reads the `[env]` section line by line
(via `_awk output=env`) and processes each line:

1. **`source` directives** — expand `~`, check file permissions, source
   the file into the current shell

2. **`include_commands_from` directives** — register the file for later
   merging (see below). Does NOT source the file.

3. **`__CLI_*=` assignments** — stripped of prefix, validated, and
   assigned to the namespaced variable via `printf -v`

4. **Everything else** — accumulated into a `$script` variable and
   `source`d as a single block at the end

This means the `[env]` section has full shell capabilities: variable
assignments, function definitions, conditionals, loops, etc.


## Include files and FIFO merging

When `include_commands_from` is used, the main config and all included
files must be merged before the AWK parser sees them. This is done via
named pipes (FIFOs):

```
Main config ──────┐
                   │
Include file 1 ───┤── cat → merged_config (FIFO) ──→ AWK parser
                   │
Include file 2 ───┘
```

Each included file's `[commands]` section is extracted by a small AWK
one-liner. If a `parent_command` is specified (not `ROOT`), the commands
are indented under that parent. The FIFOs are created in a temporary
directory and cleaned up on exit.

The merge happens in `_awk()` (the shell wrapper function), not in the
AWK script itself. The AWK script always sees a single merged config.


## Caching and performance

Performance is critical — every Tab press runs the full pipeline. The
script uses several caching strategies:

1. **AWK script cache** — `__CLI_AWK_SCRIPT` is read once on first call
   to `_cli_read_awk_script()` and reused thereafter.

2. **Config file mtime cache** — `_cli_read_command_list()` checks the
   config file's modification time. If unchanged, it reuses the cached
   `__CLI_CONFIG` array.

3. **Command word functions** — `_cli_load_command_word_functions()` runs
   on every completion. Functions depend on external state (shell variables,
   files, commands) that can change between invocations without modifying
   the config file. Caching them by mtime would cause stale completions.

4. **Config environment** — `[env]` is re-sourced on every call (because
   it may contain dynamic state), but the overhead is minimal for
   typical configs.

5. **Return code as data** — `_cli_count_matching_commands()` uses the
   shell return code to pass the count, avoiding a subshell to read a
   variable. The comment in the code notes this saved 60ms.

The script avoids subshells in completion functions wherever possible,
since each subshell costs ~10-20ms on typical systems.


## AWK script development cycle

For development of the embedded AWK script:

1. **Export the AWK script:**

        $ cli --cli-print-awk-script > cli.awk

2. **Edit cli.awk**

3. **Test run:**

        $ awk -f cli.awk config.conf output=commands command_filter=""

4. **Run syntax check:**

        $ awk --lint -f cli.awk

5. **If everything is good, copy the script to clipboard:**

        $ cat cli.awk | xclip

6. **Edit the shell script to embed the new AWK script:**
   search for `AWK_EOF`, remove old script, paste.

To run the embedded awk script directly:

    $ cli --cli-run-awk-script output=command_names
    $ cli --cli-run-awk-script output=commands command_filter="my command"
    $ cli --cli-run-awk-script output=help command_filter="" do_format=1

The script parameters are described in the comments in the AWK script
header (lines ~462-502 of derakht.sh).


## Linting

    $ dev lint          # shellcheck on derakht.sh
    $ dev lint fish     # fish_indent --check on derakht.fish
    $ dev format fish   # auto-fix fish_indent formatting

See also: [Release Process](RELEASE.md).


## Performance tips

Latency is critical for tab completion. Target times:

| Time | Feel |
|------|------|
| < 50ms | Excellent |
| ~100ms | Good |
| ~200ms | Acceptable |
| ~400ms | Sluggish |

In completion functions, avoid unless absolutely necessary:

- **Subshells** — each costs ~10-20ms
- **External programs** — process startup overhead
- **Pipes** — each pipe creates a subshell

Time with:

    $ time mycli some-command

### Why `_cli_count_matching_commands` uses return codes

The function needs to communicate a count to the caller. The obvious
approach (echo + subshell to read) adds ~60ms. Using the return code
instead saves that overhead at the cost of limiting the range to 0-255
(which is fine — no command tree has 256+ matches for a prefix).


## Tracing

    strace -c $YOUR_CLI_COMMAND


## Bats test automation

Run bats tests after checking out submodules:

    $ test/bats/bin/bats test/*.bats

Run specific test suites:

    $ test/bats/bin/bats test/awk-config-parser-bash.bats
    $ test/bats/bin/bats test/auto-completion-bash.bats
    $ test/bats/bin/bats test/abbreviation-bash.bats


## Glossary

| Term | Meaning |
|------|---------|
| **command word** | A word in the command path, defined by indentation in the config (e.g., `install`, `jar`, `from`, `file`) |
| **argument** | A value typed after the command words, defined by `:name:type:source` |
| **completion** | Tab-completion during typing |
| **expansion** | Expanding abbreviated commands for execution |
| **command expression** | The shell expression after the colon in a command definition (e.g., `echo \0 \1`) |
| **command filter** | A prefix or exact match passed to the AWK parser's `command_filter` parameter |
| **flat format** | The one-line-per-command representation in `__CLI_CONFIG` |
| **dynamic command** | A command whose last word is `$variable`, `&function`, or `val1\|val2` |
