package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.tweens.FlxTween;
import options.OptionsMenuState;
import flixel.util.FlxStringUtil;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;

class PauseSubState extends MusicBeatSubState
{
	public static var pauseMusic:FlxSound = null;
	static var goToOptions:Bool = false;

	var curSelected:Int = 0;
	var menuItems:Array<String> = [];

	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to menu'];
	var difficultyChoices:Array<String> = [];

	var grpMenuShit:FlxTypedGroup<Alphabet>;
	var practiceText:FlxText;
	var skipTimeText:FlxText;
	var skipTimeTracker:Alphabet;
	var curTime:Float = Math.max(0, Conductor.songPosition);

	var fromOptions:Bool = false;

	public function new(?fromOptions:Bool = false):Void
	{
		super();

		this.fromOptions = fromOptions;
	}

	public override function create():Void
	{
		if (CoolUtil.difficultyStuff.length < 2) { // No need to change difficulty if there is only one!
			menuItemsOG.remove('Change Difficulty');
		}

		if (PlayState.chartingMode)
		{
			menuItemsOG.insert(2, 'Leave Charting Mode');

			var num:Int = 0;

			if (!PlayState.instance.startingSong)
			{
				num = 1;
				menuItemsOG.insert(3, 'Skip Time');
			}
	
			menuItemsOG.insert(3 + num, 'End Song');
			menuItemsOG.insert(4 + num, 'Toggle Practice Mode');
			menuItemsOG.insert(5 + num, 'Toggle Botplay');
		}

		if (PlayState.gameMode == 'replay')
		{
			menuItemsOG.remove('Toggle Practice Mode');
			menuItemsOG.remove('Toggle Botplay');
		}

		for (i in 0...CoolUtil.difficultyStuff.length)
		{
			var diff:String = '' + CoolUtil.difficultyStuff[i][1];
			difficultyChoices.push(diff);
		}

		difficultyChoices.push('BACK');

		menuItems = menuItemsOG;
		goToOptions = false;

		super.create();

		if (!fromOptions)
		{
			pauseMusic = new FlxSound();

			if (OptionData.pauseMusic != 'None') {
				pauseMusic.loadEmbedded(Paths.getMusic(Paths.formatToSongPath(OptionData.pauseMusic)), true, true);
			}

			pauseMusic.volume = 0;
			pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));
			FlxG.sound.list.add(pauseMusic);
		}

		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, '', 32);
		levelInfo.text += PlayState.SONG.songName;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.getFont('vcr.ttf'), 32);
		levelInfo.updateHitbox();
		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, '', 32);
		levelDifficulty.text += CoolUtil.difficultyString(true);
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.getFont('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		add(levelDifficulty);

		var pos:Int = 64;
		var blueballedTxt:FlxText = null;
		
		if (OptionData.naughtyness)
		{
			blueballedTxt = new FlxText(20, 15 + 64, 0, '', 32);
			blueballedTxt.text = 'Blue balled: ' + PlayState.deathCounter;
			blueballedTxt.scrollFactor.set();
			blueballedTxt.setFormat(Paths.getFont('vcr.ttf'), 32);
			blueballedTxt.updateHitbox();
			blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);
			add(blueballedTxt);

			pos = 96;
		}

		var chartingText:FlxText = new FlxText(20, 15 + pos, 0, "CHARTING MODE", 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.getFont('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.updateHitbox();
		chartingText.alpha = 0;
		add(chartingText);

		practiceText = new FlxText(20, 15 + (pos + (PlayState.chartingMode ? 32 : 0)), 0, 'PRACTICE MODE', 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.getFont('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.alpha = 0;
		add(practiceText);

		if (fromOptions)
		{
			bg.alpha = 0.6;

			levelInfo.y += 5;
			levelDifficulty.y += 5;

			if (blueballedTxt != null) blueballedTxt.y += 5;

			if (PlayState.instance.practiceMode)
			{
				practiceText.alpha = 1;
				practiceText.y += 5;
			}

			if (PlayState.chartingMode)
			{
				chartingText.alpha = 1;
				chartingText.y += 5;
			}
		}
		else
		{
			levelInfo.alpha = 0;
			levelDifficulty.alpha = 0;
			if (blueballedTxt != null) blueballedTxt.alpha = 0;

			FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

			FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
			FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
			if (blueballedTxt != null) FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

			if (PlayState.instance.practiceMode)
			{
				if (PlayState.chartingMode)
				{
					if (OptionData.naughtyness)
						FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 1.1});
					else
						FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.9});
				}
				else
				{
					if (OptionData.naughtyness)
						FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.9});
					else
						FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});
				}
			}

			if (PlayState.chartingMode)
			{
				if (OptionData.naughtyness)
					FlxTween.tween(chartingText, {alpha: 1, y: chartingText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.9});
				else
					FlxTween.tween(chartingText, {alpha: 1, y: chartingText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});
			}
		}

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		regenMenu();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	private function regenMenu():Void
	{
		while (grpMenuShit.members.length > 0) {
			grpMenuShit.remove(grpMenuShit.members[0], true);
		}

		for (i in 0...menuItems.length)
		{
			var menuItem:Alphabet = new Alphabet(90, 320, menuItems[i], true);
			menuItem.isMenuItem = true;
			menuItem.targetY = i - curSelected;
			menuItem.setPosition(0, (70 * i) + 30);
			grpMenuShit.add(menuItem);

			if (menuItems[i] == 'Skip Time')
			{
				skipTimeText = new FlxText(0, 0, 0, '', 64);
				skipTimeText.setFormat(Paths.getFont('vcr.ttf'), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				skipTimeText.scrollFactor.set();
				skipTimeText.borderSize = 2;
				skipTimeTracker = menuItem;
				add(skipTimeText);

				updateSkipTextStuff();
				updateSkipTimeText();
			}
		}

		curSelected = 0;
		changeSelection();
	}

	var holdTime:Float = 0;
	var holdTimeValue:Float = 0;
	var cantUnpause:Float = 0.1;

	public override function update(elapsed:Float):Void
	{
		cantUnpause -= elapsed;

		if (OptionData.pauseMusic != 'None' && pauseMusic != null && pauseMusic.volume < 0.5) {
			pauseMusic.volume += 0.01 * elapsed;
		}

		super.update(elapsed);
		updateSkipTextStuff();

		if (menuItems.length > 1)
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

			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
				}
			}

			if (FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.getSound('scrollMenu'));
				changeSelection(-1 * FlxG.mouse.wheel);
			}
		}

		var daSelected:String = menuItems[curSelected];

		switch (daSelected)
		{
			case 'Skip Time':
			{
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
	
					curTime -= 1000;
					holdTimeValue = 0;
				}

				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
		
					curTime += 1000;
					holdTimeValue = 0;
				}

				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTimeValue += elapsed;

					if (holdTimeValue > 0.5) {
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if (curTime >= FlxG.sound.music.length) {
						curTime -= FlxG.sound.music.length;
					}
					else if (curTime < 0) {
						curTime += FlxG.sound.music.length;
					}
	
					updateSkipTimeText();
				}
			}
		}

		if ((controls.ACCEPT || FlxG.mouse.justPressed) && (cantUnpause <= 0 || !controls.controllerMode))
		{
			if (menuItems == difficultyChoices)
			{
				if (menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
				{
					var name:String = PlayState.SONG.songID;
					var poop:String = name + CoolUtil.difficultyStuff[curSelected][2];

					PlayState.SONG = Song.loadFromJson(poop, PlayState.SONG.songID);
					PlayState.lastDifficulty = curSelected;

					if (PlayState.storyDifficulty != PlayState.lastDifficulty) {
						PlayState.changedDifficulty = true;
					}

					FlxG.sound.music.volume = 0;

					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState(), true);

					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}

			switch (daSelected)
			{
				case 'Resume':
				{
					PlayState.instance.resume();
					close();
				}
				case 'Restart Song': restartSong();
				case 'Leave Charting Mode':
				{
					restartSong();
					PlayState.chartingMode = false;
				}
				case 'Skip Time':
				{
					if (curTime < Conductor.songPosition)
					{
						PlayState.startOnTime = curTime;
						restartSong(true);
					}
					else
					{
						if (curTime != Conductor.songPosition)
						{
							PlayState.instance.clearNotesBefore(curTime);
							PlayState.instance.setSongTime(curTime);
						}

						PlayState.instance.resume();
						close();
					}
				}
				case 'End Song':
				{
					PlayState.instance.resume();
					close();
					PlayState.instance.finishSong(true);
				}
				case 'Toggle Practice Mode':
				{
					PlayState.instance.practiceMode = !PlayState.instance.practiceMode;
					PlayState.usedPractice = true;

					if (PlayState.instance.practiceMode) {
						FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y + 5}, 0.4, {ease: FlxEase.quartInOut});
					}
					else {
						FlxTween.tween(practiceText, {alpha: 0, y: practiceText.y - 5}, 0.4, {ease: FlxEase.quartInOut});
					}
				}
				case 'Toggle Botplay':
				{
					PlayState.instance.cpuControlled = !PlayState.instance.cpuControlled;
					PlayState.usedPractice = true;
					PlayState.instance.botplayTxt.visible = PlayState.instance.cpuControlled;
					PlayState.instance.botplayTxt.alpha = 1;
					PlayState.instance.botplaySine = 0;
				}
				case 'Change Difficulty':
				{
					menuItems = difficultyChoices;
					deleteSkipTimeText();
					regenMenu();
				}
				case 'Options':
				{
					goToOptions = true;

					PlayState.isNextSubState = true;

					FlxG.state.closeSubState();
					FlxG.state.openSubState(new OptionsSubState());
				}
				case 'Exit to menu':
				{
					FlxG.sound.music.volume = 0;

					PlayState.cancelMusicFadeTween();

					PlayState.deathCounter = 0;

					PlayState.usedPractice = false;
					PlayState.changedDifficulty = false;
					PlayState.seenCutscene = false;
					PlayState.chartingMode = false;

					WeekData.loadTheFirstEnabledMod();

					switch (PlayState.gameMode)
					{
						case 'story': FlxG.switchState(new StoryMenuState());
						case 'freeplay': FlxG.switchState(new FreeplayMenuState());
						case 'replay': FlxG.switchState(new options.ReplaysMenuState());
						default: FlxG.switchState(new MainMenuState());
					}
				}
			}
		}
	}

	function deleteSkipTimeText():Void
	{
		if (skipTimeText != null)
		{
			skipTimeText.kill();
			remove(skipTimeText);
			skipTimeText.destroy();
		}

		skipTimeText = null;
		skipTimeTracker = null;
	}

	public static function restartSong(noTrans:Bool = false):Void
	{
		PlayState.instance.paused = true; // For lua

		FlxG.sound.music.volume = 0;

		if (PlayState.instance.vocals != null) {
			PlayState.instance.vocals.volume = 0;
		}

		FlxTransitionableState.skipNextTransIn = noTrans;
		FlxTransitionableState.skipNextTransOut = noTrans;

		StageData.loadDirectory(PlayState.SONG);
		LoadingState.loadAndSwitchState(new PlayState(), true);
	}

	public override function destroy():Void
	{
		if (!goToOptions) {
			pauseMusic.destroy();
		}

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = CoolUtil.boundSelection(curSelected + change, menuItems.length);

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;

				if (item == skipTimeTracker)
				{
					curTime = Math.max(0, Conductor.songPosition);
					updateSkipTimeText();
				}
			}
		}
	}

	function updateSkipTextStuff():Void
	{
		if (skipTimeText == null || skipTimeTracker == null) return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText():Void
	{
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000))) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}
}
