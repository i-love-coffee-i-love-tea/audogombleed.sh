# ADR-006: Config file structure

Author: i-love-coffee-i-love-tea
Status: Accepted

## Context

The tool needs a config file format that:

- Defines a command tree (hierarchy of command words)
- Maps commands to shell expressions
- Declares argument types and completion sources
- Supports dynamic expansion (variables, functions, static lists)
- Is readable and writable by humans without tooling

The format must be parseable by an embedded AWK script with no external
dependencies.

## Decision

The config file has two sections, separated by headers:

### `[env]` section

Shell code that runs in the current session on every completion and
execution. Used for variable assignments, `source` directives, function
definitions, and `include_commands_from` declarations.

Simple `VAR=value` assignments are processed via `printf -v` (no eval).
Multi-line or complex entries require shell evaluation (gated by
`ALLOW_ENV_CODE`).

### `[commands]` section

An indentation-based tree. Indentation level defines the hierarchy.
There are three node types:

**Command groups** — a word on its own line, no colon:

```
deploy
    staging
    production
```

**Commands** — a word followed by `:` and a shell expression:

```
deploy staging: ./deploy.sh staging
```

**Arguments** — lines starting with `:`, defining completion metadata:

```
:arg_name:TYPE
:arg_name:TYPE:value
:arg_name:TYPE:value:description
```

Types: `STRING`, `INTEGER`, `int_range`, `list`, `eval`, `FILE`, `DIR`,
`ENVVAR`, `USER`, `GROUP`, `SSH_HOST`, `BLKDEV`, `SERVICE`.

An optional `?` suffix makes an argument optional.

### Dynamic expansion

The last word of a command group can be dynamic:

- `$VARIABLE` — expands from a shell variable
- `&function` — expands from a shell function's output
- `val1|val2|val3` — expands from a static list

### Help text

Lines starting with `#` are help text. Attached to the next command or
group. `##` lines are detail text shown in command-specific help.

## Rationale

### Indentation-based, not a table

The tree structure maps naturally to indentation. A flat table (e.g.
CSV) would require encoding the hierarchy in the command name itself
(`deploy.staging`), losing the visual structure and making deep trees
hard to read.

### AWK-parseable

The format is line-oriented with a small set of syntactic markers (`:`,
`$`, `&`, `|`, `#`). The AWK parser tracks indentation level, detects
the node type from the line content, and builds the command tree in a
single pass. No backtracking, no multi-line constructs, no quoting rules
beyond what the shell already handles.

### One file, four features

A single config file provides tab completion, command abbreviation, help
output, and command execution. No separate completion scripts, help
files, or alias definitions.

### Arguments are positional

Arguments are defined in order and referenced by position (`\0`, `\1`,
`\2`) in the command expression. This keeps the mapping between config
and execution explicit — the user sees exactly which argument goes where.

## Consequences

- The config file is the single source of truth for the CLI's behavior.
- Editing the config and pressing Tab immediately reflects the change
  (see ADR-001).
- The AWK parser must handle the full format in a single pass — it
  cannot resolve references across sections or files.
- The indentation-based format is sensitive to inconsistent whitespace.
  Tabs and spaces must not be mixed (enforced by the tab check in
  `release.sh`).

## Changes

- 2026-08-08: i-love-coffee-i-love-tea - initial draft
- 2026-08-08: i-love-coffee-i-love-tea - accepted
- 2026-08-08: i-love-coffee-i-love-tea - already implemented
