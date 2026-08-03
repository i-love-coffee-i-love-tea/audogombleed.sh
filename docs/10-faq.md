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


## Tab completion doesn't work

Make sure you sourced the symlink and created the alias:

    source ~/bin/mycli
    alias mycli='_cli_execute'

Both lines must be in your `.bashrc` or `.zshrc`. The source registers the
completion function; the alias makes the command name invoke execution in the
current shell.


## Config changes not taking effect

The config file is re-read on every completion and execution. If changes
don't appear:

- Check that the config filename matches the symlink name (`~/.NAME.conf`)
- Check for syntax errors — unclosed quotes, missing section headers
- Set `__CLI_CFG_LOG_LEVEL=4` in the `[env]` section and check the log file
  (`/tmp/cli-bash.log` or `/tmp/cli-zsh.log`)


## Zsh completions not working

Add these to your `.zshrc`:

    autoload bashcompinit
    bashcompinit

If you use an alias for the CLI command, also add:

    setopt completealiases


## How does command abbreviation work?

Commands can be submitted in abbreviated form as long as all command words
resolve unambiguously. For example, with this config:

    [commands]
    docker
        list
            containers: docker list containers
            images: docker list images

You can execute `cli d l c` and it expands to `cli docker list containers`.

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
- Bash: `/tmp/cli-bash.log`
- Zsh: `/tmp/cli-zsh.log`

NOTE: Debug output slows the CLI down noticeably.


## How do I use this with multiple CLIs?

Each symlink gets its own config file and variable namespace:

    ln -s ~/bin/audogombleed.sh ~/bin/cluster
    ln -s ~/bin/audogombleed.sh ~/bin/music

This creates two independent CLIs:
- `cluster` reads `~/.cluster.conf`
- `music` reads `~/.music.conf`

Variables are namespaced by the CLI name, so they don't interfere with each
other.
