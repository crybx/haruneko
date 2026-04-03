@echo off
setlocal

set "SCRIPT_DIR=%~dp0"
set "BASH_SCRIPT=%SCRIPT_DIR%build-local-electron.sh"

if not exist "%BASH_SCRIPT%" (
    echo Build script not found:
    echo %BASH_SCRIPT%
    pause
    exit /b 1
)

pushd "%SCRIPT_DIR%"

where bash.exe >nul 2>&1
if %errorlevel%==0 (
    bash.exe --login "./build-local-electron.sh"
    set "EXIT_CODE=%errorlevel%"
    popd
    if not "%EXIT_CODE%"=="0" pause
    exit /b %EXIT_CODE%
)

where sh.exe >nul 2>&1
if %errorlevel%==0 (
    sh.exe "./build-local-electron.sh"
    set "EXIT_CODE=%errorlevel%"
    popd
    if not "%EXIT_CODE%"=="0" pause
    exit /b %EXIT_CODE%
)

popd
echo Neither bash.exe nor sh.exe is available in PATH.
echo Run build-local-electron.sh from a shell that can execute POSIX shell scripts.
pause
exit /b 1
