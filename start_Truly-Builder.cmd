@echo off

cd /d "%~dp0"
if NOT "%cd%"=="%cd: =%" (
    echo.
    echo The current directory's path contains spaces.
    echo To proceed, please move or rename the directory to one without spaces.
    echo.
    pause
)

powershell -NoProfile -ExecutionPolicy ByPass "%~dp0\src\Truly-Builder.ps1"
