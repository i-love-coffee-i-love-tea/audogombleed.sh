# Configuration Reference

A configuration file defines a command tree. Indentation and hierarchy define
where a command resides in the tree. Arguments have a type which determines
how completion works.

A config file must contain a `[commands]` section and can optionally contain
an `[env]` section.

The default config filename is `~/.${NAME}.conf`, where `NAME` is the symlink
filename. This lets you create multiple independent CLIs with different configs.


## [commands] section

### Simple command

    [commands]
    first-word: echo

This creates one command. `first-word` is the command name, `echo` is what
gets executed.

### Command tree

Indentation creates hierarchy. The indentation width of the first indented
line sets the convention for the rest of the file.

    [commands]
    cd
        git-projects
            project1: cd ~/git/project1
            project2: cd ~/git/project2

This creates commands like `cd git-projects project1`.

### Command words vs. arguments

A command is a path through the tree. In `mycli deploy staging`, both
`deploy` and `staging` are **command words** — defined by indentation in
the config file.

Commands can also have **arguments** — values typed after the command
words. In `mycli deploy staging v2`, `v2` is an argument. Arguments are
defined by `:name:type:source` lines and substituted into placeholders
like `\1`. If no arguments are defined, the command has none.

The last command word can also be dynamic — provided by a variable
(`$namespaces`), a function (`&get_namespaces`), or a static list
(`staging|production`). This blurs the line: the user types what looks
like an argument, but it's actually selecting a command word. See
[Advanced Command Configurations](03-advanced-command-configurations.md)
for details.

### Comments

Lines beginning with `#` are comments. They document the next command or
tree element:

    [commands]
    # deployment commands
    deploy
        # deploy to production
        prod: ./deploy.sh prod
        # deploy to staging
        staging: ./deploy.sh staging

Display help by appending `?` or `-h` to a command:

    $ mycli deploy ?
    deployment commands

#### Comment types

There are four levels of comments:

**Global header** — consecutive `#` lines at the very top of `[commands]`,
terminated by a blank line. Appears at the top of `mycli ?` output, above
all section headings. Use for CLI name, description, or usage hints:

    [commands]
    # mycli — manage widgets and gadgets
    # Run 'mycli <command> ?' for help.

    # deployment commands
    deploy
        ...

    $ mycli ?
      mycli — manage widgets and gadgets
      Run 'mycli <command> ?' for help.

      deployment commands
        d[eploy] ...

If the blank line is omitted, the `#` lines become section headings for the
first group instead:

    [commands]
    # deployment commands
    deploy
        ...

    $ mycli ?
      deployment commands
        d[eploy] ...

**Section headings** — a `#` comment at the top level (no indentation) before
a command group. Appears above the group in global help (`mycli ?`), with a
2-space indent:

    # deployment commands
    deploy
        ...

    $ mycli ?
      deployment commands
        d[eploy] ...

**Command help** — a `#` comment directly before a command (at the same
indentation level). Appears inline with the command in help output:

    deploy
        # deploy to production
        prod: ./deploy.sh prod

    $ mycli deploy ?
      d[eploy] p[rod]          deploy to production

A `#` comment before a standalone (non-group) top-level command also appears
inline:

    # show version
    version: echo "1.0.0"

    $ mycli ?
      v[ersion]                show version

**Detail comments** — lines beginning with `##` (double hash). These provide
extra detail text shown when viewing a specific command's help (`mycli cmd ?`),
displayed below the command's `#` help text:

    deploy
        ## requires AWS credentials in ~/.aws/credentials
        ## runs in us-east-1 by default
        # deploy to production
        prod: ./deploy.sh prod

    $ mycli deploy prod ?
      deploy to production
        requires AWS credentials in ~/.aws/credentials
        runs in us-east-1 by default

`##` comments can also be placed before a command group to provide group-level
detail:

    ## all deploy commands require AWS credentials
    deploy
        ...

    $ mycli deploy ?
    all deploy commands require AWS credentials
      d[eploy] ...

### Argument placeholders

`\0` is replaced by the last word of the command path (the word before the
colon). `\1`, `\2`, etc. are replaced by user-supplied arguments, matching
the `:name:type:source` definitions in order:

    [commands]
    deploy: ./deploy.sh --env \1 --tag \2
        :environment:list:staging|prod
        :tag:list:v1|v2|v3

    $ mycli deploy staging v2
    >> executes: ./deploy.sh --env staging --tag v2

