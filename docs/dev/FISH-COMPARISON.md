# Fish Comparison

```
    }<(((*>
              <*))))>{
```

## Why not just use fish?

Fish has great out-of-the-box completion. It parses man pages, suggests flags, handles
nested subcommands for well-known tools (git, docker, kubectl). For a developer building
their own CLI, fish completions are written in fish syntax and are reasonably ergonomic.

But fish completions are per-tool, per-shell. If you build a CLI for your team or your
company, every user needs fish AND your completion script installed. derakht.sh
works in bash and zsh — the shells most people actually use. The config is a single
declarative file, not a scripting language.

| Capability | Fish | derakht.sh |
|---|---|---|
| Shell support | fish only | bash + zsh |
| Completion definition | Fish scripting | Declarative config file |
| Nested command trees | Manual `__fish_use_subcommand` | Automatic from indentation |
| Argument types | Manual `__fish_complete_path` etc. | Built-in: FILE, DIR, INTEGER, list, eval |
| Abbreviation expansion | Yes (`abbr` built-in) | Yes (configurable) |
| Help text / usage | Written in completion script | Parsed from `#` comments in config |
| Config validation | None | `--cli-validate-config` checks structure |
| Dependencies | fish shell | bash/awk (universally available) |
| Distribution | Requires installation | Package manager or copy one file |
| Security model | Package-managed, curated | Evaluated config with permission checks |

## But completions are inherently dangerous

Completions execute code in your shell context. Fish handles this by shipping
completions as part of the package — trusted code, installed via package manager.
That's a valid model.

derakht.sh takes a different approach: the command hierarchy and help text
are declarative (defined by indentation and comments), but the config also
contains evaluated code — the `[env]` section can source files and set variables,
and command expressions are executed via eval. The tool validates file permissions
before sourcing anything (rejects world-writable files, files owned by other
users, symlinks to unsafe targets).

The tradeoff: fish completions are safer because they're curated. derakht.sh
configs are more flexible because they're user-defined. Neither model is wrong —
they serve different trust levels.

## The real comparison

Fish is a better shell for interactive use. derakht.sh is a framework for building
completions for your own CLIs. Different problems.

If your users all use fish: fish completions are fine. If your users use bash and zsh
(which is most of the world), and you want a structured way to define command trees
without writing completion scripts, that's what this is for.
