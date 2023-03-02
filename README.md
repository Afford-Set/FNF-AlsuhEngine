# Friday Night Funkin' Alsuh Engine

[READ THE WIKI BEFORE DOING QUESTIONS!!!](https://github.com/Afford-Set/FNF-AlsuhEngine/wiki)
[READ THE WIKI BEFORE DOING QUESTIONS!!!](https://github.com/Afford-Set/FNF-AlsuhEngine/wiki)
[READ THE WIKI BEFORE DOING QUESTIONS!!!](https://github.com/Afford-Set/FNF-AlsuhEngine/wiki)

**Alsuh Engine** - This is modified connecting version of Psych Engine and Kade Engine. This engine is designed for modcharting.
This engine is 24.7% more powerful than Psych Engine thanks to new features.

## Installation:
You must have [version 4.2.5 of Haxe](https://haxe.org/download/version/4.2.5/), seriously, stop using 4.1.5, it misses some stuff.

open up a Command Prompt/PowerShell or Terminal, type `haxelib install hmm`
after it finishes, simply type `haxelib run hmm install` in order to install all the needed libraries for *Alsuh Engine!*

**WARNING:** After the libraries installation is complete, on Command Prompt/PowerShell type this command: `haxelib run lime rebuild extension-webm [linux/windows/macos]`, if *.Webm Cutscenes* supported on selected platform.

## Customization:

if you wish to disable things like *Lua Scripts* or *.MP4 Cutscenes* or *.Webm Cutscenes*, you can read over to `Project.xml`
inside `Project.xml`, you will find several variables to customize Alsuh Engine to your liking

to start you off, disabling *.MP4 Cutscenes* should be simple, simply Delete the line `"VIDEOS_ALLOWED"` or comment it out by wrapping the line in XML-like comments, like this `<!-- YOUR_LINE_HERE -->`

same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED`, this and other customization options are all available within the `Project.xml` file,

and again also same goes for *.Webm Cutscenes*, comment out or delete the line with `WEBM_ALLOWED`, but you understood everything.

# Features

It's the same as in the Psych Engine, only there are changes and additions shown below.
The main feature is support for .MP3 audio files. .OGG audio files continue to be supported in this engine.

### Additions
- Custom Inst and Voices for other difficulties
- .WEBM Videos Support (supported on Linux/Windows/MacOS)
- Replays
- Custom Achievements (original by [TheWorldMachinima](https://github.com/TheWorldMachinima))
- Playback Rate/Pitch on other platforms (original by [Raltyro](https://github.com/Raltyro))

### Changes:
- Menu Character dances to every beat on Story Menu
- Preferences Menu cambacked

## Credits:
### Alsuh Engine by
- Null - Programmer

### Psych Engine Team
- Shadow Mario - Programmer
- RiverOaken - Artist
- Yoshubs - Assistant Programmer

### Psych Engine Contributors
- bbpanzu - Ex-Programmer
- shubs - New Input System
- SqirraRNG - Crash Handler and Base code for Chart Editor's Waveform
- EliteMasterEric - Runtime Shaders support
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