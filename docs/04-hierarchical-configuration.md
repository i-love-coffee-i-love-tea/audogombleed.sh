# Hierarchial configuration

Commands defined in other config files can be included in the command tree.

Syntax:

    include_commands_from <cli-config-file> <parent-command-word>

The example config, `~/.cli.conf` for the cli `cli`

    include_commands_from ~/.cli-module-cluster.conf cluster

... includes all the commands from the file ~/.cli-module-cluster.conf
and makes them accessible under the cluster command word.

So if you type `cli cluster <TAB><TAB>` the contained commands will be
listed as if they were defined in `~/.cli.conf`.
