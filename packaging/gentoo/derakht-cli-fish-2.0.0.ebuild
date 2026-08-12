# Copyright 1999-2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

DESCRIPTION="Fish shell support for derakht-cli"
HOMEPAGE="https://github.com/i-love-coffee-i-love-tea/derakht-cli"
SRC_URI="https://github.com/i-love-coffee-i-love-tea/derakht-cli/archive/refs/tags/v${PV}.tar.gz -> derakht-cli-${PV}.tar.gz"
S="${WORKDIR}/derakht-cli-${PV}"

LICENSE="BSD-2"
SLOT="0"
KEYWORDS="~amd64 ~arm64 ~x86"

RDEPEND="
	app-shells/fish
	sys-apps/gawk
"

src_install() {
	newbin derakht.fish derakht-fish
	doman derakht.1
}
