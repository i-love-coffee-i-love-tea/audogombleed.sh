2024-02-29
	DEV-0001: Implement a built in documentation mechanism
	
	DEV-0001 done
		- commands and command tree words can now be documented in the command tree config file
		- comment lines must start with (optional whitespace and then) a # character
		- comment lines followin after other comment lines are read as one comment
		- comments describe the first non comment line, describing a tree item or command, right after them
		- appending a ? after the command now outputs the comment

		Example config:

			# list commands
			# can be used to list stuff
			list
				# list containers
				container

		Example output

			$ cli list ?<enter>
			list commands
			can be used to list stuff

	Idea DEV-0002:
		- while i was documenting my current config i noticed that it is usually nice to have it document the commands
		  under that node, but the content would be similar to the command comments themselves. This violates the DRY principle
			=> the help for a parent node should output all its commands comments (DRY!)


2024-03-01

	DEV-0002 done

	New Ideas
		DEV-0003:
		- The help function (command with ? at end of line) simply prints all comand help lines beginning with ##
			- it would be nice if the command name would be prepended automatically, so documentation doesn't require duplication
		DEV-0004:
		- Command group help should print the command argument list after the commands, so it does not need to be documented manually

2024-03-02

	DEV-0003 done
	DEV-0004 done
	
	New Ideas:
		DEV-0005:
		- It shold be possible to supply a custom completion function that returns elements for completion of command arguments

	DEV-0005 done, It is now possible to use the 'eval' argument to specify a command that will be executed to find completable argument values

2024-03-03

	Bug:
		DEV-0006:
		- config parser does not support shallower tree level commands after deeper level
		
	DEV-0006 done, implemented indentation level detection, indentation width is variable, you just have to be consistent

2024-03-04

	New Ideas:
		DEV-0007:
		- command execution should support abbreviated commands
		  Example command definition: 

				tomcat
					 install-war
							 from-maven-repo: ...
							 from-git-project: ...
			
		  should be executable by writing:
				 tomcat i from-m
				 tomcat i from-g

		  every command word must be unambigious for the command to be expanded and executed

2024-03-06

	DEV-0007 done

					
2024-03-07

	DEV-0008: when completing commands during execution first display the completion result and ask
		the user to proceed with execution
		- add a config variable to disable, because
			- it is required for execution in scripts
			- when users have (gained) enough trust, they can use it more efficiently

	DEV-0008 done
		- new config option, to be set in [env] section of $0.conf file:
			__CLI_ACK_EXPANDED_COMMANDS=y enables it

2024-03-08

	New Ideas:

		DEV-0009 (declined): Add '?' command for help to autocompletion reply

		DEV-0010: Print command help, if available, when command is executed without all required
				  arguments 
	
		DEV-0011: Support combining the command trees of two individually usable configurations under one command

			NOTE: This is a very complex feature. I'm not yet convinced it would be good to implement it.
				  On the other hand the possible modularization if done right, could be very empowering for users

			Motivation: I am using multiple independent command tree configs and script names. 
						  Both contain many commands and i like having them separated in different files

				Example:
					# script for managing a cluster
					~/bin/cluster, with config ~/.cluster.conf

					# a script for sending commands to music on console player
					~/bin/moc, with config ~/.moc.conf

					# cluster and moc are links to the main script
					ln -s ~/bin/generic-command-tree.sh ~/bin/cluster
					ln -s ~/bin/generic-command-tree.sh ~/bin/moc

				# Example config with includes	
				~/.cli.conf:
					[env]
					include_config $HOME/.cluster.conf 
					include_config $HOME/.moc.conf moc
					[commands]
					example-cmd: echo example
					...

				# Included config
				~/.cluster.conf:
					[env]
					node1=
					[commands]
					# cluster node commands
					node
						# cluster node power commands
						power
							on: 	cluster_ipmi_power.sh on	
							off: 	cluster_ipmi_power.sh off	
							status: cluster_ipmi_power.sh status	

				# Included config
				~/moc.conf
					[env]
					...
					[commands]
					play: moc_play.sh
					pause: moc__pause.sh	
					

				# we have created a link to the cli.conf which includes the other configs
				ln -s ~/bin/generic-command-tree.sh ~/bin/cli	

				# then we should be able to use it like this:
				cli node power on
				# and, with the config inserted at a named command node 'moc'
				cli moc play
				# the cli config can also contain commands
				cli example-cmd
					

2024-03-13

	DEV-0012 Allow abbreviation not only of commands but of list arguments too

2024-03-14
		
	DEV-0012 done
		added new config options to control how arguments are expanded and execution of expanded args (could be dangerous because you did expect something else)


	DEV-0013 If there isn't a newline at the end of the config file the last command can not be executed
	DEV-0013 done

	DEV-0014 when the main script is called with '?' as only argument usage info for all commands should be printed


