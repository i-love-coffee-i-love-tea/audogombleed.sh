# Contributing

Contributions are welcome — bug fixes, features, questions, or just poking
around. No CLA, no special status. Jump in.


## Setup

The script is one file. You need bash (or fish) and awk.

```bash
git clone --recurse-submodules https://github.com/i-love-coffee-i-love-tea/derakht-cli
cd derakht.sh
ln -sf derakht.sh dev && source ./dev
```

This gives you a development CLI — `dev ?` to see available commands.
Forgot `--recurse-submodules`?

```bash
git submodule update --init --recursive
```


## Running the tests

558 tests, every bash test mirrored in zsh and fish, covering completion,
execution, security, edge cases, and benchmarks.

```bash
dev test all       # everything
dev test bash      # just bash
dev test zsh       # just zsh
dev test fish      # just fish
dev test file auto-completion-bash   # one file
dev test bench     # performance
```

CI runs against bash 4.2.53 through 5.3, macOS, FreeBSD, and WSL. To test
a specific bash version locally:

```bash
dev test compat 5.2.37
```


## Linting

```bash
dev lint           # shellcheck on the main script
dev awk export     # pull the embedded AWK script into a file
dev awk lint       # lint it
```

Shellcheck also runs as part of `release.sh`, but run it locally too.


## Project layout

```
derakht.sh      the bash/zsh script (~4K lines, one file, by design)
derakht.fish    the fish script
derakht.1       manpage
dev.conf        the project's own dev CLI (real-world config example)
example.conf    test fixture (CI smoke test + parser compatibility tests)
release.sh      release orchestrator
release.d/      hooks that fire on release
test/           test files — every bash test has zsh and fish twins
test/bats/      bats-core (submodule)
docs/           user documentation
docs/dev/       architecture, ADRs, benchmarks
packaging/      Arch, Homebrew, Nix, RPM — all CI-verified
debian/         Debian packaging
```

The single file per shell is what makes it usable everywhere — copy it,
symlink it, source it. No installation required. The ADRs explain the reasoning.


## Architecture

`docs/dev/README.md` covers how the AWK parser works, how a Tab keypress
flows to `COMPREPLY`, how commands get executed, and where the performance
bottlenecks are.

There are 12 ADRs in `docs/dev/adr/`. Starting from ADR-011, they follow
the [MADR spec](https://adr.github.io/madr/). If your change touches
something an ADR covers, read it first. If you disagree, write a new ADR.


## Making a contribution

1. Fork the repo, branch from `main`.
2. Keep it focused — one thing per commit.
3. **Write tests.** New features need `*-bash.bats`, `*-zsh.bats`, and
   `*-fish.bats`. Bug fixes need a regression test. Existing test files
   are good templates.
4. `dev test all` — everything green.
5. `dev lint` — no warnings.
6. Update docs if behavior changed.
7. Open a PR.


## Coding conventions

**Shell.** 4-space indent. Functions are `_cli_*`, variables are `__CLI_*`.
Quote your expansions. Prefer `printf -v` over `eval`.

**AWK.** POSIX-compatible only — no `gensub`, no `PROCINFO`, no gawk
extensions. The embedded AWK has to run on BWK (macOS), mawk, and gawk.
Use `dev awk export` to work on it standalone, then embed it back.

**Portability.** Linux (bash, zsh, fish), macOS (bash 3.2, zsh, fish),
FreeBSD, WSL. CI covers all four.

**Performance.** Tab completion runs on every keypress. Every subshell costs
10-20ms. If you touch the completion path, measure before and after with
`dev test bench`.


## Updating bats

```bash
git -C test/bats fetch --tags && git -C test/bats checkout <tag>
git -C test/test_helper/bats-support fetch --tags && git -C test/test_helper/bats-support checkout <tag>
git -C test/test_helper/bats-assert fetch --tags && git -C test/test_helper/bats-assert checkout <tag>
git add test/bats test/test_helper/bats-support test/test_helper/bats-assert
git commit -m "test: update bats submodules"
```

Verify with `test/bats/bin/bats test/smoke-test.bats` after.


## Code coverage

[kcov](https://github.com/SimonKagstrom/kcov) tracks test coverage. AWK,
subshells, and eval are partially invisible, so don't chase the percentage.
It's useful for finding dead code. See
`docs/dev/adr/012-ci-code-coverage-with-kcov.md`.

```bash
dev coverage open   # run tests with coverage, open HTML report
dev coverage clean  # clean up
```


## Releases

`release.sh` runs hooks: validate configs, shellcheck, stamp version across
package formats, build .deb, run tests, commit, and tag.

See `docs/PUBLISHING.md` for the full workflow.


## Bug reports

Open an issue with your OS, shell, and shell version. A minimal config that
reproduces the issue helps.


## Security

The tool gets sourced into your shell and uses `eval` to run config content.
That's by design — see `docs/SECURITY.md` for the tradeoffs. If you've found
a vulnerability, open an issue with the `security` label.


## Where to start

Look for issues labeled `good first issue` or `help wanted`.
`docs/dev/README.md` is the best entry point. Questions welcome as issues.
