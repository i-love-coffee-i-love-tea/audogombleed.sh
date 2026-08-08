# ADR-005: Safe mode with layered security toggles

Author: i-love-coffee-i-love-tea
Status: Superseded by [008](008-remove-safe-mode-toggles.md)

## Context

The config file is shell code. The `[env]` section is sourced, command
expressions are passed to `eval`, and `&function`/`:arg:eval:` entries
call user-defined functions. This is powerful but risky if the config
file is not fully trusted (e.g. shared configs, CI environments, copied
from the internet).

## Decision

Provide a layered security model: one master toggle and four per-feature
toggles, all settable in `[env]` or as environment variables.

| Toggle | Default | Blocks |
|--------|---------|--------|
| `SAFE_MODE` | `n` | All dynamic code execution (master switch) |
| `ALLOW_ENV_CODE` | `y` | Multi-line/complex `[env]` entries (simple `VAR=value` always works via `printf -v`) |
| `ALLOW_CMD_SHELL_SYNTAX` | `y` | Pipes, redirects, chaining in command expressions |
| `ALLOW_CMD_WORD_EXPANSION` | `y` | `&function` command words during completion |
| `ALLOW_ARG_EXPANSION` | `y` | `:arg:eval:function` argument types during completion |

## Rationale

### Safe execution path

When `ALLOW_CMD_SHELL_SYNTAX=n` (or safe mode is on), command
expressions without shell metacharacters are tokenized and executed via
`exec` — no `eval`. The tokenizer parses quotes and whitespace, appends
user arguments as separate tokens, and calls the command directly.

Commands with pipes, redirects, or chaining fall back to `eval` — but
`ALLOW_CMD_SHELL_SYNTAX=n` blocks these entirely.

### Simple assignments always work

`VAR=value` and `export VAR=value` in `[env]` are processed via
`printf -v`, not `eval`. They work regardless of `ALLOW_ENV_CODE`
because they cannot execute arbitrary code. Only multi-line or complex
entries require shell evaluation.

### Per-feature, not all-or-nothing

`SAFE_MODE` blocks everything. But a user may want to allow `source`
directives while blocking `&function` expansion, or allow function
expansion while blocking shell syntax in commands. The per-feature
toggles allow this.

## Consequences

- Default configuration is permissive (everything allowed) — backwards
  compatible with existing configs.
- `SAFE_MODE=y` is the strictest setting and suitable for untrusted
  configs or CI environments.
- The toggles are checked at runtime, not at config parse time. A config
  that defines `&function` entries will not error on load — the functions
  are simply not called during completion.

## Changes

- 2026-08-08: i-love-coffee-i-love-tea - initial draft
- 2026-08-08: i-love-coffee-i-love-tea - accepted
- 2026-08-08: i-love-coffee-i-love-tea - superseded by [008](008-remove-safe-mode-toggles.md)
