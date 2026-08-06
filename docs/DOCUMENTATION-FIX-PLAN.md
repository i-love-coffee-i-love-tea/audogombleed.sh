# Documentation Fix Plan

This plan covers fixes to documentation, release tooling, and one code improvement (`include_commands_from` error handling). Each task is numbered and references the original review finding.

---

## T1. Fix `release.sh` to update manpage version (Finding #2)

**File:** `release.sh`

**Problem:** `release.sh` only updates `__CLI_VERSION` in `audogombleed.sh`. The manpage `audogombleed.1` line 1 has a hardcoded version (`1.1.1`) that is never updated.

**Fix:** After the `sed` that updates the script version (line 18), add a `sed` to update the manpage `.TH` macro:

```bash
sed -i "s/^\.TH AUDOGOMBLED\.SH 1 \".*\" \".*\" \".*\"/.TH AUDOGOMBLED.SH 1 \"$(date +%Y)\" \"$version\" \"User Commands\"/" "$manpage"
```

Add `manpage="audogombleed.1"` alongside `script="audogombleed.sh"` at the top, and `git add "$manpage"` to the commit.

---

## T2. Fix `example.conf` missing space (Finding #3)

**File:** `example.conf`

**Problem:** Line 51 has `echo: \0 \2 \1` but the argument lines use `:arg1:list:first` — this is actually valid syntax (the parser accepts `:name:type:value` with the type being `list`), so this is NOT a real issue. However, the example uses argument names `arg1`/`arg2` which are less descriptive than the docs' convention. No change needed — the syntax is correct.

**Status:** No fix required. The syntax is valid.

---

## T3. Add missing CLI options to `02-configuration.md` (Finding #4)

**File:** `docs/02-configuration.md`

**Problem:** The manpage documents `--version` and `--cli-print-env` but the markdown docs don't mention them.

**Fix:** Add to the "CLI command line arguments" section (after line 208):

```markdown
### `--version`

Print the script version and exit.

### `--cli-print-env`

Print the parsed `[env]` section (for development/debugging).
```

---

## T4. Document optional argument syntax `?` (Finding #5)

**File:** `docs/02-configuration.md`

**Problem:** The manpage shows `:arg:list?:val1|val2` (append `?` to make an argument optional) but this isn't in any markdown doc.

**Fix:** Add a subsection after the "Argument placeholders" section (after line 68):

```markdown
### Optional arguments

Append `?` to the argument type to make it optional:

    [commands]
    deploy: ./deploy.sh \1
        :target:list:staging|prod
        :tag:list?:v1|v2|v3

Here `:tag` is optional — the command executes with or without it.
Optional arguments must come after all required arguments.
```

---

## T5. Add comprehensive argument type table to `02-configuration.md` (Finding #6)

**File:** `docs/02-configuration.md`

**Problem:** The getting-started doc has a partial argument type table (6 types). The manpage lists 14 types. The configuration reference has no table at all.

**Fix:** Add a full argument types reference table after the new optional-arguments section:

```markdown
### Argument types

| Type | Syntax | Completion behavior |
|------|--------|---------------------|
| Static list | `:arg:list:val1\|val2\|val3` | Fixed set of values |
| Variable list | `:arg:list:$VAR` | Values from a shell variable |
| Function list | `:arg:eval:function_name` | Values from function output |
| Default value | `:arg:value:default` | Uses default (not a completion list) |
| String | `:arg:STRING` | Free-form string |
| Integer | `:arg:INTEGER` | Integer value |
| Integer range | `:arg:int_range:min-max` | Integer within range (inclusive) |
| File | `:arg:FILE` | File path completion |
| Directory | `:arg:DIR` | Directory path completion |
| Env variable | `:arg:ENVVAR` | Environment variable names |
| User | `:arg:USER` | System usernames |
| Group | `:arg:GROUP` | System group names |
| SSH host | `:arg:SSH_HOST` | Hosts from `~/.ssh/config` |
| Block device | `:arg:BLKDEV` | Block device names |
| Service | `:arg:SERVICE` | systemd service names |

Any type can be made optional by appending `?` (e.g., `:arg:list?:val1|val2`).
```

---

## T6. Add warning about expensive `[env]` operations (Finding #7)

**File:** `docs/02-configuration.md`

**Problem:** The docs say `[env]` is "sourced before each completion and command execution" but don't warn about performance implications.

**Fix:** Add a note after the `[env]` section description (after line 78):

```markdown
**Performance note:** the `[env]` section runs on every tab completion and
every command execution. Avoid slow operations (network calls, heavy
computation) in `[env]` — they will block completion and add latency to
every invocation. If you need dynamic values, use `eval` argument types
instead, which run only at completion time.
```

---

## T7. Fix version inconsistency across files (Finding #8)

**Problem:** Three different version numbers:
- `audogombleed.sh:68` → `__CLI_VERSION="1.2.0"`
- `audogombleed.1:1` → `"1.1.1"`
- `CHANGELOG.md` → lists `1.2.1` as latest

