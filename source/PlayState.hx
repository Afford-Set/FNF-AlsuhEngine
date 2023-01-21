package;

import haxe.Json;
import haxe.format.JsonParser;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

#if sys
import sys.io.File;
import sys.FileSystem;
#end

#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

import Song;
import Note;
import Rating;
import Section;
import StageData;
import FunkinLua;
import PhillyGlow;
import Achievements;
import DialogueBoxPsych;
import shaders.WiggleEffect;
import transition.Transition;

#if MP4_ALLOWED
import hxcodec.VideoHandler;
#end

#if WEBM_ALLOWED
import webmlmfao.WebmHandler;
import webmlmfao.VideoSubState;
import webmlmfao.BackgroundVideo;
#end

#if (!flash && MODS_ALLOWED)
import openfl.filters.ShaderFilter;
import flixel.addons.display.FlxRuntimeShader;
#end

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.ui.FlxBar;
import lime.utils.Assets;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxSort;
import flixel.util.FlxSave;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import flixel.util.FlxCollision;
import flixel.util.FlxStringUtil;
import openfl.filters.ShaderFilter;
import flixel.group.FlxSpriteGroup;
import openfl.events.KeyboardEvent;
import animateatlas.AtlasFrameMaker;
import flixel.input.keyboard.FlxKey;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.atlas.FlxAtlas;
import openfl.utils.Assets as OpenFlAssets;
import flixel.animation.FlxAnimationController;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.effects.chainable.FlxEffectSprite;

using StringTools;

class PlayState extends MusicBeatState
{
	public static var instance:PlayState = null;

	public var luaArray:Array<FunkinLua> = [];
	public var luaDebugGroup:FlxTypedGroup<DebugLuaText>;

	public var variables:Map<String, Dynamic> = new Map<String, Dynamic>();

	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();

	public var spawnTime:Float = 2000;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var generatedMusic:Bool = false;

	public function set_songSpeed(value:Float):Float
	{
		if (generatedMusic)
		{
			var ratio:Float = value / songSpeed; // funny word huh
	
			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio);
		}

		songSpeed = value;
		noteKillOffset = 350 / songSpeed;

