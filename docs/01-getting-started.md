# Getting Started

## 1. Create a symlink

The filename becomes the CLI name, determines the config file path, and is
used to register tab completion. Using a symlink (instead of copying the
script) means all your CLIs share one source file — update `audogombleed.sh`
once and every CLI picks up the new version:

    ln -s ~/bin/audogombleed.sh ~/bin/mycli

## 2. Create a config file

Must match the symlink name (`~/$NAME.conf`). A `[commands]` section is the
minimum:

    cat > ~/.mycli.conf <<'EOF'
    [commands]
    hello: echo "hello world"
    EOF

## 3. Source the symlink

This registers the tab-completion function with your shell (`complete` in
bash, `compdef` in zsh):

    source ~/bin/mycli

## 4. Create an alias

Sourcing only registers completions. The alias makes the command name invoke
`_cli_execute` in the current shell (so commands can export variables, cd
into directories, etc.):

    alias mycli='_cli_execute'

## 5. Try it

Press TAB to see completions, then execute:

    mycli <TAB><TAB>
    mycli hello


## A more complete example

Here is a config with a hierarchical command tree, argument types, and
variables:

    [env]
    GIT_ROOT="~/git/some/deep/directory"
    PROJECTS_DIR="/var/server/projects"
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

`\0` is replaced by the last command word. So `cd git-projects project1`
executes `cd ~/git/some/deep/directory/project1`.

See [03-advanced-command-configurations.md](03-advanced-command-configurations.md)
for variable, function, and list expansion, and
[04-hierarchical-configuration.md](04-hierarchical-configuration.md) for
including commands from other config files.


## Testing autocompletion

### Simple commands

    $ mycli <tab><tab>
    >> completes to: mycli hello

    $ mycli hello
    hello world

### Hierarchical commands

Given the config above:

    $ mycli cd <tab><tab>
    git-projects    app-instances

    $ mycli cd git-projects <tab><tab>
    project1  project2  project3

    $ mycli cd git-projects p<tab>
    >> completes to: mycli cd git-projects project1

### Arguments

Arguments are defined with `:name:type:source` syntax:

| Type | Syntax | Description |
|------|--------|-------------|
| Static list | `:arg:list:val1\|val2\|val3` | Complete from a fixed set of values |
| Variable list | `:arg:list:$VAR` | Complete from a shell variable |
| Function list | `:arg:eval:function_name` | Complete from function output |
| Default value | `:arg:value:default` | Use a default value (not a completion list) |
| File | `:arg:FILE` | Complete file paths |
| Directory | `:arg:DIR` | Complete directory paths |

Example with arguments:

    [commands]
    echo: echo \2 \1
        :first-arg:list:one|two|three
        :second-arg:list:alpha|beta|gamma

    $ mycli echo <tab><tab>
    one  two  three

    $ mycli echo one <tab><tab>
    alpha  beta  gamma
