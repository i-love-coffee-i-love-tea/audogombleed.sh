---
status: accepted
date: 2026-08-10
---

# AWK/shell split: parsing in AWK, matching and dispatch in shell

## Context and Problem Statement

The execution and completion paths need to match user input against the
parsed command tree and extract metadata (args, expressions). The config
is parsed by an embedded AWK script into a flat array (`__CLI_CONFIG`).
Should matching and dispatch also move into AWK, or stay in shell?

This question arose during a performance investigation. The shell-side
matching functions (`_cli_count_matching_commands`,
`_cli_get_command_expr`, `_cli_get_command_args`, etc.) iterate
`__CLI_CONFIG` with O(N) string comparisons. At 10K commands, this
takes ~460ms per execution. AWK processes the same data in ~20ms
(compiled C pattern matching vs. interpreted shell). The natural
conclusion: move matching into AWK.

## Decision Outcome

Keep the current split: **AWK parses, shell matches and dispatches**,
because AWK cannot satisfy the full feature set without spawning shell
subprocesss — which defeats the purpose.

The back-and-forth between AWK and shell is a **deliberate design
choice**, not an oversight.

## Pros and Cons of the Options

### Option A: AWK does everything

Move progressive prefix matching, arg extraction, expression extraction,
placeholder validation, and default injection into a single AWK pass.

**Good**, because:
- One subprocess instead of N shell loops + 2 AWK calls
- AWK pattern matching is 10-20x faster than shell string comparison
- Estimated 460ms → 50-80ms for execution at 10K commands

**Bad**, because:
- `eval`-type arguments (`:pod:eval:get_pods default`) require calling
  shell functions at completion time. AWK cannot invoke shell functions.
  The shell must pre-expand these and pass results via `ENVIRON[]`.
- System-level argument types (`FILE`, `DIR`, `SERVICE`, `SSH_HOST`,
  `BLKDEV`, `USER`, `GROUP`, `ENVVAR`) require OS calls (glob, lsblk,
  systemctl, /etc/passwd). AWK cannot do these.
- `&function` command words (`&create_cmd_words: echo \0`) require
  calling shell functions before AWK can match. The order of operations
  is: shell calls function → exports result → AWK reads from
  `ENVIRON[]`. AWK cannot trigger the call.
- Scoped `&function` loading (ADR-010) requires knowing which command is
  matched before calling functions. If AWK does matching, it needs
  function results to match — but it can't call functions. Two-phase
  (AWK identifies function → shell calls it → second AWK call) adds a
  spawn, negating the benefit.
- Help formatting (`format_commands`, `format_word_at_position`) is ~150
  lines of O(N²) column-alignment logic already in AWK. Adding matching
  logic to the same script makes it 2-3x larger and harder to maintain.
- The AWK script must remain POSIX-compatible (gawk/mawk/nawk).
  Complex matching logic increases the surface area for portability
  bugs.
- Debugging: shell functions support `_cli_log` at every step. AWK
  matching would need `print` to stderr with no structured logging.

**Neutral**, because:
- The AWK script is already 1200+ lines. More logic means more
  heredoc-in-bash to maintain.

### Option B: Hybrid — AWK matches commands, shell dispatches args

Move only command-word matching (the bottleneck) into AWK. Shell handles
arg-type dispatch.

**Good**, because:
- Command-word scan is the expensive part (~300ms at 10K). Arg dispatch
  is fast (~20ms). AWK handles the bottleneck.
- One AWK call replaces N shell loops for the execution path.

**Bad**, because:
- `eval` args and system types still need shell (same as Option A).
- Two code paths for matching: AWK for execution, shell for completion.
  The completion path still needs shell matching for scoped `&function`
  loading.
- The AWK script grows by ~60 lines of matching logic.

**Neutral**, because:
- Estimated 460ms → ~80ms for execution. Completion path unchanged.

### Option C: Current split (chosen)

AWK parses the config into `__CLI_CONFIG[]`. Shell iterates the array
for matching and dispatches arg types.

**Good**, because:
- `eval` args, system types, and `&function` expansion all work natively
  in shell — no subprocess overhead, no `ENVIRON[]` round-trips.
- Scoped `&function` loading (ADR-010) works naturally: shell matches
  the static prefix, determines which function is needed, calls it, then
  re-matches with expanded data.
- Debugging: `_cli_log` at every step, structured error messages, exit
  codes 50-53 with precise error context.
- The AWK script stays focused on parsing (~1200 lines). Matching logic
  stays in shell (~200 lines). Each is independently testable.
- POSIX AWK compatibility is easier to maintain with simpler AWK code.

**Bad**, because:
- Shell string comparison is 10-20x slower than AWK pattern matching.
- At 10K commands, execution takes ~460ms (vs. ~50ms theoretical with
  AWK matching).
- Multiple scans of `__CLI_CONFIG` per operation (5+ for execution).

**Neutral**, because:
- The 10K-command case is a stress test. Real configs have 20-200
  commands, where shell matching takes 50-80ms — within the "good"
  threshold (<100ms).
- Mtime caching (ADR-001) means the config is parsed once per file
  change. Subsequent operations reuse the cached array.

## Why the split is correct

The feature set requires shell-side capabilities that AWK cannot provide:

1. **`eval` args**: `:pod:eval:get_pods default` — shell must call
   `get_pods` at completion time
2. **System types**: `FILE`, `SERVICE`, etc. — shell must glob, call
   systemctl, read /etc/passwd
3. **`&function` expansion**: shell must call the function before AWK
   can read the result from `ENVIRON[]`
4. **Scoped loading**: shell must determine the matched command before
   knowing which `&function` to call
5. **Confirmation prompts**: shell must interact with the user for
   expanded commands

Moving matching into AWK would require shell to pre-expand all dynamic
state before each AWK call — calling every `&function`, every `eval`
arg, every system-type query. This is more expensive than the current
approach, not less.

The only way to make "AWK does everything" work is to drop `eval` args,
system types, and scoped `&function` loading. These are core features.

### Consequences

- Good, because `eval` args, system types, and `&function` expansion work natively in shell without subprocess round-trips
- Good, because scoped `&function` loading (ADR-010) remains effective — shell matches the static prefix, calls the function, then re-matches
- Good, because each layer (AWK parsing, shell matching) is independently testable
- Neutral, because real-world configs (20-200 commands) perform within "good" thresholds (<100ms) despite shell's interpreted string comparison
- Bad, because performance at 10K commands is bounded by shell's O(N) string comparison (~460ms vs. ~50ms theoretical with AWK matching)
- Neutral, because future performance work should focus on reducing the number of `__CLI_CONFIG` scans per operation, not on changing the matching language

## References

- ADR-001: Reload config on every invocation (mtime caching)
- ADR-002: Embed AWK parser in the script (single-file design)
- ADR-003: AWK-to-shell metadata via eval'd assignments
- ADR-010: Scoped &function loading
- `docs/dev/BENCHMARKS.md`: Performance benchmark history
