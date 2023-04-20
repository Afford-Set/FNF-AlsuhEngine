package options;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import Replay;

#if REPLAYS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;

using StringTools;

class ReplaysMenuState extends MusicBeatState
{
	var curSelected:Int = 0;

	var replaysArray:Array<String> = [];
	var actualNames:Array<String> = [];

	var grpReplays:FlxTypedGroup<Alphabet>;

	public override function create():Void
	{
		persistentUpdate = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Replays Menu", null); // Updating Discord Rich Presence
		#end

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0) {
				FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
			}
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

		#if REPLAYS_ALLOWED
		replaysArray = FileSystem.readDirectory(Paths.getPreloadPath('replays'));
		replaysArray.sort(Reflect.compare);
		#end

		if (replaysArray.length > 0)
		{
			for (i in 0...replaysArray.length)
			{
				var string:String = replaysArray[i];
				actualNames[i] = string;
		
				var rep:Replay = Replay.loadReplay(string);
				var diff:String = rep.replay.difficulties[rep.replay.songDiff][1];
				replaysArray[i] = rep.replay.songName + ' - ' + diff + ' ' + rep.replay.timestamp;
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

		super.create();
	}

	var holdTime:Float = 0;

	public override function update(elapsed:Float):Void
	{
		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			FlxG.sound.play(Paths.getSound('cancelMenu'));
			FlxG.switchState(new OptionsMenuState());
		}

		if (replaysArray.length > 0)
		{
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

			if (FlxG.mouse.wheel != 0) {
				changeSelection(-1 * FlxG.mouse.wheel);
			}
		}

		if (controls.ACCEPT || FlxG.mouse.justPressed)
		{
			if (replaysArray[curSelected] != "No replays...")
			{
				PlayState.rep = Replay.loadReplay(actualNames[curSelected]);

				var replay:ReplayJSON = PlayState.rep.replay;
				var songID:String = replay.songID;

				CoolUtil.difficultyStuff = replay.difficulties.copy();
				var ourPath:String = songID + CoolUtil.difficultyStuff[replay.songDiff][2];

				if (replay.currentModDirectory != null && replay.currentModDirectory.length > 0) {
					Paths.currentModDirectory = replay.currentModDirectory;
				}

				if (Paths.fileExists('data/' + songID + '/' + ourPath + '.json', TEXT))
				{
					try
					{
						persistentUpdate = false;

						PlayState.SONG = Song.loadFromJson(ourPath, songID);
						PlayState.gameMode = 'replay';
						PlayState.isStoryMode = false;
						PlayState.storyDifficulty = replay.songDiff;
						PlayState.lastDifficulty = PlayState.storyDifficulty;
						PlayState.storyWeekID = replay.weekID;
						PlayState.storyWeekName = replay.weekName;

						Debug.logInfo('Loading song ${PlayState.SONG.songName} from week ${PlayState.storyWeekName} into Replay...');
		
						if (!OptionData.loadingScreen) {
							FreeplayMenuState.destroyFreeplayVocals();
						}

						LoadingState.loadAndSwitchState(new PlayState(), true);
					}
					catch (e:Dynamic) {
						Debug.logError('Error on loading file "' + songID + '/' + ourPath + '.json' + '": ' + e);
					}
				}
				else {
					Debug.logError('File "data/' + songID + '/' + ourPath + '.json" does not exist!"');
				}
			}
			else {
				FlxG.sound.play(Paths.getSound('cancelMenu'));
			}
		}

		super.update(elapsed);
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