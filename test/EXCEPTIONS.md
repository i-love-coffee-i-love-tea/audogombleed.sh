# Test Exceptions Registry

This file documents every known platform/shell exception in the test suite.
When a test intentionally deviates from the standard pattern, it must be
documented here with a reference comment at the exception site.

**Purpose:** Prevent future unification passes from accidentally removing
platform-specific workarounds.

**Format:**
```
### EX-NNN: Short title
- **What:** What the exception is
- **Why:** Root cause (shell bug, OS limitation, etc.)
- **Affected:** Which shells/OSes/files
- **Workaround:** How the test handles it
- **Reference:** Link to issue, commit, or documentation
```

**Usage in test files:**
```bash
# EXCEPTION: EX-NNN — <short description>
# See test/EXCEPTIONS.md#ex-nnn
<exceptional code>
```

---

### EX-001: zsh glob filter broken (variable treated as literal)
- **What:** `[[ "$name" == $glob ]]` doesn't do glob expansion in zsh. The variable is treated as a literal string.
- **Why:** zsh's `[[ ]]` doesn't expand glob patterns stored in variables. `[[ "$name" == *.txt ]]` works (literal pattern in syntax), but `[[ "$name" == $glob ]]` where `glob="*.txt"` does NOT match.
- **Affected:** zsh only. Bash expands the variable as a glob.
- **Workaround:** Use `[[ "$name" == ${~glob} ]]` (tilde flag forces glob expansion). Tests that rely on glob filtering skip zsh with `skip "zsh glob filter limitation"`.
- **Files:** `test/completion/001-argument-type-completion-zsh.bats`
- **Reference:** Script bug at audogombleed.sh:2721

### EX-002: zsh `_values` cannot be called outside completion widget
- **What:** Completion types relying on `_values` (int_range, ENVVAR, SSH_HOST, glob FILE/DIR filters) cannot be tested outside a real zsh widget.
- **Why:** zsh's `_values` function requires a completion widget context. Running it in a subshell or direct call fails.
- **Affected:** zsh only.
- **Workaround:** Use `test_completion_zsh` helper which suppresses `_values` with `_values() { :; }` for unit testing.
- **Files:** `test/_helpers/auto-completion-mock-setup-zsh.bash`
- **Reference:** zsh completion system documentation

### EX-003: zsh CURRENT is 1-based vs bash COMP_CWORD is 0-based
- **What:** `test_completion_zsh 2 "testcli" "cmd"` completes the COMMAND name (word position 2). `test_completion 2 "testcli" "cmd"` completes the first ARGUMENT (index 2, past the 0-indexed command).
- **Why:** Different completion systems use different indexing.
- **Affected:** All zsh completion tests.
- **Workaround:** For zsh argument completion: `test_completion_zsh 3 "testcli" "cmd" ""` (CURRENT=3, empty word at position 3).
- **Files:** All `-zsh.bats` completion tests

### EX-004: zsh `[description]` suffixes in completion output
- **What:** zsh completions include `[description]` suffixes (e.g., `option1[one of the following]`).
- **Why:** zsh's completion system appends descriptions to completion candidates.
- **Affected:** zsh only.
- **Workaround:** Use `assert_line --partial` rather than exact `assert_line` for completion assertions.
- **Files:** All `-zsh.bats` completion tests

### EX-005: zsh `[ "" -eq "0" ]` returns true
- **What:** `[ "" -eq "0" ]` returns true in zsh, false in bash. Empty string is treated as 0 in zsh's arithmetic comparison.
- **Why:** zsh arithmetic treats empty string as 0.
- **Affected:** zsh only.
- **Workaround:** Check `[ -n "$1" ]` before arithmetic comparison. Fixed in `_cli_is_integer`.
- **Files:** `derakht.sh` (script fix, not test)

### EX-006: `source ./testcli` before `run ./testcli` is a no-op
- **What:** `source ./testcli` before `run ./testcli` in bats tests has no effect on the subprocess.
- **Why:** `run` starts a subprocess; the script's main entry handles execution. The prior `source` in the parent shell has no effect.
- **Affected:** All shells.
- **Workaround:** Don't add `source ./testcli` before `run ./testcli`. Only use `source` when calling internal functions directly (`run _cli_check_file_permissions`).
- **Files:** Previously in many files, now cleaned up.

### EX-007: zsh `$0` returns function name, not script path
- **What:** `$0` inside a zsh function returns the function name, not the script path. When sourcing via `zsh -c 'source ./script.sh'`, `$0` is `zsh`.
- **Why:** zsh's `$0` behavior differs from bash.
- **Affected:** zsh only.
- **Workaround:** No reliable way to get the original source file path from inside a sourced zsh function. Use `CLI_SCRIPT_UNDER_TEST` env var instead.
- **Files:** `test/_helpers/test-setup.bash`

