# ADR-010: Scoped &function loading

Author: i-love-coffee-i-love-tea
Status: Accepted

## Context

Currently, `_cli_load_command_word_functions` (line 3136) calls ALL `&function`
entries in the entire config on every tab press, regardless of which command is
being completed.

The current completion flow:

```
1. _cli_load_command_word_functions  → calls ALL &functions, sets env vars
2. _cli_read_command_list            → AWK expands commands using env vars
3. _cli_is_command_complete          → matches user input against expanded list
4. _cli_load_completion_vars         → loads vars for matched command
5. _cli_complete_arg                 → completes arguments
```

**Problem**: If a config has 10 commands with `&function` entries, all 10 are
called on every Tab press—even when only one command is being completed. Each
`&function` may call external commands (kubectl, database queries, etc.), making
this expensive.

**Why naive optimization doesn't work**: Command determination (step 3) depends
on the expanded command list (step 2), which depends on &function results (step
1). We cannot simply skip &function calls—the command list won't be correct.

## Decision

Implement scoped &function loading:

- **Phase 1**: Determine which command is being completed using a static
  command structure (with &function placeholders preserved, not expanded)
- **Phase 2**: Call only the &function(s) relevant to the matched command

## Design

### Key constraint: `&function` only on last command word

`&function` is only supported on the **last command word** of a command
definition, not on arbitrary levels. From `docs/03-advanced-command-configurations.md:88-90`:

> Note: `&` expands command words. To complete *arguments* from a function,
> use `:argname:eval:function_name` instead

This means:
- Command structure is always **static up to the last word**
- Only the **final dynamic word** (if any) uses `&function`
- We can match the static prefix **without calling any `&function`**
- Only call `&function` when completing the dynamic word itself

Example:
```
# Static prefix: "k logs default" — matches without &function
# Dynamic word: &get_pods default — calls function only when completing this
k logs default: kubectl logs -f -n default \1
    :pod:eval:get_pods default
```

This significantly simplifies the scoped &function loading design because we don't need to
handle `&function` at arbitrary nesting levels.

### New AWK output mode: `command_structure`

Add a new `output=command_structure` mode that returns command names with
dynamic placeholders intact:

```
# Config:
function-expansion
    &create_cmd_words: echo \0
deploy
    &get_deployments: kubectl deploy \0

# output=command_structure returns:
function-expansion &create_cmd_words
deploy &get_deployments
```

This mode skips `expand_dynamic_commands()` and preserves the raw `&function`
or `$var` references in the command words.

### New bash function: `_cli_get_functions_for_command()`

Given a command prefix (e.g., "function-expansion"), returns the &function
names needed for that command:

```bash
_cli_get_functions_for_command() {
    local cmd_prefix="$1"
    # Use AWK to find &functions associated with this command
    _awk output=command_functions_for command_filter="$cmd_prefix"
}
```

### New AWK output mode: `command_functions_for`

Given a `command_filter`, returns only the &function names that appear in that
command's subtree:

```
# command_filter="deploy" returns:
get_deployments

# command_filter="function-expansion" returns:
create_cmd_words
```

### Modified completion flow

```
Phase 1 (no &function calls):
  1. _cli_read_command_structure  → AWK returns structure with placeholders
  2. _cli_match_command           → match user input against structure
  3. Determine matched command prefix

Phase 2 (targeted &function calls):
  4. _cli_get_functions_for_command → get &functions for matched command only
  5. _cli_load_command_word_functions_filtered → call only those &functions
  6. _cli_read_command_list       → AWK expands commands (using filtered env vars)
  7. _cli_load_completion_vars    → load vars for matched command
  8. _cli_complete_arg            → complete arguments
```

### Matching with placeholders

Phase 1 matching needs to handle placeholder words. For example:

- User types: `function-expansion th`
- Structure contains: `function-expansion &create_cmd_words`
- Matching logic:
  1. `function-expansion` matches the static prefix
  2. `&create_cmd_words` is a placeholder → this command has dynamic words
  3. Record that `function-expansion` needs `create_cmd_words`
  4. In Phase 2, call `create_cmd_words` and expand

