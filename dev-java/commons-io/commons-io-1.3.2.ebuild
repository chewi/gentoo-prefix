# Copyright 1999-2007 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2
# $Header: /var/cvsroot/gentoo-x86/dev-java/commons-io/commons-io-1.3.2.ebuild,v 1.8 2007/11/25 09:33:28 nelchael Exp $

EAPI="prefix"

JAVA_PKG_IUSE="doc source"

inherit java-pkg-2 java-ant-2 eutils

MY_P="${P}-src"
DESCRIPTION="Commons-IO contains utility classes, stream implementations, file filters, and endian classes."
HOMEPAGE="http://jakarta.apache.org/commons/io"
SRC_URI="mirror://apache/commons/io/source/${MY_P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="1"
KEYWORDS="~x86-freebsd ~amd64-linux ~ia64-linux ~x86-linux"
IUSE="test"

DEPEND=">=virtual/jdk-1.4
	test? ( dev-java/ant-junit )"
RDEPEND=">=virtual/jre-1.4"

S="${WORKDIR}/${MY_P}"

src_unpack() {
	unpack ${A}
	cd "${S}"
	java-ant_ignore-system-classes
	java-ant_rewrite-classpath
	# Setting java.io.tmpdir doesn't have effect unless we do this because the
	# vm is forked
	java-ant_xml-rewrite -f build.xml --change -e junit -a clonevm -v "true"
}

EANT_EXTRA_ARGS="-Duser.home=${T}"

src_test() {
	if has userpriv ${FEATURES}; then
		ANT_OPTS="-Djava.io.tmpdir=${T} -Duser.home=${T}" \
		ANT_TASKS="ant-junit" \
			eant test \
			-Dgentoo.classpath="$(java-pkg_getjars junit)" \
			-Dlibdir="libdir" \
			-Djava.io.tmpdir="${T}"
	else
		elog "Tests fail unless userpriv is enabled because they test for"
		elog "file permissions which doesn't work when run as root."
	fi
}

src_install() {
	java-pkg_newjar build/${P}.jar ${PN}.jar

	dodoc RELEASE-NOTES.txt NOTICE.txt || die
	use doc && java-pkg_dojavadoc build/dist-build/${P}/docs
	use source && java-pkg_dosrc src/java/*
}
