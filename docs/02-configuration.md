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

### Argument placeholders

`\0` is replaced by the last command word. `\1`, `\2`, etc. are replaced by
positional arguments:

    [commands]
    echo: echo \2 \1
        :first:list:one|two
        :second:list:alpha|beta

    $ mycli echo one alpha
    >> executes: echo alpha one

If not all placeholders are used, remaining arguments are appended to the end.


## [env] section

All lines in the `[env]` section are sourced before each completion and
command execution, with one exception: the `include_commands_from` keyword
is handled differently (see
[04-hierarchical-configuration.md](04-hierarchical-configuration.md)).

Everything possible in a shell script is possible here.

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

**Warning:** the `[env]` section (including `source` directives) runs in
the current shell — this is necessary so that tab completion can access
the defined variables and functions. This means sourced files can
overwrite existing shell variables or functions. Use unique variable
names or prefix them to avoid collisions.

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
| `__CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS` | `"n"` | Allow abbreviated argument values |
| `__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS` | `"y"` | Ask user to confirm expanded commands |
| `__CLI_CFG_EXEC_PRINT_HELP_ON_INCOMPLETE_ARGS` | `"y"` | Print help when not all arguments are supplied |
| `__CLI_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY` | `"n"` | Only allow values from completion lists |
| `__CLI_CFG_EXEC_ALWAYS_RETURN_0` | `"n"` | Always return exit code 0 (useful for shell history) |
| `__CLI_CFG_LOG_LEVEL` | `0` | Log level (0=off, 4=debug, writes to `/tmp/cli-bash.log`) |


### Detailed option descriptions

#### `__CLI_CFG_LOG_LEVEL` (default: 0)

- 0 means off
- 4 means debug

If set to 4, a log file is created under `/tmp` (filename uses `mktemp`, so
the exact name varies — check `ls /tmp/cli-*` to find it).

NOTE: Debug output slows the CLI down noticeably.

#### `__CLI_CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS` (default: "y")

Allow abbreviated commands. For example, with commands `docker list containers`
and `docker list images`, you can type `d l c` and it expands to
`docker list containers` — as long as the abbreviation is unambiguous.

#### `__CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS` (default: "n")

Allow abbreviated argument values. Disabled by default because it can be
risky — you should know exactly what is happening.

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

Suppress all CLI output on stdout and stderr. When set to `"y"`, the
following are also overridden:

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

### `--cli-print-awk-script`

Prints the embedded AWK script (for development).

### `--cli-run-awk-command`

Runs the embedded AWK config parser script (for development).


## Exit status

| Code | Meaning |
|------|---------|
| 49 | Script called with wrong name — create a symlink |
| 50 | No command supplied |
| 51 | Abbreviated command expansion failed |
| 52 | Not all positional arguments could be resolved |
| 53 | Not enough arguments provided |
| 127 | Command not found by the shell |


## Zsh support

To enable tab completion in zsh, add the following to your `.zshrc`:

    autoload bashcompinit
    bashcompinit

    # if you want to use completion with an alias
    setopt completealiases
