# Debian Release Workflow

## Prerequisites

    sudo apt-get install build-essential debhelper

For signed packages (distribution), a GPG key matching the maintainer
email in `debian/control`:

    gpg --gen-key

## Building the .deb

For local testing (unsigned):

    ./build-deb.sh

For distribution (signed):

    ./build-deb.sh --sign

The `.deb` is placed in the parent directory:
`../derakht_<version>_all.deb`.

## Full release workflow

    # 1. Bump versions, commit, tag
    ./release.sh 2.0.0

    # 2. Push source and tag
    git push && git push --tags

    # 3. Build signed .deb
    ./build-deb.sh --sign

    # 4. Upload to GitHub Releases
    gh release create v2.0.0 ../derakht_2.0.0_all.deb

## Updating the maintainer email

Edit `debian/control` and set `Maintainer:` to your name and email.
This must match your GPG key for signed packages.

## Installing the .deb

    sudo dpkg -i ../derakht_2.0.0_all.deb

After installation, the script is at `/usr/bin/derakht`.
Create CLI symlinks as usual:

    ln -s /usr/bin/derakht ~/bin/mycli
