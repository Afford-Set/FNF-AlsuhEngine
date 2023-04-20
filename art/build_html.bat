@echo off
color 0a
cd ..
@echo on
echo BUILDING GAME
haxelib run openfl test html5 -release
pause