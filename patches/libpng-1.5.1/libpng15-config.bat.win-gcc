@echo off
rem simplified replacement for the original shell script
set ROOT=%~dp0

set XCFLAGS=-I"%ROOT%..\include\libpng15"
set XLIBDIR=%ROOT%..\lib\
set XLDFLAGS=-L"%ROOT%..\lib" -lpng15
set XLIBS=-lpng15
set XPREFIX=%ROOT%..\

for %%p in (%*) do (
  if x%%p == x--cflags  echo %XCFLAGS%
  if x%%p == x--libs    echo %XLIBS%
  if x%%p == x--prefix  echo %XPREFIX%
  if x%%p == x--libdir  echo %XLIBDIR% 
  if x%%p == x--ldflags echo %XLDFLAGS%
)