For commands without dynamic words (e.g., `echo arg1 arg2`), Phase 1 matching
works directly without needing Phase 2 expansion.

### Dependency analysis (confirmed by code exploration)

| Component | Needs &function results? | Reason |
|-----------|------------------------|--------|
| `_cli_getfirstwords` (line 2053) | Yes, for top-level `&func` commands | AWK `cache_command_names` reads ENVIRON |
| `_cli_count_matching_commands` (line 1633) | Yes, indirectly via `__CLI_CONFIG[]` | `__CLI_CONFIG[]` has pre-expanded dynamics |
| `_cli_command_is_exact_match` (line 1649) | Yes | AWK `print_command` calls `expand_dynamic_commands` |
| `_cli_is_command_complete` (line 1825) | Yes, via both above | Uses both functions |
| `_cli_load_completion_vars` (line 1654) | Yes, for dynamic commands | AWK `expand_dynamic_commands` matches filter |
| `_cli_complete_arg` (line 2652) | Indirectly (reads env vars) | Uses `ENVIRON` via indirect expansion |
| `_cli_expand_abbreviated_command` (line 3027) | No (execution only, not tab completion) | Not called during tab completion |

**Chicken-and-egg for `_cli_is_command_complete`**: This function needs to match
user input against commands. If the user types `container my-container`, it
needs to know that `my-container` is a valid expansion of `&list_containers`.
Without calling the function, it cannot verify this. Solution: use a "fuzzy
match" approach—match the static prefix (`container`) and then call only
`list_containers` to verify the dynamic part.

**Current AWK `command_word_functions` output lacks command context** (line
675-684): It outputs only bare function names (e.g., `list_containers`), with no
indication of which command path they belong to. The new `command_functions_for`
mode must output `command_path function_name` pairs.

### Command structure cache

The command structure is a pure function of the config file content (it doesn't
depend on &function results). It can be cached by mtime, same as the command
list currently is.

```bash
_cli_read_command_structure() {
    local _cfg_file _cfg_mtime
    _cfg_file="$(_cli_global CONFIG_FILE)"
    _cfg_mtime=$(_cli_mtime "$_cfg_file")
    if [ "$_cfg_mtime" = "$__CLI_CMD_STRUCT_MTIME" ] && [ -n "$__CLI_CMD_STRUCT" ]; then
        return
    fi
    __CLI_CMD_STRUCT="$(_awk output=command_structure)"
    __CLI_CMD_STRUCT_MTIME="$_cfg_mtime"
}
```

## Implementation steps

### Step 1: Add `command_structure` AWK output mode

Modify the AWK script to add `output=command_structure`:

- In the `cache_command_names()` function, when `output_type == "command_structure"`:
  - If the last word is a dynamic command (`is_dynamic_command`), preserve it
    as-is instead of calling `expand_dynamic_commands`
  - Format: `command_prefix dynamic_word`

**Files**: `audogombleed.sh` (AWK script section, around line 1350)

### Step 2: Add `command_functions_for` AWK output mode

Add `output=command_functions_for` that returns &function names for a specific
command filter:

- Similar to `command_word_functions` but filters by command prefix
- Uses `command_filter` parameter to match

**Files**: `audogombleed.sh` (AWK script section, around line 675)

### Step 3: Implement `_cli_read_command_structure()`

New bash function that reads and caches the command structure:

**Files**: `audogombleed.sh` (near `_cli_read_command_list`, line 442)

### Step 4: Implement `_cli_match_command_with_structure()`

New bash function that matches user input against the command structure:

- Similar to `_cli_is_command_complete` but works with placeholder-aware structure
- Returns: matched command prefix, whether it has dynamic words, which &functions
  are needed

**Files**: `audogombleed.sh` (near `_cli_is_command_complete`, line 1825)

### Step 5: Implement `_cli_load_command_word_functions_filtered()`

