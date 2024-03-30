# CLI Configuration Options

The following configuration options are available.
To change them put the variable assignment into you config file's `[env]` section.



## __CLI_CFG_LOG_LEVEL (default: 0)

May be helpful to understand why a command configuration does not work.
Is mainly intended for debugging of the cli script.

- 0 means off
- 4 means debug

Other levels are not yet used

If set to 4 a log file will be created under `/tmp`:

  - In zsh shells the file is `/tmp/cli-zsh.log`
  - In bash it is `/tmp/cli-bash.log`

NOTE: The debug output slows the CLI down noticeably.


## __CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS (default: "n")

Allow abbreviated commands. 


## __CLI_CFG_EXEC_ACK_EXPANDED_COMMANDS (default: "y")

Determines whether the user is asked to acknowledge expanded commands if
the command expansion changed the submitted command.


## __CLI_CFG_EXEC_PRINT_HELP_ON_INCOMPLETE_ARGS (default: "y")

Print help output for the command if not all arguments were supplied for execution.


## __CLI_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY (default: "n")

Can be used to only allow the options in the auto complete list for argument completion.
By default even if an argument is defined with an auto complete list of xxx, yyy
you can still submit a command with zzz for this argument position.


## __CLI_CFG_EXEC_ALWAYS_RETURN_0 (default: "n")

Why would you want it always return 0? On Ubuntu bash is configured to only
keep succeeding commands in the history. I didn't want to change this globally,
but sometimes, when i'm developing new scripts for example I want to try execution
and repeat it, without having to type the failed command again. 
In these cases you can set this to "y"

Of course when you want to use CLI commands in scripts you most likey want to
be able to access the real command exit code, so this is disable by default.


## __CLI_CFG_EXEC_SILENT (default: "n")

The CLI itself does not output anything on stdout and stderr, if set to "y"
