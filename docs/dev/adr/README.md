# Architecture Decision Records

ADRs 001–010 predate the current format and are not linted. Starting from
ADR-011, all ADRs follow the [MADR spec](https://adr.github.io/madr/)
(Markdown Architectural Decision Records, by Olaf Zimmermann). This means:

* YAML front matter with `status` and `date` (and optionally `decision-makers`,
  `consulted`, `informed`)
* Title as `# Short title` — no `ADR-NNN:` prefix
* Required sections: `## Context and Problem Statement`, `## Decision Outcome`
* Decision Outcome must include a `because` justification
* `### Consequences` must use `Good, because` / `Bad, because` / `Neutral, because`
* `## Pros and Cons of the Options` with per-option Good/Bad/Neutral breakdown

The release hook [`release.d/13-validate-madr.sh`](../../../release.d/13-validate-madr.sh)
lints all ADRs numbered > 10 against these rules. It runs as part of
`release.sh`.

| ADR | Title | Summary |
|-----|-------|---------|
| [001](001-reload-config-on-every-invocation.md) | Reload config on every invocation | `[env]` and `&function` run on every Tab press; only the AWK-parsed command list is cached (by mtime) |
| [002](002-embed-awk-parser.md) | Embed AWK parser in the script | Single file, no dependencies beyond bash and awk, manually copyable |
| [003](003-awk-to-shell-metadata.md) | AWK-to-shell metadata via eval'd assignments | Completion metadata passed as shell associative arrays, eval'd from AWK stdout |
| [004](004-symlink-as-name.md) | CLI name derived from symlink filename | One script, many CLIs — name comes from the symlink, each gets its own config |
| [005](005-safe-mode-toggles.md) | Safe mode with layered security toggles | Master toggle + per-feature toggles for env code, shell syntax, function/arg expansion |
| [006](006-config-file-structure.md) | Config file structure | Indentation-based command tree, `[env]` + `[commands]` sections, one file for completion + help + execution |
| [007](007-safety-toggles-shell-env-only.md) | Safety toggles are shell-environment-only | Toggles moved out of config file into shell env vars; config cannot set them |
| [008](008-remove-safe-mode-toggles.md) | Remove safe mode toggles | Toggles removed from main; code preserved in `security-toggles` branch for future whitelist integration |
| [009](009-cli-name-whitelist.md) | CLI-name whitelist + lockdown toggles | Whitelist restricts which program can be invoked; completes the security model |
| [010](010-scoped-function-loading.md) | Scoped &function loading | Only `&function` entries relevant to the matched command are called during completion; significantly reduces external command invocations |
| [011](011-formalize-config-grammar.md) | Formalize config file grammar | Standalone grammar spec in `docs/config-grammar.md`; embedded validator via `--cli-validate-config` |
| [012](012-ci-code-coverage-with-kcov.md) | CI: Code coverage with kcov | kcov instruments bash via debugger trap; AWK/subshell/eval paths are partially invisible; report is useful for trends and dead code, not absolute percentages |
| [013](013-awk-shell-split.md) | AWK/shell split: parsing in AWK, matching in shell | AWK parses config; shell matches and dispatches because `eval` args, system types, and `&function` expansion require shell |
| [014](014-cross-shell-config-compatibility.md) | Cross-shell config file compatibility | Restrictions for configs that must work in bash, zsh, AND fish; `[env.fish]` section for fish-specific code |
