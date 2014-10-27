@echo off
rem simplified replacement for the original shell script
set ROOT=%~dp0

set XCFLAGS=-I"%ROOT%..\include\freetype2"
set XLIBS=-L"%ROOT%..\lib" -lfreetype -lz
set XVERSION=2.4.4
set XPREFIX=%ROOT%..\

for %%p in (%*) do (
  if x%%p == x--cflags     echo %XCFLAGS%
  if x%%p == x--libs       echo %XLIBS%
  if x%%p == x--version    echo %XVERSION%
  if x%%p == x--prefix     echo %XPREFIX% 
)
