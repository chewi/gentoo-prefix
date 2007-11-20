# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-java/javatoolkit/javatoolkit-0.2.0-r1.ebuild,v 1.7 2007/03/15 01:28:22 nichoj Exp $

EAPI="prefix"

inherit eutils python

DESCRIPTION="Collection of Gentoo-specific tools for Java"
HOMEPAGE="http://www.gentoo.org/proj/en/java/"
SRC_URI="mirror://gentoo/${P}.tar.bz2"
LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~ia64 ~ppc-macos ~x86 ~x86-macos"
IUSE=""

src_unpack() {
	unpack "${A}"
	cd "${S}"
	epatch "${FILESDIR}/0.2.0-use-sax-fixed.patch"
	epatch "${FILESDIR}/0.2.0-prefix.patch"
	eprefixify makedefs.mak src/{javatoolkit,bsfix}/Makefile
	find . -name "*.py" -print0 | xargs -0 sed -i -e '/^#\( \|\)!.*python/c\#!/usr/bin/env python'
	# Fix version
	sed -i -e s/${PV}/${PVR}/ makedefs.mak
}

src_install() {
	make DESTDIR=${D} install || die
}

pkg_postinst() {
	python_mod_optimize "${EPREFIX}"/usr/share/javatoolkit
}

pkg_postrm() {
	python_mod_cleanup "${EPREFIX}"/usr/share/javatoolkit
}
