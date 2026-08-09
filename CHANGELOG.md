# Changelog

## 2.1.0

### Features

- Add release.d hook system: 19 hooks for validation, linting, version stamping, testing, and tagging (`release.sh` orchestrates the pipeline)
- Add formal config grammar specification (`docs/config-grammar.md`) with embedded validator accessible via `--cli-validate-config`
- Add code coverage workflow with kcov (CI artifact report + local `coverage.sh` script)
- Add ADR-011 (config grammar) and ADR-012 (code coverage) in MADR format (ADR-011+ follow the [MADR spec](https://adr.github.io/madr/))
- Add Homebrew formula, RPM spec, Gentoo ebuild, Nix expression packaging with CI verification
- Add Arch Linux PKGBUILD with CI build verification
- Add WSL test job (Ubuntu 24.04 under Windows)
- Add contributing guide (`docs/CONTRIBUTING.md`)

### CI

- Add test jobs for WSL (bash + zsh)
- Add package build jobs for Arch, Homebrew, RPM, Gentoo, Nix
- Restructure job names with `test:` and `pkg:` prefixes
- Use GNU mirror and curl retry for bash source downloads
- Raise WSL benchmark thresholds (400ms exec, 400ms completion, 600ms large)

### Fixes

- Fix shellcheck warnings and errors in `audogombleed.sh`: resolve all findings (real bugs, style issues, and suppressions with explanations)
- Fix `$args` array truncation in `_cli_execute_command()` — multi-arg abbreviation expansion was only passing the first argument
- Fix `args="$expanded_args"` reassignment that corrupted the args array by leaking old elements
- Fix `arg_list` array/string type confusion in `_cli_complete_arg()` that broke list argument completion
- Fix `$expanded_arg` and `$COMPREPLY` array-without-index issues
- Fix `ls | grep` patterns replaced with portable globs
- Fix `trap` to defer variable expansion to signal time
- Make release hooks 90 (commit) and 91 (tag) idempotent — re-running `release.sh` is now safe
- Fix AWK heredoc anchors: use unique markers (`MAIN_AWK_EOF`, `VALIDATOR_AWK_EOF`) to prevent validator script from leaking into the main parser during sed extraction
- Fix RPM tarball layout, Homebrew tap setup, Gentoo ebuild validation, Arch tarball layout
- Fix WSL path conversion, CRLF handling, and script encoding

### Documentation

- Add badge row to README (tests, coverage, shellcheck, license, release, stars, bash, zsh)
- Add contributing guide with setup, testing, coding conventions, and MADR ADR reference
- Document conventional commit message format in contributing guide
- Convert ADR-011 and ADR-012 to MADR format (YAML front matter, Pros and Cons sections)
- Add MADR convention documentation to ADR README with lint script reference
- Update packaging files documentation

## 2.0.0

### Features

- Add FreeBSD support: platform detection, BSD `stat` syntax, portable shebang (`#!/usr/bin/env bash`), and `:arg:SERVICE` completion using `rc.d` scripts
- Add help system enhancements: global header (`#` lines at top of `[commands]`), section headings, standalone command help, `##` detail comments
- Add argument description syntax (`:name:type:description` and `:name:type:value:description`), shown as `[description]` suffixes in zsh completions at all nesting levels
- Add file permission checks before sourcing config, source, and include files (rejects world-writable files, files owned by other users, and symlinks to unsafe targets)
- Add CLI name validation (only letters, digits, and underscores allowed)
- Add config caching (mtime-based, skips re-parsing unchanged config files)
- Add scoped `&function` loading — only `&function` entries relevant to the matched command are called during completion, instead of all `&function` entries
- Add macOS support (portable file modification time)
- Add `.deb` packaging (`build-deb.sh`, `debian/` directory)
- Add `release.sh` for version bump (updates `audogombleed.sh`, `audogombleed.1`, `debian/changelog`), commit, and tagging
- Remove `CFG_EXEC_SUBPROCESS` option — redundant with the existing alias mode (`alias mycli='_cli_execute'`)

### Performance

- Eliminate subprocess forks and duplicate AWK calls in the completion path
- Reduce external tool calls and subshells in hot paths
- Optimize completion execution time across all command levels

### Fixes

- Fix exit codes 52 and 53 (placeholder mismatch and missing required args now work correctly)
- Fix eval quoting bug in completion
- Fix `include_commands_from` under zsh (word splitting via `SH_WORD_SPLIT`)
- Fix tilde-in-quotes bug in test setup
- Fix macOS portability: `stat`, `mktemp`, `sed -i`, `awk` (BWK vs gawk), and benchmark timing (`date +%s%N`)
- Fix FreeBSD portability: `stat` syntax, shebang, and pipe/regex detection in zsh completion
- Fix argument completion when preceding file argument has spaces in filename
- Optimize exit 53 check (pure bash, no sed/grep)
- Optimize zsh deep nesting completion

### Documentation

- Rewrite manpage: add installation, security, shell compatibility, and troubleshooting sections
- Add security documentation (trust model, `eval` implications, file permission checks, recommendations)
- Add shell compatibility documentation (execution model, OS support including FreeBSD, known limitations)
- Document argument description syntax in configuration reference and getting started guide
- Document `&` prefix for function expansion of command words
- Document `source` as the way to externalize `[env]` configuration
- Add execution modes and multiple CLI sections to getting started guide
- Expand hierarchical configuration docs with error handling

### Tests

- Restructure test suite for dual bash/zsh coverage (358+ tests, up from ~120)
- Add zsh counterparts for every test file (21 bash + 21 zsh test files)
- Add CI jobs for zsh, macOS, FreeBSD, Arch Linux, and WSL test suites
- Add macOS CI with Homebrew bash and coreutils
- Add FreeBSD CI job with fdescfs mount and gawk/coreutils
- Add Arch Linux CI job with PKGBUILD build verification
- Add WSL CI job testing under Windows Subsystem for Linux
- Add comprehensive help tests (global header, sections, standalone commands, detail comments)
- Add argument description tests (AWK parser + zsh completion descriptions)
- Add benchmark tests with OS-specific thresholds
- Add exit code 52/53 tests
- Add command-word expansion tests for `&function`
- Add security, error handling, and execution edge case tests
- Add AWK POSIX compatibility tests (gawk, mawk, nawk)
- Add external state and variable/function update completion tests

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
