package;

#if desktop
import Discord.DiscordClient;
#end

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import haxe.Json;

import flixel.FlxG;
import openfl.Assets;
import flixel.FlxSprite;
import shaders.ColorSwap;
import flixel.math.FlxMath;
import lime.app.Application;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepad;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

typedef TitleData =
{
	titlex:Float,
	titley:Float,

	startx:Float,
	starty:Float,

	gfx:Float,
	gfy:Float,

	backgroundSprite:String,

	bpm:Int
}

class TitleState extends MusicBeatState
{
	public static var muteKeys:Array<FlxKey> = [FlxKey.ZERO];
	public static var volumeDownKeys:Array<FlxKey> = [FlxKey.NUMPADMINUS, FlxKey.MINUS];
	public static var volumeUpKeys:Array<FlxKey> = [FlxKey.NUMPADPLUS, FlxKey.PLUS];

	public static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var textGroup:FlxGroup;
	var ngSpr:FlxSprite;

	var curWacky:Array<String> = [];

	var titleJSON:TitleData;

	public override function create():Void
	{
		Paths.clearStoredMemory();
		Paths.clearUnusedMemory();

		#if LUA_ALLOWED
		Paths.pushGlobalMods();
		#end

		WeekData.loadTheFirstEnabledMod();

		super.create();

		OptionData.loadPrefs();

		FlxG.game.focusLostFramerate = 60;
		FlxG.sound.muteKeys = muteKeys;
		FlxG.sound.volumeDownKeys = volumeDownKeys;
		FlxG.sound.volumeUpKeys = volumeUpKeys;
		FlxG.keys.preventDefaultKeys = [TAB];

		curWacky = FlxG.random.getObject(getIntroTextShit());

		Highscore.load();

		PlayerSettings.init();
		OptionData.loadCtrls();

		PlayStateChangeables.loadChangeables();

		#if sys
		if (!FileSystem.exists(Sys.getCwd() + "\\assets\\replays")) {
			FileSystem.createDirectory(Sys.getCwd() + "\\assets\\replays");
		}
		#end
		
		titleJSON = Json.parse(Paths.getTextFromFile('title/gfDanceTitle.json'));

		if (OptionData.checkForUpdates && !initialized)
		{
			var http = new haxe.Http("https://raw.githubusercontent.com/AlanSurtaev2008/FNF-AlsuhEngine/main/version.downloadMe");
			var returnedData:Array<String> = [];
	
			http.onData = function(data:String)
			{
				returnedData[0] = data.substring(0, data.indexOf(';'));
				returnedData[1] = data.substring(data.indexOf('-'), data.length);
	
				OutdatedState.newVersion = returnedData[0].trim();
				OutdatedState.curChanges = returnedData[1];
			}
	
			http.onError = function(error)
			{
				trace('error: $error');
			}
	
			http.request();
		}

		if (initialized)
		{
			new FlxTimer().start(1, function(tmr:FlxTimer)
			{
				startIntro();
			});
		}
		else
		{
			persistentUpdate = true;
			persistentDraw = true;

			FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));

