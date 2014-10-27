@set SRCDIR=.\src\patch\2.5.9\patch-2.5.9-src
@if not exist config.h copy %SRCDIR%\..\patch-2.5.9\config.h .
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\error.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\addext.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\argmatch.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\backupfile.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\basename.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\dirname.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\getopt.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\getopt1.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\inp.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\maketime.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\partime.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\patch.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\pch.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\quote.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\quotearg.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\quotesys.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\util.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\version.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\xmalloc.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\hash.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\./pc/pc_quote.c
gcc -c -DHAVE_CONFIG_H -Ded_PROGRAM=\"ed\" -I. -I %SRCDIR% -O2 %SRCDIR%\nonposix.c
gcc -o patch.exe -g -O2 -Wl,--major-image-version=2 -Wl,--minor-image-version=5 error.o addext.o argmatch.o backupfile.o basename.o dirname.o getopt.o getopt1.o inp.o maketime.o partime.o patch.o pch.o quote.o quotearg.o quotesys.o util.o version.o xmalloc.o hash.o pc_quote.o nonposix.o
