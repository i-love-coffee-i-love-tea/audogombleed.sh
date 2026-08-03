[![Automated Bash Tests](https://github.com/i-love-coffee-i-love-tea/audogombleed.sh/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/i-love-coffee-i-love-tea/audogombleed.sh/actions/workflows/main.yml)

# Audogombleed

This script can be used to easily create CLIs with auto completable command trees.
All you need to do is to create a link to the main script and a simple configuration file.

**Goal**: Make auto completion quick to setup and customize without coding.

### Who is this for?

If you are working a lot in the shell, like me and have accumulated so many commands
and scripts that you have trouble organizing them and remembering where they are and what
arguments they require, this might be of interest to you.

Or maybe you want to create a descriptive CLI for the program or script you are developing.

### But why don't you just use shell autocompletion? Bash and ZSH both have support for it?!

This script of course makes use of bash and zsh completion features. My problem with it was,
that it is not declarative. This means, if you want to use auto completion with 20 scripts, you
need to have 20 auto completion files. Or you write one function that can handle every one of your
scripts. This would get you very much in the direction this script took. 

The next problem is that it is all hard coded. If you change a script parameter name or add or remove a parameter,
you need to also change code in the auto completion function to keep it in sync with the implementation.

**This script implements a declarative approach to autocompletion.**
You can add or remove words in auto completions for commands and restructure the completion
tree by copying and pasting and changing indentation, etc.

## Quick Start

1. **Create a symlink** — the filename becomes the CLI name, determines the
   config file path, and is used to register tab completion. Using a symlink
   (instead of copying the script) means all your CLIs share one source file —
   update `audogombleed.sh` once and every CLI picks up the new version:

       ln -s ~/bin/audogombleed.sh ~/bin/mycli

2. **Create a config file** — must match the symlink name (`~/$NAME.conf`).
   A `[commands]` section is the minimum:

       cat > ~/.mycli.conf <<'EOF'
       [commands]
       hello: echo "hello world"
       EOF

3. **Source the symlink** — this registers the tab-completion function with
   your shell (`complete` in bash, `compdef` in zsh):

       source ~/bin/mycli

4. **Create an alias** — sourcing only registers completions. The alias makes
   the command name invoke `_cli_execute` in the current shell (so commands
   can export variables, cd into directories, etc.):

       alias mycli='_cli_execute'

5. **Try it** — press TAB to see completions, then execute:

       mycli <TAB><TAB>
       mycli hello

# Configuration

A configuration file defines a command tree. 
Indentation and previous hierarchy elements define where a command will reside in the tree. 
It also defines command arguments. Arguments have a type which determines which function, variable or static list will be used for completion.

A config file must at least contain a [commands] section and can contain an [env] section.

The default configuration filename is ~/.${0}.conf. So the script can be used to
create multi CLI trees with different names and configs. The config name is
derived from the program/alias name.

## Comments

Lines beginning with # are comment lines. Comments always
are related to the following command or tree element.
All comment lines before a command or tree element belong to
the following element.


## command configuration in the [commands] section

The commands are configured in [commands] section in the config file.

### Most simple command configuration

Let's first look at a an example of a most simple command configuration:

    [commands]
    first-word: echo

Now, if we created our cli with `ln -s ~/bin/audogombleed.sh ~/bin/cli` and
have created an alias `alias cli='_cli_execute'`, we can
write

    $ cli <TAB><TAB>

and it will be completed, because there is only one command available at the root level.

    $ cli first-word

On hitting `<enter>` the `echo` command will be executed and all arguments that follow `first-word`
on the command line will be appended.


### Command tree configuration

Where it really starts to get useful is when the hierarchical command tree structure comes into play.

Let's look at a more complex command tree now, with a demonstration of using variables.
Since autocompletion scripts are sourced, you can create directory bookmarks with this configuration.
The indentation can be freely chosen. The indentation of the first indented line after the beginning of a
command tree decides how the rest of the file must be indented (meaning which indentation depth is one level
in tree depth).


    [env]
    GIT_ROOT="~/git/some/deep/directory/structure/in/a/large/git/repository/"
    PROJECTS_DIR="/var/server/group/group_x/projects"
    [commands]
    cd
        git-projects
            project1: cd $GIT_ROOT/\0
            project2: cd $GIT_ROOT/\0
            project3: cd $GIT_ROOT/\0
        app-instances
            app1: cd $PROJECTS_DIR/\0
            app2: cd $PROJECTS_DIR/\0
            app3: cd $PROJECTS_DIR/\0

It will create these commands with full autocompletion support:

    cd git-projects project1
    cd git-projects project2
    cd git-projects project3
    cd app-instances app1
    cd app-instances app2
    cd app-instances app3
    

Defined variables can be used in command expressions.
`\0` will be replaced by the last command word. 

See [docs/03-advanced-command-configuration.md](https://github.com/i-love-coffee-i-love-tea/audogombleed.sh/blob/main/docs/03-advanced-command-configuration.md)
for more info about command definition possibilities.

### Argument types

Arguments are defined with `:name:type:source` syntax:

| Type | Syntax | Description |
|------|--------|-------------|
| Static list | `:arg:list:val1\|val2\|val3` | Complete from a fixed set of values |
| Variable list | `:arg:list:$VAR` | Complete from a shell variable (words separated by spaces or newlines) |
| Function list | `:arg:eval:function_name` | Complete from the output of a shell function |
| Default value | `:arg:value:default` | Use a default value (not a completion list) |
| File | `:arg:FILE` | Complete file paths |
| Directory | `:arg:DIR` | Complete directory paths |


## optional [env] section

### Configuration options

Set these in the `[env]` section of your config file:

| Option | Default | Description |
|--------|---------|-------------|
| `__CLI_CFG_EXEC_SILENT` | `"n"` | Suppress all CLI output (for script use) |
| `__CLI_CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS` | `"y"` | Allow abbreviated command words |
| `__CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS` | `"n"` | Allow abbreviated argument values |
| `__CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS` | `"y"` | Ask user to confirm expanded commands |
| `__CLI_CFG_EXEC_PRINT_HELP_ON_INCOMPLETE_ARGS` | `"y"` | Print help when not all arguments are supplied |
| `__CLI_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY` | `"n"` | Only allow values from completion lists |
| `__CLI_CFG_EXEC_ALWAYS_RETURN_0` | `"n"` | Always return exit code 0 (useful for shell history) |
| `__CLI_CFG_EXEC_SUBPROCESS` | `"n"` | Execute commands in a subprocess (`bash -c`) instead of the current shell. `cd`, `export`, and variable assignments won't affect the parent shell. |
| `__CLI_CFG_LOG_LEVEL` | `0` | Log level (0=off, 4=debug, writes to `/tmp/cli-bash.log`) |

See [docs/02-configuration-options.md](https://github.com/i-love-coffee-i-love-tea/audogombleed.sh/blob/main/docs/02-configuration-options.md) for details.

### setting configuration options in the [env] section

All lines in the `[env]` section are sourced before each completion
and command execution, with one exemption: The `include_commands_from` keyword
is handled differently (see [docs/04-hierarchical-configuration.md](https://github.com/i-love-coffee-i-love-tea/audogombleed.sh/blob/main/docs/04-hierarchical-configuration.md)).

Everything that is possible in a shell script is possible here. Most useful to define
array variables or functions to create argument lists for completions.

Purpose:

- set CLI options
- define array variables or functions to create argument lists for completions
- include function and variable definitions from other shell scripts
- include other config files with the `include_commands_from` directive.

#### Source shell scripts

    source ~/bin/custom-cli-function.sh
    
#### Define/set variables and functions directly


Function example:

    function example_function { echo "foo"; echo "bar"; }

Multiline function example. 

    function example_function {
        echo "foo"
        echo "bar"
    }

## CLI command line arguments

## -b | --batch

Run in script mode. This disables all output on stdout and stderr
and those features which might require interactive user input.
Namely only command expansion at the moment.

- Sets __CLI_CFG_SILENT="y"
- Sets __CLI_CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS="n"
- Sets __CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS="n"


## --cli-print-awk-script

Prints the embedded AWK script

## --cli-run-awk-command

Runs the embedded AWK config parser script. Only there for development purposes.


## Builtin Help Output

If the CLI is executed with '?' as sole argument, it will print the help for
all configured commands.

'?' can also be append to complete or incomplete commands.

> **Note**: If `?` doesn't work, it may be expanded by the shell as a glob pattern.
> Use `-h` or `\?` instead. See [FAQ](docs/10-FAQ.md).

Example configuration:

    [commands]
    # help for 'this' command group
    this
        # help for 'this is-the' command group
        is-the
            # help for command
            command: echo it does nothing

Display command help by appending a '?' or '-h' to the command line.
When appended to a command group it will list the available 
commands in the group/tree

    $ cli this is-the ?
    help for 'this is-the' command group

        command

When appended to a command, it will print detailed command help, if available

    $ cli this is-the command ?
    help for command
         

Can be used to print help texts if there are any in the configuration file.
Displays the optional parts of command words in square brackets.

Example help output:

    $ cli logs ?

      output tomcat logs

        lo[gs] w[ebapp]                                            view webapp logs
        lo[gs] o[sgi-framework]                                    view osgi framework logs
        lo[gs] c[atalina.out]                                      view catalina.out



## Abbreviated Commands

Commands can be submitted in an abbreviated form as long as all command words resolve unambiguously.

Arguments can be completed too and not only command words, but this is disabled by default,
because it is kind of risky. You should know exactly what is happening and what can go wrong
if you aren't careful with this.


## Example of command expansion:

Example config mimicking the docker cli for demonstration:

    [commands]
    docker
        list
            containers: docker list containers
            images: docker list images

Considering the configuration above, you could execute `cli d l c` and it would expand to `cli docker list containers`

    $ cli d l c


## Exit status

In case of failed command execution the script uses the exit status to indicate
the reason

- 49 script was called with wrong name. need to create a link and use this.
- 50 no command supplied
- 51 attempt to expand abbreviated command failed
- 52 not all positional arguments could be resolved. not enough arguments.
- 53 not enough arguments provided
- 127 the command in the resolved command expression was not found by the shell


## Zsh support with bashcompinit

To enable tab completion in zsh, add the following to your `.zshrc`:

    autoload bashcompinit
    bashcompinit

    # if you want to use completion with an alias you need to set this
    setopt completealiases
