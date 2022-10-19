#!/bin/sh

# helper functions
function xxrun ()
{
  echo "######## gonna launch: $@" | tee -a $OUT/$PACK.build.log
  {
    "$@" && echo "######## retval=success" || echo "######## retval=FAILURE"
  } 2>&1 | tee -a $OUT/$PACK.build.log
}

function save_configure_help ()
{
  ./configure --help > $OUT/$PACK.configure-help.txt
}

function disable_pthread()
{
### #ultra ugly
### for A in `find "$GCCDIR" -name pthread.h`; do
###   if [ -f $A ] ; then
###     echo "DISABLING $A"
###     mv $A $A.backup
###   else
###     echo "WARNING $A not a file"
###   fi
### done
echo "nop"
}

function enable_pthread()
{
### #ultra ugly
### for A in `find "$GCCDIR" -name pthread.h.backup`; do
###   B=`echo $A | sed "s,\.backup$,,"`
###   if [ -f $A ] ; then
###     echo "ENABLING $A"
###     mv $A $B
###   else
###     echo "WARNING $A not a file"
###   fi
### done
echo "nop"
}

function patch_libtool()
{
  find . -type f -name libtool | while read LIBTOOL; do
    echo "gonna patch.libtool $LIBTOOL"
    if [ ! -e $LIBTOOL.backup ] ; then cp -p $LIBTOOL $LIBTOOL.backup; fi
    if [ -e $LIBTOOL.backup ] ; then
	#1-hack for DLLSUFFIX
	#2-hack for proper detection of 64bit *.a libs - based on "objdump -f libname.a" output
    sed -e "s|^\s*shrext_cmds=.\.dll.$|shrext_cmds='$DLLSUFFIX.dll'|" \
        -e "s|^\s*\(library_names_spec=\".\`echo .\${libname}\)|\1$DLLSUFFIX|" \
        -e "s|EGREP[-e ]*'file format pe-i386(\.\*architecture: i386)?' >/dev/null ; then|EGREP 'file format pe-(i386\|x86-64)(.*architecture: i386)?' >/dev/null ; then|" \
        -e "s|deplibs_check_method=\"file_magic file format pei\*-i386(\.\*architecture: i386)?\"|deplibs_check_method=\"file_magic file format pe-(i386\|x86-64)(.*architecture: i386)?\" |" \
        -e "s|deplibs_check_method=\"file_magic file format pe-i386(\.\*architecture: i386)?\"|deplibs_check_method=\"file_magic file format pe-(i386\|x86-64)(.*architecture: i386)?\" |" \
          $LIBTOOL.backup > $LIBTOOL;
    # preserve the original file timestamp
    touch -r $LIBTOOL.backup $LIBTOOL
    fi
  done
}

function patch_libtool_v2()
{
  find . -type f -name libtool.m4 -o -name aclocal.m4 -o -name ltmain.sh -o -name libtool -o -name configure | while read LIBTOOL; do
    echo "gonna patch_libtool $LIBTOOL"
    if [ ! -e $LIBTOOL.backup ] ; then cp -p $LIBTOOL $LIBTOOL.backup; fi
    if [ -e $LIBTOOL.backup ] ; then
	#1-hack for DLLSUFFIX
	#2-hack for proper detection of 64bit *.a libs - based on "objdump -f libname.a" output
    sed -e "s|^\s*shrext_cmds=.\.dll.$|shrext_cmds='$DLLSUFFIX.dll'|" \
        -e "s|^\s*\(library_names_spec=\".\`echo .\${libname}\)|\1$DLLSUFFIX|" \
	-e "s|EGREP[-e ]*'file format pe-i386(\.\*architecture: i386)?' >|EGREP 'file format (pei\*-i386(\.\*architecture:\ i386)?\|pe-arm-wince\|pe-x86-64)' >|" \
	-e "s|EGREP[-e ]*'file format (pe-i386(\.\*architecture: i386)?\|pe-arm-wince\|pe-x86-64)' >|EGREP 'file format (pei\*-i386(\.\*architecture:\ i386)?\|pe-arm-wince\|pe-x86-64)' >|" \
	-e "s|deplibs_check_method='file_magic file format pei\*-i386(\.\*architecture: i386)?'|deplibs_check_method='file_magic file format (pei\*-i386(\.\*architecture:\ i386)?\|pe-arm-wince\|pe-x86-64)'|" \
	-e "s|deplibs_check_method='file_magic file format pe-i386(\.\*architecture: i386)?'|deplibs_check_method='file_magic file format (pei\*-i386(\.\*architecture:\ i386)?\|pe-arm-wince\|pe-x86-64)'|" \
          $LIBTOOL.backup > $LIBTOOL
    diff -up $LIBTOOL.backup $LIBTOOL >> $LIBTOOL.backup.diff
    # preserve the original file timestamp
    touch -r $LIBTOOL.backup $LIBTOOL
    fi
  done
}

function patch_prefix ()
{
  #hack needed for openssl which generates paths like "z:/build/dir/..."
  OUT2=`echo "$OUT"| sed -e "s,^/\([a-zA-Z]\)/,\1:/,"`
  #echo "patch_prefix (OUT=$OUT OUT2=$OUT2)"
  for F in $@; do
    echo "gonna patch.prefix $F"
    if [ -e $F ] ; then
      if [ ! -e $F.backup ] ; then cp $F $F.backup; fi
      #echo "patch_prefix (sed $F.backup > $F)"
      # /mingw replaced by ${pcfiledir}/../..
      sed -e "s,$OUT2,\$\{pcfiledir}\/../..,gi" \
          -e "s,c:.Windows.System32.\([^\.]*\).dll,-l\1,gi" \
          -e "s,$OUT,\$\{pcfiledir}\/../..,gi" $F.backup > $F
    fi
  done
}

function install_bats ()
{
  echo "curdir=`pwd`"
  find . -type f -name "*.bat.win-gcc" | while read F; do
    FF=`basename $F | sed "s/\.win-gcc$//"`
    FS=`echo $F | sed "s/-config\.bat\.win-gcc$/-config/"`
    V=`grep -A1 "\-\-version)" $FS | grep "echo *[0-9]" | head -n1 | sed "s/^[^0-9]*//"`
    echo "gonna install(bat) $F > $FF"
    if [ -n "$V" ] ; then
      echo "patching version number: $V"
      sed "s/^set XVERSION=.*/set XVERSION=$V/" $F > $OUT/bin/$FF
    else
      cp $F $OUT/bin/$FF
    fi
  done
}

function reset_timestamps ()
{
  touch $OUT/_timestamp_
  find $OUT/ -type f | xargs touch -t '7707070707.07'
}

### start ###

if gcc -v 2>&1 | grep "Target.*x86_64" >/dev/null ; then
IS64BIT=1
HOSTBUILD="--host=x86_64-w64-mingw32 --build=x86_64-w64-mingw32"
HOSTBUILDTARGET="--host=x86_64-w64-mingw32 --build=x86_64-w64-mingw32 --target=x86_64-w64-mingw32"
XTARGET="x86_64-w64-mingw32"
ARCHNICK=64bit
ARCHBITS=64
LBUFFEROVERFLOWU=-lbufferoverflowu
else
IS64BIT=
HOSTBUILD="--host=i686-w64-mingw32 --build=i686-w64-mingw32"
HOSTBUILDTARGET="--host=i686-w64-mingw32 --build=i686-w64-mingw32 --target=i686-w64-mingw32"
XTARGET="i686-w64-mingw32"
ARCHNICK=32bit
ARCHBITS=32
fi

if [ ! -e "$1" ] ; then
  echo "Warning: assuming params to be package names!"
  export PKGLISTNAME=buildtest
  if [ $IS64BIT ] ; then
    export DLLSUFFIX=__
  else
    export DLLSUFFIX=_
  fi
  PKGLIST=$@
else
  # parameter 1: pkg-list filename
  export PKGLISTNAME=$1
  PKGLIST=`grep -v -e "^#" -e "^\s*$" "$1" 2>/dev/null`
  # parameter 2: dllsuffix
  if [ -s "$2" ] ; then
    export DLLSUFFIX=
  else
    export DLLSUFFIX=$2
  fi
fi

#calling pwd needs correct PATH
export PATH=".:/usr/local/bin:/bin:$PATH"

