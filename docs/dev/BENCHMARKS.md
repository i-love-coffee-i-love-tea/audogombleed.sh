# Performance Benchmarks

Benchmark tests for completion latency (the TAB-press experience) and command
execution latency.

## Thresholds

From the dev README:

| Rating | Latency |
|--------|---------|
| Sluggish | >400ms |
| OK | ~200ms |
| Good | ~100ms |
| Very good | <50ms |

## Running the benchmarks

```bash
# bash benchmarks
./test/bats/bin/bats test/benchmark-bash.bats

# zsh benchmarks
./test/bats/bin/bats test/benchmark-zsh.bats

# both
./test/bats/bin/bats test/benchmark-bash.bats test/benchmark-zsh.bats
```

## What is measured

**Execution benchmarks** measure command execution latency — how long it takes
to run a command from the CLI. Uses `date +%s%N` for nanosecond timing.

**Completion benchmarks** measure the TAB-press path — how long `_cli_complete_`
takes to produce completion results. This is the critical UX path: every TAB
press re-reads the config and re-parses everything (by design, so config changes
take effect immediately).

The completion benchmarks source the script once, then time individual
`_cli_complete_` calls. This measures the per-TAB cost, not the one-time
sourcing cost.

## Test cases

| Test | What it measures |
|------|-----------------|
| simple command execution | `echo hello` via `-b` (batch mode) |
| hierarchical command execution | `install jar from file /tmp/test.jar` via `-b` |
| first-word completion | TAB on first word (`e` → `echo`, `list-expansion`, etc.) |
| second-word completion | TAB after first word (`echo` → `first`, `second`) |
| argument list completion | TAB on argument (`list-argument static` → `first-element`, `second`, etc.) |
| hierarchical command completion | TAB on group (`k` → `get`, `logs`, `restart`) |
| large config — first-word | Same as above but with 600+ command config |
| large config — deep nesting | TAB on 4-level deep command path |
| large config — argument | TAB on argument in deep command |
| large config — 8-level deep | TAB on 8-level deep command path (extreme nesting) |

## Test environment

- Hardware: Framework Desktop
- OS: Linux (Ubuntu)
- bash: `/bin/bash`
- zsh: 5.9 (x86_64-ubuntu-linux-gnu)

## Results (2026-08-06)

| Test | bash | zsh |
|------|------|-----|
| Simple command exec | 44ms | 55ms |
| Hierarchical command exec | 47ms | 64ms |
| First-word completion | 53ms | 59ms |
| Second-word completion | 58ms | 61ms |
| Argument list completion | 64ms | 59ms |
| Hierarchical completion | 54ms | 60ms |
| Large config — first-word | 74ms | 61ms |
| Large config — deep nesting | 85ms | 71ms |
| Large config — argument | 98ms | 78ms |
| Large config — 8-level deep | 87ms | 66ms |

All results are within the "good" threshold (<100ms) for simple configs.
Large config results are within the "OK" threshold (<200ms).

zsh is now faster than bash for all large config benchmarks after removing the
expensive help-text lookup (`_awk output=help` + `grep | cut` per word) from
`_cli_getfirstwords` and `_cli_complete_command`.

## Results (2026-08-09)

After performance optimizations (subshell elimination, AWK fork reduction,
bash-native env extraction, combined completion_init, permission check caching).

| Test | bash | zsh |
|------|------|-----|
| Simple command exec | 57ms | — |
| Hierarchical command exec | 65ms | — |
| First-word completion | 81ms | — |
| Second-word completion | 76ms | — |
| Argument list completion | 82ms | — |
| Hierarchical completion | 79ms | — |
| Large config — first-word | 118ms | — |
| Large config — deep nesting | 145ms | — |
| Large config — argument | 143ms | — |
| Large config — 8-level deep | 128ms | — |

Simple config results are in the "very good" zone (<100ms).
Large config results are in the "good" zone (<200ms).

### Why benchmarks are slower despite optimizations

The optimizations are real — AWK forks dropped from 4 to 2 on first TAB, and
subshells were eliminated. But two subsequent changes added overhead that
outweighs the gains:

1. **File permission checks** (`bdd79e9`): Every AWK call and every `source`
   now runs `_cli_check_file_permissions`, which calls `stat`, `readlink`, and
   `id` to verify the config file is not world-writable and is owned by the
   current user or root. This adds 3-4 external process forks per completion.

2. **Removed function/env caching** (`dc55ae7`): Functions and the `[env]`
   section depend on external state (shell variables, files, commands) that can
   change between invocations without modifying the config file. Caching them
   by mtime was incorrect — it caused stale completions. The fix: always
   re-read the function list from AWK on every completion, adding back one
   AWK fork that the optimizations had eliminated.

Net effect: the optimizations reduced AWK forks from 4→2, but correctness and
security added ~4 external tool calls back. The benchmarks reflect this trade-off.

## AWK call count per TAB press

| Call | output= | Before | After |
|------|---------|--------|-------|
| 1 | `env` | AWK fork | **bash inline** (no fork) |
| 2 | `command_structure` | AWK fork | combined into `completion_init` |
| 3 | `commands` (no filter) | AWK fork | AWK fork (mtime cached) |
| 4 | `command_word_functions` | AWK fork | combined into `completion_init` |
| **First TAB total** | | **4 forks** | **2 forks** |
| **Subsequent TAB** | | **1 fork** (env) | **0 forks** |

## Large config generator

`generate_large_config.sh` produces a 1200-line config with 600+ commands,
deep nesting, many arguments, and lots of comments. Used for stress-testing
the parser and completion under load.
