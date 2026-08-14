---
status: proposed
date: 2026-08-10
---

# Cross-shell config file compatibility

## Context and Problem Statement

derakht.sh currently supports bash and zsh. Fish shell support is being
added (see FISH-PLAN.md). Bash and zsh share enough syntax that the same
`[env]` section and command expressions work in both. Fish is a different
language — different variable syntax, no `eval` builtin, different function
definitions, different quoting rules.

The question: what restrictions apply to `.conf` files that must work across
bash, zsh, AND fish? Which parts of the config are portable, which are
shell-specific, and how do we handle the split?

## Decision Outcome

The config file has three zones with different portability characteristics:

1. **`[commands]` section** — shell-agnostic by convention (external commands
   with arguments), but shell syntax leaks in via command expressions
2. **`[env]` section** — shared settings portable across all shells, but
   function definitions are shell-specific
3. **`[env.fish]` section** — new, fish-only, ignored by bash/zsh wrappers

A config is cross-shell compatible if its author follows the restrictions
below. The tool cannot enforce this — it's a documentation and convention
problem.

**because** the config file format is already a mix of declarative structure
(commands, arguments, help text) and imperative shell code (env, expressions,
eval args). The declarative parts are fully portable. The imperative parts
are shell-specific by nature. Trying to abstract over shell differences
would require inventing a shell-independent scripting language — which is
out of scope.

## Shell syntax zones in the config file

### Zone 1: Fully portable (no restrictions)

These parts of the config contain no shell syntax and work identically in
all shells:

| Config element | Example | Why it's portable |
|---|---|---|
| Command tree structure | `install` / `jar` / `file: ...` | Parsed by AWK, not by shell |
| Help comments | `# install a jar file` | Parsed by AWK |
| Argument definitions | `:jar-file:FILE` | Parsed by AWK |
| Static list values | `:env:list:staging\|prod` | Parsed by AWK |
| `int_range` values | `:port:int_range:1-65535` | Parsed by AWK |
| `value` defaults | `:msg:value:hello` | Parsed by AWK |
| CLI config variables | `__CLI_CFG_EXEC_SILENT=n` | Simple key=value, shell sets via `set -g` |
| `include_commands_from` | `include_commands_from ~/x.conf ROOT` | Handled by AWK merge logic |

### Zone 2: Portable with care (external commands)

Command expressions that invoke external programs with arguments are
portable. Pipes, redirections, and logical operators are also portable
across all three shells.

**Portable patterns in command expressions:**

| Pattern | Bash | Zsh | Fish | Example |
|---------|------|-----|------|---------|
| External command + args | ✅ | ✅ | ✅ | `echo \0 \1` |
| External command + flags | ✅ | ✅ | ✅ | `kubectl get pods -o wide` |
| Placeholder substitution | ✅ | ✅ | ✅ | `terraform plan -var-file=\1` |
| Pipe `\|` | ✅ | ✅ | ✅ | `cmd1 \| cmd2` |
| Redirect `>` | ✅ | ✅ | ✅ | `cmd > /dev/null` |
| Redirect append `>>` | ✅ | ✅ | ✅ | `cmd >> logfile` |
| Redirect stderr `2>&1` | ✅ | ✅ | ✅ | `cmd 2>&1` |
| AND list `&&` | ✅ | ✅ | ✅ | `cmd1 && cmd2` |
| OR list `\|\|` | ✅ | ✅ | ✅ | `cmd1 \|\| cmd2` |
| Semicolon `;` | ✅ | ✅ | ✅ | `cmd1; cmd2` |
| Negation `!` | ✅ | ✅ | ✅ | `! cmd` |
| Tilde expansion `~` | ✅ | ✅ | ✅ | `~/bin/script` |
| `$HOME` variable | ✅ | ✅ | ✅ | `$HOME/bin/script` |
| `false` | ✅ | ✅ | ✅ | `/usr/bin/false` (exit code 1) |
| `true` | ✅ | ✅ | ✅ | `/usr/bin/true` (exit code 0) |
| `source file` | ✅ | ✅ | ✅ | `source ~/.env` |

All of these are either external commands (resolved via `$PATH`) or
shell operators with identical syntax in bash, zsh, and fish.

**Restrictions — avoid these in command expressions:**

