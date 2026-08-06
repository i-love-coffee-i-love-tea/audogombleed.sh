# TODO: New Test Cases for audogombleed.sh

- [x] **T1** Fix README documentation bug: `:arg:DIRECTORY` → `:arg:DIR`
- [x] **T2** Create `test/argument-types.bats` — test `:FILE`, `:DIR`, `:value:` types
- [x] **T3** Create `test/config-options.bats` — test `-b`, `ALWAYS_RETURN_0`, `PRINT_HELP_ON_INCOMPLETE_ARGS`, `ARGS_ALLOW_COMPLETION_RESULTS_ONLY` (subprocess mode tests added)
- [x] **T4** Create `test/exit-codes.bats` — test exit codes 49, 51, 52, 53
- [x] **T5** Create `test/help-triggers.bats` — test `?`, `-h`, `-?`, `\?` triggers
- [x] **T6** Create `test/include-config.bats` — test `include_commands_from` feature
- [x] **T7** Create `test/multiple-clis.bats` — test variable namespace isolation
- [x] **T8** Run full test suite, verify no regressions

# TODO: Safer Execution Mode

- [x] Add `CFG_EXEC_SUBPROCESS` config option to `audogombleed.sh`
- [x] Modify `_cli_execute_command()` to use `bash -c` when subprocess mode is active
- [x] Store env script in `__CLI_ENV_SCRIPT` for subprocess use
- [x] Update README.md config options table
- [x] Update docs/02-configuration.md
- [x] Update example.conf
- [x] Add subprocess mode tests to test/config-options.bats
- [x] Run full test suite, verify no regressions

# TODO: Bug Fixes (from robustness audit)

- [ ] **B1** Fix trap for noglob — `set +o noglob` not reached if `eval` calls `exit` (line 2172). Use trap to restore.
- [ ] **B2** Add `wait` for background FIFO writers before cleanup (line 1496) — race condition leaks temp dir.
- [ ] **B3** Add `-r` flag to all `read` calls — missing `-r` eats backslashes from config content.
- [ ] **B4** Quote array expansions — `for file in ${include_files[@]}` and `cat ... ${include_fifos[@]}` break on spaces.
- [ ] **B5** Fix array slicing phantom element — `args=("${args[@]:1:${#args[@]}-1}")` produces `("")` instead of `()` for single-element arrays.
- [ ] **B6** Replace `grep -P` with `grep -E` in SSH_HOST completion (line 2426) — PCRE unavailable on macOS.

# TODO: DX Improvements (from product-design audit)

- [ ] **D1** Add comparison table to README vs alternatives (`compgen`, `complete`, Cobra, Click, fzf-based completers)
- [ ] **D2** Include alias (`alias mycli='_cli_execute'`) in the default Getting Started flow, not as an advanced option — without it, `cd`/`export` commands silently run in a subprocess
- [ ] **D3** Add human-readable error messages alongside exit codes 49-53 (e.g. "No unambiguous match for 'x'. Did you mean 'xyz'?")
