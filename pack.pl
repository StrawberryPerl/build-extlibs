#!perl

use strict;
use warnings;

use JSON::PP 'decode_json';
use Archive::Zip qw( :ERROR_CODES :CONSTANTS );
use Data::Dumper;
use File::Temp;
use File::Spec;
use File::Find;
use File::Basename;

my $desc = {
  'fribidi-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS','README'],
    'licdir' => 'licenses\fribidi',
    'urls' => [
      ['Homepage', 'http://fribidi.org'],
    ],
  }, 
  'libwebp-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS','README'],
    'licdir' => 'licenses\libwebp',
    'urls' => [
      ['Homepage', 'https://developers.google.com/speed/webp'],
    ],
  }, 
  'patch-' => {
    'files' => [
      ['bin\patch.exe', 'c\bin\patch.exe'],
    ],
    'trees' => [],
    'licenses' => ['COPYING','AUTHORS','README'],
    'licdir' => 'licenses\patch',
    'urls' => [
      ['Homepage', 'http://savannah.gnu.org/projects/patch/'],
    ],
  }, 
  'pexports-' => {
    'files' => [
      ['bin\pexports.exe', 'c\bin\pexports.exe'],
    ],
    'trees' => [],
    'licenses' => ['COPYING','AUTHORS','README'],
    'licdir' => 'licenses\pexports',
    'urls' => [
      ['Homepage', 'https://sourceforge.net/projects/mingw/files/MinGW/Extension/pexports/'],
    ],
  }, 
  'dmake-' => {
    'files' => [
      ['bin\dmake.exe', 'c\bin\dmake.exe'],
    ],
    'trees' => [
      ['bin\startup', 'c\bin\startup', '.*'],
    ],
    'licenses' => ['COPYING','AUTHORS'],
    'licdir' => 'licenses\dmake',
    'urls' => [
      ['Homepage', 'http://code.google.com/a/apache-extras.org/p/dmake/'],
    ],
  }, 
  'db-' => {
    'files' => [
      ['include\db.h', 'c\include\db.h'],
      ['include\db_cxx.h', 'c\include\db_cxx.h'],
      ['lib\libdb-6.2.a', 'c\lib\libdb.a'], #XXX_FIXME hack!!!
    ],
    'trees' => [
      ['bin', 'c\bin', 'libdb-\d+\.\d+_*.dll$'], # e.g. libdb-6.2__.dll
    ],
    'licenses' => ['LICENSE'],
    'licdir' => 'licenses\libdb-BerkeleyDB',
    'urls' => [
      ['Homepage', 'http://www.oracle.com/technetwork/database/berkeleydb/downloads/index.html'],
    ],
  }, 
  'netcdf-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['include', 'c\include', '\.h$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['bin', 'c\bin', '\.dll$'],
    ],
    'licenses' => ['COPYRIGHT'],
    'licdir' => 'licenses\netfdf',
    'urls' => [
      ['Homepage', 'http://www.unidata.ucar.edu/software/netcdf/'],
    ],
  },
  'netcdf-c-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['include', 'c\include', '\.h$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['bin', 'c\bin', '\.dll$'],
    ],
    'licenses' => ['COPYRIGHT'],
    'licdir' => 'licenses\netfdf',
    'urls' => [
      ['Homepage', 'http://www.unidata.ucar.edu/software/netcdf/'],
    ],
  },
  'curl-' => {
    'files' => [
      ['bin\curl.exe', 'c\bin\curl.exe'],
    ],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['include', 'c\include', '\.h$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
    ],
    'licenses' => ['README', 'COPYING'],
    'licdir' => 'licenses\curl',
    'urls' => [
      ['Homepage', 'http://curl.haxx.se'],
    ],
  },
  'libuv-' => {
    'files' => [
    ],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['include', 'c\include', '\.h$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
    ],
    'licenses' => ['AUTHORS', 'LICENSE'],
    'licdir' => 'licenses\libuv',
    'urls' => [
      ['Homepage', 'http://www.libuv.org'],
    ],
  },
  'ncurses-' => {
    'files' => [
      ###XXX['lib\libncurses.a', 'c\lib\libncurses.a'],
    ],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['include', 'c\include', '\.h$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
    ],
    'licenses' => ['AUTHORS'],
    'licdir' => 'licenses\ncurses',
    'urls' => [
      ['Homepage', 'http://www.gnu.org/software/ncurses/'],
    ],
  },
  'tidyp-' => {
    'files' => [
      ['bin\tidyp.exe', 'c\bin\tidyp.exe'],
      ['lib\libtidyp.a', 'c\lib\libtidyp.a'],
    ],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['README'],
    'licdir' => 'licenses\libtidyp',
    'urls' => [
      ['Homepage', 'http://tidyp.com'],
    ],
  }, 
  'mpfr-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS','README'],
    'licdir' => 'licenses\libmpfr',
    'urls' => [
      ['Homepage', 'http://www.mpfr.org/'],
    ],
  }, 
  'mpc-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING.LESSER','AUTHORS','README'],
    'licdir' => 'licenses\libmpc',
    'urls' => [
      ['Homepage', 'http://www.multiprecision.org/'],
    ],
  }, 
  'libffi-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['LICENSE'],
    'licdir' => 'licenses\libffi',
    'urls' => [
      ['Homepage', 'http://sourceware.org/libffi/'],
    ],
  }, 
  'ta-lib-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['bsd.txt'],
    'licdir' => 'licenses\ta-lib',
    'urls' => [
      ['Homepage', 'http://ta-lib.org/'],
    ],
  }, 
  'freeglut-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS'],
    'licdir' => 'licenses\libfreeglut',
    'urls' => [
      ['Homepage', 'http://freeglut.sourceforge.net/'],
    ],
  }, 
  'freetype-' => {
    'files' => [
    ],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['docs\LICENSE.TXT', 'docs\GPLv2.TXT', 'docs\FTL.TXT'],
    'licdir' => 'licenses\libfreetype',
    'urls' => [
      ['Homepage', 'http://www.freetype.org/'],
    ],
  }, 
  'gd-' => {
    'files' => [
    ],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING'],
    'licdir' => 'licenses\libgd',
    'urls' => [
      ['Homepage', 'http://www.libgd.org/'],
    ],
  }, 
  'libgd-' => {
    'files' => [
    ],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING'],
    'licdir' => 'licenses\libgd',
    'urls' => [
      ['Homepage', 'http://www.libgd.org/'],
    ],
  }, 
  'gdbm-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING'],
    'licdir' => 'licenses\libgdbm',
    'urls' => [
      ['Homepage', 'http://www.gnu.org/software/gdbm/'],
    ],
  }, 
  't1lib-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['LICENSE','LGPL'],
    'licdir' => 'licenses\libt1',
    'urls' => [
      ['Homepage', 'http://www.t1lib.org/'],
    ],
  },
  'giflib-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','README'],
    'licdir' => 'licenses\libgif',
    'urls' => [
      ['Homepage', 'http://giflib.sourceforge.net/'],
    ],
  }, 
  'libunistring-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS'],
    'licdir' => 'licenses\libunistring',
    'urls' => [
      ['Homepage', 'https://www.gnu.org/software/libunistring/'],
    ],
  },
  'libidn2-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS'],
    'licdir' => 'licenses\libidn2',
    'urls' => [
      ['Homepage', 'http://www.gnu.org/software/libidn/'],
    ],
  },
  'libidn-' => {
    'files' => [
      #['bin\idn.exe', 'c\bin\idn.exe'],
    ],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS'],
    'licdir' => 'licenses\libidn',
    'urls' => [
      ['Homepage', 'http://www.gnu.org/software/libidn/'],
    ],
  },
  'libiconv-' => {
    'files' => [
      ['bin\iconv.exe', 'c\bin\iconv.exe'],
    ],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS'],
    'licdir' => 'licenses\libiconv',
    'urls' => [
      ['Homepage', 'http://www.gnu.org/software/libiconv/'],
    ],
  }, 
  'jpeg-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['README'],
    'licdir' => 'licenses\libjpeg',
    'urls' => [
      ['Homepage', 'http://www.ijg.org/'],
    ],
  },
  'libjpeg-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['README'],
    'licdir' => 'licenses\libjpeg',
    'urls' => [
      ['Homepage', 'http://www.ijg.org/'],
    ],
  },
  'openssl111-' => {
    'files' => [
      ['bin\openssl.exe', 'c\bin\openssl.exe'],
      ['lib\libcrypto.dll.a', 'c\lib\libcrypto.a'],
      ['lib\libssl.dll.a', 'c\lib\libssl.a'],
    ],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['lib\engines-1_1', 'c\lib\engines-1_1', '\.dll$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['LICENSE'],
    'licdir' => 'licenses\openssl',
    'urls' => [
      ['Homepage', 'http://www.openssl.org/'],
    ],
  },
  'openssl11-' => {
    'files' => [
      ['bin\openssl.exe', 'c\bin\openssl.exe'],
      ['lib\libcrypto.dll.a', 'c\lib\libcrypto.a'],
      ['lib\libssl.dll.a', 'c\lib\libssl.a'],
    ],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['LICENSE'],
    'licdir' => 'licenses\openssl',
    'urls' => [
      ['Homepage', 'http://www.openssl.org/'],
    ],
  },
  'openssl-' => {
    'files' => [
      ['bin\openssl.exe', 'c\bin\openssl.exe'],
      ['lib\libcrypto.dll.a', 'c\lib\libeay32.a'],
      ['lib\libssl.dll.a', 'c\lib\libssl32.a'],
      ['lib\libssl.dll.a', 'c\lib\libssleay32.a'],
    ],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
      ['ssl', 'c\ssl'],
    ],
    'licenses' => ['LICENSE'],
    'licdir' => 'licenses\openssl',
    'urls' => [
      ['Homepage', 'http://www.openssl.org/'],
    ],
  }, 
  'gnuplot-' => {
    'files' => [
      ['bin\wgnuplot.mnu', 'c\bin\wgnuplot.mnu'],
      ['bin\wgnuplot.exe', 'c\bin\wgnuplot.exe'],
      ['bin\gnuplot.exe', 'c\bin\gnuplot.exe'],
    ],
    'trees' => [],
    'licenses' => ['README', 'Copyright'],
    'licdir' => 'licenses\gnuplot',
    'urls' => [
      ['Homepage', 'http://gnuplot.sourceforge.net/'],
    ],
  }, 
  'libpng-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['LICENSE'],
    'licdir' => 'licenses\libpng',
    'urls' => [
      ['Homepage', 'http://www.libpng.org/pub/png/libpng.html'],
    ],
  }, 
  'libsodium-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => [qw/LICENSE AUTHORS/],
    'licdir' => 'licenses\libsodium',
    'urls' => [
      ['Homepage', 'https://github.com/jedisct1/libsodium'],
    ],
  },
  'harfbuzz-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => [qw/COPYING AUTHORS/],
    'licdir' => 'licenses\harfbuzz',
    'urls' => [
      ['Homepage', 'http://harfbuzz.org'],
    ],
  },
  'graphite2-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => [qw/COPYING LICENSE/],
    'licdir' => 'licenses\graphite2',
    'urls' => [
      ['Homepage', 'https://graphite.sil.org/'],
    ],
  },
  'termcap-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => [qw/COPYING/],
    'licdir' => 'licenses\termcap',
    'urls' => [
      ['Homepage', 'https://www.gnu.org/software/termutils/manual/termcap-1.3/termcap.html'],
    ],
  },
  'readline-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => [qw/COPYING/],
    'licdir' => 'licenses\readline',
    'urls' => [
      ['Homepage', 'https://tiswww.case.edu/php/chet/readline/rltop.html'],
    ],
  },
  'libssh2-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => [qw/COPYING/],
    'licdir' => 'licenses\libssh2',
    'urls' => [
      ['Homepage', 'http://www.libssh2.org'],
    ],
  }, 
  'xz-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => [qw/AUTHORS COPYING THANKS COPYING.LGPLv2.1 COPYING.GPLv2 COPYING.GPLv3/],
    'licdir' => 'licenses\libxz',
    'urls' => [
      ['Homepage', 'http://tukaani.org/xz/'],
    ],
  }, 
  'postgresql-' => {
    'files' => [
      ['bin\pg_config.exe', 'c\bin\pg_config.exe'],
      ['lib\libpq.a', 'c\lib\libpq.a'], #cannot use wildcard
    ],
    'trees' => [
      #['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\bin', '\.dll$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYRIGHT'],
    'licdir' => 'licenses\postgresql',
    'urls' => [
      ['Homepage', 'http://www.postgresql.org/'],
    ],
  }, 
  'tiff-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.(h|hxx)$'],
    ],
    'licenses' => ['COPYRIGHT'],
    'licdir' => 'licenses\libtiff',
    'urls' => [
      ['Homepage', 'http://remotesensing.org/libtiff/'],
    ],
  }, 
  'libxml2-' => {
    'files' => [
      ['bin\xmlcatalog.exe', 'c\bin\xmlcatalog.exe'],
      ['bin\xmllint.exe', 'c\bin\xmllint.exe'],
    ],
    'trees' => [
      ['include\libxml2', 'c\include', '\.h$'],  ## ugly hack (historical reasons) - see go-build.sh
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
    ],
    'licenses' => ['COPYING','AUTHORS'],
    'licdir' => 'licenses\libxml2',
    'urls' => [
      ['Homepage', 'http://xmlsoft.org/'],
    ],
  }, 
  'libxslt-' => {
    'files' => [
      ['bin\xsltproc.exe', 'c\bin\xsltproc.exe'],
    ],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS'],
    'licdir' => 'licenses\libxslt',
    'urls' => [
      ['Homepage', 'http://xmlsoft.org/XSLT/'],
    ],
  }, 
  'zlib-' => {
    'files' => [
      ['lib\libz.dll.a', 'c\lib\libz.a'],
      ['lib\libz.dll.a', 'c\lib\libzdll.a'],
      ['lib\libz.dll.a', 'c\lib\libzlib.a'],
    ],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['README'],
    'licdir' => 'licenses\libzlib',
    'urls' => [
      ['Homepage', 'http://www.zlib.net/'],
    ],
  }, 
  'bzip2-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['LICENSE','README'],
    'licdir' => 'licenses\libbzip2',
    'urls' => [
      ['Homepage', 'http://bzip.org/'],
    ],
  }, 
  'lzo-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['AUTHORS','COPYING'],
    'licdir' => 'licenses\liblzo',
    'urls' => [
      ['Homepage', 'http://www.oberhumer.com/opensource/lzo/'],
    ],
  }, 
  'libXpm-' => {
    'files' => [
      ['lib\libXpm.dll.a', 'c\lib\libXpm.a'],
    ],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS'],
    'licdir' => 'licenses\libxpm',
    'urls' => [
      ['Homepage', 'http://www.freedesktop.org/wiki/Software/xlibs'],
    ],
  },
  'gmp-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS','README'],
    'licdir' => 'licenses\libgmp',
    'urls' => [
      ['Homepage', 'http://gmplib.org/'],
    ],
  }, 
  'gsl-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS','README'],
    'licdir' => 'licenses\libgsl',
    'urls' => [
      ['Homepage', 'http://www.gnu.org/software/gsl/'],
    ],
  }, 
  'glpk-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS','README'],
    'licdir' => 'licenses\libglpk',
    'urls' => [
      ['Homepage', 'http://www.gnu.org/software/glpk/'],
    ],
  }, 
  'fftw-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.(h|f.*)$'],
    ],
    'licenses' => ['COPYING','AUTHORS','README'],
    'licdir' => 'licenses\libfftw',
    'urls' => [
      ['Homepage', 'http://www.fftw.org/'],
    ],
  },
  'fftw2-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS','README'],
    'licdir' => 'licenses\libfftw2',
    'urls' => [
      ['Homepage', 'http://www.fftw.org/'],
    ],
  },
  'lapack-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['LICENSE'],
    'licdir' => 'licenses\liblapack',
    'urls' => [
      ['Homepage', 'http://www.netlib.org/lapack/'],
    ],
  },
  'szip-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','README'],
    'licdir' => 'licenses\libszip',
    'urls' => [
      ['Homepage', 'http://www.hdfgroup.org/doc_resource/SZIP/'],
    ],
  },
  'hdf5-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','README.txt'],
    'licdir' => 'licenses\libhdf5',
    'urls' => [
      ['Homepage', 'http://www.hdfgroup.org/HDF5/'],
    ],
  },
  'hdf-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.(h|inc)$'],
    ],
    'licenses' => ['COPYING','README.txt'],
    'licdir' => 'licenses\libhdf',
    'urls' => [
      ['Homepage', 'http://www.hdfgroup.org/products/hdf4/'],
    ],
  },
  'plplot-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['share\plplot*', 'c\share\plplot', '\.\w+$'],
      #['lib\plplot*\driversd', 'c\share\plplot', '\.driver_info$'],
      #['lib\plplot*\driversd', 'c\bin', '\.dll$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING.LIB','AUTHORS','README'],
    'licdir' => 'licenses\libplplot',
    'urls' => [
      ['Homepage', 'http://plplot.sourceforge.net/'],
    ],
  },  
  'proj-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['bin', 'c\bin', '\.exe$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS','README'],
    'licdir' => 'licenses\libproj',
    'urls' => [
      ['Homepage', 'http://trac.osgeo.org/proj/'],
    ],
  },  
  'fontconfig-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','AUTHORS'],
    'licdir' => 'licenses\libfontconfig',
    'urls' => [
      ['Homepage', 'http://www.fontconfig.org/'],
    ],
  }, 
  'qrencode-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING','README'],
    'licdir' => 'licenses\libqrencode',
    'urls' => [
      ['Homepage', 'http://megaui.net/fukuchi/works/qrencode/index.en.html'],
    ],
  }, 
  'expat-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['COPYING'],
    'licdir' => 'licenses\libexpat',
    'urls' => [
      ['Homepage', 'http://expat.sourceforge.net/'],
    ],
  },
  'uv-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => ['LICENSE','AUTHORS'],
    'licdir' => 'licenses\libuv',
    'urls' => [
      ['Homepage', 'https://github.com/joyent/libuv'],
    ],
  },
  'ffmpeg-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['bin', 'c\bin', '\.exe$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => [qw/COPYING.GPLv2 COPYING.GPLv3 COPYING.LGPLv3 COPYING.LGPLv2.1 CREDITS LICENSE.md README.md /],
    'licdir' => 'licenses\libffmpeg',
    'urls' => [
      ['Homepage', 'https://www.ffmpeg.org'],
    ],
  }, 
  'cfitsio-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '\.dll$'],
      ['bin', 'c\bin', '(fitscopy|fpack|funpack|imcopy)\.exe$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.h$'],
    ],
    'licenses' => [qw(License.txt README)],
    'licdir' => 'licenses\libcfitsio',
    'urls' => [
      ['Homepage', 'http://heasarc.gsfc.nasa.gov/fitsio/'],
    ],
  }, 
  'libcaca-' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      #['bin', 'c\bin', '\.exe$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.(h|hxx|inc)$'],
    ],
    'licenses' => [qw/AUTHORS COPYING COPYING.GPL COPYING.ISC COPYING.LGPL/],
    'licdir' => 'licenses\libcaca',
    'urls' => [
      ['Homepage', 'http://caca.zoy.org/wiki/libcaca'],
    ],
  }, 
  'libcerf-' => {
    'files' => [],
    'trees' => [
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.(h|hxx|inc)$'],
    ],
    'licenses' => [qw/COPYING README/],
    'licdir' => 'licenses\libcerf',
    'urls' => [
      ['Homepage', 'http://apps.jcns.fz-juelich.de/libcerf'],
    ],
  }, 
  '_default_' => {
    'files' => [],
    'trees' => [
      ['bin', 'c\bin', '-config(\.bat)?$'],
      ['bin', 'c\bin', '\.dll$'],
      ['bin', 'c\bin', '\.exe$'],
      ['lib', 'c\lib', '\.a$'],
      ['lib\pkgconfig', 'c\lib\pkgconfig', '\.pc$'],
      ['include', 'c\include', '\.(h|hxx|inc)$'],
    ],
  }, 

};  

