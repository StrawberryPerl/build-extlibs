@echo off
rem simplified replacement for the original shell script
set ROOT=%~dp0

set XCFLAGS=-I"%ROOT%..\include\smpeg" -I"%ROOT%..\include\SDL" -D_GNU_SOURCE=1 -Dmain=SDL_main
set XLIBS=-L"%ROOT%..\lib" -lsmpeg -lSDLmain -lSDL
set XVERSION=0.4.5
set XPREFIX=%ROOT%..\

for %%p in (%*) do (
  if x%%p == x--cflags     echo %XCFLAGS%
  if x%%p == x--libs       echo %XLIBS%
  if x%%p == x--version    echo %XVERSION%
  if x%%p == x--prefix     echo %XPREFIX%
) 
