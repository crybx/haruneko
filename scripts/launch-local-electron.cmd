@echo off
set "SEARCH_DIR=%~dp0..\app\electron\.local-run\current"
set "EXE=%SEARCH_DIR%\hakuneko-electron.exe"
if not exist "%EXE%" (
    echo Local Electron build not found under:
    echo %SEARCH_DIR%
    echo Run scripts\build-local-electron.cmd first.
    pause
    exit /b 1
)
start "" /D "%SEARCH_DIR%" "%EXE%" --local %*
if errorlevel 1 pause