sub prepare_pack {
  my ($pkgzip, $pkgsrc, $datestamp, $deschash) = @_;
  
  my ($sinfo) = $pkgzip->membersMatching('.*\.srcinfo\.json$');
  my $sihash = decode_json($pkgzip->contents($sinfo));
  my ($binfo) = $pkgzip->memberNamed('build.info.json');
  my $bihash = decode_json($pkgzip->contents($binfo));
  
  warn "GONNA PACK: $sihash->{pack} url=", ($sihash->{url}||'n.a.'), "\n";
  my $srcroot = $pkgsrc;
  
  my $jobname = $sihash->{pack};
  $jobname =~ s/-\d.*$/-/g;
  $jobname = 'fftw2-' if $sihash->{pack} =~ /^fftw-2/; #hack
  $jobname = 'gd-' if $sihash->{pack} =~ /^gd-HG/i;    #hack
  $jobname = 'libuv-' if $sihash->{pack} =~ /^libuv-v/i;   #hack
  $jobname = 'openssl11-' if $sihash->{pack} =~ /^openssl-1\.1\.0/i;   #hack
  $jobname = 'openssl111-' if $sihash->{pack} =~ /^openssl-1\.1\.1/i;   #hack
  my $pkghash = $deschash->{$jobname};
  if (! defined $pkghash) {
    warn "###warning### Missing definition for '$jobname' (using default)\n";
    $pkghash = $deschash->{_default_};
  }
  
  my $tmpsrcdir = File::Temp->newdir( "tmp".$sihash->{pack}."_src_XXXX", DIR => '.', CLEANUP => 1 );
  my $tmpbindir = File::Temp->newdir( "tmp".$sihash->{pack}."_out_XXXX", DIR => '.', CLEANUP => 1 );
  my $binroot = $tmpbindir->dirname;
  $pkgzip->extractTree(undef, "$binroot/");
  
  # hack: *.dll.a => *.a
  if ($sihash->{pack} !~ /^(zlib|openssl|libXpm)-/) {
    my @afiles;
    find({ wanted => sub {push @afiles, $File::Find::name if $File::Find::name =~ /\.a$/}, follow => 1 }, $binroot);
    for my $a (@afiles) {
      if ($a =~ /^(.*?)\.dll\.a$/) {
        my $newa = "$1.a";
        if (-f $a && -f $newa) {
          warn "###warning### REPLACING '$newa' with '$a' !!!\n";
	  unlink $newa;
	  rename $a, $newa;
        }
        else {
          rename $a, $newa;
        }
      }
    }
  }
  
  # Create a Zip file
  my $zipname = sprintf "%s_%s-bin_%s.zip", $bihash->{architecture}, $sihash->{pack}, $datestamp;   
  #warn "GONNA CREATE: '$zipname'\n";
  my $zip = Archive::Zip->new();
    
  # Process 'files'
  my $pf = $pkghash->{'files'};
  warn "[debug] >>>>>>> files not defined\n" unless defined $pf;
  foreach my $i (@$pf) {
    my $src = $i->[0];
    $src = $binroot . '/' . $src if $binroot;
    $src =~ s/\\/\//g;
    $src = [glob($src)]->[0] if $src =~ /\*/;
    my $dst = $i->[1];
    $dst =~ s/\\/\//g;
    warn "non-existing file '$src'\n" unless -f $src;
    my $f = eval { $zip->addFile($src, $dst) };
    if($f) {    
      #warn "  added(file): '$src'#'$i->[1]'\n";
      $f->desiredCompressionLevel(9);
      $f->unixFileAttributes(0777) if $dst =~ /\.(exe|bat|dll)$/i; # necessary for correct unzipping on cygwin
    }
    else {
      warn "  ###error###: cannot add(file) '$src'>'$dst' # '$i->[1]'! $@\n";
      sleep 60;
    }
  };
  
  # Process 'trees'
  my $pt = $pkghash->{'trees'};
  warn "[debug] >>>>>>> trees not defined\n" unless defined $pt;
  foreach my $i (@$pt) {
    my $src = $i->[0];
    $src = $binroot . '/' . $src if $binroot;
    $src =~ s/\\/\//g;
    $src = [glob($src)]->[0] if $src =~ /\*/;
    my $dst = $i->[1];
    $dst =~ s/\\/\//g;  
    my $f = $zip->addTreeMatching($src, $dst, defined $i->[2] ? $i->[2] : '.*');
    if($f == AZ_OK) {    
      #warn "  added(tree): '$src'#'$i->[1]'#'$i->[2]'\n";
    }
    else {
      warn "  ###error###: cannot add(tree) '$src'#'$i->[1]'#'$i->[2]'\n";
    }
  };

  # Process 'licenses'
  my $pl = $pkghash->{'licenses'};
  warn "[debug] >>>>>>> licenses not defined\n" unless defined $pl;
  foreach my $s (@$pl) {
    #warn "[debug] gona add license src1='$src'\n";
    my $src = $srcroot . '/' . $s if $srcroot;
    my $file = $src;
    $file =~ s/^.*?([^\/\\]*)$/$1/;
    my $dst = $deschash->{$jobname}->{'licdir'} . '/' . $file;
    $src =~ s/\\/\//g;
    $dst =~ s/\\/\//g;
    my $f = eval { $zip->addFile($src, $dst) };
    if($f) {    
      #warn "  added(license): '$src'\n";
      $f->desiredCompressionLevel(9);
    }
    else {
      warn "  ###error###: cannot add(license) '$src'!\n";
    }
  };
  
  my $diff = "$binroot/$sihash->{pack}.diff";
  my $custom_patch;
  if (-f $diff && -s $diff > 0) {
    $custom_patch = basename($diff);
    my $dst = $deschash->{$jobname}->{'licdir'} . '/' . $custom_patch;
    my $f = eval { $zip->addFile($diff, $dst) };
    if($f) {    
      $f->desiredCompressionLevel(9);
    }
    else {
      warn "  ###error###: cannot add(patch) '$diff'!\n";
    }
  }

  # Process 'urls'
  open my $html_log, ">>", "pack_links_log.html";
  my $urlinfo="Package: $sihash->{pack}\n";
  if ($sihash->{url}) {
    $urlinfo .= "Sources: $sihash->{url}\n";    
    print $html_log "$sihash->{pack} - Sources: <a href=\"$sihash->{url}\">$sihash->{url}</a><p>\n"
  }
  else {
    warn "###error### URL for srctarball not defined\n";
  }
  if ($custom_patch) {
    $urlinfo .= "Patch: $custom_patch\n";
  }
  my $pu = $pkghash->{'urls'};
  warn "[debug] >>>>>>> urls not defined\n" unless defined $pu;
  foreach my $i (@$pu) {
    $urlinfo .= "$i->[0]: $i->[1]\n";
    print $html_log "$sihash->{pack} - $i->[0]: <a href=\"$i->[1]\">$i->[1]</a><p>\n"
  };
  
  if ($deschash->{$jobname}->{'licdir'}) {
    my $dst = $deschash->{$jobname}->{'licdir'}.'/_INFO_';
    $dst =~ s/\\/\//g;
    $zip->addString( $urlinfo, $dst );
  }
  else {
    warn "[debug] >>>>>>> no INFO created\n";
  }

  # Save the Zip file
  die 'ZIP write error' unless ( $zip->writeToFileNamed($zipname) == AZ_OK );
  #warn "FINISHED: '$zipname'\n";
  warn "FINISHED\n";
}

