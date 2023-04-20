@echo off
color 0a
cd ..
echo BUILDING GAME
haxelib run openfl test windows -debug
echo.
echo done.
pause