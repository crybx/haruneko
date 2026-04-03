@echo off
set "SEARCH_DIR=%~dp0..\app\nw\.local-run\current"
set "EXE=%SEARCH_DIR%\hakuneko-nw.exe"
if not exist "%EXE%" (
    echo Local NW.js build not found under:
    echo %SEARCH_DIR%
    echo Run scripts\build-local-nw.cmd first.
    pause
    exit /b 1
)
start "" /D "%SEARCH_DIR%" "%EXE%" --local %*
if errorlevel 1 pause
