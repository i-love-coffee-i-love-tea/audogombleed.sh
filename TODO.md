# TODO: New Test Cases for audogombleed.sh

- [x] **T1** Fix README documentation bug: `:arg:DIRECTORY` → `:arg:DIR`
- [ ] **T2** Create `test/argument-types.bats` — test `:FILE`, `:DIR`, `:value:` types
- [x] **T3** Create `test/config-options.bats` — test `-b`, `ALWAYS_RETURN_0`, `PRINT_HELP_ON_INCOMPLETE_ARGS`, `ARGS_ALLOW_COMPLETION_RESULTS_ONLY` (subprocess mode tests added)
- [ ] **T4** Create `test/exit-codes.bats` — test exit codes 49, 51, 52, 53
- [ ] **T5** Create `test/help-triggers.bats` — test `?`, `-h`, `-?`, `\?` triggers
- [ ] **T6** Create `test/include-config.bats` — test `include_commands_from` feature
- [ ] **T7** Create `test/multiple-clis.bats` — test variable namespace isolation
- [ ] **T8** Run full test suite, verify no regressions

# TODO: Safer Execution Mode

- [x] Add `CFG_EXEC_SUBPROCESS` config option to `audogombleed.sh`
- [x] Modify `_cli_execute_command()` to use `bash -c` when subprocess mode is active
- [x] Store env script in `__CLI_ENV_SCRIPT` for subprocess use
- [x] Update README.md config options table
- [x] Update docs/02-configuration-options.md
- [x] Update example.conf
- [x] Add subprocess mode tests to test/config-options.bats
- [x] Run full test suite, verify no regressions
