@if not exist config.h copy config.h.W32 config.h 
@cd w32\subproc 
gcc -mthreads -Wall -O2 -I.. -I. -I../include -I../.. -DWINDOWS32 -c misc.c -o ../../w32_misc.o
gcc -mthreads -Wall -O2 -I.. -I. -I../include -I../.. -DWINDOWS32 -c sub_proc.c -o ../../sub_proc.o
gcc -mthreads -Wall -O2 -I.. -I. -I../include -I../.. -DWINDOWS32 -c w32err.c -o ../../w32err.o
@cd ..\..
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c variable.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c rule.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c remote-stub.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c commands.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c file.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c getloadavg.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c default.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c signame.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c expand.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c dir.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c main.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c getopt1.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c job.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c read.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c version.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c getopt.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c arscan.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c remake.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c hash.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c strcache.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c misc.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c ar.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c function.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c vpath.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c implicit.c
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c ./glob/glob.c -o glob.o
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c ./glob/fnmatch.c -o fnmatch.o
gcc -mthreads -Wall -O2 -I. -I./glob -I./w32/include -DWINDOWS32 -DHAVE_CONFIG_H -c ./w32/pathstuff.c -o pathstuff.o
gcc -mthreads -o gnumake.exe variable.o rule.o remote-stub.o commands.o file.o getloadavg.o default.o signame.o expand.o dir.o main.o getopt1.o job.o read.o version.o getopt.o arscan.o remake.o misc.o hash.o strcache.o ar.o function.o vpath.o implicit.o glob.o fnmatch.o pathstuff.o w32_misc.o sub_proc.o w32err.o -lkernel32 -luser32 -lgdi32 -lwinspool -lcomdlg32 -ladvapi32 -lshell32 -lole32 -loleaut32 -luuid -lodbc32 -lodbccp32
