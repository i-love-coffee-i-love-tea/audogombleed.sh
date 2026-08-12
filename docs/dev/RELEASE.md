# Release Process

This document describes how to release a new version of derakht-cli.


## Overview

The release has two phases:

1. **Validate** — run `release.sh` in CI to stamp the version, lint, test,
   and build packages for all platforms. Nothing is tagged or published.
2. **Release** — push the tag. CI builds packages again and creates the
   GitHub release with all artifacts attached.

This split exists because package builds (`.deb`, `.rpm`, `.pkg.tar.zst`,
FreeBSD `.pkg`, Homebrew formula) can only be fully tested in CI across
multiple OS containers. If a build fails, you want to know before the tag
exists — not after.


## Step-by-step

### 1. Prepare the release

Make sure `CHANGELOG.md` has a section for the new version:

    ## 2.3.0
    - Added fish shell support
    - Fixed abbreviation expansion in batch mode

The section heading must match `## <version>` exactly — CI extracts
release notes from it.

### 2. Validate in CI

Trigger the validation workflow from the GitHub Actions tab or via `gh`:

    gh workflow run validate-release.yml -f version=2.3.0

This runs the full `release.d` pipeline (version stamps, linting, tests)
and then builds packages for all platforms:

| Platform | Format | Runner |
|----------|--------|--------|
| Debian/Ubuntu | `.deb` | ubuntu-latest |
| Fedora | `.rpm` | fedora container |
| Arch Linux | `.pkg.tar.zst` | archlinux container |
| FreeBSD | `.pkg` | FreeBSD VM |
| macOS | Homebrew formula | macos-latest |

Each build also installs the package and runs the test suite against
the installed binary.

**If the workflow fails:** fix the issue locally, commit, and re-trigger.
Nothing was tagged or published.

**If the workflow passes:** proceed to the next step.

### 3. Stamp, commit, and tag locally

    ./release.sh 2.3.0

This runs every `release.d/*.sh` hook in order:

| Hook | What it does |
|------|--------------|
| `10-validate-release-artifacts.sh` | Checks packaging files exist |
| `12-validate-adr-format.sh` | Validates ADR format |
| `14-validate-config.sh` | Validates dev.conf, example.conf, and all test configs against the grammar |
| `20-stamp-version-in-script.sh` | Writes version into `derakht.sh` |
| `20-stamp-version-in-fish-script.sh` | Writes version into `derakht.fish` |
| `21-stamp-version-in-manpage.sh` | Writes version into `derakht.1` |
| `25-stamp-changelog.sh` | Updates `CHANGELOG.md` |
| `28-embed-awk-scripts.sh` | Embeds AWK scripts from `lib/` |
| `30-lint-embedded-awk-script.sh` | Lints the embedded AWK with `awk --lint` |
| `31-lint-derakht.sh-with-shellcheck.sh` | Lints `derakht.sh` with shellcheck |
| `32-lint-derakht.fish-with-fish-indent.sh` | Lints `derakht.fish` with fish_indent |
| `40-generate-debian-changelog.sh` | Generates `debian/changelog` |
| `60-stamp-version-in-aur-pkgbuild.sh` | Stamps version in AUR PKGBUILD |
| `61-stamp-version-in-rpm-spec.sh` | Stamps version in RPM spec |
| `62-stamp-version-in-gentoo-ebuild.sh` | Stamps version in Gentoo ebuild |
| `63-stamp-version-in-nix-expression.sh` | Stamps version in Nix expression |
| `64-stamp-version-in-homebrew-formula.sh` | Stamps version in Homebrew formula |
| `70-build-deb.sh` | Builds a `.deb` package |
| `80-run-tests.sh` | Runs the test suite |
| `90-commit-release.sh` | Commits all stamped files |
| `91-create-tag.sh` | Creates the `v2.3.0` tag |

### 4. Push

    git push && git push --tags

Pushing the tag triggers the release workflow (`.github/workflows/release.yml`),
which builds all packages again and creates the GitHub release with artifacts
and release notes from `CHANGELOG.md`.

### 5. Publish to package repositories

See `docs/PUBLISHING.md` for per-ecosystem instructions (Debian, Nix,
AUR, Homebrew, RPM/COPR, Gentoo).


## Dev commands

    dev lint             # shellcheck on derakht.sh
    dev lint fish        # fish_indent --check on derakht.fish
    dev format fish      # auto-fix fish_indent formatting


## What if the tag push fails CI?

If the release workflow fails after you pushed the tag:

    git tag -d v2.3.0                    # delete local tag
    git push origin :refs/tags/v2.3.0    # delete remote tag
    # fix, commit, re-trigger validation
    gh workflow run validate-release.yml -f version=2.3.0
    # when green:
    ./release.sh 2.3.0
    git push && git push --tags

This is the fallback, not the expected path. The validation workflow
exists to catch these failures before the tag is pushed.


## Key files

| File | Purpose |
|------|---------|
| `release.sh` | Runs all `release.d/*.sh` hooks |
| `release.d/*.sh` | Individual release steps (numbered for order) |
| `CHANGELOG.md` | Release notes (CI extracts the matching section) |
| `.github/workflows/validate-release.yml` | Pre-tag validation (workflow_dispatch) |
| `.github/workflows/release.yml` | Post-tag release (v* tag trigger) |
| `create-github-release.sh` | Manual GitHub release creation (optional) |
