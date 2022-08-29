# Friday Night Funkin' Alsuh Engine

**Alsuh Engine** - This is modified connecting version of Psych Engine and Kade Engine by AlanSurtaev2008.

## Installation:
You must have [version 4.2.5 of Haxe](https://haxe.org/download/version/4.2.5/), seriously, stop using 4.1.5, it misses some stuff.

Follow a Friday Night Funkin' source code compilation tutorial, after this you will need to install LuaJIT.

To install LuaJIT do this: `haxelib git linc_luajit https://github.com/nebulazorua/linc_luajit` on a Command prompt/PowerShell
...Or if you don't want your mod to be able to run .lua scripts, delete the "LUA_ALLOWED" line on Project.xml

Install Actuate do this: `haxelib install actuate` on a Command prompt/PowerShell.

If you want video support on your mod, simply do `haxelib git hxCodec https://github.com/polybiusproxy/hxCodec` or `haxelib git extension-webm https://github.com/GrowtopiaFli/extension-webm` or generally install them both on a Command prompt/PowerShell
otherwise, you can delete the "VIDEOS_ALLOWED" Line on Project.xml

## Credits:
### Alsuh Engine by
- AlanSurtaev2008 - Programmer

### Psych Engine Team
- Shadow Mario - Programmer
- RiverOaken - Artist
- Yoshubs - Assistant Programmer

### Psych Engine Contributors
- bbpanzu - Ex-Programmer
- shubs - New Input System
- SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform
- KadeDev - Fixed some cool stuff on Chart Editor and other PRs
- iFlicky - Composer of Psync and Tea Time, also made the Dialogue Sounds
- PolybiusProxy - .MP4 Video Loader Library (hxCodec)
- Keoiki - Note Splash Animations
- Smokey - Sprite Atlas Support
- Nebula the Zorua - LUA JIT Fork and some Lua reworks

### Funkin' Crew
- ninjamuffin99 - Programmer of the Friday Night Funkin'
- PhantomArcade - Animator/Artist of the Friday Night Funkin'
- evilsk8r - Artist of the Friday Night Funkin'
- kawaisprite - Composer of the Friday Night Funkin'
