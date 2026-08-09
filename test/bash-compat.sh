#!/usr/bin/env bash
#
# Build a specific bash version from source and run the BATS test suite against it.
#
# Usage: bash test/bash-compat.sh <version>
# e.g.   bash test/bash-compat.sh 4.2.53
#
# Requires: curl, tar, make, build-essential, libncurses-dev

set -euo pipefail

VERSION="${1:?Usage: bash test/bash-compat.sh <version>}"
TARBALL="bash-${VERSION}.tar.gz"
URL="https://ftpmirror.gnu.org/bash/${TARBALL}"
BUILD_DIR="/tmp/bash-build-${VERSION}"
PREFIX="${BUILD_DIR}/install"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "=== bash ${VERSION} ==="

# Download
if [ ! -f "${BUILD_DIR}/${TARBALL}" ]; then
    mkdir -p "${BUILD_DIR}"
    echo "Downloading ${URL} ..."
    curl --retry 3 --retry-delay 5 --retry-all-errors -fLo "${BUILD_DIR}/${TARBALL}" "${URL}"
fi

# Extract
echo "Extracting ..."
tar xf "${BUILD_DIR}/${TARBALL}" -C "${BUILD_DIR}"

# Build
echo "Building (this may take a minute) ..."
cd "${BUILD_DIR}/bash-${VERSION}"
./configure --prefix="${PREFIX}" --without-bash-malloc > /dev/null 2>&1
make -j"$(nproc)" > /dev/null 2>&1
make install > /dev/null 2>&1

BASH_BIN="${PREFIX}/bin/bash"
if [ ! -x "${BASH_BIN}" ]; then
    echo "FAIL: ${BASH_BIN} not found after install"
    exit 1
fi

echo "Installed: ${BASH_BIN} ($(${BASH_BIN} --version | head -1))"

# Run tests
echo "Running tests ..."
cd "${REPO_DIR}"
set +e
${BASH_BIN} test/bats/bin/bats test/*-bash.bats test/*-all.bats --formatter junit > report.xml
EXIT_CODE=$?
set -e

if [ ${EXIT_CODE} -eq 0 ]; then
    echo "PASS: bash ${VERSION} — all tests passed"
else
    echo "FAIL: bash ${VERSION} — exit code ${EXIT_CODE}"
fi

# Cleanup
echo "Cleaning up build artifacts ..."
rm -rf "${BUILD_DIR}"

exit ${EXIT_CODE}
