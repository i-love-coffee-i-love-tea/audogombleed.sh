[![Automated Bash Tests](https://github.com/i-love-coffee-i-love-tea/audogombleed.sh/actions/workflows/main.yml/badge.svg?branch=main)](https://github.com/i-love-coffee-i-love-tea/audogombleed.sh/actions/workflows/main.yml)

# Audogombleed

Create CLIs with auto-completable command trees — no coding required.

Define commands and arguments in a plain text config file. Tab completion,
command abbreviation, and help output all come for free.

### :mag: What it looks like

Config (`~/.tf.conf`):

    [commands]
    plan
        staging: terraform plan -var-file=staging.tfvars
        prod: terraform plan -var-file=prod.tfvars
    apply
        staging: terraform apply -var-file=staging.tfvars
        prod: terraform apply -var-file=prod.tfvars
    destroy
        staging: terraform destroy -var-file=staging.tfvars
        prod: terraform destroy -var-file=prod.tfvars

Shell session:

    $ tf <TAB><TAB>
    plan  apply  destroy
    $ tf p<TAB>
    plan
    $ tf plan st<TAB>
    staging
    $ tf plan staging
    >> executes: terraform plan -var-file=staging.tfvars

Commands can be abbreviated as long as they are unambiguous — `tf p st`
expands to `tf plan staging`.

### :question: Why not just use shell autocompletion?

Bash and zsh have built-in completion, but it requires one completion script
per command (or a big hardcoded function). If you change a parameter, you
have to update the completion code too.

Audogombleed takes a **declarative approach**: everything lives in a config
file. Add, remove, or restructure commands by editing text. No shell
functions to maintain.

### :star: What makes this different

- :page_facing_up: **One config file, four features** — tab completion, command abbreviation,
  help output, and command execution all come from a single config. No other
  tool I know of does all four declaratively.
- :globe_with_meridians: **Language-agnostic** — works with any program: shell scripts, binaries,
  aliases, Python scripts, you name it. CLI frameworks like Cobra (Go) or
  Click (Python) only work within their language.
- :package: **Zero dependencies** — the config parser is an embedded AWK script. The
  only runtime requirements are bash (or zsh) and awk, which are on every
  Unix system. Nothing to install.
- :rocket: **Scales from trivial to complex** — a one-command CLI needs 3 lines of
  config. A multi-level command tree with dynamic arguments and included
  modules needs more, but the same mechanism.

### :dart: Use cases

- **Kubernetes admins** — `kubectl` commands are long and hard to remember.
  Wrap `kubectl get pods`, `kubectl logs -f`, `kubectl rollout restart` in a
  CLI with tab completion for namespaces, deployments, and pods.
- **DevOps / infrastructure** — shorten `terraform plan -var-file=staging.tfvars`
  to `tf p st`. Add tab completion for environments, workspaces, and targets.
- **Internal tools** — your team's shell scripts, deploy scripts, and one-off
  utilities don't ship with tab completion. Give them a discoverable CLI
  without writing any completion code.
- **Shell script collections** — unify a folder of scripts under one command
  tree with help output and abbreviation. No need to remember script names
  or flags.
- **Docker / Podman** — wrap complex `docker compose` or `podman` commands
  with environment-specific arguments and service name completion.

## :zap: Quick Start

1. **Create a symlink** — the filename becomes the CLI name:

       ln -s ~/bin/audogombleed.sh ~/bin/mycli

2. **Create a config file** — must match the symlink name (`~/$NAME.conf`):

       cat > ~/.mycli.conf <<'EOF'
       [commands]
       hello: echo "hello world"
       EOF

3. **Source the symlink** — registers tab completion and makes the command executable:

       source ~/bin/mycli

4. **Try it**:

       mycli <TAB><TAB>
       mycli hello

See [Getting Started](docs/01-getting-started.md) for a more complete
example with command trees and argument types.

## :books: Documentation

- [Getting Started](docs/01-getting-started.md) — tutorial: create a CLI, define commands, test completions
- [Configuration Reference](docs/02-configuration.md) — all config options, argument types, CLI flags, exit codes
- [Advanced Commands](docs/03-advanced-command-configurations.md) — expand one definition into multiple commands with variables, functions, or lists
- [Hierarchical Configuration](docs/04-hierarchical-configuration.md) — split your config across multiple files
- [FAQ](docs/10-faq.md) — common issues and solutions
