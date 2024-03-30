# Audogombleed

This script can be used to easily create CLI interfaces with auto completable command trees.
All you need to do is to create a link to the main script and a simple configuration file.

The configuration file defines a command tree. 
Indentation and previous hierarchy elements define where a command will reside in the tree. 
It also defines command arguments. Arguments have a type which determines which function, variable or static list will be used for completion.


### Who is this for?

If you are working a lot in the shell, like me and have accumulated so many commands
and scripts that you have trouble organizing them and remembering where they are and what
arguments they require, this might be of interest to you.

Or maybe you want to create a descriptive CLI for the program or script you are developing.


# Configuration

A config file must at least contain a [commands] section and can contain an [env] section.

The default configuration filename is ~/.${0}.conf. So the script can be used to
create multi CLI trees with different names and configs. The config name is
derived from the program/alias name.

## comments

Lines beginning with # are comment lines. Comments always
are related to the following command or tree element.
All comment lines before a command or tree element belong to
the following element.

## optional [env] section

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


## command configuration in the [commands] section

The commands are configured in [commands] section in the config file.



# CLI command line arguments

## -b | --batch

Run in script mode. This disables all output on stdout and stderr
and those features which might require interactive user input.
Namely only command expansion at the moment.

- Sets __CLI_CFG_SILENT="y"
- Sets __CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS="n"


## --cli-print-awk-script

Prints the embedded AWK script

## --cli-run-awk-command

Runs the embedded AWK config parser script. Only there for development purposes.


# Builtin Help Output

If the CLI is executed it just a '?' as argument it will print the help for
all configured commands.

'?' can also be append to complete or incomplete commands.

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
Displays the optinal parts of command words in square brackets.

Example help output:

    $ cli logs ?

      | output tomcat logs

        lo[gs] w[ebapp]                                            view webapp logs
        lo[gs] o[sgi-framework]                                    view osgi framework logs
        lo[gs] c[atalina.out]                                      view catalina.out





# Abbreviated Commands

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

Considering the configuration above, you could execute `cluster-cli d l c` and it would expand to `cluster-cli docker list containers`

    $ cluster-cli 



# Zsh support with bashcompinit
.zshrc:

    autoload bashcompinit
    bashcompinit
    setopt completealiases
