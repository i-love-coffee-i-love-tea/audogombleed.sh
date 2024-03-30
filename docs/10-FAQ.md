# why doesn't the command help print anything?

Because of shell globbing, the '?' at the end of the line
will be replaced by the filename if there is a file with
a name of a single character in your work dir.

Example of a failing command: 

	mycli ?

Possible solutions:

- change to a directory that doesn't contain single character files
- escape the ? with a backslash, to prevent shell expansion
- remove the file
- use -h, -? or escape the question mark (see below)

Submit with backspace to prevent expansion: 

	mycli -h
	mycli -?
	mycli \\?
	mycli "\?"
