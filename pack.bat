@echo off
REM Build HeliosPT.zip with the shaders\ folder at the archive root.
REM This layout is mandatory for Oculus 1.6.4 (see INSTALL.md).
setlocal

cd /d "%~dp0"

if exist HeliosPT.zip del /f /q HeliosPT.zip

REM Compress-Archive preserves the folder as a top-level entry: shaders\...
powershell -NoProfile -Command "Compress-Archive -Path 'shaders' -DestinationPath 'HeliosPT.zip' -Force"

echo Created %CD%\HeliosPT.zip
echo Sanity check: opening the zip must show shaders\ at its root (no wrapper folder).
endlocal