2024-03-15
	DEV-0014 done

2024-03-16
	
	New Ideas:
		
		DEV-0015 Currently completed args are appended to the command expression. Allow the use of placeholders, to insert args at custom postion
		
				
	DEV-0015 done: It is now possible to use \1, \2, etc as placeholders for the completed arguments.

			Usage example

				Command definition: myfind: find . -name "\1" -exec grep \2 {} \;
						:list_from_var:__CLI_FIND_EXPRESSIONS
						:list_from_var:__CLI_GREP_EXPRESSIONS

			If not all placeholders are used the rest of the arguments are appended

				Command definition: echotest:  echo \3
												:eval:echo one
												:eval:echo two
												:eval:echo three

				so the command
					 echotest one two three

				Would echo
					 three one two
						
	New Ideas:
			
		DEV-0016 Allow dynamic word lists as command tree node

			The problem I want to solve: Some configurations are more verbose than desired.
			
			# tomcat manager commands
			manager
				start: ~/bin/tomcat-manager.sh start
					:eval:installed_webapps
				stop: ~/bin/tomcat-manager.sh stop
					:eval:installed_webapps
				status: ~/bin/tomcat-manager.sh status
					:eval:installed_webapps

			All commands have the same argument. It would be desirable to be able to write it like this:

			manager
				start|stop|status: ~/bin/tomcat-manager.sh \0
					:eval:installed_webapps

			Since our arguments are starting with \1 it would be nice and logical to have the last part of the command
			name mapped to \0.

		DEV-0017 Considering the following configuration, when working with these commands, it is often
				 necessary to run multiple of them in succession. For example you stop an application, install jars,
				 then you may want to start it again. It would be nice if start, stop, status could be the last command part,
				 so we have command lines that are more convenient to edit. 


			Example of current configuration that has the described problem that the argument most often changed is not the last one:

			manager
				start|stop|status: ~/bin/tomcat-manager.sh \0
					:eval:installed_webapps
					
			Currently the best we could do is to rewrite the config and add one more word in depth to reverse the args:

			manager
				command:
					:eval:installed_webapps
					:list:start|stop|status

			------------------

			A better idea:

				Command tree nodes, previously had to be exactly one word per line, optionally prefixed and/or suffixed with withspace.
				To expand them to multiple commands, a list of constants, a variable or a function should be supplied
			
				=> One example for each

				xxx
					$list_of_webapps: <-- variable
						:list:start|stop|status

				yyy
					&installed_webapps: <-- function
						:list:start|stop|status

				zzz:
					webapp1|webapp2: <-- list of constants
						:list:start|stop|status


				These are expanded to multiple completable commands:

					zzz webapp1 <start|stop|status>
					zzz webapp2 <start|stop|status>

				It works the same way with variables and functions. The command will be expanded to multiple commands, one for each value in the variable or function return.


2024-03-17
				
	DEV-0016 done
	DEV-0017 done, implemented the "better idea"

