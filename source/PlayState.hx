package;

import haxe.Json;
import haxe.io.Path;

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
import Section;
import FlxVideo;
import Conductor;
import StageData;
import FunkinLua;
import Character;
import PhillyGlow;
import Achievements;
import DialogueBoxPsych;
import shaderslmfao.WiggleEffect;
import shaderslmfao.BuildingShaders;

import editors.ChartingState;
import editors.CharacterEditorState;

#if (VIDEOS_ALLOWED && desktop)
#if (hxCodec >= "2.6.1")
import hxcodec.VideoSprite as MP4Sprite;
#elseif (hxCodec == "2.6.0")
import VideoSprite as MP4Sprite;
#else 
import vlc.MP4Sprite;
#end
import webmlmfao.WebmSprite;
#end

#if (!flash && sys)
import openfl.filters.ShaderFilter;
import flixel.addons.display.FlxRuntimeShader;
#end

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.ui.FlxBar;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.text.FlxText;
import flixel.util.FlxSort;
import flixel.util.FlxSave;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.math.FlxPoint;
import flixel.math.FlxAngle;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.util.FlxCollision;
import flixel.util.FlxStringUtil;
import openfl.display.BitmapData;
import flixel.group.FlxSpriteGroup;
import openfl.events.KeyboardEvent;
import animateatlas.AtlasFrameMaker;
import flixel.input.keyboard.FlxKey;
import flixel.addons.effects.FlxTrail;
import flixel.graphics.atlas.FlxAtlas;
import flixel.animation.FlxAnimationController;
import flixel.addons.effects.chainable.FlxWaveEffect;
import flixel.addons.effects.chainable.FlxEffectSprite;
import flixel.addons.transition.FlxTransitionableState;

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

	public var generatedMusic:Bool = false;

	public static var STRUM_X:Float = 48.5;
	public static var STRUM_X_MIDDLESCROLL:Float = -278;

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

	public static var SONG:SwagSong = null;
	public static var curStage:String = '';

	public static var rep:Replay;
	public static var daPixelZoom:Float = 6;
	public static var isPixelStage:Bool = false;
	public static var isNextSubState:Bool = false;
	public static var gameMode:String = 'default';
	public static var isStoryMode:Bool = false;
	public static var firstSong:String = 'tutorial';
	public static var storyWeekID:String = 'tutorial';
	public static var storyWeek(get, never):Int;
	static function get_storyWeek():Int return WeekData.weeksList.indexOf(storyWeekID);
	public static var storyWeekName:String = 'Tutorial';
	public static var storyPlaylist:Array<String> = [];
	public static var weekLength:Int = 0;
	public static var chartingMode:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var usedPractice:Bool = false;
	public static var storyDifficulty:Int = 1;
	public static var lastDifficulty:Int = 1;

	public static var seenCutscene:Bool = false;

	public var songAccuracy:Float = 0;
	public var songMisses:Int = 0;
	public var songScore:Int = 0;
	public var songHits:Int = 0;

	public static var deathCounter:Int = 0;
	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var campaignAccuracy:Float = 0;

	public var boyfriendMap:Map<String, Boyfriend> = new Map<String, Boyfriend>();
	public var dadMap:Map<String, Character> = new Map<String, Character>();
	public var gfMap:Map<String, Character> = new Map<String, Character>();

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var songSpeedTween:FlxTween;
	public var spawnTime:Float = 2000;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	@:deprecated('PlayState.instance.gfDisabled` is deprecated. Use `PlayState.instance.stageData.hide_girlfriend` instead.')
	public var gfDisabled(get, never):Bool; // deprecated lol
	function get_gfDisabled():Bool {
		if (stageData != null) return stageData.hide_girlfriend;
		return false;
	}

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Boyfriend = null;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	var singAnimations:Array<String> = [];

	public static var debugKeysChart:Array<FlxKey>;
	public static var debugKeysCharacter:Array<FlxKey>;

	public var allowPlayCutscene(default, set):Bool = false;

	public var stageData:StageFile = null; // for lua
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
	var lightFadeShader:BuildingShaders;
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
		stageData = StageData.getStageFile(stage);

		if (stageData == null) // Stage couldn't be found, create a dummy stage for preventing a crash
		{
			stageData = {
				directory: '',
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

				if (!OptionData.lowQuality)
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
				if (!OptionData.lowQuality) {
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

				lightFadeShader = new BuildingShaders();

				if (!OptionData.lowQuality)
				{
					phillyWindow = new BGSprite('philly/window', city.x, city.y, 0.3, 0.3);
					phillyWindow.setGraphicSize(Std.int(phillyWindow.width * 0.85));
					phillyWindow.updateHitbox();
					phillyWindow.shader = lightFadeShader.shader; 
					add(phillyWindow);
					
					var streetBehind:BGSprite = new BGSprite('philly/behindTrain', -40, 50);
					add(streetBehind);
	
					phillyTrain = new BGSprite('philly/train', 2000, 360);
					add(phillyTrain);

					precacheList.set('train_passes', 'sound');

					trainSound = new FlxSound();
					trainSound.loadEmbedded(Paths.getSound('train_passes'));
					FlxG.sound.list.add(trainSound);
				}

				phillyStreet = new BGSprite('philly/street', -40, 50);
				add(phillyStreet);

				loadCharGroups();
			}
			case 'limo': // Week 4
			{
				var skyBG:BGSprite = new BGSprite('limo/limoSunset', -120, -50, 0.1, 0.1);
				add(skyBG);

				if (!OptionData.lowQuality)
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
				resetFastCar();
				add(fastCar);

				loadCharGroups();

				limo = new BGSprite('limo/limoDrive', -120, 550, 1, 1, ['Limo stage'], true);
				addBehindDad(limo);
			}
			case 'mall': // Week 5 - Cocoa, Eggnog
			{
				var bg:BGSprite = new BGSprite('christmas/bgWalls', -1000, -500, 0.2, 0.2);
				bg.setGraphicSize(Std.int(bg.width * 0.8));
				bg.updateHitbox();
				add(bg);

				if (!OptionData.lowQuality)
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

				if (!OptionData.lowQuality)
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
			case 'mallEvil': // Week 5 - Winter Horrorland
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
			case 'school': // Week 6 - Senpai, Roses
			{
				var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
				bgSky.antialiasing = false;
				add(bgSky);

				var repositionShit:Float = -200;
				var widShit:Int = Std.int(bgSky.width * 6);

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

				if (!OptionData.lowQuality)
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

				if (!OptionData.lowQuality)
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
			case 'schoolEvil': // Week 6 - Thorns
			{
				var posX:Float = 400;
				var posY:Float = 200;

				if (!OptionData.lowQuality)
				{
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);

					bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
					bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
					bgGhouls.updateHitbox();
					bgGhouls.visible = false;
					bgGhouls.antialiasing = false;
					bgGhouls.animation.finishCallback = function(name:String)
					{
						if (name == 'BG freaks glitch instance') {
							bgGhouls.visible = false;
						}
					}
					add(bgGhouls);
				}
				else
				{
					var bg:BGSprite = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);
					bg.scale.set(6, 6);
					bg.antialiasing = false;
					add(bg);
				}

				loadCharGroups();
			}
			case 'tank': // Week 7 - Ugh, Guns, Stress
			{
				for (i in 1...26)
				{
					if (Paths.fileExists('sounds/jeffGameover/jeffGameover-' + i + '.${Paths.SOUND_EXT}', SOUND)) {
						precacheList.set('jeffGameover/jeffGameover-' + i, 'sound');
					}
				}

				precacheList.set('tankmanKilled1', 'image');

				var bg:BGSprite = new BGSprite('tankSky', -400, -400, 0, 0);
				add(bg);

				if (!OptionData.lowQuality)
				{
					var tankSky:BGSprite = new BGSprite('tankClouds', FlxG.random.int(-700, -100), FlxG.random.int(-20, 20), 0.1, 0.1);
					tankSky.active = true;
					tankSky.velocity.x = FlxG.random.float(5, 15);
					add(tankSky);

					var tankMountains:BGSprite = new BGSprite('tankMountains', -300, -20, 0.2, 0.2);
					tankMountains.setGraphicSize(Std.int(tankMountains.width * 1.2));
					tankMountains.updateHitbox();
					add(tankMountains);

					var tankBuildings:BGSprite = new BGSprite('tankBuildings', -200, 0, 0.30, 0.30);
					tankBuildings.setGraphicSize(Std.int(tankBuildings.width * 1.1));
					tankBuildings.updateHitbox();
					add(tankBuildings);
				}

				var tankRuins:BGSprite = new BGSprite('tankRuins', -200, 0, 0.35, 0.35);
				tankRuins.setGraphicSize(Std.int(tankRuins.width * 1.1));
				tankRuins.updateHitbox();
				add(tankRuins);

				if (!OptionData.lowQuality)
				{
					var smokeLeft:BGSprite = new BGSprite('smokeLeft', -200, -100, 0.4, 0.4, ['SmokeBlurLeft'], true);
					add(smokeLeft);
	
					var smokeRight:BGSprite = new BGSprite('smokeRight', 1100, -100, 0.4, 0.4, ['SmokeRight'], true);
					add(smokeRight);
	
					tankWatchtower = new BGSprite('tankWatchtower', 100, 50, 0.5, 0.5, ['watchtower gradient color']);
					add(tankWatchtower);
				}

				tankGround = new BGSprite('tankRolling', 300, 300, 0.5, 0.5, ['BG tank w lighting'], true);
				add(tankGround);

				tankmanRun = new FlxTypedGroup<TankmenBG>();
				add(tankmanRun);

				var tankGround:BGSprite = new BGSprite('tankGround', -420, -150);
				tankGround.setGraphicSize(Std.int(tankGround.width * 1.15));
				tankGround.updateHitbox();
				add(tankGround);

				moveTank();
				loadCharGroups();

				foregroundSprites = new FlxTypedGroup<BGSprite>();
				add(foregroundSprites);

				var fgTank0:BGSprite = new BGSprite('tank0', -500, 650, 1.7, 1.5, ['fg']);
				foregroundSprites.add(fgTank0);

				if (!OptionData.lowQuality)
				{
					var fgTank1:BGSprite = new BGSprite('tank1', -300, 750, 2, 0.2, ['fg']);
					foregroundSprites.add(fgTank1);
				}

				var fgTank2:BGSprite = new BGSprite('tank2', 450, 940, 1.5, 1.5, ['foreground']); // just called 'foreground' just cuz small inconsistency no bbiggei
				foregroundSprites.add(fgTank2);

				if (!OptionData.lowQuality)
				{
					var fgTank4:BGSprite = new BGSprite('tank4', 1300, 900, 1.5, 1.5, ['fg']);
					foregroundSprites.add(fgTank4);
				}

				var fgTank5:BGSprite = new BGSprite('tank5', 1620, 700, 1.5, 1.5, ['fg']);
				foregroundSprites.add(fgTank5);

				if (!OptionData.lowQuality)
				{
					var fgTank3:BGSprite = new BGSprite('tank3', 1300, 1200, 3.5, 2.5, ['fg']);
					foregroundSprites.add(fgTank3);
				}
			}
			default: loadCharGroups();
		}

		callOnLuas('onLoadStagePost', []);
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

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	public var healthBarBG:AttachedSprite;
	public var healthBar:FlxBar;

	public var scoreTxt:FlxText;

	public var botplaySine:Float = 0;
	public var botplayTxt:FlxText;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var timeBarBG:AttachedSprite;
	public var timeBar:FlxBar;
	public var timeTxt:FlxText;

	public var grpRatings:FlxTypedGroup<RatingSprite>;
	public var grpCombo:FlxTypedGroup<ComboSprite>;
	public var grpNumbers:FlxTypedGroup<NumberSprite>;

	public static var lastRating:RatingSprite;
	public static var lastCombo:ComboSprite;
	public static var lastScore:Array<NumberSprite> = [];

	public function loadHUD():Void
	{
		callOnLuas('onLoadHUD', []);

		grpRatings = new FlxTypedGroup<RatingSprite>();
		grpRatings.cameras = [camHUD];
		add(grpRatings);

		grpCombo = new FlxTypedGroup<ComboSprite>();
		grpCombo.cameras = [camHUD];
		add(grpCombo);

		grpNumbers = new FlxTypedGroup<NumberSprite>();
		grpNumbers.cameras = [camHUD];
		add(grpNumbers);

		var showTime:Bool = OptionData.timeBarType != 'Disabled';

		if (Paths.fileExists('images/healthBar.png', IMAGE)) {
			timeBarBG = new AttachedSprite('healthBar');
		}
		else {
			timeBarBG = new AttachedSprite('ui/healthBar');
		}

		timeBarBG.y = 10;
		timeBarBG.screenCenter(X);
		timeBarBG.scrollFactor.set();
		timeBarBG.xAdd = -4;
		timeBarBG.yAdd = -4;
		if (downScroll) timeBarBG.y = FlxG.height - 30;
		timeBarBG.visible = showTime;
		timeBarBG.copyVisible = true;
		timeBarBG.cameras = [camHUD];
		timeBarBG.alpha = 0;
		add(timeBarBG);

		timeBar = new FlxBar(timeBarBG.x + 4, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), instance,
			'songPercent', 0, 1);
		timeBar.scrollFactor.set();
		timeBar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);
		timeBar.numDivisions = 800;
		timeBar.cameras = [camHUD];
		timeBar.visible = showTime;
		timeBar.alpha = 0;
		add(timeBar);

		timeBarBG.sprTracker = timeBar;

		timeTxt = new FlxText(0, timeBarBG.y + 1, FlxG.width, '', 20);
		timeTxt.setFormat(Paths.getFont('vcr.ttf'), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.borderSize = 1.25;
		timeTxt.cameras = [camHUD];
		timeTxt.visible = showTime;
		timeTxt.text = SONG.songName + " - " + CoolUtil.difficultyStuff[lastDifficulty][1];
		timeTxt.alpha = 0;
		add(timeTxt);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		opponentStrums.cameras = [camHUD];
		add(opponentStrums);

		playerStrums = new FlxTypedGroup<StrumNote>();
		playerStrums.cameras = [camHUD];
		add(playerStrums);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		strumLineNotes.cameras = [camHUD];
		strumLineNotes.visible = false;
		add(strumLineNotes);

		notes = new FlxTypedGroup<Note>();
		notes.cameras = [camHUD];
		add(notes);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		grpNoteSplashes.cameras = [camHUD];
		add(grpNoteSplashes);

		if (Paths.fileExists('images/healthBar.png', IMAGE)) {
			healthBarBG = new AttachedSprite('healthBar');
		}
		else {
			healthBarBG = new AttachedSprite('ui/healthBar');
		}

		healthBarBG.y = downScroll ? 0.11 * FlxG.height : FlxG.height * 0.89;
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

		scoreTxt = new FlxText(0, healthBarBG.y + 50, FlxG.width, '', 16);
		scoreTxt.setFormat(Paths.getFont('vcr.ttf'), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		updateScore();
		scoreTxt.scrollFactor.set();
		scoreTxt.cameras = [camHUD];
		scoreTxt.visible = OptionData.scoreText;
		add(scoreTxt);

		botplayTxt = new FlxText(400, downScroll ? timeBarBG.y - 85 : timeBarBG.y + 75, FlxG.width - 800, 'BOTPLAY', 32);
		botplayTxt.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.visible = cpuControlled;
		botplayTxt.alpha = 0;
		botplayTxt.cameras = [camHUD];
		add(botplayTxt);

		callOnLuas('onLoadHUDPost', []);
	}

	public var songLength:Float = 0;

	#if DISCORD_ALLOWED
	var storyDifficultyText:String = "";
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	public var vocals:FlxSound;
	public var vocalsVolume:Float = 1;
	public var vocalsFinished:Bool = false;

	public var inCutscene:Bool = false;
	public var startingSong:Bool = false;
	public var updateTime:Bool = false;

	var dialogueJson:DialogueFile = null;
	var dialogue:Array<String> = ['blah blah blah', 'coolswag'];

	public var iconsZooming:Bool = false;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;
	public var cameraSpeed:Float = 1;

	public var camHUD:SwagCamera;
	public var camGame:SwagCamera;
	public var camOther:SwagCamera;

	public var camFollowPos:FlxObject;
	public var camFollow:FlxPoint;

	private static var prevCamFollowPos:FlxObject;
	private static var prevCamFollow:FlxPoint;

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];
	public var eventNotes:Array<EventNote> = [];
	public var saveNotes:Array<Float> = [];

	public var gfSpeed:Int = 1;
	public var health(default, set):Float = 1;
	public var combo:Int = 0;

	public var ratingsData:Array<Rating> = [];

	public var sicks:Int = 0;
	public var goods:Int = 0;
	public var bads:Int = 0;
	public var shits:Int = 0;

	public var isCameraOnForcedPos:Bool = false;

	public var noteTypeArray:Array<String> = [];
	public var eventPushedArray:Array<String> = [];

	public var keysArray:Array<Array<FlxKey>>;
	public var controlArray:Array<String>;

	public var songPercent:Float = 0;

	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var randomNotes:Bool = false;
	public var instakillOnMiss:Bool = false;
	public var cpuControlled(default, set):Bool = false;
	public var practiceMode:Bool = false;
	public var playbackRate(default, set):Float = 1;
	public var downScroll:Bool = false;

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

		controlArray = [for (i in 0...Note.maxNote) 'NOTE_' + Note.pointers[i]];
		keysArray = [for (i in controlArray) OptionData.keyBinds.get(i.toLowerCase()).copy()];
		keysPressed = [for (i in keysArray) false];
		singAnimations = [for (i in 0...Note.maxNote) 'sing' + Note.pointers[i]];

		debugKeysChart = OptionData.keyBinds.get('debug_1').copy();
		debugKeysCharacter = OptionData.keyBinds.get('debug_2').copy();

		healthGain = OptionData.getGameplaySetting('healthgain', 1);
		healthLoss = OptionData.getGameplaySetting('healthloss', 1);

		instakillOnMiss = OptionData.getGameplaySetting('instakill', false);
		randomNotes = OptionData.getGameplaySetting('randomnotes', false);
		practiceMode = OptionData.getGameplaySetting('practice', false);
		cpuControlled = OptionData.getGameplaySetting('botplay', false);
		playbackRate = OptionData.getGameplaySetting('songspeed', 1);

		usedPractice = cpuControlled || practiceMode;
		downScroll = OptionData.downScroll;

		camGame = new SwagCamera();
		FlxG.cameras.reset(camGame);

		camHUD = new SwagCamera();
		camHUD.bgColor.alpha = 0;
		FlxG.cameras.add(camHUD, false);

		camOther = new SwagCamera();
		camOther.bgColor.alpha = 0;
		FlxG.cameras.add(camOther, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		persistentUpdate = true;
		persistentDraw = true;

		ratingsData = Conductor.getDefaultRatings();

		if (SONG == null) {
			SONG = Song.loadFromJson('tutorial', 'tutorial');
		}

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);

		GameOverSubState.resetVariables();
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

		if (!stageData.hide_girlfriend)
		{
			gf = new Character(0, 0, gfVersion);
			startCharacterPos(gf);
			gfGroup.add(gf);
			startCharacterLua(gf.curCharacter);
		}

		dad = new Character(0, 0, SONG.player2);
		startCharacterPos(dad, true);
		dadGroup.add(dad);
		startCharacterLua(dad.curCharacter);

		if (dad.curCharacter.startsWith('gf'))
		{
			dad.setPosition(GF_X, GF_Y);

			if (gf != null) {
				gf.visible = false;
			}
		}

		switch (dad.curCharacter)
		{
			case 'spirit':
			{
				if (!OptionData.lowQuality)
				{
					var evilTrail:FlxTrail = new FlxTrail(dad, null, 4, 24, 0.3, 0.069); // nice
					addBehindDad(evilTrail);
				}
			}
		}

		boyfriend = new Boyfriend(0, 0, SONG.player1);
		startCharacterPos(boyfriend);
		boyfriendGroup.add(boyfriend);

		if (boyfriend != null)
		{
			GameOverSubState.characterName = boyfriend.deathChar;
			GameOverSubState.deathSoundName = boyfriend.deathSound;
			GameOverSubState.loopSoundName = boyfriend.deathMusic;
			GameOverSubState.endSoundName = boyfriend.deathConfirm;
		}

		startCharacterLua(boyfriend.curCharacter);

		try // Checks for json/Psych Engine dialogue
		{
			var file:String = Paths.getJson('data/' + SONG.songID + '/dialogue');

			if (Paths.fileExists(file, TEXT, true)) {
				dialogueJson = DialogueBoxPsych.parseDialogue(file);
			}
		}
		catch (e:Dynamic) {
			Debug.logError('Dialogue file cannot loaded! ' + e);
		}

		try // Checks for vanilla/Senpai dialogue
		{
			var ourPath:String = 'data/' + SONG.songID + '/' + SONG.songID + 'Dialogue.txt';

			if (Paths.fileExists(ourPath, TEXT, true))
			{
				dialogue = CoolUtil.coolTextFile(ourPath, false);

				doof = new DialogueBox(false, dialogue);
				doof.scrollFactor.set();
				doof.finishThing = stopAndStart;
				doof.cameras = [camHUD];
			}
		}
		catch (e:Dynamic) {
			Debug.logError('Dialogue file cannot loaded! ' + e);
		}

		generateSong(SONG);

		startingSong = true;
		updateTime = true;

		camFollow = new FlxPoint(0, 0);
		camFollowPos = new FlxObject(0, 0, 1, 1);

		moveCameraToGF(false);

		if (prevCamFollow != null) {
			camFollow = prevCamFollow;
		}

		if (prevCamFollowPos != null) {
			camFollowPos = prevCamFollowPos;
		}

		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, null, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		FlxG.fixedTimestep = false;

		loadHUD();

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);

		var filesPushed:Array<String> = []; // "GLOBAL" SCRIPTS
		var sharedLibrary:String = Paths.getLibraryPath('scripts/', 'shared');
		sharedLibrary = sharedLibrary.substring(sharedLibrary.indexOf(':') + 1, sharedLibrary.length);
		var foldersToCheck:Array<String> = [sharedLibrary, Paths.getPreloadPath('scripts/')];

		if (Paths.currentLevel != null && Paths.currentLevel.length > 0 && Paths.currentLevel != 'shared') {
			var lib:String = Paths.getLibraryPath('scripts/', Paths.currentLevel);
			lib = lib.substring(lib.indexOf(':') + 1, lib.length);
			foldersToCheck.insert(0, lib);
		}

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

		startLuasOnFolder('weeks/' + storyWeekID + '.lua');
		startLuasOnFolder(storyWeekID + '.lua');
		startLuasOnFolder('stages/' + curStage + '.lua');

		#if ACHIEVEMENTS_ALLOWED
		for (award in Achievements.achievementsStuff) {
			startLuasOnFolder('achivements/' + award.lua_code + '.lua');
		}
		#end

		if (generatedMusic)
		{
			for (notetype in noteTypeArray) {
				startLuasOnFolder('custom_notetypes/' + notetype + '.lua');
			}
	
			for (event in eventPushedArray) {
				startLuasOnFolder('custom_events/' + event + '.lua');
			}
		}
		#end

		noteTypeArray = [];
		noteTypeArray = null;

		eventPushedArray = [];
		eventPushedArray = null;

		if (generatedMusic && eventNotes.length > 1)
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

		initDiscord();

		if (SONG.songID != firstSong && gameMode == 'story' && !seenCutscene)
		{
			skipArrowStartTween = true;

			if (prevCamFollow != null && prevCamFollowPos != null) {
				blockedCameraMovement = false;
			}
		}

		prevCamFollow = null;
		prevCamFollowPos = null;

		allowPlayCutscene = ((gameMode == 'story' && OptionData.cutscenesInType.contains('Story'))
			|| (gameMode == 'freeplay' && OptionData.cutscenesInType.contains('Freeplay'))
			|| (gameMode == 'replay' && OptionData.cutscenesInType.contains('Replay'))
			|| OptionData.cutscenesInType == 'Everywhere');

		if (allowPlayCutscene && OptionData.cutscenesInType != 'Nowhere' && !seenCutscene)
		{
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
							cameraMovementSection();

							camHUD.visible = true;
							stopAndStart();
						}
					});
				}
				case 'monster':
				{
					skipArrowStartTween = false;
					blockedCameraMovement = true;

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
							remove(whiteScreen, true);

							moveCameraToGF(true);
							stopAndStart();
						}
					});

					FlxG.sound.play(Paths.getSoundRandom('thunder_', 1, 2));

					if (gf != null) gf.playAnim('scared', true);
					boyfriend.playAnim('scared', true);
				}
				case 'winter-horrorland':
				{
					skipArrowStartTween = false;
					blockedCameraMovement = true;

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
							remove(blackScreen, true);
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
								cameraMovementSection();
								stopAndStart();
							}
						});
					});
				}
				case 'senpai' | 'roses' | 'thorns':
				{
					skipArrowStartTween = false;

					if (SONG.songID == 'thorns') {
						blockedCameraMovement = true;
					}

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
				case 'ugh' | 'guns' | 'stress': tankIntro();
				default: stopAndStart();
			}

			seenCutscene = OptionData.skipCutscenes;
		}
		else {
			stopAndStart();
		}

		if (!blockedCameraMovement) {
			cameraMovementSection();
		}

		if (gameMode != 'replay') {
			rep = new Replay('na');
		}

		RecalculateRating();

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

		for (i in 1...4) { // PRECACHING MISS SOUNDS BECAUSE I THINK THEY CAN LAG PEOPLE AND FUCK THEM UP IDK HOW HAXE WORKS
			precacheList.set('missnote' + i, 'sound');
		}

		precacheList.set(GameOverSubState.deathSoundName, 'sound');
		precacheList.set(GameOverSubState.loopSoundName, 'music');
		precacheList.set(GameOverSubState.endSoundName, 'music');

		var characterJsonPath:String = 'characters/' + GameOverSubState.characterName + '.json';

		if (Paths.fileExists(characterJsonPath, TEXT))
		{
			try
			{
				var gameOverCharacter:CharacterFile = Character.getCharacterFile(characterJsonPath);
				precacheList.set(gameOverCharacter.image, 'image');
			}
			catch (e:Dynamic) {
				Debug.logError('Cannot precache character image file: ' + e);
			}
		}

		if (OptionData.pauseMusic != 'None') {
			precacheList.set(Paths.formatToSongPath(OptionData.pauseMusic), 'music');
		}

		if (Paths.fileExists('images/alphabet.png', IMAGE)) {
			precacheList.set('alphabet', 'image');
		}
		else {
			precacheList.set('ui/alphabet', 'image');
		}

		if (!controls.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		callOnLuas('onCreatePost', []);

		super.create();

		cacheCountdown();
		cacheNoteSplashes();
		cachePopUpScore();

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

		CustomFadeTransition.nextCamera = camOther;
		if (eventNotes.length < 1) checkEventNote();
	}

	private function stopAndStart():Void
	{
		var ret:Dynamic = callOnLuas('onStart', [allowPlayCutscene]);

		if (ret != FunkinLua.Function_Stop) {
			startCountdown();
		}
	}

	var doof:DialogueBox = null;

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

	function initDiscord():Void
	{
		#if DISCORD_ALLOWED
		storyDifficultyText = CoolUtil.difficultyStuff[lastDifficulty][1] + (lastDifficulty != storyDifficulty ? ' (' + CoolUtil.difficultyStuff[storyDifficulty][1] + ')' : '');

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

		DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconP2.getCharacter()); // Updating Discord Rich Presence.
		#end
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();

	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if (!OptionData.shaders) return new FlxRuntimeShader();

		#if (!flash && sys)
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

		var foldersToCheck:Array<String> = [Paths.getPreloadPath('shaders/')];
		foldersToCheck.insert(0, Paths.getLibraryPath('shaders/', 'shared'));

		if (Paths.currentLevel != null && Paths.currentLevel.length > 0 && Paths.currentLevel != 'shared') {
			foldersToCheck.insert(0, Paths.getLibraryPath('shaders/', Paths.currentLevel));
		}

		#if MODS_ALLOWED
		foldersToCheck.insert(0, Paths.mods('shaders/'));

		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0) {
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));
		}

		for (mod in Paths.getGlobalMods()) {
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		}
		#end

		for (folder in foldersToCheck)
		{
			if (Paths.fileExists(folder, TEXT, true))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;

				if (Paths.fileExists(frag, TEXT, true))
				{
					frag = Paths.getTextFromFile(frag);
					found = true;
				}
				else {
					frag = null;
				}

				if (Paths.fileExists(frag, TEXT, true))
				{
					vert = Paths.getTextFromFile(vert);
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

	private function set_health(value:Float):Float
	{
		health = CoolUtil.boundTo(value, 0, 2);
		updateScore();

		return value;
	}

	private function set_cpuControlled(value:Bool):Bool
	{
		cpuControlled = value;

		if (botplayTxt != null) {
			botplayTxt.visible = cpuControlled;
		}

		return cpuControlled;
	}

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

	private function set_allowPlayCutscene(value:Bool):Bool
	{
		allowPlayCutscene = value;

		setOnLuas('allowPlayCutscene', allowPlayCutscene);
		setOnLuas('playingCutscene', allowPlayCutscene);

		return allowPlayCutscene;
	}

	public function addTextToDebug(text:String, color:FlxColor):Void
	{
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText):Void {
			spr.y += 20;
		});

		if (luaDebugGroup.length > 34)
		{
			var blah:DebugLuaText = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah, true);
		}

		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup, color));
		#end
	}

	public function reloadHealthBarColors():Void
	{
		var dadCol:Array<Int> = dad.healthColorArray;
		var bfCol:Array<Int> = boyfriend.healthColorArray;

		if (OptionData.coloredHealthBar) {
			healthBar.createFilledBar(FlxColor.fromRGB(dadCol[0], dadCol[1], dadCol[2]), FlxColor.fromRGB(bfCol[0], bfCol[1], bfCol[2]));
		}
		else {
			healthBar.createFilledBar(0xFFFF0000, 0xFF66FF33);
		}

		healthBar.updateBar();
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

					startCharacterPos(newBoyfriend);
					newBoyfriend.alpha = FlxMath.EPSILON;
					startCharacterLua(newBoyfriend.curCharacter);

					var iconPath:String = 'icons/' + newBoyfriend.healthIcon;

					if (!Paths.fileExists('images/' + iconPath + '.png', IMAGE)) {
						iconPath = 'icons/icon-' + newBoyfriend.healthIcon;
					}

					precacheList.set(iconPath, 'image');
				}
			}
			case 1:
			{
				if (!dadMap.exists(newCharacter))
				{
					var newDad:Character = new Character(0, 0, newCharacter);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);

					startCharacterPos(newDad, true);
					newDad.alpha = FlxMath.EPSILON;
					startCharacterLua(newDad.curCharacter);

					var iconPath:String = 'icons/' + newDad.healthIcon;

					if (!Paths.fileExists('images/' + iconPath + '.png', IMAGE)) {
						iconPath = 'icons/icon-' + newDad.healthIcon;
					}

					precacheList.set(iconPath, 'image');
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

					startCharacterPos(newGf);
					newGf.alpha = FlxMath.EPSILON;
					startCharacterLua(newGf.curCharacter);

					var iconPath:String = 'icons/' + newGf.healthIcon; // just in case

					if (!Paths.fileExists('images/' + iconPath + '.png', IMAGE)) {
						iconPath = 'icons/icon-' + newGf.healthIcon;
					}

					precacheList.set(iconPath, 'image');
				}
			}
		}
	}

	public function startCharacterLua(name:String):Void
	{
		#if LUA_ALLOWED
		var doPush:Bool = false;

		var luaFile:String = Paths.getLua('characters/' + name);

		if (Paths.fileExists(luaFile, TEXT, true)) {
			doPush = true;
		}

		if (doPush)
		{
			for (script in luaArray) {
				if (script.scriptName == luaFile) return;
			}

			luaArray.push(new FunkinLua(luaFile));
		}
		#end
	}

	public function getLuaObject(tag:String, text:Bool = true):Dynamic
	{
		if (modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if (text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		if (variables.exists(tag)) return variables.get(tag);

		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false):Void
	{
		if (gfCheck && char.curCharacter.startsWith('gf')) // IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
		{
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = OptionData.danceOffset;
		}

		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	public function startVideo(name:String):Void
	{
		inCutscene = true;
		skipArrowStartTween = false;

		#if VIDEOS_ALLOWED
		if (Paths.fileExists(Paths.getVideo(name), BINARY, true))
		{
			var bg:FlxSprite = new FlxSprite(-FlxG.width, -FlxG.height);
			bg.makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
			bg.scrollFactor.set();
			bg.updateHitbox();
			bg.cameras = [camHUD];
			add(bg);

			var video:FlxVideo = new FlxVideo(name);
			video.finishCallback = function():Void
			{
				remove(video, true);
				video.destroy();

				remove(bg, true);
				bg.destroy();

				startAndEnd();
			};
			add(video);

			return;
		}

		Debug.logWarn('Couldnt find video file: ' + name);
		#else
		Debug.logWarn('Platform not supported!');
		#end

		startAndEnd();
	}

	public function startAndEnd():Void
	{
		if (endingSong) {
			endSong();
		}
		else {
			stopAndStart();
		}
	}

	var dialogueCount:Int = 0;
	public var psychDialogue:DialogueBoxPsych;

	public function startDialogue(dialogueFile:DialogueFile, ?song:String = null):Void // You don't have to add a song, just saying. You can just do "startDialogue(dialogueJson);" and it should work
	{
		if (psychDialogue != null) return;

		if (dialogueFile.dialogue.length > 0)
		{
			inCutscene = true;

			precacheList.set('dialogue', 'sound');
			precacheList.set('dialogueClose', 'sound');

			psychDialogue = new DialogueBoxPsych(dialogueFile, song);
			psychDialogue.scrollFactor.set();

			if (endingSong)
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					endSong();
				}
			}
			else
			{
				psychDialogue.finishThing = function()
				{
					psychDialogue = null;
					stopAndStart();
				}
			}

			psychDialogue.nextDialogueThing = startNextDialogue;
			psychDialogue.skipDialogueThing = skipDialogue;
			psychDialogue.cameras = [camHUD];
			add(psychDialogue);
		}
		else
		{
			Debug.logWarn('Your dialogue file is badly formatted!');
			startAndEnd();
		}
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
			remove(black, true);

			if (SONG.songID == 'thorns')
			{
				add(red);
				camHUD.visible = false;
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
									remove(senpaiEvil, true);
									remove(red, true);

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
					stopAndStart();
				}

				remove(black, true);
			}
		});
	}

	public function tankIntro():Void
	{
		var cutsceneHandler:CutsceneHandler = new CutsceneHandler();

		var songName:String = SONG.songID;
		dadGroup.alpha = FlxMath.EPSILON;
		camHUD.visible = false;

		var tankman:FlxSprite = new FlxSprite(-20, 320);
		tankman.frames = Paths.getSparrowAtlas('cutscenes/' + songName);
		tankman.antialiasing = OptionData.globalAntialiasing;
		addBehindDad(tankman);

		cutsceneHandler.push(tankman);

		var tankman2:FlxSprite = new FlxSprite(16, 312);
		tankman2.antialiasing = OptionData.globalAntialiasing;
		tankman2.alpha = FlxMath.EPSILON;
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

			FlxTween.tween(FlxG.camera, {zoom: defaultCamZoom}, timeForStuff, {ease: FlxEase.quadInOut});
			cameraMovement('dad');

			stopAndStart();

			blockedCameraMovement = false;
			cameraMovementSection();

			dadGroup.alpha = 1;
			camHUD.visible = true;

			boyfriend.animation.finishCallback = null;

			gf.animation.finishCallback = null;
			gf.dance();
		};

		blockedCameraMovement = true;
		camFollow.set(dad.x + 280, dad.y + 170);

		switch (songName)
		{
			case 'ugh':
			{
				cutsceneHandler.endTime = 12;
				cutsceneHandler.music = 'DISTORTO';

				precacheList.set('wellWellWell', 'sound');
				precacheList.set('killYou', 'sound');
				precacheList.set('bfBeep', 'sound');

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
		
				precacheList.set('tankSong2', 'sound');

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

				gfGroup.alpha = FlxMath.EPSILON;
				boyfriendGroup.alpha = FlxMath.EPSILON;

				camFollow.set(dad.x + 400, dad.y + 170);

				FlxTween.tween(FlxG.camera, {zoom: 0.9 * 1.2}, 1, {ease: FlxEase.quadInOut});

				foregroundSprites.forEach(function(spr:BGSprite):Void {
					spr.y += 100;
				});
	
				precacheList.set('stressCutscene', 'sound');

				tankman2.frames = Paths.getSparrowAtlas('cutscenes/stress2');
				addBehindDad(tankman2);

				if (!OptionData.lowQuality)
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

				if (!OptionData.lowQuality) {
					gfCutscene.alpha = FlxMath.EPSILON;
				}

				picoCutscene.frames = AtlasFrameMaker.construct('cutscenes/stressPico');
				picoCutscene.animation.addByPrefix('anim', 'Pico Badass', 24, false);
				picoCutscene.alpha = FlxMath.EPSILON;
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

				cutsceneHandler.timer(17.5, function():Void {
					zoomBack();
				});

				cutsceneHandler.timer(19.5, function():Void
				{
					tankman2.animation.addByPrefix('lookWhoItIs', 'TANK TALK 3', 24, false);
					tankman2.animation.play('lookWhoItIs', true);
					tankman2.alpha = 1;
					tankman.visible = false;
				});

				cutsceneHandler.timer(20, function():Void {
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

	public var countdownThree:FlxSprite;
	public var countdownReady:FlxSprite;
	public var countdownSet:FlxSprite;
	public var countdownGo:FlxSprite;

	public var introAssets:Array<String> = ['Three', 'Ready', 'Set', 'Go'];

	function cacheCountdown():Void
	{
		if (isPixelStage)
		{
			introImagesSuffix = '-pixel';
			introSoundsSuffix = '-pixel';
		}

		for (asset in introAssets)
		{
			var doubleAsset:String = Paths.formatToSongPath(asset) + introImagesSuffix;

			if (Paths.fileExists('images/pixelUI/' + doubleAsset + '.png', IMAGE) && isPixelStage) {
				precacheList.set('pixelUI/' + doubleAsset, 'image');
			}
			else if (Paths.fileExists('images/' + doubleAsset + '.png', IMAGE)) {
				precacheList.set(doubleAsset, 'image');
			}
			else if (Paths.fileExists('images/countdown/' + doubleAsset + '.png', IMAGE)) {
				precacheList.set('countdown/' + doubleAsset, 'image');
			}
		}

		for (i in 1...4) {
			precacheList.set('intro' + i + introSoundsSuffix, 'sound');
		}

		precacheList.set('introGo' + introSoundsSuffix, 'sound');
	}

	public var skipCountdown:Bool = false;

	public var startTimer:FlxTimer = new FlxTimer();
	public var startedCountdown:Bool = false;

	public static var startOnTime:Float = 0;

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

			for (i in 0...playerStrums.length)
			{
				setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
				setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
			}

			generateStaticArrows(1);

			for (i in 0...opponentStrums.length)
			{
				setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
				setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
			}

			startedCountdown = true;
			Conductor.songPosition = -Conductor.crochet * 5;

			setOnLuas('startedCountdown', true);
			callOnLuas('onCountdownStarted', []);

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

			var swagCounter:Int = 0;

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

				switch (SONG.stage)
				{
					case 'philly':
					{
						if (curLoop % 4 == 0)
						{
							curLight = FlxG.random.int(0, phillyLightsColors.length - 1, [curLight]);
		
							if (phillyWindow != null && !OptionData.lowQuality)
							{
								phillyWindow.color = phillyLightsColors[curLight];
								lightFadeShader.reset();
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
						if (!OptionData.lowQuality)
						{
							upperBoppers.dance(true);
							bottomBoppers.dance(true);
						}

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
						if (!OptionData.lowQuality) tankWatchtower.dance();
		
						foregroundSprites.forEach(function(spr:BGSprite):Void {
							spr.dance();
						});
					}
				}
				var introSprPaths:Array<String> = introAssets;
				if(introSprPaths[swagCounter] != null && swagCounter < 5) {
					readySetGo(introSprPaths[swagCounter]);
				}
				if(countdownThree != null)
				{
					countdownThree.visible = false;
					countdownThree.alpha = 0;
				}
				var introSndPaths = ['intro3', 'intro2', 'intro1', 'introGo'];
				var introSndPath = introSndPaths[swagCounter] + introSoundsSuffix;
				if(Paths.fileExists('sounds/' + introSndPath + '.${Paths.SOUND_EXT}', SOUND)) {
					FlxG.sound.play(Paths.getSound(introSndPath), 0.6);
				}
				notes.forEachAlive(function(note:Note) {
					if(OptionData.opponentStrums || note.mustPress)
					{
						note.copyAlpha = false;
						note.alpha = note.multAlpha;
						if(OptionData.middleScroll && !note.mustPress) {
							note.alpha *= 0.35;
						}
					}
				});

				callOnLuas('onCountdownTick', [swagCounter]);
				swagCounter += 1;
			}, 5);
		}
	}

	function readySetGo(path:String):Void
	{
		var antialias:Bool = OptionData.globalAntialiasing && !isPixelStage;
		var name:String = Paths.formatToSongPath(path) + introImagesSuffix;

		var countdownSpr:FlxSprite = new FlxSprite();

		if (Paths.fileExists('images/pixelUI/' + name + '.png', IMAGE) && isPixelStage) {
			countdownSpr.loadGraphic(Paths.getImage('pixelUI/' + name));
		}
		else if (Paths.fileExists('images/' + name + '.png', IMAGE)) {
			countdownSpr.loadGraphic(Paths.getImage(name));
		}
		else if (Paths.fileExists('images/countdown/' + name + '.png', IMAGE)) {
			countdownSpr.loadGraphic(Paths.getImage('countdown/' + name));
		}

		if (!isPixelStage) {
			countdownSpr.setGraphicSize(Std.int(countdownSpr.width * 0.75));
		}

		countdownSpr.scrollFactor.set();

		if (isPixelStage) {
			countdownSpr.setGraphicSize(Std.int(countdownSpr.width * daPixelZoom));
		}

		countdownSpr.updateHitbox();
		countdownSpr.screenCenter();
		countdownSpr.antialiasing = antialias;
		countdownSpr.cameras = [camHUD];
		insert(members.indexOf(notes), countdownSpr);

		Reflect.setProperty(instance, 'countdown' + path, countdownSpr);

		FlxTween.tween(countdownSpr, {alpha: 0}, Conductor.crochet / 1000 / playbackRate,
		{
			ease: FlxEase.cubeInOut,
			onComplete: function(twn:FlxTween):Void
			{
				countdownSpr.kill();
				remove(countdownSpr, true);
				countdownSpr.destroy();
			}
		});
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

	public function clearNotesBefore(time:Float):Void
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

	public var scoreSeparator:String = ' | ';
	public var scoreDisplays:Dynamic = {
		deaths: true,
		ratingPercent: true,
		ratingName: true,
		ratingFC: true,
		health: true,
		misses: true
	};

	public function updateScore(miss:Bool = false):Void
	{
		callOnLuas('onUpdateScore', [miss]);

		var ultimateScoreArray:Array<String> = ['Score: ' + songScore];

		if (scoreDisplays.misses) {
			ultimateScoreArray.insert(0, 'Combo Breaks: ' + songMisses);
		}

		if (scoreDisplays.health) {
			ultimateScoreArray.insert(0, 'Health: ' + Math.floor(health * 50) + '%');
		}

		if (scoreDisplays.ratingName) {
			ultimateScoreArray.insert(0, 'Rating: ' + ratingName + (ratingName != 'N/A' && scoreDisplays.ratingFC ? ' (' + ratingFC + ')' : ''));
		}

		if (scoreDisplays.ratingPercent)
		{
			var ratingSplit:Array<String> = ('' + CoolUtil.floorDecimal(songAccuracy, 2)).split('.');

			if (ratingSplit.length < 2) { // No decimals, add an empty space
				ratingSplit.push('');
			}
	
			while (ratingSplit[1].length < 2) { // Less than 2 decimals in it, add decimals then
				ratingSplit[1] += '0';
			}

			ultimateScoreArray.insert(0, 'Accuracy: ' + ratingSplit.join('.') + '%');
		}

		if (scoreDisplays.deaths) {
			ultimateScoreArray.insert(0, 'Deaths: ' + deathCounter);
		}

		scoreTxt.text = ultimateScoreArray.join(scoreSeparator);
	}

	public function setSongTime(time:Float):Void
	{
		if (time < 0) time = 0;

		FlxG.sound.music.pause();
		if (vocals != null) vocals.pause();

		FlxG.sound.music.time = time;
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.play();

		if (vocals != null)
		{
			if (Conductor.songPosition <= vocals.length)
			{
				vocals.time = time;
				vocals.pitch = playbackRate;
			}

			vocals.play();
		}

		Conductor.songPosition = time;
		songTime = time;
	}

	function startNextDialogue():Void
	{
		dialogueCount++;
		callOnLuas('onNextDialogue', [dialogueCount]);
	}

	function skipDialogue():Void
	{
		callOnLuas('onSkipDialogue', [dialogueCount]);
	}

	var previousFrameTime:Int = 0;
	var songTime:Float = 0;

	public function startSong():Void
	{
		prevCamFollow = null;
		prevCamFollowPos = null;

		blockedCameraMovement = false;

		startingSong = false;
		iconsZooming = true;

		previousFrameTime = FlxG.game.ticks;

		FlxG.sound.playMusic(Paths.getInst(SONG.songID, CoolUtil.difficultyStuff[lastDifficulty][2]), 1, false);
		FlxG.sound.music.pitch = playbackRate;
		FlxG.sound.music.onComplete = finishSong.bind();

		vocals = new FlxSound();

		if (SONG.needsVoices) {
			vocals.loadEmbedded(Paths.getVoices(SONG.songID, CoolUtil.difficultyStuff[lastDifficulty][2]));
		}

		vocals.pitch = playbackRate;
		vocals.onComplete = function():Void {
			vocalsFinished = true;
		}
		vocals.play();
		FlxG.sound.list.add(vocals);

		var alpha:Float = 0;

		if (startOnTime > 0)
		{
			alpha = 1;
			setSongTime(startOnTime - 500);
		}

		timeBar.alpha = alpha;
		timeTxt.alpha = alpha;

		startOnTime = 0;

		if (paused)
		{
			FlxG.sound.music.pause();
			if (vocals != null) vocals.pause();
		}

		songLength = FlxG.sound.music.length; // Song duration in a float, useful for the time left feature

		if (alpha < 1)
		{
			FlxTween.tween(timeBar, {alpha: 1}, 0.5);
			FlxTween.tween(timeTxt, {alpha: 1}, 0.5);
		}

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

		if (!blockedCameraMovement && !inCutscene && !isCameraOnForcedPos) {
			cameraMovementSection();
		}

		#if DISCORD_ALLOWED
		DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconP2.getCharacter(), true, songLength); // Updating Discord Rich Presence (with Time Left)
		#end

		setOnLuas('songLength', songLength);
		callOnLuas('onSongStart', []);
	}

	private function generateSong(songData:SwagSong):Void
	{
		Conductor.changeBPM(songData.bpm);

		if (gameMode != 'replay')
		{
			songSpeedType = OptionData.getGameplaySetting('scrolltype', 'multiplicative');

			switch (songSpeedType)
			{
				case 'multiplicative':
					songSpeed = songData.speed * OptionData.getGameplaySetting('scrollspeed', 1);
				case 'constant':
					songSpeed = OptionData.getGameplaySetting('scrollspeed', 1);
			}
		}
		else
		{
			downScroll = rep.replay.isDownscroll;
			songSpeed = rep.replay.noteSpeed;
		}

		var songID:String = songData.songID;
		precacheList.set(Paths.getInst(songID, CoolUtil.difficultyStuff[lastDifficulty][2], true), 'music'); // baby it will still work

		if (songData.needsVoices) {
			precacheList.set(Paths.getVoices(songID, CoolUtil.difficultyStuff[lastDifficulty][2], true), 'music');
		}

		unspawnNotes = ChartParser.parseSongChart(songData);

		if (Paths.fileExists('data/' + songID + '/events.json', TEXT))
		{
			var eventsData:Array<Dynamic> = Song.getEvents(songID);

			if (eventsData != null && eventsData.length > 0)
			{
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
						eventNotes.push(subEvent);
						eventPushed(subEvent);
					}
				}
			}
		}

		if (songData.events != null && songData.events.length > 0)
		{
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
					eventNotes.push(subEvent);
					eventPushed(subEvent);
				}
			}
		}

		unspawnNotes.sort(sortByTime);

		if (unspawnNotes.length > 0)
		{
			var blyad:Int = unspawnNotes.length;

			var notesBlyad:Int = blyad;
			var susNotesBlyad:Int = 0;

			for (i in 0...blyad)
			{
				if (unspawnNotes[i].isSustainNote) {
					--notesBlyad;
				}

				if (unspawnNotes[i].tail.length > 0)
				{
					--notesBlyad;
					susNotesBlyad++;
				}
			}

			var eventInfo:String = (eventNotes.length > 0 ? "(" + susNotesBlyad + " sustainables and "
				+ notesBlyad + " unsustainables) and " + eventNotes.length + " events." : "("
				+ susNotesBlyad + " sustainables and " + notesBlyad + " unsustainables).");

			Debug.logInfo(SONG.songName + ": Generated " + (notesBlyad + susNotesBlyad) + " notes " + eventInfo);
		}

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
					case 'gf' | 'girlfriend' | '1': charType = 2;
					case 'dad' | 'opponent' | '0': charType = 1;
					default:
					{
						charType = Std.parseInt(event.value1);
						if (Math.isNaN(charType)) charType = 0;
					}
				}

				var newCharacter:String = event.value2;
				addCharacterToList(newCharacter, charType);
			}
			case 'Dad Battle Spotlight' | 'Dadbattle Spotlight':
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

				precacheList.set('philly/particle', 'image');

				phillyGlowParticles = new FlxTypedGroup<PhillyGlowParticle>();
				phillyGlowParticles.visible = false;
				insert(members.indexOf(phillyGlowGradient) + 1, phillyGlowParticles);
			}
			case 'Pico Speaker Shoot':
			{
				if (gf != null && gf.curCharacter == 'pico-speaker' && SONG.stage == 'tank')
				{
					gf.playAnim('shoot1', true, false, 0, function(name:String):Void
					{
						if (gf.animExists(name)) {
							gf.playAnim(name, false, false, gf.animation.curAnim.frames.length - 3);
						}
					});

					if (!OptionData.lowQuality && tankmanRun != null && FlxG.random.bool(16))
					{
						var val1:Int = Std.parseInt(event.value1);
						if (Math.isNaN(val1)) val1 = 1;

						var tankman:TankmenBG = new TankmenBG(20, 500, true);
						tankman.strumTime = event.strumTime;
						tankman.resetShit(500, 200 + FlxG.random.int(50, 100), val1 < 2);
						tankman.alpha = 1;
						tankmanRun.add(tankman);
					}
				}
				else {
					Debug.logWarn('Event "Pico Speaker Shoot" works only on stage Tank and "pico-speaker" GF version!');
				}
			}
		}

		callOnLuas('eventPushed', [event.event]);

		if (!eventPushedArray.contains(event.event)) {
			eventPushedArray.push(event.event);
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

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...Note.maxNote)
		{
			var targetAlpha:Float = 1;

			if (player < 1)
			{
				if (!OptionData.opponentStrums) {
					targetAlpha = 0;
				}
				else if (OptionData.middleScroll) {
					targetAlpha = 0.35;
				}
			}

			var babyArrow:StrumNote = new StrumNote(OptionData.middleScroll ? STRUM_X_MIDDLESCROLL : STRUM_X, downScroll ? FlxG.height - 150 : 50, i, player);
			babyArrow.downScroll = downScroll;

			if (!skipArrowStartTween)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;

				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1 / playbackRate,
				{
					ease: FlxEase.circOut,
					startDelay: (0.5 + (0.2 * i)) / playbackRate,
					onComplete: function(twn:FlxTween):Void
					{
						switch (player)
						{
							case 0:
							{
								setOnLuas('defaultOpponentStrumX' + i, opponentStrums.members[i].x);
								setOnLuas('defaultOpponentStrumY' + i, opponentStrums.members[i].y);
							}
							case 1:
							{
								setOnLuas('defaultPlayerStrumX' + i, playerStrums.members[i].x);
								setOnLuas('defaultPlayerStrumY' + i, playerStrums.members[i].y);
							}
						}
					}
				});
			}
			else {
				babyArrow.alpha = targetAlpha;
			}

			switch (player)
			{
				case 0:
				{
					if (OptionData.middleScroll)
					{
						babyArrow.x += 310;
	
						if (i > 1) { // Up and Right
							babyArrow.x += FlxG.width / 2 + 25;
						}
					}

					opponentStrums.add(babyArrow);
				}
				case 1: playerStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
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

				if (vocals != null) {
					vocals.pause();
				}
			}

			if (startTimer != null && !startTimer.finished) {
				startTimer.active = false;
			}

			if (finishTimer != null && !finishTimer.finished) {
				finishTimer.active = false;
			}

			if (cameraTwn != null && !cameraTwn.finished) {
				cameraTwn.active = false;
			}
		}
	}

	public function resume():Void
	{
		#if (VIDEOS_ALLOWED && desktop)
		if (bgVideoSprite != null)
		{
			var spr:Dynamic = (cast bgVideoSprite);

			if (Std.isOfType(spr, MP4Sprite))
			{
				#if (hxCodec > "2.6.0")
				if (spr.bitmap != null) {
					spr.bitmap.resume();
				}
				#else
				@:privateAccess
				if (spr.video != null) {
					spr.video.resume();
				}
				#end
			}
			else
			{
				if (spr.handler != null) {
					spr.handler.resume();
				}
			}

			spr.active = true;
		}
		#end

		if (camGame != null) {
			camGame.active = true;
		}

		if (camHUD != null) {
			camHUD.active = true;
		}

		if (cameraTwn != null && !cameraTwn.finished) {
			cameraTwn.active = true;
		}

		FlxTimer.globalManager.forEach(function(tmr:FlxTimer):Void
		{
			if (!tmr.finished) tmr.active = true;
		});

		FlxG.sound.list.forEachAlive(function(sud:FlxSound):Void
		{
			@:privateAccess
			if (sud._paused) sud.resume();
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween):Void
		{
			if (!twn.finished) twn.active = true;
		});

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

			paused = false;

			#if DISCORD_ALLOWED
			if (startTimer != null && startTimer.finished) {
				DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconP2.getCharacter(), true, songLength - Conductor.songPosition - OptionData.noteOffset);
			}
			else {
				DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconP2.getCharacter());
			}
			#end
		}
	}

	public override function onFocus():Void
	{
		super.onFocus();

		#if DISCORD_ALLOWED
		if (health > 0 && !paused && OptionData.autoPause)
		{
			if (Conductor.songPosition > 0.0) {
				DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconP2.getCharacter(), true, songLength - Conductor.songPosition - OptionData.noteOffset);
			}
			else {
				DiscordClient.changePresence(detailsText, SONG.songName + " - " + storyDifficultyText, iconP2.getCharacter());
			}
		}
		#end
	}
	
	public override function onFocusLost():Void
	{
		#if DISCORD_ALLOWED
		if (health > 0 && !paused && OptionData.autoPause) {
			DiscordClient.changePresence(detailsPausedText, SONG.songName + " - " + storyDifficultyText, iconP2.getCharacter());
		}
		#end

		super.onFocusLost();
	}

	public function resyncVocals():Void
	{
		if (finishTimer != null) return;

		if (vocals != null) vocals.pause();

		FlxG.sound.music.play();
		FlxG.sound.music.pitch = playbackRate;

		Conductor.songPosition = FlxG.sound.music.time;

		if (vocals != null)
		{
			if (vocalsFinished) return;

			if (Conductor.songPosition <= vocals.length)
			{
				vocals.time = Conductor.songPosition;
				vocals.pitch = playbackRate;
			}
	
			vocals.play();
		}
	}

	public var paused:Bool = false;

	public var canPause:Bool = true;
	public var canReset:Bool = true;

	var limoSpeed:Float = 0;

	public override function update(elapsed:Float):Void
	{
		setOnLuas('elapsed', elapsed);
		callOnLuas('onUpdate', [elapsed]);

		if (startedCountdown) {
			Conductor.songPosition += elapsed * 1000 * playbackRate;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0) {
				startSong();
			}
			else if (!startedCountdown) {
				Conductor.songPosition = -Conductor.crochet * 5;
			}
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

					songPercent = (curTime / songLength);

					var songCalc:Float = (songLength - curTime);

					var secondsTotal:Int = Math.floor(songCalc / 1000);
					if (secondsTotal < 0) secondsTotal = 0;

					var secondsTotalBlyad:Int = Math.floor(curTime / 1000);
					if (secondsTotalBlyad < 0) secondsTotalBlyad = 0;

					if (timeTxt != null)
					{
						timeTxt.text = SONG.songName + " - " + CoolUtil.difficultyStuff[lastDifficulty][1];

						if (OptionData.timeBarType != 'Song Name')
						{
							switch (OptionData.timeBarType)
							{
								case 'Time Left and Elapsed':
									timeTxt.text += ' (' + FlxStringUtil.formatTime(secondsTotalBlyad) + ' / ' + FlxStringUtil.formatTime(secondsTotal, false) + ')';
								case 'Time Elapsed':
									timeTxt.text += ' (' + FlxStringUtil.formatTime(secondsTotalBlyad) + ')';
								default:
									timeTxt.text += ' (' + FlxStringUtil.formatTime(secondsTotal) + ')';
							}
						}
					}
				}
			}
		}

		grpNoteSplashes.forEachDead(function(splash:NoteSplash):Void
		{
			if (grpNoteSplashes.length > 1)
			{
				grpNoteSplashes.remove(splash, true);
				splash.destroy();
			}
		});

		switch (SONG.stage)
		{
			case 'philly':
			{
				if (!OptionData.lowQuality && trainMoving)
				{
					trainFrameTiming += elapsed;

					if (trainFrameTiming >= 1 / 24)
					{
						updateTrainPos();
						trainFrameTiming = 0;
					}
				}

				lightFadeShader.update((Conductor.crochet / 1000) * elapsed * 1.5);
				//phillyWindow.alpha -= (Conductor.crochet / 1000) * elapsed * 1.5;

				if (phillyGlowParticles != null)
				{
					var i:Int = phillyGlowParticles.length - 1;

					while (i > 0)
					{
						var particle:PhillyGlowParticle = phillyGlowParticles.members[i];

						if (particle.alpha < FlxMath.EPSILON)
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
				if (!OptionData.lowQuality)
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
										case 1: limoCorpse.visible = true;
										case 2: limoCorpseTwo.visible = true;
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
							bgLimo.x = FlxMath.lerp(bgLimo.x, -150, CoolUtil.boundTo(elapsed * 9, 0, 1));

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
				if (bottomBoppers != null && heyTimer > 0)
				{
					heyTimer -= elapsed;

					if (heyTimer <= 0)
					{
						bottomBoppers.dance(true);
						heyTimer = 0;
					}
				}
			}
			case 'tank': moveTank(elapsed);
		}

		if (!inCutscene)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed * playbackRate, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

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

		super.update(elapsed);

		setOnLuas('curDecStep', curDecStep);
		setOnLuas('curDecBeat', curDecBeat);

		if (botplayTxt != null && botplayTxt.visible)
		{
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - Math.sin((Math.PI * botplaySine) / 180);
		}

		if (!endingSong && !inCutscene)
		{
			if (controls.PAUSE && startedCountdown && canPause && !controls.controllerMode)
			{
				var ret:Dynamic = callOnLuas('onPause', [], false);
	
				if (ret != FunkinLua.Function_Stop) {
					openPauseMenu();
				}
			}

			if (gameMode != 'replay')
			{
				if (FlxG.keys.anyJustPressed(debugKeysChart))
				{
					var ret:Dynamic = callOnLuas('onOpenChartEditor', [], false);
		
					if (ret != FunkinLua.Function_Stop) {
						openChartEditor();
					}
				}

				#if MODS_ALLOWED
				if (FlxG.keys.anyJustPressed(debugKeysCharacter))
				{
					var ret:Dynamic = callOnLuas('onOpenCharacterEditor', [], false);

					if (ret != FunkinLua.Function_Stop) {
						openCharacterEditor();
					}
				}
				#end
			}
		}

		var mult:Float = FlxMath.lerp(1, iconP1.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP1.scale.set(mult, mult);
		iconP1.updateHitbox();

		var mult:Float = FlxMath.lerp(1, iconP2.scale.x, CoolUtil.boundTo(1 - (elapsed * 9 * playbackRate), 0, 1));
		iconP2.scale.set(mult, mult);
		iconP2.updateHitbox();

		var iconOffset:Int = 26;

		if (iconP1.usePsych) {
			iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) + (150 * iconP1.scale.x - 150) / 2 - iconOffset;
		}
		else {
			iconP1.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01) - iconOffset);
		}

		if (iconP2.usePsych) {
			iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (150 * iconP2.scale.x) / 2 - iconOffset * 2;
		}
		else {
			iconP2.x = healthBar.x + (healthBar.width * (FlxMath.remapToRange(healthBar.percent, 0, 100, 100, 0) * 0.01)) - (iconP2.width - iconOffset);
		}

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

		if (camZooming)
		{
			FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
			camHUD.zoom = FlxMath.lerp(1, camHUD.zoom, CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay * playbackRate), 0, 1));
		}

		FlxG.watch.addQuick('secShit', curSection);
		FlxG.watch.addQuick('beatShit', curBeat);
		FlxG.watch.addQuick('stepShit', curStep);

		if (controls.RESET && !OptionData.noReset && canReset && !inCutscene && startedCountdown && !endingSong && !cpuControlled && !practiceMode) {
			health = 0;
		}

		doDeathCheck();

		if (unspawnNotes.length > 0 && unspawnNotes[0] != null)
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

		if (generatedMusic)
		{
			if (!inCutscene)
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
					var fakeCrochet:Float = (60 / SONG.bpm) * 1000;

					notes.forEachAlive(function(daNote:Note):Void
					{
						var strumGroup:FlxTypedGroup<StrumNote> = daNote.mustPress ? playerStrums : opponentStrums;
						var strum:StrumNote = strumGroup.members[daNote.noteData];

						var strumX:Float = strum.x;
						var strumY:Float = strum.y;
						var strumAngle:Float = strum.angle;
						var strumDirection:Float = strum.direction;
						var strumAlpha:Float = strum.alpha;
						var strumScroll:Bool = strum.downScroll;

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

						if (daNote.copyY)
						{
							daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

							if (strumScroll && daNote.isSustainNote) // Jesus fuck this took me so much mother fucking time AAAAAAAAAA
							{
								if (daNote.animation.curAnim.name.endsWith('end'))
								{
									daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
									daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;

									if (isPixelStage) {
										daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * daPixelZoom;
									}
									else {
										daNote.y -= 19;
									}
								}

								daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
								daNote.y += 27.5 * ((SONG.bpm / 100) - 1) * (songSpeed - 1);
							}
						}

						if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) {
							opponentNoteHit(daNote);
						}

						if (!daNote.blockHit && daNote.mustPress && cpuControlled && daNote.canBeHit)
						{
							if (daNote.isSustainNote)
							{
								if (daNote.canBeHit) {
									goodNoteHit(daNote);
								}
							}
							else if (daNote.strumTime <= Conductor.songPosition || daNote.isSustainNote) {
								goodNoteHit(daNote);
							}
						}

						var center:Float = strumY + Note.swagWidth / 2;

						if (strum.sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) && (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
						{
							if (strumScroll)
							{
								var swagRect:FlxRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								var result:Int = Std.int((daNote.y + daNote.height) - center);

								if (result > 0) {
									swagRect.y = result / daNote.scale.y;
								}

								daNote.clipRect = swagRect;
							}
							else
							{
								var swagRect:FlxRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
								var result:Int = Std.int(center - daNote.y);

								if (result > 0) {
									swagRect.y = result / daNote.scale.y;
								}

								daNote.clipRect = swagRect;
							}
						}

						if (Conductor.songPosition > noteKillOffset + daNote.strumTime) // Kill extremely late notes and cause misses
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
		}

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
		setOnLuas('practice', practiceMode);
		setOnLuas('practiceMode', practiceMode);

		callOnLuas('onUpdatePost', [elapsed]);
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

		FlxG.sound.list.forEachAlive(function(sud:FlxSound):Void
		{
			@:privateAccess
			if (!sud._paused) sud.pause();
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween):Void
		{
			if (!twn.finished) twn.active = false;
		});

		#if (VIDEOS_ALLOWED && desktop)
		if (bgVideoSprite != null)
		{
			var spr:Dynamic = (cast bgVideoSprite);

			if (Std.isOfType(spr, MP4Sprite))
			{
				#if (hxCodec > "2.6.0")
				if (spr.bitmap != null) {
					spr.bitmap.pause();
				}
				#else
				@:privateAccess
				if (spr.video != null) {
					spr.video.pause();
				}
				#end
			}
			else
			{
				if (spr.handler != null) {
					spr.handler.pause();
				}
			}

			spr.active = false;
		}
		#end

		persistentUpdate = false;
		persistentDraw = true;

		paused = true;

		openSubState(new PauseSubState(false));
	
		#if DISCORD_ALLOWED
		DiscordClient.changePresence(detailsPausedText, SONG.songName + " - " + storyDifficultyText, iconP2.getCharacter());
		#end
	}

	public var isDead:Bool = false; // Don't mess with this on Lua!!!

	public function doDeathCheck(?skipHealthCheck:Bool = false):Bool
	{
		if (((skipHealthCheck && instakillOnMiss) || health < FlxMath.EPSILON) && !practiceMode && !cpuControlled)
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

				for (sud in modchartSounds)
				{
					@:privateAccess
					if (sud._paused) sud.resume();
				}

				for (tween in modchartTweens) {
					tween.active = true;
				}

				for (timer in modchartTimers) {
					timer.active = true;
				}

				FlxG.sound.music.stop();
				if (vocals != null) vocals.stop();

				if (camGame != null) {
					camGame.active = true;
				}

				if (camHUD != null) {
					camHUD.active = true;
				}

				#if (VIDEOS_ALLOWED && desktop)
				endBGVideo();
				#end

				FlxAnimationController.globalSpeed = 1;

				openSubState(new GameOverSubState(boyfriend.getScreenPosition().x - boyfriend.positionArray[0], boyfriend.getScreenPosition().y - boyfriend.positionArray[1]));

				#if DISCORD_ALLOWED
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.songName + " - " + storyDifficultyText, iconP2.getCharacter());
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

		if (camHUD != null) {
			camHUD.active = false;
		}

		FlxTimer.globalManager.forEach(function(tmr:FlxTimer):Void
		{
			if (!tmr.finished) tmr.active = false;
		});

		FlxG.sound.list.forEachAlive(function(sud:FlxSound):Void
		{
			@:privateAccess
			if (!sud._paused) sud.pause();
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween):Void
		{
			if (!twn.finished) twn.active = false;
		});

		CustomFadeTransition.nextCamera = camOther;
		FlxG.switchState(new ChartingState());

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public function openCharacterEditor():Void
	{
		persistentUpdate = false;
		paused = true;

		cancelMusicFadeTween();

		if (camHUD != null) {
			camHUD.active = false;
		}

		FlxTimer.globalManager.forEach(function(tmr:FlxTimer):Void
		{
			if (!tmr.finished) tmr.active = false;
		});

		FlxG.sound.list.forEachAlive(function(sud:FlxSound):Void
		{
			@:privateAccess
			if (!sud._paused) sud.pause();
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween):Void
		{
			if (!twn.finished) twn.active = false;
		});

		CustomFadeTransition.nextCamera = camOther;
		FlxG.switchState(new CharacterEditorState(SONG.player2, true));
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
			case 'Dad Battle Spotlight' | 'Dadbattle Spotlight':
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

						new FlxTimer().start(0.12, function(tmr:FlxTimer):Void {
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
						if (dad.curCharacter.startsWith('gf')) // Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						{
							if (dad.animation.curAnim != null && dad.animation.curAnim.name != 'hairBlow' && dad.animation.curAnim.name != 'hairFall')
							{
								dad.playAnim('cheer', true);
								dad.specialAnim = true;
								dad.heyTimer = time;
							}
						}
						else if (gf != null)
						{
							if (gf.animation.curAnim != null && gf.animation.curAnim.name != 'hairBlow' && gf.animation.curAnim.name != 'hairFall')
							{
								gf.playAnim('cheer', true);
								gf.specialAnim = true;
								gf.heyTimer = time;
							}
						}
	
						if (SONG.stage == 'mall' && bottomBoppers != null)
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
							if (dad.animation.curAnim != null && dad.animation.curAnim.name != 'hairBlow' && dad.animation.curAnim.name != 'hairFall')
							{
								gf.playAnim('cheer', true);
								gf.specialAnim = true;
								gf.heyTimer = time;
							}
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
						if (!OptionData.lowQuality)
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
			case 'Kill Henchmen': killHenchmen();
			case 'Add Camera Zoom':
			{
				if (OptionData.camZooms && FlxG.camera.zoom < 1.35)
				{
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);

					if (Math.isNaN(camZoom)) camZoom = 0.015;
					if (Math.isNaN(hudZoom)) hudZoom = 0.03;

					FlxG.camera.zoom += camZoom;
					camZooming = true;

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
			case 'Pico Speaker Shoot':
			{
				if (gf != null && gf.curCharacter == 'pico-speaker')
				{
					var val1:Int = Std.parseInt(value1);
					if (Math.isNaN(val1)) val1 = 1;

					if (val1 > 2) {
						val1 = 3;
					}

					val1 += FlxG.random.int(0, 1);

					var animName:String = 'shoot' + val1;

					if (gf.animExists(animName))
					{
						gf.playAnim(animName, true, false, 0, function(name:String):Void
						{
							if (gf.animExists(name)) {
								gf.playAnim(name, false, false, gf.animation.curAnim.frames.length - 3);
							}
						});
					}
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
							boyfriend.alpha = FlxMath.EPSILON;
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
							dad.alpha = FlxMath.EPSILON;
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
								gf.alpha = FlxMath.EPSILON;
								gf = gfMap.get(value2);
								gf.alpha = lastAlpha;
							}

							setOnLuas('gfName', gf.curCharacter);
						}
					}
				}

				cameraMovementSection();
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

				var newValue:Float = SONG.speed * OptionData.getGameplaySetting('scrollspeed', 1) * val1;

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
			case 'Call From Object':
			{
				var fieldArray:Array<String> = value1.split('.');
				var arguments:Array<String> = [for (i in value2.trim().split(',')) i = i.trim()];

				if (fieldArray.length > 1)
				{
					#if js
					var killMe:Array<String> = fieldArray.slice(0, fieldArray.length - 1);
					var fuckYouHtml5:Dynamic = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length - 1]);
					Reflect.callMethod(null, Reflect.getProperty(fuckYouHtml5, fieldArray[fieldArray.length - 1]), arguments);
					#else
					Reflect.callMethod(null, FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(fieldArray, true, true), fieldArray[fieldArray.length - 1]), arguments);
					#end
				}
				else
				{
					#if js
					Reflect.callMethod(instance, FunkinLua.getVarInArray(instance, value1), arguments);
					#else
					Reflect.callMethod(null, FunkinLua.getVarInArray(instance, value1), arguments);
					#end
				}
			}
			#if LUA_ALLOWED
			case 'Call on Luas':
			{
				var arguments:Array<String> = [for (i in value2.trim().split(',')) i = i.trim()];
				callOnLuas(value1.trim(), arguments);
			}
			case 'Set on Luas':
			{
				setOnLuas(value1.trim(), value2);
			}
			#end
			#if (VIDEOS_ALLOWED && desktop)
			case 'Start Video on HUD':
			{
				var path:String = Paths.getVideo(value1);

				if (Paths.fileExists(path, BINARY, true))
				{
					backgroundVideo(value1, (value2 == 'true' || value2 == 'yes'));
					return;
				}

				Debug.logWarn('Couldnt find video file: ' + value1);
			}
			case 'Start BG Video':
			{
				var path:String = Paths.getVideo(value1);

				if (Paths.fileExists(path, BINARY, true))
				{
					var arrayShit:Array<String> = [for (i in value2.trim().split(',')) i = i.trim()];
					makeBackgroundTheVideo(value1, (arrayShit[0] == 'true' || arrayShit[0] == 'yes'), arrayShit[1]);
					return;
				}

				Debug.logWarn('Couldnt find video file: ' + value1);
			}
			case 'End Video': endBGVideo();
			#end
			case 'Play Sound':
			{
				var soundPath:String = value1.trim();

				var volume:Float = Std.parseFloat(value2);
				if (Math.isNaN(volume)) volume = 1;

				if (modchartSounds.exists(soundPath)) {
					modchartSounds.get(soundPath).stop();
				}

				modchartSounds.set(soundPath, FlxG.sound.play(Paths.getSound(soundPath), volume, false, function():Void
				{
					modchartSounds.remove(soundPath);
					callOnLuas('onSoundFinished', [soundPath]);
				}));

				return;
			}
			case 'Stop Sound':
			{
				var soundPath:String = value1.trim();

				if (soundPath != null && soundPath.length > 1 && modchartSounds.exists(soundPath))
				{
					modchartSounds.get(soundPath).stop();
					modchartSounds.remove(soundPath);
				}
			}
			case 'Pause Sound':
			{
				var soundPath:String = value1.trim();

				if (soundPath != null && soundPath.length > 1 && modchartSounds.exists(soundPath))
				{
					modchartSounds.get(soundPath).pause();
					modchartSounds.remove(soundPath);
				}
			}
			case 'Resume Sound':
			{
				var soundPath:String = value1.trim();

				if (soundPath != null && soundPath.length > 1 && modchartSounds.exists(soundPath))
				{
					modchartSounds.get(soundPath).resume();
					modchartSounds.remove(soundPath);
				}
			}
			case 'Sound Fade In':
			{
				var arrayBlyad:Array<String> = [for (i in value2.trim().split(',')) i = i.trim()];

				var duration:Float = Std.parseFloat(arrayBlyad[0]);
				var fromValue:Float = Std.parseFloat(arrayBlyad[1]);
				var toValue:Float = Std.parseFloat(arrayBlyad[2]);

				var soundPath:String = value1.trim();

				if (modchartSounds.exists(soundPath)) {
					modchartSounds.get(soundPath).fadeIn(duration, fromValue, toValue);
				}
			}
			case 'Sound Fade Out':
			{
				var arrayBlyad:Array<String> = [for (i in value2.trim().split(',')) i = i.trim()];

				var duration:Float = Std.parseFloat(arrayBlyad[0]);
				var toValue:Float = Std.parseFloat(arrayBlyad[1]);

				var soundPath:String = value1.trim();

				if (modchartSounds.exists(soundPath)) {
					modchartSounds.get(soundPath).fadeOut(duration, toValue);
				}
			}
			case 'Cancel Sound Fade':
			{
				var soundPath:String = value1.trim();

				if (modchartSounds.exists(soundPath))
				{
					var theSound:FlxSound = modchartSounds.get(soundPath);

					if (theSound.fadeTween != null)
					{
						theSound.fadeTween.cancel();
						modchartSounds.remove(soundPath);
					}
				}
			}
			case 'Fade Event':
			{
				if (!Paths.fileExists('custom_events/' + eventName + '.lua', TEXT)) // fuck it
				{
					var color:Int = CoolUtil.getColorFromString(value2);
					FlxG.camera.fade(color, Std.parseFloat(value1), false);
				}
			}
			case 'Flash Event':
			{
				if (!Paths.fileExists('custom_events/' + eventName + '.lua', TEXT)) // fuck it
				{
					var color:Int = CoolUtil.getColorFromString(value2);
					FlxG.camera.flash(color, Std.parseFloat(value1), null, false);
				}
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
				if (Math.isNaN(duration)) duration = 1;

				var ease:String = array[3];

				if (object != null && (tag != null && tag.length > 0) && (ease != null && ease.length > 0))
				{
					modchartTweens.set(tag, FlxTween.tween(object, {x: newValue}, duration,
					{
						ease: FunkinLua.getFlxEaseByString(ease),
						onUpdate: function(twn:FlxTween):Void
						{
							cameraMovementSection();
							callOnLuas('onTweenUpdate', [tag, FlxG.elapsed]);
						},
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
				if (Math.isNaN(duration)) duration = 1;

				var ease:String = array[3];

				if (object != null && (tag != null && tag.length > 0) && (ease != null && ease.length > 0))
				{
					modchartTweens.set(tag, FlxTween.tween(object, {y: newValue}, duration,
					{
						ease: FunkinLua.getFlxEaseByString(ease),
						onUpdate: function(twn:FlxTween):Void
						{
							cameraMovementSection();
							callOnLuas('onTweenUpdate', [tag, FlxG.elapsed]);
						},
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

				if (object != null && (tag != null && tag.length > 0) && (ease != null && ease.length > 0))
				{
					modchartTweens.set(tag, FlxTween.tween(object, {x: newValueX, y: newValueY}, duration,
					{
						ease: FunkinLua.getFlxEaseByString(ease),
						onUpdate: function(twn:FlxTween):Void
						{
							cameraMovementSection();
							callOnLuas('onTweenUpdate', [tag, FlxG.elapsed]);
						},
						onComplete: function(twn:FlxTween):Void
						{
							callOnLuas('onTweenCompleted', [tag]);
							modchartTweens.remove(tag);
						}
					}));
				}
			}
			case 'Object Alpha Tween':
			{
				var array:Array<String> = value2.trim().split(',');

				for (i in 0...array.length) {
					array[i] = array[i].trim();
				}

				var tag:String = array[0];
				var object:Dynamic = FunkinLua.getTween(tag, value1);

				var newValue:Float = Std.parseFloat(array[1]);
				if (Math.isNaN(newValue)) newValue = 0;

				if (newValue < 0) newValue = 0;
				if (newValue > 1) newValue = 1;

				var duration:Float = Std.parseFloat(array[2]);
				if (Math.isNaN(duration)) duration = 1;

				var ease:String = array[3];

				if (object != null && (tag != null && tag.length > 0) && (ease != null && ease.length > 0))
				{
					modchartTweens.set(tag, FlxTween.tween(object, {alpha: newValue}, duration,
					{
						ease: FunkinLua.getFlxEaseByString(ease),
						onUpdate: function(twn:FlxTween):Void {
							callOnLuas('onTweenUpdate', [tag, FlxG.elapsed]);
						},
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
				if (Math.isNaN(duration)) duration = 1;

				var ease:String = array[3];

				if (object != null && (tag != null && tag.length > 0) && (ease != null && ease.length > 0))
				{
					modchartTweens.set(tag, FlxTween.tween(object, {angle: newValue}, duration,
					{
						ease: FunkinLua.getFlxEaseByString(ease),
						onUpdate: function(twn:FlxTween):Void {
							callOnLuas('onTweenUpdate', [tag, FlxG.elapsed]);
						},
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
				if (Math.isNaN(duration)) duration = 1;

				var ease:String = array[3];

				if (object != null && (tag != null && tag.length > 0) && (ease != null && ease.length > 0))
				{
					modchartTweens.set(tag, FlxTween.tween(object, {zoom: newValue}, duration,
					{
						ease: FunkinLua.getFlxEaseByString(ease),
						onUpdate: function(twn:FlxTween):Void {
							callOnLuas('onTweenUpdate', [tag, FlxG.elapsed]);
						},
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

				if (tag != null && tag.length > 0)
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

				if (obj != null && obj.length > 0)
				{
					var luaObject:FlxSprite = getLuaObject(obj, false);

					if (luaObject != null)
					{
						var luaObj:FlxSprite = luaObject;
		
						if (luaObj.animation.getByName(name) != null)
						{
							luaObj.animation.play(name, forced, reverse, startFrame);

							luaObj.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int):Void {
								callOnLuas('onAnimationProgress', [obj, name, frameNumber, frameIndex]);
							};
		
							luaObj.animation.finishCallback = function(name:String):Void
							{
								callOnLuas('onAnimationFinished', [obj, name]);
		
								luaObj.animation.callback = null;
								luaObj.animation.finishCallback = null;
							};
		
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

								spr.animation.callback = function(name:String, frameNumber:Int, frameIndex:Int):Void {
									callOnLuas('onAnimationProgress', [obj, name, frameNumber, frameIndex]);
								};

								spr.animation.finishCallback = function(name:String):Void
								{
									callOnLuas('onAnimationFinished', [obj, name]);
			
									spr.animation.callback = null;
									spr.animation.finishCallback = null;
								};
							}
						}	
					}
				}
			}
			case 'Set Health Bar Colors':
			{
				if (!Paths.fileExists('custom_events/' + eventName + '.lua', TEXT)) // fuck it
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
			}
			case 'Set Music Volume':
			{
				if (!Paths.fileExists('custom_events/' + eventName + '.lua', TEXT)) // fuck it
				{
					if (FlxG.sound.music != null)
					{
						var newValue:Float = Std.parseFloat(value1);
						if (Math.isNaN(newValue)) newValue = 1;
	
						FlxG.sound.music.volume = newValue;
					}
				}
			}
			case 'Set Vocals Volume':
			{
				if (!Paths.fileExists('custom_events/' + eventName + '.lua', TEXT)) // fuck it
				{
					if (vocals != null)
					{
						var newValue:Float = Std.parseFloat(value1);
						if (Math.isNaN(newValue)) newValue = 1;

						vocalsVolume = newValue;
						vocals.volume = vocalsVolume;
					}
				}
			}
			case 'Change Icon':
			{
				if (!Paths.fileExists('custom_events/' + eventName + '.lua', TEXT)) // fuck it
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
			}
			case 'Camera Tween Pos':
			{
				if (!Paths.fileExists('custom_events/' + eventName + '.lua', TEXT)) // fuck it
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
								onUpdate: function(twn:FlxTween):Void
								{
									callOnLuas('onTweenUpdate', ['CameraEventX', FlxG.elapsed]);
									modchartTweens.remove('CameraEventX');
								},
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
								onUpdate: function(twn:FlxTween):Void
								{
									callOnLuas('onTweenUpdate', ['CameraEventY', FlxG.elapsed]);
									modchartTweens.remove('CameraEventY');
								},
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
			}
			case 'Camera Tween Zoom':
			{
				if (!Paths.fileExists('custom_events/' + eventName + '.lua', TEXT)) // fuck it
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
						onUpdate: function(twn:FlxTween):Void
						{
							defaultCamZoom = FlxG.camera.zoom;

							callOnLuas('onTweenUpdate', ['ZoomEvent', FlxG.elapsed]);
							modchartTweens.remove('ZoomEvent');
						},
						onComplete: function(twn:FlxTween):Void
						{
							defaultCamZoom = FlxG.camera.zoom;

							callOnLuas('onTweenCompleted', ['ZoomEvent']);
							modchartTweens.remove('ZoomEvent');
						}
					}));

					defaultCamZoom = newValue;
				}
			}
			case 'Set Cam Zoom':
			{
				if (!Paths.fileExists('custom_events/' + eventName + '.lua', TEXT)) // fuck it
				{
					if (value1 != null && value1.length > 0)
					{
						var ourNewValue:Float = Std.parseFloat(value1);
						if (Math.isNaN(ourNewValue)) ourNewValue = 0.9;

						var duration:Float = Std.parseFloat(value2);
						if (Math.isNaN(duration)) duration = 1;

						defaultCamZoom = ourNewValue;

						modchartTweens.set('camz', FlxTween.tween(FlxG.camera, {zoom: ourNewValue}, duration,
						{
							ease: FlxEase.sineInOut,
							onUpdate: function(twn:FlxTween):Void
							{
								defaultCamZoom = FlxG.camera.zoom;

								callOnLuas('onTweenUpdate', ['camz', FlxG.elapsed]);
								modchartTweens.remove('camz');
							},
							onComplete: function(twn:FlxTween):Void
							{
								defaultCamZoom = FlxG.camera.zoom;

								callOnLuas('onTweenCompleted', ['camz']);
								modchartTweens.remove('camz');
							}
						}));
					}
				}
			}
			case 'Cam Boom Speed':
			{
				if (!Paths.fileExists('custom_events/' + eventName + '.lua', TEXT)) // fuck it
				{
					boomSpeed = Std.parseInt(value1);
					if (Math.isNaN(boomSpeed)) boomSpeed = 4;

					bamVal = Std.parseInt(value2);
					if (Math.isNaN(bamVal)) bamVal = 1;
				}
			}
		}

		callOnLuas('onEvent', [eventName, value1, value2]);
	}

	public var blockedCameraMovement:Bool = true;

	public function cameraMovementSection():Void
	{
		if (SONG.notes[curSection] != null)
		{
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
	}

	var cameraTwn:FlxTween;

	public var cameraRightSide:Null<Bool> = null;

	public function cameraMovement(moveCameraTo:Dynamic):Void
	{
		if (moveCameraTo == 'dad' || moveCameraTo == true)
		{
			cameraRightSide = false;

			camFollow.set(dad.getMidpoint().x + 150, dad.getMidpoint().y - 100);
			camFollow.x += dad.cameraPosition[0] + opponentCameraOffset[0];
			camFollow.y += dad.cameraPosition[1] + opponentCameraOffset[1];

			tweenCamIn();
		}
		else if (moveCameraTo == 'boyfriend' || moveCameraTo == false)
		{
			cameraRightSide = true;

			camFollow.set(boyfriend.getMidpoint().x - 100, boyfriend.getMidpoint().y - 100);
			camFollow.x -= boyfriend.cameraPosition[0] - boyfriendCameraOffset[0];
			camFollow.y += boyfriend.cameraPosition[1] + boyfriendCameraOffset[1];

			if (SONG.songID == 'tutorial' && cameraTwn == null && FlxG.camera.zoom != 1)
			{
				cameraTwn = FlxTween.tween(FlxG.camera, {zoom: 1}, (Conductor.stepCrochet * 4 / 1000),
				{
					ease: FlxEase.elasticInOut,
					onComplete: function(twn:FlxTween) {
						cameraTwn = null;
					}
				});
			}
		}
		else
		{
			cameraRightSide = null;

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

	public function snapCamFollowToPos(x:Float, y:Float):Void
	{
		camFollow.set(x, y);
		camFollowPos.setPosition(x, y);
	}

	function killCombo(daNote:Note = null):Void
	{
		if (daNote != null)
		{
			if (!daNote.isSustainNote)
			{
				health -= daNote.missHealth * healthLoss;
				FlxG.sound.play(Paths.getSoundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			}
			else {
				health -= daNote.missHealth_sus * healthLoss;
			}
		}
		else
		{
			FlxG.sound.play(Paths.getSoundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));
			health -= 0.025 * healthLoss;
		}

		if (instakillOnMiss) {
			doDeathCheck(true);
		}

		if (combo > 5 && gf != null && gf.animExists('sad')) {
			gf.playAnim('sad');
		}

		if (combo > 0)
		{
			combo = 0;
			displayCombo();
		}

		if (!practiceMode && !cpuControlled)
		{
			if (daNote != null && !daNote.isSustainNote && !daNote.hitCausesMiss) songMisses++;
			totalPlayed++;

			RecalculateRating(true);
		}

		if (vocals != null) {
			vocals.volume = 0;
		}

		if (instakillOnMiss) {
			doDeathCheck(true);
		}
	}

	public var endingSong(default, set):Bool = false;
	private function set_endingSong(value:Bool):Bool {
		endingSong = value;
		setOnLuas('endingSong', endingSong);
		return value;
	}

	public var finishTimer:FlxTimer = null;

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong;

		endingSong = true;
		updateTime = false;

		camZooming = false;
		iconsZooming = false;

		FlxG.sound.music.volume = 0;

		if (vocals != null)
		{
			vocals.pause();
			vocals.volume = 0;
		}

		if (OptionData.noteOffset < 1 || ignoreNoteOffset) {
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
		if (!startingSong) // Should kill you if you tried to cheat
		{
			notes.forEach(function(daNote:Note):Void
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			});

			for (daNote in unspawnNotes)
			{
				if (daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}

			if (doDeathCheck()) {
				return;
			}
		}

		inCutscene = false;
		blockedCameraMovement = true;

		if (gameMode != 'replay') {
			rep.saveReplay(saveNotes);
		}

		endingSong = true;
		updateTime = false;

		camZooming = false;
		iconsZooming = false;

		timeBar.visible = false;
		timeTxt.visible = false;

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
			var achieve:String = checkForAchievement(null, [Achievements.getAchievement('friday_night_play')]);

			if (achieve != null)
			{
				startAchievement(achieve);
				return;
			}
		}
		#end

		prevCamFollow = null;
		prevCamFollowPos = null;

		allowPlayCutscene = ((gameMode == 'story' && OptionData.cutscenesInType.contains('Story'))
			|| (gameMode == 'freeplay' && OptionData.cutscenesInType.contains('Freeplay'))
			|| (gameMode == 'replay' && OptionData.cutscenesInType.contains('Replay'))
			|| OptionData.cutscenesInType == 'Everywhere');

		var ret:Dynamic = callOnLuas('onEndSong', [allowPlayCutscene], false);

		if (ret != FunkinLua.Function_Stop && !transitioning)
		{
			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			var difficultyID:String = CoolUtil.difficultyStuff[lastDifficulty][0];
			var difficultySuffix:String = CoolUtil.difficultyStuff[storyDifficulty][2];

			if (gameMode != 'replay')
			{
				#if !switch
				Highscore.saveScore(CoolUtil.formatSong(SONG.songID, difficultyID), songScore, (Math.isNaN(songAccuracy) ? 0 : songAccuracy));
				#end
			}

			playbackRate = 1;

			switch (gameMode)
			{
				case 'story':
				{
					campaignScore += songScore;
					campaignMisses += songMisses;
					campaignAccuracy += songAccuracy;
					campaignAccuracy /= weekLength;

					storyPlaylist.shift();

					var firstSong:String = storyPlaylist[0];

					var ourPath:String = 'data/' + firstSong + '/' + firstSong + difficultySuffix + '.json';
					var noExistsPoop:Bool = firstSong != null && !Paths.fileExists(ourPath, TEXT);

					if (storyPlaylist.length <= 0 || noExistsPoop)
					{
						if (noExistsPoop) {
							Debug.logError('File "' + ourPath + '" does not exist! Going to Story Menu...');
						}
						else {
							Debug.logInfo('Finished week "' + storyWeekName + '".');
						}

						cancelMusicFadeTween();

						CustomFadeTransition.nextCamera = camOther;

						if (FlxTransitionableState.skipNextTransIn) {
							CustomFadeTransition.nextCamera = null;
						}

						if (!usedPractice)
						{
							if (!changedDifficulty) {
								Highscore.saveWeekScore(CoolUtil.formatSong(storyWeekID, difficultyID), campaignScore);
							}

							WeekData.weekCompleted.set(storyWeekID, true);

							FlxG.save.data.weekCompleted = WeekData.weekCompleted;
							FlxG.save.flush();
						}

						usedPractice = false;
						changedDifficulty = false;

						WeekData.loadTheFirstEnabledMod();
						FlxG.switchState(new StoryMenuState());
					}
					else
					{
						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;

						usedPractice = cpuControlled;

						if (changedDifficulty) {
							lastDifficulty = storyDifficulty;
						}

						switch (SONG.songID)
						{
							case 'eggnog': // no camFollow and camFollowPos so it centers on horror tree
							{
								inCutscene = true;

								var blackShit:FlxSprite = new FlxSprite(-FlxG.width * FlxG.camera.zoom, -FlxG.height * FlxG.camera.zoom);
								blackShit.makeGraphic(FlxG.width * 3, FlxG.height * 3, FlxColor.BLACK);
								blackShit.scrollFactor.set();
								add(blackShit);

								FlxG.sound.play(Paths.getSound('Lights_Shut_off'), 1, false, null, true, function():Void {
									nextSong(firstSong, difficultySuffix);
								});

								camHUD.visible = false;
							}
							default:
							{
								prevCamFollow = camFollow;
								prevCamFollowPos = camFollowPos;

								nextSong(firstSong, difficultySuffix);
							}
						}
					}
				}
				default:
				{
					usedPractice = false;
					changedDifficulty = false;

					cancelMusicFadeTween();

					CustomFadeTransition.nextCamera = camOther;

					if (FlxTransitionableState.skipNextTransIn) {
						CustomFadeTransition.nextCamera = null;
					}

					WeekData.loadTheFirstEnabledMod();

					if (!isStoryMode)
					{
						if (gameMode == 'freeplay')
						{
							FlxG.switchState(new FreeplayMenuState());
							return;
						}
						else if (gameMode == 'replay')
						{
							FlxG.switchState(new options.ReplaysMenuState());
							return;
						}
					}

					FlxG.switchState(new MainMenuState());
				}
			}
		}
	}

	public function nextSong(firstSong:String, difficultySuffix:String):Void
	{
		var ourPath:String = Paths.formatToSongPath(firstSong + difficultySuffix);
		Debug.logInfo('Loading next story song "' + ourPath + '"...');

		cancelMusicFadeTween();

		SONG = Song.loadFromJson(ourPath, firstSong);
		LoadingState.loadAndSwitchState(new PlayState(), true);
	}

	#if ACHIEVEMENTS_ALLOWED
	var achievementObj:AchievementObject = null;

	public function startAchievement(achieve:String):Void
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

	public var totalPlayed:Int = 0;
	public var totalNotesHit:Float = 0;

	public var showRating:Bool = true;
	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;

	public var ratingSuffix:String = '';
	public var numberSuffix:String = '';

	private function cachePopUpScore():Void
	{
		var pathsRatingShit:Array<String> = ['', 'ratings/'];

		if (isPixelStage)
		{
			ratingSuffix = '-pixel';
			numberSuffix = '-pixel';

			pathsRatingShit.insert(0, 'pixelUI/');
		}

		var ratingShit:Array<String> = [for (rating in ratingsData) if (rating != null && rating.image != null && rating.image.length > 0) rating.image];
		ratingShit.push('combo');

		for (sus in pathsRatingShit)
		{
			for (rat in ratingShit)
			{
				if (Paths.fileExists('images/' + sus + rat + ratingSuffix + '.png', IMAGE)) {
					precacheList.set(sus + rat + ratingSuffix, 'image');
				}
			}
		}

		var pathsNumberShit:Array<String> = ['', 'pixelUI', 'numbers/'];

		for (i in 0...10)
		{
			for (sus in pathsNumberShit)
			{
				if (Paths.fileExists('images/' + sus + 'num' + i + numberSuffix + '.png', IMAGE)) {
					precacheList.set(sus + 'num' + i + numberSuffix, 'image');
				}
			}
		}
	}

	private function cacheNoteSplashes():Void
	{
		var pathShit:String = 'notes/' + SONG.splashSkin;

		if (Paths.fileExists('images/' + SONG.splashSkin + '.png', IMAGE)) {
			pathShit = SONG.splashSkin;
		}
		if (Paths.fileExists('images/pixelUI/' + SONG.splashSkin + '.png', IMAGE) && isPixelStage) {
			pathShit = 'pixelUI/' + SONG.splashSkin;
		}
		if (Paths.fileExists('images/notes/pixel/' + SONG.splashSkin + '.png', IMAGE) && isPixelStage) {
			pathShit = 'notes/pixel/' + SONG.splashSkin;
		}

		if (Paths.fileExists('images/' + pathShit + '.xml', TEXT)) {
			Paths.getSparrowAtlas(pathShit);
		}
		else {
			Paths.getImage(pathShit);
		}

		var pathShit:String = 'notes/' + SONG.splashSkin2;

		if (Paths.fileExists('images/' + SONG.splashSkin2 + '.png', IMAGE)) {
			pathShit = SONG.splashSkin2;
		}
		if (Paths.fileExists('images/pixelUI/' + SONG.splashSkin2 + '.png', IMAGE) && isPixelStage) {
			pathShit = 'pixelUI/' + SONG.splashSkin2;
		}
		if (Paths.fileExists('images/notes/pixel/' + SONG.splashSkin2 + '.png', IMAGE) && isPixelStage) {
			pathShit = 'notes/pixel/' + SONG.splashSkin2;
		}

		if (Paths.fileExists('images/' + pathShit + '.xml', TEXT)) {
			Paths.getSparrowAtlas(pathShit);
		}
		else {
			Paths.getImage(pathShit);
		}
	}

	private function popUpScore(daNote:Note):Void
	{
		var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition + OptionData.ratingOffset);
		var daRating:Rating = Conductor.judgeNote(ratingsData, daNote, noteDiff / playbackRate);

		if (daRating.noteSplash && !daNote.noteSplashDisabled && !daNote.quickNoteSplash && !daNote.isSustainNote) {
			spawnNoteSplashOnNote(daNote);
		}

		daNote.rating = daRating.defaultName;
		daNote.ratingMod = daRating.ratingMod;

		if (!daNote.healthDisabled && daNote.healthDisabledOnGoodNoteHit)
		{
			if (daNote.isSustainNote)
			{
				if (Reflect.getProperty(daNote, 'hitHealth_' + daNote.parent.rating + '_sus') != null) {
					health += Reflect.getProperty(daNote, 'hitHealth_' + daNote.parent.rating + '_sus') * healthGain;
				}
			}
			else
			{
				if (Reflect.getProperty(daNote, 'hitHealth_' + daNote.rating) != null) {
					health += Reflect.getProperty(daNote, 'hitHealth_' + daNote.rating) * healthGain;
				}
			}
		}

		if (!practiceMode && !cpuControlled)
		{
			if (daNote.isSustainNote)
			{
				var daRatingSus:Rating = Conductor.getRatingByName(ratingsData, daNote.rating);

				songScore += Math.round(daRatingSus.score / 2);
				totalNotesHit += FlxG.random.float(daRatingSus.ratingMod - 0.5, daRatingSus.ratingMod - 0.25);
			}
			else
			{
				songScore += daRating.score;
				totalNotesHit += FlxG.random.float(daRating.ratingMod - 0.25, daRating.ratingMod);

				if (!daNote.ratingDisabled)
				{
					daRating.increase();
					totalPlayed++;
				}
			}
		}

		if (!daNote.isSustainNote)
		{
			var rating:RatingSprite = new RatingSprite(daRating.image, ratingSuffix);

			if (!OptionData.comboStacking)
			{
				if (lastRating != null)
				{
					lastRating.kill();
					grpRatings.remove(lastRating);
				}

				lastRating = rating;
			}

			if (showRating) {
				grpRatings.add(rating);
			}

			FlxTween.tween(rating, {alpha: 0}, 0.2 / playbackRate,
			{
				startDelay: Conductor.crochet * 0.001 / playbackRate,
				onComplete: function(twn:FlxTween):Void
				{
					rating.kill();
					grpRatings.remove(rating, true);
					rating.destroy();
				}
			});

			displayCombo();
		}

		if (!practiceMode && !cpuControlled) {
			RecalculateRating();
		}

		callOnLuas('onPopUpScore', [daNote.rating, notes.members.indexOf(daNote), Math.abs(daNote.noteData), daNote.noteType, daNote.isSustainNote]);
	}

	function displayCombo():Void
	{
		var comboSpr:ComboSprite = new ComboSprite(ratingSuffix);

		if (!OptionData.comboStacking)
		{
			if (lastCombo != null)
			{
				lastCombo.kill();
				grpCombo.remove(lastCombo);
			}

			lastCombo = comboSpr;
		}

		if (showCombo) {
			grpCombo.add(comboSpr);
		}

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2 / playbackRate,
		{
			startDelay: Conductor.crochet * 0.002 / playbackRate,
			onComplete: function(twn:FlxTween):Void
			{
				comboSpr.kill();
				grpCombo.remove(comboSpr, true);
				comboSpr.destroy();
			}
		});

		var seperatedScore:Array<Int> = [];
		var tempCombo:Int = combo;

		var stringCombo:String = '' + tempCombo;

		for (i in 0...stringCombo.length) {
			seperatedScore.push(Std.parseInt(stringCombo.charAt(i)));
		}

		while (seperatedScore.length < 3) {
			seperatedScore.insert(0, 0);
		}

		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				var ndumb:NumberSprite = lastScore[0];

				ndumb.kill();
				lastScore.remove(ndumb);
				grpNumbers.remove(ndumb);
			}
		}

		for (i in 0...seperatedScore.length)
		{
			var numScore:NumberSprite = new NumberSprite(seperatedScore[i], numberSuffix, i);

			if (showComboNum) {
				grpNumbers.add(numScore);
			}

			if (!OptionData.comboStacking) {
				lastScore.push(numScore);
			}

			FlxTween.tween(numScore, {alpha: 0}, 0.2 / playbackRate,
			{
				startDelay: Conductor.crochet * 0.002 / playbackRate,
				onComplete: function(twn:FlxTween):Void
				{
					numScore.kill();
					grpNumbers.remove(numScore, true);
					numScore.destroy();
				}
			});
		}
	}

	public var strumsBlocked:Array<Bool> = [];

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var noteData:Int = getDataFromKeyEvent(eventKey);

		if (!cpuControlled && !startingSong && startedCountdown && !paused && noteData > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || controls.controllerMode))
		{
			if (!boyfriend.stunned && generatedMusic && !endingSong)
			{
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !OptionData.ghostTapping;

				var pressNotes:Array<Note> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];

				notes.forEachAlive(function(daNote:Note):Void
				{
					if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
					{
						if (daNote.noteData == noteData) {
							sortedNotesList.push(daNote);
						}

						canMiss = true;
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
					callOnLuas('onGhostTap', [noteData]);

					if (canMiss && !inCutscene) {
						noteMissPress(noteData);
					}
				}

				keysPressed[noteData] = true;
				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[noteData];

			if (!strumsBlocked[noteData] && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}

			callOnLuas('onKeyPress', [noteData]);
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
		var noteData:Int = getDataFromKeyEvent(eventKey);

		if (!startingSong && !cpuControlled && startedCountdown && !paused && noteData > -1)
		{
			var spr:StrumNote = playerStrums.members[noteData];

			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}

			rep.replay.keyReleases.push({
				time: Conductor.songPosition,
				key: Note.pointers[noteData].toLowerCase()
			});

			callOnLuas('onKeyRelease', [noteData]);
		}
	}

	private function getDataFromKeyEvent(key:FlxKey):Int
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

		if (controls.controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
	
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] && !strumsBlocked[i]) {
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
				var achieve:String = checkForAchievement([Achievements.getAchievement('oversinging')]);

				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}
			else if (boyfriend.animation.curAnim != null && boyfriend.holdTimer > Conductor.stepCrochet * 0.0011 * boyfriend.singDuration && boyfriend.animation.curAnim.name.startsWith('sing') && !boyfriend.animation.curAnim.name.endsWith('miss')) {
				boyfriend.dance();
			}
		}

		if (controls.controllerMode || strumsBlocked.contains(true))
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

	public function noteMiss(daNote:Note):Void // You didn't hit the key and let it go offscreen, also used by Hurt Notes
	{
		notes.forEachAlive(function(note:Note):Void
		{
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 10)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		killCombo(daNote);

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

	public function noteMissPress(direction:Int = 1):Void // You pressed a key when there was no notes to press for this key
	{
		if (OptionData.ghostTapping) return; // fuck it

		if (!boyfriend.stunned)
		{
			if (boyfriend.hasMissAnimations) {
				boyfriend.playAnim(singAnimations[direction] + 'miss', true);
			}

			killCombo();
		}

		callOnLuas('noteMissPress', [direction]);
	}

	public function opponentNoteHit(daNote:Note):Void
	{
		if (SONG.songID != 'tutorial') {
			camZooming = true;
		}

		if (daNote.noteType == 'Hey!' && dad.animExists('hey'))
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
			var animToPlay:String = singAnimations[daNote.noteData] + altAnim;

			if (daNote.gfNote) {
				char = gf;
			}

			if (char != null)
			{
				char.playAnim(animToPlay, true);
				char.holdTimer = 0;
			}
		}

		var time:Float = 0.15;

		if (daNote != null && daNote.isSustainNote && daNote.animation.curAnim != null && !daNote.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}

		StrumPlayAnim(daNote.noteData, time / playbackRate);

		if (daNote.noteSplashHitByOpponent && !daNote.noteSplashDisabled && !daNote.isSustainNote) {
			spawnNoteSplashOnNote(daNote);
		}

		if (vocals != null) {
			vocals.volume = vocalsVolume;
		}

		daNote.hitByOpponent = true;

		callOnLuas('opponentNoteHit', [notes.members.indexOf(daNote), Math.abs(daNote.noteData), daNote.noteType, daNote.isSustainNote]);

		if (!daNote.isSustainNote)
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
				var animToPlay:String = singAnimations[note.noteData];

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
					if (boyfriend.animExists('hey'))
					{
						boyfriend.playAnim('hey', true);
						boyfriend.specialAnim = true;
						boyfriend.heyTimer = 0.6;
					}

					if (gf != null && gf.animExists('cheer'))
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
							if (boyfriend.animExists('hurt'))
							{
								boyfriend.playAnim('hurt', true);
								boyfriend.specialAnim = true;
							}
						}
					}
				}

				note.wasGoodHit = true;

				if (!note.isSustainNote)
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

			if (!note.healthDisabledOnGoodNoteHit) {
				health += note.hitHealth * healthGain;
			}

			if (!note.ignoreNote)
			{
				if (!note.isSustainNote)
				{
					songHits++;
					combo++;
				}

				popUpScore(note);
			}

			if (cpuControlled)
			{
				var time:Float = 0.15;

				if (note != null && note.isSustainNote && note.animation.curAnim != null && !note.animation.curAnim.name.endsWith('end')) {
					time += 0.15;
				}

				StrumPlayAnim(note.noteData + Note.maxNote, time);
			}
			else
			{
				var spr:StrumNote = playerStrums.members[note.noteData];

				if (spr != null) {
					spr.playAnim('confirm', true);
				}
			}

			if(gameMode != 'replay') {
				saveNotes.push(CoolUtil.floorDecimal(note.strumTime, 2));
				rep.replay.keyPresses.push({
					time: Conductor.songPosition,
					key: Note.pointers[note.noteData].toLowerCase()
				});
			}

			note.wasGoodHit = true;

			if (vocals != null) {
				vocals.volume = vocalsVolume;
			}

			var isSus:Bool = note.isSustainNote; // GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
			var leData:Int = Math.round(Math.abs(note.noteData));
			var leType:String = note.noteType;

			callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus]);

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}

		if (!practiceMode && !cpuControlled) {
			RecalculateRating();
		}
	}

	public function spawnNoteSplashOnNote(note:Note):Void
	{
		if (OptionData.splashOpacity > 0 && note != null)
		{
			var strum:StrumNote = null;

			if (note.noteSplashHitByOpponent)
				strum = opponentStrums.members[note.noteData];
			else
				strum = playerStrums.members[note.noteData];

			if (strum != null) {
				spawnNoteSplash(strum.x, strum.y, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, ?daNote:Note = null):Void
	{
		if (daNote == null) return;
		var skin:String = 'noteSplashes';

		if (daNote.mustPress)
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

		var data:Int = daNote.noteData;

		var hue:Float = OptionData.arrowHSV[data % Note.maxNote][0] / 360;
		var sat:Float = OptionData.arrowHSV[data % Note.maxNote][1] / 100;
		var brt:Float = OptionData.arrowHSV[data % Note.maxNote][2] / 100;

		if (data > -1 && data < OptionData.arrowHSV.length)
		{
			hue = OptionData.arrowHSV[data][0] / 360;
			sat = OptionData.arrowHSV[data][1] / 100;
			brt = OptionData.arrowHSV[data][2] / 100;

			if (daNote != null)
			{
				skin = daNote.noteSplashTexture;

				hue = daNote.noteSplashHue;
				sat = daNote.noteSplashSat;
				brt = daNote.noteSplashBrt;
			}
		}

		var splash:NoteSplash = new NoteSplash(x, y, data);
		splash.setupNoteSplash(x, y, data, skin, daNote.mustPress, daNote.isCustomHSB, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	var lightningStrikeBeat:Int = 0;
	var lightningOffset:Int = 8;

	function lightningStrikeShit():Void
	{
		FlxG.sound.play(Paths.getSoundRandom('thunder_', 1, 2));
		if (!OptionData.lowQuality) halloweenBG.animation.play('halloweem bg lightning strike');

		lightningStrikeBeat = curBeat;
		lightningOffset = FlxG.random.int(8, 24);

		if (boyfriend.animExists('scared')) {
			boyfriend.playAnim('scared', true);
		}

		if (gf != null && gf.animExists('scared')) {
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

	function trainStart():Void
	{
		trainMoving = true;

		if (!trainSound.playing) {
			trainSound.play(true);
		}
	}

	var startedMoving:Bool = false;

	function updateTrainPos():Void
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

	function trainReset():Void
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

	function resetFastCar():Void
	{
		fastCar.x = -12600;
		fastCar.y = FlxG.random.int(140, 250);
		fastCar.velocity.x = 0;
		fastCarCanDrive = true;
	}

	function killHenchmen():Void
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

				var achieve:String = checkForAchievement([Achievements.getAchievement('roadkill_enthusiast')]);

				if (achieve != null) {
					startAchievement(achieve);
				}
				#if debug
				Debug.logInfo('Deaths: ' + Achievements.henchmenDeath);
				#end
				#end
			}
		}
	}

	var carTimer:FlxTimer;

	function fastCarDrive():Void
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

	function resetLimoKill():Void
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

	var tankAngle:Float = FlxG.random.int(-90, 45);
	var tankSpeed:Float = FlxG.random.float(5, 7);
	var tankX:Float = 400;

	function moveTank(?elapsed:Float = 0):Void
	{
		if (!inCutscene)
		{
			var daAngleOffset:Float = 1;
			tankAngle += elapsed * tankSpeed;

			tankGround.angle = tankAngle - 90 + 15;
			tankGround.x = tankX + Math.cos(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1500;
			tankGround.y = 1300 + Math.sin(FlxAngle.asRadians((tankAngle * daAngleOffset) + 180)) * 1100;
		}
	}

	public override function destroy():Void
	{
		for (lua in luaArray)
		{
			lua.call('onDestroy', []);
			lua.stop();
		}

		luaArray = [];

		#if LUA_ALLOWED
		Lua_helper.callbacks.clear();
		#end

		#if (VIDEOS_ALLOWED && desktop)
		endBGVideo();
		#end

		#if hscript
		if (FunkinLua.hscript != null) FunkinLua.hscript = null;
		#end

		FlxAnimationController.globalSpeed = 1;

		if (!controls.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		FlxG.sound.music.pitch = 1;
		instance = null;

		super.destroy();
	}

	public static function cancelMusicFadeTween():Void
	{
		if (FlxG.sound.music.fadeTween != null) {
			FlxG.sound.music.fadeTween.cancel();
		}

		FlxG.sound.music.fadeTween = null;
	}

	var lastStepHit:Int = -1;

	public override function stepHit():Void
	{
		super.stepHit();

		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
			|| (SONG.needsVoices && vocals != null && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate))) {
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
			notes.sort(FlxSort.byY, downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
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

					if (phillyWindow != null && !OptionData.lowQuality)
					{
						phillyWindow.color = phillyLightsColors[curLight];
						lightFadeShader.reset();
					}
				}

				if (!OptionData.lowQuality && curBeat % 8 == 4 && FlxG.random.bool(30) && !trainMoving && trainCooldown > 8)
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
				if (!OptionData.lowQuality)
				{
					upperBoppers.dance(true);
					if (heyTimer <= 0) bottomBoppers.dance(true);
				}

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
				if (!OptionData.lowQuality) tankWatchtower.dance();

				foregroundSprites.forEach(function(spr:BGSprite):Void {
					spr.dance();
				});
			}
		}

		try
		{
			if (boomSpeed != 4 && curBeat % boomSpeed == 0) {
				triggerEventNote("Add Camera Zoom", Std.string(0.015 * bamVal), Std.string(0.03 * bamVal));
			}
		}
		catch (e:Dynamic) {
			Debug.logError('error: ' + e);
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
			if (generatedMusic && !blockedCameraMovement && !endingSong && !isCameraOnForcedPos) {
				cameraMovementSection();
			}

			if (OptionData.camZooms && camZooming && FlxG.camera.zoom < 1.35)
			{
				FlxG.camera.zoom += 0.015 * camZoomingMult;
				camHUD.zoom += 0.03 * camZoomingMult;
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

	public function StrumPlayAnim(isDad:Null<Bool> = null, id:Int, time:Float):Void
	{
		if (isDad == null) isDad = id < Note.maxNote;
		var spr:StrumNote = null;

		if (isDad) {
			spr = opponentStrums.members[id % Note.maxNote];
		}
		else {
			spr = playerStrums.members[id % Note.maxNote];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	#if (VIDEOS_ALLOWED && desktop)
	public var bgVideoSprite:VideoSprite = null;
	#end

	public function backgroundVideo(path:String, ?loop:Bool = false):Void
	{
		#if (VIDEOS_ALLOWED && desktop)
		var newpath:String = Paths.getVideo(path);

		if (Paths.fileExists(newpath, BINARY, true))
		{
			endBGVideo();
			createBGVideo(path, loop, true);

			var spr:Dynamic = (cast bgVideoSprite);
			var ourVal:Float = 1 / defaultCamZoom;
			spr.scale.set(ourVal, ourVal);
			insert(members.indexOf(camFollowPos), spr);
			return;
		}

		Debug.logWarn('Couldnt find video file: ' + newpath);
		#else
		Debug.logWarn('Platform not supported!');
		#end
	}

	public function makeBackgroundTheVideo(path:String, ?loop:Bool = false, ?pos:Dynamic = 'gf'):Void
	{
		#if (VIDEOS_ALLOWED && desktop)
		var newpath:String = Paths.getVideo(path);

		if (Paths.fileExists(newpath, BINARY, true))
		{
			endBGVideo();
			createBGVideo(path, loop, false, pos);

			var spr:Dynamic = (cast bgVideoSprite);

			var ourVal:Float = 1 / defaultCamZoom;
			spr.scale.set(ourVal, ourVal);

			switch (pos)
			{
				case 'before' | 'in front of' | 'afore' | 'ere' | 'front' | 'head' | true | 'true': {
					add(spr);
				}
				case 'dad' | 'opponent' | 1 | '1': {
					addBehindDad(spr);
				}
				case 'bf' | 'boyfriend' | 0 | '0': {
					addBehindBF(spr);
				}
				default:
				{
					if (pos == 'behind' || pos == 'posteriorly' || pos == 'aback' || pos == 'after' ||
						pos == 'abaft' || pos == false || pos == 'false' || pos == 'back from' || pos == 'no before' ||
						pos == 'no in front of' || pos == 'no afore' || pos == 'no ere' || pos == 'no front' ||
						pos == 'no head' || pos == 'gf' || pos == 'girlfriend' || pos == '2' || pos == 2) {
						addBehindGF(spr);
					}
				}
			}

			return;
		}

		Debug.logWarn('Couldnt find video file: ' + path);
		#else
		Debug.logWarn('Platform not supported!');
		#end
	}

	private function createBGVideo(path:String, ?loop:Bool = false, ?hud:Bool = false, ?pos:Dynamic = null):Void
	{
		#if (VIDEOS_ALLOWED && desktop)
		var newPath:String = Paths.getVideo(path);

		if (newPath.contains(':')) {
			newPath = newPath.substring(newPath.indexOf(':') + 1, newPath.length);
		}

		// extension webm is no longer needed
		// why? because volume for SampleDataEvent is very hardy for me
		/*if (newPath.endsWith('.webm')) {
			bgVideoSprite = new WebmSprite();
		}
		else {*/
			bgVideoSprite = new MP4Sprite();
		//}

		var spr:Dynamic = (cast bgVideoSprite);
		spr.playVideo(newPath, loop);
		#if (hxCodec >= "2.6.0")
		if (Std.isOfType(spr, MP4Sprite)) {
			spr.bitmap.canSkip = false;
		}
		#end
		spr.scrollFactor.set();
		spr.updateHitbox();
		spr.finishCallback = function():Void
		{
			if (loop)
			{
				if (hud) {
					backgroundVideo(path, loop);
				}
				else {
					makeBackgroundTheVideo(path, loop, pos);
				}
			}
			else
			{
				callOnLuas('onFinishBGVideo', [path]);

				remove(spr);
				spr = null;
			}
		}
		#else
		Debug.logWarn('Platform not supported!');
		#end
	}

	public function endBGVideo():Void
	{
		#if (VIDEOS_ALLOWED && desktop)
		if (bgVideoSprite != null)
		{
			var spr:Dynamic = (cast bgVideoSprite);

			if (Std.isOfType(spr, MP4Sprite))
			{
				#if (hxCodec >= "2.6.0")
				spr.bitmap.stop();
				#else
				@:privateAccess
				spr.video.stop();
				#end
			}
			else
			{
				if (spr.handler != null) {
					spr.handler.stop();
				}
			}

			spr.kill();
			remove(spr);
			spr = null;
		}
		#else
		Debug.logWarn('Platform not supported!');
		#end
	}

	#if LUA_ALLOWED
	public function startLuasOnFolder(luaFile:String) {
		for(script in luaArray) {
			if (script.scriptName == luaFile) return false;
		}
		var luaToLoad=Paths.getLua(luaFile);
		if(Paths.fileExists(luaToLoad, TEXT, true)) {
			luaArray.push(new FunkinLua(luaToLoad));
			return true;
		}
		return false;
	}
	#end

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

	public var ratingName:String = 'N/A';
	public var ratingPercent:Float = 0;
	public var ratingFC:String;

	public function RecalculateRating(badHit:Bool = false):Void
	{
		setOnLuas('score', songScore);
		setOnLuas('misses', songMisses);
		setOnLuas('hits', songHits);

		var ret:Dynamic = callOnLuas('onRecalculateRating', [badHit], false);

		if (ret != FunkinLua.Function_Stop)
		{
			if (totalPlayed < 1) {
				ratingName = 'N/A';
			}
			else
			{
				songAccuracy = Math.min(1, Math.max(0, totalNotesHit / totalPlayed)) * 100;
				ratingPercent = songAccuracy / 100;

				if (songAccuracy >= 100) {
					ratingName = ratingStuff[ratingStuff.length - 1][0]; // Uses last string
				}
				else
				{
					for (i in 0...ratingStuff.length - 1)
					{
						if (songAccuracy < ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			ratingFC = '';

			if (sicks > 0) ratingFC = 'SFC';
			if (goods > 0) ratingFC = 'GFC';
			if (bads > 0 || shits > 0) ratingFC = 'FC';

			if (songMisses > 0 && songMisses < 10) ratingFC = 'SDCB';
			else if (songMisses >= 10) ratingFC = 'Clear';
		}

		updateScore(badHit); // score will only update after rating is calculated, if it's a badHit, it shouldn't bounce -Ghost

		setOnLuas('accuracy', songAccuracy);
		setOnLuas('rating', songAccuracy / 100);
		setOnLuas('ratingName', ratingName);
		setOnLuas('ratingFC', ratingFC);
	}

	#if ACHIEVEMENTS_ALLOWED
	public function checkForAchievement(include:Array<Achievement> = null, exclude:Array<Achievement> = null):String
	{
		if (chartingMode) return null;
		var achievesToCheck:Array<Achievement>=[];
		for(i in Achievements.achievementsStuff) {
			achievesToCheck.push(i);
		}
		if(include != null && include.length > 0) {
			achievesToCheck = include;
		}
		if(exclude != null && exclude.length > 0) {
			for(exclude in exclude) { // lol
				achievesToCheck.remove(exclude);
			}
		}
		for(award in achievesToCheck) {
			if(award != null) {
				var achievementName:String=award.save_tag;
				if(!Achievements.isAchievementUnlocked(achievementName) && !cpuControlled && Achievements.exists(achievementName)) {
					var unlock:Bool = false;
					if((isStoryMode && award.week_nomiss == storyWeekID) || (award.song == SONG.songID)) {
						var diff:String = CoolUtil.difficultyStuff[storyDifficulty][0];
						if(!usedPractice && (award.diff == diff || award.diff == null || award.diff.length < 1)) {
							var isNoMisses:Bool = true;
							if(award.misses > -1) {
								isNoMisses = campaignMisses + songMisses < award.misses + 1;
							}
							if(!changedDifficulty && isNoMisses) {
								if(storyPlaylist.length < 2 || !isStoryMode) {
									//unlock = true;
									Achievements.unlockAchievement(achievementName);
									return achievementName;
								}
							}
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
						default:
						{
							var ret:Dynamic = callOnLuas('onCheckForAchievement', [achievementName, award.song, award.week_nomiss, award.misses, award.diff, award.lua_code, award.hidden], true);
							unlock = ret == true && ret != FunkinLua.Function_Continue && ret != FunkinLua.Function_Stop && ret != FunkinLua.Function_StopLua;
						}
					}

					if (unlock)
					{
						Achievements.unlockAchievement(achievementName);
						return achievementName;
					}
				}
			}
		}

		return null;
	}
	#end
}