| Pattern | Bash/Zsh | Fish | Workaround |
|---------|----------|------|------------|
| `$(subcmd)` | ✅ | ❌ fish: `(subcmd)` | Use a wrapper script in `[env]`/`[env.fish]` |
| `` `subcmd` `` | ✅ | ❌ | Same — use a wrapper script |
| `VAR=val cmd` (inline env) | ✅ | ❌ fish: `set -x VAR val; cmd` | Put exports in `[env]`, use `env VAR=val cmd` as portable alternative |
| `export X=y cmd` | ✅ | ❌ fish: `set -gx X y; cmd` | Put exports in `[env]`, not in expressions |
| `local x=1` | ✅ | ❌ fish has no `local` in command context | N/A — don't use in expressions |
| `[[ condition ]]` | ✅ | ❌ fish: `test condition` | Use `test` (POSIX, works everywhere) |
| `$(( arithmetic ))` | ✅ | ❌ fish: `(math expr)` | Use an external tool like `expr` or `bc` |
| Array expansion `${arr[@]}` | ✅ | ❌ | Don't use arrays in expressions |
| Process substitution `<(cmd)` | ✅ | ❌ fish: uses psub function | Avoid; use temp files or pipes |
| Here-strings `<<< "$var"` | ✅ | ❌ fish: `echo $var \| cmd` | Use `echo ... |` pattern |
| Heredocs `<< EOF` | ✅ | ❌ fish: uses different syntax | Use `echo` or temp files |
| `return N` | ✅ | ❌ fish: only valid inside functions | Use external command with exit code, or `sh -c "exit N"` |
| `exit N` | ✅ | ⚠️ | Exits the wrapper shell — not useful in command expressions |
| `source file` (with bash syntax) | ✅ | ❌ if file contains bash syntax | Source shell-appropriate files |

### Dynamic command words: `$variable` and `&function`

Command words can be dynamic — expanded at load time from shell state.
These live before the colon and are parsed by the shell wrapper, not AWK.

**`$variable` expansions** (e.g., `$__VAR_EXPANSION_WORDS: echo \0`):

| Aspect | Portable? | Notes |
|--------|-----------|-------|
| Reference syntax (`$VAR`) | ✅ | Same syntax in all three shells |
| Value format (space-separated string) | ✅ | `export VAR="a b c"` works in all |
| Setting via `export VAR=val` in `[env]` | ✅ | Fish wrapper translates to `set -gx` |
| Value containing shell syntax | ❌ | Value is just strings, no issue in practice |

`$variable` expansions are fully portable. The variable is set in `[env]`
(plain `export VAR=value`), and the fish wrapper handles the `export` →
`set -gx` translation. The value itself is just a string — no shell syntax.

**`&function` expansions** (e.g., `&create_cmd_words: echo \0`):

| Aspect | Portable? | Notes |
|--------|-----------|-------|
| Reference syntax (`&func`) | ✅ | Config-level syntax, parsed by all wrappers |
| Calling mechanism | ✅ | All wrappers call the function and capture output |
| Output format (one word per line) | ✅ | Just stdout text |
| **Function definition** | **❌** | **Must be defined in each shell's syntax** |

The function interface is portable: called with no args, outputs one word
per line to stdout. But the function body uses shell syntax:

```bash
# Bash/zsh — in [env]
function create_cmd_words() {
    echo "thievery"
    echo "corporation"
}
```

```fish
# Fish — in [env.fish]
function create_cmd_words
    echo "thievery"
    echo "corporation"
end
```

The function body is identical in this case (just `echo` calls), but the
surrounding syntax differs. For cross-shell configs, define the function
in both `[env]` and `[env.fish]`.

**Can you write a single function definition that works in all three
shells?** No. The function declaration syntax is incompatible:

| Feature | Bash | Zsh | Fish |
|---------|------|-----|------|
| Declaration | `function f() {` | `function f() {` | `function f` |
| Body terminator | `}` | `}` | `end` |
| Arguments | `$1`, `$2` | `$1`, `$2` | `$argv[1]`, `$argv[2]` |
| Quoting | `"$var"` | `"$var"` | `"$var"` (same) |

There is no overlap — bash/zsh share `function f() { ... }` but fish
requires `function f ... end`. The definitions must be separate.

**`list-expansion` command words** (e.g., `thievery|corporation: echo \0`):

| Aspect | Portable? | Notes |
|--------|-----------|-------|
| Pipe-separated syntax | ✅ | Parsed by AWK, not shell |
| Expansion into multiple commands | ✅ | AWK expands, shell sees flat list |

Fully portable — no shell involvement.

