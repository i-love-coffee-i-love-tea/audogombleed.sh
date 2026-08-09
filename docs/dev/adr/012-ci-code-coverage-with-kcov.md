---
status: accepted
date: 2026-08-09
decision-makers: i-love-coffee-i-love-tea
---

# CI: Code coverage with kcov

## Context and Problem Statement

The project has 558 behavioral tests (bash + zsh) but no visibility into
which code paths in the 4K-line main script are exercised. Line coverage
data would help find dead code and track test completeness over time.

Bash has no built-in coverage mechanism. The main tool available is
[kcov](https://github.com/SimonKagstrom/kcov), which instruments bash
scripts via `bash --debugger`. It integrates with bats and generates HTML
reports.

The project's execution model involves subshells, eval, process
substitution, and an embedded AWK parser — all of which interact with
kcov's instrumentation in non-trivial ways. The constraints need to be
documented so the coverage data is interpreted correctly.

How to get meaningful coverage data from a bash project that relies
heavily on subshells, eval, and an embedded AWK parser?

## Decision Drivers

* Untested code paths and dead code should be identifiable.
* Coverage data should be available in CI (PR-level) and locally.
* The tool must work with bats and sourced scripts (not just executed
  scripts).
* The coverage report must be interpretable — a misleading percentage
  is worse than no percentage.

## Considered Options

* **kcov** — instruments bash via debugger trap; generates HTML and
  Cobertura reports; works with bats; known subshell limitations.
* **bashcov** — Ruby-based wrapper; less maintained; no bats integration.
* **No coverage tooling** — rely on behavioral test count alone (status
  quo).

## Decision Outcome

Chosen option: **kcov, with documented constraints**, because it is the
only tool that works with bats and can track sourced files, despite its
limitations with subshells and eval.

kcov is used with `--bash-method=DEBUG` and `--bash-parse-files-in-dir`
to track coverage of `audogombleed.sh` when sourced by bats tests. The
HTML report is generated in CI and downloadable as an artifact. A local
`coverage.sh` script provides the same report for developers.

Codecov integration and a coverage badge are NOT added, because the
absolute percentage is not trustworthy (see constraints below).

### What kcov tracks reliably

* Function bodies — `_cli_execute_command`, `_cli_complete_arg`, the
  tokenizer, the completion dispatch (`case` statements), etc.
* Control flow — `if`/`case`/`while` branches in the main script.
* Lines executed directly in the current shell context.

### What kcov does NOT track

* **The embedded AWK script** (~500 lines). AWK runs as a separate
  process. kcov has no visibility into it. The parser is effectively
  invisible to coverage.
* **Subshell invocation sites.** Code inside `$(...)` may not generate
  hit data for the expression itself, even if the function called within
  the subshell is tracked. The wrapper line shows 0 hits; the function
  body may show hits.
* **`eval` of dynamic content.** Line 2818 (`eval $cmd_expr`) falls
  back for shell metacharacters. The eval'd expression is constructed at
  runtime — kcov cannot predict or track the resulting code path.
* **Process substitution sources.** Line 2157 (`source <(_awk ...)`)
  runs `_awk` in a subshell. The `source` itself is tracked; the AWK
  output generation is not.

### Eval sites in the project

| Line | Expression | Path | kcov tracking |
|------|-----------|------|---------------|
| 2860 | `eval "${tokens[@]}"` | Safe tokenized execution (main path) | Likely tracked — just word splitting |
| 2818 | `eval $cmd_expr ${user_args[*]}` | Shell metacharacter fallback | Mixed — depends on eval'd content |
| 3305 | `arg_list=$(eval "$eval_cmd")` | `:arg:eval:function` completion | Poorly tracked — subshell + eval |
| 2157 | `source <(_awk ...)` | AWK output loading | Source tracked; AWK invisible |

### Dead code detection

kcov is useful for dead code detection but not proof. A line at 0 hits
across all tests is a strong signal, but could be a kcov blind spot
(subshell boundary, eval context). Treat 0-hit lines as "investigate
this" rather than "this is dead."

### Constraints

1. **The coverage percentage is a lower bound, not an accurate
   measurement.** Lines that definitely execute may show 0 hits due to
   subshell/eval limitations. No coverage badge — the number would
   mislead.
2. **kcov is bash-only.** The zsh test suite verifies correctness but
   does not contribute coverage data. Since the core logic is shared
   (same script), bash coverage is a reasonable proxy.
3. **The AWK parser is invisible.** If AWK-level coverage matters in
   the future, a separate AWK coverage tool or unit tests against the
   exported AWK script would be needed.
4. **Coverage data is useful for trends, not absolutes.** Going from
  45% to 52% is real progress. Claiming "52% coverage" is not.

### Consequences

* Good, because dead code and obviously untested paths become visible.
* Good, because PR-level coverage diffs show when new code adds uncovered lines.
* Good, because the HTML report is self-contained — no external service needed.
* Neutral, because the absolute percentage is pessimistic. Developers
  must understand why and not chase a number.
* Neutral, because kcov must be built from source in CI (no apt package
  on the runner). This adds ~30s to the coverage job.
* Neutral, because the `coverage/` directory is gitignored; no data
  accumulates in the repo.

### Confirmation

* `./coverage.sh` produces an HTML report with line-by-line hit data.
* The CI coverage workflow runs and uploads the report as an artifact.
* Lines in the tokenizer, completion dispatch, and execution pipeline
  show non-zero hit counts.
* The AWK script and eval fallback lines show 0 or inconsistent hits.

## Pros and Cons of the Options

### kcov

* Good, because it works with bats and can track sourced files.
* Good, because it generates HTML reports and Cobertura XML.
* Good, because it has no runtime dependencies beyond bash and debug symbols.
* Neutral, because it must be built from source on CI runners.
* Bad, because subshells, eval, and AWK are partially invisible.
* Bad, because the absolute percentage is a lower bound, not accurate.

### bashcov

* Good, because it has a simpler API.
* Bad, because it is Ruby-based — adds a runtime dependency.
* Bad, because it has no bats integration.
* Bad, because it is less maintained than kcov.

### No coverage tooling

* Good, because no additional tooling or CI complexity.
* Bad, because dead code and untested paths remain invisible.
* Bad, because there is no way to track test completeness over time.

## More Information

* [kcov documentation](https://github.com/SimonKagstrom/kcov)
* `coverage.sh` — local coverage script
* `.github/workflows/coverage.yml` — CI coverage workflow
* `docs/dev/BENCHMARKS.md` — performance context (coverage adds overhead)