### main ###

my ($sec,$min,$hour,$day,$month,$yr19,@rest) =   localtime(time);
my $date = sprintf("%04d%02d%02d",($yr19+1900),($month+1),$day);
warn "ARGS: 0=$ARGV[0]\n" if defined $ARGV[0];
warn "ARGS: 1=$ARGV[1]\n" if defined $ARGV[1];

my $srcprefix = $ARGV[0] || '_wrk_buildtest_';
my $outprefix;
$srcprefix =~ s|/+$||; # strip trailing /
if ($srcprefix =~ /^(.*?)\.src$/) {
  $outprefix = "$1.patched";
}
else {
  $outprefix = "$srcprefix.patched";
  $srcprefix = "$srcprefix.src";
}

die "###error### directory '$srcprefix' does not exists\n" unless -d $srcprefix;
die "###error### directory '$outprefix' does not exists\n" unless -d $outprefix;

my @pkglist = glob("$outprefix/out_*.zip");
warn "###error###: No files matching '$outprefix/out_*.zip'\n" unless @pkglist;

unlink "pack_links_log.html";

foreach my $pzip (@pkglist) {
  warn "\n";
  warn "Processing '$pzip'\n";
  my $zip = Archive::Zip->new();
  if ( $zip->read( $pzip ) == AZ_OK ) {
    my ($sinfo) = $zip->membersMatching( '.*\.srcinfo\.json$' );
    my $sihash = decode_json($zip->contents($sinfo));
    my $p = $sihash->{pack};
    if (-d "$srcprefix/$p/") {
      prepare_pack ( $zip, "$srcprefix/$p/", $date, $desc );
    }
    else {
      warn "###error###: Directory '$srcprefix/$p/' does not exist!!!\n";
    }
  }
  else {
    warn "###error###: Cannot open '$zip'\n";
  }
}