### Argument value expressions

Argument definitions (`:name:type:value:description`) also contain
expressions in the value field. Portability depends on the arg type:

| Arg type | Value field | Portable? | Notes |
|----------|-------------|-----------|-------|
| `list` (static) | `val1\|val2\|val3` | ✅ | Parsed by AWK, not shell |
| `list` (from `$var`) | `$VARIABLE` | ✅ | Variable set via `export` in `[env]`, fish wrapper translates |
| `eval` | `function_name` | ❌ | Function must be defined in shell syntax; needs `[env]` + `[env.fish]` |
| `int_range` | `1-65535` | ✅ | Parsed by AWK |
| `value` | `default_string` | ✅ | Just a string |
| `STRING` | (none) | ✅ | No value field |
| `INTEGER` | (none) | ✅ | No value field |
| `FILE` | optional glob `*.txt` | ✅ | Glob is a string, shell expands at completion time |
| `DIR` | optional glob | ✅ | Same |
| `FILE_OR_DIR` | optional glob | ✅ | Same |
| `ENVVAR` | (none) | ✅ | Shell lists env vars natively |
| `USER` | (none) | ✅ | Reads /etc/passwd |
| `GROUP` | (none) | ✅ | Reads /etc/group |
| `SSH_HOST` | (none) | ✅ | Parses ~/.ssh/config |
| `BLKDEV` | (none) | ✅ | OS-level listing |
| `SERVICE` | (none) | ✅ | systemctl / launchctl / rc.d |

The only non-portable arg type is `eval` — it calls a shell function by
name, so the function must be defined in each shell's syntax. All other
types are either AWK-parsed (static values) or handled by the shell
wrapper using OS-level queries (no shell syntax in the value field).

**`eval` arg functions** (e.g., `:pod:eval:get_pods default`):

The function name is config-level (portable). The function body is
shell-specific. Same situation as `&function` command words:

```bash
# Bash/zsh — in [env]
function get_pods() {
    kubectl get pods -n "$1" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n'
}
```

```fish
# Fish — in [env.fish]
function get_pods
    kubectl get pods -n $argv[1] -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n'
end
```

Note the argument access: `$1` (bash/zsh) vs `$argv[1]` (fish). This is
the most common incompatibility in eval functions — not the function
wrapper syntax, but how you access arguments.

For cross-shell configs, define eval functions in both `[env]` and
`[env.fish]`.

**Safe rule of thumb:** If the expression is `program arg1 arg2 ...` with
optional pipes and redirects, it's portable. If it uses shell language
features (subshells, conditionals, variable assignment, arithmetic), it's not.

### Zone 3: Shell-specific (`[env]` functions, `eval` args)

These are inherently tied to one shell's syntax:

**`[env]` function definitions:**

```bash
# Bash/zsh — works in both
function get_pods() {
    kubectl get pods -n "$1" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n'
}
```

```fish
# Fish — must be in [env.fish]
function get_pods
    kubectl get pods -n $argv[1] -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n'
end
```

Key differences:
- Fish: no `()`, no `{`, no `$1` (uses `$argv[1]`)
- Fish: `end` instead of `}`
- Fish: no `function` keyword with parens

**`eval`-type argument functions** (`:pod:eval:get_pods`):

The function name is stored in config (portable). The function body must
exist in the executing shell's environment. For cross-shell configs, define
the function in both `[env]` (bash/zsh) and `[env.fish]` (fish).

**`&function` command word expansions** (`&create_cmd_words: echo \0`):

Same as eval args — the function must be defined in the executing shell.
Define in both `[env]` and `[env.fish]`.

**`$variable` command word expansions** (`$__VAR_EXPANSION_WORDS: echo \0`):

The variable must be set in the executing shell's environment. Simple
`export VAR=value` assignments in `[env]` are portable if the value is a
plain string (no shell syntax in the value). The fish wrapper translates
`export VAR=value` to `set -gx VAR value`.

## Cross-shell config template

```
[env]
# Shared settings — work in bash, zsh, AND fish
__CLI_CFG_EXEC_SILENT=n

# Simple variable assignments — portable
export DEPLOY_ENV="staging"

# Source a shared file (if the file itself is portable)
source ~/.mycli-common.env

# include_commands_from is fully portable
include_commands_from ~/.mycli-commands.conf ROOT

# Bash/zsh functions — NOT portable to fish
function get_pods() {
    kubectl get pods -n "$1" -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n'
}

[env.fish]
# Fish functions — same logic, fish syntax
function get_pods
    kubectl get pods -n $argv[1] -o jsonpath='{.items[*].metadata.name}' | tr ' ' '\n'
end

[commands]
# Portable: external commands with args and placeholders
k
    get
        pods: kubectl get pods -o wide
        services: kubectl get svc
    logs
        default: kubectl logs -f -n default \1
            :pod:eval:get_pods default
```