`\1` maps to the first argument definition (`:environment`), `\2` to the
second (`:tag`). If not all placeholders are used, remaining arguments are
appended to the end of the command.

> [!NOTE]
> `\0` and `\1`+ come from different sources. `\0` is always the
> last command word — most useful with expanded commands (`$variable`,
> `&function`, `val1|val2`) where the expanded word carries meaning (e.g.,
> a namespace name). `\1`+ are the user's arguments after the command words.

### Optional arguments

Append `?` to the argument type to make it optional:

    [commands]
    deploy: ./deploy.sh \1 \2
        :target:list:staging|prod
        :tag:list?:v1|v2|v3

Here `:tag` is optional — the command executes with or without it.

> [!NOTE]
> Optional arguments must come after all required arguments.

### Argument types

| Type | Syntax | Completion behavior |
|------|--------|---------------------|
| Static list | `:arg:list:val1\|val2\|val3` | Fixed set of values |
| Variable list | `:arg:list:$VAR` | Values from a shell variable |
| Function list | `:arg:eval:function_name` | Values from function output |
| Default value | `:arg:value:default` | Uses default (not a completion list) |
| String | `:arg:STRING` | Free-form string |
| Integer | `:arg:INTEGER` | Integer value |
| Integer range | `:arg:int_range:min-max` | Integer within range (inclusive) |
| File | `:arg:FILE` | File path completion |
| Directory | `:arg:DIR` | Directory path completion |
| Env variable | `:arg:ENVVAR` | Environment variable names |
| User | `:arg:USER` | System usernames |
| Group | `:arg:GROUP` | System group names |
| SSH host | `:arg:SSH_HOST` | Hosts from `~/.ssh/config` |
| Block device | `:arg:BLKDEV` | Block device names |
| Service | `:arg:SERVICE` | service names (systemd / rc.d) |

Any type can be made optional by appending `?` (e.g., `:arg:list?:val1|val2`).

An optional description can be appended as the last field. In types
with a value field (list, int_range, eval) it comes after the value;
in all other types it comes directly after the type:

    :name:type:description              (STRING, INTEGER, FILE, etc.)
    :name:type:value:description        (list, int_range, eval)

> [!NOTE]
> Descriptions appear as `[description]` suffixes in zsh tab completions.
> They are ignored in bash.

    [commands]
    deploy: ./deploy.sh \1
        :env:list:staging|prod:target environment
        :tag:list?:v1|v2|v3:release tag
        :port:int_range:1-65535:TCP port number


## [env] section

All lines in the `[env]` section are sourced before each completion and
command execution, with one exception: the `include_commands_from` keyword
is handled differently (see
[04-hierarchical-configuration.md](04-hierarchical-configuration.md)).

Everything possible in a shell script is possible here.

> [!IMPORTANT]
> The `[env]` section runs on every tab completion and every command
> execution. Avoid slow operations (network calls, heavy computation) in
> `[env]` — they will block completion and add latency to every invocation.
> If you need dynamic values for argument completion, use `eval` argument
> types instead, which run only at completion time.

### Purpose

- Set CLI configuration options
- Define variables or functions for argument completion lists
- Source other shell scripts
- Include other config files with `include_commands_from`

### Source shell scripts

Use `source` to load variables, functions, and CLI configuration from
external files. This is the way to externalize your `[env]` section into
a separate file:

    source ~/.mycli-env.conf

The sourced file can contain the same content as `[env]`: variable
assignments, `__CLI_` options, function definitions, and exports. Paths
with `~` are expanded to `$HOME`.

    source ~/bin/custom-cli-function.sh

> [!WARNING]
> The `[env]` section (including `source` directives) runs in the current
> shell — this is necessary so that tab completion can access the defined
> variables and functions. This means sourced files can overwrite existing
> shell variables or functions. Use unique variable names or prefix them to
> avoid collisions.

### Define variables and functions

    MY_OPTIONS="opt1 opt2 opt3"

    function example_function { echo "foo"; echo "bar"; }

    function multiline_example {
        echo "foo"
        echo "bar"
    }


## Configuration options

Set these in the `[env]` section:

