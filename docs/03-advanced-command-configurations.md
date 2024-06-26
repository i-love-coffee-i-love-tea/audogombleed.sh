# Advanced command configurations

There are three ways to write commands to expand them to multiple commands.

- variable expansion
- function expansion
- list expansion

This may be desireable when you have a multiple commands in the same hierarchy with
the same arguments.

For example, consider this configuration:

	cmd
	    webapp1: echo \0
	        :action:list:start|stop|status
	    webapp2: echo \0
	        :action:list:start|stop|status
	    webapp3: echo \0
	        :action:list:start|stop|status
	

We can write this in a shorter form by using a list for the last command word.
NOTE: \0 is replaced with the last command word (word before the colon).


## Variable expansion

	cmd-var-demo
	    $__APP_NAMES: echo \0
	        :action:list:start|stop|status

Will expand to as many commands as there are words in `$__APP_NAMES`.
\0 will be replaced by the word.

for example if `$__APP_NAMES="app1 app2 app3"`, it will result in these commands:
	
	cmd-var-demo app1 [start|stop|status]
	cmd-var-demo app2 [start|stop|status]
	cmd-var-demo app3 [start|stop|status]


## Function expansion

works the same way as variable expansion, but with a function:

	cmd-fun-demo
	    &create_command_variations: echo \0
	        :action:list:start|stop|status

## List expansion

most simple way, with a static list

	cmd-fun-demo
		app1|app2|app3: echo \0
	        :action:list:start|stop|status


## Argument placeholders

The default is to append all defined command arugments at the end of the line.
In cases where you need more flexibility, because the arguments need to be
embedded in a command at the right places, you can use placeholders.

Exmaple of placeholder usage. This config defines two static command args which can be completed
   
	[commands]
 	echo: echo \2 \1
  		:value:first
		:value:second

Upon hitting tab serveral times, this command will complete to

	$ cli echo first second

 The resulting command for execution will be

 	$ echo second first

  
  
