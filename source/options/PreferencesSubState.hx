package options;

#if desktop
import Discord.DiscordClient;
#end

import options.OptionsMenuState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.ui.FlxBar;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.util.FlxStringUtil;
import flixel.effects.FlxFlicker;

using StringTools;

class PreferencesSubState extends MusicBeatSubState
{
	private static var curSelected:Int = 1;

	private var optionsArray:Array<Option>;
	private var curOption:Option = null;
	private var defaultValue:Option = new Option('Reset to Default Values', true);

	private function getOptions():Void
	{
		addOption(new Option('Graphics', false));

		var option:Option = new Option('Full Screen', // Name
			true, // Selected
			'Should the game be maximized?', // Description
			'fullScreen', //Save data variable name
			'bool', // Variable type
			false); // Default value
		option.onChange = function():Void {
			FlxG.fullscreen = OptionData.fullScreen;
		};
		addOption(option);

		var option:Option = new Option('Screen Resolution',
			true,
			'Choose your preferred screen resolution.',
			'screenRes',
			'string',
			'1280x720',
			['640x360', '852x480', '960x540', '1280x720', '1920x1080', '3840x2160']);
		addOption(option);
		option.onChange = function():Void
		{
			var res:Array<String> = OptionData.screenRes.split('x');
			FlxG.resizeWindow(Std.parseInt(res[0]), Std.parseInt(res[1]));
	
			FlxG.fullscreen = false;
	
			if (!FlxG.fullscreen) {
				FlxG.fullscreen = OptionData.fullScreen;
			}
		};

		//I'd suggest using "Low Quality" as an example for making your own option since it is the simplest here
		var option:Option = new Option('Low Quality',
			true,
			'If checked, disables some background details,\ndecreases loading times and improves performance.',
			'lowQuality',
			'bool',
			false);
		option.blockedOnPause = isPause;
		addOption(option);

		var option:Option = new Option('Anti-Aliasing',
			true,
			'If unchecked, disables anti-aliasing, increases performance\nat the cost of sharper visuals.',
			'globalAntialiasing',
			'bool',
			true);
		option.showBoyfriend = true;
		option.blockedOnPause = isPause;
		option.onChange = function():Void // Changing onChange is only needed if you want to make a special interaction after it changes the value
		{
			for (sprite in members)
			{
				var sprite:Dynamic = sprite; // Make it check for FlxSprite instead of FlxBasic
				var sprite:FlxSprite = sprite; // Don't judge me ok
	
				if (sprite != null && (sprite is FlxSprite) && !(sprite is FlxText)) {
					sprite.antialiasing = OptionData.globalAntialiasing;
				}
			}
		};
		addOption(option);

		var option:Option = new Option('Shaders', //Name
			true,
			'If unchecked, disables shaders.\nIt\'s used for some visual effects, and also CPU intensive for weaker PCs.', //Description
			'shaders', //Save data variable name
			'bool', //Variable type
			true); //Default value
		addOption(option);

		#if !html5 // Apparently other framerates isn't correctly supported on Browser? Probably it has some V-Sync shit enabled by default, idk
		var option:Option = new Option('Framerate',
			true,
			"Pretty self explanatory, isn't it?",
			'framerate',
			'int',
			60);
		addOption(option);

		option.minValue = 60;
		option.maxValue = 240;
		option.displayFormat = '%v FPS';
		option.onChange = function():Void
		{
			if (OptionData.framerate > FlxG.drawFramerate)
			{
				FlxG.updateFramerate = OptionData.framerate;
				FlxG.drawFramerate = OptionData.framerate;
			}
			else
			{
				FlxG.drawFramerate = OptionData.framerate;
				FlxG.updateFramerate = OptionData.framerate;
			}
		};
		#end

		addOption(new Option('Gameplay', false));

		var option:Option = new Option('Ghost Tapping',
			true,
			"If checked, you won't get misses from pressing keys\nwhile there are no notes able to be hit.",
			'ghostTapping',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Controller Mode',
			true,
			'Check this if you want to play with\na controller instead of using your Keyboard.',
			'controllerMode',
			'bool',
			false);
		option.blockedOnPause = isPause;
		addOption(option);

		// I'd suggest using "Downscroll" as an example for making your own option since it is the simplest here

		var option:Option = new Option('Downscroll',
			true,
			'If checked, notes go Down instead of Up, simple enough.',
			'downScroll',
			'bool',
			false);
		option.blockedOnPause = isPause;
		addOption(option);

		var option:Option = new Option('Middlescroll',
			true,
			'If checked, your notes get centered.',
			'middleScroll',
			'bool',
			false);
		option.blockedOnPause = isPause;
		addOption(option);

		var option:Option = new Option('Opponent Notes:',
			true,
			'What should the opponent (CPU) notes?',
			'opponentStrumsType',
			'string',
			'Glow',
			['Glow', 'Glow no Sustains', 'Glow, while Sus', 'Static', 'Disabled']);

		if (isPause)
		{
			if (option.getValue() == 'Disabled') {
				option.blockedOnPause = isPause;
			}
			else {
				option.options = ['Glow', 'Glow no Sustains', 'Glow, while Sus', 'Static'];
			}
		}

		addOption(option);

		var option:Option = new Option('Disable Reset Button',
			true,
			"If checked, pressing Reset won't do anything.",
			'noReset',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Hitsound Type:',
			true,
			'What should the sound \"Tick\"?',
			'hitsoundType',
			'string',
			'Kade',
			['None', 'Kade', 'Psych']);
		addOption(option);
		option.onChange = onChangeHitsoundVolume;
		option.isIgnoriteFunctionOnReset = true;

		var option:Option = new Option('Hitsound Volume',
			true,
			'Funny notes does \"Tick!\" when you hit them."',
			'hitsoundVolume',
			'percent',
			0);
		addOption(option);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = onChangeHitsoundVolume;
		option.isIgnoriteFunctionOnReset = true;

		var option:Option = new Option('Rating Offset',
			true,
			'Changes how late/early you have to hit for a "Sick!"\nHigher values mean you have to hit later.',
			'ratingOffset',
			'int',
			0);
		option.displayFormat = '%vms';
		option.scrollSpeed = 20;
		option.minValue = -30;
		option.maxValue = 30;
		addOption(option);

		var option:Option = new Option('Sick! Hit Window',
			true,
			'Changes the amount of time you have\nfor hitting a "Sick!" in milliseconds.',
			'sickWindow',
			'int',
			45);
		option.displayFormat = '%vms';
		option.scrollSpeed = 15;
		option.minValue = 15;
		option.maxValue = 45;
		addOption(option);

		var option:Option = new Option('Good Hit Window',
			true,
			'Changes the amount of time you have\nfor hitting a "Good" in milliseconds.',
			'goodWindow',
			'int',
			90);
		option.displayFormat = '%vms';
		option.scrollSpeed = 30;
		option.minValue = 15;
		option.maxValue = 90;
		addOption(option);

		var option:Option = new Option('Bad Hit Window',
			true,
			'Changes the amount of time you have\nfor hitting a "Bad" in milliseconds.',
			'badWindow',
			'int',
			135);
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 135;
		addOption(option);

		var option:Option = new Option('Shit Hit Window',
			true,
			'Changes the amount of time you have\nfor hitting a "Shit" in milliseconds.',
			'shitWindow',
			'int',
			160);
		option.displayFormat = '%vms';
		option.scrollSpeed = 60;
		option.minValue = 15;
		option.maxValue = 160;
		addOption(option);

		var option:Option = new Option('Safe Frames',
			true,
			'Changes how many frames you have for\nhitting a note earlier or late.',
			'safeFrames',
			'float',
			10);
		option.scrollSpeed = 5;
		option.minValue = 2;
		option.maxValue = 10;
		option.changeValue = 0.1;
		option.onChange = function():Void {
			Conductor.safeZoneOffset = (OptionData.safeFrames / 60) * 1000;
		};
		addOption(option);

		addOption(new Option('Visuals and UI', false));

		var option:Option = new Option('Camera Zooms',
			true,
			"If unchecked, the camera won't zoom in on a beat hit.",
			'camZooms',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Camera Shakes',
			true,
			"Uncheck this if you're sensitive to camera shake!",
			'camShakes',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Icon Zooms',
			true,
			"If unchecked, the icons won't zoom in on a beat hit.",
			'iconZooms',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Consume Notes\'s Sustains:',
			true,
			"What should the Consume Notes's Sustains?",
			'sustainsType',
			'string',
			'New',
			['New', 'Old']);
		option.blockedOnPause = isPause;
		addOption(option);

		var option:Option = new Option('Note Splash Opacity:',
			true,
			"Set the alpha for the Note Splashes, shown when hitting \"Sick!\" notes.",
			'splashOpacity',
			'percent',
			1);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		addOption(option);

		var option:Option = new Option('Time Bar:',
			true,
			"What should the Time Bar display?",
			'songPositionType',
			'string',
			'Time Left and Elapsed',
			['Time Left and Elapsed', 'Time Left', 'Time Elapsed', 'Song Name', 'Disabled']);
		option.onChange = function():Void
		{
			if (isPause)
			{
				var showTime:Bool = OptionData.songPositionType != 'Disabled';
	
				PlayState.instance.songPosBG.visible = showTime;
				PlayState.instance.songPosBar.visible = showTime;
				PlayState.instance.songPosName.visible = showTime;
	
				var curTime:Float = Conductor.songPosition - OptionData.noteOffset;
				if (curTime < 0) curTime = 0;
	
				PlayState.instance.songPositionBar = (curTime / PlayState.instance.songLength);
	
				var songCalc:Float = (PlayState.instance.songLength - curTime);
				if (OptionData.songPositionType == 'Time Elapsed') songCalc = curTime;
	
				var secondsTotal:Int = Math.floor(songCalc / 1000);
				if (secondsTotal < 0) secondsTotal = 0;
	
				var secondsTotalBlyad:Int = Math.floor(curTime / 1000);
				if (secondsTotalBlyad < 0) secondsTotalBlyad = 0;
	
				PlayState.instance.songPosName.text = PlayState.SONG.songName + " - " + CoolUtil.getDifficultyName(PlayState.lastDifficulty, PlayState.difficulties);
	
				if (OptionData.songPositionType != 'Song Name')
				{
					switch (OptionData.songPositionType)
					{
						case 'Time Left and Elapsed':
							PlayState.instance.songPosName.text += ' (' + FlxStringUtil.formatTime(secondsTotalBlyad, false) + ' / ' + FlxStringUtil.formatTime(secondsTotal, false) + ')';
						case 'Time Elapsed':
							PlayState.instance.songPosName.text += ' (' + FlxStringUtil.formatTime(secondsTotalBlyad, false) + ')';
						default:
							PlayState.instance.songPosName.text += ' (' + FlxStringUtil.formatTime(secondsTotal, false) + ')';
					}
				}
			}
		};
		addOption(option);

		var option:Option = new Option('Score Text',
			true,
			"If unchecked, the score text is not displayed.",
			'scoreText',
			'bool',
			true);
		option.onChange = function():Void
		{
			if (isPause) {
				PlayState.instance.scoreTxt.visible = OptionData.scoreText;
			}
		};
		addOption(option);

		var option:Option = new Option('Cutscenes in:',
			true,
			"What mode should cutscenes be in?",
			'cutscenesInType',
			'string',
			'Story',
			['Story', 'Story and Freeplay', 'Freeplay', 'Freeplay and Replay', 'Replay', 'Replay and Story', 'Everywhere', 'Nowhere']);
		addOption(option);

		var option:Option = new Option('Skip Cutscene Replay',
			true,
			"Check the box if you want to see only one cutscene.",
			'skipCutscenes',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Naughtyness',
			true,
			"Uncheck this if your mom doesn't allow swearing.",
			'naughtyness',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Combo Stacking',
			true,
			"If unchecked, Ratings and Combo won't stack, saving on System Memory and making them easier to read",
			'comboStacking',
			'bool',
			true);
		addOption(option);

		var option:Option = new Option('Show Ratings',
			true,
			"If unchecked, hides combo ratings.",
			'showRatings',
			'bool',
			true);
		option.onChange = function():Void
		{
			if (isPause)
			{
				for (rating in PlayState.instance.grpRatings) {
					rating.goToVisible();
				}
			}
		};
		addOption(option);

		var option:Option = new Option('Show Numbers',
			true,
			"If unchecked, hides combo numbers.",
			'showNumbers',
			'bool',
			true);
		option.onChange = function():Void
		{
			if (isPause)
			{
				for (number in PlayState.instance.grpNumbers) {
					number.goToVisible();
				}
			}
		};
		addOption(option);

		var option:Option = new Option('Health Bar Transparency',
			true,
			'How much transparent should the health bar and icons be.',
			'healthBarAlpha',
			'percent',
			1);
		option.scrollSpeed = 1.6;
		option.minValue = 0.0;
		option.maxValue = 1;
		option.changeValue = 0.1;
		option.decimals = 1;
		option.onChange = function():Void
		{
			if (isPause)
			{
				PlayState.instance.healthBarBG.alpha = OptionData.healthBarAlpha;
				PlayState.instance.healthBar.alpha = OptionData.healthBarAlpha;
				PlayState.instance.iconP1.alpha = OptionData.healthBarAlpha;
				PlayState.instance.iconP2.alpha = OptionData.healthBarAlpha;
			}
		};
		addOption(option);

		var option:Option = new Option('Pause Screen Song:',
			true,
			"What song do you prefer for the Pause Screen?",
			'pauseMusic',
			'string',
			'Tea Time',
			['None', 'Breakfast', 'Tea Time']);
		option.onChange = function():Void
		{
			FreeplayMenuState.destroyFreeplayVocals();

			if (isPause)
			{
				if (OptionData.pauseMusic == 'None') {
					PauseSubState.pauseMusic.volume = 0;
				}
				else
				{
					PauseSubState.pauseMusic.loadEmbedded(Paths.getMusic(Paths.formatToSongPath(OptionData.pauseMusic)), true, true);
					PauseSubState.pauseMusic.volume = 0.5;
					PauseSubState.pauseMusic.play();
				}
			}
			else
			{
				if (OptionData.pauseMusic == 'None') {
					FlxG.sound.music.volume = 0;
				}
				else {
					FlxG.sound.playMusic(Paths.getMusic(Paths.formatToSongPath(OptionData.pauseMusic)));
				}
			}
	
			changedMusic = true;
		};
		option.isIgnoriteFunctionOnReset = true;
		addOption(option);

		#if !mobile
		var option:Option = new Option('FPS Counter',
			true,
			'If unchecked, hides FPS Counter.',
			'fpsCounter',
			'bool',
			false);
		addOption(option);
		option.onChange = function():Void
		{
			if (Main.fpsCounter != null) {
				Main.fpsCounter.visible = OptionData.fpsCounter;
			}
		};

		var option:Option = new Option('Rainbow FPS Counter',
			true,
			'If checked, FPS Counter becomes colorful.',
			'rainFPS',
			'bool',
			false);
		addOption(option);

		var option:Option = new Option('Memory Counter',
			true,
			'If unchecked, hides Memory Counter.',
			'memoryCounter',
			'bool',
			false);
		addOption(option);
		option.onChange = function():Void
		{
			if (Main.memoryCounter != null) {
				Main.memoryCounter.visible = OptionData.memoryCounter;
			}
		};

		var option:Option = new Option('Rainbow Memory Counter',
			true,
			'If checked, Memory counter becomes colorful.',
			'rainMemory',
			'bool',
			false);
		addOption(option);
		#end

		#if CHECK_FOR_UPDATES
		var option:Option = new Option('Check for Updates',
			true,
			'On Release builds, turn this on to check for updates when you start the game.',
			'checkForUpdates',
			'bool',
			true);
		addOption(option);
		#end

		var option:Option = new Option('Auto Pause',
			true,
			'If checked, the game will automatically freeze itself when not in focus.',
			'autoPause',
			'bool',
			false);
		addOption(option);
		option.onChange = function():Void {
			FlxG.autoPause = OptionData.autoPause;
		};

		var option:Option = new Option('Watermarks',
			true,
			'If unchecked, hides all watermarks on the engine.',
			'watermarks',
			'bool',
			true);
		addOption(option);

		#if PRELOAD_ALL
		var option:Option = new Option('Loading Screen',
			true,
			'Check this if you like to enjoy loading.',
			'loadingScreen',
			'bool',
			false);
		addOption(option);
		#end

		var option:Option = new Option('Flashing Lights',
			true,
			"Uncheck this if you're sensitive to flashing lights!",
			'flashingLights',
			'bool',
			true);
		addOption(option);

		addOption(defaultValue);
	}