**Analysis:** CHANGELOG 1.2.1 is the *planned* next release (contains unreleased changes). The script version `1.2.0` is the last released version. The manpage `1.1.1` is stale from two releases ago.

**Fixes:**
1. Update manpage version to `1.2.0` (current released version) — `release.sh` fix (T1) prevents this drift in the future.
2. CHANGELOG 1.2.1 is correct as-is (it documents unreleased work). No change needed.
3. Add missing entries to CHANGELOG 1.2.1:

```markdown
## 1.2.1

- ... (existing entries) ...
- Add `--version` and `--cli-print-env` CLI options to manpage
- Fix manpage version tracking — `release.sh` now updates `audogombleed.1`
- Fix `include_commands_from` to validate file existence (like `source` does)
- Add optional argument syntax (`?`) documentation
- Add full argument types reference table to configuration docs
- Fix log file path documentation (was `/tmp/cli-bash.log`, actual is `/tmp/cli-XXXXXX-bash.log`)
- Remove stale demo creation tooling references from demo README
- Add error handling documentation for `include_commands_from`
```

---

## T8. Fix `02-configuration.md` `__CLI_CFG_EXEC_SILENT` description (Finding #9)

**File:** `docs/02-configuration.md`

**Problem:** The detailed description at line 178 says "Suppress all CLI output on stdout and stderr" but also overrides abbreviation expansion. The override behavior IS documented below it (lines 183-188), but the lead sentence could be clearer.

**Fix:** Update line 178-188 to:

```markdown
#### `__CLI_CFG_EXEC_SILENT` (default: "n")

Suppress all CLI output. When set to `"y"`, interactive features that
produce output are also disabled:

    __CLI_CFG_EXEC_EXPAND_ABBREVIATED_COMMANDS="n"
    __CLI_CFG_EXEC_EXPAND_ABBREVIATED_ARGS="n"

This is because abbreviated command expansion normally asks the user to
confirm before execution — that prompt is impossible when output is
suppressed. The same overrides are applied by `-b` / `--batch`.
```

Remove the "on stdout and stderr" phrase since the behavior is broader than just output suppression.

---

## T9. Add config file encoding note (Finding #12)

**File:** `docs/02-configuration.md`

**Problem:** No mention of encoding or line ending requirements.

**Fix:** Add a note at the top of the file, after the opening paragraph (after line 11):

```markdown
**File encoding:** config files must use UTF-8 encoding with Unix line
endings (LF). Windows-style CRLF line endings will cause parsing errors.
```

---

## T10. Document `include_commands_from` error handling (Finding #13)

**Files:** `docs/04-hierarchical-configuration.md`, `audogombleed.sh`

### Part A: Fix the code

**Problem (from code analysis):** `include_commands_from` has zero error handling:
- Missing file: silent failure (awk prints to stderr, commands vanish)
- No `[commands]` section: silent failure
- Empty path: silently skipped
- Contrast: `source` directive validates file existence and emits `_cli_error`

**Fix in `audogombleed.sh` lines 1510-1523:** Add a file-existence check matching the pattern used by `source` (lines 1496-1508):

```bash
# After line 1518 (tilde expansion), add:
if [ ! -f "$include_file" ]; then
    _cli_error "config error: [env] line $line_nr:'$env_line'; include file '$include_file' does not exist or is not a file"
    return 1
fi
```

### Part B: Document the behavior

**Fix in `docs/04-hierarchical-configuration.md`:** Add a new section after "How it works":

```markdown
## Error handling

- **Missing file:** if the included config file does not exist, the CLI
  prints an error and stops. Check the path and filename.
- **No `[commands]` section:** if the included file exists but has no
  `[commands]` section, the include is silently ignored (no commands
  are merged). The rest of the config works normally.
- **One level only:** `include_commands_from` only works in the main
  config's `[env]` section. Included files cannot include further files.
  Any `include_commands_from` in an included file is treated as a shell
  command and executed (not parsed as an include directive).
```

---

## T11. Fix log file path documentation (Finding #15)

**Files:** `docs/02-configuration.md`, `docs/10-faq.md`, `audogombleed.sh` (comment at line 62)

**Problem:** Docs say `/tmp/cli-bash.log` but actual path is `/tmp/cli-XXXXXX-bash.log` (random via mktemp).

**Fixes:**

1. `docs/02-configuration.md` line 142-143 — change to:
   ```
   If set to 4, a log file is created under `/tmp` with a random name
   (pattern: `/tmp/cli-XXXXXX-bash.log` or `/tmp/cli-XXXXXX-zsh.log`).
   Check `ls /tmp/cli-*` to find it.
   ```

2. `docs/10-faq.md` lines 100-105 — already correct (mentions XXXXXX). No change.

3. `audogombleed.sh` lines 62-64 — update comment to match actual behavior:
   ```
   # debug logs to /tmp/cli-XXXXXX-bash.log or /tmp/cli-XXXXXX-zsh.log
   ```