			startIntro();
		}

		#if desktop
		DiscordClient.initialize();
		
		Application.current.onExit.add(function(exitCode:Int)
		{
			DiscordClient.shutdown();
		});
		#end
	}

	var swagShader:ColorSwap = null;

	var logoBl:FlxSprite;
	var gfDance:FlxSprite;
	var danceLeft:Bool = false;
	var titleText:FlxSprite;

	var titleTextColors:Array<FlxColor> = [0xFF33FFFF, 0xFF3333CC];
	var titleTextAlphas:Array<Float> = [1, .64];

	function startIntro():Void
	{
		Conductor.changeBPM(titleJSON.bpm);
		persistentUpdate = true;

		var bg:FlxSprite = new FlxSprite();

		if (titleJSON.backgroundSprite != null && titleJSON.backgroundSprite.length > 0 && titleJSON.backgroundSprite != 'none') {
			bg.loadGraphic(Paths.getImage('title/' + titleJSON.backgroundSprite));
		} else {
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		}

		add(bg);

		swagShader = new ColorSwap();

		gfDance = new FlxSprite(titleJSON.gfx, titleJSON.gfy);
		gfDance.frames = Paths.getSparrowAtlas('title/gfDanceTitle');
		gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
		gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);
		gfDance.antialiasing = OptionData.globalAntialiasing;
		gfDance.shader = swagShader.shader;
		add(gfDance);

		logoBl = new FlxSprite(titleJSON.titlex, titleJSON.titley);
		logoBl.frames = Paths.getSparrowAtlas('title/logoBumpin');
		logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
		logoBl.antialiasing = OptionData.globalAntialiasing;
		logoBl.shader = swagShader.shader;
		add(logoBl);

		titleText = new FlxSprite(titleJSON.startx, titleJSON.starty);

		#if (desktop && MODS_ALLOWED)
		var path = "mods/" + Paths.currentModDirectory + "/images/title/titleEnter.png";

		if (!FileSystem.exists(path)) {
			path = "mods/images/title/titleEnter.png";
		}

		if (!FileSystem.exists(path)) {
			path = "assets/images/title/titleEnter.png";
		}

		titleText.frames = FlxAtlasFrames.fromSparrow(BitmapData.fromFile(path), File.getContent(StringTools.replace(path, ".png", ".xml")));
		#else
		titleText.frames = Paths.getSparrowAtlas('title/titleEnter');
		#end

		var animFrames:Array<FlxFrame> = [];

		@:privateAccess
		{
			titleText.animation.findByPrefix(animFrames, "ENTER IDLE");
			titleText.animation.findByPrefix(animFrames, "ENTER FREEZE");
		}
		
		if (animFrames.length > 0)
		{
			newTitle = true;
			
			titleText.animation.addByPrefix('idle', "ENTER IDLE", 24);
			titleText.animation.addByPrefix('press', OptionData.flashingLights ? "ENTER PRESSED" : "ENTER FREEZE", 24);
		}
		else
		{
			newTitle = false;
			
			titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
			titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
		}

		titleText.antialiasing = OptionData.globalAntialiasing;
		titleText.animation.play('idle');
		titleText.updateHitbox();
		add(titleText);

		blackScreen = new FlxSprite();
		blackScreen.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		add(blackScreen);

		textGroup = new FlxGroup();
		add(textGroup);

		ngSpr = new FlxSprite(0, FlxG.height * 0.52);
		ngSpr.loadGraphic(Paths.getImage('title/newgrounds_logo'));
		ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
		ngSpr.updateHitbox();
		ngSpr.screenCenter(X);
		ngSpr.antialiasing = OptionData.globalAntialiasing;
		ngSpr.visible = false;
		add(ngSpr);

		FlxG.mouse.visible = false;

		if (initialized) {
			skipIntro();
		} else {
			initialized = true;
		}
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Paths.getTextFromFile('data/introText.txt');

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	var skippedIntro:Bool = false;

	var newTitle:Bool = false;
	var titleTimer:Float = 0;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.sound.music != null)
		{
			Conductor.songPosition = FlxG.sound.music.time;
		}

		if (FlxG.keys.justPressed.F)
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

		if (gamepad != null)
		{
			if (gamepad.justPressed.START)
				pressedEnter = true;

			#if switch
			if (gamepad.justPressed.B)
				pressedEnter = true;
			#end
		}

		if (newTitle)
		{
			titleTimer += CoolUtil.boundTo(elapsed, 0, 1);
			if (titleTimer > 2) titleTimer -= 2;
		}

		if (initialized && !transitioning && skippedIntro)
		{
			#if sys
			if (controls.BACK) {
				Sys.exit(0);
			}
			#end

			if (newTitle && !pressedEnter)
			{
				var timer:Float = titleTimer;

				if (timer >= 1) {
					timer = (-timer) + 2;
				}
				
				timer = FlxEase.quadInOut(timer);
				
				titleText.color = FlxColor.interpolate(titleTextColors[0], titleTextColors[1], timer);
				titleText.alpha = FlxMath.lerp(titleTextAlphas[0], titleTextAlphas[1], timer);
			}
			
			if (pressedEnter)
			{
				if (titleText != null)
				{
					titleText.color = FlxColor.WHITE;
					titleText.alpha = 1;
	
					titleText.animation.play('press');
				}

				FlxG.camera.flash(OptionData.flashingLights ? FlxColor.WHITE : 0x4CFFFFFF, 1);
				FlxG.sound.play(Paths.getSound('confirmMenu'), 0.7);

				transitioning = true;

				new FlxTimer().start(1, function(tmr:FlxTimer)
				{
					if (OptionData.checkForUpdates && OutdatedState.newVersion != MainMenuState.engineVersion && !OutdatedState.leftState)
					{
						trace('There is a new version ' + OutdatedState.newVersion + '!');
						FlxG.switchState(new OutdatedState());
					}
					else
					{
						trace('You now have the latest version');
						FlxG.switchState(new MainMenuState());
					}
				});
			}
		}

		if (initialized && pressedEnter && !skippedIntro)
		{
			skipIntro();
		}

		if (swagShader != null)
		{
			if (controls.RESET) swagShader.hue = 0;

			if (controls.UI_LEFT) swagShader.hue -= elapsed * 0.1;
			if (controls.UI_RIGHT) swagShader.hue += elapsed * 0.1;
		}
	}

	function createCoolText(textArray:Array<String>):Void
	{
		if (textGroup != null)
		{
			for (i in 0...textArray.length)
			{
				var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
				money.screenCenter(X);
				money.y += (i * 60) + 200;
				textGroup.add(money);
			}
		}
	}

	function addMoreText(text:String):Void
	{
		if (textGroup != null)
		{
			var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
			coolText.screenCenter(X);
			coolText.y += (textGroup.length * 60) + 200;
			textGroup.add(coolText);
		}
	}

	function deleteCoolText():Void
	{
		if (textGroup != null)
		{
			while (textGroup.members.length > 0)
			{
				textGroup.remove(textGroup.members[0], true);
			}
		}
	}

	public override function beatHit():Void
	{
		super.beatHit();

		if (logoBl != null)
		{
			logoBl.animation.play('bump');
		}

		if (gfDance != null)
		{
			danceLeft = !danceLeft;

			if (danceLeft)
				gfDance.animation.play('danceRight');
			else
				gfDance.animation.play('danceLeft');
		}

		switch (curBeat)
		{
			case 1:
			{
				if (OptionData.watermarks)
					createCoolText(['afford-set']);
				else
					createCoolText(['ninjamuffin99', 'phantomArcade', 'kawaisprite', 'evilsk8er']);
			}
			case 3:
				addMoreText('present');
			case 4:
				deleteCoolText();
			case 5:
			{
				if (OptionData.watermarks)
					createCoolText(['Original by']);
				else
					createCoolText(['In association', 'with']);
			}
			case 7:
			{
				if (OptionData.watermarks)
				{
					addMoreText('ninjamuffin99');
					addMoreText('phantomArcade');
					addMoreText('kawaisprite');
					addMoreText('evilsk8er');
				}
				else
				{
					addMoreText('newgrounds');
					ngSpr.visible = true;
				}
			}
			case 8:
			{
				deleteCoolText();
				ngSpr.visible = false;
			}
			case 9:
				createCoolText([curWacky[0]]);
			case 11:
				addMoreText(curWacky[1]);
			case 12:
				deleteCoolText();
			case 13:
				addMoreText('Friday');
			case 14:
				addMoreText('Night');
			case 15:
				addMoreText('Funkin');
			case 16:
				skipIntro();
		}
	}

	function skipIntro():Void
	{
		if (!skippedIntro)
		{
			remove(ngSpr);

			blackScreen.visible = false;
			blackScreen.alpha = 0;
			remove(blackScreen);

			remove(textGroup);

			FlxG.camera.flash(FlxColor.WHITE, 4);

			skippedIntro = true;
		}
	}
}
