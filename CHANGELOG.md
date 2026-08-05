# Changelog

## 1.2.1

- Restructure test suite for dual bash/zsh coverage (257 tests, up from 121)
- Add zsh counterparts for every test file (21 bash + 21 zsh test files)
- Add CI job for zsh test suite
- Remove `CFG_EXEC_SUBPROCESS` option — redundant with the existing alias mode (`alias mycli='_cli_execute'`)
- Fix `include_commands_from` under zsh (word splitting via `SH_WORD_SPLIT`)
- Fix wrong variable name `__CLI_CFG_SILENT` in batch mode docs
- Document `&` prefix for function expansion of command words
- Add shell compatibility doc (execution model, bash/zsh differences)
- Add command-word expansion tests for `&function` (14 tests, bash + zsh)
- Unskip zsh include-config tests (5 tests)
- Fix hierarchical commands example in getting-started doc
- Document `source` as the way to externalize `[env]` configuration

## 1.2.0

- Add full zsh compatibility: config loading, completion, command execution
- Add zsh completion descriptions: commands show help text and arguments show type descriptions in zsh `_values` format
- Rewrite embedded AWK script to be POSIX compatible (no gensub, no PROCINFO) — now works with gawk, mawk, and nawk
- Add manpage (`audogombleed.1`)
- Add argument type completion tests for FILE, DIR, STRING, INTEGER, int_range, ENVVAR, USER, GROUP, SSH_HOST, BLKDEV, SERVICE
- Add zsh test suite (`test/zsh.bats`, `test/zsh-completion-descriptions.bats`)
- Add zsh test helpers (`test/zsh-helpers.bash`, `test/common-setup-zsh.bash`)
- Add `release.sh` script for version bump and tagging

## 1.1.1

- Replace eval with printf -v for config variable assignments (eliminates code injection risk)
- Replace eval echo with parameter expansion for source/include paths
- Add noglob around eval and bash -c execution to prevent glob expansion
- Quote $@ and ${args[@]} to prevent word splitting and injection
- Use mktemp -d for FIFO temp directory (fixes race condition with mktemp -u)
- Use mktemp for log file creation with chmod 600 (prevents predictable tmpfile collisions)
- Add cleanup trap for temp directory removal
- Validate __CLI_ variable names against safe character set `[A-Za-z_][A-Za-z0-9_]*`
- Add -r to read in yes/no prompt to prevent backslash interpretation

## 1.1

- Add `CFG_EXEC_SUBPROCESS` option to run commands in a `bash -c` subprocess instead of `eval` in the current shell
- Add bash version compatibility testing workflow (bash 4.2.53 through 5.3)
- Fix variable expansion bug in commands affecting auto-completion
- Fix default `exit_code` not being set in certain cases
- Fix exit code handling for codes 49-53
- Apply shell hardening (quoting, variable handling, robustness)
- Improve help formatting for long commands with single help text lines
- Restructure documentation into getting-started, configuration, advanced-command-configurations, hierarchical-configuration, and faq guides
- Replace docker/cd examples with kubectl/terraform workflows in docs and README to better reflect real-world deployment use cases
- Document alias usage in getting-started guide
- Add CFG_EXEC_SUBPROCESS tradeoff matrix and side-effects table to docs
- Add Use Cases section to docs
- Update CI to Node.js 24, add manual workflow trigger
- Add 73 new tests (argument types, exit codes, help triggers, include-config, multiple CLIs, subprocess config, auto-completion, abbreviated commands, cmdline options, help output, AWK config parser)
- Add shared test infrastructure (common-setup, common-teardown, auto-completion-mock-setup)
- Rename `test.bats` to `test/command-definitions.bats`
- Change license to Simplified BSD
- Move dev docs into `docs/dev/`, add ROADMAP.md and TODO.md
- Update `.gitignore`

## 1.0

- Initial release
- CLI framework with auto-completable hierarchical command trees
- Configuration file system with [commands] and [env] sections
- Tab completion for commands and arguments
- Variable and function support in command expressions
- Built-in help system with '?' and '-h' triggers
- Abbreviated command expansion (unambiguous shortcuts)
- Exit status codes 49-53 for different error conditions
- Zsh support via bashcompinit
- Batch mode (-b/--batch) for script usage
- AWK-based config parser
- Bats test framework setup
