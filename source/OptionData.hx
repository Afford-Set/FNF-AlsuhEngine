package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.math.FlxMath;
import flixel.input.keyboard.FlxKey;
import flixel.input.gamepad.FlxGamepadInputID;

using StringTools;

class OptionData
{
	public static var gameplaySettings:Map<String, Dynamic> =
	[
		'scrollspeed' => 1.0,
		'scrolltype' => 'multiplicative', 
		// anyone reading this, amod is multiplicative speed mod, cmod is constant speed mod, and xmod is bpm based speed mod.
		// an amod example would be chartSpeed * multiplier
		// cmod would just be constantSpeed = chartSpeed
		// and xmod basically works by basing the speed on the bpm.
		// iirc (beatsPerSecond * (conductorToNoteDifference / 1000)) * noteSize (110 or something like that depending on it, prolly just use note.height)
		// bps is calculated by bpm / 60
		// oh yeah and you'd have to actually convert the difference to seconds which I already do, because this is based on beats and stuff. but it should work
		// just fine. but I wont implement it because I don't know how you handle sustains and other stuff like that.
		// oh yeah when you calculate the bps divide it by the songSpeed or rate because it wont scroll correctly when speeds exist.
		'songspeed' => 1.0,
		'randomnotes' => false,
		'healthgain' => 1.0,
		'healthloss' => 1.0,
		'instakill' => false,
		'practice' => false,
		'botplay' => false,
		'opponentplay' => false
	];

	public static var fullScreen:Bool = false;
	#if windows
	public static var screenRes:String = '1280x720';
	#end
	public static var lowQuality:Bool = false;

	public static var globalAntialiasing:Bool = true;
	public static var shaders:Bool = true;
	public static var framerate:Int = 60;

	public static var loadingOggFiles:Bool = false;
	public static var loadingWavFiles:Bool = false;

	public static var ghostTapping:Bool = true;
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var opponentStrums:Bool = true;
	public static var hitsoundType:String = 'Kade';
	public static var hitsoundVolume:Float = 0;
	public static var noReset:Bool = false;
	public static var ratingOffset:Int = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var shitWindow:Int = 160;
	public static var comboStacking:Bool = true;
	public static var coloredHealthBar:Bool = true;
	public static var safeFrames:Float = 10;
	public static var noteOffset:Int = 0;

	public static var camZooms:Bool = true;
	public static var camShakes:Bool = true;

	public static var cutscenesInType:String = 'Story';
	public static var skipCutscenes:Bool = true;

	public static var iconZooms:Bool = true;
	public static var splashOpacity:Float = 0.6;
	public static var danceOffset:Int = 2;
	public static var timeBarType:String = 'Time Left and Elapsed';
	public static var scoreText:Bool = true;
	public static var naughtyness:Bool = true;

	public static var showRatings:Bool = true;
	public static var showNumbers:Bool = true;

	public static var healthBarAlpha:Float = 1;
	public static var pauseMusic:String = 'Tea Time';
	#if !mobile
	public static var fpsCounter:Bool = false;
	#if !hl
	public static var memoryCounter:Bool = false;
	#end
	#end
	#if CHECK_FOR_UPDATES
	public static var checkForUpdates:Bool = true;
	#end
	public static var autoPause:Bool = false;
	public static var watermarks:Bool = true;
	public static var loadingScreen:Bool = true;
	public static var flashingLights:Bool = true;

