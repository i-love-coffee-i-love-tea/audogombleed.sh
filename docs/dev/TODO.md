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

# TODO: DX Improvements (from product-design audit)

- [ ] **D1** Add comparison table to README vs alternatives (`compgen`, `complete`, Cobra, Click, fzf-based completers)
- [ ] **D2** Write `install.sh` — handles symlink, `.bashrc`/`.zshrc` injection (source + alias), zsh `bashcompinit` setup
- [ ] **D3** Include alias (`alias mycli='_cli_execute'`) in the default Getting Started flow, not as an advanced option — without it, `cd`/`export` commands silently run in a subprocess
- [ ] **D4** Add human-readable error messages alongside exit codes 49-53 (e.g. "No unambiguous match for 'x'. Did you mean 'xyz'?")
