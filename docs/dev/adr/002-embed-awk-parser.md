# ADR-002: Embed the AWK config parser in the script

Author: i-love-coffee-i-love-tea
Status: Accepted

## Context

The config file parser is an AWK script (~1000 lines) that interprets
the `[commands]` section, expands dynamic command words, formats help
output, and produces shell variable assignments for completion. It is
embedded in the main bash script as a heredoc inside
`_cli_read_awk_script()`.

The alternative is to ship the AWK script as a separate file.

## Decision

Embed the AWK script in the bash script. The tool is a single component
with no dependencies beyond what is available on every Unix system (bash
and awk), so a user can manually copy it to any machine and use it.

## Rationale

### Single file

The tool is one file. The user copies it, creates a symlink, writes a
config file. No directory structure, no path resolution, no risk of the
AWK script going missing. If it were external, the user would need to
place both files in the same directory or install the AWK script to a
known location — both break the "copy one file" workflow.

### POSIX AWK compatibility

The AWK script is written in POSIX awk — no gensub, no PROCINFO, no
gawk extensions. It works with gawk, mawk, and nawk. This is verified
by CI tests (`test/awk-posix-compat-all.bats`) that run the parser
against all three implementations and compare output.

Embedding the script makes this guarantee easier to enforce: there is
only one copy, it is always the version that ships with the script, and
there is no risk of the user having a stale or modified copy of the AWK
file.

### Runtime caching

The AWK script is read once into a shell variable (`__CLI_AWK_SCRIPT`)
and reused for all subsequent invocations within the same shell session.
This is effectively a one-time parse of a constant string — no file I/O
after the first completion.

## Tradeoff: maintainability

The main cost is maintainability. 1000 lines of AWK inside a bash
heredoc are harder to edit, lint, and test than a standalone file:

- Editors may not recognize the heredoc content as AWK, losing syntax
  highlighting and indentation support.
- AWK linters cannot lint a heredoc inline — the script must be
  extracted first.
- Unit testing the AWK parser requires extracting it from the shell
  script.

## Mitigations

The tool provides CLI flags to work around these limitations:

- `--cli-print-awk-script`: prints the embedded AWK script to stdout.
  This allows piping it to linters, editors, or test harnesses.
- `--cli-run-awk-command`: runs the AWK script with arbitrary arguments,
  enabling direct testing of the parser logic.
- `--cli-print-env`: runs the `[env]` extraction mode, useful for
  debugging config parsing in isolation.

The development CLI (`dev.conf`) wraps these for convenience:

```
dev awk export   — exports the AWK script to cli.awk
dev awk lint     — runs awk --lint on the exported script
dev awk run ...  — runs the AWK script with specific arguments
dev awk diff     — diffs exported vs embedded (to detect drift)
```

The test suite (`test/awk-posix-compat-all.bats`) exports the script and
runs it against gawk, mawk, and nawk, comparing output for equivalence.
This catches portability issues that would be invisible if the script
were only tested against one AWK implementation.

## Alternatives considered

### Ship as a separate file

Solves the maintainability problem but breaks the single-file promise.
Requires path resolution logic, complicates installation, and introduces
the risk of version mismatch between the shell script and the AWK file.

### Ship as a separate file with fallback

Embed the AWK script in the shell but also ship an external file; prefer
the external file if found. Adds complexity for marginal benefit — if
the user has the external file, they can just use `awk -f` directly.

### Generate the AWK from a template

Use a build step to inline the AWK script into the shell script from a
separate source file. Adds a build dependency, requires a Makefile or
build script, and means the checked-in shell script is not the source of
truth. The `--cli-print-awk-script` flag already provides the export
direction; going the other way (separate file → inline) is not worth the
build complexity.

## Consequences

- The tool is a single file with no installation step beyond a symlink.
- The AWK script is always the correct version for the shell script it
  ships with — no version skew possible.
- AWK development requires exporting the script first (`--cli-print-awk-script`
  or `dev awk export`).
- POSIX compatibility is enforced by CI tests against multiple AWK
  implementations.
- The `dev awk diff` command catches cases where someone edits the
  exported file but forgets to update the embedded copy (or vice versa).

## Changes

- 2026-08-08: i-love-coffee-i-love-tea - initial draft
- 2026-08-08: i-love-coffee-i-love-tea - accepted
- 2026-08-08: i-love-coffee-i-love-tea - already implemented
