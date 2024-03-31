# Audogombleed

This script can be used to easily create CLIs with auto completable command trees.
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

On hitting <enter> the `echo` command will be executed and all arguments that follow `first-word`
on the command line will be appended.


### Command tree configuration

Where it really starts to get useful is when the hierarchical command tree structure comes into play.

Let's look at a more complex command tree now, with a demonstration of using variables.
Since autocompletion scripts are sourced, you can create directory bookmarks.

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

    cd git-projects projects1
    cd git-projects projects2
    cd git-projects projects3
    cd app1 projects
    cd app2 projects1
    cd app3 projects1
    

Defined variables can be used in command expressions.
`\0` will be replaced by the last command word. 

See [docs/03-advanced-command-configuration.md](https://github.com/i-love-coffee-i-love-tea/audogombleed.sh/blob/main/docs/03-advanced-command-configuration.md).
for more info about command definition possibilities.


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

If the CLI is executed with '?' as sole argument, it will print the help for
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


# Exit status

In case of failed command execution the script uses the exit status to indicate
the reason

	- 49 script was called with wrong name. need to create a link and use this.
	- 50 no command supplied
	- 51 attempt to expand abbreviated command failed
	- 52 not all positional arguments could be resolved. not enough arguments.
	- 53 not enough arguments provided


# Zsh support with bashcompinit
.zshrc:

    autoload bashcompinit
    bashcompinit

	# if you want to use completion with an alias you need to set this	
    setopt completealiases
