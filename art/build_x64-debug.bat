@echo off
color 0a
cd ..
echo BUILDING GAME
haxelib run openfl build windows -debug
echo.
echo done.
pause
pwd
explorer.exe export\debug\windows\bin