		return value;
	}

	public static var STRUM_X:Float = 42;
	public static var STRUM_X_MIDDLESCROLL:Float = -278;

	public static var SONG:SwagSong = null;

	/**
	 * `PlayState.curStage` is deprecated, use `PlayState.SONG.stage` instead
	 */
	public static var curStage:String = '';

	public static var rep:Replay;
	#if WEBM_ALLOWED
	public static var webmHandler:WebmHandler;
	#end
	public static var daPixelZoom:Float = 6;
	public static var isPixelStage:Bool = false;
	public static var isNextSubState:Bool = false;
	public static var gameMode:String = 'story';
	public static var isStoryMode:Bool = false;
	public static var firstSong:String = 'story';
	public static var storyWeekText:String = 'tutorial';
	public static var storyWeek(get, never):Int;
	static function get_storyWeek():Int return WeekData.weeksList.indexOf(PlayState.storyWeekText);

	public static var storyWeekName:String = 'Tutorial';
	public static var storyPlaylist:Array<String> = [];
	public static var weekLength:Int = 0;
	public static var chartingMode:Bool = false;
	public static var difficulties:Array<Dynamic> =
	[
		['Easy',	'Normal',	'Hard'],
		['easy',	'normal',	'hard'],
		['-easy',	'',			'-hard']
	];
	public static var storyDifficultyID:String = 'normal';

	public static var storyDifficulty(get, never):Int;
	static function get_storyDifficulty():Int return CoolUtil.getDifficultyIndex(storyDifficultyID);

	public static var lastDifficulty:String = 'normal';
	public static var lastDifficultyNumber(get, never):Int;
	static function get_lastDifficultyNumber():Int return CoolUtil.getDifficultyIndex(lastDifficulty);

	public static var seenCutscene:Bool = false;
	public static var usedPractice:Bool = false;

	public static var hasWebmCutscene:Bool = false;

	var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public static var debugKeysChart:Array<FlxKey>;
	public static var debugKeysCharacter:Array<FlxKey>;

	public var videoSprite:FlxSprite;

	public var useVideo:Bool = false;
	public var stopUpdate:Bool = false;
	public var removedVideo:Bool = false;

	public var boyfriendGroup:FlxSpriteGroup;
	public var boyfriend:Boyfriend;

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	
	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var boyfriendCameraOffset:Array<Float> = null;

	public var iconP1:HealthIcon;

	public function loadBF(name:String):Void
	{
		boyfriend = new Boyfriend(0, 0, name);
		startCharacterPos(boyfriend, boyfriendGroup);
		boyfriendGroup.add(boyfriend);
		startCharacterLua(boyfriend.curCharacter);

		if (boyfriend != null)
		{
			GameOverSubState.characterName = boyfriend.deathChar;
			GameOverSubState.deathSoundName = boyfriend.deathSound;
			GameOverSubState.loopSoundName = boyfriend.deathMusic;
			GameOverSubState.endSoundName = boyfriend.deathConfirm;
		}
	}

	public var dadGroup:FlxSpriteGroup;
	public var dad:Character;

	public var DAD_X:Float = 770;
	public var DAD_Y:Float = 100;
	
	public var dadMap:Map<String, Character> = new Map<String, Character>() ;
	public var opponentCameraOffset:Array<Float> = null;

	public var iconP2:HealthIcon;

	public function loadDad(name:String):Void
	{
		dad = new Character(0, 0, name);
		startCharacterPos(dad, dadGroup, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);
	}

	public var gfGroup:FlxSpriteGroup;
	public var gf:Character;

	public var gfDisabled:Bool = false;

	public var gfSpeed:Int = 1;

	public var GF_X:Float = 770;
	public var GF_Y:Float = 100;
	
	public var gfMap:Map<String, Character> = new Map<String, Character>();
	public var girlfriendCameraOffset:Array<Float> = null;

	public function loadGF(name:String):Void
	{
		if (!gfDisabled)
		{
			gf = new Character(0, 0, name);
			startCharacterPos(gf, gfGroup);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);
		}

		if (gf != null && gf.curCharacter == 'pico-speaker' && tankmanRun != null)
		{
			if (OptionData.lowQuality == false)
			{
				var firstTank:TankmenBG = new TankmenBG(20, 500, true);
				firstTank.resetShit(20, 600, true);
				firstTank.strumTime = 10;
				tankmanRun.add(firstTank);

				for (i in 0...TankmenBG.animationNotes.length)
				{
					if (FlxG.random.bool(16))
					{
						var tankBih = tankmanRun.recycle(TankmenBG);
						tankBih.strumTime = TankmenBG.animationNotes[i][0];
						tankBih.resetShit(500, 200 + FlxG.random.int(50, 100), TankmenBG.animationNotes[i][1] < 2);
						tankmanRun.add(tankBih);
					}
				}
			}
		}
	}

	public function startCharacterPos(char:Character, group:FlxSpriteGroup, ?gfCheck:Bool = false):Void
	{
		if (gfCheck && char.curCharacter.startsWith('gf')) // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
		{
			group.setPosition(GF_X, GF_Y);

			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;

			gf.visible = false;
		}

		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function addCharacterToList(newCharacter:String, type:Int):Void
	{
		switch (type)
		{
			case 0:
			{
				if (!boyfriendMap.exists(newCharacter))
				{
					var newBoyfriend:Boyfriend = new Boyfriend(0, 0, newCharacter);
					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);

					startCharacterPos(newBoyfriend, boyfriendGroup);
					newBoyfriend.alpha = 0.00001;
					startCharacterLua(newBoyfriend.curCharacter);
				}
			}
			case 1:
			{
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);

					startCharacterPos(newDad, dadGroup, true);
					newDad.alpha = 0.00001;
					startCharacterLua(newDad.curCharacter);
				}
			}
			case 2:
			{
				if (!gfMap.exists(newCharacter))
				{
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.scrollFactor.set(0.95, 0.95);
					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);

					startCharacterPos(newGf, gfGroup);
					newGf.alpha = 0.00001;
					startCharacterLua(newGf.curCharacter);
				}
			}
		}
	}

	private function loadCharGroups():Void
	{
		gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		add(gfGroup);

		dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		add(dadGroup);

		boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		add(boyfriendGroup);
	}

	public function addBehindGF(bsc:FlxBasic):Void
	{
		if (bsc == null || !bsc.alive) return;
		insert(members.indexOf(gfGroup), bsc);
	}

	public function addBehindBF(bsc:FlxBasic):Void
	{
		if (bsc == null || !bsc.alive) return;
		insert(members.indexOf(boyfriendGroup), bsc);
	}

	public function addBehindDad(bsc:FlxBasic):Void
	{
		if (bsc == null || !bsc.alive) return;
		insert(members.indexOf(dadGroup), bsc);
	}

	public function reloadHealthBarColors():Void
	{
		healthBar.createFilledBar(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
			FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
		healthBar.updateBar();
	}

	private var allowPlayCutscene(default, set):Bool = false;

	private function set_allowPlayCutscene(value:Bool):Bool
	{
		allowPlayCutscene = value;

		setOnLuas('allowPlayCutscene', allowPlayCutscene);
		setOnLuas('playingCutscene', allowPlayCutscene);

		return allowPlayCutscene;
	}

	public var defaultCamZoom:Float = 1.05;

	var dadbattleBlack:BGSprite;
	var dadbattleLight:BGSprite;
	var dadbattleSmokes:FlxSpriteGroup;

	var halloweenBG:BGSprite;
	var halloweenWhite:BGSprite;

	var curLight:Int = 0;
	var curLightEvent:Int = 0;

	var phillyLightsColors:Array<FlxColor> = [0xFF31A2FD, 0xFF31FD8C, 0xFFFB33F5, 0xFFFD4531, 0xFFFBA633];
	var phillyWindow:BGSprite;
	var phillyStreet:BGSprite;
	var phillyTrain:BGSprite;
	var blammedLightsBlack:FlxSprite;
	var phillyWindowEvent:BGSprite;
	var trainSound:FlxSound;
	var phillyGlowGradient:PhillyGlowGradient;
	var phillyGlowParticles:FlxTypedGroup<PhillyGlowParticle>;

	var limoKillingState:Int = 0;
	var limo:BGSprite;
	var limoMetalPole:BGSprite;
	var limoLight:BGSprite;
	var limoCorpse:BGSprite;
	var limoCorpseTwo:BGSprite;
	var bgLimo:BGSprite;
	var grpLimoParticles:FlxTypedGroup<BGSprite>;
	var grpLimoDancers:FlxTypedGroup<BackgroundDancer>;
	var fastCar:BGSprite;
	var carPassSound:FlxSound;
	var deathSound:FlxSound;

	var upperBoppers:BGSprite;
	var bottomBoppers:BGSprite;
	var santa:BGSprite;
	var heyTimer:Float;

	var bgGirls:BackgroundGirls;
	var bgGhouls:BGSprite;

	var tankWatchtower:BGSprite;
	var tankGround:BGSprite;
	var tankmanRun:FlxTypedGroup<TankmenBG>;
	var foregroundSprites:FlxTypedGroup<BGSprite>;

	var precacheList:Map<String, String> = new Map<String, String>();

	public function loadStage(stage:String):Void
	{
		var stageData:StageFile = StageData.getStageFile(stage);

		if (stageData == null) // Stage couldn't be found, create a dummy stage for preventing a crash
		{
			stageData = {
				directory: "",
				defaultZoom: 0.9,
				isPixelStage: false,

				boyfriend: [770, 100],
				girlfriend: [400, 130],
				opponent: [100, 100],
				hide_girlfriend: false,

				camera_boyfriend: [0, 0],
				camera_opponent: [0, 0],
				camera_girlfriend: [0, 0],
				camera_speed: 1
			};
		}

		defaultCamZoom = stageData.defaultZoom;
		isPixelStage = stageData.isPixelStage;

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];

		gfDisabled = stageData.hide_girlfriend;

		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];

		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if (stageData.camera_speed != null) {
			cameraSpeed = stageData.camera_speed;
		}

		boyfriendCameraOffset = stageData.camera_boyfriend;

		if (boyfriendCameraOffset == null) { // Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];
		}

		opponentCameraOffset = stageData.camera_opponent;

		if (opponentCameraOffset == null) {
			opponentCameraOffset = [0, 0];
		}

		girlfriendCameraOffset = stageData.camera_girlfriend;

		if (girlfriendCameraOffset == null) {
			girlfriendCameraOffset = [0, 0];
		}

		callOnLuas('onLoadStage', []);

		switch (stage)
		{
			case 'stage': // Week 1
			{
				var pathShit:String = 'stage/stageback';

				if (Paths.fileExists('images/stageback.png', IMAGE)) {
					pathShit = 'stageback';
				}

				var bg:BGSprite = new BGSprite(pathShit, -600, -200, 0.9, 0.9);
				add(bg);

				var pathShit:String = 'stage/stagefront';

				if (Paths.fileExists('images/stagefront.png', IMAGE)) {
					pathShit = 'stagefront';
				}

				var stageFront:BGSprite = new BGSprite(pathShit, -650, 600, 0.9, 0.9);
				stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
				stageFront.updateHitbox();
				add(stageFront);

				if (OptionData.lowQuality == false)
				{
					var pathShit:String = 'stage/stage_light';

					if (Paths.fileExists('images/stage_light.png', IMAGE)) {
						pathShit = 'stage_light';
					}

					var stageLight:BGSprite = new BGSprite(pathShit, -125, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					add(stageLight);

					var stageLight:BGSprite = new BGSprite(pathShit, 1225, -100, 0.9, 0.9);
					stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
					stageLight.updateHitbox();
					stageLight.flipX = true;
					add(stageLight);

					var pathShit:String = 'stage/stagecurtains';

					if (Paths.fileExists('images/stagecurtains.png', IMAGE)) {
						pathShit = 'stagecurtains';
					}

					var stageCurtains:BGSprite = new BGSprite(pathShit, -500, -300, 1.3, 1.3);
					stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
					stageCurtains.updateHitbox();
					add(stageCurtains);
				}

				loadCharGroups();

				dadbattleSmokes = new FlxSpriteGroup();
				add(dadbattleSmokes);
			}
			case 'spooky': // Week 2
			{
				if (OptionData.lowQuality == false) {
					halloweenBG = new BGSprite('halloween_bg', -200, -100, ['halloweem bg0', 'halloweem bg lightning strike']);
				}
				else {
					halloweenBG = new BGSprite('halloween_bg_low', -200, -100);
				}

				add(halloweenBG);

				loadCharGroups();

				halloweenWhite = new BGSprite(null, -800, -400, 0, 0);
				halloweenWhite.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
				halloweenWhite.alpha = 0;
				halloweenWhite.blend = ADD;
				add(halloweenWhite);

				precacheList.set('thunder_1', 'sound');
				precacheList.set('thunder_2', 'sound');
			}
			case 'philly': // Week 3
			{
				var bg:BGSprite = new BGSprite('philly/sky', -100, 0, 0.1, 0.1);
				add(bg);

				var city:BGSprite = new BGSprite('philly/city', -10, 0, 0.3, 0.3);
				city.setGraphicSize(Std.int(city.width * 0.85));
				city.updateHitbox();
				add(city);

				phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
				phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
				phillyWindow.updateHitbox();
				phillyWindow.alpha = 0;
				add(phillyWindow);

				var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
				add(streetBehind);

				phillyTrain = new BGSprite('philly/train', 2000, 360);
				add(phillyTrain);

				precacheList.set('train_passes', 'sound');

				trainSound = new FlxSound();
				trainSound.loadEmbedded(Paths.getSound('train_passes'));
				FlxG.sound.list.add(trainSound);

				phillyStreet = new BGSprite('philly/street', -40, 50);
				add(phillyStreet);

				loadCharGroups();
			}
			case 'limo':
			{
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if (OptionData.lowQuality == false)
				{
					limoMetalPole = new BGSprite('gore/metalPole', -500, 220, 0.4, 0.4);
					add(limoMetalPole);

					bgLimo = new BGSprite('limo/bgLimo', -150, 480, 0.4, 0.4, ['background limo pink'], true);
					add(bgLimo);

					limoCorpse = new BGSprite('gore/noooooo', -500, limoMetalPole.y - 130, 0.4, 0.4, ['Henchmen on rail'], true);
					add(limoCorpse);

					limoCorpseTwo = new BGSprite('gore/noooooo', -500, limoMetalPole.y, 0.4, 0.4, ['henchmen death'], true);
					add(limoCorpseTwo);

					grpLimoDancers = new FlxTypedGroup<BackgroundDancer>();
					add(grpLimoDancers);

					for (i in 0...5)
					{
						var dancer:BackgroundDancer = new BackgroundDancer((370 * i) + 170, bgLimo.y - 400);
						dancer.scrollFactor.set(0.4, 0.4);
						grpLimoDancers.add(dancer);
					}

					limoLight = new BGSprite('gore/coldHeartKiller', limoMetalPole.x - 180, limoMetalPole.y - 80, 0.4, 0.4);
					add(limoLight);

					grpLimoParticles = new FlxTypedGroup<BGSprite>();
					add(grpLimoParticles);

					var particle:BGSprite = new BGSprite('gore/stupidBlood', -400, -400, 0.4, 0.4, ['blood'], false);
					particle.alpha = 0.01;
					grpLimoParticles.add(particle);

					resetLimoKill();

					precacheList.set('carPass0', 'sound');
					precacheList.set('carPass1', 'sound');

					precacheList.set('dancerdeath', 'sound');

					deathSound = new FlxSound();
					deathSound.loadEmbedded(Paths.getSound('dancerdeath'), false);
					deathSound.volume = 0.5;
					FlxG.sound.list.add(deathSound);
				}

				limoKillingState = 0;

				fastCar = new BGSprite('limo/fastCarLol', -300, 160);
				fastCar.active = true;
				add(fastCar);

				resetFastCar();
				loadCharGroups();

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);
				addBehindDad(limo);
			}
			case 'mall':
			{
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if (OptionData.lowQuality == false)
				{
					upperBoppers = new BGSprite('christmas/upperBop', -240, -90, 0.33, 0.33, ['Upper Crowd Bob']);
					upperBoppers.setGraphicSize(Std.int(upperBoppers.width * 0.85));
					upperBoppers.updateHitbox();
					add(upperBoppers);

					var bgEscalator:BGSprite = new BGSprite('christmas/bgEscalator', -1100, -600, 0.3, 0.3);
					bgEscalator.setGraphicSize(Std.int(bgEscalator.width * 0.9));
					bgEscalator.updateHitbox();
					add(bgEscalator);
				}

				var tree:BGSprite = new BGSprite('christmas/christmasTree', 370, -250, 0.40, 0.40);
				add(tree);

				if (OptionData.lowQuality == false)
				{
					bottomBoppers = new BGSprite('christmas/bottomBop', -300, 140, 0.9, 0.9, ['Bottom Level Boppers Idle']);
					bottomBoppers.animation.addByPrefix('hey', 'Bottom Level Boppers HEY', 24, false);
					bottomBoppers.setGraphicSize(Std.int(bottomBoppers.width * 1));
					bottomBoppers.updateHitbox();
					add(bottomBoppers);	
				}

				var fgSnow:BGSprite = new BGSprite('christmas/fgSnow', -600, 700);
				add(fgSnow);

				santa = new BGSprite('christmas/santa', -840, 150, 1, 1, ['santa idle in fear']);
				add(santa);

				loadCharGroups();

				precacheList.set('Lights_Shut_off', 'sound');
			}
			case 'mallEvil':
			{
				precacheList.set('Lights_Turn_On', 'sound');

				var bg:BGSprite = new BGSprite('christmas/evilBG', -400, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				var evilTree:BGSprite = new BGSprite('christmas/evilTree', 300, -300, 0.2, 0.2);
				add(evilTree);

				var evilSnow:BGSprite = new BGSprite('christmas/evilSnow', -200, 700);
				add(evilSnow);

				loadCharGroups();
			}
			case 'school':
			{
				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				bgSky.antialiasing = false;
				add(bgSky);

				var repositionShit = -200;
				var widShit = Std.int(bgSky.width * 6);

				bgSky.setGraphicSize(widShit);
				bgSky.updateHitbox();

				var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
				bgSchool.antialiasing = false;
				bgSchool.setGraphicSize(widShit);
				bgSchool.updateHitbox();
				add(bgSchool);

				var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
				bgStreet.antialiasing = false;
				bgStreet.setGraphicSize(widShit);
				bgStreet.updateHitbox();
				add(bgStreet);

				if (OptionData.lowQuality == false)
				{
					var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
					fgTrees.setGraphicSize(Std.int(widShit * 0.8));
					fgTrees.updateHitbox();
					fgTrees.antialiasing = false;
					add(fgTrees);
				}

				var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
				bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
				bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
				bgTrees.animation.play('treeLoop');
				bgTrees.scrollFactor.set(0.85, 0.85);
				bgTrees.antialiasing = false;
				bgTrees.setGraphicSize(Std.int(widShit * 1.4));
				bgTrees.updateHitbox();
				add(bgTrees);

				if (OptionData.lowQuality == false)
				{
					var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
					treeLeaves.setGraphicSize(widShit);
					treeLeaves.updateHitbox();
					treeLeaves.antialiasing = false;
					add(treeLeaves);

					bgGirls = new BackgroundGirls(-100, 190);
					bgGirls.scrollFactor.set(0.9, 0.9);
					bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
					bgGirls.updateHitbox();
					add(bgGirls);
				}

				bgSchool.setGraphicSize(widShit);

				loadCharGroups();
			}
			case 'schoolEvil':
			{
				if (OptionData.lowQuality == false)
				{
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', 400, 200, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					add(bgGhouls);
				}
				else
				{
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', 400, 200, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}

				loadCharGroups();
			}
			case 'tank':
			{
				var sky:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
				add(sky);

				if (OptionData.lowQuality == false)
				{
					var clouds:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					clouds.active = true;
					clouds.velocity.x = FlxG.random.float(5, 15);
					add(clouds);

					var mountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
					mountains.setGraphicSize(Std.int(1.2 * mountains.width));
					mountains.updateHitbox();
					add(mountains);

					var buildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.3, 0.3);
					buildings.setGraphicSize(Std.int(1.1 * buildings.width));
					buildings.updateHitbox();
					add(buildings);
				}

				var ruins:BGSprite = new BGSprite('tankRuins',-200,0,.35,.35);
				ruins.setGraphicSize(Std.int(1.1 * ruins.width));
				ruins.updateHitbox();
				add(ruins);

				if (OptionData.lowQuality == false)
				{
					var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);

					var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);

					tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
				}

				tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5,['BG tank w lighting'], true);
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var ground:BGSprite = new BGSprite('tankGround', -420, -150);
				ground.setGraphicSize(Std.int(1.15 * ground.width));
				ground.updateHitbox();
				add(ground);

				moveTank();
				loadCharGroups();

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				add(foregroundSprites);

				foregroundSprites.add(new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']));
				if (OptionData.lowQuality == false) foregroundSprites.add(new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']));
				foregroundSprites.add(new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']));
				if (OptionData.lowQuality == false) foregroundSprites.add(new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']));
				foregroundSprites.add(new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']));
				if (OptionData.lowQuality == false) foregroundSprites.add(new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']));
			}
			default:
			{
				loadCharGroups();
			}
		}

		callOnLuas('onLoadStagePost', []);
	}

	public var songLength:Float = 0;

	#if DISCORD_ALLOWED
	var storyDifficultyIDDiscord:String = "";
	var iconRPC:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	public var vocals:FlxSound;

	public var inCutscene:Bool = false;
	public var startingSong:Bool = false;
	public var updateTime:Bool = false;

	public var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	public var iconsZooming:Bool = false;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	public var cameraSpeed:Float = 1;

	public var camHUDZooming:Bool = false;
	public var camHUDZoomingMult:Float = 1;
	public var camHUDZoomingDecay:Float = 1;

	public var camHUD:FlxCamera;
	public var camGame:FlxCamera;
	public var camOther:FlxCamera;

	public var camFollowPos:FlxObject;
	public var camFollow:FlxPoint;

	private static var prevCamFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;

	public var notes:FlxTypedGroup<Note>;

	public var unspawnNotes:Array<Note> = [];

	public var eventNotes:Array<Dynamic> = [];
	public var saveNotes:Array<Float> = [];

	public var combo:Int = 0;

	public static var deathCounter:Int = 0;
	public var songAccuracy:Float = 0;
	public var totalNotesHit:Float = 0;
	public var totalPlayed:Int = 0;
	public var ratingString:String = 'N/A';
	public var comboRank:String = '';
	public var health(default, set):Float = 1;

	private function set_health(value:Float):Float
	{
		health = value;
		updateScore();

		return value;
	}

	public var songMisses:Int = 0;
	public var songScore:Int = 0;
	public var songHits:Int = 0;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var campaignAccuracy:Float = 0;

	public var ratingsData:Array<RatingData> = [];

	public function getRatingByName(name:String):RatingData
	{
		if (ratingsData.length > 0)
		{
			for (rtg in ratingsData)
			{
				if (rtg != null && rtg.name == name) {
					return rtg;
				}
			}
		}

		return new RatingData('sick');
	}

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	public static var ratingStuff:Array<Dynamic> =
	[
		['F-', 0],
		['F', 5],
		['E', 10],
		['D', 20],
		['C-', 25],
		['C', 30],
		['B-', 35],
		['B', 40],
		['B+', 43],
		['A-', 45],
		['A', 50],
		['A+', 60],
		['A++', 70],
		['S-', 75],
		['S', 80],
		['S+', 90],
		['S++', 100]
	];

	public var isCameraOnForcedPos:Bool = false;

	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	public var keysArray:Array<Dynamic>;
	public var controlArray:Array<String>;

	public var songPositionBar:Float = 0;

	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var randomNotes:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled(default, set):Bool = false;
	public var practiceMode:Bool = false;
	public var playbackRate(default, set):Float = 1;

	private function set_cpuControlled(value:Bool):Bool
	{
		cpuControlled = value;

		if (botplayTxt != null) {
			botplayTxt.visible = cpuControlled;
		}

		return cpuControlled;
	}

	private function set_playbackRate(value:Float):Float
	{
		playbackRate = value;

		if (generatedMusic)
		{
			if (vocals != null) vocals.pitch = playbackRate;
			FlxG.sound.music.pitch = playbackRate;
		}

		FlxAnimationController.globalSpeed = playbackRate;

		Conductor.safeZoneOffset = (OptionData.safeFrames / 60) * 1000 * playbackRate;
		setOnLuas('playbackRate', playbackRate);

		return playbackRate;
	}

	var achievementsArray:Array<FunkinLua> = [];
	var achievementWeeks:Array<String> = [];
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	public override function create():Void
	{
		Paths.clearStoredMemory();

		instance = this; // for lua and stuff

		if (FlxG.sound.music != null) {
			FlxG.sound.music.stop();
		}

		keysArray = [
			OptionData.copyKey(OptionData.keyBinds.get('note_left')),
			OptionData.copyKey(OptionData.keyBinds.get('note_down')),
			OptionData.copyKey(OptionData.keyBinds.get('note_up')),
			OptionData.copyKey(OptionData.keyBinds.get('note_right'))
		];

		controlArray = [
			'NOTE_LEFT',
			'NOTE_DOWN',
			'NOTE_UP',
			'NOTE_RIGHT'
		];

		for (i in 0...keysArray.length) {
			keysPressed.push(false);
		}

		debugKeysChart = OptionData.copyKey(OptionData.keyBinds.get('debug_1'));
		debugKeysCharacter = OptionData.copyKey(OptionData.keyBinds.get('debug_2'));

		healthGain = PlayStateChangeables.healthGain;
		healthLoss = PlayStateChangeables.healthLoss;

		instakillOnMiss = PlayStateChangeables.instaKill;
		randomNotes = PlayStateChangeables.randomNotes;
		cpuControlled = PlayStateChangeables.botPlay;
		practiceMode = PlayStateChangeables.practiceMode;
		playbackRate = PlayStateChangeables.playbackRate;

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		Transition.nextCamera = camOther;

		super.create();

		persistentUpdate = true;
		persistentDraw = true;

		ratingsData.push(new RatingData('sick')); // default rating

		var rating:RatingData = new RatingData('good');
		rating.ratingMod = 0.7;
		rating.score = 200;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:RatingData = new RatingData('bad');
		rating.ratingMod = 0.4;
		rating.score = 100;
		rating.noteSplash = false;
		ratingsData.push(rating);

		var rating:RatingData = new RatingData('shit');
		rating.ratingMod = 0;
		rating.score = 50;
		rating.noteSplash = false;
		ratingsData.push(rating);

		if (SONG == null) {
			SONG = Song.loadFromJson('tutorial', 'tutorial');
		}

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		GameOverSubState.resetVariables();

		try
		{
			var ourPath:String = Paths.getTxt(SONG.songID + '/' + SONG.songID + 'Dialogue');

			switch (SONG.songID)
			{
				case 'senpai' | 'roses' | 'thorns':
				{
					if (Paths.fileExists(ourPath, TEXT)) {
						dialogue = CoolUtil.coolTextFile(ourPath);
					}
					else {
						Debug.logError('Dialogue file no exists!');
					}
				}
			}

		}
		catch (e:Dynamic) {
			Debug.logError('Dialogue file cannot loaded! ' + e);
		}

		Conductor.songPosition = -5000 / Conductor.songPosition;

		if (SONG.stage == null || SONG.stage.length < 1)
		{
			switch (SONG.songID)
			{
				case 'spookeez' | 'south' | 'monster':
					SONG.stage = 'spooky';
				case 'pico' | 'blammed' | 'philly' | 'philly-nice':
					SONG.stage = 'philly';
				case 'milf' | 'satin-panties' | 'high':
					SONG.stage = 'limo';
				case 'cocoa' | 'eggnog':
					SONG.stage = 'mall';
				case 'winter-horrorland':
					SONG.stage = 'mallEvil';
				case 'senpai' | 'roses':
					SONG.stage = 'school';
				case 'thorns':
					SONG.stage = 'schoolEvil';
				case 'ugh' | 'guns' | 'stress':
					SONG.stage = 'tank';
				default:
					SONG.stage = 'stage';
			}
		}

		curStage = SONG.stage;

		try {
			loadStage(SONG.stage);
		}
		catch (e:Dynamic)
		{
			Debug.logError('Stage cannot loaded: ' + e);
			loadCharGroups();
		}

		generateSong(SONG);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);

		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('scripts/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('scripts/'));

		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) {
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/scripts/'));
		}

		for (mod in Paths.getGlobalMods()) {
			foldersToCheck.insert(0, Paths.mods(mod + '/scripts/'));
		}
		#end

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}

		startLuasOnFolder('weeks/' + storyWeekText + '.lua');
		#end

		#if (MODS_ALLOWED && LUA_ALLOWED)
		startLuasOnFolder('stages/' + curStage + '.lua');
		#end

		#if (MODS_ALLOWED && LUA_ALLOWED && ACHIEVEMENTS_ALLOWED)
		function addAbilityToUnlockAchievements(funkinLua:FunkinLua):Void
		{
			var lua:State = funkinLua.lua;

			if (lua != null)
			{
				Lua_helper.add_callback(lua, "giveAchievement", function(name:String):String
				{
					if (luaArray.contains(funkinLua)) {
						throw 'Illegal attempt to unlock ' + name;
					}

					if (Achievements.isAchievementUnlocked(name)) return "Achievement " + name + " is already unlocked!";
					if (!Achievements.exists(name)) return "Achievement " + name + " does not exist."; 

					if (instance != null)
					{
						Achievements.unlockAchievement(name);
						instance.startAchievement(name);

						OptionData.savePrefs();
						return "Unlocked achievement " + name + "!";
					}

					return "Instance is null.";
				});
			}
		}

		var luaFiles:Array<String> = Achievements.getModAchievements().copy();

		if (luaFiles.length > 0)
		{
			for (luaFile in luaFiles)
			{
				var meta:AchievementMeta = try Json.parse(File.getContent(luaFile.substring(0, luaFile.length - 4) + '.json')) catch (e:Dynamic) throw e;

				if (meta != null)
				{
					if (meta.song != null && meta.song.length > 0 && SONG.songID != Paths.formatToSongPath(meta.song)) continue;

					var lua:FunkinLua = new FunkinLua(luaFile);
					addAbilityToUnlockAchievements(lua);
					achievementsArray.push(lua);
				}
			}
		}

		var achievementMetas:Array<AchievementMeta> = Achievements.getModAchievementMetas().copy();

		for (i in achievementMetas)
		{
			if (i.song != null && i.song.length > 0 && SONG.songID != Paths.formatToSongPath(i.song)) continue;

			if (i.lua_code != null)
			{
				var lua:FunkinLua = new FunkinLua(null, i.lua_code);
				addAbilityToUnlockAchievements(lua);
				achievementsArray.push(lua);
			}

			if (i.week_nomiss != null) {
				achievementWeeks.push(i.week_nomiss + '_nomiss');
			}
		}
		#end

		var gfVersion:String = SONG.gfVersion;
	
		if (gfVersion == null || gfVersion.length < 1)
		{
			switch (SONG.stage)
			{
				case 'limo':
					gfVersion = 'gf-car';
				case 'mall' | 'mallEvil':
					gfVersion = 'gf-christmas';
				case 'school' | 'schoolEvil':
					gfVersion = 'gf-pixel';
				case 'tank':
					gfVersion = 'gf-tankmen';
				default:
					gfVersion = 'gf';
			}

			switch (SONG.songID)
			{
				case 'stress':
					gfVersion = 'pico-speaker';
			}

			SONG.gfVersion = gfVersion; // Fix for the Chart Editor
		}

		loadGF(gfVersion);
		loadDad(SONG.player2);
		loadBF(SONG.player1);

		if (!OptionData.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		loadHUD();

		startingSong = true;
		updateTime = true;

		#if LUA_ALLOWED
		for (notetype in noteTypeMap.keys()) {
			startLuasOnFolder('custom_notetypes/' + notetype + '.lua');
		}

		for (event in eventPushedMap.keys()) {
			startLuasOnFolder('custom_events/' + event + '.lua');
		}
		#end

		noteTypeMap.clear();
		noteTypeMap = null;

		eventPushedMap.clear();
		eventPushedMap = null;

		if (eventNotes.length > 1)
		{
			for (event in eventNotes) event.strumTime -= eventNoteEarlyTrigger(event);
			eventNotes.sort(sortByTime);
		}

		#if LUA_ALLOWED
		var filesPushed:Array<String> = [];
		var foldersToCheck:Array<String> = [Paths.getPreloadPath('data/' + SONG.songID + '/')];

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('data/' + SONG.songID + '/'));

		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) {
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/data/' + SONG.songID + '/'));
		}

		for (mod in Paths.getGlobalMods()) {
			foldersToCheck.insert(0, Paths.mods(mod + '/data/' + SONG.songID + '/' ));// using push instead of insert because these should run after everything else
		}
		#end

		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				for (file in FileSystem.readDirectory(folder))
				{
					if (file.endsWith('.lua') && !filesPushed.contains(file))
					{
						luaArray.push(new FunkinLua(folder + file));
						filesPushed.push(file);
					}
				}
			}
		}
		#end

		#if DISCORD_ALLOWED
		storyDifficultyIDDiscord = CoolUtil.getDifficultyName(lastDifficulty, difficulties) + (lastDifficulty != storyDifficultyID ? ' (' + CoolUtil.getDifficultyName(storyDifficultyID, difficulties) + ')' : '');
		iconRPC = dad.char_name;

		switch (gameMode) // String that contains the mode defined here so it isn't necessary to call changePresence for each mode
		{
			case 'story':
				detailsText = 'Story Mode: ' + storyWeekName;
			case 'freeplay':
				detailsText = 'Freeplay';
			case 'replay':
				detailsText = 'Replay';
		}

		detailsPausedText = "Paused - " + detailsText; // String for when the game is paused

		DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyIDDiscord, iconRPC); // Updating Discord Rich Presence.
		#end

		if (SONG.songID != firstSong && gameMode == 'story' && !seenCutscene)
		{
			skipArrowStartTween = true;

			if (prevCamFollow != null && prevCamFollowPos != null) {
				blockedCameraMovementOnStart = false;
			}
		}

		allowPlayCutscene = ((gameMode == 'story' && OptionData.cutscenesInType.contains('Story'))
			|| (gameMode == 'freeplay' && OptionData.cutscenesInType.contains('Freeplay'))
			|| (gameMode == 'replay' && OptionData.cutscenesInType.contains('Replay'))
			|| OptionData.cutscenesInType == 'Everywhere') && !seenCutscene;

		if (allowPlayCutscene) {
			triggerCutscenes();
		}
		else {
			stopAndStart();
		}

		if (!blockedCameraMovementOnStart) {
			cameraMovementSection();
		}

		if (gameMode != 'replay') {
			rep = new Replay("na");
		}

		cacheCountdown();
		cachePopUpScore();

		callOnLuas('onCreatePost', []);

		if (OptionData.hitsoundVolume > 0)
		{
			switch (OptionData.hitsoundType)
			{
				case 'Kade':
					precacheList.set('SNAP', 'sound');
				case 'Psych':
					precacheList.set('hitsound', 'sound');
			}
		}

		precacheList.set('missnote1', 'sound');
		precacheList.set('missnote2', 'sound');
		precacheList.set('missnote3', 'sound');

		precacheList.set(GameOverSubState.deathSoundName, 'sound');
		precacheList.set(GameOverSubState.loopSoundName, 'music');
		precacheList.set(GameOverSubState.endSoundName, 'music');

		if (OptionData.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(OptionData.pauseMusic), 'music');
		}

		precacheList.set('alphabet', 'image');

		for (key => type in precacheList)
		{
			switch (type)
			{
				case 'image':
					Paths.getImage(key);
				case 'sound':
					Paths.getSound(key);
				case 'music':
					Paths.getMusic(key);
			}
		}

		Paths.clearUnusedMemory();

		Transition.nextCamera = camOther;
		if (eventNotes.length < 1) checkEventNote();
	}

	private function stopAndStart():Void
	{
		var ret:Dynamic = callOnLuas('onStart', [allowPlayCutscene]);

		if (ret != FunkinLua.Function_Stop) {
			startCountdown();
		}
	}

	public function triggerCutscenes():Void
	{
		if (OptionData.cutscenesInType != 'Nowhere')
		{
			var doof:DialogueBox = new DialogueBox(false, dialogue);
			doof.scrollFactor.set();
			doof.finishThing = stopAndStart;
			doof.cameras = [camHUD];

			switch (SONG.songID)
			{
				case 'tutorial':
				{
					camHUD.visible = false;
					FlxG.camera.zoom = 2.1;

					moveCameraToGF(false);

					var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);

					if (gf != null)
					{
						camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
						camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
					}

					camFollow.set(camPos.x, camPos.y);

					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5,
					{
						ease: FlxEase.quadInOut,
						onComplete: function(twn:FlxTween):Void
						{
							camHUD.visible = true;
							startCountdown();
						}
					});
				}
				case 'monster':
				{
					blockedCameraMovementOnStart = true;

					var whiteScreen:FlxSprite = new FlxSprite(0, 0);
					whiteScreen.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.WHITE);
					whiteScreen.scrollFactor.set();
					whiteScreen.blend = ADD;
					add(whiteScreen);

					camHUD.visible = false;

					snapCamFollowToPos(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
					inCutscene = true;

					FlxTween.tween(whiteScreen, {alpha: 0}, 1,
					{
						startDelay: 0.1,
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween):Void
						{
							camHUD.visible = true;
							remove(whiteScreen);

							moveCameraToGF(true);
							startCountdown();
						}
					});

					FlxG.sound.play(Paths.getSoundRandom('thunder_', 1, 2));

					if (gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);
				}
				case 'winter-horrorland':
				{
					blockedCameraMovementOnStart = true;

					camHUD.visible = false;
					inCutscene = true;

					snapCamFollowToPos(400, -2050);

					var blackScreen:FlxSprite = new FlxSprite();
					blackScreen.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
					blackScreen.scrollFactor.set();
					add(blackScreen);

					FlxTween.tween(blackScreen, {alpha: 0}, 0.7,
					{
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween):Void {
							remove(blackScreen);
						}
					});

					FlxG.sound.play(Paths.getSound('Lights_Turn_On'));

					FlxG.camera.focusOn(camFollow);
					FlxG.camera.zoom = 1.5;

					new FlxTimer().start(0.8, function(tmr:FlxTimer):Void
					{
						camHUD.visible = true;

						FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 2.5,
						{
							ease: FlxEase.quadInOut,
							onComplete: function(twn:FlxTween):Void
							{
								moveCameraToGF(true);
								startCountdown();
							}
						});
					});
				}
				case 'senpai' | 'roses' | 'thorns':
				{
					if (SONG.songID == 'roses')
					{
						FlxG.sound.play(Paths.getSound('ANGRY'), 1, false, null, true, function():Void {
							schoolIntro(doof);
						});
					}
					else {
						schoolIntro(doof);
					}
				}
				case 'ugh' | 'guns' | 'stress':
				{
					tankIntro();
				}
				default:
				{
					stopAndStart();
				}
			}

			seenCutscene = OptionData.skipCutscenes;
		}
	}

	public function moveCameraToGF(?justMove:Null<Bool> = false):Void
	{
		var camPos:FlxPoint = new FlxPoint(girlfriendCameraOffset[0], girlfriendCameraOffset[1]);

		if (gf != null)
		{
			camPos.x += gf.getGraphicMidpoint().x + gf.cameraPosition[0];
			camPos.y += gf.getGraphicMidpoint().y + gf.cameraPosition[1];
		}

		if (camFollow != null && camFollowPos != null)
		{
			if (justMove) {
				camFollow.set(camPos.x, camPos.y);
			}
			else {
				snapCamFollowToPos(camPos.x, camPos.y);
			}
		}
	}

	public function startVideo(name:String, type:String = 'mp4'):Void
	{
		inCutscene = true;
		skipArrowStartTween = false;

		switch (type)
		{
			case 'webm':
			{
				#if WEBM_ALLOWED
				var filepath:String = Paths.getWebm(name);
				var filepathFindLimeOpenFlShit:String = Paths.getWebm(name, null, true);
		
				#if sys
				if (!FileSystem.exists(filepath))
				#else
				if (!OpenFlAssets.exists(filepathFindLimeOpenFlShit))
				#end
				{
					Debug.logWarn('Couldnt find video file: ' + name);
					startAndEnd();

					return;
				}

				openSubState(new VideoSubState(name, startAndEnd));
				#else
				Debug.logWarn('Platform not supported!');
				startAndEnd();
				#end
			}
			default:
			{
				#if MP4_ALLOWED
				var filepath:String = Paths.getVideo(name);
				var filepathFindLimeOpenFlShit:String = Paths.getVideo(name, null, true);
		
				#if sys
				if (!FileSystem.exists(filepath))
				#else
				if (!OpenFlAssets.exists(filepathFindLimeOpenFlShit))
				#end
				{
					Debug.logWarn('Couldnt find video file: ' + name);
					startAndEnd();

					return;
				}
		
				var video:VideoHandler = new VideoHandler();
				video.playVideo(filepath);
				video.finishCallback = startAndEnd;
				#else
				Debug.logWarn('Platform not supported!');
				startAndEnd();
				#end
			}
		}
	}

	public function startAndEnd():Void
	{
		if (endingSong) {
			endSong();
		}
		else {
			startCountdown();
		}
	}

	public var strumLine:FlxSprite;

	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;

	public var scoreTxtTween:FlxTween;
	public var scoreTxt:FlxText;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;

	public var songPosBG:AttachedSprite;
	public var songPosBar:FlxBar;
	public var songPosName:FlxText;

	public var grpRatings:FlxTypedGroup<Rating>;
	public var grpNumbers:FlxTypedGroup<Number>;

	public static var lastRating:Rating;
	public static var lastCombo:FlxSprite;
	public static var lastScore:Array<Number> = [];

	public var ratingTweensArray:Array<FlxTween> = [];
	public var numbersTweensArray:Array<FlxTween> = [];

	public function loadHUD():Void
	{
		camFollow = new FlxPoint(0, 0);
		camFollowPos = new FlxObject(0, 0, 1, 1);

		moveCameraToGF(false);

		if (prevCamFollow != null)
		{
			camFollow = prevCamFollow;
			prevCamFollow = null;
		}

		if (prevCamFollowPos != null)
		{
			camFollowPos = prevCamFollowPos;
			prevCamFollowPos = null;
		}

		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);
		FlxG.fixedTimestep = false;

		callOnLuas('onLoadHUD', []);

		strumLine = new FlxSprite(OptionData.middleScroll == true ? STRUM_X_MIDDLESCROLL : STRUM_X, OptionData.downScroll ? FlxG.height - 150 : 50);
		strumLine.makeGraphic(FlxG.width, 10);
		strumLine.scrollFactor.set();
		strumLine.alpha = 0;
		strumLine.visible = false;
		strumLine.cameras = [camHUD];
		add(strumLine);

		grpRatings = new FlxTypedGroup<Rating>();
		grpRatings.cameras = [camHUD];
		add(grpRatings);

		grpNumbers = new FlxTypedGroup<Number>();
		grpNumbers.cameras = [camHUD];
		add(grpNumbers);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		playerStrums = new FlxTypedGroup<StrumNote>();

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		strumLineNotes.cameras = [camHUD];
		add(strumLineNotes);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteSplashes.cameras = [camHUD];
		add(grpNoteSplashes);

		var splash:NoteSplash = new NoteSplash(100, 100, 0);
		splash.alpha = 0.0;
		grpNoteSplashes.add(splash);

		if (Paths.fileExists('images/healthBar.png', IMAGE)) {
			healthBarBG = new AttachedSprite('healthBar');
		}
		else {
			healthBarBG = new AttachedSprite('ui/healthBar');
		}

		healthBarBG.y = OptionData.downScroll ? 0.11 * FlxG.height : FlxG.height * 0.89;
		healthBarBG.screenCenter(X);
		healthBarBG.scrollFactor.set();
		healthBarBG.xAdd = -4;
		healthBarBG.yAdd = -4;
		healthBarBG.cameras = [camHUD];
		add(healthBarBG);

		healthBar = new FlxBar(healthBarBG.x + 4, healthBarBG.y + 4, RIGHT_TO_LEFT, Std.int(healthBarBG.width - 8), Std.int(healthBarBG.height - 8), instance,
			'health', 0, 2);
		healthBar.scrollFactor.set();
		reloadHealthBarColors();
		healthBarBG.sprTracker = healthBar;
		healthBar.alpha = OptionData.healthBarAlpha;
		healthBar.cameras = [camHUD];
		add(healthBar);

		iconP1 = new HealthIcon(boyfriend.healthIcon, true);
		iconP1.y = healthBar.y - (iconP1.height / 2);
		iconP1.alpha = OptionData.healthBarAlpha;
		iconP1.cameras = [camHUD];
		add(iconP1);

		iconP2 = new HealthIcon(dad.healthIcon, false);
		iconP2.y = healthBar.y - (iconP2.height / 2);
		iconP2.alpha = OptionData.healthBarAlpha;
		iconP2.cameras = [camHUD];
		add(iconP2);

		scoreTxt = new FlxText(0, healthBarBG.y + 50, FlxG.width, "", 16);
		scoreTxt.setFormat(Paths.getFont("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		updateScore();
		scoreTxt.scrollFactor.set();
		scoreTxt.cameras = [camHUD];
		scoreTxt.visible = OptionData.scoreText;
		add(scoreTxt);

		notes = new FlxTypedGroup<Note>();
		notes.cameras = [camHUD];
		add(notes);

		var showTime:Bool = OptionData.songPositionType != 'Disabled';

		if (Paths.fileExists('images/healthBar.png', IMAGE)) {
			songPosBG = new AttachedSprite('healthBar');
		}
		else {
			songPosBG = new AttachedSprite('ui/healthBar');
		}
		songPosBG.y = 10;
		songPosBG.screenCenter(X);
		songPosBG.scrollFactor.set();
		songPosBG.xAdd = -4;
		songPosBG.yAdd = -4;
		if (OptionData.downScroll == true) songPosBG.y = FlxG.height - 30;
		songPosBG.visible = showTime;
		songPosBG.copyVisible = true;
		songPosBG.cameras = [camHUD];
		songPosBG.alpha = 0;
		add(songPosBG);

		songPosBar = new FlxBar(songPosBG.x + 4, songPosBG.y + 4, LEFT_TO_RIGHT, Std.int(songPosBG.width - 8), Std.int(songPosBG.height - 8), instance,
			'songPositionBar', 0, 1);
		songPosBar.scrollFactor.set();
		songPosBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		songPosBar.numDivisions = 800;
		songPosBar.cameras = [camHUD];
		songPosBar.visible = showTime;
		songPosBar.alpha = 0;
		add(songPosBar);

		songPosBG.sprTracker = songPosBar;

		songPosName = new FlxText(0, songPosBG.y + 1, FlxG.width, "", 20);
		songPosName.setFormat(Paths.getFont("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songPosName.scrollFactor.set();
		songPosName.borderSize = 1.25;
		songPosName.cameras = [camHUD];
		songPosName.visible = showTime;
		songPosName.text = SONG.songName + " - " + CoolUtil.getDifficultyName(lastDifficulty, difficulties);
		songPosName.alpha = 0;
		add(songPosName);

		botplayTxt = new FlxText(400, OptionData.downScroll == true ? songPosBG.y - 85 : songPosBG.y + 75, FlxG.width - 800, "BOTPLAY", 32);
		botplayTxt.setFormat(Paths.getFont("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		botplayTxt.alpha = 0;
		botplayTxt.cameras = [camHUD];
		add(botplayTxt);

		callOnLuas('onLoadHUDPost', []);
	}

	public function updateScore():Void
	{
		scoreTxt.text = Highscore.getScoreText(deathCounter, songAccuracy, ratingString, comboRank, health, songMisses, songScore);
	}

	public function snapCamFollowToPos(x:Float, y:Float):Void
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	var dialogueCount:Int = 0;

	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void // You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	{
		if (dialogueFile.dialogue.length > 0) // TO DO: Make this more flexible, maybe?
		{
			inCutscene = true;

			CoolUtil.precacheSound('dialogue');
			CoolUtil.precacheSound('dialogueClose');

			skipArrowStartTween = false;

			var doof:DialogueBoxPsych = new DialogueBoxPsych(dialogueFile, song);
			doof.scrollFactor.set();

			if (endingSong) {
				doof.finishThing = endSong;
			}
			else {
				doof.finishThing = startCountdown;
			}

			doof.nextDialogueThing = startNextDialogue;
			doof.skipDialogueThing = skipDialogue;
			doof.cameras = [camHUD];
			add(doof);

			return;
		}

		Debug.logWarn('Your dialogue file is badly formatted!');
		startAndEnd();
	}

	public function startNextDialogue():Void
	{
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	public function skipDialogue():Void
	{
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	public function schoolIntro(?dialogueBox:DialogueBox):Void
	{
		var black:FlxSprite = new FlxSprite(-100, -100);
		black.makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.BLACK);
		black.scrollFactor.set();
		add(black);

		var red:FlxSprite = new FlxSprite(-100, -100);
		red.makeGraphic(FlxG.width * 2, FlxG.height * 2, 0xFFff1b31);
		red.scrollFactor.set();

		var senpaiEvil:FlxSprite = new FlxSprite();
		senpaiEvil.frames = Paths.getSparrowAtlas('weeb/senpaiCrazy');
		senpaiEvil.animation.addByPrefix('idle', 'Senpai Pre Explosion', 24, false);
		senpaiEvil.setGraphicSize(Std.int(senpaiEvil.width * 6));
		senpaiEvil.scrollFactor.set();
		senpaiEvil.updateHitbox();
		senpaiEvil.screenCenter();
		senpaiEvil.x += senpaiEvil.width / 5;

		if (SONG.songID == 'roses' || SONG.songID == 'thorns')
		{
			remove(black);

			if (SONG.songID == 'thorns') {
				add(red);
			}
		}

		new FlxTimer().start(0.3, function(tmr:FlxTimer):Void
		{
			black.alpha -= 0.15;

			if (black.alpha > 0) {
				tmr.reset(0.3);
			}
			else
			{
				if (dialogueBox != null)
				{
					inCutscene = true;

					if (SONG.songID == 'thorns')
					{
						camHUD.visible = false;

						senpaiEvil.alpha = 0;
						add(senpaiEvil);

						new FlxTimer().start(0.3, function(swagTimer:FlxTimer):Void
						{
							senpaiEvil.alpha += 0.15;

							if (senpaiEvil.alpha < 1) {
								swagTimer.reset();
							}
							else
							{
								senpaiEvil.animation.play('idle');

								FlxG.sound.play(Paths.getSound('Senpai_Dies'), 1, false, null, true, function():Void
								{
									remove(senpaiEvil);
									remove(red);

									moveCameraToGF();

									FlxG.camera.fade(FlxColor.WHITE, 0.5, true, function():Void
									{
										camHUD.visible = true;
										add(dialogueBox);
									}, true);
								});

								new FlxTimer().start(3.2, function(deadTime:FlxTimer):Void {
									FlxG.camera.fade(FlxColor.WHITE, 1.6, false);
								});
							}
						});
					}
					else {
						add(dialogueBox);
					}
				}
				else {
					startCountdown();
				}

				remove(black);
			}
		});
	}

	var weekSevenTweenCameraZoomShit:FlxTween = null;

	public function tankIntro():Void
	{
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

		var songName:String = SONG.songID;
		dadGroup.alpha = 0.00001;
		camHUD.visible = false;

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = OptionData.globalAntialiasing;
		addBehindDad(tankman);

		cutsceneHandler.push(tankman);

		var tankman2:FlxSprite = new FlxSprite(16, 312);
		tankman2.antialiasing = OptionData.globalAntialiasing;
		tankman2.alpha = 0.000001;
		cutsceneHandler.push(tankman2);

		var gfDance:FlxSprite = new FlxSprite(gf.x - 107, gf.y + 140);
		gfDance.antialiasing = OptionData.globalAntialiasing;
		cutsceneHandler.push(gfDance);

		var gfCutscene:FlxSprite = new FlxSprite(gf.x - 104, gf.y + 122);
		gfCutscene.antialiasing = OptionData.globalAntialiasing;
		cutsceneHandler.push(gfCutscene);

		var picoCutscene:FlxSprite = new FlxSprite(gf.x - 849, gf.y - 264);
		picoCutscene.antialiasing = OptionData.globalAntialiasing;
		cutsceneHandler.push(picoCutscene);

		var boyfriendCutscene:FlxSprite = new FlxSprite(boyfriend.x + 5, boyfriend.y + 20);
		boyfriendCutscene.antialiasing = OptionData.globalAntialiasing;
		cutsceneHandler.push(boyfriendCutscene);

		cutsceneHandler.finishCallback = function():Void
		{
			var timeForStuff:Float = Conductor.crochet / 1000 * 4.5;
			FlxG.sound.music.fadeOut(timeForStuff);

			if (weekSevenTweenCameraZoomShit != null) {
				weekSevenTweenCameraZoomShit.cancel();
			}

			weekSevenTweenCameraZoomShit = FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			cameraMovement('dad');

			startCountdown();

			blockedCameraMovementOnStart = false;
			cameraMovementSection();

			dadGroup.alpha = 1;
			camHUD.visible = true;

			boyfriend.animation.finishCallback = null;

			gf.animation.finishCallback = null;
			gf.dance();
		};

		camFollow.set(dad.x + 280, dad.y + 170);

		switch (songName)
		{
			case 'ugh':
			{
				cutsceneHandler.endTime = 12;
				cutsceneHandler.music = 'DISTORTO';

				CoolUtil.precacheSound('wellWellWell');
				CoolUtil.precacheSound('killYou');
				CoolUtil.precacheSound('bfBeep');

				var wellWellWell:FlxSound = new FlxSound().loadEmbedded(Paths.getSound('wellWellWell'));
				FlxG.sound.list.add(wellWellWell);

				tankman.animation.addByPrefix('wellWell', 'TANK TALK 1 P1', 24, false);
				tankman.animation.addByPrefix('killYou', 'TANK TALK 1 P2', 24, false);
				tankman.animation.play('wellWell', true);
				FlxG.camera.zoom *= 1.2;

				cutsceneHandler.timer(0.1, function():Void
				{
					wellWellWell.play(true);
				});

				cutsceneHandler.timer(3, function():Void
				{
					camFollow.x += 750;
					camFollow.y += 100;
				});

				cutsceneHandler.timer(4.5, function():Void
				{
					boyfriend.playAnim('singUP', true);
					boyfriend.specialAnim = true;
					FlxG.sound.play(Paths.getSound('bfBeep'));
				});

				cutsceneHandler.timer(6, function():Void
				{
					camFollow.x -= 750;
					camFollow.y -= 100;

					tankman.animation.play('killYou', true);
					FlxG.sound.play(Paths.getSound('killYou'));
				});
			}
			case 'guns':
			{
				cutsceneHandler.endTime = 11.5;
				cutsceneHandler.music = 'DISTORTO';
	
				tankman.x += 40;
				tankman.y += 10;
		
				CoolUtil.precacheSound('tankSong2');

				var tightBars:FlxSound = new FlxSound();
				tightBars.loadEmbedded(Paths.getSound('tankSong2'));
				FlxG.sound.list.add(tightBars);

				tankman.animation.addByPrefix('tightBars', 'TANK TALK 2', 24, false);
				tankman.animation.play('tightBars', true);
				boyfriend.animation.curAnim.finish();

				cutsceneHandler.onStart = function():Void
				{
					tightBars.play(true);

					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 4, {ease: FlxEase.quadInOut});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2 * 1.2}, 0.5, {ease: FlxEase.quadInOut, startDelay: 4});
					FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom * 1.2}, 1, {ease: FlxEase.quadInOut, startDelay: 4.5});
				};

				cutsceneHandler.timer(4, function():Void
				{
					gf.playAnim('sad', true);

					gf.animation.finishCallback = function(name:String):Void {
						gf.playAnim('sad', true);
					};
				});
			}
			case 'stress':
			{
				cutsceneHandler.endTime = 35.5;

				tankman.x -= 54;
				tankman.y -= 14;

				gfGroup.alpha = 0.00001;
				boyfriendGroup.alpha = 0.00001;

				camFollow.set(dad.x + 400, dad.y + 170);

				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});
	
				foregroundSprites.forEach(function(spr:BGSprite):Void
				{
					spr.y += 100;
				});
	
				CoolUtil.precacheSound('stressCutscene');

				tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
				addBehindDad(tankman2);

				if (OptionData.lowQuality == false)
				{
					gfDance.frames = Paths.getSparrowAtlas('characters/gfTankmen');
					gfDance.animation.addByPrefix('dance', 'GF Dancing at Gunpoint', 24, true);
					gfDance.animation.play('dance', true);
					addBehindGF(gfDance);
				}

				gfCutscene.frames = Paths.getSparrowAtlas('cutscenes/stressGF');
				gfCutscene.animation.addByPrefix('dieBitch', 'GF STARTS TO TURN PART 1', 24, false);
				gfCutscene.animation.addByPrefix('getRektLmao', 'GF STARTS TO TURN PART 2', 24, false);
				gfCutscene.animation.play('dieBitch', true);
				gfCutscene.animation.pause();
				addBehindGF(gfCutscene);

				if (OptionData.lowQuality == false) {
					gfCutscene.alpha = 0.00001;
				}

				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				picoCutscene.alpha = 0.00001;
				addBehindGF(picoCutscene);

				boyfriendCutscene.frames = Paths.getSparrowAtlas('characters/BOYFRIEND');
				boyfriendCutscene.animation.addByPrefix('idle', 'BF idle dance', 24, false);
				boyfriendCutscene.animation.play('idle', true);
				boyfriendCutscene.animation.curAnim.finish();
				addBehindBF(boyfriendCutscene);

				var cutsceneSnd:FlxSound = new FlxSound();
				cutsceneSnd.loadEmbedded(Paths.getSound('stressCutscene'));
				FlxG.sound.list.add(cutsceneSnd);

				tankman.animation.addByPrefix('godEffingDamnIt', 'TANK TALK 3', 24, false);
				tankman.animation.play('godEffingDamnIt', true);

				var calledTimes:Int = 0;

				var zoomBack:Void->Void = function():Void
				{
					var camPosX:Float = 630;
					var camPosY:Float = 425;

					camFollow.set(camPosX, camPosY);
					camFollowPos.setPosition(camPosX, camPosY);

					FlxG.camera.zoom = 0.8;
					cameraSpeed = 1;

					calledTimes++;

					if (calledTimes > 1)
					{
						foregroundSprites.forEach(function(spr:BGSprite):Void {
							spr.y -= 100;
						});
					}
				}

				cutsceneHandler.onStart = function():Void {
					cutsceneSnd.play(true);
				};

				cutsceneHandler.timer(15.2, function():Void
				{
					FlxTween.tween(camFollow, {x: 650, y: 300}, 1, {ease: FlxEase.sineOut});
					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 2.25, {ease: FlxEase.quadInOut});

					gfDance.visible = false;
					gfCutscene.alpha = 1;
					gfCutscene.animation.play('dieBitch', true);
					gfCutscene.animation.finishCallback = function(name:String):Void
					{
						if (name == 'dieBitch') // Next part
						{
							gfCutscene.animation.play('getRektLmao', true);
							gfCutscene.offset.set(224, 445);
						}
						else
						{
							gfCutscene.visible = false;
							picoCutscene.alpha = 1;
							picoCutscene.animation.play('anim', true);

							boyfriendGroup.alpha = 1;
							boyfriendCutscene.visible = false;
							boyfriend.playAnim('bfCatch', true);
							boyfriend.animation.finishCallback = function(name:String):Void
							{
								if (name != 'idle')
								{
									boyfriend.playAnim('idle', true);
									boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
								}
							};

							picoCutscene.animation.finishCallback = function(name:String):Void
							{
								picoCutscene.visible = false;
								gfGroup.alpha = 1;
								picoCutscene.animation.finishCallback = null;
							};

							gfCutscene.animation.finishCallback = null;
						}
					};
				});

				cutsceneHandler.timer(17.5, function():Void
				{
					zoomBack();
				});

				cutsceneHandler.timer(19.5, function():Void
				{
					tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman2.animation.play('lookWhoItIs', true);
					tankman2.alpha = 1;
					tankman.visible = false;
				});

				cutsceneHandler.timer(20, function():Void
				{
					camFollow.set(dad.x + 500, dad.y + 170);
				});

				cutsceneHandler.timer(31.2, function():Void
				{
					boyfriend.playAnim('singUPmiss', true);
					boyfriend.animation.finishCallback = function(name:String):Void
					{
						if (name == 'singUPmiss')
						{
							boyfriend.playAnim('idle', true);
							boyfriend.animation.curAnim.finish(); //Instantly goes to last frame
						}
					};

					camFollow.set(boyfriend.x + 280, boyfriend.y + 200);
					cameraSpeed = 12;

					FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2 * 1.2}, 0.25, {ease: FlxEase.elasticOut});
				});

				cutsceneHandler.timer(32.2, function():Void {
					zoomBack();
				});
			}
		}
	}

	public var introImagesSuffix:String = '';
	public var introSoundsSuffix:String = '';

	function cacheCountdown():Void
	{
		if (isPixelStage)
		{
			introImagesSuffix = '-pixel';
			introSoundsSuffix = '-pixel';
		}

		for (asset in ['three', 'ready', 'set', 'go'])
		{
			var doubleAsset:String = asset + introImagesSuffix;

			if (Paths.fileExists('images/' + doubleAsset + '.png', IMAGE)) {
				Paths.getImage(doubleAsset);
			}
			else if (Paths.fileExists('images/pixelUI/' + doubleAsset + '.png', IMAGE)) {
				Paths.getImage('pixelUI/' + doubleAsset);
			}
			else if (Paths.fileExists('images/countdown/' + doubleAsset + '.png', IMAGE)) {
				Paths.getImage('countdown/' + doubleAsset);
			}
		}
		
		Paths.getSound('intro3' + introSoundsSuffix);
		Paths.getSound('intro2' + introSoundsSuffix);
		Paths.getSound('intro1' + introSoundsSuffix);

		Paths.getSound('introGo' + introSoundsSuffix);
	}

	public var skipCountdown:Bool = false;

	public var startTimer:FlxTimer = new FlxTimer();
	public var startedCountdown:Bool = false;

	public static var startOnTime:Float = 0;

	public var countdownTweens:Array<FlxTween> = [];
	public var countdownSounds:Array<FlxSound> = [];

	public var countdownThree:FlxSprite;
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public function startCountdown():Void
	{
		if (startedCountdown)
		{
			callOnLuas('onStartCountdown', []);
			return;
		}

		inCutscene = false;

		var ret:Dynamic = callOnLuas('onStartCountdown', []);

		if (ret != FunkinLua.Function_Stop)
		{
			if (skipCountdown || startOnTime > 0) skipArrowStartTween = true;

			generateStaticArrows(0);
			generateStaticArrows(1);

			for (i in 0...playerStrums.length)
			{
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}

			for (i in 0...opponentStrums.length)
			{
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;

			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

			var swagCounter:Int = 0;

			if (startOnTime < 0) startOnTime = 0;

			if (startOnTime > 0)
			{
				clearNotesBefore(startOnTime);
				setSongTime(startOnTime - 350);

				return;
			}
			else if (skipCountdown)
			{
				setSongTime(0);
				return;
			}

			startTimer.start(Conductor.crochet / 1000 / playbackRate, function(tmr:FlxTimer):Void
			{
				var curLoop:Int = tmr.loopsLeft;

				if (gf != null && curLoop % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				{
					gf.dance();
				}

				if (curLoop % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
				{
					boyfriend.dance();
				}

				if (curLoop % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
				{
					dad.dance();
				}

				var antialias:Bool = isPixelStage ? false : OptionData.globalAntialiasing;

				switch (SONG.stage)
				{
					case 'philly':
					{
						if (curLoop % 4 == 0)
						{
							curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
		
							if (phillyWindow != null)
							{
								phillyWindow.color = phillyLightsColors[curLight];
								phillyWindow.alpha = 1;
							}
						}
					}
					case 'limo':
					{
						if (grpLimoDancers != null)
						{
							grpLimoDancers.forEach(function(dancer:BackgroundDancer):Void {
								dancer.dance();
							});
						}
					}
					case 'mall':
					{
						if (OptionData.lowQuality == false) {
							upperBoppers.dance(true);
						}
	
						bottomBoppers.dance(true);
						santa.dance(true);
					}
					case 'school':
					{
						if (bgGirls != null) {
							bgGirls.dance();
						}
					}
					case 'tank':
					{
						if (OptionData.lowQuality == false) tankWatchtower.dance();
		
						foregroundSprites.forEach(function(spr:BGSprite):Void {
							spr.dance();
						});
					}
				}

				switch (swagCounter)
				{
					case 0:
					{
						countdownThree = new FlxSprite();

						var name:String = 'three' + introImagesSuffix;

						if (Paths.fileExists('images/' + name + '.png', IMAGE)) {
							countdownThree.loadGraphic(Paths.getImage(name));
						}
						else if (Paths.fileExists('images/pixelUI/' + name + '.png', IMAGE)) {
							countdownThree.loadGraphic(Paths.getImage('pixelUI/' + name));
						}
						else if (Paths.fileExists('images/countdown/' + name + '.png', IMAGE)) {
							countdownThree.loadGraphic(Paths.getImage('countdown/' + name));
						}

						countdownThree.setGraphicSize(Std.int(countdownThree.width * 0.75));
						countdownThree.scrollFactor.set();

						if (isPixelStage) {
							countdownThree.setGraphicSize(Std.int(countdownThree.width * daPixelZoom));
						}

						countdownThree.updateHitbox();
						countdownThree.screenCenter();
						countdownThree.alpha = 0;
						countdownThree.visible = false;
						countdownThree.antialiasing = antialias;
						countdownThree.cameras = [camHUD];
						insert(members.indexOf(notes), countdownThree);

						var tween:FlxTween = FlxTween.tween(countdownThree, {alpha: 0}, Conductor.crochet / 1000,
						{
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween):Void
							{
								remove(countdownThree);
								countdownTweens.remove(twn);
								countdownThree.destroy();
							}
						});

						countdownTweens.push(tween);

						var sound = FlxG.sound.play(Paths.getSound('intro3' + introSoundsSuffix), 0.6);
						countdownSounds.push(sound);
					}
					case 1:
					{
						countdownReady = new FlxSprite();

						var name:String = 'ready' + introImagesSuffix;

						if (Paths.fileExists('images/' + name + '.png', IMAGE)) {
							countdownReady.loadGraphic(Paths.getImage(name));
						}
						else if (Paths.fileExists('images/pixelUI/' + name + '.png', IMAGE)) {
							countdownReady.loadGraphic(Paths.getImage('pixelUI/' + name));
						}
						else {
							countdownReady.loadGraphic(Paths.getImage('countdown/' + name));
						}

						countdownReady.setGraphicSize(Std.int(countdownReady.width * 0.75));
						countdownReady.scrollFactor.set();

						if (isPixelStage) {
							countdownReady.setGraphicSize(Std.int(countdownReady.width * daPixelZoom));
						}

						countdownReady.updateHitbox();
						countdownReady.screenCenter();
						countdownReady.antialiasing = antialias;
						countdownReady.cameras = [camHUD];
						insert(members.indexOf(notes), countdownReady);

						var tween:FlxTween = FlxTween.tween(countdownReady, {alpha: 0}, Conductor.crochet / 1000,
						{
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween):Void
							{
								remove(countdownReady);
								countdownTweens.remove(twn);
								countdownReady.destroy();
							}
						});

						countdownTweens.push(tween);

						var sound = FlxG.sound.play(Paths.getSound('intro2' + introSoundsSuffix), 0.6);
						countdownSounds.push(sound);
					}
					case 2:
					{
						countdownSet = new FlxSprite();

						var name:String = 'set' + introImagesSuffix;

						if (Paths.fileExists('images/' + name + '.png', IMAGE)) {
							countdownSet.loadGraphic(Paths.getImage(name));
						}
						else if (Paths.fileExists('images/pixelUI/' + name + '.png', IMAGE)) {
							countdownSet.loadGraphic(Paths.getImage('pixelUI/' + name));
						}
						else {
							countdownSet.loadGraphic(Paths.getImage('countdown/' + name));
						}

						countdownSet.setGraphicSize(Std.int(countdownSet.width * 0.75));
						countdownSet.scrollFactor.set();

						if (isPixelStage) {
							countdownSet.setGraphicSize(Std.int(countdownSet.width * daPixelZoom));
						}

						countdownSet.updateHitbox();
						countdownSet.screenCenter();
						countdownSet.antialiasing = antialias;
						countdownSet.cameras = [camHUD];
						insert(members.indexOf(notes), countdownSet);

						var tween:FlxTween = FlxTween.tween(countdownSet, {alpha: 0}, Conductor.crochet / 1000,
						{
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween):Void
							{
								remove(countdownSet);
								countdownTweens.remove(twn);
								countdownSet.destroy();
							}
						});

						countdownTweens.push(tween);

						var sound = FlxG.sound.play(Paths.getSound('intro1' + introSoundsSuffix), 0.6);
						countdownSounds.push(sound);
					}
					case 3:
					{
						countdownGo = new FlxSprite();

						var name:String = 'go' + introImagesSuffix;

						if (Paths.fileExists('images/' + name + '.png', IMAGE)) {
							countdownGo.loadGraphic(Paths.getImage(name));
						}
						else if (Paths.fileExists('images/pixelUI/' + name + '.png', IMAGE)) {
							countdownGo.loadGraphic(Paths.getImage('pixelUI/' + name));
						}
						else {
							countdownGo.loadGraphic(Paths.getImage('countdown/' + name));
						}

						countdownGo.setGraphicSize(Std.int(countdownGo.width * 0.75));
						countdownGo.scrollFactor.set();

						if (isPixelStage) {
							countdownGo.setGraphicSize(Std.int(countdownGo.width * daPixelZoom));
						}

						countdownGo.updateHitbox();
						countdownGo.screenCenter();
						countdownGo.antialiasing = antialias;
						countdownGo.cameras = [camHUD];
						insert(members.indexOf(notes), countdownGo);

						var tween:FlxTween = FlxTween.tween(countdownGo, {alpha: 0}, Conductor.crochet / 1000,
						{
							ease: FlxEase.cubeInOut,
							onComplete: function(twn:FlxTween):Void
							{
								remove(countdownGo);
								countdownTweens.remove(twn);
								countdownGo.destroy();
							}
						});

						countdownTweens.push(tween);

						var sound = FlxG.sound.play(Paths.getSound('introGo' + introSoundsSuffix), 0.6);
						countdownSounds.push(sound);
					}
					case 4:
					{
						// da nothing here dumbass lol
					}
				}

				notes.forEachAlive(function(note:Note):Void
				{
					if (OptionData.opponentStrumsType != 'Disabled' || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;

						if (OptionData.middleScroll == true && !note.mustPress) {
							note.alpha *= 0.35;
						}
					}
				});

				callOnLuas('onCountdownTick', [swagCounter]);
				swagCounter += 1;
			}, 5);
		}
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	public var timerTween:Array<FlxTween> = [];

	public function startSong():Void
	{
		#if WEBM_ALLOWED
		var ourVideo:Dynamic = BackgroundVideo.get();

		if (useVideo && ourVideo != null) {
			ourVideo.resume();
		}
		#end

		prevCamFollowPos = null;
		prevCamFollow = null;

		blockedCameraMovementOnStart = false;

		startingSong = false;
		iconsZooming = true;

		previousFrameTime = FlxG.game.ticks;

		if (startOnTime > 0) {
			setSongTime(startOnTime - 500);
		}

		startOnTime = 0;

		switch (SONG.stage)
		{
			case 'tank':
			{
				if (!OptionData.lowQuality) tankWatchtower.dance();
		
				foregroundSprites.forEach(function(spr:BGSprite):Void {
					spr.dance();
				});
			}
		}

		FlxG.sound.playMusic(Paths.getInst(SONG.songID, CoolUtil.getDifficultySuffix(lastDifficulty), #if NO_PRELOAD_ALL true #else false #end), 1);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();
		vocals.play();

		if (paused)
		{
			FlxG.sound.music.pause();
			vocals.pause();
		}

		if (!blockedCameraMovementOnStart && !blockedCameraMovementOnEnd && !inCutscene && !isCameraOnForcedPos) {
			cameraMovementSection();
		}

		var twn:FlxTween = FlxTween.tween(songPosBar, {alpha: 1}, 0.4);
		timerTween.push(twn);

		var twn:FlxTween = FlxTween.tween(songPosName, {alpha: 1}, 0.4);
		timerTween.push(twn);

		songLength = FlxG.sound.music.length; // Song duration in a float, useful for the time left feature

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyIDDiscord, iconRPC, true, songLength); // Updating Discord Rich Presence (with Time Left)
		#end

		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	public function clearNotesBefore(time:Float)
	{
		var i:Int = unspawnNotes.length - 1;

		while (i >= 0)
		{
			var daNote:Note = unspawnNotes[i];

			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				unspawnNotes.remove(daNote);
				daNote.destroy();
			}

			--i;
		}

		i = notes.length - 1;

		while (i >= 0)
		{
			var daNote:Note = notes.members[i];

			if (daNote.strumTime - 350 < time)
			{
				daNote.active = false;
				daNote.visible = false;
				daNote.ignoreNote = true;

				daNote.kill();
				notes.remove(daNote, true);
				daNote.destroy();
			}

			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if (time < 0) time = 0;

		FlxG.sound.music.pause();
		vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = time;
			vocals.pitch = playbackRate;
		}

		vocals.play();

		Conductor.songPosition = time;
		songTime = time;
	}

	private function generateSong(songData:SwagSong):Void
	{
		Conductor.changeBPM(songData.bpm);

		if (gameMode != 'replay')
		{
			songSpeedType = PlayStateChangeables.scrollType;

			switch (songSpeedType)
			{
				case 'multiplicative':
					songSpeed = songData.speed * PlayStateChangeables.scrollSpeed;
				case 'constant':
					songSpeed = PlayStateChangeables.scrollSpeed;
			}
		}

		if (gameMode == 'replay')
		{
			cpuControlled = true;

			botplayTxt.visible = cpuControlled;
			OptionData.downScroll = rep.replay.isDownscroll;

			songSpeed = rep.replay.noteSpeed;
		}

		if (songData.needsVoices) {
			vocals = new FlxSound().loadEmbedded(Paths.getVoices(songData.songID, CoolUtil.getDifficultySuffix(lastDifficulty), #if NO_PRELOAD_ALL true #else false #end));
		}
		else {
			vocals = new FlxSound();
		}

		vocals.pitch = playbackRate;

		FlxG.sound.list.add(vocals);
		FlxG.sound.list.add(new FlxSound().loadEmbedded(Paths.getInst(songData.songID, CoolUtil.getDifficultySuffix(lastDifficulty), #if NO_PRELOAD_ALL true #else false #end)));

		var noteData:Array<SwagSection> = songData.notes;

		var file:String = Paths.getJson(songData.songID + '/events');

		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modsJson(songData.songID + '/events')) || FileSystem.exists(file))
		#else
		if (OpenFlAssets.exists(file))
		#end
		{
			var eventsData:Array<Dynamic> = Song.loadFromJson('events', songData.songID).events;

			for (event in eventsData) // Event Notes
			{
				for (i in 0...event[1].length)
				{
					var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];

					var subEvent:EventNote = {
						strumTime: newEventNote[0] + OptionData.noteOffset,
						event: newEventNote[1],
						value1: newEventNote[2],
						value2: newEventNote[3]
					};
					subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1] > 3) {
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note = null;

				if (unspawnNotes.length > 0) {
					oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];
				}

				var swagNote:Note = new Note(daStrumTime, randomNotes ? FlxG.random.int(0, Note.maxNote - 1) : daNoteData, oldNote, false, false, gottaHitNote);
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];
				swagNote.gfNote = (section.gfSection && (songNotes[1] < 4));

				var typeShit:String = (!Std.isOfType(songNotes[3], String) ? editors.ChartingState.noteTypeList[songNotes[3]] : songNotes[3]);
				swagNote.noteType = typeShit;
				swagNote.scrollFactor.set();

				var susLength:Float = swagNote.sustainLength;

				susLength = susLength / Conductor.stepCrochet;
				unspawnNotes.push(swagNote);

				var floorSus:Int = Math.floor(susLength);

				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = unspawnNotes[Std.int(unspawnNotes.length - 1)];

						var sustainNote:Note = new Note(daStrumTime + (Conductor.stepCrochet * susNote) + (Conductor.stepCrochet / FlxMath.roundDecimal(songSpeed, 2)), swagNote.noteData, oldNote, true, false, gottaHitNote);
						sustainNote.mustPress = gottaHitNote;
						sustainNote.gfNote = (section.gfSection && (songNotes[1] < 4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						unspawnNotes.push(sustainNote);

						if (sustainNote.mustPress) {
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if (OptionData.middleScroll == true)
						{
							sustainNote.x += 310;
		
							if (daNoteData > 1) { // Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress) {
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if (OptionData.middleScroll == true)
				{
					swagNote.x += 310;

					if (daNoteData > 1) { // Up and Right
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if (!noteTypeMap.exists(swagNote.noteType)) {
					noteTypeMap.set(swagNote.noteType, true);
				}
			}
		}

		for (event in songData.events) // Event Notes
		{
			for (i in 0...event[1].length)
			{
				var newEventNote:Array<Dynamic> = [event[0], event[1][i][0], event[1][i][1], event[1][i][2]];

				var subEvent:EventNote = {
					strumTime: newEventNote[0] + OptionData.noteOffset,
					event: newEventNote[1],
					value1: newEventNote[2],
					value2: newEventNote[3]
				};
				subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
				eventNotes.push(subEvent);
				eventPushed(subEvent);
			}
		}

		unspawnNotes.sort(sortByTime);

		var blyad:Int = unspawnNotes.length;

		var notesBlyad:Int = blyad;
		var susNotesBlyad:Int = 0;

		for (i in 0...blyad)
		{
			if (unspawnNotes[i].isSustainNote) {
				notesBlyad--;
			}

			if (unspawnNotes[i].tail.length > 0)
			{
				notesBlyad--;
				susNotesBlyad++;
			}
		}

		Debug.logInfo(SONG.songName + ": Generated " + (notesBlyad + susNotesBlyad) + " notes. (" + susNotesBlyad + " sustainables and " + notesBlyad + " unsustainables)");
		Debug.logInfo(SONG.songName + ": Generated " + eventNotes.length + " events.");

		generatedMusic = true;
	}

	public function eventPushed(event:EventNote):Void
	{
		switch (event.event)
		{
			case 'Change Character':
			{
				var charType:Int = 0;

				switch (event.value1.toLowerCase())
				{
					case 'gf' | 'girlfriend' | '1':
					{
						charType = 2;
					}
					case 'dad' | 'opponent' | '0':
					{
						charType = 1;
					}
					default:
					{
						charType = Std.parseInt(event.value1);
						if (Math.isNaN(charType)) charType = 0;
					}
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
			}
			case 'Dadbattle Spotlight':
			{
				dadbattleBlack = new BGSprite(null, -800, -400, 0, 0);
				dadbattleBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				dadbattleBlack.alpha = 0.25;
				dadbattleBlack.visible = false;
				add(dadbattleBlack);

				var pathShit:String = 'stage/spotlight';

				if (Paths.fileExists('images/spotlight.png', IMAGE)) {
					pathShit = 'spotlight';
				}

				dadbattleLight = new BGSprite(pathShit, 400, -400);
				dadbattleLight.alpha = 0.375;
				dadbattleLight.blend = ADD;
				dadbattleLight.visible = false;
				add(dadbattleLight);

				dadbattleSmokes.alpha = 0.7;
				dadbattleSmokes.blend = ADD;
				dadbattleSmokes.visible = false;
				add(dadbattleSmokes);

				var pathShit:String = 'stage/smoke';

				if (Paths.fileExists('images/smoke.png', IMAGE)) {
					pathShit = 'smoke';
				}

				var smoke:BGSprite = new BGSprite(pathShit, -1350, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(15, 22);
				smoke.active = true;
				dadbattleSmokes.add(smoke);

				var smoke:BGSprite = new BGSprite(pathShit, 1750, 660 + FlxG.random.float(-20, 20), 1.2, 1.05);
				smoke.setGraphicSize(Std.int(smoke.width * FlxG.random.float(1.1, 1.22)));
				smoke.updateHitbox();
				smoke.velocity.x = FlxG.random.float(-15, -22);
				smoke.active = true;
				smoke.flipX = true;
				dadbattleSmokes.add(smoke);
			}
			case 'Philly Glow':
			{
				blammedLightsBlack = new FlxSprite(FlxG.width * -0.5, FlxG.height * -0.5);
				blammedLightsBlack.makeGraphic(Std.int(FlxG.width * 2), Std.int(FlxG.height * 2), FlxColor.BLACK);
				blammedLightsBlack.visible = false;
				insert(members.indexOf(phillyStreet), blammedLightsBlack);

				phillyWindowEvent = new BGSprite('philly/window', phillyWindow.x, phillyWindow.y, 0.3, 0.3);
				phillyWindowEvent.setGraphicSize(Std.int(phillyWindowEvent.width * 0.85));
				phillyWindowEvent.updateHitbox();
				phillyWindowEvent.visible = false;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyWindowEvent);

				phillyGlowGradient = new PhillyGlowGradient(-400, 225); // This shit was refusing to properly load FlxGradient so fuck it
				phillyGlowGradient.visible = false;
				phillyGlowGradient.intendedAlpha = OptionData.flashingLights ? 1 : 0.7;
				insert(members.indexOf(blammedLightsBlack) + 1, phillyGlowGradient);

				CoolUtil.precacheImage('philly/particle');

				phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
			}
		}

		if (!eventPushedMap.exists(event.event)) {
			eventPushedMap.set(event.event, true);
		}
	}

	public function eventNoteEarlyTrigger(event:EventNote):Float
	{
		var returnedValue:Null<Float> = callOnLuas('eventEarlyTrigger', [event.event, event.value1, event.value2, event.strumTime], [], [0]);

		if (returnedValue != null && returnedValue != 0 && returnedValue != FunkinLua.Function_Continue) {
			return returnedValue;
		}

		switch (event.event)
		{
			case 'Kill Henchmen': // Better timing so that the kill sound matches the beat intended
				return 280; // Plays 280ms before the actual position
		}

		return 0;
	}

	function sortByTime(obj1:Dynamic, obj2:Dynamic):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, obj1.strumTime, obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; // for lua
	public var staticArrowsTweens:Array<FlxTween> = [];

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...4)
		{
			var targetAlpha:Float = 1;

			if (player == 0)
			{
				if (OptionData.opponentStrumsType == 'Disabled') {
					targetAlpha = 0;
				}
				else if (OptionData.middleScroll == true) {
					targetAlpha = 0.35;
				}
			}

			var babyArrow:StrumNote = new StrumNote(OptionData.middleScroll == true ? STRUM_X_MIDDLESCROLL : STRUM_X, strumLine.y, i, player);
			babyArrow.downScroll = OptionData.downScroll == true;

			if (!skipArrowStartTween)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;

				var tween:FlxTween = FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1 / playbackRate, {ease: FlxEase.circOut, startDelay: (0.5 + (0.2 * i)) / playbackRate});
				staticArrowsTweens.push(tween);
			}

			switch (player)
			{
				case 0:
				{
					if (OptionData.middleScroll == true)
					{
						babyArrow.x += 310;
	
						if (i > 1) { // Up and Right
							babyArrow.x += FlxG.width / 2 + 25;
						}
					}

					opponentStrums.add(babyArrow);
				}
				case 1:
				{
					playerStrums.add(babyArrow);
				}
			}

			babyArrow.postAddedToGroup();
			strumLineNotes.add(babyArrow);
		}
	}

	public override function openSubState(SubState:FlxSubState):Void
	{
		super.openSubState(SubState);

		if (paused)
		{
			if (FlxG.sound.music != null)
			{
				FlxG.sound.music.pause();
				vocals.pause();
			}

			if (!startTimer.finished) {
				startTimer.active = false;
			}

			if (finishTimer != null && !finishTimer.finished) {
				finishTimer.active = false;
			}

			if (cameraTwn != null && !cameraTwn.finished) {
				cameraTwn.active = false;
			}

			if (weekSevenTweenCameraZoomShit != null && !weekSevenTweenCameraZoomShit.finished) {
				weekSevenTweenCameraZoomShit.active = false;
			}

			for (tween in staticArrowsTweens) {
				tween.active = false;
			}

			for (tween in countdownTweens) {
				tween.active = false;
			}

			for (sound in countdownSounds)
			{
				@:privateAccess
				if (!sound._paused) sound.pause();
			}
			
			var chars:Array<Character> = [boyfriend, gf, dad];

			for (char in chars)
			{
				if (char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			if (trainSound != null) {
				trainSound.active = false;
			}

			if (carPassSound != null) {
				carPassSound.active = false;
			}

			if (deathSound != null) {
				deathSound.active = false;
			}

			if (scoreTxtTween != null) {
				scoreTxtTween.active = false;
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}

			if (songSpeedTween != null) {
				songSpeedTween.active = false;
			}

			for (timer in modchartTimers) {
				timer.active = false;
			}

			for (sound in modchartSounds)
			{
				@:privateAccess
				if (!sound._paused) sound.pause();
			}

			for (tween in ratingTweensArray) {
				tween.active = false;
			}

			for (tween in numbersTweensArray) {
				tween.active = false;
			}

			for (tween in timerTween) {
				tween.active = false;
			}
		}
	}

	public function resume():Void
	{
		allowPlayCutscene = ((gameMode == 'story' && OptionData.cutscenesInType.contains('Story'))
			|| (gameMode == 'freeplay' && OptionData.cutscenesInType.contains('Freeplay'))
			|| (gameMode == 'replay' && OptionData.cutscenesInType.contains('Replay'))
			|| OptionData.cutscenesInType == 'Everywhere') && !seenCutscene;

		setOnLuas('allowPlayCutscene', allowPlayCutscene);

		healthGain = PlayStateChangeables.healthGain;
		healthLoss = PlayStateChangeables.healthLoss;

		instakillOnMiss = PlayStateChangeables.instaKill;
		cpuControlled = PlayStateChangeables.botPlay;
		playbackRate = PlayStateChangeables.playbackRate;

		callOnLuas('onResume', []);
	}

	public override function closeSubState():Void
	{
		super.closeSubState();

		if (isNextSubState) {
			isNextSubState = false;
		}
		else if (paused)
		{
			if (FlxG.sound.music != null && !startingSong) {
				resyncVocals();
			}

			if (!startTimer.finished) {
				startTimer.active = true;
			}

			if (songSpeedTween != null) {
				songSpeedTween.active = true;
			}

			if (finishTimer != null && !finishTimer.finished) {
				finishTimer.active = true;
			}

			if (camGame != null) {
				camGame.active = true;
			}
	
			if (camHUD != null) {
				camHUD.active = true;
			}

			if (cameraTwn != null && !cameraTwn.finished) {
				cameraTwn.active = true;
			}

			if (weekSevenTweenCameraZoomShit != null && !weekSevenTweenCameraZoomShit.finished) {
				weekSevenTweenCameraZoomShit.active = true;
			}

			var chars:Array<Character> = [boyfriend, gf, dad];

			for (char in chars)
			{
				if (char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}

			if (trainSound != null) {
				trainSound.active = true;
			}

			if (carPassSound != null) {
				carPassSound.active = true;
			}

			if (deathSound != null) {
				deathSound.active = true;
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}

			if (scoreTxtTween != null) {
				scoreTxtTween.active = true;
			}

			for (tween in staticArrowsTweens) {
				tween.active = true;
			}

			for (timer in modchartTimers) {
				timer.active = true;
			}

			for (sound in modchartSounds)
			{
				@:privateAccess
				if (sound._paused) sound.resume();
			}

			for (tween in ratingTweensArray) {
				tween.active = true;
			}

			for (tween in numbersTweensArray) {
				tween.active = true;
			}

			for (tween in countdownTweens) {
				tween.active = true;
			}

			for (sound in countdownSounds)
			{
				@:privateAccess
				if (sound._paused) sound.resume();
			}

			for (tween in timerTween) {
				tween.active = true;
			}

			FlxTimer.globalManager.forEach(function(tmr:FlxTimer):Void
			{
				if (!tmr.finished) tmr.active = true;
			});

			FlxG.sound.list.forEachAlive(function(sound:FlxSound):Void
			{
				@:privateAccess
				if (sound._paused) sound.resume();
			});

			FlxTween.globalManager.forEach(function(twn:FlxTween):Void
			{
				if (!twn.finished) twn.active = true;
			});

			paused = false;

			#if DISCORD_ALLOWED
			if (startTimer.finished) {
				DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyIDDiscord, iconRPC, true, songLength - Conductor.songPosition - OptionData.noteOffset);
			}
			else {
				DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyIDDiscord, iconRPC);
			}
			#end
		}
	}

	public override function onFocus():Void
	{
		super.onFocus();

		#if DISCORD_ALLOWED
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0) {
				DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyIDDiscord, iconRPC, true, songLength - Conductor.songPosition - OptionData.noteOffset);
			}
			else {
				DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyIDDiscord, iconRPC);
			}
		}
		#end
	}
	
	public override function onFocusLost():Void
	{
		#if DISCORD_ALLOWED
		if (health > 0 && !paused) {
			DiscordClient.changePresence(detailsPausedText, SONG.songName + " - " + storyDifficultyIDDiscord, iconRPC);
		}
		#end

		super.onFocusLost();
	}

	public function resyncVocals():Void
	{
		if (finishTimer != null) return;
		
		vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;

		Conductor.songPosition = FlxG.sound.music.time;

		if (Conductor.songPosition <= vocals.length)
		{
			vocals.time = Conductor.songPosition;
			vocals.pitch = playbackRate;
		}

		vocals.play();
	}

	public function recalculateRating():Void
	{
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', [], false);

		if (ret != FunkinLua.Function_Stop)
		{
			if (totalPlayed < 1) {
				ratingString = 'N/A';
			}
			else
			{
				songAccuracy = Math.min(1, Math.max(0, totalNotesHit / totalPlayed)) * 100;

				if (songAccuracy >= 100) {
					ratingString = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length - 1)
					{
						if (songAccuracy < ratingStuff[i][1])
						{
							ratingString = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			comboRank = "";

			if (sicks > 0)
				comboRank = 'SFC';
			if (goods > 0)
				comboRank = 'GFC';
			if (bads > 0 || shits > 0)
				comboRank = 'FC';
			if (songMisses > 0 && songMisses < 10)
				comboRank = 'SDCB';
			else if (songMisses >= 10)
				comboRank = 'Clear';
		}

		updateScore();

		setOnLuas('accuracy', songAccuracy);
		setOnLuas('rating', songAccuracy);
		setOnLuas('ratingName', ratingString);
		setOnLuas('ratingFC', comboRank);
	}

	public var paused:Bool = false;

	public var canPause:Bool = true;
	public var canReset:Bool = true;

	var limoSpeed:Float = 0;

	public override function update(elapsed:Float):Void
	{
		callOnLuas('onUpdate', [elapsed]);

		switch (SONG.stage)
		{
			case 'philly':
			{
				if (trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}

				phillyWindow.alpha -= (Conductor.crochet / 1000) * FlxG.elapsed * 1.5;

				if (phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.members.length - 1;

					while (i > 0)
					{
						var particle:PhillyGlowParticle = phillyGlowParticles.members[i];

						if (particle.alpha <= 0)
						{
							particle.kill();
							phillyGlowParticles.remove(particle, true);
							particle.destroy();
						}

						--i;
					}
				}
			}
			case 'limo':
			{
				if (OptionData.lowQuality == false)
				{
					grpLimoParticles.forEach(function(spr:BGSprite):Void
					{
						if (spr.animation.curAnim.finished)
						{
							spr.kill();
							grpLimoParticles.remove(spr, true);
							spr.destroy();
						}
					});

					switch (limoKillingState)
					{
						case 1:
						{
							limoMetalPole.x += 5000 * elapsed;
							limoLight.x = limoMetalPole.x - 180;
							limoCorpse.x = limoLight.x - 50;
							limoCorpseTwo.x = limoLight.x + 35;

							var dancers:Array<BackgroundDancer> = grpLimoDancers.members;

							for (i in 0...dancers.length)
							{
								if (dancers[i].x < FlxG.width * 1.5 && limoLight.x > (370 * i) + 170)
								{
									switch (i)
									{
										case 0 | 3:
										{
											if (i == 0) deathSound.play();

											var diffStr:String = i == 3 ? ' 2 ' : ' ';

											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 200, dancers[i].y, 0.4, 0.4, ['hench leg spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x + 160, dancers[i].y + 200, 0.4, 0.4, ['hench arm spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/noooooo', dancers[i].x, dancers[i].y + 50, 0.4, 0.4, ['hench head spin' + diffStr + 'PINK'], false);
											grpLimoParticles.add(particle);

											var particle:BGSprite = new BGSprite('gore/stupidBlood', dancers[i].x - 110, dancers[i].y + 20, 0.4, 0.4, ['blood'], false);
											particle.flipX = true;
											particle.angle = -57.5;
											grpLimoParticles.add(particle);
										}
										case 1:
										{
											limoCorpse.visible = true;
										}
										case 2:
										{
											limoCorpseTwo.visible = true;
										}
									}

									dancers[i].x += FlxG.width * 2;
								}
							}

							if (limoMetalPole.x > FlxG.width * 2)
							{
								resetLimoKill();

								limoSpeed = 800;
								limoKillingState = 2;
							}
						}
						case 2:
						{
							limoSpeed -= 4000 * elapsed;
							bgLimo.x -= limoSpeed * elapsed;

							if (bgLimo.x > FlxG.width * 1.5)
							{
								limoSpeed = 3000;
								limoKillingState = 3;
							}
						}
						case 3:
						{
							limoSpeed -= 2000 * elapsed;
							if (limoSpeed < 1000) limoSpeed = 1000;

							bgLimo.x -= limoSpeed * elapsed;

							if (bgLimo.x < -275)
							{
								limoKillingState = 4;
								limoSpeed = 800;
							}
						}
						case 4:
						{
							bgLimo.x = CoolUtil.coolLerp(bgLimo.x, -150, 0.16);

							if (Math.round(bgLimo.x) == -150)
							{
								bgLimo.x = -150;
								limoKillingState = 0;
							}
						}
					}

					if (limoKillingState > 2)
					{
						var dancers:Array<BackgroundDancer> = grpLimoDancers.members;

						for (i in 0...dancers.length) {
							dancers[i].x = (370 * i) + bgLimo.x + 280;
						}
					}
				}
			}
			case 'mall':
			{
				if (heyTimer > 0)
				{
					heyTimer -= elapsed;

					if (heyTimer <= 0)
					{
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
			}
			case 'schoolEvil':
			{
				if (!OptionData.lowQuality && bgGhouls != null && bgGhouls.animation.curAnim.finished) {
					bgGhouls.visible = false;
				}
			}
			case 'tank':
			{
				moveTank(elapsed);
			}
		}

		#if WEBM_ALLOWED
		var ourVideo:Dynamic = BackgroundVideo.get();

		if (useVideo && ourVideo != null && !stopUpdate && !FlxG.save.data.lowDetail)
		{
			if (ourVideo.ended && !removedVideo)
			{
				remove(videoSprite);

				removedVideo = true;
				useVideo = false;
			}
		}
		#end

		super.update(elapsed);

		if (!inCutscene)
		{
			camFollowPos.setPosition(CoolUtil.coolLerp(camFollowPos.x, camFollow.x, 0.04 * cameraSpeed * playbackRate), CoolUtil.coolLerp(camFollowPos.y, camFollow.y, 0.04 * cameraSpeed * playbackRate));

			if (!startingSong && !endingSong && boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle'))
			{
				boyfriendIdleTime += elapsed;

				if (boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			}
			else {
				boyfriendIdleTime = 0;
			}
		}

		if (botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (controls.PAUSE && startedCountdown && canPause && !OptionData.controllerMode)
		{
			var ret:Dynamic = callOnLuas('onPause', [], false);

			if (ret != FunkinLua.Function_Stop) {
				openPauseMenu();
			}
		}

		if (controls.RESET && !OptionData.noReset && canReset && !inCutscene && startedCountdown && !endingSong && !usedPractice) {
			health = 0;
		}

		doDeathCheck();

		if (health < 0 && practiceMode) {
			health = 0;
		}

		if (health > 2) {
			health = 2;
		}

		if (FlxG.keys.anyJustPressed(debugKeysChart) && !endingSong && !inCutscene && gameMode != 'replay') {
			openChartEditor();
		}

		#if MODS_ALLOWED
		if (FlxG.keys.anyJustPressed(debugKeysCharacter) && !endingSong && !inCutscene) {
			openCharacterEditor();
		}
		#end

		var mult:Float = CoolUtil.coolLerp(1, iconP1.scale.x, 0.16, 54.5 * playbackRate, 1);
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = CoolUtil.coolLerp(1, iconP2.scale.x, 0.16, 54.5 * playbackRate, 1);
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);

		if (healthBar.percent < 20)
		{
			iconP1.animation.curAnim.curFrame = 1;
	
			if (iconP2.animation.curAnim.numFrames == 3) {
				iconP2.animation.curAnim.curFrame = 2;
			}
		}
		else if (healthBar.percent > 80)
		{
			iconP2.animation.curAnim.curFrame = 1;
	
			if (iconP1.animation.curAnim.numFrames == 3) {
				iconP1.animation.curAnim.curFrame = 2;
			}
		}
		else
		{
			iconP1.animation.curAnim.curFrame = 0;
			iconP2.animation.curAnim.curFrame = 0;
		}

		if (startedCountdown) {
			Conductor.songPosition += FlxG.elapsed * 1000 * playbackRate;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if (!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}
		else
		{
			if (!paused)
			{
				songTime += FlxG.game.ticks - previousFrameTime;
				previousFrameTime = FlxG.game.ticks;

				if (Conductor.lastSongPos != Conductor.songPosition)
				{
					songTime = (songTime + Conductor.songPosition) / 2;
					Conductor.lastSongPos = Conductor.songPosition;
				}

				if (updateTime)
				{
					var curTime:Float = Conductor.songPosition - OptionData.noteOffset;
					if (curTime < 0) curTime = 0;

					songPositionBar = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if (secondsTotal < 0) secondsTotal = 0;

					var secondsTotalBlyad:Int = Math.floor(curTime / 1000);
					if (secondsTotalBlyad < 0) secondsTotalBlyad = 0;

					songPosName.text = SONG.songName + " - " + CoolUtil.getDifficultyName(lastDifficulty, difficulties);

					if (OptionData.songPositionType != 'Song Name')
					{
						switch (OptionData.songPositionType)
						{
							case 'Time Left and Elapsed':
								songPosName.text += ' (' + FlxStringUtil.formatTime(secondsTotalBlyad, false) + ' / ' + FlxStringUtil.formatTime(secondsTotal, false) + ')';
							case 'Time Elapsed':
								songPosName.text += ' (' + FlxStringUtil.formatTime(secondsTotalBlyad, false) + ')';
							default:
								songPosName.text += ' (' + FlxStringUtil.formatTime(secondsTotal, false) + ')';
						}
					}
				}
			}
		}

		if (camZooming) {
			FlxG.camera.zoom = CoolUtil.coolLerp(defaultCamZoom, FlxG.camera.zoom, 0.95 * camZoomingDecay * playbackRate, 3.35, 1);
		}

		if (camHUDZooming) {
			camHUD.zoom = CoolUtil.coolLerp(1, camHUD.zoom, 0.95 * camHUDZoomingDecay * playbackRate, 3.35, 1);
		}

		FlxG.watch.addQuick("secShit", curSection);
		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		if (unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;

			if (songSpeed < 1) time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				callOnLuas('onSpawnNote', [notes.members.indexOf(dunceNote), dunceNote.noteData, dunceNote.noteType, dunceNote.isSustainNote]);

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic && !inCutscene)
		{
			if (!startingSong && !endingSong)
			{
				if (!cpuControlled) {
					keyShit();
				}
				else if (boyfriend.holdTimer > Conductor.stepCrochet * (0.0011 / FlxG.sound.music.pitch) * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
					boyfriend.dance();
				}
			}

			if (startedCountdown)
			{
				notes.forEachAlive(function(daNote:Note):Void
				{
					var strumGroup:FlxTypedGroup<StrumNote> = daNote.mustPress ? playerStrums : opponentStrums;

					var strumX:Float = strumGroup.members[daNote.noteData].x;
					var strumY:Float = strumGroup.members[daNote.noteData].y;
		
					var strumAngle:Float = strumGroup.members[daNote.noteData].angle;
					var strumDirection:Float = strumGroup.members[daNote.noteData].direction;
		
					var strumAlpha:Float = strumGroup.members[daNote.noteData].alpha;
					var strumScroll:Bool = strumGroup.members[daNote.noteData].downScroll;

					strumX += daNote.offsetX;
					strumY += daNote.offsetY;

					strumAngle += daNote.offsetAngle;
					strumAlpha *= daNote.multAlpha;

					if (strumScroll) {
						daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
					}
					else {
						daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
					}

					var angleDir:Float = strumDirection * Math.PI / 180;
		
					if (daNote.copyAngle) {
						daNote.angle = strumDirection - 90 + strumAngle;
					}

					if (daNote.copyAlpha) {
						daNote.alpha = strumAlpha;
					}

					if (daNote.copyX) {
						daNote.x = strumX + Math.cos(angleDir) * daNote.distance;
					}

					noteMovement(daNote, strumGroup, strumY + Note.swagWidth / 2, strumY, ((60 / SONG.bpm) * 1000), angleDir, strumScroll);

					if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) {
						opponentNoteHit(daNote);
					}

					if (!daNote.blockHit && daNote.mustPress && cpuControlled && daNote.canBeHit)
					{
						if (daNote.isSustainNote)
						{
							if (daNote.canBeHit && !daNote.ignoreNote) {
								goodNoteHit(daNote);
							}
						}
						else if ((daNote.strumTime <= Conductor.songPosition || (daNote.isSustainNote && daNote.canBeHit && daNote.mustPress)) && !daNote.ignoreNote) {
							goodNoteHit(daNote);
						}
					}

					if (Conductor.songPosition > noteKillOffset + daNote.strumTime)
					{
						if (daNote.mustPress && !cpuControlled && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit)) {
							noteMiss(daNote);
						}

						daNote.active = false;
						daNote.visible = false;

						daNote.kill();
						notes.remove(daNote, true);
						daNote.destroy();
					}
				});
			}
			else
			{
				notes.forEachAlive(function(daNote:Note):Void
				{
					daNote.canBeHit = false;
					daNote.wasGoodHit = false;
				});
			}
		}

		checkEventNote();

		#if debug
		if (!startingSong && !endingSong)
		{
			if (FlxG.keys.justPressed.ONE)
			{
				KillNotes();
				FlxG.sound.music.onComplete();
			}

			if (FlxG.keys.justPressed.TWO) //Go 10 seconds into the future :O
			{
				setSongTime(Conductor.songPosition + 10000);
				clearNotesBefore(Conductor.songPosition);
			}
		}
		#end

		setOnLuas('cameraX', camFollowPos.x);
		setOnLuas('cameraY', camFollowPos.y);

		setOnLuas('botPlay', cpuControlled);

		callOnLuas('onUpdatePost', [elapsed]);
	}

	private function noteMovement(daNote:Note, strumGroup:FlxTypedGroup<StrumNote>, center:Float, strumY:Float, fakeCrochet:Float, angleDir:Float, strumScroll:Bool):Void
	{
		if (daNote.copyY)
		{
			daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

			if (strumScroll && daNote.isSustainNote) // Jesus fuck this took me so much mother fucking time AAAAAAAAAA
			{
				if (daNote.animation.curAnim.name.endsWith('end'))
				{
					daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
					daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;
	
					if (PlayState.isPixelStage) {
						daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
					}
					else {
						daNote.y -= 19;
					}
				}

				daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
				daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
			}
		}

		switch (OptionData.sustainsType)
		{
			case 'Old':
			{
				if (daNote.y > FlxG.height)
				{
					daNote.active = false;
					daNote.visible = false;
				}
				else
				{
					daNote.visible = true;
					daNote.active = true;
				}
			}
			case 'New':
			{
				if (strumGroup.members[daNote.noteData].sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) &&
					(!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						if (daNote.y - daNote.offset.y * daNote.scale.y + daNote.height >= center)
						{
							var swagRect:FlxRect = new FlxRect(0, 0, daNote.frameWidth, daNote.frameHeight);
							swagRect.height = (center - daNote.y) / daNote.scale.y;
							swagRect.y = daNote.frameHeight - swagRect.height;
		
							daNote.clipRect = swagRect;
						}
					}
					else
					{
						if (daNote.y + daNote.offset.y * daNote.scale.y <= center)
						{
							var swagRect:FlxRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
							swagRect.y = (center - daNote.y) / daNote.scale.y;
							swagRect.height -= swagRect.y;
		
							daNote.clipRect = swagRect;
						}
					}
				}
			}
		}
	}

	public function openPauseMenu():Void
	{
		if (camGame != null) {
			camGame.active = false;
		}

		if (camHUD != null) {
			camHUD.active = false;
		}

		FlxTimer.globalManager.forEach(function(tmr:FlxTimer):Void
		{
			if (!tmr.finished) tmr.active = false;
		});

		FlxG.sound.list.forEachAlive(function(sound:FlxSound):Void
		{
			@:privateAccess
			if (!sound._paused) sound.pause();
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween):Void
		{
			if (!twn.finished) twn.active = false;
		});

		persistentUpdate = false;
		persistentDraw = true;

		paused = true;

		openSubState(new PauseSubState(false));
	
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(detailsPausedText, SONG.songName + " - " + storyDifficultyIDDiscord, iconRPC);
		#end
	}

	public var isDead:Bool = false;

	public function doDeathCheck(?skipHealthCheck:Bool = false):Bool
	{
		if (((skipHealthCheck && instakillOnMiss) || health <= 0) && !practiceMode && !cpuControlled)
		{
			var ret:Dynamic = callOnLuas('onGameOver', [], false);

			if (ret != FunkinLua.Function_Stop)
			{
				isDead = true;

				deathCounter++;

				boyfriend.stunned = true;

				persistentUpdate = false;
				persistentDraw = false;
				paused = true;

				for (sound in modchartSounds)
				{
					@:privateAccess
					if (sound._paused) sound.resume();
				}

				for (tween in modchartTweens) {
					tween.active = true;
				}

				for (timer in modchartTimers) {
					timer.active = true;
				}

				FlxG.sound.music.stop();
				vocals.stop();

				FlxAnimationController.globalSpeed = 1;

				openSubState(new GameOverSubState(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1]));
				
				#if DISCORD_ALLOWED
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.songName + " - " + storyDifficultyIDDiscord, iconRPC);
				#end

				return true;
			}
		}

		return false;
	}

	public function openChartEditor():Void
	{
		chartingMode = true;

		persistentUpdate = false;
		paused = true;

		cancelMusicFadeTween();

		FlxG.switchState(new editors.ChartingState());

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public override function onTransIn():Void
	{
		super.onTransIn();

		#if WEBM_ALLOWED
		var ourVideo:Dynamic = BackgroundVideo.get();

		if (useVideo && ourVideo != null)
		{
			ourVideo.stop();
			remove(videoSprite);
		}

		removedVideo = true;
		#end
	}

	public function openCharacterEditor():Void
	{
		persistentUpdate = false;
		paused = true;

		cancelMusicFadeTween();

		Transition.nextCamera = camOther;
		FlxG.switchState(new editors.CharacterEditorState(SONG.player2, true));
	}

	public function checkEventNote():Void
	{
		while (eventNotes.length > 0) 
		{
			var leStrumTime:Float = eventNotes[0].strumTime;

			if (Conductor.songPosition < leStrumTime) {
				return;
			}

			var value1:String = '';

			if (eventNotes[0].value1 != null) {
				value1 = eventNotes[0].value1;
			}

			var value2:String = '';

			if (eventNotes[0].value2 != null) {
				value2 = eventNotes[0].value2;
			}

			triggerEventNote(eventNotes[0].event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String):Bool
	{
		return Reflect.getProperty(controls, key);
	}

	var boomSpeed:Int = 4;
	var bamVal:Int = 1;

	public function triggerEventNote(eventName:String, value1:String, value2:String):Void
	{
		switch (eventName)
		{
			case 'Dadbattle Spotlight':
			{
				var val:Null<Int> = Std.parseInt(value1);
				if (val == null) val = 0;

				switch (Std.parseInt(value1))
				{
					case 1, 2, 3:
					{
						if (val == 1)
						{
							dadbattleBlack.visible = true;
							dadbattleLight.visible = true;

							dadbattleSmokes.visible = true;
							defaultCamZoom += 0.12;
						}

						var who:Character = dad;
						if (val > 2) who = boyfriend;

						dadbattleLight.alpha = 0;

						new FlxTimer().start(0.12, function(tmr:FlxTimer):Void
						{
							dadbattleLight.alpha = 0.375;
						});

						dadbattleLight.setPosition(who.getGraphicMidpoint().x - dadbattleLight.width / 2, who.y + who.height - dadbattleLight.height + 50);
					}
					default:
					{
						dadbattleBlack.visible = false;
						dadbattleLight.visible = false;

						defaultCamZoom -= 0.12;

						FlxTween.tween(dadbattleSmokes, {alpha: 0}, 1,
						{
							onComplete: function(twn:FlxTween):Void {
								dadbattleSmokes.visible = false;
							}
						});
					}
				}
			}
			case 'Hey!':
			{
				var value:Int = 2;

				switch (value1.toLowerCase().trim())
				{
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
					case 'bfgf' | 'bfandgf' | 'bfxgf' | 'bf and gf' | 'bf x gf' | 'bf-and-gf' | 'bf-x-gf' | '2':
						value = 2;
				}

				var time:Float = Std.parseFloat(value2);
				if (Math.isNaN(time) || time <= 0) time = 0.6;

				switch (value)
				{
					case 0:
					{
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = time;
					}
					case 1:
					{
						if (dad.curCharacter.startsWith('gf'))
						{
							dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = time;
						}
						else if (gf != null)
						{
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = time;
						}
	
						if (SONG.stage == 'mall')
						{
							bottomBoppers.animation.play('hey', true);
							heyTimer = time;
						}
					}
					case 2:
					{
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = time;

						if (dad.curCharacter.startsWith('gf'))
						{
							dad.playAnim('cheer', true);
							dad.specialAnim = true;
							dad.heyTimer = time;
						}
						else if (gf != null)
						{
							gf.playAnim('cheer', true);
							gf.specialAnim = true;
							gf.heyTimer = time;
						}
	
						if (SONG.stage == 'mall')
						{
							bottomBoppers.animation.play('hey', true);
							heyTimer = time;
						}
					}
				}
			}
			case 'Set GF Speed':
			{
				var value:Int = Std.parseInt(value1);

				if (Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;
			}
			case 'Philly Glow':
			{
				var lightId:Int = Std.parseInt(value1);
				if (Math.isNaN(lightId)) lightId = 0;

				var doFlash:Void->Void = function():Void
				{
					var color:FlxColor = FlxColor.WHITE;
					if (!OptionData.flashingLights) color.alphaFloat = 0.5;

					FlxG.camera.flash(color, 0.15, null, true);
				};

				var chars:Array<Character> = [boyfriend, gf, dad];

				switch (lightId)
				{
					case 0:
					{
						if (phillyGlowGradient.visible)
						{
							doFlash();

							if (OptionData.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = false;
							phillyWindowEvent.visible = false;

							phillyGlowGradient.visible = false;
							phillyGlowParticles.visible = false;
	
							curLightEvent = -1;

							for (who in chars) {
								who.color = FlxColor.WHITE;
							}

							phillyStreet.color = FlxColor.WHITE;
						}
					}
					case 1: // turn on
					{
						curLightEvent = FlxG.random.int(0, phillyLightsColors.length - 1, [curLightEvent]);
						var color:FlxColor = phillyLightsColors[curLightEvent];

						if (!phillyGlowGradient.visible)
						{
							doFlash();

							if (OptionData.camZooms)
							{
								FlxG.camera.zoom += 0.5;
								camHUD.zoom += 0.1;
							}

							blammedLightsBlack.visible = true;
							blammedLightsBlack.alpha = 1;
							phillyWindowEvent.visible = true;
							phillyGlowGradient.visible = true;
							phillyGlowParticles.visible = true;
						}
						else if (OptionData.flashingLights)
						{
							var colorButLower:FlxColor = color;
							colorButLower.alphaFloat = 0.25;

							FlxG.camera.flash(colorButLower, 0.5, null, true);
						}

						var charColor:FlxColor = color;

						if (!OptionData.flashingLights)
							charColor.saturation *= 0.5;
						else
							charColor.saturation *= 0.75;

						for (who in chars) {
							who.color = charColor;
						}

						phillyGlowParticles.forEachAlive(function(particle:PhillyGlowParticle):Void {
							particle.color = color;
						});

						phillyGlowGradient.color = color;
						phillyWindowEvent.color = color;

						color.brightness *= 0.5;
						phillyStreet.color = color;
					}
					case 2: // spawn particles
					{
						if (OptionData.lowQuality == false)
						{
							var particlesNum:Int = FlxG.random.int(8, 12);
							var width:Float = (2000 / particlesNum);
							var color:FlxColor = phillyLightsColors[curLightEvent];

							for (j in 0...3)
							{
								for (i in 0...particlesNum)
								{
									var particle:PhillyGlowParticle = new PhillyGlowParticle(-400 + width * i + FlxG.random.float(-width / 5, width / 5), phillyGlowGradient.originalY + 200 + (FlxG.random.float(0, 125) + j * 40), color);
									phillyGlowParticles.add(particle);
								}
							}
						}

						phillyGlowGradient.bop();
					}
				}
			}
			case 'Kill Henchmen':
			{
				killHenchmen();
			}
			case 'Add Camera Zoom':
			{
				if (OptionData.camZooms && FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);

					if (Math.isNaN(camZoom)) camZoom = 0.015;
					if (Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camHUD.zoom += hudZoom;
				}
			}
			case 'Trigger BG Ghouls':
			{
				if (SONG.stage == 'schoolEvil' && !OptionData.lowQuality)
				{
					bgGhouls.dance(true);
					bgGhouls.visible = true;
				}
			}
			case 'Play Animation':
			{
				var char:Character = dad;

				switch (value2.toLowerCase().trim()) 
				{
					case 'bf' | 'boyfriend': char = boyfriend;
					case 'gf' | 'girlfriend': char = gf;
					default:
					{
						var val2:Int = Std.parseInt(value2);
						if (Math.isNaN(val2)) val2 = 0;

						switch (val2)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
					}
				}

				if (char != null)
				{
					char.playAnim(value1, true);
					char.specialAnim = true;
				}
			}
			case 'Camera Follow Pos':
			{
				if (camFollow != null)
				{
					var val1:Float = Std.parseFloat(value1);
					var val2:Float = Std.parseFloat(value2);

					if (Math.isNaN(val1)) val1 = 0;
					if (Math.isNaN(val2)) val2 = 0;

					isCameraOnForcedPos = false;

					if (!Math.isNaN(Std.parseFloat(value1)) || !Math.isNaN(Std.parseFloat(value2)))
					{
						camFollow.x = val1;
						camFollow.y = val2;

						isCameraOnForcedPos = true;
					}
				}
			}
			case 'Alt Idle Animation':
			{
				var char:Character = dad;

				switch (value1.toLowerCase())
				{
					case 'gf' | 'girlfriend': {
						char = gf;
					}
					case 'boyfriend' | 'bf': {
						char = boyfriend;
					}
					default:
					{
						var val:Int = Std.parseInt(value1);
						if (Math.isNaN(val)) val = 0;

						switch (val)
						{
							case 1: char = boyfriend;
							case 2: char = gf;
						}
					}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}
			}
			case 'Screen Shake':
			{
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];

				for (i in 0...targetsArray.length)
				{
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;

					if (split[0] != null) duration = Std.parseFloat(split[0].trim());
					if (split[1] != null) intensity = Std.parseFloat(split[1].trim());

					if (Math.isNaN(duration)) duration = 0;
					if (Math.isNaN(intensity)) intensity = 0;

					if (OptionData.camShakes && duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}
			}
			case 'Change Character':
			{
				var charType:Int = 0;

				switch (value1)
				{
					case 'gf' | 'girlfriend': {
						charType = 2;
					}
					case 'dad' | 'opponent': {
						charType = 1;
					}
					default:
					{
						charType = Std.parseInt(value1);
						if (Math.isNaN(charType)) charType = 0;
					}
				}

				switch (charType)
				{
					case 0:
					{
						if (boyfriend.curCharacter != value2)
						{
							if (!boyfriendMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var lastAlpha:Float = boyfriend.alpha;
							boyfriend.alpha = 0.00001;
							boyfriend = boyfriendMap.get(value2);
							boyfriend.alpha = lastAlpha;
							iconP1.changeIcon(boyfriend.healthIcon);
						}

						setOnLuas('boyfriendName', boyfriend.curCharacter);
					}
					case 1:
					{
						if (dad.curCharacter != value2)
						{
							if (!dadMap.exists(value2)) {
								addCharacterToList(value2, charType);
							}

							var wasGf:Bool = dad.curCharacter.startsWith('gf');

							var lastAlpha:Float = dad.alpha;
							dad.alpha = 0.00001;
							dad = dadMap.get(value2);

							if (!dad.curCharacter.startsWith('gf'))
							{
								if (wasGf && gf != null) {
									gf.visible = true;
								}
							}
							else if (gf != null) {
								gf.visible = false;
							}

							dad.alpha = lastAlpha;

							#if DISCORD_ALLOWED
							iconRPC = dad.char_name;
							#end

							iconP2.changeIcon(dad.healthIcon);
						}

						setOnLuas('dadName', dad.curCharacter);
					}
					case 2:
					{
						if (gf != null)
						{
							if (gf.curCharacter != value2)
							{
								if (!gfMap.exists(value2)) {
									addCharacterToList(value2, charType);
								}

								var lastAlpha:Float = gf.alpha;
								gf.alpha = 0.00001;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}

							setOnLuas('gfName', gf.curCharacter);
						}
					}
				}

				reloadHealthBarColors();
			}
			case 'BG Freaks Expression':
			{
				if (bgGirls != null) bgGirls.swapDanceType();
			}
			case 'Change Scroll Speed':
			{
				if (songSpeedType == 'constant') return;
		
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
	
				if (Math.isNaN(val1)) val1 = 1;
				if (Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * PlayStateChangeables.scrollSpeed * val1;

				if (val2 <= 0) {
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(instance, {songSpeed: newValue}, val2 / playbackRate,
					{
						ease: FlxEase.linear,
						onComplete: function(twn:FlxTween):Void {
							songSpeedTween = null;
						}
					});
				}
			}
			case 'Set Property':
			{
				var fieldArray:Array<String> = value1.split('.');

				if (fieldArray.length > 1) {
					FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(fieldArray, true, true), fieldArray[fieldArray.length - 1], value2);
				}
				else {
					FunkinLua.setVarInArray(instance, value1, value2);
				}
			}
			case 'Play Sound':
			{
				var soundPath:String = value1.trim();

				var volume:Float = Std.parseFloat(value2);
				if (Math.isNaN(volume)) volume = 1;

				if (soundPath != null || soundPath.length > 0) {
					FlxG.sound.play(Paths.getSound(soundPath), volume);
				}
			}
			case 'Fade Event':
			{
				var strColor:String = value2.startsWith('0x') ? value2 : ('0x' + value2);

				var color:FlxColor = Std.parseInt(strColor);
				FlxG.camera.fade(color, Std.parseFloat(value1), false);
			}
			case 'Flash Event':
			{
				var strColor:String = value2.startsWith('0x') ? value2 : ('0x' + value2);

				var color:FlxColor = Std.parseInt(strColor);
				FlxG.camera.flash(color, Std.parseFloat(value1), null, false);
			}
			case 'Object X Tween':
			{
				var array:Array<String> = value2.trim().split(',');

				for (i in 0...array.length) {
					array[i] = array[i].trim();
				}

				var tag:String = array[0];

				var object:Dynamic = FunkinLua.getTween(tag, value1);
				var array:Array<String> = value2.trim().split(',');

				var newValue:Float = Std.parseFloat(array[1]);
				if (Math.isNaN(newValue)) newValue = 100;

				var duration:Float = Std.parseFloat(array[2]);
				if (Math.isNaN(duration)) newValue = 1;

				var ease:String = array[2];

				if (object != null && (tag != null || tag.length > 0) && (ease != null || ease.length > 0))
				{
					modchartTweens.set(tag, FlxTween.tween(object, {x: newValue}, duration,
					{
						ease: FunkinLua.getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween):Void
						{
							callOnLuas('onTweenCompleted', [tag]);
							modchartTweens.remove(tag);
						}
					}));
				}
			}
			case 'Object Y Tween':
			{
				var array:Array<String> = value2.trim().split(',');

				for (i in 0...array.length) {
					array[i] = array[i].trim();
				}

				var tag:String = array[0];

				var object:Dynamic = FunkinLua.getTween(tag, value1);

				var newValue:Float = Std.parseFloat(array[1]);
				if (Math.isNaN(newValue)) newValue = 100;

				var duration:Float = Std.parseFloat(array[2]);
				if (Math.isNaN(duration)) newValue = 1;

				var ease:String = array[2];

				if (object != null && (tag != null || tag.length > 0) && (ease != null || ease.length > 0))
				{
					modchartTweens.set(tag, FlxTween.tween(object, {y: newValue}, duration,
					{
						ease: FunkinLua.getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween):Void
						{
							callOnLuas('onTweenCompleted', [tag]);
							modchartTweens.remove(tag);
						}
					}));
				}
			}
			case 'Object XY Tween':
			{
				var array:Array<String> = value2.trim().split(',');

				for (i in 0...array.length) {
					array[i] = array[i].trim();
				}

				var tag:String = array[0];

				var object:Dynamic = FunkinLua.getTween(tag, value1);

				var newValueX:Float = Std.parseFloat(array[1]);
				if (Math.isNaN(newValueX)) newValueX = 100;

				var newValueY:Float = Std.parseFloat(array[2]);
				if (Math.isNaN(newValueY)) newValueY = 100;

				var duration:Float = Std.parseFloat(array[3]);
				if (Math.isNaN(duration)) duration = 1;

				var ease:String = array[4];

				if (object != null && (tag != null || tag.length > 0) && (ease != null || ease.length > 0))
				{
					modchartTweens.set(tag, FlxTween.tween(object, {x: newValueX, y: newValueY}, duration,
					{
						ease: FunkinLua.getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween):Void
						{
							callOnLuas('onTweenCompleted', [tag]);
							modchartTweens.remove(tag);
						}
					}));
				}
			}
			case 'Object Angle Tween':
			{
				var array:Array<String> = value2.trim().split(',');

				for (i in 0...array.length) {
					array[i] = array[i].trim();
				}

				var tag:String = array[0];

				var object:Dynamic = FunkinLua.getTween(tag, value1);

				var newValue:Float = Std.parseFloat(array[1]);
				if (Math.isNaN(newValue)) newValue = 0;

				var duration:Float = Std.parseFloat(array[2]);
				if (Math.isNaN(duration)) newValue = 1;

				var ease:String = array[2];

				if (object != null && (tag != null || tag.length > 0) && (ease != null || ease.length > 0))
				{
					modchartTweens.set(tag, FlxTween.tween(object, {angle: newValue}, duration,
					{
						ease: FunkinLua.getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween):Void
						{
							callOnLuas('onTweenCompleted', [tag]);
							modchartTweens.remove(tag);
						}
					}));
				}
			}
			case 'Object Zoom Tween':
			{
				var array:Array<String> = value2.trim().split(',');

				for (i in 0...array.length) {
					array[i] = array[i].trim();
				}

				var tag:String = array[0];

				var object:Dynamic = FunkinLua.getTween(tag, value1);

				var newValue:Float = Std.parseFloat(array[1]);
				if (Math.isNaN(newValue)) newValue = 1;

				var duration:Float = Std.parseFloat(array[2]);
				if (Math.isNaN(duration)) newValue = 1;

				var ease:String = array[2];

				if (object != null && (tag != null || tag.length > 0) && (ease != null || ease.length > 0))
				{
					modchartTweens.set(tag, FlxTween.tween(object, {zoom: newValue}, duration,
					{
						ease: FunkinLua.getFlxEaseByString(ease),
						onComplete: function(twn:FlxTween):Void
						{
							callOnLuas('onTweenCompleted', [tag]);
							modchartTweens.remove(tag);
						}
					}));
				}
			}
			case 'Run Timer':
			{
				var tag:String = value1;

				if (tag != null || tag.length > 0)
				{
					FunkinLua.cancelTimer(tag);

					var timeAndLoops:Array<String> = value2.trim().split(',');
	
					for (i in 0...timeAndLoops.length) {
						timeAndLoops[i] = timeAndLoops[i].trim();
					}
	
					var time:Float = Std.parseFloat(timeAndLoops[0]);
					if (Math.isNaN(time)) time = 1;
	
					var loops:Int = Std.parseInt(timeAndLoops[1]);
					if (Math.isNaN(time)) loops = 1;
	
					modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer)
					{
						if (tmr.finished) {
							modchartTimers.remove(tag);
						}
		
						callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
					}, loops));
				}
			}
			case 'Object Play Animation':
			{
				var obj:String = value1;

				var array:Array<String> = value2.trim().split(',');

				for (i in 0...array.length) {
					array[i] = array[i].trim();
				}

				var name:String = array[0];

				var forced:Bool = array[1] == 'true';
				var reverse:Bool = array[2] == 'true';

				var startFrame:Int = Std.parseInt(array[3]);
				if (Math.isNaN(startFrame)) startFrame = 0;

				if (obj != null || obj.length > 0)
				{
					var luaObject:FlxSprite = getLuaObject(obj, false);

					if (luaObject != null)
					{
						var luaObj:FlxSprite = luaObject;
		
						if (luaObj.animation.getByName(name) != null)
						{
							luaObj.animation.play(name, forced, reverse, startFrame);
		
							if (Std.isOfType(luaObj, ModchartSprite))
							{
								var obj:Dynamic = luaObj;
								var luaObj:ModchartSprite = obj;
		
								var daOffset = luaObj.animOffsets.get(name);
		
								if (luaObj.animOffsets.exists(name)) {
									luaObj.offset.set(daOffset[0], daOffset[1]);
								}
							}
						}
					}
					else
					{
						var spr:FlxSprite = Reflect.getProperty(instance, obj);
		
						if (spr != null)
						{
							if (spr.animation.getByName(name) != null)
							{
								if (Std.isOfType(spr, Character))
								{
									var obj:Dynamic = spr;
									var spr:Character = obj;
			
									spr.playAnim(name, forced, reverse, startFrame);
								}
								else {
									spr.animation.play(name, forced, reverse, startFrame);
								}
							}
						}	
					}
				}
			}
			case 'Set Health Bar Colors':
			{
				if (value1 == null || value1.length < 1) {
					value1 = Std.string(FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]));
				}

				var left:FlxColor = Std.parseInt(value1);
				if (!value1.startsWith('0x')) left = Std.parseInt('0xff' + value1);

				if (value2 == null || value2.length < 1) {
					value2 = Std.string(FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2]));
				}
	
				var right:FlxColor = Std.parseInt(value2);
				if (!value2.startsWith('0x')) right = Std.parseInt('0xff' + value2);
	
				healthBar.createFilledBar(left, right);
				healthBar.updateBar();
			}
			case 'Set Music Volume':
			{
				if (FlxG.sound.music != null)
				{
					var newValue:Float = Std.parseFloat(value1);
					if (Math.isNaN(newValue)) newValue = 1;

					FlxG.sound.music.volume = newValue;
				}
			}
			case 'Set Vocals Volume':
			{
				if (vocals != null)
				{
					var newValue:Float = Std.parseFloat(value1);
					if (Math.isNaN(newValue)) newValue = 1;

					vocals.volume = newValue;
				}
			}
			case 'Change Icon':
			{
				var icon:HealthIcon = null;

				switch (value1.toLowerCase().trim())
				{
					case 'iconp2' | 'p2' | '2' | 'dad' | 'opponent':
						icon = iconP2;
					default:
						icon = iconP1;
				}
				
				icon.changeIcon(value2);
			}
			case 'Camera Tween Pos':
			{
				if (value1 != '' && value2 != '')
				{
					FunkinLua.cancelTween('CameraEventX');
					FunkinLua.cancelTween('CameraEventY');

					var xyAndDur:Array<String> = value1.trim().split(',');

					for (i in 0...xyAndDur.length) {
						xyAndDur[i] = xyAndDur[i].trim();
					}

					var newX:Float = Std.parseFloat(xyAndDur[0]);
					if (Math.isNaN(newX)) newX = 100;

					var newY:Float = Std.parseFloat(xyAndDur[1]);
					if (Math.isNaN(newY)) newY = 100;

					var duration:Float = Std.parseFloat(xyAndDur[2]);
					if (Math.isNaN(duration)) duration = 1;

					if (camFollow != null && camFollowPos != null)
					{
						modchartTweens.set('CameraEventX', FlxTween.tween(camFollowPos, {x: newX}, duration,
						{
							ease: FunkinLua.getFlxEaseByString(value2),
							onComplete: function(twn:FlxTween):Void
							{
								camFollow.x = newX;

								callOnLuas('onTweenCompleted', ['CameraEventX']);
								modchartTweens.remove('CameraEventX');
							}
						}));

						modchartTweens.set('CameraEventY', FlxTween.tween(camFollowPos, {y: newY}, duration,
						{
							ease: FunkinLua.getFlxEaseByString(value2),
							onComplete: function(twn:FlxTween):Void
							{
								camFollow.y = newY;

								callOnLuas('onTweenCompleted', ['CameraEventY']);
								modchartTweens.remove('CameraEventY');
							}
						}));

						isCameraOnForcedPos = true;
					}
				}
				else {
					isCameraOnForcedPos = false;
				}
			}
			case 'Camera Tween Zoom':
			{
				FunkinLua.cancelTween('ZoomEvent');

				var tarAndDur:Array<String> = value1.trim().split(',');

				for (i in 0...tarAndDur.length) {
					tarAndDur[i] = tarAndDur[i].trim();
				}

				var newValue:Float = Std.parseFloat(tarAndDur[0]);
				if (Math.isNaN(newValue)) newValue = 1;

				var duration:Float = Std.parseFloat(tarAndDur[1]);
				if (Math.isNaN(duration)) duration = 1;

				modchartTweens.set('ZoomEvent', FlxTween.tween(FlxG.camera, {zoom: newValue}, duration,
				{
					ease: FunkinLua.getFlxEaseByString(value2),
					onComplete: function(twn:FlxTween):Void
					{
						callOnLuas('onTweenCompleted', ['ZoomEvent']);
						modchartTweens.remove('ZoomEvent');
					}
				}));

				defaultCamZoom = newValue;
			}
			case 'Set Cam Zoom':
			{
				if (value1 != null || value1.length > 0)
				{
					var ourNewValue:Float = Std.parseFloat(value1);
					if (Math.isNaN(ourNewValue)) ourNewValue = 0.9;

					var duration:Float = Std.parseFloat(value2);
					if (Math.isNaN(duration)) duration = 1;

					defaultCamZoom = ourNewValue;

					modchartTweens.set('camz', FlxTween.tween(FlxG.camera, {zoom: ourNewValue}, duration,
					{
						ease: FlxEase.sineInOut,
						onComplete: function(twn:FlxTween):Void
						{
							defaultCamZoom = FlxG.camera.zoom;

							callOnLuas('onTweenCompleted', ['camz']);
							modchartTweens.remove('camz');
						}
					}));
				}
			}
			case 'Cam Boom Speed':
			{
				boomSpeed = Std.parseInt(value1);
				if (Math.isNaN(boomSpeed)) boomSpeed = 4;

				bamVal = Std.parseInt(value2);
				if (Math.isNaN(bamVal)) bamVal = 1;
			}
		}

		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	public var blockedCameraMovementOnStart:Bool = true;
	public var blockedCameraMovementOnEnd:Bool = false;

	var cameraTwn:FlxTween;

	public function cameraMovementSection():Void
	{
		if (SONG.notes[curSection] == null) return;

		if (gf != null && SONG.notes[curSection].gfSection)
		{
			cameraMovement('gf');
			callOnLuas('onMoveCamera', ['gf']);

			return;
		}

		if (!SONG.notes[curSection].mustHitSection)
		{
			cameraMovement('dad');
			callOnLuas('onMoveCamera', ['dad']);
		}
		else
		{
			cameraMovement('boyfriend');
			callOnLuas('onMoveCamera', ['boyfriend']);
		}
	}

	public function cameraMovement(moveCameraTo:Dynamic):Void
	{
		if (moveCameraTo == 'dad' || moveCameraTo == true)
		{
			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];

			tweenCamIn();
		}
		else if (moveCameraTo == 'boyfriend' || moveCameraTo == false)
		{
			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (SONG.songID == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000),
				{
					ease: FlxEase.elasticInOut,
					onComplete: function(twn:FlxTween)
					{
						cameraTwn = null;
					}
				});
			}
		}
		else
		{
			camFollow.set(gf.getMidpoint().x, gf.getMidpoint().y);
			camFollow.x += gf.cameraPosition[0] + girlfriendCameraOffset[0];
			camFollow.y += gf.cameraPosition[1] + girlfriendCameraOffset[1];

			tweenCamIn();
		}
	}

	public function tweenCamIn():Void
	{
		if (SONG.songID == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1.3)
		{
			cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1.3}, (Conductor.stepCrochet * 4 / 1000),
			{
				ease: FlxEase.elasticInOut,
				onComplete: function(twn:FlxTween):Void {
					cameraTwn = null;
				}
			});
		}
	}

	public var endingSong:Bool = false;
	public var finishTimer:FlxTimer = null;

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong;

		endingSong = true;
		updateTime = false;

		camZooming = false;
		camHUDZooming = false;

		iconsZooming = false;

		#if WEBM_ALLOWED
		endBGVideo();
		#end

		FlxG.sound.music.pause();
		FlxG.sound.music.volume = 0;

		vocals.pause();
		vocals.volume = 0;

		if (OptionData.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		}
		else
		{
			finishTimer = new FlxTimer().start(OptionData.noteOffset / 1000, function(tmr:FlxTimer):Void {
				finishCallback();
			});
		}
	}

	public var transitioning:Bool = false;

	public function endSong():Void
	{
		inCutscene = false;

		if (gameMode != 'replay') {
			rep.saveReplay(saveNotes);
		}

		blockedCameraMovementOnEnd = true;

		endingSong = true;
		updateTime = false;

		camZooming = false;
		camHUDZooming = false;

		iconsZooming = false;

		songPosBar.visible = false;
		songPosName.visible = false;

		canPause = false;
		canReset = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if (achievementObj != null) {
			return;
		}
		else
		{
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'week7_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);
			var customAchieve:String = checkForAchievement(achievementWeeks);

			if (achieve != null || customAchieve != null)
			{
				startAchievement(customAchieve != null ? customAchieve : achieve);
				return;
			}
		}
		#end

		prevCamFollow = null;
		prevCamFollowPos = null;

		allowPlayCutscene = ((gameMode == 'story' && OptionData.cutscenesInType.contains('Story'))
			|| (gameMode == 'freeplay' && OptionData.cutscenesInType.contains('Freeplay'))
			|| (gameMode == 'replay' && OptionData.cutscenesInType.contains('Replay'))
			|| OptionData.cutscenesInType == 'Everywhere') && !seenCutscene;

		var ret:Dynamic = callOnLuas('onEndSong', [allowPlayCutscene], false);

		if (ret != FunkinLua.Function_Stop && !transitioning)
		{
			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			var difficultySuffix:String = CoolUtil.getDifficultySuffix(storyDifficultyID);

			if (!usedPractice && gameMode != 'replay')
			{
				#if !switch
				Highscore.saveScore(CoolUtil.formatSong(SONG.songID, storyDifficultyID), songScore, (Math.isNaN(songAccuracy) ? 0 : songAccuracy));
				#end
			}

			switch (gameMode)
			{
				case 'story':
				{
					if (!usedPractice)
					{
						campaignScore += songScore;
						campaignMisses += songMisses;
						campaignAccuracy += songAccuracy;
						campaignAccuracy /= weekLength;
					}

					storyPlaylist.remove(storyPlaylist[0]);

					var ourPath:String = 'data/' + PlayState.storyPlaylist[0] + '/' + PlayState.storyPlaylist[0] + difficultySuffix + '.json';
					var noExistsPoop:Bool = !Paths.fileExists(ourPath, TEXT);
		
					if (storyPlaylist.length <= 0 || noExistsPoop)
					{
						if (noExistsPoop) {
							Debug.logError('File "' + ourPath + '" does not exist! Going to Story Menu...');
						}
						else {
							Debug.logInfo('Finished week "' + storyWeekName + '".');
						}

						cancelMusicFadeTween();

						Transition.nextCamera = camOther;

						if (Transition.skipNextTransIn) {
							Transition.nextCamera = null;
						}

						if (!usedPractice)
						{
							Highscore.saveWeekScore(CoolUtil.formatSong(storyWeekText, storyDifficultyID), campaignScore);
							WeekData.weekCompleted.set(storyWeekText, true);

							FlxG.save.data.weekCompleted = WeekData.weekCompleted;
							FlxG.save.flush();
						}

						usedPractice = false;
						WeekData.loadTheFirstEnabledMod();
					}
					else
					{
						Transition.skipNextTransIn = true;
						Transition.skipNextTransOut = true;

						usedPractice = cpuControlled;

						switch (SONG.songID)
						{
							case 'eggnog':
							{
								var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom, -FlxG.height * FlxG.camera.zoom);
								blackShit.makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
								blackShit.scrollFactor.set();
								add(blackShit);

								FlxG.sound.play(Paths.getSound('Lights_Shut_off'), 1, false, null, true, function():Void {
									nextSong(difficultySuffix);
								});

								camHUD.visible = false;
							}
							default:
							{
								prevCamFollow = camFollow;
								prevCamFollowPos = camFollowPos;

								nextSong(difficultySuffix);
							}
						}

						callOnLuas('onEndSongPost', [allowPlayCutscene], false);
						return;
					}
				}
				#if sys
				case 'replay':
				{
					cancelMusicFadeTween();

					Transition.nextCamera = camOther;

					if (Transition.skipNextTransIn) {
						Transition.nextCamera = null;
					}

					Replay.resetVariables();
					WeekData.loadTheFirstEnabledMod();
				}
				#end
				default:
				{
					usedPractice = false;
					cancelMusicFadeTween();

					Transition.nextCamera = camOther;

					if (Transition.skipNextTransIn) {
						Transition.nextCamera = null;
					}

					WeekData.loadTheFirstEnabledMod();
				}
			}

			var ret:Dynamic = callOnLuas('onEndSongPost', [allowPlayCutscene], false);

			if (ret != FunkinLua.Function_Stop) {
				goToState(gameMode);
			}
		}
	}

	public function nextSong(difficultySuffix:String):Void
	{
		var ourPath:String = Paths.formatToSongPath(storyPlaylist[0].toLowerCase() + difficultySuffix);
		Debug.logInfo('Loading next story song "' + ourPath + '"...');

		cancelMusicFadeTween();

		SONG = Song.loadFromJson(ourPath, Paths.formatToSongPath(storyPlaylist[0]));
		LoadingState.loadAndSwitchState(new PlayState(), true);
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;

	function startAchievement(achieve:String):Void
	{
		achievementObj = new AchievementObject(achieve, camOther);
		achievementObj.onFinish = achievementEnd;
		add(achievementObj);
	}

	function achievementEnd():Void
	{
		achievementObj = null;

		if (endingSong && !inCutscene) {
			endSong();
		}
	}
	#end

	public function goToState(gameMode:String):Void
	{
		if (!transitioning)
		{
			switch (gameMode)
			{
				case 'story': FlxG.switchState(new StoryMenuState());
				case 'freeplay': FlxG.switchState(new FreeplayMenuState());
				case 'replay': FlxG.switchState(new options.ReplaysMenuState());
				default: FlxG.switchState(new MainMenuState());
			}

			transitioning = true;
		}
	}

	public function KillNotes():Void
	{
		while (notes.length > 0)
		{
			var daNote:Note = notes.members[0];

			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}

		unspawnNotes = [];
		eventNotes = [];
	}

	public var ratingSuffix:String = '';
	public var numberSuffix:String = '';

	private function cachePopUpScore():Void
	{
		if (isPixelStage)
		{
			ratingSuffix = '-pixel';
			numberSuffix = '-pixel';
		}

		var pathsRatingShit:Array<String> =
		[
			'',
			'pixelUI',
			'ratings/'
		];

		var ratingShit:Array<String> =
		[
			'sick',
			'good',
			'bad',
			'shit',
			'combo'
		];

		for (sus in pathsRatingShit)
		{
			for (rat in ratingShit)
			{
				if (Paths.fileExists('images/' + sus + rat + ratingSuffix + '.png', IMAGE)) {
					Paths.getImage(sus + rat + ratingSuffix);
				}
			}
		}

		var pathsNumberShit:Array<String> =
		[
			'',
			'pixelUI',
			'numbers/'
		];
		
		for (i in 0...10)
		{
			for (sus in pathsNumberShit)
			{
				if (Paths.fileExists('images/' + sus + 'num' + i + numberSuffix + '.png', IMAGE)) {
					Paths.getImage(sus + 'num' + i + numberSuffix);
				}
			}
		}
	}

	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	public var showRating:Bool = true;

	private function popUpScore(daNote:Note):Void
	{
		var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition + OptionData.ratingOffset);
		var placement:String = Std.string(combo);

		var coolText:FlxText = new FlxText(0, 0, 0, placement, 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;

		vocals.volume = 1;

		var daRating:RatingData = Conductor.judgeNote(daNote, noteDiff / playbackRate);

		if (daRating.noteSplash && !daNote.noteSplashDisabled && !daNote.quickNoteSplash && !daNote.isSustainNote) {
			spawnNoteSplashOnNote(daNote);
		}

		daNote.rating = daRating.name;

		if (!daNote.healthDisabled)
		{
			if (!daNote.isSustainNote)
			{
				if (Reflect.field(daNote, 'hithealth_' + daRating.name) != null) {
					health += Reflect.field(daNote, 'hithealth_' + daRating.name) * healthGain;
				}
			}
			else
			{
				var curRatingFromParent:String = daNote.parent.rating == 'unknown' ? 'shit' : daNote.parent.rating;

				if (Reflect.field(daNote, 'hithealth_' + curRatingFromParent + '_sus') != null) {
					health += Reflect.field(daNote, 'hithealth_' + curRatingFromParent + '_sus') * healthGain;
				}
			}
		}

		if (!practiceMode && !cpuControlled)
		{
			if (daNote.isSustainNote)
			{
				var curRatingFromParent:String = daNote.parent.rating == 'unknown' ? 'shit' : daNote.parent.rating;
				var daRatingSus:RatingData = getRatingByName(curRatingFromParent);

				songScore += Math.round(daRatingSus.score / 2);
				totalNotesHit += FlxG.random.float(daRatingSus.ratingMod - 0.50, daRatingSus.ratingMod - 0.25);
			}
			else
			{
				songScore += daRating.score;
				totalNotesHit += FlxG.random.float(daRating.ratingMod - 0.25, daRating.ratingMod);

				if (!daNote.ratingDisabled) {
					daRating.increase();
				}

				songHits++;
				totalPlayed++;
			}
		}

		if (!daNote.isSustainNote)
		{
			combo += 1;

			var rating:Rating = new Rating(daRating.image, ratingSuffix, coolText);

			if (showRating) {
				grpRatings.add(rating);
			}

			var comboSpr:FlxSprite = new FlxSprite();

			if (Paths.fileExists('images/combo' + ratingSuffix + '.png', IMAGE)) {
				comboSpr.loadGraphic(Paths.getImage('combo' + ratingSuffix));
			}
			else if (Paths.fileExists('pixelUI/combo' + ratingSuffix + '.png', IMAGE)) {
				comboSpr.loadGraphic(Paths.getImage('pixelUI/combo' + ratingSuffix));
			}
			else {
				comboSpr.loadGraphic(Paths.getImage('ratings/combo' + ratingSuffix));
			}

			comboSpr.cameras = [camHUD];
			comboSpr.screenCenter();
			comboSpr.x = coolText.x;
			comboSpr.acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
			comboSpr.velocity.y -= FlxG.random.int(140, 160) * playbackRate;
			comboSpr.visible = (!OptionData.showRatings && showCombo);
			comboSpr.x += OptionData.comboOffset[0];
			comboSpr.y -= OptionData.comboOffset[1];
			comboSpr.y += 60;
			comboSpr.velocity.x += FlxG.random.int(1, 10) * playbackRate;

			if (!OptionData.comboStacking)
			{
				if (lastCombo != null) lastCombo.kill();
				lastCombo = comboSpr;
			}

			if (showCombo) {
				insert(members.indexOf(strumLineNotes), comboSpr);
			}

			if (!OptionData.comboStacking)
			{
				if (lastRating != null) lastRating.kill();
				lastRating = rating;
			}

			if (lastScore != null)
			{
				while (lastScore.length > 0)
				{
					lastScore[0].kill();
					lastScore.remove(lastScore[0]);
				}
			}

			var seperatedScore:Array<Int> = [];

			seperatedScore.push(Math.floor(combo / 100));
			seperatedScore.push(Math.floor((combo - (seperatedScore[0] * 100)) / 10));
			seperatedScore.push(combo % 10);

			var daLoop:Int = 0;

			for (i in seperatedScore)
			{
				var numScore:Number = new Number(Std.int(i), numberSuffix, coolText, daLoop);

				if (showComboNum) {
					grpNumbers.add(numScore);
				}

				if (!OptionData.comboStacking) {
					lastScore.push(numScore);
				}

				var numtwn:FlxTween = FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate,
				{
					startDelay: Conductor.crochet * 0.002 / playbackRate,
					onComplete: function(tween:FlxTween):Void
					{
						numbersTweensArray.remove(tween);

						numScore.kill();
						grpNumbers.remove(numScore, true);
						numScore.destroy();
					}
				});

				numbersTweensArray.push(numtwn);
				daLoop++;
			}

			coolText.text = Std.string(seperatedScore);

			var rttwn:FlxTween = FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate,
			{
				startDelay: Conductor.crochet * 0.001 / playbackRate,
				onComplete: function(tween:FlxTween):Void
				{
					coolText.destroy();

					ratingTweensArray.remove(tween);

					rating.kill();
					grpRatings.remove(rating, true);
					rating.destroy();
				}
			});

			ratingTweensArray.push(rttwn);

			var cmbtwn:FlxTween = FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate,
			{
				startDelay: Conductor.crochet * 0.002 / playbackRate,
				onComplete: function(tween:FlxTween):Void
				{
					ratingTweensArray.remove(tween);
					comboSpr.destroy();
				}
			});

			ratingTweensArray.push(cmbtwn);
		}

		if (!practiceMode && !cpuControlled) {
			recalculateRating();
		}
	}

	public var strumsBlocked:Array<Bool> = [];

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (!cpuControlled && !startingSong && startedCountdown && !paused && key > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || OptionData.controllerMode))
		{
			if (!boyfriend.stunned && generatedMusic && !endingSong)
			{
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var pressNotes:Array<Note> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];

				notes.forEachAlive(function(daNote:Note):Void
				{
					if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && daNote.noteData == key && !daNote.blockHit) {
						sortedNotesList.push(daNote);
					}
				});

				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0)
				{
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) 
						{
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
							{
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							}
							else {
								notesStopped = true;
							}
						}

						if (!notesStopped) // eee jack detection before was not super good
						{
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				}
				else
				{
					callOnLuas('onGhostTap', [key]);

					if (OptionData.ghostTapping == false) {
						noteMissPress(key);
					}
				}

				keysPressed[key] = true;

				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[key];

			if (strumsBlocked[key] != true && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}

			callOnLuas('onKeyPress', [key]);
		}
	}

	public function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority) return 1;
		else if (!a.lowPriority && b.lowPriority) return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);

		if (!startingSong && !cpuControlled && startedCountdown && !paused && key > -1)
		{
			var spr:StrumNote = playerStrums.members[key];

			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}

			callOnLuas('onKeyRelease', [key]);
		}
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j]) {
						return i;
					}
				}
			}
		}

		return -1;
	}

	private function keyShit():Void
	{
		var parsedHoldArray:Array<Bool> = parseKeys();

		if (OptionData.controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
	
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] && strumsBlocked[i] != true) {
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
					}
				}
			}
		}

		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note):Void
			{
				if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit
					&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) { // hold note functions
					goodNoteHit(daNote);
				}
			});

			if (parsedHoldArray.contains(true) && !endingSong)
			{
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);

				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}
		}

		if (OptionData.controllerMode || strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys('_R');

			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] || strumsBlocked[i] == true) {
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
					}
				}
			}
		}
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];

		for (i in 0...controlArray.length) {
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		}

		return ret;
	}

	public function noteMissPress(direction:Int = 1):Void
	{
		FlxG.sound.play(Paths.getSoundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		if (!boyfriend.stunned)
		{
			health -= 0.05 * healthLoss;

			if (!practiceMode && !cpuControlled)
			{
				if (!endingSong) {
					songMisses++;
				}

				totalPlayed++;
				songScore -= 10;
			}

			if (combo > 5 && gf != null && gf.animOffsets.exists('sad')) {
				gf.playAnim('sad');
			}

			combo = 0;

			if (boyfriend.hasMissAnimations) {
				boyfriend.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
			}

			vocals.volume = 0;

			if (instakillOnMiss)
			{
				vocals.volume = 0;
				doDeathCheck(true);
			}
		}

		if (!practiceMode && !cpuControlled) {
			recalculateRating();
		}

		callOnLuas('noteMissPress', [direction]);
	}

	public function noteMiss(daNote:Note):Void
	{
		FlxG.sound.play(Paths.getSoundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		notes.forEachAlive(function(note:Note):Void
		{
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 10)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		health -= daNote.missHealth * healthLoss; // For testing purposes

		if (!practiceMode && !cpuControlled)
		{
			songScore -= 10;
			songMisses++;
			totalPlayed++;
		}

		if (combo > 5 && gf != null && gf.animOffsets.exists('sad')) {
			gf.playAnim('sad');
		}

		combo = 0;

		vocals.volume = 0;

		if (instakillOnMiss) {
			doDeathCheck(true);
		}

		if (!practiceMode && !cpuControlled) {
			recalculateRating();
		}

		var char:Character = boyfriend;

		if (daNote.gfNote) {
			char = gf;
		}

		if (char != null && !daNote.noMissAnimation && char.hasMissAnimations)
		{
			var animToPlay:String = singAnimations[daNote.noteData] + 'miss' + daNote.animSuffix;
			char.playAnim(animToPlay, true);
		}

		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote]);
	}

	public function opponentNoteHit(daNote:Note):Void
	{
		if (SONG.songID != 'tutorial')
		{
			camZooming = true;
			camHUDZooming = true;
		}

		if (daNote.noteType == 'Hey!' && dad.animOffsets.exists('hey'))
		{
			dad.playAnim('hey', true);
			dad.specialAnim = true;
			dad.heyTimer = 0.6;
		}
		else if (!daNote.noAnimation)
		{
			var altAnim:String = daNote.animSuffix;

			if (SONG.notes[curSection] != null)
			{
				if (SONG.notes[curSection].altAnim && !SONG.notes[curSection].gfSection) {
					altAnim = '-alt';
				}
			}

			var char:Character = dad;
			var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + altAnim;

			if (daNote.gfNote == true) {
				char = gf;
			}

			if (char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		if (OptionData.opponentStrumsType == 'Glow' || (OptionData.opponentStrumsType == 'Glow no Sustains' && !daNote.isSustainNote) || (OptionData.opponentStrumsType == 'Glow, while Sus' && daNote.isSustainNote))
		{
			var time:Float = 0.15;

			if (daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end')) {
				time += 0.15;
			}
	
			StrumPlayAnim(true, Std.int(Math.abs(daNote.noteData)), time / playbackRate);
		}

		if (daNote.noteSplashHitByOpponent && !daNote.noteSplashDisabled && !daNote.isSustainNote) {
			spawnNoteSplashOnNote(daNote);
		}

		if (SONG.needsVoices == true) {
			vocals.volume = 1;
		}

		daNote.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(daNote), Math.abs(daNote.noteData), daNote.noteType, daNote.isSustainNote]);

		if (OptionData.sustainsType == 'Old' || !daNote.isSustainNote)
		{
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
	}

	public function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (cpuControlled && (note.ignoreNote || note.hitCausesMiss)) return;

			if (OptionData.hitsoundVolume > 0 && OptionData.hitsoundType != '' && !note.hitsoundDisabled)
			{
				if (OptionData.hitsoundType == 'Kade') {
					FlxG.sound.play(Paths.getSound('SNAP'), OptionData.hitsoundVolume);
				}
				else if (OptionData.hitsoundType == 'Psych') {
					FlxG.sound.play(Paths.getSound('hitsound'), OptionData.hitsoundVolume);
				}
			}

			if (!note.noAnimation)
			{
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				if (note.gfNote)
				{
					if (gf != null)
					{
						gf.playAnim(animToPlay + note.animSuffix, true);
						gf.holdTimer = 0;
					}
				}
				else
				{
					boyfriend.playAnim(animToPlay + note.animSuffix, true);
					boyfriend.holdTimer = 0;
				}

				if (note.noteType == 'Hey!')
				{
					if (boyfriend.animOffsets.exists('hey'))
					{
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if (gf != null && gf.animOffsets.exists('cheer'))
					{
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = 0.6;
					}
				}
			}

			if (note.hitCausesMiss)
			{
				noteMiss(note);

				if (!note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				if (!note.noMissAnimation)
				{
					switch (note.noteType)
					{
						case 'Hurt Note': // Hurt note
						{
							if (boyfriend.animation.getByName('hurt') != null)
							{
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
						}
					}
				}

				note.wasGoodHit = true;

				if (OptionData.sustainsType == 'Old' || !note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}

				var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
				var leData:Int = Math.round(Math.abs(note.noteData));
				var leType:String = note.noteType;

				callOnLuas('onHitCauses', [notes.members.indexOf(note), leData, leType, isSus]);
				return;
			}

			if (note.quickNoteSplash) {
				spawnNoteSplashOnNote(note);
			}

			if (!note.ignoreNote)
			{
				popUpScore(note);
	
				if (!note.isSustainNote) {
					if (combo > 9999) combo = 9999;
				}
				else {
					totalNotesHit += 0.075;
				}
			}

			if (cpuControlled)
			{
				var time:Float = 0.15;

				if (note.isSustainNote && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}

				StrumPlayAnim(false, Std.int(Math.abs(note.noteData)) % 4, time);
			}
			else
			{
				playerStrums.forEach(function(spr:StrumNote):Void
				{
					if (Math.abs(note.noteData) == spr.ID) {
						spr.playAnim('confirm', true);
					}
				});
			}

			if (gameMode != 'replay' && note.mustPress) {
				saveNotes.push(CoolUtil.floorDecimal(note.strumTime, 2));
			}

			note.wasGoodHit = true;
			vocals.volume = 1;

			var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;

			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (OptionData.sustainsType == 'Old' || !note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}

		if (!practiceMode && !cpuControlled) {
			recalculateRating();
		}
	}

	public function spawnNoteSplashOnNote(note:Note):Void
	{
		if (OptionData.splashOpacity > 0 && note != null)
		{
			var strum:StrumNote = null;

			if (!note.noteSplashHitByOpponent)
				strum = playerStrums.members[note.noteData];
			else
				strum = opponentStrums.members[note.noteData];

			if (strum != null) {
				spawnNoteSplash(strum.x, strum.y, note.noteData, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, ?note:Note = null):Void
	{
		var skin:String = 'noteSplashes';

		if (note.mustPress)
		{
			if (SONG.splashSkin != null && SONG.splashSkin.length > 0) {
				skin = SONG.splashSkin;
			}
		}
		else
		{
			if (SONG.splashSkin2 != null && SONG.splashSkin2.length > 0) {
				skin = SONG.splashSkin2;
			}
		}

		var hue:Float = OptionData.arrowHSV[data % 4][0] / 360;
		var sat:Float = OptionData.arrowHSV[data % 4][1] / 100;
		var brt:Float = OptionData.arrowHSV[data % 4][2] / 100;

		if (data > -1 && data < OptionData.arrowHSV.length)
		{
			hue = OptionData.arrowHSV[data][0] / 360;
			sat = OptionData.arrowHSV[data][1] / 100;
			brt = OptionData.arrowHSV[data][2] / 100;

			if (note != null)
			{
				skin = note.noteSplashTexture;

				hue = note.noteSplashHue;
				sat = note.noteSplashSat;
				brt = note.noteSplashBrt;
			}
		}

		var splash:NoteSplash = grpNoteSplashes.recycle(NoteSplash);
		splash.setupNoteSplash(x, y, data, skin, note.mustPress, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	public function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.getSoundRandom('thunder_', 1, 2));
		if (OptionData.lowQuality == false) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (boyfriend.animOffsets.exists('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if (gf != null && gf.animOffsets.exists('scared')) {
			gf.playAnim('scared', true);
		}

		if (OptionData.camZooms)
		{
			FlxG.camera.zoom += 0.015;
			camHUD.zoom += 0.03;

			if (!camZooming) // Just a way for preventing it to be permanently zoomed until Skid & Pump hits a note
			{
				FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, 0.5);
				FlxTween.tween(camHUD, {zoom: 1}, 0.5);
			}
		}

		if (OptionData.flashingLights)
		{
			halloweenWhite.alpha = 0.4;

			FlxTween.tween(halloweenWhite, {alpha: 0.5}, 0.075);
			FlxTween.tween(halloweenWhite, {alpha: 0}, 0.25, {startDelay: 0.15});
		}
	}

	var trainMoving:Bool = false;
	var trainFrameTiming:Float = 0;

	var trainCars:Int = 8;
	var trainFinishing:Bool = false;
	var trainCooldown:Int = 0;

	public function trainStart():Void
	{
		trainMoving = true;

		if (!trainSound.playing) {
			trainSound.play(true);
		}
	}

	var startedMoving:Bool = false;

	public function updateTrainPos():Void
	{
		if (trainSound.time >= 4700)
		{
			startedMoving = true;

			if (gf != null) {
				gf.playAnim('hairBlow');
			}
		}

		if (startedMoving)
		{
			phillyTrain.x -= 400;

			if (phillyTrain.x < -2000 && !trainFinishing)
			{
				phillyTrain.x = -1150;
				trainCars--;

				if (trainCars <= 0) {
					trainFinishing = true;
				}
			}

			if (phillyTrain.x < -4000 && trainFinishing) {
				trainReset();
			}
		}
	}

	public function trainReset():Void
	{
		if (gf != null) {
			gf.playAnim('hairFall');
		}

		phillyTrain.x = FlxG.width + 200;
		trainMoving = false;

		trainCars = 8;

		trainFinishing = false;
		startedMoving = false;
	}

	var fastCarCanDrive:Bool = true;

	public function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	public function killHenchmen():Void
	{
		if (!OptionData.lowQuality && SONG.stage == 'limo')
		{
			if (limoKillingState < 1)
			{
				limoMetalPole.x = -400;
				limoMetalPole.visible = true;
				limoLight.visible = true;
				limoCorpse.visible = false;
				limoCorpseTwo.visible = false;
				limoKillingState = 1;

				#if ACHIEVEMENTS_ALLOWED
				Achievements.henchmenDeath++;
				FlxG.save.data.henchmenDeath = Achievements.henchmenDeath;

				var achieve:String = checkForAchievement(['roadkill_enthusiast']);

				if (achieve != null) {
					startAchievement(achieve);
				}
				else {
					FlxG.save.flush();
				}

				Debug.logInfo('Deaths: ' + Achievements.henchmenDeath);
				#end
			}
		}
	}

	var carTimer:FlxTimer;

	public function fastCarDrive():Void
	{
		carPassSound = FlxG.sound.play(Paths.getSoundRandom('carPass', 0, 1), 0.7);

		fastCar.velocity.x = (FlxG.random.int(170, 220) / FlxG.elapsed) * 3;
		fastCarCanDrive = false;

		carTimer = new FlxTimer().start(2, function(tmr:FlxTimer):Void
		{
			resetFastCar();
			carTimer = null;
		});
	}

	public function resetLimoKill():Void
	{
		if (SONG.stage == 'limo')
		{
			limoMetalPole.x = -500;
			limoMetalPole.visible = false;
			limoLight.x = -500;
			limoLight.visible = false;
			limoCorpse.x = -500;
			limoCorpse.visible = false;
			limoCorpseTwo.x = -500;
			limoCorpseTwo.visible = false;
		}
	}

	var tankX:Float = 400;
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankAngle:Float = FlxG.random.int(-90, 45);

	public function moveTank(?elapsed:Float = 0):Void
	{
		if (!inCutscene)
		{
			tankAngle += elapsed * tankSpeed;
			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + 1500 * Math.cos(Math.PI / 180 * (1 * tankAngle + 180));
			tankGround.y = 1300 + 1100 * Math.sin(Math.PI / 180 * (1 * tankAngle + 180));
		}
	}

	public function backgroundVideo(source:String):Void // for background videos
	{
		#if WEBM_ALLOWED
		useVideo = true;

		webmHandler = new WebmHandler();
		webmHandler.source(Paths.getWebm("DO NOT DELETE OR GAME WILL CRASH/dontDelete"));
		webmHandler.makePlayer();
		webmHandler.webm.name = "WEBM SHIT";

		BackgroundVideo.setWebm(webmHandler);
		var ourVideo:Dynamic = BackgroundVideo.get();

		ourVideo.source(Paths.getWebm(source));
		ourVideo.clearPause();

		if (BackgroundVideo.isWebm) {
			ourVideo.updatePlayer();
		}

		ourVideo.show();

		if (BackgroundVideo.isWebm) {
			ourVideo.restart();
		}
		else {
			ourVideo.play();
		}

		var data = webmHandler.webm.bitmapData;

		videoSprite = new FlxSprite(0, 0);
		videoSprite.loadGraphic(data);
		videoSprite.scrollFactor.set();
		videoSprite.cameras = [camHUD];
		add(videoSprite);

		if (startingSong)
			webmHandler.pause();
		else
			webmHandler.resume();
		#end
	}

	public function makeBackgroundTheVideo(source:String, with:Dynamic):Void // for background videos
	{
		#if WEBM_ALLOWED
		useVideo = true;

		webmHandler = new WebmHandler();
		webmHandler.source(Paths.getWebm("DO NOT DELETE OR GAME WILL CRASH/dontDelete"));
		webmHandler.makePlayer();
		webmHandler.webm.name = "WEBM SHIT";

		BackgroundVideo.setWebm(webmHandler);
		var ourVideo:Dynamic = BackgroundVideo.get();

		ourVideo.source(Paths.getWebm(source));
		ourVideo.clearPause();

		if (BackgroundVideo.isWebm) {
			ourVideo.updatePlayer();
		}

		ourVideo.show();

		if (BackgroundVideo.isWebm) {
			ourVideo.restart();
		}
		else {
			ourVideo.play();
		}

		var data = webmHandler.webm.bitmapData;

		videoSprite = new FlxSprite(0, 0);
		videoSprite.loadGraphic(data);
		videoSprite.setGraphicSize(Std.int(videoSprite.width * 1.4));
		videoSprite.scrollFactor.set();

		switch (with)
		{
			case 'before' | 'in front of' | 'afore' | 'ere' | 'front' | 'head' | true | 'true':
				add(videoSprite);
			case 'dad' | 'opponent':
				addBehindDad(videoSprite);
			case 'bf' | 'boyfriend':
				addBehindBF(videoSprite);
			default:
				addBehindGF(videoSprite);
		}

		if (startingSong)
			webmHandler.pause();
		else
			webmHandler.resume();
		#end
	}

	public function endBGVideo():Void
	{
		#if WEBM_ALLOWED
		var video:Dynamic = BackgroundVideo.get();

		if (useVideo && video != null)
		{
			video.stop();
			remove(videoSprite);
		}
		#end
	}

	var lastStepHit:Int = -1;

	public override function stepHit():Void
	{
		super.stepHit();

		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate) || (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate))) {
			resyncVocals();
		}

		if (curStep == lastStepHit) {
			return;
		}

		lastStepHit = curStep;

		setOnLuas('curStep', curStep);
		callOnLuas('onStepHit', []);
	}

	var lastBeatHit:Int = -1;

	public override function beatHit():Void
	{
		super.beatHit();

		if (lastBeatHit >= curBeat) {
			return;
		}

		if (generatedMusic) {
			notes.sort(FlxSort.byY, OptionData.downScroll == true ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}

		if (OptionData.iconZooms && iconsZooming)
		{
			iconP1.scale.set(1.2, 1.2);
			iconP2.scale.set(1.2, 1.2);
	
			iconP1.updateHitbox();
			iconP2.updateHitbox();
		}

		if (gf != null && curBeat % Math.round(gfSpeed * gf.danceEveryNumBeats) == 0 && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
		{
			gf.dance();
		}

		if (curBeat % boyfriend.danceEveryNumBeats == 0 && boyfriend.animation.curAnim != null && !boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.stunned)
		{
			boyfriend.dance();
		}

		if (curBeat % dad.danceEveryNumBeats == 0 && dad.animation.curAnim != null && !dad.animation.curAnim.name.startsWith('sing') && !dad.stunned)
		{
			dad.dance();
		}

		switch (SONG.stage)
		{
			case 'spooky':
			{
				if (FlxG.random.bool(10) && curBeat > lightningStrikeBeat + lightningOffset) {
					lightningStrikeShit();
				}
			}
			case 'philly':
			{
				if (!trainMoving) {
					trainCooldown++;
				}

				if (curBeat % 4 == 0)
				{
					curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);

					phillyWindow.color = phillyLightsColors[curLight];
					phillyWindow.alpha = 1;
				}

				if (curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
				{
					trainCooldown = FlxG.random.int(-4, 0);
					trainStart();
				}
			}
			case 'limo':
			{
				if (grpLimoDancers != null)
				{
					grpLimoDancers.forEach(function(dancer:BackgroundDancer):Void {
						dancer.dance();
					});
				}

				if (FlxG.random.bool(10) && fastCarCanDrive) {
					fastCarDrive();
				}
			}
			case 'mall':
			{
				if (OptionData.lowQuality == false) {
					upperBoppers.dance(true);
				}

				if (heyTimer <= 0) bottomBoppers.dance(true);
				santa.dance(true);
			}
			case 'school':
			{
				if (bgGirls != null) bgGirls.dance();
			}
			case 'tank':
			{
				if (OptionData.lowQuality == false) tankWatchtower.dance();

				foregroundSprites.forEach(function(spr:BGSprite):Void {
					spr.dance();
				});
			}
		}

		if (boomSpeed != 4 && curBeat % boomSpeed == 0) {
			triggerEventNote("Add Camera Zoom", Std.string(0.015 * bamVal), Std.string(0.03 * bamVal));
		}

		lastBeatHit = curBeat;

		setOnLuas('curBeat', curBeat); // DAWGG?????
		callOnLuas('onBeatHit', []);
	}

	public override function sectionHit():Void
	{
		super.sectionHit();

		if (SONG.notes[curSection] != null)
		{
			if (!blockedCameraMovementOnStart && !blockedCameraMovementOnEnd && !inCutscene && !isCameraOnForcedPos) {
				cameraMovementSection();
			}

			if (OptionData.camZooms && FlxG.camera.zoom < 1.35)
			{
				if (camZooming) {
					FlxG.camera.zoom += 0.015 * camZoomingMult;
				}
	
				if (camHUDZooming) {
					camHUD.zoom += 0.03 * camHUDZoomingMult;
				}
			}

			if (SONG.notes[curSection].changeBPM)
			{
				Conductor.changeBPM(SONG.notes[curSection].bpm);

				setOnLuas('curBpm', Conductor.bpm);
				setOnLuas('crochet', Conductor.crochet);
				setOnLuas('stepCrochet', Conductor.stepCrochet);
			}

			setOnLuas('mustHitSection', SONG.notes[curSection].mustHitSection);
			setOnLuas('altAnim', SONG.notes[curSection].altAnim);
			setOnLuas('gfSection', SONG.notes[curSection].gfSection);
		}
		
		setOnLuas('curSection', curSection);
		callOnLuas('onSectionHit', []);
	}

	public function StrumPlayAnim(isDad:Bool, id:Int, time:Float):Void
	{
		var spr:StrumNote = null;

		if (isDad) {
			spr = opponentStrums.members[id];
		}
		else {
			spr = playerStrums.members[id];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public function addTextToDebug(text:String, color:FlxColor):Void
	{
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText):Void {
			spr.y += 20;
		});

		if (luaDebugGroup.members.length > 34)
		{
			var blah:DebugLuaText = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}

		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function getLuaObject(tag:String, text:Bool = true):FlxSprite
	{
		if (modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if (variables.exists(tag)) return variables.get(tag);

		return null;
	}

	public function callOnLuas(event:String, args:Array<Dynamic>, ignoreStops:Bool = true, exclusions:Array<String> = null, excludeValues:Array<Dynamic> = null):Dynamic
	{
		var returnVal:Dynamic = FunkinLua.Function_Continue;

		#if LUA_ALLOWED
		if (exclusions == null) exclusions = [];
		if (excludeValues == null) excludeValues = [];

		for (script in luaArray)
		{
			if (exclusions.contains(script.scriptName)) continue;

			var myValue:Dynamic = script.call(event, args);
			if (myValue == FunkinLua.Function_StopLua && !ignoreStops) break;
			
			if (myValue != null && myValue != FunkinLua.Function_Continue) {
				returnVal = myValue;
			}
		}
		#end

		return returnVal;
	}

	public function setOnLuas(variable:String, arg:Dynamic):Void
	{
		#if LUA_ALLOWED
		for (i in 0...luaArray.length)
		{
			var lua:FunkinLua = luaArray[i];

			if (lua != null) {
				lua.set(variable, arg);
			}
		}

		for (i in achievementsArray) i.set(variable, arg);
		#end
	}

	public static function cancelMusicFadeTween():Void
	{
		if (FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}

		FlxG.sound.music.fadeTween = null;
	}

	public override function destroy():Void
	{
		super.destroy();

		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}

		luaArray = [];

		#if hscript
		if (FunkinLua.hscript != null) FunkinLua.hscript = null;
		#end

		FlxAnimationController.globalSpeed = 1;

		if (!OptionData.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		FlxG.sound.music.pitch = 1;
		instance = null;
	}

	#if (!flash && MODS_ALLOWED)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();

	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if (!OptionData.shaders) return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if (!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			Debug.logWarn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		Debug.logWarn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120):Bool
	{
		if (!OptionData.shaders) return false;

		if (runtimeShaders.exists(name))
		{
			Debug.logWarn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];

		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) {
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));
		}
		
		for (folder in foldersToCheck)
		{
			if (FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
	
				if (FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else {
					frag = null;
				}

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else {
					vert = null;
				}

				if (found)
				{
					runtimeShaders.set(name, [frag, vert]);
					return true;
				}
			}
		}

		Debug.logWarn('Missing shader $name .frag AND .vert files!');
		return false;
	}
	#end

	#if LUA_ALLOWED
	public function startLuasOnFolder(luaFile:String):Bool
	{
		for (script in luaArray) {
			if (script.scriptName == luaFile) return false;
		}

		#if MODS_ALLOWED
		var luaToLoad:String = Paths.modFolders(luaFile);

		if (FileSystem.exists(luaToLoad))
		{
			luaArray.push(new FunkinLua(luaToLoad));
			return true;
		}
		else
		{
			luaToLoad = Paths.getPreloadPath(luaFile);

			if (FileSystem.exists(luaToLoad))
			{
				luaArray.push(new FunkinLua(luaToLoad));
				return true;
			}
		}
		#elseif sys
		var luaToLoad:String = Paths.getPreloadPath(luaFile);

		if (OpenFlAssets.exists(luaToLoad))
		{
			luaArray.push(new FunkinLua(luaToLoad));
			return true;
		}
		#end

		return false;
	}
	#end

	public function startCharacterLua(name:String):Void
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;
		var luaFile:String = 'characters/' + name + '.lua';

		#if MODS_ALLOWED
		if (FileSystem.exists(Paths.modFolders(luaFile)))
		{
			luaFile = Paths.modFolders(luaFile);
			doPush = true;
		}
		else
		{
			luaFile = Paths.getPreloadPath(luaFile);

			if (FileSystem.exists(luaFile)) {
				doPush = true;
			}
		}
		#else
		luaFile = Paths.getPreloadPath(luaFile);

		if (Assets.exists(luaFile)) {
			doPush = true;
		}
		#end

		if (doPush)
		{
			for (script in luaArray) {
				if (script.scriptName == luaFile) return;
			}

			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	#if ACHIEVEMENTS_ALLOWED
	private function checkForAchievement(achievesToCheck:Array<String> = null):String
	{
		if (chartingMode) return null;

		for (i in 0...achievesToCheck.length)
		{
			var achievementName:String = achievesToCheck[i];
	
			if (!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled && Achievements.exists(achievementName))
			{
				var unlock:Bool = false;
		
				if (achievementName.contains(storyWeekText) && achievementName.endsWith('nomiss'))
				{
					if (gameMode == 'story' && campaignMisses + songMisses < 1 && storyDifficultyID == 'hard' && storyPlaylist.length <= 1 && storyDifficultyID == lastDifficulty && !usedPractice) {
						unlock = true;
					}
				}

				switch (achievementName)
				{
					case 'ur_bad':
					{
						if (songAccuracy < 20 && !practiceMode) {
							unlock = true;
						}
					}
					case 'ur_good':
					{
						if (songAccuracy >= 100 && !usedPractice) {
							unlock = true;
						}
					}
					case 'roadkill_enthusiast':
					{
						if (Achievements.henchmenDeath >= 100) {
							unlock = true;
						}
					}
					case 'oversinging':
					{
						if (boyfriend.holdTimer >= 10 && !usedPractice) {
							unlock = true;
						}
					}
					case 'hype':
					{
						if (!boyfriendIdled && !usedPractice) {
							unlock = true;
						}
					}
					case 'two_keys':
					{
						if (!usedPractice)
						{
							var howManyPresses:Int = 0;

							for (j in 0...keysPressed.length) {
								if (keysPressed[j]) howManyPresses++;
							}

							if (howManyPresses <= 2) {
								unlock = true;
							}
						}
					}
					case 'toastie':
					{
						if (OptionData.lowQuality && !OptionData.globalAntialiasing && !OptionData.shaders) {
							unlock = true;
						}
					}
					case 'debugger':
					{
						if (SONG.songID == 'test' && !usedPractice) {
							unlock = true;
						}
					}
				}

				if (unlock)
				{
					Achievements.unlockAchievement(achievementName);
					return achievementName;
				}
			}
		}

		return null;
	}
	#end
}