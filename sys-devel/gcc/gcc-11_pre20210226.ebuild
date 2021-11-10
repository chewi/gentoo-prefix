# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="7"

GCC_TARBALL_SRC_URI="https://dev.gentoo.org/~grobian/distfiles/gcc-pre11-apple-si-a172e87.tar.gz"
PATCH_GCC_VER="11.0.0"
PATCH_VER="6"
TOOLCHAIN_GCC_PV=11.0.1

inherit toolchain

#KEYWORDS="~ppc-macos ~x64-macos"

RDEPEND=""
BDEPEND="
	kernel_linux? ( ${CATEGORY}/binutils )
	kernel_Darwin? (
		|| ( ${CATEGORY}/binutils-apple ${CATEGORY}/native-cctools )
	)"

S="${WORKDIR}"/gcc-darwin-arm64-master-wip-apple-si

src_prepare() {
	has_version '>=sys-libs/glibc-2.32-r1' && rm -v "${WORKDIR}/patch/23_all_disable-riscv32-ABIs.patch"
	toolchain_src_prepare

	if use elibc_Cygwin; then
		sed -e '/0001-share-mingw-fset-stack-executable-with-cygwin.patch/d' \
			-i "${WORKDIR}/gcc-${CYGWINPORTS_GITREV}/gcc.cygport" || die
	fi

	# make sure 64-bits native targets don't screw up the linker paths
	eapply -p0 "${FILESDIR}"/no-libs-for-startfile.patch
	if use prefix; then
		eapply -p0 "${FILESDIR}"/4.5.2/prefix-search-dirs.patch
		# try /usr/lib32 in 32bit profile on x86_64-linux (needs
		# --enable-multilib), but this does make sense in prefix only
		eapply -p0 "${FILESDIR}"/${PN}-4.8.3-linux-x86-on-amd64.patch
	fi

	# make it have correct install_names on Darwin
	eapply -p1 "${FILESDIR}"/4.3.3/darwin-libgcc_s-installname.patch

	if [[ ${CHOST} == powerpc*-darwin* ]] ; then
		# https://gcc.gnu.org/bugzilla/show_bug.cgi?id=44107
		sed -i -e 's|^ifeq (/usr/lib,|ifneq (/usr/lib,|' \
			libgcc/config/t-slibgcc-darwin || die
	fi

	# fixup a what seems to be a typo, we need this at least to finish
	# compilation on arm64-macos during bootstrap as gmp.h else won't be
	# found
	sed -i -e 's/ALL_SPPFLAGS/ALL_CPPFLAGS/' \
		gcc/config/aarch64/t-aarch64 || die

	# allow building with macOS 12
	eapply -p1 "${FILESDIR}"/${PN}-10.3.0-monterey.patch
}

src_configure() {
	local myconf=()
	case ${CTARGET}:" ${USE} " in
		powerpc*-darwin*)
			# bug #381179
			filter-flags "-mcpu=*" "-mtune=*"
			# bug #657522
			# A bug in configure checks whether -no-pie works, but the
			# compiler doesn't pass -no-pie onto the linker if -fno-PIE
			# isn't passed, so the configure check always finds -no-pie
			# is accepted.  (Likewise, when -fno-PIE is passed, the
			# compiler passes -no_pie onto the linker.)
			# Since our linker doesn't grok this, avoid above checks to
			# be run
			# NOTE: later ld64 does grok -no_pie, not -no-pie (as checked)
			export gcc_cv_c_no_fpie=no
			export gcc_cv_no_pie=no
		;;
		*-darwin20)
			# use sysroot with the linker, #756160
			export gcc_cv_ld_sysroot=yes
			;;
		*-solaris*)
			# todo: some magic for native vs. GNU linking?
			myconf+=( --with-gnu-ld --with-gnu-as --enable-largefile )
			# Solaris 11 defines this in its headers, but that causes a
			# mismatch whilst compiling, bug #657514
			export ac_cv_func_aligned_alloc=no
			export ac_cv_func_memalign=no
			export ac_cv_func_posix_memalign=no
		;;
		i[34567]86-*-linux*:*" prefix "*)
			# to allow the linux-x86-on-amd64.patch become useful, we need
			# to enable multilib, even if there is just one multilib option.
			myconf+=( --enable-multilib )
			if [[ ${CBUILD:-${CHOST}} == "${CHOST}" ]]; then
				# we might be on x86_64-linux, but don't do cross-compile, so
				# tell the host-compiler to really create 32bits (for stage1)
				# (real x86-linux-gcc also accept -m32).
				append-flags -m32
			fi
		;;
	esac

	# Since GCC 4.1.2 some non-posix (?) /bin/sh compatible code is used, at
	# least on Solaris, and AIX /bin/sh is way too slow,
	# so force it to use $BASH (that portage uses) - it can't be EPREFIX
	# in case that doesn't exist yet
	export CONFIG_SHELL="${CONFIG_SHELL:-${BASH}}"
	toolchain_src_configure "${myconf[@]}"
}
