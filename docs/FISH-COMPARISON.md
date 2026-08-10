# Fish Shell Integration Reference

Comparison of bash/zsh and fish shell completion APIs for audogombleed.sh.

## Completion model comparison

| Concept | Bash | Zsh | Fish |
|---------|------|-----|------|
| Registration | `complete -F _func prog` | `compdef _func prog` | `complete -c prog -f -a '(_func)'` |
| Command line access | `$COMP_WORDS`, `$COMP_CWORD`, `$COMP_LINE` | `$words`, `$CURRENT` | `commandline -opc`, `commandline -ct` |
| Result delivery | `COMPREPLY` array | `_values` with `[desc]` suffixes | stdout of `-a` argument |
| Descriptions | N/A | `value[description]` suffix | `complete -a 'val' -d 'desc'` |
| Variable indirection | `${!var}` | `${(P)var}` | `$$var` |
| Associative arrays | `declare -A` | `declare -A` | `set -gA name key value` (3.0+) |
| Array from output | `mapfile -t arr < <(cmd)` | `arr=("${(@f)$(cmd)}")` | `set arr (cmd)` |
| Function existence | `declare -f "$fun"` | `(( $+functions[fun] ))` | `functions -q "$fun"` |
| eval | `eval "$cmd"` | `eval "$cmd"` | No eval; `fish -c "$cmd"` or avoid |
| printf -v | `printf -v var '%s' val` | `printf -v var '%s' val` | `set var value` |
| Word splitting | `read -a arr <<<"$str"` | `${(z)str}` | Native (arrays split on newlines) |
| Source detection | `$0 != ${BASH_SOURCE[0]}` | `$zsh_eval_context =~ file` | `status is-interactive` |
| Glob options | `shopt -s extglob` | `setopt null_glob` | Always extended |
| File completion | `compgen -f` | `compadd` | `__fish_complete_path` |
| Dir completion | `compgen -d` | `compadd -/` | `__fish_complete_directories` |

## AWK output format comparison

### Bash (`output=commands command_filter="..."`)

```bash
declare -g -A __CMD_ARG __CMD_ARG_TYPE __CMD_ARG_VALUE __CMD_ARG_DESC __CMD_ARG_NAME
__CMD="echo"
__CMD_ARG[0]="arg1"
__CMD_ARG_NAME[0]="arg1"
__CMD_ARG_TYPE[0]="list"
__CMD_ARG_VALUE[0]="first|second"
__CMD_ARG_DESC[0]=""
```

Source'd via `eval "$(_awk output=commands command_filter="echo")"`.

### Fish (`output=fish command_filter="..."`)

```fish
set -g __CMD echo
set -gA __CMD_ARG 0 arg1
set -gA __CMD_ARG_NAME 0 arg1
set -gA __CMD_ARG_TYPE 0 list
set -gA __CMD_ARG_VALUE 0 'first|second'
set -gA __CMD_ARG_DESC 0 ''
```

Parsed via `for line in $arg_info; eval $line; end`.

## Known limitations

- Fish 3.0+ required for `set -gA` (associative arrays)
- `[env]` functions must be defined in fish syntax for `eval`-type arguments
- No execution support in v1 (completions only)
- Fish has no `eval` builtin — `eval`-type arguments call fish functions directly
