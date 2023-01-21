package options;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import flixel.FlxG;
#if sys
import sys.io.File;
import sys.FileSystem;
#end
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import transition.TransitionableState;

using StringTools;

class ReplaysMenuState extends TransitionableState
{
	var curSelected:Int = 0;

	var replaysArray:Array<String> = [];
	var actualNames:Array<String> = [];

	var grpReplays:FlxTypedGroup<Alphabet>;

	public override function create():Void
	{
		super.create();

		persistentUpdate = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Replays Menu", null); // Updating Discord Rich Presence
		#end

		if (FlxG.sound.music.playing == false || FlxG.sound.music.volume == 0) {
			FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
		}

		var bg:FlxSprite = new FlxSprite();
		if (Paths.fileExists('images/menuBGBlue.png', IMAGE)) {
			bg.loadGraphic(Paths.getImage('menuBGBlue'));
		}
		else {
			bg.loadGraphic(Paths.getImage('bg/menuBGBlue'));
		}
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = OptionData.globalAntialiasing;
		add(bg);

		#if sys
		replaysArray = FileSystem.readDirectory(Sys.getCwd() + "\\assets\\replays\\");
		#end
		replaysArray.sort(Reflect.compare);

		if (replaysArray.length > 0)
		{
			for (i in 0...replaysArray.length)
			{
				var string:String = replaysArray[i];
				actualNames[i] = string;
		
				var rep:Replay = Replay.loadReplay(string);
				replaysArray[i] = rep.replay.songName + ' - ' + CoolUtil.getDifficultyName(rep.replay.songDiff) + ' ' + rep.replay.timestamp;
			}
		}
		else {
			replaysArray.push('No replays...');
		}

		grpReplays = new FlxTypedGroup<Alphabet>();
		add(grpReplays);

		for (i in 0...replaysArray.length)
		{
			var leText:Alphabet = new Alphabet(100, 270, replaysArray[i], false);
			leText.isMenuItem = true;
			leText.targetY = i - curSelected;
			leText.snapToPosition();
			grpReplays.add(leText);
		}

		changeSelection();
	}

	var holdTime:Float = 0;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			FlxG.sound.play(Paths.getSound('cancelMenu'));
			FlxG.switchState(new OptionsMenuState());
		}

		if (controls.UI_DOWN || controls.UI_UP)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.getSound('scrollMenu'));
				changeSelection(-1);

				holdTime = 0;
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.getSound('scrollMenu'));
				changeSelection(1);

				holdTime = 0;
			}

			var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
			holdTime += elapsed;
			var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

			if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
			{
				changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
				FlxG.sound.play(Paths.getSound('scrollMenu'));
			}
		}

		if (controls.ACCEPT || FlxG.mouse.justPressed)
		{
			if (replaysArray[curSelected] != "No replays...")
			{
				PlayState.rep = Replay.loadReplay(actualNames[curSelected]);

				var diffic:String = CoolUtil.getDifficultySuffix(PlayState.rep.replay.songDiff, false, PlayState.rep.replay.difficulties);

				if (Paths.fileExists('data/' + PlayState.rep.replay.songID + '/' + PlayState.rep.replay.songID + diffic + '.json', TEXT) == true)
				{
					persistentUpdate = false;

					PlayState.SONG = Song.loadFromJson(PlayState.rep.replay.songID + diffic, PlayState.rep.replay.songID);
					PlayState.gameMode = 'replay';
					PlayState.isStoryMode = false;
					PlayState.difficulties = PlayState.rep.replay.difficulties;
					PlayState.lastDifficulty = PlayState.rep.replay.songDiff;
					PlayState.storyDifficultyID = PlayState.rep.replay.songDiff;
					PlayState.storyWeekText = PlayState.rep.replay.weekID;
					PlayState.storyWeekName = PlayState.rep.replay.weekName;

					Debug.logInfo('Loading song ${PlayState.SONG.songName} from week ${PlayState.storyWeekName} into Replay...');
	
					if (!OptionData.loadingScreen) {
						FreeplayMenuState.destroyFreeplayVocals();
					}
	
					LoadingState.loadAndSwitchState(new PlayState(), true);
				}
				else {
					Debug.logError('File "data/' + PlayState.rep.replay.songID + '/' + PlayState.rep.replay.songID + diffic + '.json" does not exist!"');
				}
			}
			else {
				FlxG.sound.play(Paths.getSound('cancelMenu'));
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = CoolUtil.boundSelection(curSelected + change, replaysArray.length);

		var bullShit:Int = 0;

		for (item in grpReplays.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}
	}
}