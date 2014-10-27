@echo off

set MYVER=5.5.11
set BUILDDATE=20110503

rem set TOOLBIN64=%~dp0..\w64gcc4\bin
rem set TOOLBIN32=%~dp0..\w32gcc4\bin
set TOOLBIN64=z:\myperl64\c\bin
set TOOLBIN32=z:\myperl32\c\bin

PATH=%SystemRoot%\system32;%SystemRoot%;%SystemRoot%\System32\Wbem;%~dp0\..\bin

echo ########### download ########### 
wget -nc http://mysql.mirrors.ovh.net/ftp.mysql.com/Downloads/MySQL-5.5/mysql-5.5.11-win32.zip
wget -nc http://mysql.mirrors.ovh.net/ftp.mysql.com/Downloads/MySQL-5.5/mysql-5.5.11-winx64.zip

echo ########### unpack ########### 
if exist mysql-%MYVER%-win32\nul goto NEXT1
rem rmdir /S/Q mysql-%MYVER%-win32 2>nul
7za x -y mysql-%MYVER%-win32.zip
:NEXT1

if exist mysql-%MYVER%-winx64\nul goto NEXT2
rem rmdir /S/Q mysql-%MYVER%-winx64 2>nul
7za x -y mysql-%MYVER%-winx64.zip
:NEXT2

echo ########### 32bit ########### 
set MDSTDIR=32bit_mysql-%MYVER%-bin_%BUILDDATE%
set MSRCDIR=mysql-%MYVER%-win32
echo gonna create destination dir tree ...
rmdir /S/Q %MDSTDIR% 2>nul
mkdir %MDSTDIR%\c\bin 2>nul
mkdir %MDSTDIR%\c\lib 2>nul
mkdir %MDSTDIR%\c\include\mysql_5 2>nul
mkdir %MDSTDIR%\licenses\mysql 2>nul
echo gonna copy single files ...
copy %MSRCDIR%\lib\libmysql.dll %MDSTDIR%\c\bin\libmysql_.dll
copy %MSRCDIR%\COPYING %MDSTDIR%\licenses\mysql
copy %MSRCDIR%\README %MDSTDIR%\licenses\mysql
copy %MSRCDIR%\DOCS\INFO_BIN %MDSTDIR%\licenses\mysql
copy %MSRCDIR%\DOCS\INFO_SRC %MDSTDIR%\licenses\mysql
copy mysql_config.bat %MDSTDIR%\c\bin\mysql_config.bat
copy _INFO_ %MDSTDIR%\licenses\mysql
echo gonna copy headers ...
xcopy /E /Y %MSRCDIR%\include %MDSTDIR%\c\include\mysql_5
echo gonna run dlltool ...
%TOOLBIN32%\dlltool -D %MDSTDIR%\c\bin\libmysql_.dll -d libmysql-%MYVER%-win32.def -k -l %MDSTDIR%\c\lib\libmysql.a

echo ########### 64bit ########### 
set MDSTDIR=64bit_mysql-%MYVER%-bin_%BUILDDATE%
set MSRCDIR=mysql-%MYVER%-winx64
echo gonna create destination dir tree ...
rmdir /S/Q %MDSTDIR% 2>nul
mkdir %MDSTDIR%\c\bin 2>nul
mkdir %MDSTDIR%\c\lib 2>nul
mkdir %MDSTDIR%\c\include\mysql_5 2>nul
mkdir %MDSTDIR%\licenses\mysql 2>nul
echo gonna copy single files ...
copy %MSRCDIR%\lib\libmysql.dll %MDSTDIR%\c\bin\libmysql__.dll
copy %MSRCDIR%\COPYING %MDSTDIR%\licenses\mysql
copy %MSRCDIR%\README %MDSTDIR%\licenses\mysql
copy %MSRCDIR%\DOCS\INFO_BIN %MDSTDIR%\licenses\mysql
copy %MSRCDIR%\DOCS\INFO_SRC %MDSTDIR%\licenses\mysql
copy mysql_config.bat %MDSTDIR%\c\bin\mysql_config.bat
copy _INFO_ %MDSTDIR%\licenses\mysql
echo gonna copy headers ...
xcopy /E /Y %MSRCDIR%\include %MDSTDIR%\c\include\mysql_5
echo gonna run dlltool ...
%TOOLBIN64%\dlltool -D %MDSTDIR%\c\bin\libmysql__.dll -d libmysql-%MYVER%-winx64.def -k -l %MDSTDIR%\c\lib\libmysql.a