## Pros and Cons of the Options

### Option A: Document restrictions, `[env.fish]` section (chosen)

Add `[env.fish]` as an optional section. Document which config patterns are
portable and which are shell-specific. Author's responsibility to follow
the restrictions.

**Good**, because:
- Single config file serves bash, zsh, and fish audiences
- No changes to existing bash/zsh wrappers — they ignore `[env.fish]`
- AWK parser change is minimal (recognize one more section header)
- Users who only target one shell are unaffected
- Follows the existing pattern: `[env]` is already "whatever the shell
  understands" — we're just adding a fish-specific variant

**Bad**, because:
- Nothing prevents an author from writing non-portable expressions and
  claiming the config is cross-shell
- Two function definitions needed for eval args / &function expansions
- No automated validation of portability

**Neutral**, because:
- The restriction set is small and mostly obvious ("don't use bash syntax
  in command expressions if you want fish compatibility")
- The `[env]`/`[env.fish]` split mirrors how real projects handle
  cross-shell config (`.bashrc` vs `config.fish`)

### Option B: Shell-agnostic expression language

Invent a mini-language for command expressions that the tool translates
to bash, zsh, and fish. Something like:

```
# Hypothetical
command: {{exec}} kubectl get pods -n {{arg:namespace}} -o wide
```

**Good**, because:
- True portability — the tool guarantees correct output in all shells
- No author knowledge of shell differences required

**Bad**, because:
- Massive scope increase — we're building a shell abstraction layer
- The existing config format is already established; breaking change
- Most command expressions are simple `program args` anyway — solving
  a problem that barely exists
- Maintenance burden: every new shell feature needs a translation

**Neutral**, because:
- This is what tools like Cobra (Go) or Click (Python) do — but they
  have a real language to work with

### Option C: Fish wrapper ignores `[env]` entirely, only reads `[env.fish]`

Fish users must duplicate ALL env settings in `[env.fish]`. Nothing shared.

**Good**, because:
- Complete separation — no ambiguity about what works where
- Fish wrapper is simpler (one section to parse)

**Bad**, because:
- `__CLI_CFG_*` settings must be duplicated
- `export VAR=value` must be duplicated
- `include_commands_from` must be duplicated
- Defeats the purpose of a single config file

### Consequences

- Good, because a single config file serves bash, zsh, and fish audiences
- Good, because existing bash/zsh wrappers are unaffected — they simply ignore `[env.fish]`
- Good, because `$variable` expansions are fully portable when set via simple `export VAR=value` in `[env]`
- Good, because authors targeting a single shell face no restrictions — the config format is unchanged for them
- Bad, because `eval`-type and `&function`-type features require dual function definitions in `[env]` and `[env.fish]` for cross-shell configs
- Bad, because nothing prevents an author from writing non-portable expressions and claiming the config is cross-shell
- Neutral, because command expressions in `[commands]` are portable only if they use external commands, pipes, and redirects
- Neutral, because the AWK parser must recognize `[env.fish]` as a section header (minimal change)

## What this ADR is missing

- **Config validation**: should `--cli-validate-config` warn about
  non-portable patterns in command expressions? (e.g., `$(...)` usage
  when fish compatibility is intended)
- **Fish version requirement**: Fish 3.0+ for `set -gA` (associative
  arrays). Should this be enforced or documented?
- **`eval` semantics in fish**: Fish has no `eval`. The fish wrapper
  calls functions directly. Is this a semantic difference that matters?
  (bash `eval` allows arbitrary code; fish function call is bounded)
- **Testing strategy**: how to test that a config is actually cross-shell
  compatible. Bats tests for fish? A compatibility linter?
- **Migration path**: for existing configs that want to add fish support.
  What's the minimal diff?

## References

- ADR-006: Config file structure
- ADR-013: AWK/shell split: parsing in AWK, matching in shell
- `docs/FISH-COMPARISON.md`: Fish shell API comparison
- `docs/dev/FISH-PLAN.md`: Fish integration implementation plan
