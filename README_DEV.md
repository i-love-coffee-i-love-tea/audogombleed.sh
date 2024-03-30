# generic autocomplete tree - development notes

All features work in bash and zsh, apart from one:
In zsh the autocompletions can additionally use description labels, which
aren't supported in bash.

The core of the script is a config parser developed in AWK.
It is embedded in the shell script and can be exported for delepment purposes as described below.

## global variables 

All used variables begin with `__CLI_`

All but `__CLI_VERSION` are initialized during completion and command execution

To list them all you can use the shell builtin compgen in bash (and zsh with loaded bash completion support, see `README.md`)

	compgen -A variable | grep ^__CLI_

## global functions

All functions begin with `_cli_`

Functions are loaded by sourcing the cli script


Registered completion functions can be listed by calling complete without arguments

	$ complete | grep ^_cli



## Embedded AWK script for config parsing

Serves multiple purposes:

- flattens the tree to one line per command for the shell script 
- is used to query for commands and their arguments
- exports argument completion environment vars to the CLI script
- is used to query for command help texts
- extracts the [env] content from the config file


For development of the embedded AWK script I use this cycle:

1. Export the AWK script

    `$ cli --cli-print-awk-script > cli.awk` 

2. Edit cli.awk

3. Test run

    `$ awk -f cli awk output=commands command_filter=""`

3. Run syntax check 

    `$ awk --lint -f cli.awk`

4. If everything is good, copy the script to mouse buffer

    `$ cat cli.awk | xclip`

5. Edit CLI file to embed the new AWK script
   search for AWK_EOF
   remove old script
   paste the mouse buffer with middle click

To run the embedded awk script it can be executed like shown below.
The script parameters are described in the comments in the script header.

   `$ cli --cli-run-awk-script output=command_names`

## Linting

I use shellcheck to find sources of uninteded errors.


   `$ shellcheck cli.sh`

## Bash tipps

### performance / completion and execution latency

Latency is important. It makes your computer feel slow or quick.
It may sound obvious, but it's very very important for a good user experience.

Therefore, in auto completion functons, do not, unless absolutely necessary

- use subshells
- call external programs 



Script execution time of 400 ms definitely makes it feel sluggish 

- About 200ms is OK
- 100ms is good
- <100ms is very good


time it with the `time` command

	$ time <yourcli> <yourcommand>


## tracing 

	strace -c $YOUR_CLI_COMMAND



## Glossary

### 'completion' vs. 'expansion' in the code

Arguments and command names which the user provided are completed
or expanded to a matching valid word, if there is an unambiguous
match for the word position. 

I use 'expand' instead of 'complete' in variable and function naming
to differentiate between auto completion during typing and
expansion of submitted commands for execution, to allow
abbreviation of commands.


## AWK config parser usage examples: 

	% cli --cli-run-awk-command output=commands command_filter="filter bla rating"
	__COMMAND=filter bla rating
	__COMMAND_ARG[0]="list:lt|le|qe|gt|ge:comparison operator"
	__COMMAND_ARG[1]="int_range:1-5:rating value to compare against"

	% cli --cli-run-awk-command output=commands command_filter="set comment"   
	__COMMAND=set comment
	__COMMAND_ARG[0]="INTEGER"
	__COMMAND_ARG[1]="STRING"