	public function addOption(option:Option)
	{
		if (optionsArray == null || optionsArray.length < 1) optionsArray = [];

		if (option != null) {
			optionsArray.push(option);
		}
	}

	var isPause:Bool = false;

	public function new(?isPause:Bool = false):Void
	{
		super();

		this.isPause = isPause;
	}

	private var grpOptions:FlxTypedGroup<Alphabet>;
	private var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	private var grpTexts:FlxTypedGroup<AttachedText>;

	private var descBox:FlxSprite;
	private var descText:FlxText;

	private var boyfriend:Character = null;

	public override function create():Void
	{
		super.create();

		#if desktop
		DiscordClient.changePresence("In the Options Menu - Preferences", null);
		#end

		getOptions();

		if (!isPause) {
			Conductor.changeBPM(102);
		}

		var bg:FlxSprite = new FlxSprite();

		if (isPause)
		{
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			bg.alpha = 0.6;
			bg.scrollFactor.set();
		}
		else
		{
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
		}

		add(bg);

		if (isPause)
		{
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
		}

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		for (i in 0...optionsArray.length)
		{
			var leOption:Option = optionsArray[i];
			leOption.onPause = isPause;

			var isCentered:Bool = unselectableCheck(i, true);

			var optionText:Alphabet = new Alphabet(isCentered ? FlxG.width / 2 : (leOption.type != 'bool' ? 180 : 300), 270, leOption.name, isCentered);
			optionText.isMenuItem = true;
			optionText.changeX = false;
			optionText.lerpMult /= 2;
			optionText.targetY = i - curSelected;
			optionText.distancePerItem.y = 100;
			grpOptions.add(optionText);

			if (!isCentered)
			{
				switch (leOption.type)
				{
					case 'bool':
					{
						var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, leOption.getValue() == true);
						checkbox.sprTracker = optionText;
						checkbox.ID = i;
						checkbox.snapToUpdateVariables();
						checkboxGroup.add(checkbox);
					}
					case 'int' | 'float' | 'percent' | 'string':
					{
						var valueText:AttachedText = new AttachedText('' + leOption.getValue(), optionText.width + 80);
						valueText.sprTracker = optionText;
						valueText.ID = i;
						valueText.snapToUpdateVariables();
						grpTexts.add(valueText);
		
						leOption.setChild(valueText);
					}
				}

				updateTextFrom(leOption);
				if (curSelected < 0) curSelected = i;
			}
			else
			{
				optionText.startPosition.y = 315;
				optionText.alignment = CENTERED;
			}

			optionText.snapToPosition();

			if (leOption.showBoyfriend && boyfriend == null && !leOption.blockedOnPause) {
				reloadBoyfriend();
			}
		}

