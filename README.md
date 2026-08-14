[![bash tests](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/i-love-coffee-i-love-tea/d78d735477baaf8be3fb7c5cfd75bd1e/raw/bash-tests.json)](https://github.com/i-love-coffee-i-love-tea/derakht-cli/actions/workflows/main.yml)
[![zsh tests](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/i-love-coffee-i-love-tea/d78d735477baaf8be3fb7c5cfd75bd1e/raw/zsh-tests.json)](https://github.com/i-love-coffee-i-love-tea/derakht-cli/actions/workflows/main.yml)
[![fish tests](https://img.shields.io/endpoint?url=https://gist.githubusercontent.com/i-love-coffee-i-love-tea/d78d735477baaf8be3fb7c5cfd75bd1e/raw/fish-tests.json)](https://github.com/i-love-coffee-i-love-tea/derakht-cli/actions/workflows/main.yml)
[![Coverage](https://github.com/i-love-coffee-i-love-tea/derakht-cli/actions/workflows/coverage.yml/badge.svg?branch=main)](https://github.com/i-love-coffee-i-love-tea/derakht-cli/actions/workflows/coverage.yml)
[![ShellCheck](https://img.shields.io/badge/shellcheck-passing-brightgreen)](https://www.shellcheck.net/)
[![License](https://img.shields.io/github/license/i-love-coffee-i-love-tea/derakht-cli)](LICENSE)
[![Latest Release](https://img.shields.io/github/v/release/i-love-coffee-i-love-tea/derakht-cli)](https://github.com/i-love-coffee-i-love-tea/derakht-cli/releases/latest)
[![bash](https://img.shields.io/badge/bash-4.2%2B-blue?logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![zsh](https://img.shields.io/badge/zsh-compatible-blue?logo=zsh&logoColor=white)](https://zsh.sourceforge.io/)
[![fish](https://img.shields.io/badge/fish-compatible-blue?logo=fish&logoColor=white)](https://fishshell.com/)

# Derakht

*derakht* [/dɛˈɾæxt/](https://forvo.com/word/%D8%AF%D8%B1%D8%AE%D8%AA/#fa) — Persian for "tree" (درخت).

Create CLIs with auto-completable command trees — no coding required.

Define commands and arguments in a plain text config file. Tab completion,
command abbreviation, and help output all come for free.

```
                    ┌──────────────┐
                    │  Config File │
                    │  (.NAME.conf)│
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  [env]       │  ← shell code: exports, functions,
                    │  section     │    CLI options
                    └──────┬───────┘
                           │
                    ┌──────▼───────┐
                    │  [commands]  │  ← parsed by embedded AWK script
                    │  section     │
                    └──────┬───────┘
                           │
              ┌────────────┼────────────┐
              │            │            │
     ┌────────▼───┐ ┌──────▼─────┐ ┌───▼──────────┐
     │ Completion │ │  Help      │ │  Execution   │
     │ (Tab key)  │ │  (? / -h)  │ │  (Enter key) │
     └────────────┘ └────────────┘ └──────────────┘
```

| | Docs |
|---|---|
| Config file | [Configuration Reference](docs/02-configuration.md) |
| `[env]` section | [Environment](docs/02-configuration.md#env-section) |
| `[commands]` section | [Command tree](docs/02-configuration.md#commands-section) |
| Help | [Comments & help output](docs/02-configuration.md#comments) |

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

Commands can be abbreviated as long as they are unambiguous — `tf p s`
expands to `tf plan staging`. You can also use no-space abbreviations like
`tf ps` to achieve the same result.

### :question: Why not just use shell autocompletion?

Bash, zsh, and fish have built-in completion, but it requires one completion script
per command (or a big hardcoded function). If you change a parameter, you
have to update the completion code too.

Derakht takes a **declarative approach**: everything lives in a config
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
  only runtime requirements are bash, zsh, or fish and awk, which are on every
  Unix system. Nothing to install.
- :rocket: **Scales from trivial to complex** — a one-command CLI needs 3 lines of
  config. A multi-level command tree with dynamic arguments and included
  modules needs more, but the same mechanism.

### :dart: Use case

Over the years, scripts and tools accumulate in your `~/bin`. Some you use
daily, others you wrote six months ago and can't quite remember what they do
or how they're invoked. You may have written `--help` output for them, but
that doesn't help when you can't remember the command name in the first
place.

Writing proper shell completions and usage docs for personal scripts is
rarely worth the effort — so most scripts go without.

Derakht solves both problems at once: define your tools in a config file and
you get tab completion, abbreviation, help output, and documentation — all
without touching the scripts themselves. Type the first letter, hit Tab, and
see what's there.

**Works with AI too.** AI agents can read your scripts to figure out the
interface — but that costs tokens every time. Tell AI to create a derakht
config for your scripts once, and it never has to scan them again. The config
is a persistent, structured interface to your tools.

**Project CLIs for teams.** Check a config file into your repo and everyone
gets the same commands — `dev test`, `dev lint`, `dev deploy staging` — with
tab completion and help. No Makefile targets to forget, no README sections
to go stale. See `dev.conf` in this repo for a working example.

## :zap: Quick Start

1. **Create a symlink** — the filename becomes the CLI name:

       ln -s ~/bin/derakht.sh ~/bin/mycli

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

| Doc | What it covers |
|-----|---------------|
| [Getting Started](docs/01-getting-started.md) | Install, first CLI, source vs alias, testing completions |
| [Configuration Reference](docs/02-configuration.md) | `[commands]` and `[env]` sections, argument types (`:list:`, `:eval:`, `:FILE`, etc.), config options, CLI flags, exit codes, zsh/fish setup |
| [Advanced Commands](docs/03-advanced-command-configurations.md) | Expand one definition into multiple commands with `$variable`, `&function`, or `val1\|val2` lists; argument placeholders (`\0`, `\1`, `\2`) |
| [Hierarchical Configuration](docs/04-hierarchical-configuration.md) | `include_commands_from` — split your config across multiple files, merge at runtime |
| [Shell Compatibility](docs/05-shell-compatibility.md) | Bash/zsh/fish differences, execution model, `SH_WORD_SPLIT` requirement, known limitations |
| [FAQ](docs/10-faq.md) | Common issues: globbing `?`, zsh/fish setup, config debugging, multiple CLIs |
| [Config Grammar](docs/config-grammar.md) | Formal ABNF-like specification — the authoritative spec for the config file format |
| [Security](docs/SECURITY.md) | Trust model, `eval` implications, attack surface, recommendations |
