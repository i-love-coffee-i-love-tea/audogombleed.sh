# Publishing to Package Repositories

This document covers the steps to publish derakht-cli to Debian, Nix (nixpkgs),
the Arch User Repository (AUR), Homebrew, and Fedora COPR.

## Prerequisites (all ecosystems)

- A signed release tag: `git tag -s v2.0.0`
- A GitHub release with a source tarball at the tag
- The packaging files in `packaging/` and `debian/` are kept up to date with
  the current version

---

## 1. Debian (ITP process)

### Overview

New packages enter Debian through the **Intent to Package (ITP)** process. You
file a bug, upload to mentors.debian.net, and a Debian Developer (DD) sponsors
your upload into the archive.

### Steps

#### 1.1 File an ITP bug

Send an email to `submit@bugs.debian.org`:

```
Subject: ITP: derakht-cli -- Create CLIs with auto-completion, abbreviation and built-in help from config

Package: wnpp
Severity: wishlist
Owner: Steffen Kremsler <debian@gobuki.org>

* Package name    : derakht-cli
  Version         : 2.0.0
  Upstream Author : Steffen Kremsler
* URL             : https://github.com/i-love-coffee-i-love-tea/derakht-cli
* License         : BSD-2-Clause
  Programming Lang: Shell (bash/zsh)
  Description     : Create CLIs with auto-completion, abbreviation and built-in help from config

 Derakht generates shell CLIs from a plain text config file.
 Define commands and arguments declaratively — tab completion,
 command abbreviation, help output, and execution all come for free.
 .
 Works in both bash and zsh. No dependencies beyond awk and the shell.
 .
 Help and documentation features:
  * Auto-generated help from config file comments
  * Context-sensitive help: 'mycli ?' shows all commands, 'mycli deploy ?'
    shows help for the deploy subtree
  * Command-level, section-level, and global help text via comments
  * Shows required vs optional arguments and argument types in help output
  * Displays shortest unambiguous abbreviation for each command
 .
 Other features:
  * Tab completion for commands and arguments
  * Command abbreviation (shortest unambiguous prefix)
  * Argument types: FILE, DIR, STRING, INTEGER, list, eval, and more
  * Hierarchical config with include_commands_from
  * Dynamic command words from variables, functions, or static lists
  * Batch mode (-b/--batch) for scripted/non-interactive usage
```

You will receive a bug number (e.g. `#1100000`) within seconds.

#### 1.2 Update `debian/changelog`

Replace `NNNNNN` with your ITP bug number:

```
derakht-cli (2.0.0) unstable; urgency=medium

  * Initial release. (Closes: #NNNNNN)

 -- Steffen Kremsler <debian@gobuki.org>  Sun, 09 Aug 2026 13:34:53 +0200
```

#### 1.3 Build and lint

```bash
dpkg-buildpackage -us -uc
lintian ../derakht-cli_2.0.0_amd64.changes
```

Fix any errors lintian reports. Warnings are usually acceptable for a first
upload.

#### 1.4 Upload to mentors

```bash
dput mentors ../derakht-cli_2.0.0_source.changes
```

This uploads to https://mentors.debian.net/ where DDs can find it.

#### 1.5 Request sponsorship

Email `debian-mentors@lists.debian.org`:

```
Subject: Sponsor needed for derakht-cli (ITP #NNNNNN)

Hi,

I've uploaded derakht-cli to mentors.debian.net:
https://mentors.debian.net/package/derakht-cli

It's a shell-based CLI framework that generates auto-completable command
trees from plain text config files. License is BSD-2-Clause.

Lintian is clean (or: has only the following acceptable warnings: ...).

ITP bug: https://bugs.debian.org/NNNNNN

Thanks for reviewing!
```

#### 1.6 Ongoing maintenance

Once accepted, subsequent uploads go through `debian-mentors` or directly if you
become a Debian Maintainer (DM) or Debian Developer (DD):
- DM application: https://nm.debian.org/
- You need an existing DD to advocate for you
- The process takes weeks to months

### Files

| File | Purpose |
|------|---------|
| `debian/control` | Package metadata, dependencies, description |
| `debian/changelog` | Version history (must reference ITP bug) |
| `debian/copyright` | License and copyright (DEP-5 format) |
| `debian/rules` | Build instructions |
| `debian/source/format` | Source format (`3.0 (native)`) |

