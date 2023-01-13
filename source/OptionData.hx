package;

import flixel.FlxG;
import flixel.util.FlxSave;
import flixel.input.keyboard.FlxKey;

import Controls;

using StringTools;

class OptionData
{
	public static var fullScreen:Bool = false;
	#if !web
	public static var screenRes:String = '1280x720';
	#end
	public static var lowQuality:Bool = false;
	public static var globalAntialiasing:Bool = true;
	public static var shaders:Bool = true;
	#if !html5
	public static var framerate:Int = 60;
	#end

	public static var ghostTapping:Bool = true;
	public static var controllerMode:Bool = false;
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;
	public static var opponentStrumsType:String = 'Glow';
	public static var hitsoundType:String = 'Kade';
	public static var hitsoundVolume:Float = 0;
	public static var noReset:Bool = false;
	public static var ratingOffset:Int = 0;
	public static var sickWindow:Int = 45;
	public static var goodWindow:Int = 90;
	public static var badWindow:Int = 135;
	public static var shitWindow:Int = 160;
	public static var comboStacking:Bool = true;
	public static var safeFrames:Float = 10;
	public static var noteOffset:Int = 0;

	public static var camZooms:Bool = true;
	public static var camShakes:Bool = true;

	public static var cutscenesInType:String = 'Story';
	public static var skipCutscenes:Bool = true;

	public static var iconZooms:Bool = true;
	public static var sustainsType:String = 'New';
	public static var splashOpacity:Float = 0.6;
	public static var danceOffset:Int = 2;
	public static var songPositionType:String = 'Time Left and Elapsed';
	public static var scoreText:Bool = true;
	public static var naughtyness:Bool = true;

	public static var showRatings:Bool = true;
	public static var showNumbers:Bool = true;

	public static var healthBarAlpha:Float = 1;
	public static var pauseMusic:String = 'Tea Time';
	#if !mobile
	public static var fpsCounter:Bool = false;
	public static var rainFPS:Bool = false;
	public static var memoryCounter:Bool = false;
	public static var rainMemory:Bool = false;
	#end
	#if CHECK_FOR_UPDATES
	public static var checkForUpdates:Bool = true;
	#end
	public static var autoPause:Bool = false;
	public static var watermarks:Bool = true;
	public static var loadingScreen:Bool = #if NO_PRELOAD_ALL true #else false #end;
	public static var flashingLights:Bool = true;

	public static var comboOffset:Array<Int> = [0, 0, 0, 0];
	public static var arrowHSV:Array<Array<Int>> = [[0, 0, 0], [0, 0, 0], [0, 0, 0], [0, 0, 0]];

	private static var importantMap:Map<String, Array<String>> =
	[
		"saveBlackList" => ["keyBinds", "defaultKeys"],
		"saveAchievements" => ["achievementsMap", "henchmenDeath"],
		"flixelSound" => ["volume", "sound"],
		"loadBlackList" => ["keyBinds", "defaultKeys", "loadCtrls", "saveCtrls"],
	];

	public static function savePrefs():Void
	{
		FlxG.save.bind('alsuh-engine', CoolUtil.getSavePath());

		for (field in Type.getClassFields(OptionData))
		{
			if (Type.typeof(Reflect.field(OptionData, field)) != TFunction)
			{
				if (!importantMap.get("saveBlackList").contains(field)) {
					Reflect.setField(FlxG.save.data, field, Reflect.field(OptionData, field));
				}
			}
		}

		for (achievement in importantMap.get("saveAchievements")) {
			Reflect.setField(FlxG.save.data, achievement, Reflect.field(Achievements, achievement));
		}

		for (flixelS in importantMap.get("flixelSound")) {
			Reflect.setField(FlxG.save.data, flixelS, Reflect.field(FlxG.sound, flixelS));
		}

		for (flixelS in importantMap.get("flixelSound"))
		{
			var flxProp:Dynamic = Reflect.field(FlxG.save.data, flixelS);

			if (flxProp != null) {
				Reflect.setProperty(FlxG.sound, flixelS, flxProp);
			}
		}
	}

