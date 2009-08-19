# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/x11-libs/libxcb/libxcb-1.4.ebuild,v 1.2 2009/08/18 16:58:22 ssuominen Exp $

EAPI="2"

# Must be before x-modular eclass is inherited
#SNAPSHOT="yes"

inherit x-modular prefix

DESCRIPTION="X C-language Bindings library"
HOMEPAGE="http://xcb.freedesktop.org/"
SRC_URI="http://xcb.freedesktop.org/dist/${P}.tar.bz2"
LICENSE="X11"

KEYWORDS="~x86-freebsd ~amd64-linux ~x86-linux ~ppc-macos ~x86-macos ~sparc-solaris ~x86-solaris"
IUSE="doc selinux"

RDEPEND="x11-libs/libXau
	x11-libs/libXdmcp
	dev-libs/libpthread-stubs"
DEPEND="${RDEPEND}
	doc? ( app-doc/doxygen )
	dev-libs/libxslt
	>=x11-proto/xcb-proto-1.5
	>=dev-lang/python-2.5[xml]"

pkg_setup() {
	CONFIGURE_OPTIONS="$(use_enable doc build-docs)
		$(use_enable selinux)
		--enable-xinput"
}

src_prepare() {
	cp "${FILESDIR}"/xcb-rebuilder.sh "${T}"/ || die
	eprefixify "${T}"/xcb-rebuilder.sh
}

src_install() {
	x-modular_src_install
	dobin "${T}"/xcb-rebuilder.sh || die
}

pkg_postinst() {
	x-modular_pkg_postinst

	ewarn "libxcb-1.2 removed libxcb-xlib.so. Run xcb-rebuilder.sh to rebuild"
	ewarn "packages that broke. revdep-rebuild may also work."
	ebeep 5
	epause 5
}