2024-03-18

	New Ideas:
	
		DEV-0018 read $__CLI_DEBUG from config file instead of hard coded var in script
				 add $__CLI_DEBUG_FILE to select a different output file than the default
                 check if command can be executed before trying

		DEV-0019 Improve robustness.
					 Check if command_words_function exists before executing - DONE
				     check sourced files in env for existance - DONE
			
		DEV-0020 Improve help output by setting optional command letters in square brackets

			Example: 

				  bookmark management commands:

	    				a[dd] [comment]           bookmark the current mocp playing
						                          position with an optional comment
						g[oto] <bookmark_index>   jump to the bookmark playing position
						                          the file containing the bookmark must
						                          be playing in mocp
						fir[st]                   jump to first bookmark in the current file
						pre[vious]                jump to previous bookmark in the current file
						n[ext]                    jump to next bookmark in the current file
						la[st]                    jump to last bookmark in the current file
						                          If there was a manual jump before.
						                          If not the jump will be to the first bookmark 

		DEV-0021 Improve help output by dynamically setting the width of the first (command-) column to
				 bring the columns closer together when all commands are short and give enough space for long commands

		DEV-0022 Fix comments without space (#comment) and with only one word aren't recognized as comments

		DEV-0023 Change list_from_var type to list, make it work with lists and arrays

2024-03-19
	
	DEV-0018 done
	DEV-0020 done
	DEV-0021 done

	New Bugs:
	
		DEV-0024 Substitution of positional arguments doesn't work for args >=\2 anymore
		DEV-0025 Setting _CLI_DEBUG=0 in config works for autocompletion, but not during execution
	
	DEV-0024 done
	

	New Ideas/Bugs:

		DEV-0026 It would be very handy to be able to export variables with configured commands
				 This is not possible if the script is called in a subshell like all scripts are, unless
				 sourced. Since we already source it anyway, we can use the sourced functions to execute
			     commands. It is also a more resource efficient way to use it.

		DEV-0026 Solution: Moved main script execution lines to a function _cli_execute
		
				 If you want to make changes to the active user shell environment,
				 like exporting variables, you now can call that function by an alias.
				 The alias must be the same name as the sourced script. 

					alias mycli='_cli_execute' 

				 It works like this:

					1. during sourcing the name of the source file or link is read

					2. the autocompletion function is registered for this command name

					3. the alias maps this name to the _cli_execute function

					4. all command line parameters are passed to _cli_execute at execution time

		DEV-0027 Add a command line switch to override config values.
				 Motivation for it came from the need to disable error outputs when cli commands
				 are used in custom completion functions, without having to disable it completely.

		DEV-0028 Display argument types in help output

	DEV-0010 done, config option $__CLI_EXEC_PRINT_HELP_ON_INCOMPLETE_ARGS can be set to "n" to disable it
	DEV-0019 done
	DEV-0023 done change list_from_var to list, make list work with variables
	DEV-0026 done
	DEV-0027 done -b, --batch switch for silent execution, supresses error messages on stderr

	DEV-0011 done implemented a basic modular config. Other configs can be included like below
	
		[env]
		include_commands_from <other-config-file> <parent-command-name>	

		if parent-command-name is ROOT, the file is just attached without putting the
		commands in their own paren leaf


		From the pipe (7) manpage

			Note: although FIFOs have a pathname in the filesystem, I/O on FIFOs does
				  not involve operations on the underlying device (if there is one).


		
	Status summary:

		Still open
			DEV-0022 comments without space after comment character not parsed as comments
			DEV-0025 __CLI_DEBUG=0 doesn't work during execution

		Declined
			DEV-0009 add '?' to completion list

		rest is done


2024-03-21

	DEV-0025 done

	New Ideas: 

		DEV-0028 Introduce log levels DEBUG, INFO, WARN, ERROR
				 make the level configurable 0=OFF 1=ERROR 2=WARN 3=INFO 4=DEBUG
		
		DEV-0028 done, default is off and doesn't create a log file

		DEV-0029 Introduce a variable namespace by prefixing public __CLI_* 
				 variables with the sourced file's name, so multiple configurations
				 can be used without the scripts overwriting the configuration of 
                 the previously sourced one

		DEV-0030 Add an global CLI argument to automatically embed a changed AWK script
				 Ideally add an edit option which should open the config in the
                 default editor and save it after editing.
		
				 Declined: I discussed it with my self - it's too developer centric
						   should not go into a release. write helper script.

		DEV-0031 Make formatting more robust. Reformat help texts, so they aren't wrapped by the shell.


	Status summary: 

		Open
			DEV-0022 comments without space after #
			DEV-0029 variable namespace
			DEV-0031 robust formatting

		Decliend
			DEV-0009
			DEV-0030

2024-03-23

	DEV-0029 done
	DEV-0031 done, all help text are now broken to the next line, if there is not enough space
			       all help output uses a 50/50 two column layout

	
	New:
		DEV-0032 consistent help display for single word commands

				example (current):

					[commands]
					# does echo bla
					demo-command: echo bla
		
		
					will become in help:

						demo-command					does echo bla


		DEV-0033 improve confusing message: "no command supplied"
					when command was supplied, but did not match a
					configured command and expansion failed
		DEV-0034 improve config [env] application
				 combine env lines before eval, to allow multiline
				 expressions. not for config var assignments and source
				 command and include config function
		DEV-0035 When using batch mode, disable argument expansion
		DEV-0036 Return exit code of executed command instead of 0, to improve usability in scripts

				 Why always 0? On Ubuntu bash is configured to only keep succeeding commands in the history.
				 I didn't want to change this globally, but sometimes, when i'm developing new scripts for example i want to try execution and repeat it, without having to type the failed command again. So I made 0 the default.

				 Introdude a new config option for the user to configure the desired behavior.
				 CFG_EXEC_ALWAYS_RETURN_0="n"
				 

2024-04-24
				 
		DEV-0033 done
		DEV-0034 done
		DEV-0035 done
		DEV-0036 done				 

		DEV-0037 convencience fix: when there is more than one space between words on the
				 command line, auto completion stops to work
		DEV-0038 minimize process creations and syscalls
					analyze loop complexity
					reduce loop complexity where possible

					do not reload config if $__CLI_CONFIG has data and PROGNAME is the same as during previous execution
						saves one file access 

			
					
		DEV-0039 fix: after variable namespace implementation (without config array, because these
				 can't be referenced indirectly) the same commands are shown, when multiple cli configs are used

					fixed, but now two different cli's can't work in the same shell. Didn't it work before?

						It worked when execution did not call _cli_execute directly, but executed the script. i
						See DEV-0026, which enabled manipulation of the running shell trough commands 

						fixed
		
		DEV-0039 done
						
				
		DEV-0040 fix help output: tomcat manager ? does not print the comments, full help does

		DEV-0041 fix \1 \2 palceholder replacement

			executes, but should not
				tomcat echo 

			does not execute, but should
				tomcat echo first

			executes, but does not replace \2
				tomcat echo first second

		DEV-0041 done

		DEV-0042 fix optional args

		DEV-0042 done


2024-04-27

		Status summary:

			Open:
				DEV-0022 comments without space after comment character not parsed as comments
				DEV-0032 consistent help display for single word commands
				DEV-0037 more than one space in cmd line breaks auto completion
				DEV-0038 minimize process creations and syscalls
				DEV-0040 fix help output: tomcat manager ? does not print the comments, full help does

			Declined:
				DEV-0009
				DEV-0030
		
			Rest is done

	New:

		DEV-0043 create fifos with better temp file names

	DEV-0043 done
	DEV-0037 done
	DEV-0038 
			1x sed
		 	3x grep
		 	1x awk
		 	9x cut
		
			replaced a lot of subshell calls with functions

			execution time before optimization was 470ms
			now it is around 100ms
			felt snappy from <150ms
			now it feels really snappy 
			let's see how muhc faster we can make it

	DEV-0038 done

	
	New:
		DEV-0044 support more builtin bash auto completions (compgen -A)

                      file    File names.  May also be specified as -f.
                      directory
                              Directory names.  May also be specified as -d.
                      export  Names of exported shell variables.  May also be specified as -e.
                      arrayvar
                              Array variable names.

                      group   Group names.  May also be specified as -g.
                      user    User names.  May also be specified as -u.
                      hostname

                      job     Job names, if job control is active.  May also be specified as -j.
                      running Names of running jobs, if job control is active.
                      stopped Names of stopped jobs, if job control is active.

                      service Service names.  May also be specified as -s.

                      signal  Signal names.

                      variable
                              Names of all shell variables.  May also be specified as -v.



				support compgen options dirnames, filenames, noquote, nosort, nospace, plusdirs

					              -o comp‐option
                      The comp‐option controls several aspects of the compspec’s behavior beyond the simple generation of completions.  comp‐option
                      may be one of:
                      bashdefault
                              Perform the rest of the default bash completions if the compspec generates no matches.
                      default Use readline’s default filename completion if the compspec generates no matches.
                      dirnames
                              Perform directory name completion if the compspec generates no matches.
                      filenames
                              Tell  readline that the compspec generates filenames, so it can perform any filename-specific processing (like adding
                              a slash to directory names, quoting special characters, or suppressing trailing spaces).  Intended to  be  used  with
                              shell functions.
                      noquote Tell readline not to quote the completed words if they are filenames (quoting filenames is the default).
                      nosort  Tell readline not to sort the list of possible completions alphabetically.
                      nospace Tell readline not to append a space (the default) to words completed at the end of the line.
                      plusdirs
                              After  any  matches defined by the compspec are generated, directory name completion is attempted and any matches are
                              added to the results of the other actions.

	

2024-03-30

	New:

		DEV-0045 fix command execution via script. for example ./tomcat echo first second

			gobuki@archimedes:~/dev/shell/awk/config_flattener_v62$ ./tomcat bash: printf: `__CLI_./tomcat_CONFIG_FILE': not a valid identifier
			bash: printf: `__CLI_./tomcat_CFG_EXEC_ACK_EXPANDED_COMMANDS': not a valid identifier
			bash: printf: `__CLI_./tomcat_CFG_EXEC_EXPAND_ABBREVIATED_ARGS': not a valid identifier
			bash: printf: `__CLI_./tomcat_CFG_EXEC_PRINT_HELP_ON_INCOMPLETE_ARGS': not a valid identifier
			bash: printf: `__CLI_./tomcat_CFG_EXEC_ARGS_ALLOW_COMPLETION_RESULTS_ONLY': not a valid identifier
			bash: printf: `__CLI_./tomcat_CFG_EXEC_ALWAYS_RETURN_0': not a valid identifier
			bash: printf: `__CLI_./tomcat_CFG_EXEC_SILENT': not a valid identifier
			bash: printf: `__CLI_./tomcat_CFG_LOG_LEVEL': not a valid identifier
			bash: __CLI_./tomcat_CFG_LOG_LEVEL: invalid variable name

		DEV-0045 done

		DEV-0046 in some situations the script tries to write to a log file handle that is not opened.
		
		DEV-0047 placeholder for empty current word from 'empty' to
				 to something else to avoid clashes with words a user might use
				 on the command line

		DEV-0048 fix additional args are not appended

		DEV-0048 done
		