| Option | Default | Description |
|--------|---------|-------------|
| `__CLI_CFG_EXEC_SILENT` | `"n"` | Suppress all CLI output (for script use) |
| `__CLI_CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS` | `"y"` | Allow abbreviated command words |
| `__CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS` | `"n"` | Allow abbreviated argument values (experimental) |
| `__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS` | `"y"` | Ask user to confirm expanded commands |
| `__CLI_CFG_EXEC_PRINT_HELP_ON_INCOMPLETE_ARGS` | `"y"` | Print help when not all arguments are supplied |
| `__CLI_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY` | `"n"` | Only allow values from completion lists |
| `__CLI_CFG_EXEC_ALWAYS_RETURN_0` | `"n"` | Always return exit code 0 (useful for shell history) |
| `__CLI_CFG_LOG_LEVEL` | `0` | Log level (0=off, 4=debug, writes to `/tmp/cli-XXXXXX-{bash,zsh}.log`) |


### Detailed option descriptions

#### `__CLI_CFG_LOG_LEVEL` (default: 0)

- 0 means off
- 4 means debug

If set to 4, a log file is created under `/tmp` (filename uses `mktemp`, so
the exact name varies — check `ls /tmp/cli-*` to find it).

> [!NOTE]
> Debug output slows the CLI down noticeably.

#### `__CLI_CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS` (default: "y")

Allow abbreviated commands. For example, with commands `docker list containers`
and `docker list images`, you can type `d l c` and it expands to
`docker list containers` — as long as the abbreviation is unambiguous.

You can also use no-space abbreviations by concatenating the first letters of
each word. For example, `dlc` expands to `docker list containers`, and `ijfm`
expands to `install jar from maven`. This works as long as the abbreviation
is unambiguous.

#### `__CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS` (default: "n") — experimental

> [!CAUTION]
> Allow abbreviated argument values. Disabled by default because it can be
> risky — you should know exactly what is happening. The environment can
> change between tab-completion and execution (e.g. new files appear, a
> dynamic eval list changes), so an abbreviation that matched one value at
> completion time may silently resolve to a different value at execution
> time. Use at your own risk.

#### `__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS` (default: "y")

When the command expansion changes the submitted command, the user is asked
to confirm before execution.

#### `__CLI_CFG_EXEC_PRINT_HELP_ON_INCOMPLETE_ARGS` (default: "y")

Print help output for the command if not all required arguments were supplied.

#### `__CLI_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY` (default: "n")

Only allow values from the auto complete list. By default, even if an argument
has a completion list of `xxx, yyy`, you can still submit `zzz`.

#### `__CLI_CFG_EXEC_ALWAYS_RETURN_0` (default: "n")

Always return exit code 0. Useful on Ubuntu where bash is configured to only
keep succeeding commands in history. Disabled by default so scripts can access
the real exit code.

#### `__CLI_CFG_EXEC_SILENT` (default: "n")

Suppress all CLI output. When set to `"y"`, interactive features that
produce output are also disabled:

    __CLI_CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS="n"
    __CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS="n"

This is because abbreviated command expansion normally asks the user to
confirm before execution — that prompt is impossible when output is
suppressed. The same overrides are applied by `-b` / `--batch`.


## CLI command line arguments

### `-b` / `--batch`

Run in script mode. Disables all output on stdout and stderr and features
that require interactive input (command expansion).

- Sets `__CLI_CFG_EXEC_SILENT="y"`
- Sets `__CLI_CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS="n"`
- Sets `__CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS="n"`

### `--version`

Print the script version and exit.

The following options are for development and debugging only:

- `--cli-print-awk-script` — print the embedded AWK config parser script
- `--cli-print-env` — print the parsed `[env]` section
- `--cli-run-awk-command` — run the embedded AWK config parser directly


## Exit status

| Code | Meaning |
|------|---------|
| 49 | Script called with wrong name — create a symlink |
| 50 | No command supplied |
| 51 | Abbreviated command expansion failed |
| 52 | Not all positional arguments could be resolved |
| 53 | Not enough arguments provided |
| 54 | Config file rejected — permissions or symlink issue |
| 127 | Command not found by the shell |


## Zsh support

To enable tab completion in zsh, add the following to your `.zshrc`:

    autoload bashcompinit
    bashcompinit

    # if you want to use completion with an alias
    setopt completealiases