		descBox = new FlxSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.getFont("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		changeSelection();
		reloadCheckboxes();

		if (isPause) cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var flickering:Bool = false;

	var nextAccept:Int = 5;

	var holdTime:Float = 0;
	var holdTimeValue:Float = 0;

	var holdValue:Float = 0;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var pauseMusic:FlxSound = PauseSubState.pauseMusic;

		if (isPause && pauseMusic != null && pauseMusic.volume < 0.5) {
			pauseMusic.volume += 0.01 * elapsed;
		}

		if (FlxG.sound.music != null && !isPause) {
			Conductor.songPosition = FlxG.sound.music.time;
		}

		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			FlxG.sound.play(Paths.getSound('cancelMenu'));

			if (isPause)
			{
				OptionData.savePrefs();

				PlayState.isNextSubState = true;

				FlxG.state.closeSubState();
				FlxG.state.openSubState(new OptionsSubState());
			}
			else {
				close();
			}
		}

		if (!flickering)
		{
			if (optionsArray.length > 1)
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

				if (FlxG.mouse.wheel != 0 && !(FlxG.keys.pressed.ALT && curOption.type != 'bool')) {
					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}

			if ((controls.ACCEPT || FlxG.mouse.justPressed) && nextAccept <= 0)
			{
				if (curOption == defaultValue)
				{
					if (OptionData.flashingLights)
					{
						flickering = true;

						FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flick:FlxFlicker):Void
						{
							reset();
							FlxG.sound.play(Paths.getSound('cancelMenu'));
						});
					}
					else
					{
						reset();

						FlxG.sound.play(Paths.getSound('cancelMenu'));
						reloadCheckboxes();
					}

					FlxG.sound.play(Paths.getSound('confirmMenu'));
				}
				else if (!unselectableCheck(curSelected))
				{
					if (curOption.type == 'bool' && !curOption.blockedOnPause)
					{
						if (OptionData.flashingLights)
						{
							flickering = true;
	
							FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flick:FlxFlicker):Void
							{
								changeBool(curOption);
							});
	
							FlxG.sound.play(Paths.getSound('confirmMenu'));
						}
						else {
							changeBool(curOption);
						}
					}
					else if (curOption.type == 'menu')
					{
						if (OptionData.flashingLights)
						{
							flickering = true;

							FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flick:FlxFlicker):Void
							{
								flickering = false;
								curOption.change();
							});

							FlxG.sound.play(Paths.getSound('confirmMenu'));
						}
						else {
							curOption.change();
						}
					}
				}
			}

			if (controls.RESET)
			{
				curOption.resetToDefault();
				curOption.change();

				FlxG.sound.play(Paths.getSound('scrollMenu'));

				updateTextFrom(curOption);
				reloadCheckboxes();
			}

			if (curOption.type != 'bool' && curOption.type != 'menu' && curOption != defaultValue && !curOption.blockedOnPause)
			{
				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					var pressed:Bool = (controls.UI_LEFT_P || controls.UI_RIGHT_P);

					if (holdTimeValue > 0.5 || pressed) 
					{
						if (pressed)
						{
							var add:Dynamic = null;

							if (curOption.type != 'string') {
								add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
							}

							switch (curOption.type)
							{
								case 'int' | 'float' | 'percent':
								{
									holdValue = curOption.getValue() + add;

									if (holdValue < curOption.minValue)
										holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue)
										holdValue = curOption.maxValue;

									switch (curOption.type)
									{
										case 'int':
										{
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);
										}
										case 'float' | 'percent':
										{
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
										}
									}
								}
								case 'string':
								{
									var num:Int = curOption.curOption; // lol

									if (controls.UI_LEFT_P)
										--num;
									else
										num++;

									if (num < 0)
										num = curOption.options.length - 1;
									else if (num >= curOption.options.length)
										num = 0;

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]); // lol
								}
							}

							updateTextFrom(curOption);

							curOption.change();
							FlxG.sound.play(Paths.getSound('scrollMenu'));
						}
						else if (curOption.type != 'string')
						{
							holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);

							if (holdValue < curOption.minValue) 
								holdValue = curOption.minValue;
							else if (holdValue > curOption.maxValue)
								holdValue = curOption.maxValue;

							switch (curOption.type)
							{
								case 'int':
								{
									curOption.setValue(Math.round(holdValue));
								}
								case 'float' | 'percent':
								{
									curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));
								}
							}

							updateTextFrom(curOption);
							curOption.change();
						}
					}

					if (curOption.type != 'string') {
						holdTimeValue += elapsed;
					}
				}
				else if (controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					clearHold();
				}

				if (FlxG.mouse.wheel != 0 && (FlxG.keys.pressed.ALT && curOption.type != 'bool'))
				{
					if (curOption.type != 'string')
					{
						holdValue += -(curOption.scrollSpeed / 50) * FlxG.mouse.wheel;

						if (holdValue < curOption.minValue) 
							holdValue = curOption.minValue;
						else if (holdValue > curOption.maxValue)
							holdValue = curOption.maxValue;

						switch (curOption.type)
						{
							case 'int':
							{
								curOption.setValue(Math.round(holdValue));
							}
							case 'float' | 'percent':
							{
								curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));
							}
						}
		
						updateTextFrom(curOption);
						curOption.change();

						FlxG.sound.play(Paths.getSound('scrollMenu'));
					}
					else if (curOption.type == 'string')
					{
						var num:Int = curOption.curOption; // lol
						num += (-1 * FlxG.mouse.wheel);

						if (num < 0)
							num = curOption.options.length - 1;
						else if (num >= curOption.options.length)
							num = 0;

						curOption.curOption = num;
						curOption.setValue(curOption.options[num]); // lol

						updateTextFrom(curOption);
						curOption.change();

						FlxG.sound.play(Paths.getSound('scrollMenu'));
					}
				}
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function clearHold():Void
	{
		if (holdTimeValue > 0.5) {
			FlxG.sound.play(Paths.getSound('scrollMenu'));
		}

		holdTimeValue = 0;
	}

	function reset():Void
	{
		flickering = false;

		for (i in 0...optionsArray.length)
		{
			var leOption:Option = optionsArray[i];

			if (!unselectableCheck(i) && leOption != defaultValue)
			{
				leOption.setValue(leOption.defaultValue);

				if (leOption.type != 'bool')
				{
					if (leOption.type == 'string') {
						leOption.curOption = leOption.options.indexOf(leOption.getValue());
					}

					updateTextFrom(leOption);
				}

				if (!leOption.isIgnoriteFunctionOnReset) {
					leOption.change();
				}
			}
		}

		reloadCheckboxes();
	}

	function changeBool(option:Option):Void
	{
		flickering = false;

		FlxG.sound.play(Paths.getSound('scrollMenu'));

		option.setValue((option.getValue() == true) ? false : true);
		option.change();

		reloadCheckboxes();
	}

	function reloadCheckboxes():Void
	{
		for (checkbox in checkboxGroup) {
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
		}
	}

	function updateTextFrom(option:Option):Void
	{
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();

		if (option.type == 'percent') val *= 100;

		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function onChangeHitsoundVolume():Void
	{
		#if !web
		if (OptionData.hitsoundType != 'None')
		{
			if (OptionData.hitsoundType == 'Kade') {
				FlxG.sound.play(Paths.getSound('SNAP'), OptionData.hitsoundVolume);
			}
			else if (OptionData.hitsoundType == 'Psych') {
				FlxG.sound.play(Paths.getSound('hitsound'), OptionData.hitsoundVolume);
			}
		}
		#end
	}

	var changedMusic:Bool = false;

	public override function destroy():Void
	{
		super.destroy();

		if (!isPause && changedMusic) FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
	}

	public override function beatHit():Void
	{
		super.beatHit();

		if (boyfriend != null && curBeat % OptionData.danceOffset == 0) {
			boyfriend.dance();
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		do {
			curSelected = CoolUtil.boundSelection(curSelected + change, optionsArray.length);
		}
		while (unselectableCheck(curSelected));

		curOption = optionsArray[curSelected];

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			if (!unselectableCheck(bullShit - 1))
			{
				item.alpha = 0.6;

				if (item.targetY == 0)
				{
					item.alpha = 1;

					for (checkbox in checkboxGroup)
					{
						checkbox.alpha = 0.6;

						if (checkbox.sprTracker == item) {
							checkbox.alpha = 1;
						}
					}

					for (text in grpTexts)
					{
						text.alpha = 0.6;

						if (text.sprTracker == item) {
							text.alpha = 1;
						}
					}
				}
			}
		}

		descText.text = curOption.description;
		descText.screenCenter(Y);
		descText.y += 270;
		descText.visible = curOption.description != '';

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();
		descBox.visible = curOption.description != '';

		if (boyfriend != null) {
			boyfriend.visible = curOption.showBoyfriend && !curOption.blockedOnPause;
		}

		FlxG.sound.play(Paths.getSound('scrollMenu'));
	}

	public function reloadBoyfriend():Void
	{
		var wasVisible:Bool = false;

		if (boyfriend != null)
		{
			wasVisible = boyfriend.visible;
			boyfriend.kill();
			remove(boyfriend);

			boyfriend.destroy();
		}

		boyfriend = new Character(840, 170, 'bf', true);
		boyfriend.setGraphicSize(Std.int(boyfriend.width * 0.75));
		boyfriend.updateHitbox();
		boyfriend.dance();
		insert(members.indexOf(grpOptions), boyfriend);

		boyfriend.visible = wasVisible;
	}	

	private function unselectableCheck(num:Int, ?checkDefaultValue:Bool = false):Bool
	{
		if (optionsArray[num] == defaultValue) {
			return checkDefaultValue;
		}

		return optionsArray[num].selected == false && optionsArray[num] != defaultValue;
	}
}