Modified version of `_cli_load_command_word_functions` that only calls specified
functions:

```bash
_cli_load_command_word_functions_filtered() {
    local funcs="$1"  # space-separated list of function names
    local fun
    for fun in $funcs; do
        if declare -f -p "$fun" 1>/dev/null 2>/dev/null; then
            _cli_map_function_output_to_env_var "$fun"
        else
            _cli_error "CLI warning: command word function '$fun' not available"
        fi
    done
}
```

**Files**: `audogombleed.sh` (near `_cli_load_command_word_functions`, line 3136)

### Step 6: Modify completion entry point

Update the completion function (around line 2880) to use scoped &function loading:

```bash
# Phase 1: Match command without &function calls
_cli_read_command_structure
_cli_read_command_list  # uses cached structure, no &function calls needed

# ... determine which command is being completed ...

# Phase 2: Call only relevant &functions
_funcs_needed="$(_cli_get_functions_for_command "$matched_cmd")"
_cli_load_command_word_functions_filtered "$_funcs_needed"
_cli_read_command_list  # re-expand with new &function results
```

**Files**: `audogombleed.sh` (completion function, around line 2880)

### Step 7: Update execution path

Apply the same optimization to `_cli_execute()` (line 3164):

- Determine command from args first
- Call only relevant &functions

**Files**: `audogombleed.sh` (`_cli_execute`, line 3164)

### Step 8: Update ADR 001

Update `docs/adr/001-reload-config-on-every-invocation.md` to reflect the new
behavior: &function calls are now scoped to the relevant command, not global.

**Files**: `docs/adr/001-reload-config-on-every-invocation.md`

## Edge cases

### 1. First-word completion

When completing the first word (no command prefix yet), we don't know which
command will be selected. Options:

- **Call all &functions for first-word completion** (fallback to current behavior)
- **Only complete static first words** (commands without dynamic prefixes)

Most CLI tools have static first words, so this is typically not a bottleneck.

### 2. Abbreviation expansion

`_cli_expand_abbreviated_command` uses `_cli_getmatchingcommands` which depends
on the expanded command list. For abbreviation expansion:

- If the abbreviation matches a static prefix, no &function calls needed
- If the abbreviation matches a dynamic prefix, call the relevant &function

### 3. Commands with multiple dynamic words

Some commands may have multiple `&function` entries in their subtree:

```
deploy
    &environments: &deployments: kubectl deploy \0 \1
```

The `command_functions_for` AWK mode should return all &functions in the
command's subtree.

### 4. Nested command groups

Command groups (parent nodes) may contain multiple commands with different
&functions. The matching should handle this correctly by matching the full
command path.

## Performance impact

**Before**: All &functions called on every Tab press.

**After**: Only &functions for the matched command are called.

**Expected improvement**:
- Config with 10 commands, each with &function: ~10x fewer function calls
- Config with 1 dynamic command: same performance (no regression)
- First-word completion: may still call all &functions (acceptable tradeoff)

## Alternatives considered

### Cache &function results by mtime

Would break the "always fresh" contract of &functions (they query live state).
Rejected per ADR-001 rationale.

### Lazy evaluation via AWK subshells

Have AWK call &functions on-demand via `system()` calls. Adds subshell overhead
per function call and makes the AWK script more complex. Less clean than
scoped &function loading approach.

### One-phase with command-to-function mapping

Build a mapping of command→function during config parse, use it to filter
function calls. Similar to this proposal but without the structure/matching
split. The scoped &function loading approach is clearer and more maintainable.

## Consequences

- Tab completion is faster for configs with multiple &function entries
- &function calls are scoped to the relevant command
- Command structure is cached by mtime (same as command list)
- First-word completion may still call all &functions (known limitation)
- Abbreviation expansion works correctly with the new approach

## Changes

- 2026-08-08: MiMo Code Agent - initial draft based on user optimization request
- 2026-08-08: Added dependency analysis from code exploration, clarified chicken-and-egg problem
