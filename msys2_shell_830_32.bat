@echo off
set GCCDIR=z:\mingw32bit.830
set CMAKEBIN=z:\sw\cmake\bin
set NASMBIN=z:\sw\nasm
set PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%GCCDIR%\bin;%CMAKEBIN%;%NASMBIN%
z:\msys64\msys2_shell.cmd -use-full-path