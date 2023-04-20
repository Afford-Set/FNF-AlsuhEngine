# Friday Night Funkin' - Alsuh Engine

**Alsuh Engine** - This is modified connecting version of Psych Engine and Kade Engine.

This engine is designed for modcharting and also fix the bugs and many issues from Psych and Vanilla.
Also adds some features.

## Features:
Most of them are based on the Psych Engine.

### Atleast one change to every week:
**Week 1:**
- BF and GF does "Hey!" during Bopeebo
- New Dad Idle and Left sing sprite (Psych)
- Unused stage lights are now used (Psych)

**Week 2:**
- Both BF and Skid & Pump does "Hey!" animations (Psych)
- Thunders does a quick light flash and zooms the camera in slightly (Psych)
- Added a quick transition/cutscene to Monster (Psych)

**Week 3:**
- BF does "Hey!" during Philly Nice (Psych)
- GF does "Hey!" during Blammed
- Blammed has a cool new colors flash during that sick part of the song (Psych)

**Week 4:**
- Better hair physics for Mom/Boyfriend (Psych)
- Henchmen die during all songs. (Psych)

**Week 5:**
- Bottom Boppers and GF does "Hey!" animations during Cocoa and Eggnog (Psych)
- On Winter Horrorland, GF bops her head slower in some parts of the song. (Psych)

**Week 6:**
- GF does "Hey!" during Roses (animations by KirbyPoyo)
- On Thorns, the HUD is hidden during the cutscene, and also after senpai's death, the camera fade-out duration is now 0.5 seconds. (Psych/idk)
- Also there's the Background girls being spooky during the "Hey!" parts of the Instrumental (Psych)

**Week 7**:
- New animated cutscenes instead video from Vanilla (Psych)
- Some zooms on Ugh (Psych)
- The "picospeaker.json" file has been replaced by the compact event "Pico Speaker Shoot" during Stress
- Removed Kickstarter Video on end Stress

### Multiple editors to assist you in making your own Mod:
- Working both for Source code modding and Downloaded builds! (Psych)
### Story Menu rework:
- Added a different BG to every song (less Tutorial) (Psych)
- All menu characters are now in individual spritesheets, makes modding it easier. (Psych)
- All menu characters dance to every 2 beats. Dance delay on beats can be changed in the options. (less Girlfriend)
- Added week text's color flashing
### Awards/Achievements
- The engine comes with 16 example achievements that you can mess with and learn how it works (Check Achievements.hx and search for "checkForAchievement" on PlayState.hx) (Psych)
### Credits Menu:
- You can add a head icon, name, description, color and a Redirect link for when the player presses Enter while the item is currently selected. (Psych)
### Options Menu:
- You can change Preferences, Controls, Note colors, Delay and Combo Offset there. (Psych)
- On Preferences you can toggle Downscroll, Middlescroll, Anti-Aliasing, Framerate, Low Quality, Note Splashes, Flashing Lights, etc. (Psych)
- On Delay and Combo Offset you can position combo's pop ups, adjust delay position and dance delay.
### Gameplay:
- When the enemy hits a note, their strum note also glows. (Psych)
- Lag doesn't impact the camera movement and player icon scaling anymore. (Psych)
- Some stuff based on Week 7's changes has been put in (Background colors on Freeplay, Note splashes) (Psych)
- You can reset your Score on Freeplay/Story Mode by pressing Reset button. (Psych)
- You can listen to a song or adjust Scroll Speed/Damage taken/etc. on Freeplay by pressing Space. (Psych)
- New Score Text (Deaths, Accuracy, Rating, Health, Combo Breaks)
- New Song Timer

## Installation:
1. You must have [version 4.2.5 of Haxe](https://haxe.org/download/version/4.2.5/), seriously, stop using 4.1.5, it misses some stuff. It is also not recommended to use version 4.3.0 of haxe, as errors from Flixel appear.
2. Download [git-scm](https://git-scm.com/downloads). Works for Windows, Mac, and Linux, just select your build.
3. Install [Visual Studio Community 2022](https://visualstudio.microsoft.com/vs/community/).
4. While installing VSC, don't click on any of the options to install workloads. Instead, go to the individual components tab and choose the following:
- MSVC v143 - VS 2022 C++ x64/x86 build tools
- Windows SDK (10.0.20348.0) and (10.0.22621.0)

5. Open up a Command Prompt/PowerShell or Terminal, type `haxelib install hmm`
after it finishes, simply type `haxelib run hmm install` in order to install all the needed libraries for this engine.
6. On Command Prompt/PowerShell or Terminal, type the ones shown below:
```
haxelib setup .haxelib
haxelib run openfl setup
haxelib run flixel setup
haxelib run openfl rebuild extension-webm [windows/linux/macos]
```
## Supported platforms:
### C++
- Windows
- Linux
- MacOS
### JavaScript
- HTML5

## Customization:
if you wish to disable things like *Lua Scripts* or *Video Cutscenes* or *.Webm Cutscenes*, you can read over to `Project.xml`
inside `Project.xml`, you will find several variables to customize Alsuh Engine to your liking

to start you off, disabling *Video Cutscenes* should be simple, simply Delete the line `"VIDEOS_ALLOWED"` or comment it out by wrapping the line in XML-like comments, like this `<!-- YOUR_LINE_HERE -->`

same goes for *Lua Scripts*, comment out or delete the line with `LUA_ALLOWED`, this and other customization options are all available within the `Project.xml` file,

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