#cleaning up env variables influencing gcc compiler
unset LIB
unset INCLUDE

CURDIR=`pwd`
SRCDIR=$CURDIR/sources
PATCHDIR=$CURDIR/patches
WRKDIR=$CURDIR/_$PKGLISTNAME$DLLSUFFIX.src
OUTZIP=$CURDIR/_$PKGLISTNAME$DLLSUFFIX.patched
OUTTMP=$CURDIR/_$PKGLISTNAME$DLLSUFFIX.tmp
OUT=$CURDIR/_$PKGLISTNAME$DLLSUFFIX
OUTBIN=$OUT/bin
OUTLIB=$OUT/lib
OUTINC=$OUT/include
CURDATE=`date "+%Y%m%d"`

export PATH="$PATH:$OUTBIN:$CURDIR/bin"
export PKG_CONFIG_PATH="$OUTLIB/pkgconfig/"
export PKG_CONFIG=/bin/pkg-config

echo "###### [`date +%T`] BUILD STARTED param1='$PKGLISTNAME' param2='$DLLSUFFIX'"
echo "###### gcc: `gcc -v 2>&1 | grep Target`"
echo "###### is64bit: $IS64BIT"
echo "###### out: $OUT"

mkdir -p "$WRKDIR"
mkdir -p "$OUT"

cp $0 $OUT/build.script.txt
for P in $PKGLIST; do echo $P; done > $OUT/build.liblist.txt

GCCVER=`gcc --version | grep gcc`
echo "{\"builddate\":\"$CURDATE\",\"architecture\":\"$ARCHNICK\",\"gcc\":\"$GCCVER\"}" > $OUT/build.info.json

(
  echo "####current date/time"
  date
  echo "####gcc"
  gcc -v
  echo "####binutils/ar"
  ar --version
  echo "####make"
  make -v
  echo "####uname"
  uname -a
  echo "####env/subset"
  set | grep -e PROCESSOR -e \^COMSPEC
) > $OUT/build.sysinfo.txt 2>&1

