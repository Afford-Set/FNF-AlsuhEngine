package options;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.effects.FlxFlicker;

using StringTools;

class OptionsMenuState extends MusicBeatState
{
	public static var curSelected:Int = 0;

	private var options:Array<String> = ['Preferences', 'Controls', 'Note Colors', 'Adjust Delay and Combo', #if REPLAYS_ALLOWED 'Replays', #end 'Exit'];
	private var grpOptions:FlxTypedGroup<Alphabet>;

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	function openSelectedSubstate(label:String):Void
	{
		switch (label)
		{
			case 'Preferences': openSubState(new PreferencesSubState());
			case 'Controls': openSubState(new ControlsSubState());
			case 'Note Colors': openSubState(new NotesSubState());
			case 'Adjust Delay and Combo':
			{
				FlxG.sound.music.pause();
				FlxG.sound.music.volume = 0;

				FlxG.sound.play(Paths.getSound('cancelMenu'));
				FlxG.switchState(new NoteOffsetState());
			}
			case 'Credits':
			{
				FlxG.sound.play(Paths.getSound('cancelMenu'));
				FlxG.switchState(new CreditsMenuState());
			}
			#if REPLAYS_ALLOWED
			case 'Replays':
			{
				FlxG.sound.play(Paths.getSound('cancelMenu'));
				FlxG.switchState(new ReplaysMenuState());
			}
			#end
			case 'Exit':
			{
				FlxG.sound.play(Paths.getSound('cancelMenu'));
				FlxG.switchState(new MainMenuState());
			}
			default: flickering = false;
		}
	}

	public override function create():Void
	{
		CustomFadeTransition.nextCamera = null;

		super.create();

		if (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0) {
			FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
		}

		OptionData.savePrefs();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite();
		if (Paths.fileExists('images/menuDesat.png', IMAGE)) {
			bg.loadGraphic(Paths.getImage('menuDesat'));
		}
		else {
			bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		}
		bg.color = 0xFFea71fd;
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = OptionData.globalAntialiasing;
		add(bg);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			optionText.ID = i;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);

		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();
	}

	public override function closeSubState():Void
	{
		super.closeSubState();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Options Menu", null);
		#end

		flickering = false;
		OptionData.savePrefs();
	}

	var flickering:Bool = false;
	var holdTime:Float = 0;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			OptionData.savePrefs();

			FlxG.sound.play(Paths.getSound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}

		if (!flickering)
		{
			if (options.length > 1)
			{
				if (controls.UI_UP_P)
				{
					changeSelection(-1);
					holdTime = 0;
				}

				if (controls.UI_DOWN_P)
				{
					changeSelection(1);
					holdTime = 0;
				}

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
					}
				}

				if (FlxG.mouse.wheel != 0) {
					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}

			if (controls.ACCEPT || FlxG.mouse.justPressed)
			{
				if (OptionData.flashingLights)
				{
					flickering = true;

					FlxFlicker.flicker(selectorLeft, 1, 0.04, true);
					FlxFlicker.flicker(selectorRight, 1, 0.04, true);
	
					FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.04, true, false, function(flick:FlxFlicker):Void {
						openSelectedSubstate(options[curSelected]);
					});
	
					FlxG.sound.play(Paths.getSound('confirmMenu'));
				}
				else {
					openSelectedSubstate(options[curSelected]);
				}
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = CoolUtil.boundSelection(curSelected + change, options.length);

		for (item in grpOptions.members)
		{
			item.alpha = 0.6;

			if (item.ID == curSelected)
			{
				item.alpha = 1;

				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;

				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}

		FlxG.sound.play(Paths.getSound('scrollMenu'));
	}
}

class OptionsSubState extends MusicBeatSubState
{
	private static var curSelected:Int = -1;

	private var options:Array<String> = ['Preferences', 'Controls', 'Note Colors', 'Combo Position', 'Exit'];
	private var grpOptions:FlxTypedGroup<Alphabet>;

	var selectorLeft:Alphabet;
	var selectorRight:Alphabet;

