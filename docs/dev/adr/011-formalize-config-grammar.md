---
status: accepted
date: 2026-08-09
decision-makers: i-love-coffee-i-love-tea
---

# Formalize config file grammar

## Context and Problem Statement

ADR-006 describes the config file structure and the rationale behind it,
but the format is only specified informally — through examples, a table
of argument types, and prose descriptions. The embedded AWK parser is
the de facto spec, but it is not human-readable as a reference.

There is no way to validate a config file without running the tool. A
config with a typo in an argument type or a malformed section header
fails silently at runtime.

How to make the config format precise enough to validate and
reimplement without ambiguity?

## Decision Drivers

* A future parser reimplementation (non-AWK) must have an unambiguous
  reference that does not require reading 1200 lines of AWK.
* Config errors should be caught before runtime.
* ADR-006 already explains *why* the format is designed this way; the
  grammar records *what* it is.

## Considered Options

* Create a standalone grammar specification document
* Embed the grammar in ADR-006
* Leave the format informal (status quo)

## Decision Outcome

Chosen option: **standalone grammar specification document**, because
the grammar needs to be independently referenceable and maintainable.

A formal ABNF-like grammar is created in `docs/config-grammar.md`,
covering the full config format: sections, identifiers, indentation
rules, argument types, dynamic command words, comments, and placeholders.

A validator is embedded in the main script (`_cli_read_validator_script`)
accessible via `--cli-validate-config`. Every derived CLI can validate
its own config without knowing the filename:

    mycli --cli-validate-config            # validates ~/.mycli.conf
    mycli --cli-validate-config other.conf # validates a specific file

The grammar is a living document maintained alongside the AWK parser.
The ADR records the decision; the grammar doc records the spec.

### Consequences

* Good, because any derived CLI can validate its own config.
* Good, because `validate-config.sh` is a thin wrapper — no separate AWK script.
* Good, because the grammar doc can evolve independently of the ADR.
* Neutral, because the grammar must be kept in sync with the AWK parser.
  The release hook `11-validate-example-config.sh` catches drift.

### Confirmation

* `mycli --cli-validate-config` passes on a valid config.
* `validate-config.sh example.conf` passes.
* The grammar doc is reviewed when the AWK parser changes.

## Pros and Cons of the Options

### Create a standalone grammar specification document

* Good, because the grammar is independently referenceable.
* Good, because it can evolve without touching the ADR.
* Neutral, because it must be kept in sync with the AWK parser.

### Embed the grammar in ADR-006

* Good, because design rationale and spec live together.
* Bad, because ADR-006 would grow significantly and mix concerns.
* Bad, because the grammar can't evolve independently.

### Leave the format informal (status quo)

* Good, because no additional work.
* Bad, because ambiguity remains — a future reimplementation must
  reverse-engineer the AWK parser.
* Bad, because config errors fail silently at runtime.

## More Information

* [docs/config-grammar.md](../../config-grammar.md) — the grammar spec
* ADR-006: Config file structure (design rationale)
* docs/02-configuration.md: user-facing config reference