### EX-008: `read -ra` is bash-only
- **What:** `read -ra args <<< "$expanded_args"` is bash-only syntax. zsh doesn't support `read -a`.
- **Why:** zsh's `read` builtin has different flags.
- **Affected:** zsh only.
- **Workaround:** With bash compat (`bashcompinit`), this may work in zsh. Abbreviation expansion uses this for re-splitting expanded args.
- **Files:** `derakht.sh:2996`

### EX-009: zsh word-splitting differs from bash
- **What:** zsh doesn't word-split unquoted variables (`echo $var` passes whole string as one arg).
- **Why:** zsh's default behavior is no word splitting.
- **Affected:** zsh only.
- **Workaround:** Use `${(z)var}` for shell-word splitting or explicit array construction.
- **Files:** Various in `derakht.sh`

### EX-010: fish shell uses different syntax for variables
- **What:** fish uses `set -g var value` instead of `var=value`. fish output uses `set -g __CMD "value"` syntax with 1-based array indices.
- **Why:** fish is not POSIX-compatible.
- **Affected:** fish only.
- **Workaround:** Separate fish implementation in `derakht.fish`. Tests use `_fish_run` and `_fish_eval` helpers.
- **Files:** `derakht.fish`, `test/_helpers/fish-helpers.bash`

### EX-011: `__CLI_CFG_EXEC_SILENT="n"` includes execution trace
- **What:** Tests asserting exact output must use `assert_output --partial` when trace line may be present.
- **Why:** The execution trace is appended to output when not silent.
- **Affected:** All shells.
- **Workaround:** Use `assert_output --partial` instead of `assert_output` for exact match.
- **Files:** `test/security/002-injection-zsh.bats:135`

### EX-012: Bats parallel execution corrupts shared fixtures
- **What:** Bats test files share `~/.testcli.conf` and `./testcli` symlink. Parallel bats runs corrupt shared fixtures.
- **Why:** Shared filesystem state.
- **Affected:** All shells.
- **Workaround:** Sequential execution only. Each test that overwrites `~/.testcli.conf` should have a `teardown()` that restores `example.conf` and the symlink.
- **Files:** All test files

### EX-013: BATS `--filter-tags` doesn't work with cross-directory globs
- **What:** `bats test/*/*.bats --filter-tags ...` concatenates files causing duplicate `setup_file()` syntax errors.
- **Why:** BATS 1.11.0 bug/limitation.
- **Affected:** All shells.
- **Workaround:** Use per-directory paths: `bats --filter-tags category:execution test/execution/`.
- **Files:** N/A (CLI usage)

### EX-014: macOS BWK awk vs gawk differences
- **What:** macOS ships BWK awk at `/usr/bin/awk` which has different behavior from gawk.
- **Why:** Different awk implementations.
- **Affected:** macOS only.
- **Workaround:** AWK POSIX compatibility tests (`003-awk-posix-compat-all.bats`) verify behavior across gawk, mawk, and nawk.
- **Files:** `test/config/003-awk-posix-compat-all.bats`

### EX-015: Stray files in project root cause glob failures
- **What:** A file named `-e` caused `-?` glob expansion in help tests.
- **Why:** Shell glob expansion matches unexpected files.
- **Affected:** All shells.
- **Workaround:** Always check for stray files when tests fail with unexpected glob symptoms.
- **Files:** N/A (environment issue)

### EX-016: fish tests have known failures (bash syntax incompatibility)
- **What:** ~221 fish tests fail because `./testcli` (bash script) has syntax that fish doesn't support.
- **Why:** fish is not POSIX-compatible. The `./testcli` symlink points to `derakht.sh` (bash script).
- **Affected:** fish only.
- **Workaround:** Fish tests should use `_fish_run` (which runs `fish ./testcli`) or `derakht.fish` directly. Many fish tests still use `run ./testcli` which fails.
- **Files:** Various `-fish.bats` files in security/, execution/, config/
- **Status:** Known issue, not blocking. Fish-specific tests that use `_fish_run` work correctly.

### EX-017: AWK POSIX compat tests used ./testcli without setup
- **What:** Tests 4 ("non-$-prefixed arg value is NOT escaped") and 45 ("output=commands with no filter returns all commands") used `./testcli` but the test file's `setup()` doesn't create the testcli symlink.
- **Why:** The test file loads bats-support/bats-assert directly (not via `_common_setup`) to test the AWK parser in isolation. Two tests accidentally used `./testcli` instead of `_run_awk_with`.
- **Affected:** All shells (tests run under all awk implementations).
- **Workaround:** Fixed by using `_run_awk_with /usr/bin/awk` instead of `./testcli`, consistent with the rest of the file.
- **Files:** `test/config/003-awk-posix-compat-all.bats`