	function openSelectedSubstate(label:String):Void
	{
		switch (label)
		{
			case 'Preferences':
			{
				PlayState.isNextSubState = true;

				FlxG.state.closeSubState();
				FlxG.state.openSubState(new PreferencesSubState(true));
			}
			case 'Controls':
			{
				PlayState.isNextSubState = true;

				FlxG.state.closeSubState();
				FlxG.state.openSubState(new ControlsSubState(true));
			}
			case 'Note Colors':
			{
				PlayState.isNextSubState = true;

				FlxG.state.closeSubState();
				FlxG.state.openSubState(new NotesSubState(true));
			}
			case 'Combo Position':
			{
				PlayState.isNextSubState = true;

				FlxG.state.closeSubState();
				FlxG.state.openSubState(new ComboSubState());
			}
			case 'Exit':
			{
				OptionsMenuState.curSelected = curSelected;

				OptionData.savePrefs();
	
				FlxG.sound.play(Paths.getSound('cancelMenu'));
	
				PlayState.isNextSubState = true;
	
				FlxG.state.closeSubState();
				FlxG.state.openSubState(new PauseSubState(true));
	
				curSelected = -1;
			}
		}
	}

	public override function create():Void
	{
		super.create();

		OptionData.savePrefs();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Options Menu", null);
		#end

		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 20, 0, '', 32);
		levelInfo.text += PlayState.SONG.songName;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.getFont('vcr.ttf'), 32);
		levelInfo.updateHitbox();
		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 20 + 32, 0, '', 32);
		levelDifficulty.text += CoolUtil.getDifficultyName(PlayState.lastDifficulty, PlayState.difficulties).toUpperCase();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.getFont('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		add(levelDifficulty);

		var blueballedTxt:FlxText = new FlxText(20, 20 + 64, 0, '', 32);
		blueballedTxt.text = 'Blue balled: ' + PlayState.deathCounter;
		blueballedTxt.scrollFactor.set();
		blueballedTxt.setFormat(Paths.getFont('vcr.ttf'), 32);
		blueballedTxt.updateHitbox();
		blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);
		add(blueballedTxt);

		var chartingText:FlxText = new FlxText(20, 20 + 96, 0, "CHARTING MODE", 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.getFont('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.updateHitbox();
		chartingText.visible = PlayState.chartingMode;
		add(chartingText);

		var practiceText:FlxText = new FlxText(20, 20 + (PlayState.chartingMode ? 128 : 96), 0, 'PRACTICE MODE', 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.getFont('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.alpha = PlayStateChangeables.practiceMode ? 1 : 0;
		add(practiceText);

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		if (curSelected < 0) curSelected = OptionsMenuState.curSelected;

		for (i in 0...options.length)
		{
			var optionText:Alphabet = new Alphabet(0, 0, options[i], true);
			optionText.screenCenter();
			optionText.y += (100 * (i - (options.length / 2))) + 50;
			optionText.ID = i;
			grpOptions.add(optionText);
		}

		selectorLeft = new Alphabet(0, 0, '>', true);
		add(selectorLeft);

		selectorRight = new Alphabet(0, 0, '<', true);
		add(selectorRight);

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var flickering:Bool = false;
	var holdTime:Float = 0;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var pauseMusic:FlxSound = PauseSubState.pauseMusic;

		if (pauseMusic != null && pauseMusic.volume < 0.5) {
			pauseMusic.volume += 0.01 * elapsed;
		}

		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			OptionsMenuState.curSelected = curSelected;

			OptionData.savePrefs();

			FlxG.sound.play(Paths.getSound('cancelMenu'));

			PlayState.isNextSubState = true;

			FlxG.state.closeSubState();
			FlxG.state.openSubState(new PauseSubState(true));

			curSelected = -1;
		}

		if (!flickering)
		{
			if (options.length > 1)
			{
				if (controls.UI_UP_P)
				{
					changeSelection(-1);
					holdTime = 0;
				}

				if (controls.UI_DOWN_P)
				{
					changeSelection(1);
					holdTime = 0;
				}

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
					}
				}

				if (FlxG.mouse.wheel != 0) {
					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}

			if (controls.ACCEPT || FlxG.mouse.justPressed)
			{
				if (OptionData.flashingLights)
				{
					flickering = true;

					FlxFlicker.flicker(selectorLeft, 1, 0.04, true);
					FlxFlicker.flicker(selectorRight, 1, 0.04, true);
	
					FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.04, true, false, function(flick:FlxFlicker):Void {
						openSelectedSubstate(options[curSelected]);
					});
	
					FlxG.sound.play(Paths.getSound('confirmMenu'));
				}
				else {
					openSelectedSubstate(options[curSelected]);
				}
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = CoolUtil.boundSelection(curSelected + change, options.length);

		for (item in grpOptions.members)
		{
			item.alpha = 0.6;

			if (item.ID == curSelected)
			{
				item.alpha = 1;

				selectorLeft.x = item.x - 63;
				selectorLeft.y = item.y;

				selectorRight.x = item.x + item.width + 15;
				selectorRight.y = item.y;
			}
		}

		FlxG.sound.play(Paths.getSound('scrollMenu'));
	}
}