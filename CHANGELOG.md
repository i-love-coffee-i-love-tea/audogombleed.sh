# Changelog

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