---

## 2. Nix (nixpkgs)

### Overview

Nix packages are submitted as pull requests to the
[nixpkgs](https://github.com/NixOS/nixpkgs) repository. You write a Nix
expression, test it locally, and open a PR.

### Steps

#### 2.1 Install nix

```bash
sh <(curl -L https://nixos.org/nix/install) --daemon
```

#### 2.2 Fork and clone nixpkgs

```bash
git clone https://github.com/NixOS/nixpkgs.git
cd nixpkgs
git checkout -b derakht-cli
```

#### 2.3 Create the package expression

Copy `packaging/nix/default.nix` into the nixpkgs tree:

```bash
mkdir -p pkgs/by-name/de/derakht-cli
cp /path/to/derakht.sh/packaging/nix/default.nix pkgs/by-name/de/derakht-cli/package.nix
```

Note: nixpkgs uses `package.nix` as the filename, not `default.nix`.

#### 2.4 Get the source hash

```bash
nix-prefetch-url --unpack https://github.com/i-love-coffee-i-love-tea/derakht-cli/archive/refs/tags/v2.0.0.tar.gz
```

Or use `lib.fakeSha256` temporarily and let nix tell you the correct hash on
first build. Update the `sha256` field in `package.nix`.

#### 2.5 Test locally

```bash
nix-build -A derakht-cli
./result/bin/derakht --version
```

#### 2.6 Run nixpkgs linters

```bash
nix-shell -p nixpkgs-lint --run "nixpkgs-lint pkgs/by-name/de/derakht-cli"
nix-shell -p nixpkgs-review --run "nixpkgs-review pr HEAD"
```

#### 2.7 Open a pull request

```bash
git add pkgs/by-name/de/derakht-cli/
git commit -m "derakht-cli: init at 2.0.0"
git push origin derakht-cli
```

Open a PR at https://github.com/NixOS/nixpkgs/compare. Use the title:
`derakht-cli: init at 2.0.0`.

A nixpkgs committer will review and merge.

#### 2.8 After merge

The package appears in `nixpkgs-unstable` within days and in the next NixOS
release. Users install with:

```bash
nix-env -iA nixpkgs.derakht-cli
# or in a flake:
nix profile install nixpkgs#derakht-cli
```

### Files

| File | Purpose |
|------|---------|
| `packaging/nix/default.nix` | Package expression (source, build, metadata) |

---

## 3. Arch User Repository (AUR)

### Overview

The AUR is a community repository for Arch Linux. You upload a `PKGBUILD` file
and users build the package themselves. No review or approval process — it's
immediate.

### Steps

#### 3.1 Create an AUR account

Register at https://aur.archlinux.org/ and add your SSH public key.

#### 3.2 Generate a real sha256sum

```bash
curl -sL https://github.com/i-love-coffee-i-love-tea/derakht-cli/archive/refs/tags/v2.0.0.tar.gz | sha256sum
```

Update `sha256sums` in `packaging/arch/PKGBUILD` with the real hash (replace
`SKIP`).

#### 3.3 Clone the AUR repo

```bash
git clone ssh://aur@aur.archlinux.org/derakht-cli.git
cd derakht-cli
```

#### 3.4 Copy the PKGBUILD

```bash
cp /path/to/derakht.sh/packaging/arch/PKGBUILD .
```

#### 3.5 Test the build

```bash
makepkg -si
# or to just build without installing:
makepkg -s
```

Verify the package works:
```bash
derakht --version
man derakht
```

#### 3.6 Generate .SRCINFO

```bash
makepkg --printsrcinfo > .SRCINFO
```

#### 3.7 Push to AUR

```bash
git add PKGBUILD .SRCINFO
git commit -m "derakht-cli 2.0.0"
git push
```

The package is immediately available at https://aur.archlinux.org/packages/derakht.

Users install with:

```bash
git clone https://aur.archlinux.org/derakht-cli.git
cd derakht-cli
makepkg -si
```

Or with an AUR helper like `yay`:

```bash
yay -S derakht-cli
```

#### 3.8 Updating

For new versions:

1. Update `pkgver` in `PKGBUILD`
2. Reset `pkgrel` to `1`
3. Regenerate `sha256sums` with `updpkgsums` (from `pacman-contrib`)
4. Regenerate `.SRCINFO`: `makepkg --printsrcinfo > .SRCINFO`
5. Commit and push

### Files

| File | Purpose |
|------|---------|
| `packaging/arch/PKGBUILD` | Build recipe, metadata, source URL |
| `.SRCINFO` (generated) | Machine-readable metadata for the AUR web interface |

---

## 4. Homebrew (tap)

### Overview

Homebrew packages live in a "tap" — a GitHub repository named
`homebrew-<name>` under your account. Users add the tap and install
the formula. The formula is a Ruby file that describes how to fetch,
build, and install the package.

### Steps

#### 4.1 Create the tap repository

Create a GitHub repo named `homebrew-derakht-cli` under your account:

```bash
gh repo create i-love-coffee-i-love-tea/homebrew-derakht-cli --public
```

The repo needs a `Formula/` directory containing the Ruby formula file.

#### 4.2 Update the formula with a real checksum

```bash
sha=$(curl -sL https://github.com/i-love-coffee-i-love-tea/derakht-cli/archive/refs/tags/v2.1.0.tar.gz | shasum -a 256 | cut -d' ' -f1)
```

Update `sha256` in `packaging/homebrew/derakht-cli.rb` with the real hash.

#### 4.3 Push the formula to the tap repo

```bash
git clone git@github.com:i-love-coffee-i-love-tea/homebrew-derakht-cli.git
cd homebrew-derakht-cli
mkdir -p Formula
cp /path/to/derakht.sh/packaging/homebrew/derakht-cli.rb Formula/
git add . && git commit -m "derakht-cli 2.1.0" && git push
```

#### 4.4 Test locally

```bash
brew tap i-love-coffee-i-love-tea/derakht-cli
brew install i-love-coffee-i-love-tea/derakht-cli/derakht-cli
derakht --version
```

#### 4.5 Update for new versions

1. Update `url` and `sha256` in the formula
2. Push to the tap repo
3. Users update with `brew upgrade derakht`

### Files

| File | Purpose |
|------|---------|
| `packaging/homebrew/derakht-cli.rb` | Formula: source URL, checksum, install steps, test |

---

## 5. RPM (Fedora COPR)

### Overview

Fedora COPR is a build system for third-party RPM packages. You upload
a spec file, COPR builds it for multiple Fedora/EPEL releases, and
users enable the repo to install with `dnf`.

### Steps

#### 5.1 Create a COPR account

Register at https://copr.fedorainfracloud.org/ and link your GitHub or
FAS account.

#### 5.2 Create a new project

In COPR, create a project named `derakht`:
- Chroots: `fedora-rawhide-x86_64`, `fedora-40-x86_64`, `epel-9-x86_64`
- Mark as "persistent" so it survives past the default 14-day cleanup

#### 5.3 Build from the spec file

Option A — point COPR at the GitHub tarball:
1. Upload `packaging/rpm/derakht.spec` as a new build
2. Source URL: `https://github.com/i-love-coffee-i-love-tea/derakht-cli/archive/refs/tags/v2.1.0.tar.gz`

Option B — use `copr-cli`:
```bash
copr-cli build derakht --nowait \
  https://github.com/i-love-coffee-i-love-tea/derakht-cli/archive/refs/tags/v2.1.0.tar.gz
```

#### 5.4 Test

```bash
# Enable the COPR repo
dnf install 'dnf-command(copr)'
dnf copr enable $USER/derakht-cli
dnf install derakht-cli
derakht --version
```

#### 5.5 Update for new versions

1. Update `Version:` in `packaging/rpm/derakht.spec`
2. Add a `%changelog` entry
3. Rebuild in COPR

### Files

| File | Purpose |
|------|---------|
| `packaging/rpm/derakht.spec` | RPM spec: metadata, source URL, install steps |

---

## Version bump checklist

When releasing a new version, update all packaging files:

1. `debian/changelog` — add a new entry at the top
2. `packaging/nix/default.nix` — update `version` and `sha256`
3. `packaging/arch/PKGBUILD` — update `pkgver` and `sha256sums`
4. `packaging/homebrew/derakht-cli.rb` — update `url` and `sha256`
5. `packaging/rpm/derakht.spec` — update `Version:` and add `%changelog` entry

The `release.d/` hooks handle steps 1-5 automatically during `release.sh`.

Then follow the update steps for each ecosystem.