	public static function loadPrefs():Void
	{
		FlxG.save.bind('alsuh-engine', CoolUtil.getSavePath());

		for (field in Type.getClassFields(OptionData))
		{
			if (Type.typeof(Reflect.field(OptionData, field)) != TFunction)
			{
				if (!importantMap.get("loadBlackList").contains(field))
				{
					var defaultValue:Dynamic = Reflect.field(OptionData, field);
					var flxProp:Dynamic = Reflect.field(FlxG.save.data, field);

					Reflect.setField(OptionData, field, (flxProp != null ? flxProp : defaultValue));

					switch (field)
					{
						case 'fullScreen':
						{
							FlxG.fullscreen = fullScreen;
						}
						#if !web
						case 'screenRes':
						{
							var res:Array<String> = OptionData.screenRes.split('x');
							FlxG.resizeWindow(Std.parseInt(res[0]), Std.parseInt(res[1]));
					
							FlxG.fullscreen = false;
					
							if (!FlxG.fullscreen) {
								FlxG.fullscreen = OptionData.fullScreen;
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
						case 'opponentStrumsType':
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

								opponentStrumsType = FlxG.save.data.opponentStrumsType;
							}
						}
						case 'songPositionType':
						{
							if (FlxG.save.data.songPositionType != null)
							{
								if (FlxG.save.data.songPositionType == 'Multiplicative')
								{
									FlxG.save.data.songPositionType = 'Time Left and Elapsed';
									FlxG.save.flush();
								}
					
								songPositionType = FlxG.save.data.songPositionType;
							}
						}
						case 'splashOpacity':
						{
							if (FlxG.save.data.noteSplashes != null)
							{
								splashOpacity = FlxG.save.data.noteSplashes ? 0.6 : 0;
								FlxG.save.data.noteSplashes = null;

								FlxG.save.data.splashOpacity = splashOpacity;
								FlxG.save.flush();
							}
						}
						#if !mobile
						case 'fpsCounter':
						{
							if (Main.fpsCounter != null) {
								Main.fpsCounter.visible = fpsCounter;
							}
						}
						case 'memoryCounter':
						{
							if (Main.memoryCounter != null) {
								Main.memoryCounter.visible = memoryCounter;
							}
						}
						#end
						case 'autoPause':
						{
							FlxG.autoPause = autoPause;
						}
					}
				}
			}
		}
	}

	public static var luaPrefsMap:Map<String, Array<Dynamic>> = new Map<String, Array<Dynamic>>();

