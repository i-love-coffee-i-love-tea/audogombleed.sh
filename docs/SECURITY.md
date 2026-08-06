# Security

This document is an honest account of how audogombleed.sh works, what it
trusts, and what can go wrong. Read it before using the tool in any
environment where the config file isn't entirely under your control.


## How the tool works

Audogombleed is a shell script that gets **sourced into your running shell**.
When you type `source ~/bin/mycli`, the script registers a tab-completion
function. When you press Tab or run a command, the script:

1. Reads `~/.NAME.conf` (the config file)
2. Parses the `[env]` section and **executes it as shell code**
3. Parses the `[commands]` section with an embedded AWK script
4. Matches your input to a command definition
5. Substitutes your arguments into the command expression
6. Runs the result through **`eval`**

The config file is re-read on **every tab completion and every command
execution**. This is not a one-time startup cost — it is a continuous
trust relationship.


## Why `eval`

The core execution mechanism is:

```bash
eval $cmd_expr ${args[*]}
```

Where `cmd_expr` comes from the config file (e.g., `kubectl logs -f -n \1`)
and `args` are the user's arguments. The `\1` placeholder is replaced by the
first argument, then the whole string is passed to `eval`.

This is the reason the tool exists. A declarative config file that maps
command names to shell expressions needs a way to execute those expressions.
In a POSIX shell, `eval` is that way. There is no safe subset of `eval` —
it interprets the full shell grammar, including command substitution,
pipelines, and redirections.

The alternatives (arrays + `exec`, `env` + `exec`, restricted shell) would
break the feature set: positional argument substitution, variable expansion,
function calls, and the ability to use shell builtins like `cd` and `export`.

This is a deliberate design choice, not an oversight.


## Trust model

**The config file is shell code.** Anyone who can write to `~/.NAME.conf`
can execute arbitrary commands in your shell. This includes:

- The `[env]` section — sourced directly into your shell on every completion
- The `[commands]` section — command expressions are passed to `eval`
- `source` directives — load external files into your shell
- `include_commands_from` — merge external config files into the command tree
- `:arg:eval:function` argument types — call functions during tab completion

The config file has the same privilege level as your `.bashrc`. Treat it
accordingly.


## Attack surface

### Config file poisoning

If an attacker gains write access to your config file, they can:

- Run arbitrary commands every time you press Tab (the `[env]` section)
- Replace command expressions to run malicious code instead of your intended
  command
- Source malicious files via `source` directives
- Exfiltrate data through functions called during completion

**Mitigation:** the tool checks file permissions before sourcing (see below).
But the best defense is filesystem permissions — `chmod 600 ~/.NAME.conf`.

### Shared or multi-user environments

On shared systems (servers, CI runners, shared hosting), other users may be
able to:

- Write to world-writable directories in your `$PATH`
- Create symlinks in shared temp directories
- Modify files in shared dotfile repos

**Do not use audogombleed.sh in environments where you don't trust all users
on the system.**

### Supply chain attacks

If your config file is managed in a dotfiles repo, a compromised repo means
a compromised shell. The config file is executed, not just read.

**Review config changes the same way you review `.bashrc` changes.**

### Command injection via arguments

User arguments are substituted into command expressions before `eval`. If
your config passes arguments to a shell expression (not a direct command),
the arguments are interpreted by the shell:

    [commands]
    greet: echo "Hello, \1"

If a user passes `$(rm -rf /)` as an argument, `eval` will execute it.
This is inherent to the `eval` model — the argument is part of a shell
expression, not a program argument.

**Mitigation:** use direct commands with fixed arguments where possible.
If you must use shell expressions, validate arguments in a wrapper function.


## File permission checks

The tool checks files before sourcing them. A file is rejected if:

| Check | Why |
|-------|-----|
| Not a regular file | Prevents sourcing device files or named pipes |
| Not world-writable | Prevents sourcing files any user on the system can modify |
| Owned by current user or root | Prevents sourcing files planted by other users |
| Symlink target not world-writable | Prevents symlinks pointing to attacker-controlled files |
| Symlink target is a regular file | Prevents symlinks to device files or directories |

These checks apply to:

- The main config file (`~/.NAME.conf`)
- Files referenced by `source` directives in `[env]`
- Files referenced by `include_commands_from`

**What these checks do NOT protect against:**

- A config file owned by you that was modified by an attacker who already
  has your credentials (the file passes all permission checks)
- A config file in a directory writable by other users (the file itself
  may be fine, but the directory allows file replacement race conditions)
- Config content that is syntactically valid but semantically malicious
  (the tool cannot distinguish "intended" from "unintended" commands)
- Arguments containing shell metacharacters (the `eval` will interpret them)

The permission checks are a defense-in-depth layer, not a security boundary.
The real security boundary is your filesystem permissions.


## What the tool does NOT do

- It does not sandbox the `[env]` section — it runs in your current shell
- It does not validate config file content beyond syntax
- It does not escape or sanitize arguments before `eval`
- It does not restrict what commands can be defined
- It does not log or audit executed commands (debug logging is optional and
  writes to `/tmp`)
- It does not verify config file integrity (no checksums or signatures)


## Recommendations

### For personal use

1. **Set restrictive permissions on your config file:**

       chmod 600 ~/.NAME.conf

2. **Don't use `eval`-type arguments (`:arg:eval:func`) with untrusted
   input.** The function runs during tab completion — if it calls external
   commands, those commands run every time you press Tab.

3. **Use `--batch` / `-b` in scripts.** This disables interactive prompts
   and command abbreviation, reducing the chance of accidental expansion.

4. **Review your config file.** Treat it as executable code. If you copy
   configs from the internet, read them first.

5. **Don't put secrets in the `[env]` section.** Environment variables set
   there are visible to child processes.

### For shared systems

**Don't use audogombleed.sh on shared systems** unless you control all users
and have verified the home directory permissions. The `eval` model means any
config file injection is a full shell compromise.

## Reporting security issues

If you find a security vulnerability in audogombleed.sh, open an issue on the
GitHub repository with the `security` label, or contact the author directly.
