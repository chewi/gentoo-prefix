# Copyright 1999-2008 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/app-crypt/mit-krb5/mit-krb5-1.6.3-r4.ebuild,v 1.2 2008/10/05 13:12:02 flameeyes Exp $

EAPI="prefix"

inherit eutils flag-o-matic versionator autotools

PATCHV="0.4r1"
MY_P=${P/mit-}
P_DIR=$(get_version_component_range 1-2)
DESCRIPTION="MIT Kerberos V"
HOMEPAGE="http://web.mit.edu/kerberos/www/"
SRC_URI="http://web.mit.edu/kerberos/dist/krb5/${P_DIR}/${MY_P}-signed.tar
	mirror://gentoo/${P}-patches-${PATCHV}.tar.bz2"

LICENSE="as-is"
SLOT="0"
KEYWORDS="~amd64-linux ~x86-linux ~ppc-macos ~x86-macos"
IUSE="krb4 doc"

RDEPEND="!virtual/krb5
	>=sys-libs/e2fsprogs-libs-1.41.0"
DEPEND="${RDEPEND}
	doc? ( virtual/latex-base )"

S=${WORKDIR}/${MY_P}/src

PROVIDE="virtual/krb5"

src_unpack() {
	unpack ${A}
	unpack ./${MY_P}.tar.gz
	cd "${S}"
	EPATCH_SUFFIX="patch" epatch "${PATCHDIR}"

	epatch "${FILESDIR}"/${P}-no-bindnow.patch

	einfo "Regenerating configure scripts (be patient)"
	local subdir
	for subdir in $(find . -name configure.in \
		| xargs grep -l 'AC_CONFIG_SUBDIRS' \
		| sed 's@/configure\.in$@@'); do
		ebegin "Regenerating configure script in ${subdir}"
		cd "${S}"/${subdir}
		eautoconf --force -I "${S}"
		eend $?
	done
}

src_compile() {
	# needed to work with sys-libs/e2fsprogs-libs <- should be removed!!
	append-flags "-I/usr/include/et"
	econf \
		$(use_with krb4) \
		--enable-shared \
		--with-system-et --with-system-ss \
		--enable-dns-for-realm \
		--enable-kdc-replay-cache || die

	emake -j1 || die

	if use doc ; then
		cd ../doc
		for dir in api implement ; do
			make -C ${dir} || die
		done
	fi
}

src_test() {
	einfo "Tests do not run in sandbox, have a lot of dependencies and are therefore completely disabled."
}

src_install() {
	emake \
		DESTDIR="${D}" \
		EXAMPLEDIR="${EPREFIX}"/usr/share/doc/${PF}/examples \
		install || die

	keepdir /var/lib/krb5kdc

	cd ..
	dodoc README
	dodoc doc/*.ps
	doinfo doc/*.info*
	dohtml -r doc/*

	use doc && dodoc doc/{api,implement}/*.ps

	for i in {telnetd,ftpd} ; do
		mv "${ED}"/usr/share/man/man8/${i}.8 "${ED}"/usr/share/man/man8/k${i}.8
		mv "${ED}"/usr/sbin/${i} "${ED}"/usr/sbin/k${i}
	done

	for i in {rcp,rlogin,rsh,telnet,ftp} ; do
		mv "${ED}"/usr/share/man/man1/${i}.1 "${ED}"/usr/share/man/man1/k${i}.1
		mv "${ED}"/usr/bin/${i} "${ED}"/usr/bin/k${i}
	done

	newinitd "${FILESDIR}"/mit-krb5kadmind.initd mit-krb5kadmind
	newinitd "${FILESDIR}"/mit-krb5kdc.initd mit-krb5kdc

	insinto /etc
	newins "${ED}"/usr/share/doc/${PF}/examples/krb5.conf krb5.conf.example
	newins "${ED}"/usr/share/doc/${PF}/examples/kdc.conf kdc.conf.example
}

pkg_postinst() {
	elog "See /usr/share/doc/${PF}/html/krb5-admin.html for documentation."
}
