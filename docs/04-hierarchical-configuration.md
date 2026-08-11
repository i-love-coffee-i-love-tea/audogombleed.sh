# Hierarchical Configuration

You can split your command tree across multiple config files and combine them
at runtime. This is useful when:

- You have a large command set and want to keep files small and focused
- You want to share a group of commands between multiple CLIs
- You want to build a CLI from modular pieces maintained independently

## Syntax

In the `[env]` section of your main config, use `include_commands_from`:

    include_commands_from <config-file> <parent-command>

The included file must contain a `[commands]` section. Its commands are
merged into the main config under the given parent command word.

Use `ROOT` as the parent command to merge commands at the top level instead
of nesting them:

    include_commands_from <config-file> ROOT

## Example

Main config (`~/.cli.conf` for the CLI `cli`):

    [env]
    include_commands_from ~/.cli-module-cluster.conf cluster

Module config (`~/.cli-module-cluster.conf`):

    [commands]
    node
        power
            on: cluster_ipmi_power.sh on
            off: cluster_ipmi_power.sh off
            status: cluster_ipmi_power.sh status

Result: the commands from the module become available under `cluster`:

    $ cli cluster node power on
    $ cli cluster node power off
    $ cli cluster node power status

They appear in tab completion as if they were defined directly in
`~/.cli.conf`.

## How it works

The `include_commands_from` directive is processed during `[env]` loading.
The main config's `[commands]` section and all included `[commands]`
sections are merged before parsing. The result is a single command tree.

Each included file's commands are indented under the parent command word.
With `ROOT`, they are merged without a parent wrapper.

## Error handling

- **Missing file:** if the included config file does not exist, the CLI
  prints an error to stderr and stops. Check the path and filename.
- **No `[commands]` section:** if the included file exists but has no
  `[commands]` section, the include is silently ignored (no commands
  are merged). The rest of the config works normally.
- **One level only:**

  > [!WARNING]
  > `include_commands_from` only works in the main config's `[env]` section.
  > Included files cannot include further files. Any `include_commands_from`
  > in an included file is treated as a shell command and executed, not
  > parsed as an include directive.

## Visual example

Main config importing two modules:

    ~/.cli.conf
    +----------------------------+
    | [env]                      |
    | include_commands_from      |
    |   ~/.cli-import.conf       |
    |   import                   |
    | include_commands_from      |
    |   ~/.cli-export.conf       |
    |   export                   |
    |                            |
    | [commands]                 |
    | echo: echo "works too"     |
    +----------------------------+

    ~/.cli-import.conf              ~/.cli-export.conf
    +----------------------------+  +----------------------------+
    | [commands]                 |  | [commands]                 |
    | from-file:                 |  | to-file:                   |
    |   ~/bin/import-from-file.sh|  |   ~/bin/export-to-file.sh  |
    |   :FILE                    |  |   :FILE                    |
    +----------------------------+  +----------------------------+

    Result:
    +----------------------------+
    | [commands]                 |
    | echo: echo "works too"     |
    | import                     |
    |   from-file:               |
    |     ~/bin/import-from-file |
    |     :FILE                  |
    | export                     |
    |   to-file:                 |
    |     ~/bin/export-to-file   |
    |     :FILE                  |
    +----------------------------+