echo "#### Unpacking sources"
for PACK in $PKGLIST; do
  echo "### $PACK"
  mkdir -p $SRCDIR
  (cd $SRCDIR && wget -nv -nc --no-check-certificate `grep -v '^#' $CURDIR/sources.list | grep $PACK | head -n 1`)
  cd $WRKDIR
  rm -rf $WRKDIR/$PACK
  SRCBALL=''
  if [ -e $SRCDIR/$PACK.zip ]      ; then SRCBALL="$PACK.zip"; (mkdir $PACK; cd $PACK; cp $SRCDIR/$PACK.zip .; 7za -y x $PACK.zip); fi
  if [ -e $SRCDIR/$PACK.tar.gz ]   ; then SRCBALL="$PACK.tar.gz";   tar -xzf $SRCDIR/$PACK.tar.gz; fi
  if [ -e $SRCDIR/$PACK.tgz ]      ; then SRCBALL="$PACK.tgz";      tar -xzf $SRCDIR/$PACK.tgz; fi
  if [ -e $SRCDIR/$PACK.tar.bz2 ]  ; then SRCBALL="$PACK.tar.bz2";  tar -xjf $SRCDIR/$PACK.tar.bz2; fi
  if [ -e $SRCDIR/$PACK.tar.lzma ] ; then SRCBALL="$PACK.tar.lzma"; tar --lzma -xf $SRCDIR/$PACK.tar.lzma; fi
  if [ -e $SRCDIR/$PACK.tar.xz ]   ; then SRCBALL="$PACK.tar.xz";   tar --xz -xf $SRCDIR/$PACK.tar.xz; fi
  if [ -z $SRCBALL ] ; then echo "FATAL: source tarball for '$PACK' not found" ; exit ; fi
  (
    #ugly but somehow works
    echo "{"
    echo "\"url\":\"`grep -v -e '^#' $CURDIR/sources.list | grep $PACK | sed "s/^\([^\t ][^\t ]*\).*/\1/" 2>/dev/null`\","
    echo "\"pack\":\"$PACK\","
    echo "\"srcball\":\"$SRCBALL\","
    ls -gG --full-time $SRCDIR/$SRCBALL | awk '{print "\"size\":" $3 ",\"time\":\"" $4 " " $5 "\","}'
    sha1sum $SRCDIR/$SRCBALL | awk '{print "\"sha1sum\":\"" $1 "\""}'
    echo "}"
  ) > $OUT/$PACK.srcinfo.json 2>&1

  if [ -d $PATCHDIR/$PACK ] ; then
    cp -R $WRKDIR/$PACK $WRKDIR/$PACK.original
    cd $WRKDIR/$PACK
    cmd.exe /c 'attrib -R *.* /S /D' # removing R/O attribute - berkeley-db hack
    cp -r $PATCHDIR/$PACK/* . 2>/dev/null
    echo -n '' > $OUT/$PACK.patch.log
    ls $PATCHDIR/$PACK/*.patch $PATCHDIR/$PACK/*.diff 2>/dev/null | while read P; do
      echo "GONNA Apply: $P : $OUT/$PACK.patch.log"
      echo "GONNA Apply: $P" >> $OUT/$PACK.patch.log
      patch --no-backup-if-mismatch -i $P -p 1 >> $OUT/$PACK.patch.log 2>&1
    done

    ( cd "$WRKDIR/$PACK" && find . -type f | grep -v -e "\.rej$" -e "\.diff$" -e "\.patch$" | while read XF; do touch "../$PACK.original/$XF"; done )
    ( cd $WRKDIR && diff -r -u --strip-trailing-cr $PACK.original $PACK 2>/dev/null ) | grep -v "^Only in " > $OUT/$PACK.diff
    rm -rf $WRKDIR/$PACK.original
  fi
done

disable_pthread

echo "#### Building packages"
for PACK in $PKGLIST; do
echo "### BUILDING $PACK"
test -d $WRKDIR/$PACK || continue
reset_timestamps
rm -f $OUT/$PACK.build.log

case $PACK in

# ----------------------------------------------------------------------------
uv-*)
cd $WRKDIR/$PACK
xxrun make
#xxrun make bench
xxrun make test
#pseudo make install
mkdir -p $OUT/inlude/uv-private
mkdir -p $OUT/lib
cp uv.a $OUT/lib/uv.a
cp -R include/uv-private $OUT/inlude
cp include/uv.h $OUT/inlude/uv.h
;;

# ----------------------------------------------------------------------------
expat-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            "CFLAGS=-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make
xxrun make check
xxrun make install
;;

# ----------------------------------------------------------------------------
libiconv-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --without-libintl-prefix --disable-rpath --disable-nls \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make
xxrun make check
xxrun make install
;;

# ----------------------------------------------------------------------------
libxml2-*)
cd $WRKDIR/$PACK
save_configure_help

libtoolize --copy --force
aclocal
automake --add-missing
autoconf

xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --with-threads=win32 --without-python --with-modules \
            --with-iconv=$OUT --with-zlib=$OUT --with-lzma=$OUT \
            CFLAGS="-O2 -I$OUTINC -D__USE_MINGW_ANSI_STDIO=1" LDFLAGS="-L$OUTLIB"

patch_libtool
xxrun make
##xxrun make check
xxrun make install
## ugly hack (historical reasons) - see pack.pl
sed -i 's,\${includedir}/libxml2,${includedir},' $OUT/lib/pkgconfig/libxml-2.0.pc
;;

# ----------------------------------------------------------------------------
libxslt-*)
cd $WRKDIR/$PACK
###xxx-#hack: fix timestamps
###xxx-touch -r Makefile.am config.* Makefile.* configure* aclocal.*
save_configure_help

xxrun autoreconf -fi

xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --with-libxml-prefix=$OUT --without-python --with-crypto --with-plugins

############CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"

patch_libtool
xxrun make
#xxrun make check > /dev/null
xxrun make check
xxrun make install
;;

# ----------------------------------------------------------------------------
libpng-1.5*)
cd $WRKDIR/$PACK
echo "PNG-1.5"
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
libpng-1.6*)
cd $WRKDIR/$PACK
echo "PNG-1.6"
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --with-zlib-prefix=$OUT \
            CPPFLAGS="-O2 -I$OUTINC" CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make
xxrun make check
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
libpng-*)
cd $WRKDIR/$PACK
echo "non-PNG-1.5"
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make SYMBOL_PREFIX= install
install_bats
#dirty hack - libpng12.dll.a is not generated correctly by mingw-w64
#cp $OUT/lib/libpng12.dll.a $OUT/lib/libpng12.dll.a.orig
#cp $OUT/lib/libpng.dll.a $OUT/lib/libpng12.dll.a
;;

# ----------------------------------------------------------------------------
freetype-*)
cd $WRKDIR/$PACK
save_configure_help
CC=gcc xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
harfbuzz-*)
cd $WRKDIR/$PACK
save_configure_help

#dll suffix hack
sed -i "s|LIBRARY lib%s-0\.dll|LIBRARY lib%s-0$DLLSUFFIX.dll|" src/gen-def.py

xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
                  --with-graphite2=auto --with-freetype=auto CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make
xxrun make install
;;

# ----------------------------------------------------------------------------
fontconfig-*)
cd $WRKDIR/$PACK
save_configure_help

#dll suffix hack
sed -i "s|@LIBT_CURRENT_MINUS_AGE@.dll|@LIBT_CURRENT_MINUS_AGE@$DLLSUFFIX.dll|g" src/Makefile.in
sed -i "s|@LIBT_CURRENT_MINUS_AGE@.dll|@LIBT_CURRENT_MINUS_AGE@$DLLSUFFIX.dll|g" src/Makefile.am
xxrun autoreconf -fiv

xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --disable-docs --enable-iconv --with-libiconv=$OUT as_ln_s="cp -pR"

sed -i 's,all-am: Makefile $(PROGRAMS),all-am:,' test/Makefile

#HACK:
cp $(dirname `which gcc`)/*.dll ./fc-cache

patch_libtool
xxrun make
xxrun make install
;;

# ----------------------------------------------------------------------------
libgd-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --with-libiconv-prefix=$OUT --with-zlib=$OUT --with-freetype=$OUT --with-png=$OUT --with-jpeg=$OUT --with-tiff==$OUT --with-xpm=$OUT \
            --without-fontconfig --without-x \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields -DBGDWIN32" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make
xxrun make install
#hack: as we do not use install_bats we need to do some magic (copy features: line)
F=`grep "echo  *\"features:" $OUT/bin/gdlib-config | sed -e "s/^[[:blank:]]*//" -e "s/  */ /g" -e "s/\"//g"`
sed "s/^echo features:.*$/$F/" gdlib-config.bat.win-gcc > $OUT/bin/gdlib-config.bat
;;

# ----------------------------------------------------------------------------
gd-*)
cd $WRKDIR/$PACK
#hack: fix timestamps
touch -r Makefile.am config.* Makefile.* configure* aclocal.*
save_configure_help
# ... --with-fontconfig=$OUT
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --with-freetype=$OUT --with-png=$OUT --with-jpeg=$OUT --with-xpm=$OUT --without-fontconfig --without-x \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields -DBGDWIN32" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make install
#hack1: make libjpeg-6...dll part of gd
touch $OUT/bin/libjpeg-6*.dll
#hack2: as we do not use install_bats we need to do some magic (copy features: line)
F=`grep "echo  *\"features:" $OUT/bin/gdlib-config | sed -e "s/^[[:blank:]]*//" -e "s/  */ /g" -e "s/\"//g"`
sed "s/^echo features:.*$/$F/" gdlib-config.bat.win-gcc > $OUT/bin/gdlib-config.bat
;;

# ----------------------------------------------------------------------------
db-*)
cd $WRKDIR/$PACK/build_windows
../dist/configure --help > ../help_$PACK.txt
xxrun ../dist/configure $HOSTBUILD --prefix="$OUT" --enable-static=no --enable-shared=yes \
                        --enable-mingw --with-cryptography \
                        --disable-rpath --disable-tcl
###removed: --enable-cxx --enable-sql --enable-sql-codegen --enable-stl --enable-compat185 --enable-dbm
patch_libtool
xxrun make LIBSO_LIBS=-lpthread
xxrun make install
rm -rf $OUT/docs
;;

# ----------------------------------------------------------------------------
gdbm-*)
cd $WRKDIR/$PACK
save_configure_help

xxrun autoreconf --install --force

xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
                --without-libintl-prefix --without-libiconv-prefix --without-readline --enable-libgdbm-compat --disable-nls

patch_libtool
xxrun make
xxrun make check
xxrun make install
#xxrun make install-compat
;;

# ----------------------------------------------------------------------------
gmp-*)
cd $WRKDIR/$PACK
save_configure_help
#do not use any CFLAGS here!!
if [ $IS64BIT ] ; then
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=yes --enable-shared=no
else
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-fat --enable-static=yes --enable-shared=no
fi
patch_libtool
xxrun make
xxrun make check -k
xxrun make install
;;

# ----------------------------------------------------------------------------
mpfr-*)
cd $WRKDIR/$PACK
save_configure_help
#do not use any CFLAGS here!!
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=yes --enable-shared=no \
            --with-gmp=$OUT
patch_libtool
xxrun make
xxrun make check -k
xxrun make install
;;

# ----------------------------------------------------------------------------
mpc-*)
cd $WRKDIR/$PACK
save_configure_help
#do not use any CFLAGS here!!
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=yes --enable-shared=no \
            --with-mpfr=$OUT --with-gmp=$OUT
patch_libtool
xxrun make
xxrun make check -k
xxrun make install
;;


# ----------------------------------------------------------------------------
openssl-fips-*)
if [ $IS64BIT ] ; then
  OPENSSLTARGET=mingw64
else
  OPENSSLTARGET=mingw
fi
TERM=msys xxrun perl Configure --prefix=$OUT $OPENSSLTARGET
xxrun make PERL=perl
xxrun make PERL=perl install_sw
;;

# ----------------------------------------------------------------------------
openssl-1.1.1*)
cd $WRKDIR/$PACK

if [ $IS64BIT ] ; then
  OPENSSLTARGET=mingw64
else
  OPENSSLTARGET=mingw
fi

sed -i "s/shared_extension => \".dll\"/shared_extension => \"${DLLSUFFIX}.dll\"/g" Configurations/00-base-templates.conf
sed -i "s/shared_extension => \".dll\"/shared_extension => \"${DLLSUFFIX}.dll\"/g" Configurations/10-main.conf
sed -i "s/^LIBRARY  *\$libname/LIBRARY  \${libname}$DLLSUFFIX/" util/mkdef.pl

### -D__MINGW_USE_VC2005_COMPAT is a trouble maker see https://github.com/StrawberryPerl/Perl-Dist-Strawberry/issues/15

xxrun ./Configure shared zlib enable-rfc3779 enable-camellia enable-capieng enable-idea enable-mdc2 enable-rc5 \
        -DOPENSSLBIN=\"\\\"${OUT}/bin\\\"\" --openssldir=ssl \
        --with-zlib-lib=$OUTLIB --with-zlib-include=$OUTINC \
        --prefix=$OUT $OPENSSLTARGET

### zlib-dynamic vs. zlib

sed -i 's/__*\.dll\.a/.dll.a/g' Makefile
sed -i 's/__*\.dll\.a/.dll.a/g' configdata.pm
sed -i "s/define LIBZ \"ZLIB1\"/define LIBZ \"ZLIB1$DLLSUFFIX\"/" crypto/comp/c_zlib.c

xxrun make depend all
#xxrun make tests
xxrun make install_sw

###HACK engines-1_1/*.dll must be without DLLSUFFIX !!
mv "$OUT/lib/engines-1_1/capi$DLLSUFFIX.dll" "$OUT/lib/engines-1_1/capi.dll"
mv "$OUT/lib/engines-1_1/padlock$DLLSUFFIX.dll" "$OUT/lib/engines-1_1/padlock.dll"
;;

# ----------------------------------------------------------------------------
openssl-1.1.*)
cd $WRKDIR/$PACK

sed -i "s|SHLIB_SOVER=-\$\$sover\$\$arch;|SHLIB_SOVER=-\$\$sover\$\$arch\\\\${DLLSUFFIX};|" Makefile.shared
sed -i "s/\"ZLIB1\"/\"ZLIB1$DLLSUFFIX\"/" crypto/comp/c_zlib.c
if [ $IS64BIT ] ; then
  OPENSSLTARGET=mingw64
else
  OPENSSLTARGET=mingw
fi
xxrun ./Configure shared zlib enable-static-engine enable-rfc3779 --with-zlib-lib=$OUTLIB --with-zlib-include=$OUTINC --prefix=$OUT $OPENSSLTARGET
sed -i "s/lib\(crypto\|ssl\)-\([^.]\+\).dll/lib\1-\2${DLLSUFFIX}.dll/g" Makefile

xxrun make depend all
#xxrun make tests
xxrun make install_sw
### #hack: patch pkg-config related files
### sed -i -e 's/-lcrypto/-leay32/' -e 's/-lssl/-lssl32/' $OUT/lib/pkgconfig/libcrypto.pc
### sed -i -e 's/-lcrypto/-leay32/' -e 's/-lssl/-lssl32/' $OUT/lib/pkgconfig/libssl.pc
### sed -i -e 's/-lcrypto/-leay32/' -e 's/-lssl/-lssl32/' $OUT/lib/pkgconfig/openssl.pc
### #hack: renamed DLLs are not installed
### cp *.dll $OUT/bin/
;;

# ----------------------------------------------------------------------------
openssl-1.0.*)
cd $WRKDIR/$PACK

#hack: changing DLL suffix
test -e Makefile.shared.backup || cp Makefile.shared Makefile.shared.backup
sed "s|SHLIB_SOVER=32;|SHLIB_SOVER=32$DLLSUFFIX;|" Makefile.shared.backup > Makefile.shared
test -e util/mkdef.pl.backup || cp util/mkdef.pl util/mkdef.pl.backup
sed "s|{ \$libname\.=\"32\"; }|{ \$libname.=\"32$DLLSUFFIX\"; }|" util/mkdef.pl.backup > util/mkdef.pl

#hack: changing DLL suffix
sed -i "s/\"ZLIB1\"/\"ZLIB1$DLLSUFFIX\"/" crypto/comp/c_zlib.c

if [ $IS64BIT ] ; then
  OPENSSLTARGET=mingw64
else
  OPENSSLTARGET=mingw
fi
xxrun ./Configure shared zlib enable-static-engine enable-rfc3779 --with-zlib-lib=$OUTLIB --with-zlib-include=$OUTINC --prefix=$OUT $OPENSSLTARGET

sed -i "s/libeay32\.dll/libeay32${DLLSUFFIX}.dll/" Makefile
sed -i "s/ssleay32\.dll/ssleay32${DLLSUFFIX}.dll/" Makefile

xxrun make depend all
xxrun make tests
xxrun make install_sw
#hack: patch pkg-config related files
sed -i -e 's/-lcrypto/-leay32/' -e 's/-lssl/-lssl32/' $OUT/lib/pkgconfig/libcrypto.pc
sed -i -e 's/-lcrypto/-leay32/' -e 's/-lssl/-lssl32/' $OUT/lib/pkgconfig/libssl.pc
sed -i -e 's/-lcrypto/-leay32/' -e 's/-lssl/-lssl32/' $OUT/lib/pkgconfig/openssl.pc
#hack: renamed DLLs are not installed
cp *.dll $OUT/bin/
;;

# ----------------------------------------------------------------------------
mysql-connector-c-*)
cd $WRKDIR/$PACK
#hack2: pg uses linker option -lssleay32
test -e $OUT/lib/libcrypto.dll.a && cp $OUT/lib/libcrypto.dll.a $OUT/lib/libeay32.a
test -e $OUT/lib/libssl.dll.a && cp $OUT/lib/libssl.dll.a $OUT/lib/libssl32.a
test -e $OUT/lib/libssl.dll.a && cp $OUT/lib/libssl.dll.a $OUT/lib/libssleay32.a
#hacks: done
#xxrun cmake -G "MSYS Makefiles" -DWITH_ZLIB=system -DWITH_SSL=$OUT -DCMAKE_INSTALL_PREFIX=$OUT
#xxrun cmake -G "MSYS Makefiles" -DWITH_ZLIB=system -DWITH_SSL=bundled -DCMAKE_INSTALL_PREFIX=$OUT
xxrun cmake -G "MinGW Makefiles" -DWITH_ZLIB=system -DWITH_SSL=bundled -DCMAKE_INSTALL_PREFIX=$OUT -DCMAKE_MAKE_PROGRAM=gmake
xxrun gmake
xxrun gmake install
;;

# ----------------------------------------------------------------------------
postgresql-*)
cd $WRKDIR/$PACK
### #hack1: changing DLL suffix - BEWARE we use 'x_'  || 'x__'
### cp src/Makefile.shlib src/Makefile.shlib.old
### sed "s,^[[:blank:]]*shlib[[:blank:]]*=[[:blank:]]*lib.(NAME).(DLSUFFIX)$,shlib = lib\$(NAME)x$DLLSUFFIX\$(DLSUFFIX)," src/Makefile.shlib.old > src/Makefile.shlib
#hack1: changing DLL suffix
cp src/Makefile.shlib src/Makefile.shlib.old
sed "s,.(NAME).(DLSUFFIX),\$(NAME)$DLLSUFFIX\$(DLSUFFIX)," src/Makefile.shlib.old > src/Makefile.shlib
cp src/interfaces/libpq/libpqdll.def src/interfaces/libpq/libpqdll.def.old
sed "s,LIBRARY LIBPQ\.dll,LIBRARY LIBPQ$DLLSUFFIX.dll," src/interfaces/libpq/libpqdll.def.old > src/interfaces/libpq/libpqdll.def
#hack2: pg uses linker option -lssleay32
test -e $OUT/lib/libcrypto.dll.a && cp $OUT/lib/libcrypto.dll.a $OUT/lib/libeay32.a
test -e $OUT/lib/libssl.dll.a && cp $OUT/lib/libssl.dll.a $OUT/lib/libssl32.a
test -e $OUT/lib/libssl.dll.a && cp $OUT/lib/libssl.dll.a $OUT/lib/libssleay32.a
#hacks: done
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --with-zlib --with-ldap --with-openssl --with-includes=$OUTINC --with-libraries=$OUTLIB
#build only client related parts
xxrun make -C src/bin/pg_config install
xxrun make -C src/interfaces/libpq install
xxrun make -C src/include install
####cp src/include/postgres_ext.h $OUT/include/
;;

# ----------------------------------------------------------------------------
SDL-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure --prefix=$OUT --enable-static=no --enable-shared=yes --disable-nasm \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make install
install_bats
cd $WRKDIR/$PACK/test
xxrun ./configure --prefix=$OUT
xxrun make
;;

# ----------------------------------------------------------------------------
SDL_mixer-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --with-sdl-prefix=$OUT --disable-music-mp3-mad-gpl \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make install
;;

# ----------------------------------------------------------------------------
SDL2_mixer-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --with-sdl-prefix=$OUT --enable-music-mp3 \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make install
;;

# ----------------------------------------------------------------------------
SDL2-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure --prefix=$OUT --disable-dependency-tracking \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make install
rm $OUTLIB/libSDL2.a
rm $OUTLIB/libSDL2_test.a
;;

# ----------------------------------------------------------------------------
SDL2_*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make install
;;

# ----------------------------------------------------------------------------
libsmpeg-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --with-sdl-prefix=$OUT \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
SDL_net-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --with-sdl-prefix=$OUT \
	    CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make INETLIB=-lws2_32 libSDL_net_la_LIBADD=-lws2_32 install
install_bats
;;

# ----------------------------------------------------------------------------
SDL_rtf-*)
cd $WRKDIR/$PACK
save_configure_help
CFLAGS="-O2 -I$OUTINC -mms-bitfields" ./configure \
    --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
    --with-sdl-prefix=$OUT
patch_libtool
xxrun make install
install_bats
mv $OUT/lib/SDL_rtf*.dll $OUT/bin/
;;

# ----------------------------------------------------------------------------
SDL_vnc-*)
cd $WRKDIR/$PACK
save_configure_help
#workaround: CFLAGS can be specified only this way
CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB -lws2_32" ./configure \
            --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes
patch_libtool
xxrun make install
install_bats
mv $OUT/lib/SDL_vnc*.dll $OUT/bin/
;;

# ----------------------------------------------------------------------------
SDL_gfx*)
cd $WRKDIR/$PACK
save_configure_help
#disable assembler on 64bit
if [ $IS64BIT ] ; then
  SDLGFXEXTRA="--disable-mmx"
else
  SDLGFXEXTRA="--enable-mmx"
fi
xxrun ./configure --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --with-sdl-prefix=$OUT $SDLGFXEXTRA \
	    CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
##build via custom Makefile.win-gcc
SDL_Pango-* | SDL_sound-* | SDL_svg-*)
cd $WRKDIR/$PACK
xxrun make -f Makefile.win-gcc NOPERL=1 PREFIX=$OUT DLLSUFFIX=$DLLSUFFIX clean install
;;

# ----------------------------------------------------------------------------
SDL_*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --with-sdl-prefix=$OUT \
	    CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
# we build the old jpeg library from gnuwin32 sources
jpeg-6b-gnuwin32)
cd $WRKDIR/$PACK
xxrun make DLLSUFFIX=$DLLSUFFIX prefix=$OUT install-lib
#hack: we need a special patch for resulting libjpeg.la
cp -p $OUT/lib/libjpeg.la $OUT/lib/libjpeg.la.backup
sed "s/^installed=no/installed=yes/" $OUT/lib/libjpeg.la.backup > $OUT/lib/libjpeg.la
rm $OUT/lib/libjpeg.la.backup
;;

# ----------------------------------------------------------------------------
libmodplug-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make libmodplug_la_LIBADD= install
;;

# ----------------------------------------------------------------------------
flac-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --disable-asm-optimizations \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields --param large-function-growth=2000" LDFLAGS="-L$OUTLIB"
#nasm sucks here thus noasm
patch_libtool
xxrun make LOCAL_EXTRA_LIBADD=-lws2_32 install
;;

# ----------------------------------------------------------------------------
glib-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --with-threads=win32 --disable-gtk-doc-html \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
#64bit hack - configure does not properly detect x86_64
#it is perhaps due to the fact that we are using 32bit MSYS environment
###if [ $IS64BIT ] ; then
###  cp config.h config.h.backup
###  sed "s/^#define G_ATOMIC_I486 1$/#define G_ATOMIC_X86_64 1/" config.h.backup > config.h
###fi
xxrun make install
;;

# ----------------------------------------------------------------------------
gettext-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes
patch_libtool
xxrun make install
;;

# ----------------------------------------------------------------------------
pango-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            --with-included-modules=yes \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make
#ultra ugly hack fixing lines 'Z:/strawberry_libs/msys/* enumerations from "pango-coverage.h" *//n'
cp -p pango/pango-enum-types.h pango/pango-enum-types.h.backup
sed -e "s,^[a-zA-Z]:.*/\*,/*," -e "s,\*//n$,*/," pango/pango-enum-types.h.backup > pango/pango-enum-types.h
xxrun make install
;;

# ----------------------------------------------------------------------------
cairo-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
#special hack to handle changed DLL suffix
cp src/Makefile src/Makefile.backup
cp Makefile Makefile.backup
sed "s/libcairo-\$(CAIRO_VERSION_SONUM)\.dll/libcairo-\$(CAIRO_VERSION_SONUM)$DLLSUFFIX.dll/" src/Makefile.backup > src/Makefile
sed "s/libcairo-\$(CAIRO_VERSION_SONUM)\.dll/libcairo-\$(CAIRO_VERSION_SONUM)$DLLSUFFIX.dll/" Makefile.backup > Makefile
xxrun make install
;;

# ----------------------------------------------------------------------------
glpk-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes
patch_libtool
xxrun make
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
libffi-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILDTARGET --prefix=$OUT --enable-static=no --enable-shared=yes
patch_libtool
xxrun make
xxrun make install
#hack
/bin/mkdir -p "$OUT/include"
/bin/install -c -m 644 "$XTARGET/include/ffi.h" "$XTARGET/include/ffitarget.h" "$OUT/include"
sed -i 's,includedir=\${libdir}/libffi-[^/]*/include,includedir=${exec_prefix}/include,' $OUT/lib/pkgconfig/libffi.pc
;;

# ----------------------------------------------------------------------------
fftw-3*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes --disable-dependency-tracking --enable-float
patch_libtool
xxrun make
xxrun make check
xxrun make install
xxrun make clean
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes --disable-dependency-tracking
patch_libtool
xxrun make
xxrun make check
xxrun make install
;;

# ----------------------------------------------------------------------------
xz-* | gsl-* | fftw-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes
patch_libtool
xxrun make
xxrun make check
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
libssh2-*)
cd $WRKDIR/$PACK
save_configure_help
#  avoid mansyntax.sh test failure
sed -i "s|rm -f |rm -rf |" tests/mansyntax.sh
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes --disable-examples-build
patch_libtool
xxrun make
xxrun make check
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
libcaca-*)
cd $WRKDIR/$PACK
xxrun ./bootstrap
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes
patch_libtool
xxrun make
xxrun make check
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
R-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes --enable-R-shlib --without-tcltk --without-x --disable-BLAS-shlib --disable-R-profiling
patch_libtool
xxrun make
xxrun make check
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
gretl-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes --disable-gui --disable-www --disable-gnuplot-checks
patch_libtool
xxrun make
xxrun make check
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
graphite2-*)
cd $WRKDIR/$PACK

echo "IF (BUILD_SHARED_LIBS)" >> CMakeLists.txt
echo "SET_TARGET_PROPERTIES (graphite2 PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "ENDIF ()" >> CMakeLists.txt

sed -i "s|graphite2\${CMAKE_SHARED_LIBRARY_SUFFIX}|graphite2$DLLSUFFIX\${CMAKE_SHARED_LIBRARY_SUFFIX}|" tests/bittwiddling/CMakeLists.txt
sed -i "s|graphite2\${CMAKE_SHARED_LIBRARY_SUFFIX}|graphite2$DLLSUFFIX\${CMAKE_SHARED_LIBRARY_SUFFIX}|" tests/comparerenderer/CMakeLists.txt
sed -i "s|graphite2\${CMAKE_SHARED_LIBRARY_SUFFIX}|graphite2$DLLSUFFIX\${CMAKE_SHARED_LIBRARY_SUFFIX}|" tests/examples/CMakeLists.txt
sed -i "s|graphite2\${CMAKE_SHARED_LIBRARY_SUFFIX}|graphite2$DLLSUFFIX\${CMAKE_SHARED_LIBRARY_SUFFIX}|" tests/featuremap/CMakeLists.txt
sed -i "s|graphite2\${CMAKE_SHARED_LIBRARY_SUFFIX}|graphite2$DLLSUFFIX\${CMAKE_SHARED_LIBRARY_SUFFIX}|" tests/sparsetest/CMakeLists.txt
sed -i "s|graphite2\${CMAKE_SHARED_LIBRARY_SUFFIX}|graphite2$DLLSUFFIX\${CMAKE_SHARED_LIBRARY_SUFFIX}|" tests/utftest/CMakeLists.txt
sed -i "s|graphite2\${CMAKE_SHARED_LIBRARY_SUFFIX}|graphite2$DLLSUFFIX\${CMAKE_SHARED_LIBRARY_SUFFIX}|" tests/vm/CMakeLists.txt
sed -i "s|graphite2\${CMAKE_SHARED_LIBRARY_SUFFIX}|graphite2$DLLSUFFIX\${CMAKE_SHARED_LIBRARY_SUFFIX}|" gr2fonttest/CMakeLists.txt

mkdir MY_BUILD
cd MY_BUILD
xxrun cmake -G 'MSYS Makefiles' -DCMAKE_INSTALL_PREFIX=$OUT -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=OFF ..
xxrun make
xxrun make install
;;

# ----------------------------------------------------------------------------
lapack-*)
cd $WRKDIR/$PACK
mkdir MY_BUILD
cd MY_BUILD
xxrun cmake -G 'MSYS Makefiles' -DCMAKE_INSTALL_PREFIX=$OUT -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON -DBUILD_DEPRECATED=ON ..
xxrun make
xxrun make install

###hack needed for static build
sed -i 's,-lblas,-lblas -lgfortran -lquadmath,' $OUT/lib/pkgconfig/blas.pc
sed -i 's,-llapack,-llapack -lblas -lgfortran -lquadmath,' $OUT/lib/pkgconfig/lapack.pc
;;

# ----------------------------------------------------------------------------
szip-*)
cd $WRKDIR/$PACK

### old style (DLL library)
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes
patch_libtool
xxrun make
xxrun make install

# ### new style (static lib only)
# mkdir MY_BUILD
# cd MY_BUILD
# ##### cmake -G 'MSYS Makefiles' -DCMAKE_INSTALL_PREFIX=$OUT -DBUILD_SHARED_LIBS=OFF -DSZIP_ENABLE_ENCODING=ON ..
# xxrun cmake -G 'MSYS Makefiles' -DCMAKE_INSTALL_PREFIX=$OUT ..
# xxrun make
# xxrun make install
# ###hack
# cd ..
# cp -f src/ricehdf.h $OUT/include/ricehdf.h
# cp $OUT/lib/libszip-static.a $OUT/lib/libszip.a
;;

# ----------------------------------------------------------------------------
netcdf-*)
cd $WRKDIR/$PACK

###this is a hack
sed -i s/-ldf/-lhdf/ configure
sed -i 's/libnetcdf_la_LDFLAGS = /libnetcdf_la_LDFLAGS = -no-undefined /' liblib/Makefile.in

save_configure_help
CPPFLAGS=-I$OUTINC LDFLAGS=-L$OUTLIB xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes \
                        --enable-netcdf4 --enable-hdf4 --disable-dap  --disable-dynamic-loading
patch_libtool
xxrun make
xxrun make check
xxrun make install
;;

# ----------------------------------------------------------------------------
hdf5-*)
cd $WRKDIR/$PACK
echo "IF (BUILD_SHARED_LIBS)" >> CMakeLists.txt
echo "SET_TARGET_PROPERTIES (\${HDF5_LIBSH_TARGET}          PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "SET_TARGET_PROPERTIES (\${HDF5_CPP_LIBSH_TARGET}      PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "SET_TARGET_PROPERTIES (\${HDF5_HL_LIBSH_TARGET}       PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "SET_TARGET_PROPERTIES (\${HDF5_HL_CPP_LIBSH_TARGET}   PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "SET_TARGET_PROPERTIES (\${HDF5_TOOLS_LIBSH_TARGET}    PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "ENDIF ()" >> CMakeLists.txt
mkdir MY_BUILD
cd MY_BUILD
xxrun cmake -G 'MSYS Makefiles' -Wno-dev -DCMAKE_INSTALL_PREFIX=$OUT \
            -DBUILD_SHARED_LIBS=ON \
            -DBUILD_TESTING=OFF \
            -DCMAKE_BUILD_TYPE=Release \
            -DCMAKE_SKIP_RPATH=ON \
            -DHDF5_BUILD_HL_LIB=ON \
            -DHDF5_BUILD_CPP_LIB=ON \
            -DHDF5_BUILD_FORTRAN=OFF \
            -DHDF5_BUILD_TOOLS=ON \
            -DHDF5_ENABLE_DEPRECATED_SYMBOLS=ON \
            -DHDF5_ENABLE_Z_LIB_SUPPORT=ON \
            -DHDF5_ENABLE_SZIP_SUPPORT=ON \
            -DHDF5_ENABLE_SZIP_ENCODING=ON \
            -DSZIP_INCLUDE_DIR=$OUT/include \
            -DSZIP_LIBRARY=$OUT/lib/libsz.dll.a \
            ..

            ###-DHDF5_INSTALL_CMAKE_DIR="lib/cmake" \
            ###-DHDF5_INSTALL_DATA_DIR="share" \
            ###-DHAVE_IOEO_EXITCODE=1 \
            ###-DH5_LDOUBLE_TO_INTEGER_WORKS=1 \
            ###-DH5_ULONG_TO_FLOAT_ACCURATE=1 \
            ###-DH5_LDOUBLE_TO_UINT_ACCURATE=1 \
            ###-DH5_FP_TO_ULLONG_ACCURATE=1 \
            ###-DH5_ULLONG_TO_LDOUBLE_PRECISION=1 \
            ###-DH5_FP_TO_INTEGER_OVERFLOW_WORKS=1 \
            ###-DH5_LDOUBLE_TO_LLONG_ACCURATE=1 \
            ###-DH5_LLONG_TO_LDOUBLE_CORRECT=1 \
            ###-DH5_NO_ALIGNMENT_RESTRICTIONS=1 \

xxrun make
xxrun make install
;;

# ----------------------------------------------------------------------------
hdf-*)
cd $WRKDIR/$PACK
echo "IF (BUILD_SHARED_LIBS)" >> CMakeLists.txt
###new
echo "SET_TARGET_PROPERTIES (\${HDF4_SRC_LIBSH_TARGET}             PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "SET_TARGET_PROPERTIES (\${HDF4_MF_XDR_LIBSH_TARGET}          PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "SET_TARGET_PROPERTIES (\${HDF4_MF_LIBSH_TARGET}              PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "SET_TARGET_PROPERTIES (\${HDF4_MF_FCSTUB_LIBSH_TARGET}       PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "SET_TARGET_PROPERTIES (\${HDF4_MF_FORTRAN_LIBSH_TARGET}      PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "SET_TARGET_PROPERTIES (\${HDF4_SRC_FCSTUB_LIBSH_TARGET}      PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "SET_TARGET_PROPERTIES (\${HDF4_SRC_FORTRAN_LIBSH_TARGET}     PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
###old
#echo "SET_TARGET_PROPERTIES (\${HDF4_SRC_LIB_NAME} PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
#echo "SET_TARGET_PROPERTIES (\${HDF4_MF_XDR_LIB_TARGET} PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
#echo "SET_TARGET_PROPERTIES (\${HDF4_MF_LIB_TARGET} PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
#echo "SET_TARGET_PROPERTIES (\${HDF4_MF_FCSTUB_LIB_NAME} PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
#echo "SET_TARGET_PROPERTIES (\${HDF4_MF_FORTRAN_LIB_NAME} PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
#echo "SET_TARGET_PROPERTIES (\${HDF4_SRC_FCSTUB_LIB_NAME} PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
#echo "SET_TARGET_PROPERTIES (\${HDF4_SRC_FORTRAN_LIB_NAME} PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "ENDIF ()" >> CMakeLists.txt
mkdir MY_BUILD
cd MY_BUILD
cp ../COPYING.txt ./
xxrun cmake -G 'MSYS Makefiles' -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=$OUT \
                                                       -DBUILD_SHARED_LIBS=ON \
                                                       -DHDF4_BUILD_XDR_LIB=ON \
                                                       -DHDF4_ENABLE_SZIP_SUPPORT=ON \
                                                       -DHDF4_ENABLE_SZIP_ENCODING=ON \
                                                       -DHDF4_ENABLE_JPEG_LIB_SUPPORT=ON \
                                                       -DHDF4_ENABLE_Z_LIB_SUPPORT=ON \
                                                       -DHDF4_BUILD_FORTRAN=ON \
                                                       -DHDF4_BUILD_TOOLS=OFF \
                                                       -DHDF4_BUILD_UTILS=OFF \
                                                       -DHDF4_BUILD_EXAMPLES=OFF \
                                                       -DHDF4_NO_PACKAGES=ON \
                                                       -DHDF4_ENABLE_NETCDF=OFF \
                                                       -DSZIP_INCLUDE_DIR=$OUT/include \
                                                       -DSZIP_LIBRARY=$OUT/lib/libsz.dll.a \
                                                       ..
xxrun make
xxrun make install
# names:
# cp hdf_fcstub-shared.dll.a    libhdf_fcstub.dll.a
# cp hdf_fortran-shared.dll.a   libhdf_fortran.dll.a
# cp hdf-shared.dll.a           libhdf.dll.a
# cp mfhdf_fcstub-shared.dll.a  libmfhdf_fcstub.dll.a
# cp mfhdf_fortran-shared.dll.a libmfhdf_fortran.dll.a
# cp mfhdf-shared.dll.a         libmfhdf.dll.a
;;

# ----------------------------------------------------------------------------
proj-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes
patch_libtool
#patching Makefile
if [ ! -e src/Makefile.bakup ] ; then cp -p src/Makefile src/Makefile.bakup; fi
#xxx mutex needs to be commented out
sed -e "s/-DMUTEX_[a-z]*//g" src/Makefile.bakup > src/Makefile
xxrun make
xxrun make install
#XXX ugly hack
sed -i "s/PVALUE/PROJVALUE/" $OUT/include/projects.h
;;

# ----------------------------------------------------------------------------
plplot-*)
cd $WRKDIR/$PACK
find . -name CMakeLists.txt -exec sed -i "s/\(SOVERSION \${plplot\)/SUFFIX $DLLSUFFIX.dll \1/" {} \;
find . -name CMakeLists.txt -exec sed -i "s/\(SOVERSION \${csirocsa\)/SUFFIX $DLLSUFFIX.dll \1/" {} \;
find . -name CMakeLists.txt -exec sed -i "s/\(SOVERSION \${qsastime\)/SUFFIX $DLLSUFFIX.dll \1/" {} \;
xxrun cmake -G "MSYS Makefiles" -DCMAKE_INSTALL_PREFIX=$OUT \
                                -DBUILD_SHARED_LIBS=ON \
                                -DPLD_png=ON -DPLD_jpeg=ON -DPLD_gif=ON \
                                -DGD_LIBRARY=$OUT/lib/libgd.dll.a \
                                -DGD_INCLUDE_DIR=$OUT/include \
                                -DFREETYPE_LIBRARY=$OUT/lib/libfreetype.dll.a \
                                -DFREETYPE_INCLUDE_DIR=$OUT/include/freetype2 \
                                -DENABLE_DYNDRIVERS=OFF \
                                -DENABLE_f95=OFF \
                                -DENABLE_tcl=OFF \
                                -DENABLE_ada=OFF \
                                -DENABLE_d=OFF \
                                -DCMAKE_BUILD_TYPE=Release
xxrun make
xxrun make install
rm -rf $OUT/share/plplot*/examples
;;

# ----------------------------------------------------------------------------
pgplot-*)
cd $WRKDIR/$PACK
xxrun sh ./makemake . gnuwin32
xxrun make FCOMPL=gfortran
;;

# ----------------------------------------------------------------------------
jpeg-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make
xxrun make check
xxrun make install
;;

# ----------------------------------------------------------------------------
t1lib-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make without_doc
xxrun make install
;;

# ----------------------------------------------------------------------------
OLD_dmake-*)
cd $WRKDIR/$PACK
#hack: using mingw special build script
xxrun cmd.exe /c 'winnt\mingw\build.cmd'
mkdir -p $OUT/bin
cp -r ./output/* $OUT/bin/
echo "MAXLINELENGTH := 800000" > $OUT/bin/startup/local.mk
;;

# ----------------------------------------------------------------------------
dmake-*)
cd $WRKDIR/$PACK
save_configure_help
OLD_SHELL=$SHELL
unset SHELL
MSYSTEM=MINGW xxrun ./configure $HOSTBUILDTARGET --prefix=$OUT --disable-dependency-tracking
SHELL=$OLD_SHELL
xxrun make
xxrun make install
#mv $OUT/share/startup $OUT/bin
#echo -n "MAXLINELENGTH := 800000" > $OUT/bin/startup/local.mk
;;

# ----------------------------------------------------------------------------
patch-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking LDFLAGS="-static -static-libgcc -static-libstdc++"
xxrun make install
;;

# ----------------------------------------------------------------------------
pexports-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT
xxrun make install
;;

# ----------------------------------------------------------------------------
OLD_pexports-*)
cd $WRKDIR/$PACK
xxrun make all
#hack: there is no 'make install'
mkdir -p $OUT/bin
cp pexports.exe $OUT/bin/
;;

# ----------------------------------------------------------------------------
libidn2-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes
patch_libtool
xxrun make install
;;

# ----------------------------------------------------------------------------
##standard build - static libs only
qrencode-* | lzo-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=yes --enable-shared=no \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make install
;;

# ----------------------------------------------------------------------------
##standard build - dynamic libs only
rtmpdump-* | libidn-* | tidyp-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make install
;;

curl-*)
###--with-winssl           enable Windows native SSL/TLS
###--with-gssapi=DIR       Where to look for GSS-API
###--with-winidn=PATH      enable Windows native IDN
###--without-ca-bundle --without-random
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
                             --without-ca-bundle --without-random --enable-ipv6 --enable-sspi
patch_libtool
xxrun make install
;;

freeglut-3*)
cd $WRKDIR/$PACK
echo "IF (FREEGLUT_BUILD_SHARED_LIBS)" >> CMakeLists.txt
echo "SET_TARGET_PROPERTIES (freeglut PROPERTIES SUFFIX $DLLSUFFIX.dll)">> CMakeLists.txt
echo "ENDIF ()" >> CMakeLists.txt
xxrun cmake -G 'MSYS Makefiles' -DCMAKE_INSTALL_PREFIX=$OUT -DFREEGLUT_BUILD_SHARED_LIBS=ON -DFREEGLUT_BUILD_STATIC_LIBS=OFF
xxrun make
xxrun make install
#HACK: OpenGL wants lib/libglut.a not lib/libfreeglut.a
mv $OUT/lib/libfreeglut.dll.a $OUT/lib/libglut.a
sed -i 's/-lfreeglut/-lglut/' $OUT/lib/lib/pkgconfig/freeglut.pc
;;

giflib-*)
cd $WRKDIR/$PACK

sed -i "s/-\$(LIBMAJOR)\.dll/-\$(LIBMAJOR)${DLLSUFFIX}.dll/g" Makefile
sed -i "s/\$(MAKE) -C doc/#\$(MAKE) -C doc/g" Makefile
sed -i "s/diff -u/diff -wu/g" tests/makefile

xxrun make CC=gcc
xxrun make check
xxrun make PREFIX="$OUT" install
;;

# ----------------------------------------------------------------------------
tiff-* | freeglut-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes \
            CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make
xxrun make check
xxrun make install
;;

# ----------------------------------------------------------------------------
bzip2-*)
cd $WRKDIR/$PACK
### xxrun make -f Makefile.win-gcc NOPERL=1 PREFIX=$OUT DLLSUFFIX=$DLLSUFFIX clean install
### #remove static lib
### rm $OUTLIB/libbz2.a
xxrun autoreconf -fi
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes
sed -i "s/\$(DLLVER)\.dll/\$(DLLVER)$DLLSUFFIX.dll/g" Makefile
xxrun make
xxrun make install
;;

# ----------------------------------------------------------------------------
zlib-*)
cd $WRKDIR/$PACK
# ### new way
# sed -i "s/\(zlib PROPERTIES SUFFIX .*\)\.dll/\1$DLLSUFFIX.dll/" CMakeLists.txt
# xxrun cmake -G 'MSYS Makefiles' -DCMAKE_INSTALL_PREFIX=$OUT
# xxrun make
# xxrun make install
# mv $OUT/share/pkgconfig/zlib.pc $OUT/lib/pkgconfig/zlib.pc
# mv $OUT/lib/libzlib.dll.a $OUT/lib/libz.dll.a
# rm $OUT/lib/libzlibstatic.a

### old way
xxrun make -f win32/Makefile.gcc BINARY_PATH=$OUTBIN INCLUDE_PATH=$OUTINC LIBRARY_PATH=$OUTLIB SHAREDLIB=zlib1$DLLSUFFIX.dll SHARED_MODE=1 install
rm $OUTLIB/libz.a
;;

# ----------------------------------------------------------------------------
##build via custom Makefile.win-gcc
libXpm-* | libmikmod-*)
cd $WRKDIR/$PACK
xxrun make -f Makefile.win-gcc NOPERL=1 PREFIX=$OUT DLLSUFFIX=$DLLSUFFIX clean install
;;

# ----------------------------------------------------------------------------
ncurses-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --disable-libtool-lock \
--without-ada \
--with-cxx \
--enable-pc-files \
--disable-rpath \
--enable-colorfgbg \
--disable-symlinks \
--enable-warnings \
--enable-assertions \
--disable-home-terminfo \
--enable-database \
--enable-sp-funcs \
--enable-term-driver \
--enable-interop \
--enable-widec
patch_libtool
xxrun make
xxrun make install
;;

# ----------------------------------------------------------------------------
QuantLib-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --with-boost-include=$OUTINC --with-boost-lib=$OUTLIB --disable-dependency-tracking --disable-libtool-lock --enable-static=yes --enable-shared=yes
patch_libtool
xxrun make
xxrun make install
;;

# ----------------------------------------------------------------------------
boost_*)
cd $WRKDIR/$PACK
xxrun ./bootstrap.sh --prefix=$OUT
#link=shared,static
xxrun ./b2 toolset=gcc \
      variant=release \
      threading=multi \
      threadapi=win32 \
      link=shared,static \
      runtime-link=shared \
      pch=off \
      address-model=$ARCHBITS \
      --debug-configuration \
      --prefix=$OUT \
      -sICONV_PATH=$OUT \
      -sICONV_LINK="-L$OUT/lib -liconv" \
      -sNO_ZLIB \
      -sZLIB_BINARY=z \
      -sZLIB_INCLUDE=$OUT/include \
      -sZLIB_LIBPATH=$OUT/zlib \
      -d2 \
      --without-mpi \
      --without-python
mkdir -p $OUT/include $OUT/bin $OUT/lib
cp -Rf boost $OUT/include
cp -f stage/lib/*.a $OUT/lib
cp -f stage/lib/*.dll $OUT/bin
;;

# ----------------------------------------------------------------------------
ta-lib-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes
patch_libtool
xxrun make
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
libuv-*)
cd $WRKDIR/$PACK
./autogen.sh
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes
patch_libtool
xxrun make
xxrun make install
install_bats
;;

# ----------------------------------------------------------------------------
pcre-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-utf --enable-unicode-properties --disable-dependency-tracking --enable-static=no --enable-shared=yes
patch_libtool
xxrun make
xxrun make install
;;

# ----------------------------------------------------------------------------
fribidi-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes
patch_libtool
xxrun make
xxrun make install
mkdir -p $OUT/lib/pkgconfig/
[ -f $OUT/lib/pkgconfig/fribidi.pc ] || cp -f fribidi.pc $OUT/lib/pkgconfig/fribidi.pc
;;

# ----------------------------------------------------------------------------
libwebp-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes --enable-libwebpmux
patch_libtool
xxrun make
xxrun make install
;;

# ----------------------------------------------------------------------------
ffmpeg-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure --prefix=$OUT --target-os=mingw32 --arch=${XTARGET%%-*} \
                  --enable-gpl \
                  --enable-version3 \
                  --enable-runtime-cpudetect \
                  --enable-shared \
                  --enable-pic \
                  --disable-debug \
                  --disable-static \
                  --disable-doc
patch_libtool
xxrun make
xxrun make install
;;


# ----------------------------------------------------------------------------
termcap-*)
cd $WRKDIR/$PACK
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes
patch_libtool
xxrun make

# Build a shared library.  No need for -fPIC on Windows.
xxrun gcc -shared -Wl,--out-implib,libtermcap.dll.a -o libtermcap-0$DLLSUFFIX.dll termcap.o tparam.o version.o

xxrun make install prefix="$OUT" exec_prefix="$OUT" oldincludedir=
xxrun mkdir -p $OUT/{bin,lib}
xxrun install -m 0755 libtermcap-0$DLLSUFFIX.dll "$OUT/bin"
xxrun install -m 0644 libtermcap.dll.a "$OUT/lib"
;;

# ----------------------------------------------------------------------------
readline-*)
cd $WRKDIR/$PACK
save_configure_help

sed -i 's|-Wl,-rpath,$(libdir) ||g' support/shobj-conf
sed -i "s|SHLIB_LIBVERSION='\$(SHLIB_DLLVERSION)\.\$(SHLIB_LIBSUFF)'|SHLIB_LIBVERSION='\$(SHLIB_DLLVERSION)$DLLSUFFIX.\$(SHLIB_LIBSUFF)'|" support/shobj-conf

xxrun ./configure $HOSTBUILD --prefix=$OUT --enable-static=no --enable-shared=yes --without-curses \
                  "CFLAGS=-O2 -fcommon -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make
xxrun make install

mv $OUT/lib/libhistory*.dll.a  $OUT/lib/libhistory.dll.a
mv $OUT/lib/libreadline*.dll.a $OUT/lib/libreadline.dll.a

;;

# ----------------------------------------------------------------------------
gnuplot-4*)
cd $WRKDIR/$PACK
cd config/mingw
CFLAGS=-I$OUTINC LDFLAGS=-L$OUTLIB xxrun make console windows pipes support NEWGD=1 FREETYPE=1 PNG=1 JPEG=1 ICONV=1 HELPFILEJA= LUA= HHWPATH=/z/sw/help-workshop/ ARCHNICK=$ARCHNICK LBUFFEROVERFLOWU=$LBUFFEROVERFLOWU
xxrun make install DESTDIR=$OUT HELPFILEJA= LUA=
#builtin: emf svg postscript
#GD based: jpeg gif png
#platform-specific: windows
;;

# ----------------------------------------------------------------------------
gnuplot-5*)
cd $WRKDIR/$PACK

mv $OUT/bin/gdlib-config $OUT/bin/gdlib-config.OBSOLETE

autoreconf -fi
save_configure_help
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking \
                             --without-lua --with-bitmap-terminals

###--with-readline=gnu "CFLAGS=-I$OUTINC" "LDFLAGS=-L$OUTLIB"

xxrun make
xxrun make install
;;

# ----------------------------------------------------------------------------
cfitsio-*)
cd $WRKDIR/$PACK
xxrun cmake -G "MinGW Makefiles" -DWITH_ZLIB=system -DWITH_SSL=bundled -DCMAKE_INSTALL_PREFIX=$OUT -DCMAKE_MAKE_PROGRAM=gmake
xxrun make DLLSUFFIX=$DLLSUFFIX PREFIX=$OUT install
;;

# ----------------------------------------------------------------------------
##standard build - via ./configure
*)
echo "## !!!WARNING!!! using default build scenario"
cd $WRKDIR/$PACK
save_configure_help
#xxrun ./configure $HOSTBUILD --prefix=$OUT CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
xxrun ./configure $HOSTBUILD --prefix=$OUT --disable-dependency-tracking --enable-static=no --enable-shared=yes CFLAGS="-O2 -I$OUTINC -mms-bitfields" LDFLAGS="-L$OUTLIB"
patch_libtool
xxrun make
xxrun make install
;;

esac
(
  cd $OUT;
  touch $PACK.diff $PACK.list $PACK.srcinfo.json
  touch build.script.txt build.liblist.txt build.info.json build.sysinfo.txt
  find . -newer $OUT/_timestamp_ -not -type d | sort > $PACK.list
)
done

enable_pthread

echo "#### Packing results"
if [ -d $OUTZIP ] ; then
  mv $OUTZIP $OUTZIP.$$
  mkdir -p $OUTZIP
  mv $OUTZIP.$$/out_*.zip $OUTZIP
  rm -rf $OUTZIP.$$
else
  mkdir -p $OUTZIP
fi

echo "### creating a copy for patching"
rm -rf $OUTTMP
cp -r $OUT $OUTTMP

cd $OUTTMP
strip --strip-unneeded bin/*.dll 2>/dev/null
strip --strip-all bin/*.exe 2>/dev/null
strip --strip-debug lib/*.a 2>/dev/null
#ugly hack handling prefixes like 'z:/path/to/prefix/dir'
OUT2=`echo "$OUT"| sed -e "s!^/\([a-zA-Z]\)/!\1:/!"`
L=`find . -type f \( -name "*.la" -o -name "*.pc" -o -name "*.sh" -o -name "*-config" \) | xargs grep -l -i -e "$OUT" -e "$OUT2"`
patch_prefix $L
rm -f $OUTZIP/out_all_results.txt
for PACK in $PKGLIST; do
  echo "## compressing $PACK"
  rm -f $OUTZIP/out_$PACK.zip
  touch `cat $OUT/$PACK.list`

  #pack
  #tar -czf $OUTZIP/out_$PACK.tar.gz `cat $OUT/$PACK.list`
  zip -q -9 $OUTZIP/out_$PACK.zip -@ < $OUT/$PACK.list

  echo "$PACK" >> $OUTZIP/out_all_results.txt
  grep "^\#\#\#" $PACK.build.log >> $OUTZIP/out_all_results.txt
done
cd ..

rm -rf $OUTTMP

echo "###### [`date +%T`] BUILD FINISHED"

mkdir -p _out
( cd _out && ../pack.pl $WRKDIR $OUTZIP )

echo "###### [`date +%T`] PACKING FINISHED"
