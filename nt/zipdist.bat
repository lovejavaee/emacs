@echo off
rem Copyright (C) 2001-2014 Free Software Foundation, Inc.

rem Author: Christoph Scholtes cschol2112 at gmail.com

rem This file is part of GNU Emacs.

rem GNU Emacs is free software: you can redistribute it and/or modify
rem it under the terms of the GNU General Public License as published by
rem the Free Software Foundation, either version 3 of the License, or
rem (at your option) any later version.

rem GNU Emacs is distributed in the hope that it will be useful,
rem but WITHOUT ANY WARRANTY; without even the implied warranty of
rem MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
rem GNU General Public License for more details.

rem You should have received a copy of the GNU General Public License
rem along with GNU Emacs.  If not, see http://www.gnu.org/licenses/.

SETLOCAL
rem arg 1: Emacs version number
set EMACS_VER=%1

set TMP_DIST_DIR=emacs-%EMACS_VER%

rem Check, if 7zip is installed and available on path
7z 1>NUL 2>NUL
if %ERRORLEVEL% NEQ 0 goto ZIP_ERROR
goto ZIP_DIST

:ZIP_ERROR
echo.
echo ERROR: Make sure 7zip is installed and available on the Windows Path!
goto EXIT

rem Build and verify the binary distribution
:ZIP_DIST
7z a -bd -tZIP -mx=9 -x!.gitignore -xr!emacs.mdp -xr!*.pdb -xr!*.opt -xr!*~ -xr!CVS -xr!.arch-inventory emacs-%EMACS_VER%-bin-i386.zip %TMP_DIST_DIR%
7z t emacs-%EMACS_VER%-bin-i386.zip
goto EXIT

:EXIT
