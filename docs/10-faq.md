# FAQ

## Why doesn't the command help print anything?

Because of shell globbing, the `?` at the end of the line is replaced by
matching filenames if there are single-character files in your working
directory.

    mycli ?

Solutions:

- Change to a directory without single-character files
- Escape the `?` with a backslash: `mycli \?`
- Use `-h` or `-?` instead: `mycli -h`


## Why doesn't tab completion work?

Make sure you sourced the symlink and created the alias:

    source ~/bin/mycli
    alias mycli='_cli_execute'

Both lines must be in your `.bashrc` or `.zshrc`. The source registers the
completion function; the alias makes the command name invoke execution in the
current shell.


## Why aren't my config changes taking effect?

The config file is re-read on every completion and execution. If changes
don't appear:

- Check that the config filename matches the symlink name (`~/.NAME.conf`)
- Check for syntax errors — unclosed quotes, missing section headers
- Set `__CLI_CFG_LOG_LEVEL=4` in the `[env]` section and check the log file
  (`/tmp/cli-bash.log` or `/tmp/cli-zsh.log`)


## Why don't zsh completions work?

Add these to your `.zshrc`:

    autoload bashcompinit
    bashcompinit

If you use an alias for the CLI command, also add:

    setopt completealiases


## Why does zsh exit the shell on errors when sourced from `zsh -c`?

The `_cli_is_sourced` function uses `$zsh_eval_context` to detect whether
the script was sourced or executed. In zsh, this variable loses the `file`
token after sourcing completes, so functions called afterwards see
`cmdarg` instead of `cmdarg file`.

This affects the `_cli_exit_if_not_sourced` error path: when a command
fails (e.g. an unrecognized abbreviation), the script calls `exit`
instead of `return` if invoked via `zsh -c 'source ./cli; ...'`.

**Impact:** abbreviation expansion and other features that rely on
`_cli_exit_if_not_sourced` returning (instead of exiting) will terminate
the calling shell when an error occurs under `zsh -c`.

**Workaround:** use the alias (`alias mycli='_cli_execute'`) or invoke
the CLI directly (`zsh ./testcli cmd args`) instead of sourcing from
`zsh -c`.


## How does command abbreviation work?

Commands can be submitted in abbreviated form as long as all command words
resolve unambiguously. For example, with this config:

    [commands]
    get
        pods: kubectl get pods
        services: kubectl get svc
        deployments: kubectl get deploy

You can execute `cli g p` and it expands to `cli get pods`.

By default, the CLI asks for confirmation before executing expanded commands
(`CFG_EXEC_ACK_EXPANDED_COMMANDS="y"`). If you want to keep this safety net
for interactive use but need unattended execution in scripts, pass `-b` or
`--batch` — it disables the confirmation prompt (and all other interactive
output) for that invocation.


## How do I debug my config?

Set the log level in the `[env]` section:

    [env]
    __CLI_CFG_LOG_LEVEL=4

Then check the log file:
- Bash: `/tmp/cli-XXXXXX-bash.log`
- Zsh: `/tmp/cli-XXXXXX-zsh.log`

The log filename uses `mktemp` so the `XXXXXX` portion is random. Check
`ls /tmp/cli-*` to find it.

NOTE: Debug output slows the CLI down noticeably.


## How do I use this with multiple CLIs?

Each symlink gets its own config file and variable namespace:

    ln -s ~/bin/derakht.sh ~/bin/cluster
    ln -s ~/bin/derakht.sh ~/bin/music

This creates two independent CLIs:
- `cluster` reads `~/.cluster.conf`
- `music` reads `~/.music.conf`

Variables are namespaced by the CLI name, so they don't interfere with each
other.
