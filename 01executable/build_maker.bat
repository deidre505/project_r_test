@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM =========================================
REM Drag & Drop .love -> build .exe (LOVE2D)
REM - Usage: drag a .love file onto this .bat
REM - Output: <same folder>\<same name>.exe
REM - LOVE path fixed to: C:\Program Files\LOVE\love.exe
REM =========================================

set "LOVE_EXE=C:\Program Files\LOVE\love.exe"

REM 1) Check LOVE exists
if not exist "%LOVE_EXE%" (
  echo [ERROR] love.exe not found:
  echo         "%LOVE_EXE%"
  echo.
  echo Fix: Install LOVE or edit LOVE_EXE in this .bat.
  pause
  exit /b 1
)

REM 2) Ensure user drag-dropped a file
if "%~1"=="" (
  echo [USAGE] Drag a .love file onto this .bat
  echo.
  pause
  exit /b 1
)

REM 3) Input file from drag&drop
set "IN_FILE=%~1"

REM 4) Validate extension
if /I not "%~x1"==".love" (
  echo [ERROR] Input is not a .love file:
  echo         "%IN_FILE%"
  pause
  exit /b 1
)

REM 5) Build output path: same folder, same base name, .exe
set "OUT_DIR=%~dp1"
set "BASE_NAME=%~n1"
set "OUT_EXE=%OUT_DIR%%BASE_NAME%.exe"

echo =========================================
echo LOVE EXE : "%LOVE_EXE%"
echo INPUT    : "%IN_FILE%"
echo OUTPUT   : "%OUT_EXE%"
echo =========================================

REM 6) Create exe by concatenation (binary copy)
copy /b "%LOVE_EXE%" + "%IN_FILE%" "%OUT_EXE%" >nul

if errorlevel 1 (
  echo [ERROR] Build failed.
  pause
  exit /b 1
)

echo [SUCCESS] Built:
echo "%OUT_EXE%"
echo.
echo Note: DLLs (steam_api64.dll, steam_api.dll, etc.) are NOT embedded.
echo       Keep them next to the .exe if your game needs them.
pause
exit /b 0