---

## T12. Clean up `demo/README.md` (Finding #17)

**File:** `demo/README.md`

**Problem:** References `autocast` and `agg` tools for regenerating demos. These are obscure external dependencies. Also the "Regenerating the Demo" and "Customizing the Demo" sections add maintenance burden.

**Fix:** Rewrite to remove all demo-creation tooling references:

```markdown
# Demo

This directory contains a demo GIF showcasing the basic features of audogombleed.

## Files

- `demo-simple.gif` - Demo GIF showing basic features
- `demo.conf` - Configuration file used in the demo

## Features Demonstrated

1. **Help Output** - Running `demo ?` displays available commands
2. **Tab Completion** - Typing `h` and pressing TAB completes to `hello`
3. **Command Abbreviation** - Typing `g f` executes `greeting formal`
4. **Subcommand Completion** - Typing `g` and pressing TAB shows subcommand options
```

Remove the "Regenerating the Demo" and "Customizing the Demo" sections entirely, along with references to `createdemo.sh`, `run-demo.sh`, `demo-simple.cast`, `demo-simple.yaml`, `autocast`, and `agg`.

---

## T13. Mark dev-only CLI options clearly (Finding #19)

**File:** `docs/02-configuration.md`

**Problem:** `--cli-print-awk-script` and `--cli-run-awk-command` say "(for development)" but aren't clearly separated from user-facing options.

**Fix:** Add a note after the CLI arguments section:

```markdown
The following options are for development and debugging only:

- `--cli-print-awk-script` — prints the embedded AWK config parser script
- `--cli-run-awk-command` — runs the embedded AWK config parser directly
```

And update the existing entries to use consistent "(development/debugging)" phrasing.

---

## T14. Clarify placeholder semantics and `\0` vs `\1` distinction (Finding #20)

**Files:** `docs/02-configuration.md`, `docs/03-advanced-command-configurations.md`

**Problem (from code analysis):** The placeholder system has a conceptual asymmetry:
- `\0` = last word of the **command path** (not an argument)
- `\1`, `\2`, ... = positional **user arguments** (1-indexed, mapped to `:name:type:source` definitions in order)

This is not a bug but is confusing. The docs show `\0` and `\1` in examples without clearly explaining they come from different domains.

**Fix in `docs/02-configuration.md`:** Update the "Argument placeholders" section (lines 56-68):

```markdown
### Argument placeholders

`\0` is replaced by the last word of the command path (the word before
the colon). `\1`, `\2`, etc. are replaced by user-supplied arguments,
matching the `:name:type:source` definitions in order:

    [commands]
    echo: echo \2 \1
        :first:list:one|two
        :second:list:alpha|beta

    $ mycli echo one alpha
    >> executes: echo alpha one

`\1` maps to the first argument definition (`:first`), `\2` to the
second (`:second`). If not all placeholders are used, remaining
arguments are appended to the end of the command.

**Note:** `\0` and `\1`+ come from different sources. `\0` is always
the last command word (useful with `$variable` or `&function` expansion
where the expanded word is the value you need). `\1`+ are the user's
arguments after the command words.
```

**Fix in `docs/03-advanced-command-configurations.md`:** Add a note after the "Argument placeholders" section (after line 144):

```markdown
### Placeholder reference

| Placeholder | Replaced by | Source |
|-------------|-------------|--------|
| `\0` | Last word of the command path | The matched command (e.g., `file` in `install jar from file`) |
| `\1` | First user argument | First `:name:type:source` definition |
| `\2` | Second user argument | Second `:name:type:source` definition |
| ... | ... | ... |

`\0` is most useful with expanded commands (`$variable`, `&function`,
`val1|val2`) where the expanded word carries meaning (e.g., a namespace
name). For simple commands, `\1`+ are usually all you need.
```

---

## File change summary

| File | Tasks |
|------|-------|
| `release.sh` | T1 |
| `audogombleed.sh` | T10A, T11 (comment) |
| `docs/02-configuration.md` | T3, T4, T5, T6, T8, T9, T11, T13, T14 |
| `docs/03-advanced-command-configurations.md` | T14 |
| `docs/04-hierarchical-configuration.md` | T10B |
| `docs/10-faq.md` | (no change needed — already correct) |
| `audogombleed.1` | T7 (version bump to 1.2.0) |
| `CHANGELOG.md` | T7 (add missing entries to 1.2.1) |
| `demo/README.md` | T12 |

## Execution order

1. **T1** — release.sh (foundational tooling fix)
2. **T10A** — code fix for include_commands_from validation
3. **T7** — version sync (manpage + changelog)
4. **T3, T4, T5, T6, T8, T9, T11, T13, T14** — docs/02-configuration.md changes
5. **T14** — docs/03-advanced-command-configurations.md
6. **T10B** — docs/04-hierarchical-configuration.md
7. **T11** — audogombleed.sh comment fix
8. **T12** — demo/README.md cleanup