	public static var comboOffset:Array<Null<Int>> = [0, 0, 0, 0, 0, 0];
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];

	public static var hideHud(get, never):Bool;

	static function get_hideHud():Bool return !scoreText && healthBarAlpha < FlxMath.EPSILON && !showRatings && !showNumbers;

	private static var importantMap:Map<String, Array<String>> =
	[
		'saveBlackList' => ['keyBinds', 'defaultKeys', 'hideHud'],
		'flixelSound' => ['volume', 'muted'],
		'loadBlackList' => ['keyBinds', 'defaultKeys', 'hideHud', 'loadCtrls', 'saveCtrls', 'gameplaySettings'],
	];

	public static function savePrefs():Void
	{
		FlxG.save.bind('alsuh-engine', CoolUtil.getSavePath());

		for (field in Type.getClassFields(OptionData))
		{
			if (Type.typeof(Reflect.getProperty(OptionData, field)) != TFunction)
			{
				if (!importantMap.get('saveBlackList').contains(field)) {
					Reflect.setProperty(FlxG.save.data, field, Reflect.getProperty(OptionData, field));
				}
			}
		}

		for (flixelS in importantMap.get('flixelSound')) {
			Reflect.setProperty(FlxG.save.data, flixelS, Reflect.getProperty(FlxG.sound, flixelS));
		}

		FlxG.save.flush();
	}

	public static function loadPrefs():Void
	{
		FlxG.save.bind('alsuh-engine', CoolUtil.getSavePath());

		for (field in Type.getClassFields(OptionData))
		{
			if (Type.typeof(Reflect.getProperty(OptionData, field)) != TFunction)
			{
				if (!importantMap.get('loadBlackList').contains(field))
				{
					var defaultValue:Dynamic = Reflect.getProperty(OptionData, field);
					var valueFromSave:Dynamic = Reflect.getProperty(FlxG.save.data, field);

					var value:Dynamic = (valueFromSave != null ? valueFromSave : defaultValue);
					Reflect.setProperty(OptionData, field, value); // classic

					switch (field)
					{
						case 'fullScreen': {
							FlxG.fullscreen = fullScreen;
						}
						#if windows
						case 'screenRes':
						{
							var res:Array<String> = screenRes.split('x');
							FlxG.resizeWindow(Std.parseInt(res[0]), Std.parseInt(res[1]));
					
							FlxG.fullscreen = false;
					
							if (!FlxG.fullscreen) {
								FlxG.fullscreen = fullScreen;
							}
						}
						#end
						#if !html5
						case 'framerate':
						{
							if (framerate > FlxG.drawFramerate)
							{
								FlxG.updateFramerate = framerate;
								FlxG.drawFramerate = framerate;
							}
							else
							{
								FlxG.drawFramerate = framerate;
								FlxG.updateFramerate = framerate;
							}
						}
						#end
						case 'opponentStrums':
						{
							if (FlxG.save.data.cpuStrumsType != null)
							{
								FlxG.save.data.opponentStrumsType = FlxG.save.data.cpuStrumsType;
								FlxG.save.data.cpuStrumsType = null;
					
								FlxG.save.flush();
							}

							if (FlxG.save.data.opponentStrumsType != null)
							{
								if (FlxG.save.data.opponentStrumsType == 'Light Up')
								{
									FlxG.save.data.opponentStrumsType = 'Glow';
									FlxG.save.flush();
								}
					
								if (FlxG.save.data.opponentStrumsType == 'Normal')
								{
									FlxG.save.data.opponentStrumsType = 'Static';
									FlxG.save.flush();
								}

								opponentStrums = FlxG.save.data.opponentStrumsType == 'Glow' || FlxG.save.data.opponentStrumsType == 'Static';
								FlxG.save.data.opponentStrumsType = null;
							}
						}
						case 'timeBarType':
						{
							if (FlxG.save.data.songPositionType != null)
							{
								if (FlxG.save.data.songPositionType == 'Multiplicative')
								{
									FlxG.save.data.songPositionType = 'Time Left and Elapsed';
									FlxG.save.flush();
								}
					
								timeBarType = FlxG.save.data.songPositionType;
								FlxG.save.data.songPositionType = null;
								FlxG.save.flush();
							}
						}
						case 'splashOpacity':
						{
							if (FlxG.save.data.noteSplashes != null)
							{
								FlxG.save.data.splashOpacity = FlxG.save.data.noteSplashes ? 0.6 : 0;
								FlxG.save.data.noteSplashes = null;

								FlxG.save.data.splashOpacity = splashOpacity;
								FlxG.save.flush();
							}
						}
						case 'autoPause': {
							FlxG.autoPause = autoPause;
						}
						case 'comboOffset':
						{
							if (comboOffset[4] == null || comboOffset[4] < 0) {
								comboOffset[4] = 0;
							}

							if (comboOffset[5] == null || comboOffset[5] < 0) {
								comboOffset[5] = 0;
							}
						}
					}
				}
			}
		}

		if (FlxG.save.data.gameplaySettings != null)
		{
			var savedMap:Map<String, Dynamic> = FlxG.save.data.gameplaySettings;

			for (name => value in savedMap) {
				gameplaySettings.set(name, value);
			}
		}

		for (flixelS in importantMap.get('flixelSound'))
		{
			var valueFromSave:Dynamic = Reflect.getProperty(FlxG.save.data, flixelS);

			if (valueFromSave != null) {
				Reflect.setProperty(FlxG.sound, flixelS, valueFromSave);
			}
		}
	}

	public static var luaPrefsMap:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();

	public static function loadLuaPrefs():Void
	{
		luaPrefsMap.clear();

		luaPrefsMap.set('ratingOffset', [['ratingOffset'], ratingOffset]);
		luaPrefsMap.set('noteSplashes', [['noteSplashes'], splashOpacity > 0]);
		luaPrefsMap.set('splashOpacity', [['splashOpacity'], splashOpacity]);
		luaPrefsMap.set('naughtyness', [['naughtyness'], naughtyness]);
		luaPrefsMap.set('safeFrames', [['safeFrames'], safeFrames]);
		luaPrefsMap.set('downScroll', [['downScroll', 'downscroll'], downScroll]);
		luaPrefsMap.set('danceOffset', [['danceOffset'], danceOffset]);
		luaPrefsMap.set('pauseMusic', [['pauseMusic'], pauseMusic]);
		luaPrefsMap.set('middleScroll', [['middlescroll', 'middlescroll'], middleScroll]);
		#if !html5
		luaPrefsMap.set('framerate', [['framerate'], framerate]);
		#end
		luaPrefsMap.set('hideHud', [['hideHud'], hideHud]);
		luaPrefsMap.set('ghostTapping', [['ghostTapping'], ghostTapping]);
		luaPrefsMap.set('scoreText', [['scoreText'], scoreText]);
		luaPrefsMap.set('showRatings', [['showRatings'], showRatings]);
		luaPrefsMap.set('showNumbers', [['showNumbers'], showNumbers]);
		luaPrefsMap.set('timeBarType', [['timeBarType'], timeBarType]);
		luaPrefsMap.set('camZooms', [['camZooms', 'cameraZoomOnBeat'], camZooms]);
		luaPrefsMap.set('camShakes', [['cameraShakes'], camShakes]);
		luaPrefsMap.set('iconZooms', [['iconZooms'], iconZooms]);
		luaPrefsMap.set('flashingLights', [['flashingLights'], flashingLights]);
		luaPrefsMap.set('noteOffset', [['noteOffset'], noteOffset]);
		luaPrefsMap.set('healthBarAlpha', [['healthBarAlpha'], healthBarAlpha]);
		luaPrefsMap.set('noReset', [['noResetButton'], noReset]);
		luaPrefsMap.set('lowQuality', [['lowQuality'], lowQuality]);
		luaPrefsMap.set('sickWindow', [['sickWindow'], sickWindow]);
		luaPrefsMap.set('goodWindow', [['goodWindow'], goodWindow]);
		luaPrefsMap.set('badWindow', [['badWindow'], badWindow]);
		luaPrefsMap.set('shitWindow', [['shitWindow'], shitWindow]);
		luaPrefsMap.set('opponentStrums', [['opponentStrums'], opponentStrums]);
		luaPrefsMap.set('shaders', [['shadersEnabled', 'shaders'], shaders]);
	}

	public static var keyBinds:Map<String, Array<FlxKey>> =
	[
		'note_left'		=> [A, LEFT],
		'note_down'		=> [S, DOWN],
		'note_up'		=> [W, UP],
		'note_right'	=> [D, RIGHT],

		'ui_left'		=> [A, LEFT],
		'ui_down'		=> [S, DOWN],
		'ui_up'			=> [W, UP],
		'ui_right'		=> [D, RIGHT],

		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		'reset'			=> [R],

		'volume_mute'	=> [ZERO],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],

		'debug_1'		=> [SEVEN],
		'debug_2'		=> [EIGHT]
	];

	public static var gamepadBinds:Map<String, Array<FlxGamepadInputID>> =
	[
		'note_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT, X],
		'note_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN, A],
		'note_up'		=> [DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP, Y],
		'note_right'	=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT, B],

		'ui_up'			=> [DPAD_UP, LEFT_STICK_DIGITAL_UP],
		'ui_left'		=> [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
		'ui_down'		=> [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
		'ui_right'		=> [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],

		'accept'		=> [A, START],
		'back'			=> [B],
		'pause'			=> [START],
		'reset'			=> [8]
	];

	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys():Void
	{
		defaultKeys = keyBinds.copy();
	}

	public static function saveCtrls():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('controls_v4', CoolUtil.getSavePath());
		save.data.keyboard = keyBinds;
		save.data.gamepad = gamepadBinds;
		save.flush();
	}

	public static function loadCtrls():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('controls_v4', CoolUtil.getSavePath());

		if (save != null)
		{
			if (save.data.keyboard != null)
			{
				var loadedControls:Map<String, Array<FlxKey>> = save.data.keyboard;

				for (control => keys in loadedControls) {
					keyBinds.set(control, keys);
				}
			}

			if (save.data.gamepad != null)
			{
				var loadedControls:Map<String, Array<FlxGamepadInputID>> = save.data.gamepad;

				for (control => keys in loadedControls) {
					gamepadBinds.set(control, keys);
				}
			}
		}

		reloadControls();
	}

	public static function reloadControls():Void
	{
		TitleState.muteKeys = keyBinds.get('volume_mute').copy();
		TitleState.volumeDownKeys = keyBinds.get('volume_down').copy();
		TitleState.volumeUpKeys = keyBinds.get('volume_up').copy();
	}

	public static function getGameplaySetting(name:String, defaultValue:Dynamic):Dynamic
	{
		return gameplaySettings.exists(name) ? gameplaySettings.get(name) : defaultValue;
	}
}