	public static function loadLuaPrefs():Void
	{
		luaPrefsMap.clear();

		luaPrefsMap.set('ratingOffset', ['ratingOffset', OptionData.ratingOffset]);
		luaPrefsMap.set('noteSplashes', ['noteSplashes', OptionData.splashOpacity > 0]);
		luaPrefsMap.set('splashOpacity', ['splashOpacity', OptionData.splashOpacity]);
		luaPrefsMap.set('naughtyness', ['naughtyness', OptionData.naughtyness]);
		luaPrefsMap.set('safeFrames', ['safeFrames', OptionData.safeFrames]);
		luaPrefsMap.set('downScroll', ['downscroll', OptionData.downScroll]);
		luaPrefsMap.set('danceOffset', ['danceOffset', OptionData.danceOffset]);
		luaPrefsMap.set('pauseMusic', ['pauseMusic', OptionData.pauseMusic]);
		luaPrefsMap.set('middleScroll', ['middlescroll', OptionData.middleScroll]);
		#if !html5
		luaPrefsMap.set('framerate', ['framerate', OptionData.framerate]);
		#end
		luaPrefsMap.set('ghostTapping', ['ghostTapping', OptionData.ghostTapping]);
		luaPrefsMap.set('scoreText', ['scoreText', OptionData.scoreText]);
		luaPrefsMap.set('showRatings', ['showRatings', OptionData.showRatings]);
		luaPrefsMap.set('showNumbers', ['showNumbers', OptionData.showNumbers]);
		luaPrefsMap.set('songPositionType', ['songPositionType', OptionData.songPositionType]);
		luaPrefsMap.set('camZooms', ['camZooms', OptionData.camZooms]);
		luaPrefsMap.set('camZooms', ['cameraZoomOnBeat', OptionData.camZooms]);
		luaPrefsMap.set('camShakes', ['cameraShakes', OptionData.camShakes]);
		luaPrefsMap.set('iconZooms', ['iconZooms', OptionData.iconZooms]);
		luaPrefsMap.set('flashingLights', ['flashingLights', OptionData.flashingLights]);
		luaPrefsMap.set('flashingLights', ['flashing', OptionData.flashingLights]);
		luaPrefsMap.set('noteOffset', ['noteOffset', OptionData.noteOffset]);
		luaPrefsMap.set('healthBarAlpha', ['healthBarAlpha', OptionData.healthBarAlpha]);
		luaPrefsMap.set('noReset', ['noResetButton', OptionData.noReset]);
		luaPrefsMap.set('lowQuality', ['lowQuality', OptionData.lowQuality]);
		luaPrefsMap.set('sickWindow', ['sickWindow', OptionData.sickWindow]);
		luaPrefsMap.set('goodWindow', ['goodWindow', OptionData.goodWindow]);
		luaPrefsMap.set('badWindow', ['badWindow', OptionData.badWindow]);
		luaPrefsMap.set('shitWindow', ['shitWindow', OptionData.shitWindow]);
		luaPrefsMap.set('opponentStrumsType', ['opponentStrumsType', OptionData.opponentStrumsType]);
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

		'reset'			=> [R, NONE],
		'accept'		=> [SPACE, ENTER],
		'back'			=> [BACKSPACE, ESCAPE],
		'pause'			=> [ENTER, ESCAPE],
		
		'volume_mute'	=> [ZERO, NONE],
		'volume_up'		=> [NUMPADPLUS, PLUS],
		'volume_down'	=> [NUMPADMINUS, MINUS],
		
		'debug_1'		=> [SEVEN, NONE],
		'debug_2'		=> [EIGHT, NONE]
	];

	public static var defaultKeys:Map<String, Array<FlxKey>> = null;

	public static function loadDefaultKeys():Void
	{
		defaultKeys = keyBinds.copy();
	}

	public static function saveCtrls():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());
		save.data.keyBinds = keyBinds;
		save.flush();
	}

	public static function loadCtrls():Void
	{
		var save:FlxSave = new FlxSave();
		save.bind('controls_v3', CoolUtil.getSavePath());

		if (save != null && save.data.keyBinds != null)
		{
			var loadedControls:Map<String, Array<FlxKey>> = save.data.keyBinds;

			for (control => keys in loadedControls) {
				keyBinds.set(control, keys);
			}
		}

		reloadControls();
	}

	public static function reloadControls():Void
	{
		PlayerSettings.player1.controls.setKeyboardScheme(KeyboardScheme.Solo);

		TitleState.muteKeys = copyKey(keyBinds.get('volume_mute'));
		TitleState.volumeDownKeys = copyKey(keyBinds.get('volume_down'));
		TitleState.volumeUpKeys = copyKey(keyBinds.get('volume_up'));

		FlxG.sound.muteKeys = TitleState.muteKeys;
		FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
		FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;
	}

	public static function copyKey(arrayToCopy:Array<FlxKey>):Array<FlxKey>
	{
		var copiedArray:Array<FlxKey> = arrayToCopy.copy();

		var i:Int = 0;
		var len:Int = copiedArray.length;

		while (i < len)
		{
			if (copiedArray[i] == NONE)
			{
				copiedArray.remove(NONE);
				--i;
			}

			i++;
			len = copiedArray.length;
		}

		return copiedArray;
	}
}