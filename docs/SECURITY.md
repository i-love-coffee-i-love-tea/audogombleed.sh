# Security

This document describes how derakht.sh works, what it
trusts, and what can go wrong. Read it before using the tool in any
environment where the config file isn't entirely under your control.


## How the tool works

Derakht is a shell script that gets **sourced into your running shell**.
When you type `source ~/bin/mycli`, the script registers a tab-completion
function. When you press Tab or run a command, the script:

1. Reads `~/.NAME.conf` (the config file)
2. Parses the `[env]` section and **executes it as shell code**
3. Parses the `[commands]` section with an embedded AWK script
4. Matches your input to a command definition
5. Substitutes your arguments into the command expression
6. Runs the result through **`eval`** (or tokenized `exec` for simple commands)

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

> [!WARNING]
> The config file has the same privilege level as your `.bashrc`. Treat it
> accordingly.


## Safe execution path

The tool uses a tokenized execution path (`_cli_execute_safe`) by default.
For commands that do **not** contain shell metacharacters (`|`, `>`, `<`,
`&&`, `||`, `;`), the command expression is parsed into tokens and executed
via `exec` — no `eval`. This means simple commands like `kubectl get pods`
never pass through `eval`.

Commands with pipes, redirects, or chaining fall back to `eval` for
backwards compatibility.

### What the safe execution path protects against

- **`[env]` injection**: simple `VAR=value` and `export VAR=value`
  assignments in `[env]` are processed via `printf -v`, not `eval`.
  Multi-line or complex entries require shell evaluation.
- **Glob expansion**: `set -o noglob` is applied during command execution

### What the safe execution path does NOT protect against

- **User argument injection**:

  > [!WARNING]
  > User arguments containing `$(...)` or backticks are still interpreted
  > by `eval` in the execution path. The tokenized path checks the *config
  > expression* for metacharacters, not the user arguments. For example,
  > with this config:
  >
  >     greet: echo "Hello, \1"
  >
  > Running `greet $(touch /tmp/flag)` substitutes the argument into the
  > expression, producing `echo "Hello, $(touch /tmp/flag)"`. The tokenizer
  > sees no metacharacters in the config expression and takes the "safe"
  > path — but `eval` still expands `$(touch ...)` in the argument.

  Mitigate by using direct commands with fixed arguments, or wrapper
  functions that validate input.
- The config file is still read and parsed on every completion
- `source` directives in `[env]` still source external files (after
  permission checks)
- `include_commands_from` still merges external config files (after
  permission checks)
- A simple `VAR=value` assignment could still set a variable that
  influences command behavior


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

**Do not use derakht.sh in environments where you don't trust all users
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

**Mitigations:**

- Use direct commands with fixed arguments where possible
- If you must use shell expressions, validate arguments in a wrapper function
- Simple commands use tokenized `exec` instead of `eval` (via
  `_cli_execute_safe`), which prevents metacharacter interpretation of the
  config expression
- `set -o noglob` is applied during command execution to prevent glob
  expansion of arguments

### AWK output injection

The AWK config parser produces shell variable assignments (`__CMD_ARG[0]="..."`)
that are later `eval`'d. Descriptions or values containing double quotes or
backslashes could break out of the quoting.

**Mitigation:** the AWK script escapes `"`, `\`, and `$` characters in all
argument descriptions and values before output. This is verified by tests in
`test/awk-output-escaping-*.bats`.

### Regex injection in completion

The `command_filter` passed to AWK is used in regex matching. Special regex
characters in user input could alter matching behavior.

**Mitigation:** the AWK script escapes regex metacharacters in
`command_filter` before using it in `~` (regex) patterns. Only `==` string
comparison uses the raw filter.

### Tab completion side effects

- `:arg:eval:function` calls the function **every time you press Tab**
- `&function` command words call the function on every completion
- Functions called during completion run in a subshell and cannot modify
  your current shell state

### TOCTOU (time-of-check-time-of-use)

The tool checks file permissions before sourcing, but the file could be
swapped between the check and the read.

**Mitigation:** the config file is opened as FD4 at check time and read from
that file descriptor, not re-opened from the path. This prevents the race
condition where an attacker swaps the file between permission check and read.


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


## Additional security measures

### CLI name validation

The CLI name (derived from the symlink name) is validated to contain only
letters, digits, and underscores. Names with dots, dashes, or other
characters are rejected with an error. This prevents issues with aliases
and variable names.

### Variable name validation

`__CLI_*` variable assignments in `[env]` are validated against
`^[A-Za-z_][A-Za-z0-9_]*$`. Invalid variable names are rejected.

### Config variable assignments via `printf -v`

Simple `VAR=value` assignments in `[env]` are processed via `printf -v`
instead of `eval`, eliminating code injection risk for variable assignments.
Only multi-line or complex entries require shell evaluation.

### Signal handling

The tool traps `INT` and `TERM` signals to ensure temporary directories
(created for FIFO-based config merging) are cleaned up on interruption.

### Temporary file security

- Log files are created via `mktemp` with `chmod 600`
- FIFO temp directories use `mktemp -d` (not `mktemp -u`, which has race
  conditions)
- If `mktemp` fails, logging is disabled rather than crashing
- Background FIFO writers are waited on before cleanup

### Source exit code reporting

Files loaded via `source` directives have their exit codes checked. Non-zero
exit codes produce a config error message, so broken sourced files don't fail
silently.


## What the tool does NOT do

- It does not sandbox the `[env]` section — it runs in your current shell
- It does not validate config file content beyond syntax
- It does not escape or sanitize arguments before `eval`
- It does not restrict what commands can be defined
- It does not log or audit executed commands (debug logging is optional and
  writes to `/tmp` with mode 600)
- It does not verify config file integrity (no checksums or signatures)


## Recommendations

### For personal use

1. **Set restrictive permissions on your config file:**

       chmod 600 ~/.NAME.conf

2. **Use `:arg:list:$VAR` instead of `:arg:eval:func`.** The `$VAR` form
   uses indirect expansion (no eval) and is safe by default. Only use
   `:arg:eval:` if you need it and trust the function.

3. **Use `--batch` / `-b` in scripts.** This disables interactive prompts
   and command abbreviation, reducing the chance of accidental expansion.

4. **Review your config file.** Treat it as executable code. If you copy
   configs from the internet, read them first.

5. **Don't put secrets in the `[env]` section.** Environment variables set
   there are visible to child processes.

### For shared systems

> [!CAUTION]
> **Don't use derakht.sh on shared systems** unless you control all users
> and have verified the home directory permissions. The `eval` model means
> any config file injection is a full shell compromise.

## CI / supply chain

The project's CI pipeline applies these supply chain protections:

- **Pinned action SHAs**: all GitHub Actions are pinned to full commit SHAs,
  not mutable tags. This prevents a compromised tag from injecting malicious
  steps.
- **Minimal permissions**: the workflow grants only `id-token: write`,
  `contents: read`, and `checks: write`.


## Reporting security issues

If you find a security vulnerability in derakht.sh, open an issue on the
GitHub repository with the `security` label, or contact the author directly.
