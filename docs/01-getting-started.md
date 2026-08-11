# Getting Started

## 1. Install

### Option A: .deb package (Debian/Ubuntu)

For local or private usage (unsigned):

    ./build-deb.sh

For distribution (signed with GPG):

    ./build-deb.sh --sign

This produces `../derakht_<version>_all.deb`. Install with:

    sudo dpkg -i ../derakht_<version>_all.deb

Requires `build-essential` and `debhelper` (`sudo apt-get install build-essential debhelper`).

After installation, the script is at `/usr/bin/derakht`. Continue with
step 2 to create your CLI symlinks.

### Option B: Clone or download

Get `derakht.sh` into a directory of your choice (e.g. `~/bin/`).

### Create CLI symlinks

Regardless of install method, each CLI you want needs a symlink. The
filename becomes the CLI name, determines the config file path, and is
used to register tab completion:

    ln -s /usr/bin/derakht ~/bin/mycli    # after .deb install
    ln -s ~/bin/derakht.sh ~/bin/mycli    # after manual download

## 2. Create a config file

Must match the symlink name (`~/$NAME.conf`). A `[commands]` section is the
minimum:

    cat > ~/.mycli.conf <<'EOF'
    [commands]
    hello: echo "hello world"
    EOF

## 3. Source the symlink

This registers the tab-completion function with your shell (`complete` in
bash, `compdef` in zsh) and makes the command executable:

    source ~/bin/mycli

## 4. Try it

Press TAB to see completions, then execute:

    mycli <TAB><TAB>
    mycli hello


## Execution modes

### Default: without alias

If you only `source` the symlink, running `mycli some-command` executes
the script as a child process. Commands like `cd` and `export` have no
effect on your shell. This is fine for external programs (`kubectl`,
`docker`, etc.) and is the safe default.

### With alias: current-shell execution

Add an alias to make the command run in your current shell:

    alias mycli='_cli_execute'

Now `mycli cd /some/path` actually changes your directory, and
`mycli export FOO=bar` sets a variable in your shell. This also gives
commands access to your shell functions and variables, and avoids the
overhead of forking a subprocess per invocation.

This is the recommended setup for interactive use when your commands
need to affect the current shell.

### Comparison

| | No alias | Alias (`_cli_execute`) |
|--|----------|----------------------|
| `cd` / `export` | no effect on your shell | affects your shell |
| Shell functions & variables | not available to commands | available to commands |
| Functions from `[env]` | available | available |
| Argument completion (`eval`) | works (runs in your shell) | works (runs in your shell) |
| Performance | fork per invocation | no fork |

Note: tab completion always runs in your shell regardless of mode.
Argument types like `eval` and `list` with `$VARIABLE` always work
because completion happens in the current shell context.

### Multiple CLIs

If you have multiple CLIs, each `source` registers its own completion
function. The last sourced CLI's completion will be active. To switch,
source the one you want to use:

    source ~/bin/cli1    # cli1 completions active
    source ~/bin/cli2    # cli2 completions active


## A more complete example

Here is a config with a hierarchical command tree, dynamic argument
completion, and function expansion — wrapping kubectl commands that a
Kubernetes admin runs daily:

    [env]
    function get_deployments() {
        kubectl get deployments -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n'
    }

    [commands]
    pods
        restart: kubectl rollout restart deployment/\1
            :deployment:eval:get_deployments
        logs: kubectl logs -f deployment/\1 --tail=50
            :deployment:eval:get_deployments
        shell: kubectl exec -it deployment/\1 -- /bin/sh
            :deployment:eval:get_deployments

`\1` is replaced by the first argument. The `get_deployments` function
runs `kubectl` at completion time, so the list stays current as you
deploy new services.

    $ mycli pods <TAB><TAB>
    restart  logs  shell
    $ mycli pods restart <TAB>
    api-gateway  auth-service  web-frontend
    $ mycli pods restart web-frontend
    >> executes: kubectl rollout restart deployment/web-frontend

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

Given the kubectl config above:

    $ mycli pods <tab><tab>
    restart  logs  shell

    $ mycli pods restart <tab><tab>
    api-gateway  auth-service  web-frontend

    $ mycli pods restart a<tab>
    >> completes to: mycli pods restart api-gateway

### Arguments

Arguments are defined with `:name:type:source` syntax. An optional
description can be appended as the last field:

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
        :first-arg:list:one|two|three:first positional argument
        :second-arg:list:alpha|beta|gamma:second positional argument

    $ mycli echo <tab><tab>
    one  two  three

    $ mycli echo one <tab><tab>
    alpha  beta  gamma

See [Configuration Reference](02-configuration.md) for the full list of
argument types and optional arguments.
