# Changelog

## Unreleased

## 2.0.0 (2026-08-11)

### Features

- Add fish shell support: config loading, tab completion, and command execution
- Add FreeBSD support: platform detection, BSD `stat` syntax, portable shebang (`#!/usr/bin/env bash`), and `:arg:SERVICE` completion using `rc.d` scripts
- Add macOS support (portable file modification time, `dscl`-based user/group completion)
- Add help system enhancements: global header (`#` lines at top of `[commands]`), section headings, standalone command help, `##` detail comments
- Add argument description syntax (`:name:type:description` and `:name:type:value:description`), shown as `[description]` suffixes in zsh completions at all nesting levels
- Add file permission checks before sourcing config, source, and include files (rejects world-writable files, files owned by other users, and symlinks to unsafe targets)
- Add CLI name validation (only letters, digits, and underscores allowed)
- Add config caching (mtime-based, skips re-parsing unchanged config files)
- Add scoped `&function` loading — only `&function` entries relevant to the matched command are called during completion, instead of all `&function` entries
- Add `FILE_OR_DIR` argument type that completes both files and directories
- Add optional glob filter parameter for `FILE`, `DIR`, and `FILE_OR_DIR` types to restrict completions by pattern (e.g. `*.txt`, `*.log`)
- Unify config syntax so all parameterized types use `:name:type[:value[:description]]`, where `FILE`/`DIR`/`FILE_OR_DIR` treat the value field as a glob pattern
- Add formal config grammar specification (`docs/config-grammar.md`) with embedded validator accessible via `--cli-validate-config`
- Add `.deb` packaging (`build-deb.sh`, `debian/` directory)
- Add Homebrew formula, RPM spec, Gentoo ebuild, Nix expression, and Arch Linux PKGBUILD packaging with CI verification
- Remove `CFG_EXEC_SUBPROCESS` option — redundant with the existing alias mode (`alias mycli='_cli_execute'`)

### Performance

- Eliminate subprocess forks and duplicate AWK calls in the completion path
- Reduce external tool calls and subshells in hot paths
- Optimize completion execution time across all command levels
- Optimize exit 53 check (pure bash, no sed/grep)
- Optimize zsh deep nesting completion

### Fixes

- Fix exit codes 52 and 53 (placeholder mismatch and missing required args now work correctly)
- Fix eval quoting bug in completion
- Fix `include_commands_from` under zsh (word splitting via `SH_WORD_SPLIT`)
- Fix macOS portability: `stat`, `mktemp`, `sed -i`, `awk` (BWK vs gawk), and benchmark timing (`date +%s%N`)
- Fix FreeBSD portability: `stat` syntax, shebang, and pipe/regex detection in zsh completion
- Fix argument completion when preceding file argument has spaces in filename

### Renamed

- Rename project from `audogombleed.sh` to `derakht-cli` — "derakht" (درخت) is Persian for "tree", reflecting the tool's core purpose of generating command trees

### CI

- Add automated release workflow (`release.yml`): builds .deb, .rpm, Arch .pkg.tar.zst, FreeBSD .pkg, and Homebrew formula; runs full bats test suite against each installed binary; creates GitHub Release only if all builds and tests pass
- Add test jobs for zsh, macOS, FreeBSD, Arch Linux, and WSL
- Add package build jobs for Arch, Homebrew, RPM, Gentoo, Nix
- Add dependency caching to all CI workflows (`actions/cache` for apt, Homebrew, kcov)
- Add concurrency control to all CI workflows (`cancel-in-progress: true`)

### Documentation

- Rewrite manpage: add installation, security, shell compatibility, and troubleshooting sections
- Add security documentation (trust model, `eval` implications, file permission checks, recommendations)
- Add shell compatibility documentation (execution model, OS support including FreeBSD, known limitations)
- Add contributing guide (`docs/CONTRIBUTING.md`) with setup, testing, coding conventions, and MADR ADR reference
- Add Homebrew, RPM, and Gentoo publishing guides to `docs/PUBLISHING.md`
- Add ADR-011 (config grammar), ADR-012 (code coverage), ADR-013 (AWK/shell split), and ADR-014 (cross-shell config compatibility)
- Add badge row to README (tests, coverage, shellcheck, license, release, stars, bash, zsh)
- Document argument description syntax, `&` prefix for function expansion, and `source` for externalizing `[env]` configuration

### Tests

- Add fish test suite with comprehensive coverage across all categories
- Restructure test suite for dual bash/zsh coverage (398+ tests, up from ~120)
- Add zsh counterparts for every test file
- Add benchmark tests with OS-specific thresholds
- Add security, error handling, and execution edge case tests
- Add AWK POSIX compatibility tests (gawk, mawk, nawk)
- Add `CLI_UNDER_TEST` env var support — run the full bats test suite against an installed binary
- Reorganize test suite into category subdirectories with numbered files

## 1.2.0

- Add full zsh compatibility: config loading, completion, command execution
- Add zsh completion descriptions: commands show help text and arguments show type descriptions in zsh `_values` format
- Rewrite embedded AWK script to be POSIX compatible (no gensub, no PROCINFO) — now works with gawk, mawk, and nawk
- Add manpage (`derakht.1`)
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
