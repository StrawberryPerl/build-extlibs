PKG_URLS=(
	"ftp://ftp.gnu.org/gnu/gdb/gdb-7.7.1.tar.bz2"
)

PKG_PATCHES=(
	gdb/gdb-fix-display-tabs-on-mingw.patch
	gdb/gdb-mingw-gcc-4.7.patch
	gdb/gdb-perfomance.patch
)


PKG_CONFIGURE_FLAGS=(
	--host=$HOST
	--build=$TARGET
	--prefix=$PREFIX
	#
	--enable-targets=$ENABLE_TARGETS
	--enable-64-bit-bfd
	#
	--disable-nls
	--disable-werror
	--disable-win32-registry
	--disable-rpath
	#
	--with-system-gdbinit=$PREFIX/etc/gdbinit
	--with-python=$PREFIX/opt/bin/python-config-u.sh
	--with-expat
	--with-libiconv
	--with-zlib
	--disable-tui
	--disable-gdbtk
	#
	CFLAGS="\"$COMMON_CFLAGS -D__USE_MINGW_ANSI_STDIO=1\""
	CXXFLAGS="\"$COMMON_CXXFLAGS -D__USE_MINGW_ANSI_STDIO=1\""
	CPPFLAGS="\"$COMMON_CPPFLAGS\""
	LDFLAGS="\"$COMMON_LDFLAGS\""
)
