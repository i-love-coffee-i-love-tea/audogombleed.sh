# Contributing

Hey — you're thinking about contributing. That's genuinely exciting. This
project started as one person's itch and grew into something other people
actually use. Every contribution makes it better, and glad you're here.

There's no special status, no CLA, no gatekeeping. If you've got an idea, a
bug fix, a question, or just want to poke around — jump in.


## Getting your feet wet

The setup is almost comically simple. The script is one file — you can literally
copy it and it works. There's packaging for Arch, Debian, Homebrew, Nix, RPM,
and Gentoo (not distributed yet), but you don't need any of that to use it or
contribute. You need bash, awk, and that's about it.

```bash
git clone --recurse-submodules https://github.com/i-love-coffee-i-love-tea/derakht-cli
cd derakht.sh
ln -sf derakht.sh dev && source ./dev
```

That last line is worth pausing on — you just sourced the project to get a
development CLI. Type `dev ?` and tab-complete your way around. The project
is its own dev tool. It's a nice feeling.

Forgot `--recurse-submodules`? Everyone does it:

```bash
git submodule update --init --recursive
```


## Running the tests

The test suite is something to be proud of — 558 tests, every bash test
mirrored in zsh, covering completion, execution, security, edge cases, and
benchmarks. It's fast, it's thorough, and it'll catch your mistakes before
anyone else does.

```bash
dev test all       # the whole thing
dev test bash      # just bash
dev test zsh       # just zsh
dev test file auto-completion-bash   # one file
dev test bench     # performance — aim for under 100ms
```

CI runs this against bash 4.2.53 through 5.3, macOS, FreeBSD, and WSL. To
test a specific bash version locally (it builds from source, which is kind
of fun to watch):

```bash
dev test compat 5.2.37
```


## Linting

```bash
dev lint           # shellcheck on the main script
dev awk export     # pull the embedded AWK script into a file you can edit
dev awk lint       # lint it
```

Shellcheck catches real bugs. Run it early, run it often. It also runs as
part of the release process (`release.sh`) — but that's a local manual
process, so don't wait for it.


## How the project is laid out

```
derakht.sh      the script — ~4K lines, one file, by design
derakht.1       manpage
example.conf         example config (doubles as a CI smoke test)
dev.conf             the project's own dev CLI — dogfood!
release.sh           release orchestrator
release.d/           19 hooks that fire on release
test/                73 test files — every bash test has a zsh twin
test/bats/           bats-core (submodule)
docs/                user documentation
docs/dev/            architecture, ADRs, benchmarks
packaging/           Arch, Gentoo, Homebrew, Nix, RPM — all CI-verified
debian/              Debian packaging
```

The single file is what makes it usable everywhere — you can copy it, symlink
it, source it, and it just works. No installation required. There's packaging
for when you want it, but the script doesn't depend on being installed. That's
by design — the ADRs explain the reasoning if you're curious.


## Before you start writing code

`docs/dev/README.md` is the architecture guide, and it's actually enjoyable
to read. It walks through how the AWK parser works, how a Tab keypress flows
all the way to `COMPREPLY`, how commands get executed, where the performance
bottlenecks hide, and why everything is named the way it is. You'll have a
lot of "oh, *that's* how that works" moments.

There are 12 ADRs in `docs/dev/adr/` — short documents explaining the
reasoning behind every major decision. ADRs 001–010 predate the current format.
Starting from ADR-011, all ADRs follow the
[MADR spec](https://adr.github.io/madr/) (Markdown Architectural Decision
Records, by Olaf Zimmermann) — YAML front matter, Context and Problem
Statement, Decision Drivers, Considered Options with Pros and Cons, Decision
Outcome with Consequences and Confirmation, and More Information. If your
change touches something an ADR covers, read it first. If you disagree with
the ADR, that's fine — write a new one explaining your thinking. That's
exactly how the project evolves.


## Making your first contribution

1. Fork the repo, branch from `main`.
2. Make your change. Keep it focused — one thing per commit.
3. **Write tests.** This is the big one. New features need both a `*-bash.bats`
   and a `*-zsh.bats` file — the test suite mirrors everything. Bug fixes
   need a regression test. The existing test files are great templates — pick
   one that's close to what you need and adapt it.
4. `dev test all` — everything green.
5. `dev lint` — no warnings.
6. Update docs if the behavior changed. `CHANGELOG.md` for the notable stuff,
   `docs/` for user docs, `docs/dev/` for internals, `derakht.1` if the
   manpage needs it.
7. Open a PR. Don't worry about making it perfect — it'll get sorted.


## Coding conventions

**Shell.** 4-space indent. Functions are `_cli_*`, variables are `__CLI_*`.
Quote your expansions. Prefer `printf -v` over `eval` — the script has been
hardened against injection over many iterations, and every `eval` is a
potential regression.

**AWK.** POSIX-compatible only — no `gensub`, no `PROCINFO`, no gawk
extensions. The embedded AWK has to run on BWK (macOS), mawk, and gawk.
Use `dev awk export` to get it into a standalone file while you're working
on it, then embed it back when it's ready.

**Portability.** Linux (bash + zsh), macOS (bash 3.2 at `/bin/bash` for
sourcing, zsh as primary), FreeBSD, and WSL. CI covers all four — if it
passes there, you're in good shape.

**Performance.** Tab completion runs on every single keypress. Every subshell
costs 10-20ms. Every fork adds startup overhead. If you're touching the
completion path, measure before and after. `dev test bench` will tell you
if you regressed.


## Updating bats

The test framework is vendored as submodules. To bump it:

```bash
git -C test/bats fetch --tags && git -C test/bats checkout <tag>
git -C test/test_helper/bats-support fetch --tags && git -C test/test_helper/bats-support checkout <tag>
git -C test/test_helper/bats-assert fetch --tags && git -C test/test_helper/bats-assert checkout <tag>

git add test/bats test/test_helper/bats-support test/test_helper/bats-assert
git commit -m "test: update bats submodules"
```

Verify with `test/bats/bin/bats test/smoke-test.bats` after.


## Code coverage

[kcov](https://github.com/SimonKagstrom/kcov) tracks which lines the tests
exercise. It has real limitations — AWK, subshells, and eval are
partially invisible — so don't chase the percentage. But it's great for
finding dead code and seeing trends over time. The full story is in
`docs/dev/adr/012-ci-code-coverage-with-kcov.md`.

```bash
dev coverage open   # run tests with coverage, open the HTML report
dev coverage clean  # clean up
```

CI generates a downloadable HTML report on every push to `main` and on PRs.


## Releases

`release.sh` runs 19 hooks: validate configs, shellcheck, stamp the version
across 6 package formats, build the .deb, run the full test suite, commit,
and tag. It's thorough because releases should be boring.

See `docs/PUBLISHING.md` for the full workflow and how to push to Debian,
Nix, and AUR.


## Found a bug?

Open an issue. Include your OS, shell, and shell version. If you can include
a minimal config that reproduces it, that's the fastest path to a fix — the
example config in the repo is a good starting point.


## Security

The tool gets sourced into your shell and uses `eval` to run config content.
That's by design, and `docs/SECURITY.md` is honest about the tradeoffs. If
you've found a vulnerability, open an issue with the `security` label or
contact the author directly.


## Not sure where to start?

Look for issues labeled `good first issue` or `help wanted`. Or just browse
the code — `docs/dev/README.md` is the best entry point. If you have
questions, open an issue. There are no dumb questions, and happy to help
you find your way around.
