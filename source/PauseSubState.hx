package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import transition.Transition;
import flixel.system.FlxSound;
import flixel.tweens.FlxTween;
import options.OptionsMenuState;
import flixel.util.FlxStringUtil;

using StringTools;

class PauseSubState extends BaseSubState
{
	public static var pauseMusic:FlxSound = null;
	static var goToOptions:Bool = false;

	var curSelected:Int = 0;
	var menuItems:Array<String> = [];

	var menuItemsOG:Array<String> = ['Resume', 'Restart Song', 'Change Difficulty', 'Options', 'Exit to menu'];
	var difficultyChoices:Array<String> = [];

	var grpMenuShit:FlxTypedGroup<Alphabet>;

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
		super.create();

		if (PlayState.difficulties[1].length < 2 || PlayState.gameMode == 'replay') { // No need to change difficulty if there is only one!
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
			menuItemsOG.insert(4 + num, 'Gameplay Changeables');
		}

		if (PlayState.gameMode == 'replay') {
			menuItemsOG.remove('Gameplay Changeables');
		}

		for (i in 0...PlayState.difficulties[1].length) {
			difficultyChoices.push(CoolUtil.getDifficultyName(PlayState.difficulties[1][i]));
		}

		difficultyChoices.push('BACK');

		menuItems = menuItemsOG;

		goToOptions = false;

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
		levelDifficulty.text += CoolUtil.getDifficultyName(PlayState.lastDifficulty, PlayState.difficulties).toUpperCase();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.getFont('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		add(levelDifficulty);

		var blueballedTxt:FlxText = new FlxText(20, 15 + 64, 0, '', 32);
		blueballedTxt.text = 'Blue balled: ' + PlayState.deathCounter;
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.getFont('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);
		add(blueballedTxt);

		var chartingText:FlxText = new FlxText(20, 15 + 96, 0, "CHARTING MODE", 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.getFont('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.updateHitbox();
		chartingText.alpha = 0;
		add(chartingText);

		var practiceText:FlxText = new FlxText(20, 15 + (PlayState.chartingMode ? 128 : 96), 0, 'PRACTICE MODE', 32);
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
			blueballedTxt.y += 5;

			if (PlayStateChangeables.practiceMode)
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
			blueballedTxt.alpha = 0;

			FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

			FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
			FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});
			FlxTween.tween(blueballedTxt, {alpha: 1, y: blueballedTxt.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.7});

			if (PlayStateChangeables.practiceMode)
			{
				if (PlayState.chartingMode)
					FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 1.1});
				else
					FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.9});
			}

			if (PlayState.chartingMode) {
				FlxTween.tween(chartingText, {alpha: 1, y: chartingText.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.9});
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
				skipTimeText.setFormat(Paths.getFont("vcr.ttf"), 64, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
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
	var cantUnpause:Float = 0.1;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (pauseMusic != null && pauseMusic.volume < 0.5) {
			pauseMusic.volume += 0.01 * elapsed;
		}

		cantUnpause -= elapsed;

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

		updateSkipTextStuff();

		var daSelected:String = menuItems[curSelected];

		switch (daSelected)
		{
			case 'Skip Time':
			{
				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
	
					curTime -= 1000;
					holdTime = 0;
				}

				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
		
					curTime += 1000;
					holdTime = 0;
				}

				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;

					if (holdTime > 0.5) {
						curTime += 45000 * elapsed * (controls.UI_LEFT ? -1 : 1);
					}

					if (curTime >= FlxG.sound.music.length)
						curTime -= FlxG.sound.music.length;
					else if (curTime < 0)
						curTime += FlxG.sound.music.length;
	
					updateSkipTimeText();
				}
			}
		}

		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			PlayState.instance.callOnLuas('onResume', []);
			close();
		}

		if ((controls.ACCEPT || FlxG.mouse.justPressed) && !OptionData.controllerMode)
		{
			if (menuItems == difficultyChoices)
			{
				if (menuItems.length - 1 != curSelected && difficultyChoices.contains(daSelected))
				{
					var difficulty:String = CoolUtil.getDifficultySuffix(daSelected, true, PlayState.difficulties);

					PlayState.SONG = Song.loadFromJson(PlayState.SONG.songID + difficulty, PlayState.SONG.songID);
					PlayState.lastDifficulty = CoolUtil.getDifficultyID(daSelected, false, PlayState.difficulties);
					PlayState.usedPractice = PlayState.storyDifficulty != PlayState.lastDifficulty;

					FlxG.sound.music.volume = 0;
					FlxG.resetState();

					return;
				}

				menuItems = menuItemsOG;
				regenMenu();
			}

			switch (daSelected)
			{
				case 'Resume':
				{
					PlayState.instance.callOnLuas('onResume', []);
					close();
				}
				case 'Restart Song':
				{
					restartSong();
				}
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

						PlayState.instance.callOnLuas('onResume', []);
						close();
					}
				}
				case "End Song":
				{
					close();
					PlayState.instance.finishSong(true);
				}
				case 'Change Difficulty':
				{
					menuItems = difficultyChoices;
					regenMenu();
				}
				case 'Gameplay Changeables':
				{
					goToOptions = true;

					PlayState.isNextSubState = true;

					FlxG.state.closeSubState();
					FlxG.state.openSubState(new GameplayChangersSubState(true));
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

					PlayState.seenCutscene = false;
					PlayState.chartingMode = false;

					WeekData.loadTheFirstEnabledMod();

					switch (PlayState.gameMode)
					{
						case 'story':
						{
							FlxG.switchState(new StoryMenuState());
						}
						case 'freeplay':
						{
							FlxG.switchState(new FreeplayMenuState());
						}
						case 'replay':
						{
							Replay.resetVariables();
							FlxG.switchState(new options.ReplaysMenuState());
						}
						default:
						{
							FlxG.switchState(new MainMenuState());
						}
					}
				}
			}
		}
	}

	public static function restartSong(noTrans:Bool = false):Void
	{
		PlayState.instance.paused = true; // For lua

		FlxG.sound.music.volume = 0;
		PlayState.instance.vocals.volume = 0;

		if (noTrans)
		{
			Transition.skipNextTransOut = true;
			FlxG.resetState();
		}
		else {
			FlxG.resetState();
		}
	}

	public override function destroy():Void
	{
		super.destroy();

		if (!goToOptions) {
			pauseMusic.destroy();
		}
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

	function updateSkipTextStuff()
	{
		if (skipTimeText == null || skipTimeTracker == null) return;

		skipTimeText.x = skipTimeTracker.x + skipTimeTracker.width + 60;
		skipTimeText.y = skipTimeTracker.y;
		skipTimeText.visible = (skipTimeTracker.alpha >= 1);
	}

	function updateSkipTimeText()
	{
		skipTimeText.text = FlxStringUtil.formatTime(Math.max(0, Math.floor(curTime / 1000)), false) + ' / ' + FlxStringUtil.formatTime(Math.max(0, Math.floor(FlxG.sound.music.length / 1000)), false);
	}
}
