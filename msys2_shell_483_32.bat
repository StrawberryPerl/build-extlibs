@echo off
set GCCDIR=z:\mingw32bit.483
set CMAKE=z:\sw\cmake
set PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%GCCDIR%\bin;%CMAKE%\bin
z:\msys64\msys2_shell.cmd -use-full-path