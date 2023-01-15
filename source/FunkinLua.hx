package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

#if LUA_ALLOWED
import llua.Lua;
import llua.LuaL;
import llua.State;
import llua.Convert;
#end

#if sys
import sys.io.File;
import sys.FileSystem;
#end

#if hscript
import hscript.Expr;
import hscript.Parser;
import hscript.Interp;
#end

#if MP4_ALLOWED
import webmlmfao.*;
#end

import Song;
import Note;
import Section;
import StageData;
import FunkinLua;
import DialogueBoxPsych;
import transition.Transition;

import Type.ValueType;

import openfl.Lib;
import flixel.FlxG;
import flixel.FlxState;
import flixel.FlxBasic;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.math.FlxMath;
import flixel.util.FlxSave;
import flixel.text.FlxText;
import openfl.utils.Assets;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;
import openfl.display.BlendMode;
import openfl.display.BitmapData;
import openfl.filters.BitmapFilter;
import animateatlas.AtlasFrameMaker;
import flixel.input.keyboard.FlxKey;
import flixel.addons.effects.FlxTrail;
import flixel.system.FlxAssets.FlxShader;
#if (!flash && MODS_ALLOWED)
import flixel.addons.display.FlxRuntimeShader;
#end

using StringTools;

class FunkinLua
{
	public static var Function_Stop:Dynamic = 1;
	public static var Function_Continue:Dynamic = 0;
	public static var Function_StopLua:Dynamic = 2;

	#if LUA_ALLOWED
	public var lua:State = null;
	#end

	public var camTarget:FlxCamera;
	public var scriptName:String = '';
	public var closed:Bool = false;

	#if !flash
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	#end

	#if hscript
	public static var hscript:HScript = null;
	#end

	public var existionShit:Map<String, Bool> = new Map<String, Bool>();
	public var scriptCode:String;

	public function new(script:String, ?scriptCode:String):Void
	{
		#if LUA_ALLOWED
		lua = LuaL.newstate();
	
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);

		try
		{
			var result:Dynamic = null;

			if (scriptCode != null) result = LuaL.dostring(lua, scriptCode);
			else result = LuaL.dofile(lua, script);

			var resultStr:String = Lua.tostring(lua, result);

			if (resultStr != null && result != 0)
			{
				Debug.logError('Error on lua script! ' + resultStr);
	
				#if windows
				lime.app.Application.current.window.alert(resultStr, 'Error on lua script!');
				#else
				luaTrace('Error loading lua script: "$script"\n' + resultStr, true, false, FlxColor.RED);
				#end

				lua = null;
				return;
			}
		}
		catch (e:Dynamic)
		{
			Debug.logError(e);
			return;
		}

		if (scriptCode != null) this.scriptCode = scriptCode;
		scriptName = script;

		initHaxeModule();

		set('Function_StopLua', Function_StopLua);
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);
		set('inChartEditor', false);

		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songID', PlayState.SONG.songID);
		set('songName', PlayState.SONG.songName);
		set('startedCountdown', false);

		set('gameMode', PlayState.gameMode);
		set('isStoryMode', PlayState.isStoryMode);
		set('difficultyID', PlayState.lastDifficulty);
		set('difficultyName', CoolUtil.getDifficultyName(PlayState.lastDifficulty, PlayState.difficulties));
		set('difficultySuffix', CoolUtil.getDifficultySuffix(PlayState.lastDifficulty, PlayState.difficulties));

		set('storyDifficultyID', PlayState.storyDifficulty);
		set('storyDifficultyName', CoolUtil.getDifficultyName(PlayState.storyDifficulty, PlayState.difficulties));
		set('storyDifficultySuffix', CoolUtil.getDifficultySuffix(PlayState.storyDifficulty, PlayState.difficulties));
		set('weekID', PlayState.storyWeek);
		set('weekName', PlayState.storyWeekName);
		set('seenCutscene', PlayState.seenCutscene);

		set('cameraX', 0);
		set('cameraY', 0);

		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		set('curBeat', 0);
		set('curStep', 0);
		set('curSection', 0);

		set('score', 0);
		set('misses', 0);
		set('hits', 0);

		set('accuracy', 0);
		set('rating', 0);
		set('ratingName', '');
		set('ratingFC', '');
		set('gameVersion', MainMenuState.gameVersion.trim());
		set('version', MainMenuState.engineVersion.trim());
		set('psychVersion', MainMenuState.psychEngineVersion.trim());

		set('inGameOver', false);
		set('mustHitSection', false);
		set('altAnim', false);
		set('gfSection', false);

		set('curStage', PlayState.SONG.stage);

		set('healthGainMult', PlayStateChangeables.healthGain);
		set('healthLossMult', PlayStateChangeables.healthLoss);
		set('playbackRate', PlayStateChangeables.playbackRate);
		set('instakillOnMiss', PlayStateChangeables.instaKill);

		set('botPlay', PlayStateChangeables.botPlay);
		set('practiceMode', PlayStateChangeables.practiceMode);

		for (i in 0...4)
		{
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		set('defaultBoyfriendX', PlayState.instance.BF_X);
		set('defaultBoyfriendY', PlayState.instance.BF_Y);

		set('defaultOpponentX', PlayState.instance.DAD_X);
		set('defaultOpponentY', PlayState.instance.DAD_Y);

		set('defaultGirlfriendX', PlayState.instance.GF_X);
		set('defaultGirlfriendY', PlayState.instance.GF_Y);

		set('boyfriendName', PlayState.SONG.player1);
		set('dadName', PlayState.SONG.player2);
		set('gfName', PlayState.SONG.gfVersion);

		OptionData.loadLuaPrefs();

		var luaPrefsMap:Map<String, Array<Dynamic>> = OptionData.luaPrefsMap.copy();

		for (value in luaPrefsMap)
		{
			if ((value != null || value.length > 1) && (value[0] != null || value[0].length > 0) && (value[1] != null)) {
				set(value[0], value[1]);
			}
		}

		set('scrollSpeed', PlayState.SONG.speed);
		set('opponentStrumsType', OptionData.opponentStrumsType);
		set('scriptName', scriptName);

		#if windows
		set('buildTarget', 'windows');
		#elseif linux
		set('buildTarget', 'linux');
		#elseif mac
		set('buildTarget', 'mac');
		#elseif html5
		set('buildTarget', 'browser');
		#elseif android
		set('buildTarget', 'android');
		#else
		set('buildTarget', 'unknown');
		#end

		Lua_helper.add_callback(lua, "boundSelection", function(selection:Int = 0, max:Int = 1):Int
		{
			return CoolUtil.boundSelection(selection, max);
		});

		Lua_helper.add_callback(lua, "coolLerp", function(a:Float, b:Float, ratio:Float, ?multiplier:Float = 54.5):Float
		{
			return CoolUtil.coolLerp(a, b, ratio, multiplier);
		});

		Lua_helper.add_callback(lua, "boundTo", function(value:Float, min:Float, max:Float):Float
		{
			return CoolUtil.boundTo(value, min, max);
		});

		Lua_helper.add_callback(lua, "openCustomSubstate", function(name:String, pauseGame:Bool = false):Void
		{
			if (pauseGame)
			{
				PlayState.instance.persistentUpdate = false;
				PlayState.instance.persistentDraw = true;
				PlayState.instance.paused = true;
		
				if (FlxG.sound.music != null)
				{
					FlxG.sound.music.pause();
					PlayState.instance.vocals.pause();
				}
			}

			PlayState.instance.openSubState(new CustomSubState(name));
		});

		Lua_helper.add_callback(lua, "closeCustomSubstate", function():Bool
		{
			if (CustomSubState.instance != null)
			{
				PlayState.instance.closeSubState();
				CustomSubState.instance = null;
		
				return true;
			}
	
			return false;
		});

		Lua_helper.add_callback(lua, "browserLoad", function(site:String):Void
		{
			CoolUtil.browserLoad(site);
		});

		Lua_helper.add_callback(lua, "initLuaShader", function(name:String, glslVersion:Int = 120):Bool
		{
			if (!OptionData.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			return initLuaShader(name, glslVersion);
			#else
			luaTrace("initLuaShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});
		
		Lua_helper.add_callback(lua, "setSpriteShader", function(obj:String, shader:String):Bool
		{
			if (!OptionData.shaders) return false;

			#if (!flash && MODS_ALLOWED && sys)
			if (!PlayState.instance.runtimeShaders.exists(shader) && !initLuaShader(shader))
			{
				luaTrace('setSpriteShader: Shader $shader is missing!', false, false, FlxColor.RED);
				return false;
			}

			var fieldArray:Array<String> = obj.split('.');
			var leObj:FlxSprite = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				leObj = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (leObj != null)
			{
				var arr:Array<String> = PlayState.instance.runtimeShaders.get(shader);
				leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);

				return true;
			}
			#else
			luaTrace("setSpriteShader: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end

			return false;
		});

		Lua_helper.add_callback(lua, "removeSpriteShader", function(obj:String):Bool
		{
			var fieldArray:Array<String> = obj.split('.');
			var leObj:FlxSprite = getObjectDirectly(fieldArray[0]);
	
			if (fieldArray.length > 1) {
				leObj = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (leObj != null)
			{
				leObj.shader = null;
				return true;
			}

			return false;
		});

		Lua_helper.add_callback(lua, "getShaderBool", function(obj:String, prop:String):Null<Bool>
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null) {
				return null;
			}

			return shader.getBool(prop);
			#else
			luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});

		Lua_helper.add_callback(lua, "getShaderBoolArray", function(obj:String, prop:String):Dynamic
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null) {
				return null;
			}

			return shader.getBoolArray(prop);
			#else
			luaTrace("getShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});

		Lua_helper.add_callback(lua, "getShaderInt", function(obj:String, prop:String):Null<Int>
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null) {
				return null;
			}

			return shader.getInt(prop);
			#else
			luaTrace("getShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});

		Lua_helper.add_callback(lua, "getShaderIntArray", function(obj:String, prop:String):Dynamic
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null) {
				return null;
			}

			return shader.getIntArray(prop);
			#else
			luaTrace("getShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});

		Lua_helper.add_callback(lua, "getShaderFloat", function(obj:String, prop:String):Null<Float>
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null) {
				return null;
			}

			return shader.getFloat(prop);
			#else
			luaTrace("getShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});

		Lua_helper.add_callback(lua, "getShaderFloatArray", function(obj:String, prop:String):Dynamic
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null) {
				return null;
			}

			return shader.getFloatArray(prop);
			#else
			luaTrace("getShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			return null;
			#end
		});

		Lua_helper.add_callback(lua, "setShaderBool", function(obj:String, prop:String, value:Bool):Void
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null) return;

			shader.setBool(prop, value);
			#else
			luaTrace("setShaderBool: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});

		Lua_helper.add_callback(lua, "setShaderBoolArray", function(obj:String, prop:String, values:Dynamic):Void
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null) return;

			shader.setBoolArray(prop, values);
			#else
			luaTrace("setShaderBoolArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});

		Lua_helper.add_callback(lua, "setShaderInt", function(obj:String, prop:String, value:Int):Void
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null) return;

			shader.setInt(prop, value);
			#else
			luaTrace("setShaderInt: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});

		Lua_helper.add_callback(lua, "setShaderIntArray", function(obj:String, prop:String, values:Dynamic):Void
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null) return;

			shader.setIntArray(prop, values);
			#else
			luaTrace("setShaderIntArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});

		Lua_helper.add_callback(lua, "setShaderFloat", function(obj:String, prop:String, value:Float):Void
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null) return;

			shader.setFloat(prop, value);
			#else
			luaTrace("setShaderFloat: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});

		Lua_helper.add_callback(lua, "setShaderFloatArray", function(obj:String, prop:String, values:Dynamic):Void
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);
			if (shader == null) return;

			shader.setFloatArray(prop, values);
			#else
			luaTrace("setShaderFloatArray: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});

		Lua_helper.add_callback(lua, "setShaderSampler2D", function(obj:String, prop:String, bitmapdataPath:String):Void
		{
			#if (!flash && MODS_ALLOWED && sys)
			var shader:FlxRuntimeShader = getShader(obj);

			if (shader == null) return;

			var value = Paths.getImage(bitmapdataPath);

			if (value != null && value.bitmap != null) {
				shader.setSampler2D(prop, value.bitmap);
			}
			#else
			luaTrace("setShaderSampler2D: Platform unsupported for Runtime Shaders!", false, false, FlxColor.RED);
			#end
		});

		Lua_helper.add_callback(lua, "getRunningScripts", function():Array<String>
		{
			var runningScripts:Array<String> = [];
	
			for (idx in 0...PlayState.instance.luaArray.length) {
				runningScripts.push(PlayState.instance.luaArray[idx].scriptName);
			}

			return runningScripts;
		});

		Lua_helper.add_callback(lua, "setOnLuas", function(?varName:String, ?scriptVar:String):Void
		{
			if (varName == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #1 to 'setOnLuas' (string expected, got nil)");
				#end
	
				return;
			}

			if (scriptVar == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #2 to 'setOnLuas' (string expected, got nil)");
				#end
	
				return;
			}

			PlayState.instance.setOnLuas(varName, scriptVar);
		});

		Lua_helper.add_callback(lua, "callOnLuas", function(?funcName:String, ?args:Array<Dynamic>, ignoreStops = false, ignoreSelf = true, ?exclusions:Array<String>):Void
		{
			if (funcName == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #1 to 'callOnLuas' (string expected, got nil)");
				#end

				return;
			}

			if (args == null) args = [];
			if (exclusions == null) exclusions=[];

			Lua.getglobal(lua, 'scriptName');

			var daScriptName = Lua.tostring(lua, -1);
			Lua.pop(lua, 1);

			if (ignoreSelf && !exclusions.contains(daScriptName))exclusions.push(daScriptName);
			PlayState.instance.callOnLuas(funcName, args, ignoreStops, exclusions);
		});

		Lua_helper.add_callback(lua, "callScript", function(?luaFile:String, ?funcName:String, ?args:Array<Dynamic>):Void
		{
			if (luaFile == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #1 to 'callScript' (string expected, got nil)");
				#end

				return;
			}

			if (funcName == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #2 to 'callScript' (string expected, got nil)");
				#end

				return;
			}

			if (args == null) {
				args = [];
			}

			var cervix:String = luaFile + ".lua";
			if (luaFile.endsWith(".lua")) cervix = luaFile;

			var doPush:Bool = false;

			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix)) {
				doPush = true;
			}
			else 
			{
				cervix = Paths.getPreloadPath(cervix);

				if (FileSystem.exists(cervix)) {
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);

			if (Assets.exists(cervix)) {
				doPush = true;
			}
			#end

			if (doPush)
			{
				for (luaInstance in PlayState.instance.luaArray)
				{
					if (luaInstance.scriptName == cervix)
					{
						luaInstance.call(funcName, args);
						return;
					}
				}
			}
		});

		Lua_helper.add_callback(lua, "loadSong", function(?name:String = null, ?difficulty:String = ''):Void
		{
			var diff:String = CoolUtil.getDifficultySuffix(difficulty, PlayState.difficulties);

			if (Paths.fileExists('data/' + name + '/' + name + diff + '.json', TEXT))
			{
				PlayState.SONG = Song.loadFromJson(name + diff, name);
				PlayState.storyDifficulty = difficulty;
				PlayState.lastDifficulty = difficulty;
				PlayState.instance.persistentUpdate = false;

				LoadingState.loadAndSwitchState(new PlayState(), true);

				FlxG.sound.music.pause();
				FlxG.sound.music.volume = 0;

				if (PlayState.instance.vocals != null)
				{
					PlayState.instance.vocals.pause();
					PlayState.instance.vocals.volume = 0;
				}

				return;
			}

			luaTrace("loadSong: File \"" + 'data/' + name + '/' + name + diff + '.json' + "\" does not exist!", false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "loadGraphic", function(variable:String, image:String, ?gridX:Int = 0, ?gridY:Int = 0):Void
		{
			var fieldArray:Array<String> = variable.split('.');
			var spr:FlxSprite = getObjectDirectly(fieldArray[0]);

			var animated:Bool = gridX != 0 || gridY != 0;

			if (fieldArray.length > 1) {
				spr = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (spr != null && image != null && image.length > 0) {
				spr.loadGraphic(Paths.getImage(image), animated, gridX, gridY);
			}
		});

		Lua_helper.add_callback(lua, "loadFrames", function(variable:String, image:String, spriteType:String = "sparrow"):Void
		{
			var fieldArray:Array<String> = variable.split('.');
			var spr:FlxSprite = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				spr = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (spr != null && image != null && image.length > 0) {
				loadFrames(spr, image, spriteType);
			}
		});

		Lua_helper.add_callback(lua, "getProperty", function(variable:String):Dynamic
		{
			if (variable != null || variable.length > 0)
			{
				var blyad:String = getVariableByPrefix(getInstanceName(), variable);
				variable = blyad;
			}

			var result:Dynamic = null;
			var fieldArray:Array<String> = variable.split('.');
	
			if (fieldArray.length > 1) {
				result = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}
			else {
				result = getVarInArray(getInstance(), variable);
			}

			return result;
		});

		Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic):Bool
		{
			if (variable != null || variable.length > 0)
			{
				var blyad:String = getVariableByPrefix(getInstanceName(), variable);
				variable = blyad;
			}

			var fieldArray:Array<String> = variable.split('.');

			if (fieldArray.length > 1)
			{
				setVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1], value);
				return true;
			}
	
			setVarInArray(getInstance(), variable, value);
			return true;
		});

		Lua_helper.add_callback(lua, "callFromObject", function(variable:String, ?arguments:Array<Dynamic>):Dynamic
		{
			if (variable != null || variable.length > 0)
			{
				var blyad:String = getCallerByPrefix(getInstanceName(), variable);
				variable = blyad;
			}

			if (arguments == null) {
				arguments = [];
			}

			var result:Dynamic = null;
			var killMe:Array<String> = variable.split('.');

			if (killMe.length > 1)
				result = getVarInArray(getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
			else
				result = getVarInArray(getInstance(), variable);

			return Reflect.callMethod(null, result, arguments);
		});

		Lua_helper.add_callback(lua, "getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic):Dynamic
		{
			var fieldArray:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(getInstance(), obj);

			if (fieldArray.length > 1) {
				realObject = getPropertyLoopThingWhatever(fieldArray, true, false);
			}

			if (Std.isOfType(realObject, FlxTypedGroup))
			{
				var result:Dynamic = getGroupStuff(realObject.members[index], variable);
				return result;
			}

			var leArray:Dynamic = realObject[index];

			if (leArray != null)
			{
				var result:Dynamic = null;

				if (Type.typeof(variable) == ValueType.TInt) {
					result = leArray[variable];
				}
				else {
					result = getGroupStuff(leArray, variable);
				}

				return result;
			}

			luaTrace("getPropertyFromGroup: Object #" + index + " from group: " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});

		Lua_helper.add_callback(lua, "setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic):Void
		{
			var shitMyPants:Array<String> = obj.split('.');
			var realObject:Dynamic = Reflect.getProperty(getInstance(), obj);

			if (shitMyPants.length > 1) {
				realObject = getPropertyLoopThingWhatever(shitMyPants, true, false);
			}

			if (Std.isOfType(realObject, FlxTypedGroup))
			{
				setGroupStuff(realObject.members[index], variable, value);
				return;
			}

			var leArray:Dynamic = realObject[index];

			if (leArray != null)
			{
				if (Type.typeof(variable) == ValueType.TInt)
				{
					leArray[variable] = value;
					return;
				}

				setGroupStuff(leArray, variable, value);
			}
		});

		Lua_helper.add_callback(lua, "removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false):Void
		{
			if (Std.isOfType(Reflect.getProperty(getInstance(), obj), FlxTypedGroup))
			{
				var sex:FlxBasic = Reflect.getProperty(getInstance(), obj).members[index];

				if (!dontDestroy) {
					sex.kill();
				}

				Reflect.getProperty(getInstance(), obj).remove(sex, true);

				if (!dontDestroy) {
					sex.destroy();
				}

				return;
			}

			Reflect.getProperty(getInstance(), obj).remove(Reflect.getProperty(getInstance(), obj)[index]);
		});

		Lua_helper.add_callback(lua, "getPropertyFromClass", function(classVar:String, variable:String):Dynamic
		{
			if (classVar != null || classVar.length > 0) {
				classVar = getClassNameByPrefix(classVar);
			}

			if ((classVar != null || classVar.length > 0) && (variable != null || variable.length > 0))
			{
				var blyad:String = getVariableByPrefix(classVar, variable);
				variable = blyad;
			}

			@:privateAccess
			var fieldArray:Array<String> = variable.split('.');
			if (fieldArray.length > 1) {
				var fieldArrayFromClass:Dynamic = getVarInArray(Type.resolveClass(classVar.trim()), fieldArray[0]);
				for (i in 1...fieldArray.length - 1) {
					fieldArrayFromClass = getVarInArray(fieldArrayFromClass, fieldArray[i]);
				}
				return getVarInArray(fieldArrayFromClass, fieldArray[fieldArray.length - 1]);
			}
			return getVarInArray(Type.resolveClass(classVar.trim()), variable);
		});

		Lua_helper.add_callback(lua, "setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic):Bool
		{
			if (classVar != null || classVar.length > 0) {
				classVar = getClassNameByPrefix(classVar);
			}

			if ((classVar != null || classVar.length > 0) && (variable != null || variable.length > 0))
			{
				var blyad:String = getVariableByPrefix(classVar, variable);
				variable = blyad;
			}

			@:privateAccess
			var fieldArray:Array<String> = variable.split('.');
			if (fieldArray.length > 1) {
				var fieldArrayFromClass:Dynamic = getVarInArray(Type.resolveClass(classVar.trim()), fieldArray[0]);
				for (i in 1...fieldArray.length - 1) {
					fieldArrayFromClass = getVarInArray(fieldArrayFromClass, fieldArray[i]);
				}
				setVarInArray(fieldArrayFromClass, fieldArray[fieldArray.length - 1], value);
				return true;
			}
			setVarInArray(Type.resolveClass(classVar.trim()), variable, value);
			return true;
		});

		Lua_helper.add_callback(lua, "callFromClass", function(classVar:String, variable:String, ?arguments:Array<Dynamic>):Dynamic
		{
			if (classVar != null || classVar.length > 0) {
				classVar = getClassNameByPrefix(classVar);
			}

			if ((classVar != null || classVar.length > 0) && (variable != null || variable.length > 0))
			{
				var blyad:String = getCallerByPrefix(classVar, variable);
				variable = blyad;
			}

			if (arguments == null) {
				arguments = [];
			}

			@:privateAccess
			var killMe:Array<String> = variable.split('.');
			if (killMe.length > 1)
			{
				var coverMeInPiss:Dynamic = getVarInArray(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length-1) {
					coverMeInPiss = getVarInArray(coverMeInPiss, killMe[i]);
				}
				return Reflect.callMethod(null, getVarInArray(coverMeInPiss, killMe[killMe.length-1]), arguments);
			}
			return Reflect.callMethod(null, getVarInArray(Type.resolveClass(classVar), variable), arguments);
		});

		Lua_helper.add_callback(lua, "getObjectOrder", function(obj:String):Int // shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		{
			var fieldArray:Array<String> = obj.split('.');
			var leObj:FlxBasic = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				leObj = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (leObj != null) {
				return getInstance().members.indexOf(leObj);
			}

			luaTrace("getObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);

			return -1;
		});

		Lua_helper.add_callback(lua, "setObjectOrder", function(obj:String, position:Int):Void
		{
			var fieldArray:Array<String> = obj.split('.');
			var leObj:FlxBasic = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				leObj = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (leObj != null)
			{
				getInstance().remove(leObj, true);
				getInstance().insert(position, leObj);

				return;
			}
	
			luaTrace("setObjectOrder: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String):Void // gay ass tweens
		{
			var penisExam:Dynamic = getTween(tag, vars);

			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {x: value}, duration,
				{
					ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween):Void
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else {
				luaTrace('doTweenX: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		Lua_helper.add_callback(lua, "doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String):Void // gay ass tweens
		{
			var penisExam:Dynamic = getTween(tag, vars);

			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {y: value}, duration,
				{
					ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween):Void
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else {
				luaTrace('doTweenY: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		Lua_helper.add_callback(lua, "doTweenAngle", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String):Void // gay ass tweens
		{
			var penisExam:Dynamic = getTween(tag, vars);

			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {angle: value}, duration,
				{
					ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween):Void
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else {
				luaTrace('doTweenAngle: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		Lua_helper.add_callback(lua, "doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String):Void // gay ass tweens
		{
			var penisExam:Dynamic = getTween(tag, vars);

			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {alpha: value}, duration,
				{
					ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween):Void
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else {
				luaTrace('doTweenAlpha: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});
		Lua_helper.add_callback(lua, "doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String):Void // gay ass tweens
		{
			var penisExam:Dynamic = getTween(tag, vars);

			if (penisExam != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(penisExam, {zoom: value}, duration,
				{
					ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween):Void
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
			else {
				luaTrace('doTweenZoom: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		Lua_helper.add_callback(lua, "doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String):Void // gay ass tweens
		{
			var penisExam:Dynamic = getTween(tag, vars);

			if (penisExam != null)
			{
				var color:Int = Std.parseInt(targetColor);
				if (!targetColor.startsWith('0x')) color = Std.parseInt('0xff' + targetColor);

				var curColor:FlxColor = penisExam.color;
				curColor.alphaFloat = penisExam.alpha;
	
				PlayState.instance.modchartTweens.set(tag, FlxTween.color(penisExam, duration, curColor, color,
				{
					ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween):Void
					{
						PlayState.instance.modchartTweens.remove(tag);
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
					}
				}));
			}
			else {
				luaTrace('doTweenColor: Couldnt find object: ' + vars, false, false, FlxColor.RED);
			}
		});

		Lua_helper.add_callback(lua, "noteTweenX", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String):Void
		{
			cancelTween(tag);
			if (note < 0) note = 0;

			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {x: value}, duration,
				{
					ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween):Void
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		Lua_helper.add_callback(lua, "noteTweenY", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String):Void
		{
			cancelTween(tag);
	
			if (note < 0) note = 0;

			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {y: value}, duration,
				{
					ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween):Void
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		Lua_helper.add_callback(lua, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String):Void
		{
			cancelTween(tag);
			if (note < 0) note = 0;

			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration,
				{
					ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween):Void
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});
		Lua_helper.add_callback(lua, "noteTweenDirection", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String):Void
		{
			cancelTween(tag);
			if (note < 0) note = 0;

			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {direction: value}, duration,
				{
					ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween):Void
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		Lua_helper.add_callback(lua, "noteTweenAngle", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String):Void
		{
			cancelTween(tag);
			if (note < 0) note = 0;

			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {angle: value}, duration,
				{
					ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween):Void
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		Lua_helper.add_callback(lua, "noteTweenAlpha", function(tag:String, note:Int, value:Dynamic, duration:Float, ease:String):Void
		{
			cancelTween(tag);
			if (note < 0) note = 0;

			var testicle:StrumNote = PlayState.instance.strumLineNotes.members[note % PlayState.instance.strumLineNotes.length];

			if (testicle != null)
			{
				PlayState.instance.modchartTweens.set(tag, FlxTween.tween(testicle, {alpha: value}, duration,
				{
					ease: getFlxEaseByString(ease),
					onComplete: function(twn:FlxTween):Void
					{
						PlayState.instance.callOnLuas('onTweenCompleted', [tag]);
						PlayState.instance.modchartTweens.remove(tag);
					}
				}));
			}
		});

		Lua_helper.add_callback(lua, "mouseReleased", function(button:String):Bool
		{
			var boobs:Bool = FlxG.mouse.justReleased;
	
			switch (button)
			{
				case 'middle':
					boobs = FlxG.mouse.justReleasedMiddle;
				case 'right':
					boobs = FlxG.mouse.justReleasedRight;
			}

			return boobs;
		});

		Lua_helper.add_callback(lua, "mouseClicked", function(button:String):Bool
		{
			var boobs:Bool = FlxG.mouse.justPressed;

			switch (button)
			{
				case 'middle':
					boobs = FlxG.mouse.justPressedMiddle;
				case 'right':
					boobs = FlxG.mouse.justPressedRight;
			}

			return boobs;
		});

		Lua_helper.add_callback(lua, "mousePressed", function(button:String):Bool
		{
			var boobs:Bool = FlxG.mouse.pressed;

			switch (button)
			{
				case 'middle':
					boobs = FlxG.mouse.pressedMiddle;
				case 'right':
					boobs = FlxG.mouse.pressedRight;
			}

			return boobs;
		});

		Lua_helper.add_callback(lua, "cancelTween", function(tag:String):Void
		{
			cancelTween(tag);
		});

		Lua_helper.add_callback(lua, "runTimer", function(tag:String, time:Float = 1, loops:Int = 1):Void
		{
			cancelTimer(tag);

			PlayState.instance.modchartTimers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				if (tmr.finished) {
					PlayState.instance.modchartTimers.remove(tag);
				}

				PlayState.instance.callOnLuas('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});

		Lua_helper.add_callback(lua, "cancelTimer", function(tag:String):Void
		{
			cancelTimer(tag);
		});

		Lua_helper.add_callback(lua, "addScore", function(value:Int = 0):Void
		{
			PlayState.instance.songScore += value;
			PlayState.instance.recalculateRating();
		});

		Lua_helper.add_callback(lua, "addMisses", function(value:Int = 0):Void
		{
			PlayState.instance.songMisses += value;
			PlayState.instance.recalculateRating();
		});

		Lua_helper.add_callback(lua, "addHits", function(value:Int = 0):Void
		{
			PlayState.instance.songHits += value;
			PlayState.instance.recalculateRating();
		});

		Lua_helper.add_callback(lua, "setScore", function(value:Int = 0):Void
		{
			PlayState.instance.songScore = value;
			PlayState.instance.recalculateRating();
		});

		Lua_helper.add_callback(lua, "setMisses", function(value:Int = 0):Void
		{
			PlayState.instance.songMisses = value;
			PlayState.instance.recalculateRating();
		});

		Lua_helper.add_callback(lua, "setHits", function(value:Int = 0):Void
		{
			PlayState.instance.songHits = value;
			PlayState.instance.recalculateRating();
		});

		Lua_helper.add_callback(lua, "getScore", function():Int
		{
			return PlayState.instance.songScore;
		});

		Lua_helper.add_callback(lua, "getMisses", function():Int
		{
			return PlayState.instance.songMisses;
		});

		Lua_helper.add_callback(lua, "getHits", function():Int
		{
			return PlayState.instance.songHits;
		});

		Lua_helper.add_callback(lua, "setHealth", function(value:Float = 0):Void
		{
			PlayState.instance.health = value;
		});

		Lua_helper.add_callback(lua, "addHealth", function(value:Float = 0):Void
		{
			PlayState.instance.health += value;
		});

		Lua_helper.add_callback(lua, "getHealth", function():Float
		{
			return PlayState.instance.health;
		});

		Lua_helper.add_callback(lua, "getColorFromHex", function(color:String):Int
		{
			if (!color.startsWith('0x')) color = '0xff' + color;

			return Std.parseInt(color);
		});

		Lua_helper.add_callback(lua, "keyboardJustPressed", function(name:String):Bool
		{
			return Reflect.getProperty(FlxG.keys.justPressed, name);
		});

		Lua_helper.add_callback(lua, "keyboardPressed", function(name:String):Bool
		{
			return Reflect.getProperty(FlxG.keys.pressed, name);
		});

		Lua_helper.add_callback(lua, "keyboardReleased", function(name:String):Bool
		{
			return Reflect.getProperty(FlxG.keys.justReleased, name);
		});

		Lua_helper.add_callback(lua, "anyGamepadJustPressed", function(name:String):Bool
		{
			return FlxG.gamepads.anyJustPressed(name);
		});

		Lua_helper.add_callback(lua, "anyGamepadPressed", function(name:String):Bool
		{
			return FlxG.gamepads.anyPressed(name);
		});

		Lua_helper.add_callback(lua, "anyGamepadReleased", function(name:String):Bool
		{
			return FlxG.gamepads.anyJustReleased(name);
		});

		Lua_helper.add_callback(lua, "gamepadAnalogX", function(id:Int, ?leftStick:Bool = true):Float
		{
			var controller = FlxG.gamepads.getByID(id);

			if (controller == null) {
				return 0.0;
			}

			return controller.getXAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});

		Lua_helper.add_callback(lua, "gamepadAnalogY", function(id:Int, ?leftStick:Bool = true):Float
		{
			var controller = FlxG.gamepads.getByID(id);

			if (controller == null) {
				return 0.0;
			}

			return controller.getYAxis(leftStick ? LEFT_ANALOG_STICK : RIGHT_ANALOG_STICK);
		});

		Lua_helper.add_callback(lua, "gamepadJustPressed", function(id:Int, name:String):Bool
		{
			var controller = FlxG.gamepads.getByID(id);

			if (controller == null) {
				return false;
			}

			return Reflect.getProperty(controller.justPressed, name) == true;
		});

		Lua_helper.add_callback(lua, "gamepadPressed", function(id:Int, name:String):Bool
		{
			var controller = FlxG.gamepads.getByID(id);

			if (controller == null) {
				return false;
			}

			return Reflect.getProperty(controller.pressed, name) == true;
		});

		Lua_helper.add_callback(lua, "gamepadReleased", function(id:Int, name:String):Bool
		{
			var controller = FlxG.gamepads.getByID(id);

			if (controller == null) {
				return false;
			}

			return Reflect.getProperty(controller.justReleased, name) == true;
		});

		Lua_helper.add_callback(lua, "keyJustPressed", function(name:String):Bool
		{
			var key:Bool = false;

			switch (name)
			{
				case 'left': key = PlayState.instance.getControl('NOTE_LEFT_P');
				case 'down': key = PlayState.instance.getControl('NOTE_DOWN_P');
				case 'up': key = PlayState.instance.getControl('NOTE_UP_P');
				case 'right': key = PlayState.instance.getControl('NOTE_RIGHT_P');
				case 'accept': key = PlayState.instance.getControl('ACCEPT');
				case 'back': key = PlayState.instance.getControl('BACK');
				case 'pause': key = PlayState.instance.getControl('PAUSE');
				case 'reset': key = PlayState.instance.getControl('RESET');
				case 'space': key = FlxG.keys.justPressed.SPACE; // an extra key for convinience
			}

			return key;
		});

		Lua_helper.add_callback(lua, "keyPressed", function(name:String):Bool
		{
			var key:Bool = false;
	
			switch (name)
			{
				case 'left': key = PlayState.instance.getControl('NOTE_LEFT');
				case 'down': key = PlayState.instance.getControl('NOTE_DOWN');
				case 'up': key = PlayState.instance.getControl('NOTE_UP');
				case 'right': key = PlayState.instance.getControl('NOTE_RIGHT');
				case 'space': key = FlxG.keys.pressed.SPACE; // an extra key for convinience
			}
	
			return key;
		});

		Lua_helper.add_callback(lua, "keyReleased", function(name:String):Bool
		{
			var key:Bool = false;

			switch (name)
			{
				case 'left': key = PlayState.instance.getControl('NOTE_LEFT_R');
				case 'down': key = PlayState.instance.getControl('NOTE_DOWN_R');
				case 'up': key = PlayState.instance.getControl('NOTE_UP_R');
				case 'right': key = PlayState.instance.getControl('NOTE_RIGHT_R');
				case 'space': key = FlxG.keys.justReleased.SPACE; // an extra key for convinience
			}

			return key;
		});

		Lua_helper.add_callback(lua, "addCharacterToList", function(name:String, type:String):Void
		{
			var charType:Int = 0;

			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent': charType = 1;
				case 'gf' | 'girlfriend': charType = 2;
			}
	
			PlayState.instance.addCharacterToList(name, charType);
		});

		Lua_helper.add_callback(lua, "precacheImage", function(name:String):Void
		{
			Paths.returnGraphic(name);
		});

		Lua_helper.add_callback(lua, "precacheSound", function(name:String):Void
		{
			CoolUtil.precacheSound(name);
		});

		Lua_helper.add_callback(lua, "precacheMusic", function(name:String):Void
		{
			CoolUtil.precacheMusic(name);
		});

		Lua_helper.add_callback(lua, "triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic):Bool
		{
			var value1:String = arg1;
			var value2:String = arg2;

			PlayState.instance.triggerEventNote(name, value1, value2);

			return true;
		});

		Lua_helper.add_callback(lua, "startCountdown", function():Bool
		{
			PlayState.instance.startCountdown();
			return true;
		});

		Lua_helper.add_callback(lua, "finishSong", function():Bool
		{
			PlayState.instance.finishSong();
			return true;
		});

		Lua_helper.add_callback(lua, "endSong", function():Bool
		{
			PlayState.instance.KillNotes();
			PlayState.instance.endSong();

			return true;
		});

		Lua_helper.add_callback(lua, "restartSong", function(?skipTransition:Bool = false):Bool
		{
			PlayState.instance.persistentUpdate = false;
			PauseSubState.restartSong(skipTransition);

			return true;
		});

		Lua_helper.add_callback(lua, "exitSong", function(?skipTransition:Bool = false):Bool
		{
			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;

			PlayState.instance.vocals.pause();
			PlayState.instance.vocals.volume = 0;

			if (skipTransition)
			{
				Transition.skipNextTransIn = true;
				Transition.skipNextTransOut = true;
			}

			PlayState.cancelMusicFadeTween();

			Transition.nextCamera = PlayState.instance.camOther;

			if (Transition.skipNextTransIn) {
				Transition.nextCamera = null;
			}

			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;

			PlayState.instance.transitioning = true;

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

			return true;
		});

		Lua_helper.add_callback(lua, "getSongPosition", function():Float
		{
			return Conductor.songPosition;
		});

		Lua_helper.add_callback(lua, "getCharacterX", function(type:String):Float
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return PlayState.instance.dadGroup.x;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gfGroup.x;
				default:
					return PlayState.instance.boyfriendGroup.x;
			}
		});

		Lua_helper.add_callback(lua, "setCharacterX", function(type:String, value:Float):Void
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					PlayState.instance.dadGroup.x = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gfGroup.x = value;
				default:
					PlayState.instance.boyfriendGroup.x = value;
			}
		});

		Lua_helper.add_callback(lua, "getCharacterY", function(type:String):Float
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					return PlayState.instance.dadGroup.y;
				case 'gf' | 'girlfriend':
					return PlayState.instance.gfGroup.y;
				default:
					return PlayState.instance.boyfriendGroup.y;
			}
		});

		Lua_helper.add_callback(lua, "setCharacterY", function(type:String, value:Float):Void
		{
			switch (type.toLowerCase())
			{
				case 'dad' | 'opponent':
					PlayState.instance.dadGroup.y = value;
				case 'gf' | 'girlfriend':
					PlayState.instance.gfGroup.y = value;
				default:
					PlayState.instance.boyfriendGroup.y = value;
			}
		});

		Lua_helper.add_callback(lua, "cameraSetTarget", function(target:String):Void
		{
			PlayState.instance.cameraMovement(target);
		});

		Lua_helper.add_callback(lua, "cameraShake", function(camera:String, intensity:Float, duration:Float):Void
		{
			if (OptionData.camShakes) {
				cameraFromString(camera).shake(intensity, duration);
			}
		});

		Lua_helper.add_callback(lua, "cameraFlash", function(camera:String, color:String, duration:Float, forced:Bool):Void
		{
			var colorNum:Int = Std.parseInt(color);
			if (!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

			cameraFromString(camera).flash(colorNum, duration, null, forced);
		});

		Lua_helper.add_callback(lua, "cameraFade", function(camera:String, color:String, duration:Float, forced:Bool):Void
		{
			var colorNum:Int = Std.parseInt(color);
			if (!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

			cameraFromString(camera).fade(colorNum, duration, false, null, forced);
		});

		Lua_helper.add_callback(lua, "setAccuracy", function(value:Float):Void
		{
			PlayState.instance.songAccuracy = value;
		});

		Lua_helper.add_callback(lua, "setRatingName", function(value:String):Void
		{
			PlayState.instance.ratingString = value;
		});

		Lua_helper.add_callback(lua, "setRatingFC", function(value:String):Void
		{
			PlayState.instance.comboRank = value;
		});

		Lua_helper.add_callback(lua, "getMouseX", function(camera:String):Float
		{
			var cam:FlxCamera = cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).x;
		});

		Lua_helper.add_callback(lua, "getMouseY", function(camera:String):Float
		{
			var cam:FlxCamera = cameraFromString(camera);
			return FlxG.mouse.getScreenPosition(cam).y;
		});

		Lua_helper.add_callback(lua, "getMidpointX", function(variable:String):Float
		{
			var fieldArray:Array<String> = variable.split('.');
			var obj:FlxSprite = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				obj = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}
	
			if (obj != null) return obj.getMidpoint().x;

			return 0;
		});

		Lua_helper.add_callback(lua, "getMidpointY", function(variable:String):Float
		{
			var fieldArray:Array<String> = variable.split('.');
			var obj:FlxSprite = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				obj = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (obj != null) return obj.getMidpoint().y;

			return 0;
		});

		Lua_helper.add_callback(lua, "getGraphicMidpointX", function(variable:String):Float
		{
			var fieldArray:Array<String> = variable.split('.');
			var obj:FlxSprite = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				obj = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (obj != null) return obj.getGraphicMidpoint().x;

			return 0;
		});

		Lua_helper.add_callback(lua, "getGraphicMidpointY", function(variable:String):Float
		{
			var fieldArray:Array<String> = variable.split('.');
			var obj:FlxSprite = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				obj = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}
	
			if (obj != null) return obj.getGraphicMidpoint().y;

			return 0;
		});

		Lua_helper.add_callback(lua, "getScreenPositionX", function(variable:String):Float
		{
			var fieldArray:Array<String> = variable.split('.');
			var obj:FlxSprite = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				obj = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (obj != null) return obj.getScreenPosition().x;

			return 0;
		});

		Lua_helper.add_callback(lua, "getScreenPositionY", function(variable:String):Float
		{
			var fieldArray:Array<String> = variable.split('.');
			var obj:FlxSprite = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				obj = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (obj != null) return obj.getScreenPosition().y;

			return 0;
		});

		Lua_helper.add_callback(lua, "characterDance", function(curCharacter:String):Void
		{
			switch (curCharacter.toLowerCase())
			{
				case 'dad' | 'opponent': PlayState.instance.dad.dance();
				case 'gf' | 'girlfriend': if (PlayState.instance.gf != null) PlayState.instance.gf.dance();
				default: PlayState.instance.boyfriend.dance();
			}
		});

		Lua_helper.add_callback(lua, "getGlobalFromScript", function(?luaFile:String, ?global:String):Void // returns the global from a script
		{
			if (luaFile == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #1 to 'getGlobalFromScript' (string expected, got nil)");
				#end

				return;
			}

			if (global == null)
			{
				#if (linc_luajit >= "0.0.6")
				LuaL.error(lua, "bad argument #2 to 'getGlobalFromScript' (string expected, got nil)");
				#end
	
				return;
			}

			var cervix:String = luaFile + ".lua";
			if (luaFile.endsWith(".lua")) cervix = luaFile;

			var doPush:Bool = false;

			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix)) {
				doPush = true;
			}
			else 
			{
				cervix = Paths.getPreloadPath(cervix);

				if (FileSystem.exists(cervix)) {
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);

			if (Assets.exists(cervix)) {
				doPush = true;
			}
			#end

			if (doPush)
			{
				for (luaInstance in PlayState.instance.luaArray)
				{
					if (luaInstance.scriptName == cervix)
					{
						Lua.getglobal(luaInstance.lua, global);

						if (Lua.isnumber(luaInstance.lua, -1)) {
							Lua.pushnumber(lua, Lua.tonumber(luaInstance.lua, -1));
						}
						else if (Lua.isstring(luaInstance.lua, -1)) {
							Lua.pushstring(lua, Lua.tostring(luaInstance.lua, -1));
						}
						else if (Lua.isboolean(luaInstance.lua, -1)) {
							Lua.pushboolean(lua, Lua.toboolean(luaInstance.lua, -1));
						}
						else {
							Lua.pushnil(lua);
						}

						Lua.pop(luaInstance.lua,1);
						return;
					}
				}
			}
		});

		Lua_helper.add_callback(lua, "setGlobalFromScript", function(luaFile:String, global:String, val:Dynamic):Void // returns the global from a script
		{
			var cervix:String = luaFile + ".lua";
			if (luaFile.endsWith(".lua")) cervix = luaFile;

			var doPush:Bool = false;

			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix)) {
				doPush = true;
			}
			else
			{
				cervix = Paths.getPreloadPath(cervix);
	
				if (FileSystem.exists(cervix)) {
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);

			if (Assets.exists(cervix)) {
				doPush = true;
			}
			#end

			if (doPush)
			{
				for (luaInstance in PlayState.instance.luaArray)
				{
					if (luaInstance.scriptName == cervix) {
						luaInstance.set(global, val);
					}
				}
			}
		});

		Lua_helper.add_callback(lua, "isRunning", function(luaFile:String):Bool
		{
			var cervix:String = luaFile + ".lua";
			if (luaFile.endsWith(".lua")) cervix = luaFile;

			var doPush:Bool = false;

			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix)) {
				doPush = true;
			}
			else
			{
				cervix = Paths.getPreloadPath(cervix);

				if (FileSystem.exists(cervix)) {
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);

			if (Assets.exists(cervix)) {
				doPush = true;
			}
			#end

			if (doPush)
			{
				for (luaInstance in PlayState.instance.luaArray)
				{
					if (luaInstance.scriptName == cervix)
						return true;
				}
			}

			return false;
		});

		Lua_helper.add_callback(lua, "addLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false):Void // would be dope asf.
		{
			var cervix:String = luaFile + ".lua";
			if (luaFile.endsWith(".lua")) cervix = luaFile;

			var doPush:Bool = false;

			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix)) {
				doPush = true;
			}
			else
			{
				cervix = Paths.getPreloadPath(cervix);

				if (FileSystem.exists(cervix)) {
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);

			if (Assets.exists(cervix)) {
				doPush = true;
			}
			#end

			if (doPush)
			{
				if (!ignoreAlreadyRunning)
				{
					for (luaInstance in PlayState.instance.luaArray)
					{
						if (luaInstance.scriptName == cervix)
						{
							luaTrace('addLuaScript: The script "' + cervix + '" is already running!');
							return;
						}
					}
				}
	
				PlayState.instance.luaArray.push(new FunkinLua(cervix));
				return;
			}

			luaTrace("addLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "removeLuaScript", function(luaFile:String, ?ignoreAlreadyRunning:Bool = false):Void // would be dope asf.
		{
			var cervix:String = luaFile + ".lua";
			if (luaFile.endsWith(".lua")) cervix = luaFile;

			var doPush:Bool = false;

			#if MODS_ALLOWED
			if (FileSystem.exists(Paths.modFolders(cervix)))
			{
				cervix = Paths.modFolders(cervix);
				doPush = true;
			}
			else if (FileSystem.exists(cervix)) {
				doPush = true;
			}
			else
			{
				cervix = Paths.getPreloadPath(cervix);

				if (FileSystem.exists(cervix)) {
					doPush = true;
				}
			}
			#else
			cervix = Paths.getPreloadPath(cervix);

			if (Assets.exists(cervix)) {
				doPush = true;
			}
			#end

			if (doPush)
			{
				if (!ignoreAlreadyRunning)
				{
					for (luaInstance in PlayState.instance.luaArray)
					{
						if (luaInstance.scriptName == cervix)
						{
							PlayState.instance.luaArray.remove(luaInstance);
							return;
						}
					}
				}

				return;
			}

			luaTrace("removeLuaScript: Script doesn't exist!", false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "runHaxeCode", function(codeToRun:String):Dynamic
		{
			var retVal:Dynamic = null;

			#if hscript
			initHaxeModule();
	
			try {
				retVal = hscript.execute(codeToRun);
			}
			catch (e:Dynamic) {
				luaTrace(scriptName + ":" + lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			#else
			luaTrace("runHaxeCode: HScript isn't supported on this platform!", false, false, FlxColor.RED);
			#end

			if (retVal != null && !isOfTypes(retVal, [Bool, Int, Float, String, Array])) retVal = null;

			return retVal;
		});

		Lua_helper.add_callback(lua, "addHaxeLibrary", function(libName:String, ?libPackage:String = ''):Void
		{
			#if hscript
			initHaxeModule();
	
			try {
				hscript.variables.set(libName, Type.resolveClass((libPackage.length > 0 ? libPackage + '.' :  '') + libName));
			}
			catch (e:Dynamic) {
				luaTrace(scriptName + ":" + lastCalledFunction + " - " + e, false, false, FlxColor.RED);
			}
			#end
		});

		Lua_helper.add_callback(lua, "makeLuaSprite", function(tag:String, image:String, x:Float, y:Float):Void
		{
			tag = tag.replace('.', '');
			resetSpriteTag(tag);

			var leSprite:ModchartSprite = new ModchartSprite(x, y);
	
			if (image != null && image.length > 0) {
				leSprite.loadGraphic(Paths.getImage(image));
			}

			leSprite.antialiasing = OptionData.globalAntialiasing;

			PlayState.instance.modchartSprites.set(tag, leSprite);
			leSprite.active = true;
		});

		Lua_helper.add_callback(lua, "makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float, ?spriteType:String = "sparrow"):Void
		{
			tag = tag.replace('.', '');
			resetSpriteTag(tag);

			var leSprite:ModchartSprite = new ModchartSprite(x, y);

			loadFrames(leSprite, image, spriteType);

			leSprite.antialiasing = OptionData.globalAntialiasing;
			PlayState.instance.modchartSprites.set(tag, leSprite);
		});

		Lua_helper.add_callback(lua, "makeGraphic", function(obj:String, width:Int, height:Int, color:String):Void
		{
			var colorNum:Int = Std.parseInt(color);
			if (!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

			var spr:FlxSprite = PlayState.instance.getLuaObject(obj,false);
	
			if (spr != null)
			{
				PlayState.instance.getLuaObject(obj,false).makeGraphic(width, height, colorNum);
				return;
			}

			var object:FlxSprite = Reflect.getProperty(getInstance(), obj);

			if (object != null) {
				object.makeGraphic(width, height, colorNum);
			}
		});

		Lua_helper.add_callback(lua, "addAnimationByPrefix", function(obj:String, name:String, prefix:String, framerate:Int = 24, ?loop:Bool = false):Void
		{
			if (PlayState.instance.getLuaObject(obj,false) != null)
			{
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj,false);
				cock.animation.addByPrefix(name, prefix, framerate, loop);

				if (cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}

				return;
			}

			var cock:FlxSprite = Reflect.getProperty(getInstance(), obj);

			if (cock != null)
			{
				cock.animation.addByPrefix(name, prefix, framerate, loop);

				if (cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});

		Lua_helper.add_callback(lua, "addAnimation", function(obj:String, name:String, frames:Array<Int>, framerate:Int = 24, ?loop:Bool = false):Void
		{
			if (PlayState.instance.getLuaObject(obj, false) != null)
			{
				var cock:FlxSprite = PlayState.instance.getLuaObject(obj,false);
				cock.animation.add(name, frames, framerate, loop);

				if (cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}

				return;
			}

			var cock:FlxSprite = Reflect.getProperty(getInstance(), obj);

			if (cock != null)
			{
				cock.animation.add(name, frames, framerate, loop);

				if (cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});

		Lua_helper.add_callback(lua, "addAnimationByIndices", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, ?loop:Bool = false):Bool
		{
			return addAnimByIndices(obj, name, prefix, indices, framerate, loop);
		});

		Lua_helper.add_callback(lua, "addAnimationByIndicesLoop", function(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24):Bool
		{
			return addAnimByIndices(obj, name, prefix, indices, framerate, true);
		});

		Lua_helper.add_callback(lua, "playAnim", function(obj:String, name:String, forced:Bool = false, ?reverse:Bool = false, ?startFrame:Int = 0):Bool
		{
			if (PlayState.instance.getLuaObject(obj, false) != null)
			{
				var luaObj:FlxSprite = PlayState.instance.getLuaObject(obj,false);

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

				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);

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
	
				return true;
			}

			return false;
		});

		Lua_helper.add_callback(lua, "addOffset", function(obj:String, anim:String, x:Float, y:Float):Bool
		{
			if (PlayState.instance.modchartSprites.exists(obj))
			{
				PlayState.instance.modchartSprites.get(obj).animOffsets.set(anim, [x, y]);
				return true;
			}

			var char:Character = Reflect.getProperty(getInstance(), obj);

			if (char != null)
			{
				char.addOffset(anim, x, y);
				return true;
			}

			return false;
		});

		Lua_helper.add_callback(lua, "setScrollFactor", function(obj:String, scrollX:Float, scrollY:Float):Void
		{
			if (PlayState.instance.getLuaObject(obj,false) != null)
			{
				PlayState.instance.getLuaObject(obj,false).scrollFactor.set(scrollX, scrollY);
				return;
			}

			var object:FlxObject = Reflect.getProperty(getInstance(), obj);

			if (object != null) {
				object.scrollFactor.set(scrollX, scrollY);
			}
		});

		Lua_helper.add_callback(lua, "addLuaSprite", function(tag:String, behindWhom:Dynamic = 'gf'):Void
		{
			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var sprite:ModchartSprite = PlayState.instance.modchartSprites.get(tag);

				if (!sprite.wasAdded)
				{
					switch (behindWhom)
					{
						case 'before' | 'in front of' | 'afore' | 'ere' | 'front' | 'head' | true | 'true': {
							getInstance().add(sprite);
						}
						case 'dad' | 'opponent' | 1 | '1': {
							PlayState.instance.addBehindDad(sprite);
						}
						case 'bf' | 'boyfriend' | 0 | '0': {
							PlayState.instance.addBehindBF(sprite);
						}
						default:
						{
							var blyad:Bool = behindWhom == 'behind' ||
								behindWhom == 'posteriorly' ||
								behindWhom == 'aback' ||
								behindWhom == 'after' ||
								behindWhom == 'abaft' ||
								behindWhom == false ||
								behindWhom == 'false' ||
								behindWhom == 'back from' ||
								behindWhom == 'no before' ||
								behindWhom == 'no in front of' ||
								behindWhom == 'no afore' ||
								behindWhom == 'no ere' ||
								behindWhom == 'no front' ||
								behindWhom == 'no head' ||
								behindWhom == 'gf' ||
								behindWhom == 'girlfriend' ||
								behindWhom == '2' ||
								behindWhom == 2;

							if (blyad == true)
							{
								if (PlayState.instance.isDead) {
									GameOverSubState.instance.insert(PlayState.instance.members.indexOf(GameOverSubState.instance.boyfriend), sprite);
								}
								else {
									PlayState.instance.addBehindGF(sprite);
								}
							}
							else
							{
								var fieldArray:Array<String> = behindWhom.split('.');
								var leObj:FlxBasic = getObjectDirectly(fieldArray[0]);

								if (fieldArray.length > 1) {
									leObj = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
								}
					
								if (leObj != null) {
									PlayState.instance.insert(getInstance().members.indexOf(leObj), sprite);
								}
							}
						}
					}

					sprite.wasAdded = true;
					return;
				}
			}

			luaTrace("addLuaSprite: Couldnt find object: " + tag, false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "addBehindGF", function(tag:String):Void
		{
			var sprite:ModchartSprite = PlayState.instance.modchartSprites.get(tag);

			if (sprite != null)
			{
				addBehindGF(sprite);
				return
			}

			luaTrace("addBehindGF: Couldnt find object: " + tag, false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "addBehindDad", function(tag:Stringthis.scriptCode):Void
		{
			var sprite:ModchartSprite = PlayState.instance.modchartSprites.get(tag);

			if (sprite != null)
			{
				addBehindDad(sprite);
				return
			}

			luaTrace("addBehindDad: Couldnt find object: " + tag, false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "addBehindBF", function(tag:String):Void
		{
			var sprite:ModchartSprite = PlayState.instance.modchartSprites.get(tag);

			if (sprite != null)
			{
				addBehindBF(sprite);
				return
			}

			luaTrace("addBehindBF: Couldnt find object: " + tag, false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "setGraphicSize", function(obj:String, x:Int, y:Int = 0, updateHitbox:Bool = true):Void
		{
			if (PlayState.instance.getLuaObject(obj) != null)
			{
				var sprite:FlxSprite = PlayState.instance.getLuaObject(obj);
				sprite.setGraphicSize(x, y);

				if (updateHitbox) sprite.updateHitbox();

				return;
			}

			var fieldArray:Array<String> = obj.split('.');
			var sprite:FlxSprite = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				sprite = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (sprite != null)
			{
				sprite.setGraphicSize(x, y);
				if (updateHitbox) sprite.updateHitbox();

				return;
			}
	
			luaTrace('setGraphicSize: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "scaleObject", function(obj:String, x:Float, y:Float, updateHitbox:Bool = true):Void
		{
			if (PlayState.instance.getLuaObject(obj) != null)
			{
				var sprite:FlxSprite = PlayState.instance.getLuaObject(obj);
				sprite.scale.set(x, y);

				if (updateHitbox) sprite.updateHitbox();

				return;
			}

			var fieldArray:Array<String> = obj.split('.');
			var sprite:FlxSprite = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				sprite = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (sprite != null)
			{
				sprite.scale.set(x, y);
				if (updateHitbox) sprite.updateHitbox();

				return;
			}

			luaTrace('scaleObject: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "updateHitbox", function(obj:String):Void
		{
			if (PlayState.instance.getLuaObject(obj) != null)
			{
				var sprite:FlxSprite = PlayState.instance.getLuaObject(obj);
				sprite.updateHitbox();

				return;
			}

			var sprite:FlxSprite = Reflect.getProperty(getInstance(), obj);

			if (sprite != null)
			{
				sprite.updateHitbox();
				return;
			}
	
			luaTrace('updateHitbox: Couldnt find object: ' + obj, false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "updateHitboxFromGroup", function(group:String, index:Int):Void
		{
			if (Std.isOfType(Reflect.getProperty(getInstance(), group), FlxTypedGroup))
			{
				Reflect.getProperty(getInstance(), group).members[index].updateHitbox();
				return;
			}

			Reflect.getProperty(getInstance(), group)[index].updateHitbox();
		});

		Lua_helper.add_callback(lua, "removeLuaSprite", function(tag:String, destroy:Bool = true):Void
		{
			if (!PlayState.instance.modchartSprites.exists(tag)) {
				return;
			}

			var sprite:ModchartSprite = PlayState.instance.modchartSprites.get(tag);

			if (destroy) {
				sprite.kill();
			}

			if (sprite.wasAdded)
			{
				getInstance().remove(sprite, true);
				sprite.wasAdded = false;
			}

			if (destroy)
			{
				sprite.destroy();
				PlayState.instance.modchartSprites.remove(tag);
			}
		});

		Lua_helper.add_callback(lua, "luaSpriteExists", function(tag:String):Bool
		{
			return PlayState.instance.modchartSprites.exists(tag);
		});

		Lua_helper.add_callback(lua, "luaTextExists", function(tag:String):Bool
		{
			return PlayState.instance.modchartTexts.exists(tag);
		});

		Lua_helper.add_callback(lua, "luaSoundExists", function(tag:String):Bool
		{
			return PlayState.instance.modchartSounds.exists(tag);
		});

		Lua_helper.add_callback(lua, "setHealthBarColors", function(leftHex:String, rightHex:String):Void
		{
			var left:FlxColor = Std.parseInt(leftHex);
			if (!leftHex.startsWith('0x')) left = Std.parseInt('0xff' + leftHex);

			var right:FlxColor = Std.parseInt(rightHex);
			if (!rightHex.startsWith('0x')) right = Std.parseInt('0xff' + rightHex);

			PlayState.instance.healthBar.createFilledBar(left, right);
			PlayState.instance.healthBar.updateBar();
		});

		Lua_helper.add_callback(lua, "setObjectCamera", function(obj:String, camera:String = ''):Bool
		{
			var real = PlayState.instance.getLuaObject(obj);

			if (real != null)
			{
				real.cameras = [cameraFromString(camera)];
				return true;
			}

			var fieldArray:Array<String> = obj.split('.');
			var object:FlxSprite = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1)
			{
				object = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (object != null)
			{
				object.cameras = [cameraFromString(camera)];
				return true;
			}

			luaTrace("setObjectCamera: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "setBlendMode", function(obj:String, blend:String = ''):Bool
		{
			var real = PlayState.instance.getLuaObject(obj);

			if (real != null)
			{
				real.blend = blendModeFromString(blend);
				return true;
			}

			var fieldArray:Array<String> = obj.split('.');
			var spr:FlxSprite = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				spr = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (spr != null)
			{
				spr.blend = blendModeFromString(blend);
				return true;
			}

			luaTrace("setBlendMode: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "screenCenter", function(obj:String, pos:String = 'xy'):Void
		{
			var spr:FlxSprite = PlayState.instance.getLuaObject(obj);

			if (spr == null)
			{
				var fieldArray:Array<String> = obj.split('.');
				spr = getObjectDirectly(fieldArray[0]);

				if (fieldArray.length > 1) {
					spr = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
				}
			}

			if (spr != null)
			{
				switch (pos.trim().toLowerCase())
				{
					case 'x':
					{
						spr.screenCenter(X);
						return;
					}
					case 'y':
					{
						spr.screenCenter(Y);
						return;
					}
					default:
					{
						spr.screenCenter(XY);
						return;
					}
				}
			}

			luaTrace("screenCenter: Object " + obj + " doesn't exist!", false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "objectsOverlap", function(obj1:String, obj2:String):Bool
		{
			var namesArray:Array<String> = [obj1, obj2];
			var objectsArray:Array<FlxSprite> = [];

			for (i in 0...namesArray.length)
			{
				var real = PlayState.instance.getLuaObject(namesArray[i]);
	
				if (real != null) {
					objectsArray.push(real);
				}
				else {
					objectsArray.push(Reflect.getProperty(getInstance(), namesArray[i]));
				}
			}

			if (!objectsArray.contains(null) && FlxG.overlap(objectsArray[0], objectsArray[1])) {
				return true;
			}

			return false;
		});

		Lua_helper.add_callback(lua, "getPixelColor", function(obj:String, x:Int, y:Int):Int
		{
			var fieldArray:Array<String> = obj.split('.');
			var spr:FlxSprite = getObjectDirectly(fieldArray[0]);

			if (fieldArray.length > 1) {
				spr = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
			}

			if (spr != null)
			{
				if (spr.framePixels != null) spr.framePixels.getPixel32(x, y);
				return spr.pixels.getPixel32(x, y);
			}

			return 0;
		});

		Lua_helper.add_callback(lua, "getRandomInt", function(min:Int, max:Int = FlxMath.MAX_VALUE_INT, exclude:String = ''):Int
		{
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Int> = [];

			for (i in 0...excludeArray.length) {
				toExclude.push(Std.parseInt(excludeArray[i].trim()));
			}

			return FlxG.random.int(min, max, toExclude);
		});

		Lua_helper.add_callback(lua, "getRandomFloat", function(min:Float, max:Float = 1, exclude:String = ''):Float
		{
			var excludeArray:Array<String> = exclude.split(',');
			var toExclude:Array<Float> = [];

			for (i in 0...excludeArray.length) {
				toExclude.push(Std.parseFloat(excludeArray[i].trim()));
			}

			return FlxG.random.float(min, max, toExclude);
		});

		Lua_helper.add_callback(lua, "getRandomBool", function(chance:Float = 50):Bool
		{
			return FlxG.random.bool(chance);
		});

		Lua_helper.add_callback(lua, "startDialogue", function(dialogueFile:String, music:String = null):Bool
		{
			var path:String = null;

			#if MODS_ALLOWED
			path = Paths.modsJson(PlayState.SONG.songID + '/' + dialogueFile);
			if (!FileSystem.exists(path))
			#end
				path = Paths.getJson(PlayState.SONG.songID + '/' + dialogueFile);

			luaTrace('startDialogue: Trying to load dialogue: ' + path);

			#if MODS_ALLOWED
			if (FileSystem.exists(path))
			#else
			if (Assets.exists(path))
			#end
			{
				var dialogue:DialogueFile = DialogueBoxPsych.parseDialogue(path);

				if (dialogue.dialogue.length > 0)
				{
					PlayState.instance.startDialogue(dialogue, music);
					luaTrace('startDialogue: Successfully loaded dialogue', false, false, FlxColor.GREEN);

					return true;
				}
				else {
					luaTrace('startDialogue: Your dialogue file is badly formatted!', false, false, FlxColor.RED);
				}
			}
			else
			{
				luaTrace('startDialogue: Dialogue file not found', false, false, FlxColor.RED);

				if (PlayState.instance.endingSong) {
					PlayState.instance.endSong();
				}
				else {
					PlayState.instance.startCountdown();
				}
			}

			return false;
		});

		Lua_helper.add_callback(lua, "startVideo", function(videoFile:String, type:String = 'mp4'):Void
		{
			switch (type)
			{
				case 'webm':
				{
					#if WEBM_ALLOWED
					if (FileSystem.exists(Paths.getWebm(videoFile)))
					{
						PlayState.instance.startVideo(videoFile, type);
						return;
					}

					luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
					#else
					luaTrace('startVideo: Platform not supported!', false, false, FlxColor.RED);
					PlayState.instance.startAndEnd();
					#end
				}
				default:
				{
					#if MP4_ALLOWED
					if (FileSystem.exists(Paths.getVideo(videoFile)))
					{
						PlayState.instance.startVideo(videoFile, type);
						return;
					}

					luaTrace('startVideo: Video file not found: ' + videoFile, false, false, FlxColor.RED);
					#else
					luaTrace('startVideo: Platform not supported!', false, false, FlxColor.RED);
					PlayState.instance.startAndEnd();
					#end
				}
			}
		});

		Lua_helper.add_callback(lua, "backgroundVideo", function(video:String):Void
		{
			PlayState.instance.backgroundVideo(video);
		});

		Lua_helper.add_callback(lua, "makeBackgroundTheVideo", function(video:String, with:Dynamic):Void
		{
			PlayState.instance.makeBackgroundTheVideo(video, with);
		});

		Lua_helper.add_callback(lua, "endBGVideo", function():Void
		{
			PlayState.instance.endBGVideo();
		});

		Lua_helper.add_callback(lua, "playMusic", function(sound:String, volume:Float = 1, loop:Bool = false):Void
		{
			FlxG.sound.playMusic(Paths.getMusic(sound), volume, loop);
		});

		Lua_helper.add_callback(lua, "playSound", function(sound:String, volume:Float = 1, ?tag:String = null):Void
		{
			if (tag != null && tag.length > 0)
			{
				tag = tag.replace('.', '');
		
				if (PlayState.instance.modchartSounds.exists(tag)) {
					PlayState.instance.modchartSounds.get(tag).stop();
				}
			
				PlayState.instance.modchartSounds.set(tag, FlxG.sound.play(Paths.getSound(sound), volume, false, function()
				{
					PlayState.instance.modchartSounds.remove(tag);
					PlayState.instance.callOnLuas('onSoundFinished', [tag]);
				}));
			
				return;
			}
	
			FlxG.sound.play(Paths.getSound(sound), volume);
		});

		Lua_helper.add_callback(lua, "stopSound", function(tag:String):Void
		{
			if (tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag))
			{
				PlayState.instance.modchartSounds.get(tag).stop();
				PlayState.instance.modchartSounds.remove(tag);
			}
		});

		Lua_helper.add_callback(lua, "pauseSound", function(tag:String):Void
		{
			if (tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).pause();
			}
		});

		Lua_helper.add_callback(lua, "resumeSound", function(tag:String):Void
		{
			if (tag != null && tag.length > 1 && PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).play();
			}
		});

		Lua_helper.add_callback(lua, "soundFadeIn", function(tag:String, duration:Float, fromValue:Float = 0, toValue:Float = 1):Void
		{
			if (tag == null || tag.length < 1) {
				FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			}
			else if (PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).fadeIn(duration, fromValue, toValue);
			}
		});

		Lua_helper.add_callback(lua, "soundFadeOut", function(tag:String, duration:Float, toValue:Float = 0):Void
		{
			if (tag == null || tag.length < 1) {
				FlxG.sound.music.fadeOut(duration, toValue);
			}
			else if (PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).fadeOut(duration, toValue);
			}
		});

		Lua_helper.add_callback(lua, "soundFadeCancel", function(tag:String):Void
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music.fadeTween != null) {
					FlxG.sound.music.fadeTween.cancel();
				}
			}
			else if (PlayState.instance.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);

				if (theSound.fadeTween != null)
				{
					theSound.fadeTween.cancel();
					PlayState.instance.modchartSounds.remove(tag);
				}
			}
		});

		Lua_helper.add_callback(lua, "getSoundVolume", function(tag:String):Float
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null) {
					return FlxG.sound.music.volume;
				}
			}
			else if (PlayState.instance.modchartSounds.exists(tag)) {
				return PlayState.instance.modchartSounds.get(tag).volume;
			}

			return 0;
		});

		Lua_helper.add_callback(lua, "setSoundVolume", function(tag:String, value:Float):Void
		{
			if (tag == null || tag.length < 1)
			{
				if (FlxG.sound.music != null) {
					FlxG.sound.music.volume = value;
				}
			}
			else if (PlayState.instance.modchartSounds.exists(tag)) {
				PlayState.instance.modchartSounds.get(tag).volume = value;
			}
		});

		Lua_helper.add_callback(lua, "getSoundTime", function(tag:String):Float
		{
			if (tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag)) {
				return PlayState.instance.modchartSounds.get(tag).time;
			}

			return 0;
		});

		Lua_helper.add_callback(lua, "setSoundTime", function(tag:String, value:Float):Void
		{
			if (tag != null && tag.length > 0 && PlayState.instance.modchartSounds.exists(tag))
			{
				var theSound:FlxSound = PlayState.instance.modchartSounds.get(tag);

				if (theSound != null)
				{
					var wasResumed:Bool = theSound.playing;
					theSound.pause();
					theSound.time = value;

					if (wasResumed) theSound.play();
				}
			}
		});

		Lua_helper.add_callback(lua, "debugPrint", function(text1:Dynamic = '', text2:Dynamic = '', text3:Dynamic = '', text4:Dynamic = '', text5:Dynamic = ''):Void
		{
			if (text1 == null) text1 = '';
			if (text2 == null) text2 = '';
			if (text3 == null) text3 = '';
			if (text4 == null) text4 = '';
			if (text5 == null) text5 = '';

			luaTrace('' + text1 + text2 + text3 + text4 + text5, true, false);
		});
		
		Lua_helper.add_callback(lua, "close", function():Bool
		{
			closed = true;
			return closed;
		});

		Lua_helper.add_callback(lua, "makeLuaText", function(tag:String, text:String, width:Int, x:Float, y:Float):Void // LUA TEXTS
		{
			tag = tag.replace('.', '');
			resetTextTag(tag);

			var leText:ModchartText = new ModchartText(x, y, text, width);
			PlayState.instance.modchartTexts.set(tag, leText);
		});

		Lua_helper.add_callback(lua, "setTextString", function(tag:String, text:String):Bool
		{
			var obj:FlxText = getTextObject(tag);

			if (obj != null)
			{
				obj.text = text;
				return true;
			}

			luaTrace("setTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "setTextSize", function(tag:String, size:Int):Bool
		{
			var obj:FlxText = getTextObject(tag);

			if (obj != null)
			{
				obj.size = size;
				return true;
			}

			luaTrace("setTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "setTextWidth", function(tag:String, width:Float):Bool
		{
			var obj:FlxText = getTextObject(tag);

			if (obj != null)
			{
				obj.fieldWidth = width;
				return true;
			}

			luaTrace("setTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "setTextBorder", function(tag:String, size:Int, color:String):Bool
		{
			var obj:FlxText = getTextObject(tag);

			if (obj != null)
			{
				var colorNum:Int = Std.parseInt(color);
				if (!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				obj.borderSize = size;
				obj.borderColor = colorNum;
				return true;
			}

			luaTrace("setTextBorder: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "setTextColor", function(tag:String, color:String):Bool
		{
			var obj:FlxText = getTextObject(tag);

			if (obj != null)
			{
				var colorNum:Int = Std.parseInt(color);
				if (!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				obj.color = colorNum;
				return true;
			}

			luaTrace("setTextColor: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "setTextFont", function(tag:String, newFont:String):Bool
		{
			var obj:FlxText = getTextObject(tag);

			if (obj != null)
			{
				obj.font = Paths.getFont(newFont);
				return true;
			}

			luaTrace("setTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "setTextItalic", function(tag:String, italic:Bool):Bool
		{
			var obj:FlxText = getTextObject(tag);

			if (obj != null)
			{
				obj.italic = italic;
				return true;
			}

			luaTrace("setTextItalic: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "setTextAlignment", function(tag:String, alignment:String = 'left'):Bool
		{
			var obj:FlxText = getTextObject(tag);

			if (obj != null)
			{
				obj.alignment = LEFT;
	
				switch (alignment.trim().toLowerCase())
				{
					case 'right':
						obj.alignment = RIGHT;
					case 'center':
						obj.alignment = CENTER;
				}

				return true;
			}

			luaTrace("setTextAlignment: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return false;
		});

		Lua_helper.add_callback(lua, "getTextString", function(tag:String):String
		{
			var obj:FlxText = getTextObject(tag);

			if (obj != null) {
				return obj.text;
			}

			luaTrace("getTextString: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return null;
		});

		Lua_helper.add_callback(lua, "getTextSize", function(tag:String):Float
		{
			var obj:FlxText = getTextObject(tag);

			if (obj != null) {
				return obj.size;
			}

			luaTrace("getTextSize: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return -1;
		});

		Lua_helper.add_callback(lua, "getTextFont", function(tag:String):String
		{
			var obj:FlxText = getTextObject(tag);

			if (obj != null) {
				return obj.font;
			}

			luaTrace("getTextFont: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			
			return null;
		});

		Lua_helper.add_callback(lua, "getTextWidth", function(tag:String):Float
		{
			var obj:FlxText = getTextObject(tag);

			if (obj != null) {
				return obj.fieldWidth;
			}

			luaTrace("getTextWidth: Object " + tag + " doesn't exist!", false, false, FlxColor.RED);
			return 0;
		});

		Lua_helper.add_callback(lua, "addLuaText", function(tag:String):Void
		{
			if (PlayState.instance.modchartTexts.exists(tag))
			{
				var text:ModchartText = PlayState.instance.modchartTexts.get(tag);

				if (!text.wasAdded)
				{
					getInstance().add(text);
					text.wasAdded = true;
				}
			}
		});

		Lua_helper.add_callback(lua, "removeLuaText", function(tag:String, destroy:Bool = true):Void
		{
			if (!PlayState.instance.modchartTexts.exists(tag)) {
				return;
			}

			var sprite:ModchartText = PlayState.instance.modchartTexts.get(tag);

			if (destroy) {
				sprite.kill();
			}

			if (sprite.wasAdded)
			{
				getInstance().remove(sprite, true);
				sprite.wasAdded = false;
			}

			if (destroy)
			{
				sprite.destroy();
				PlayState.instance.modchartTexts.remove(tag);
			}
		});

		Lua_helper.add_callback(lua, "initSaveData", function(name:String, ?folder:String = 'affordset'):Void
		{
			if (!PlayState.instance.modchartSaves.exists(name))
			{
				var save:FlxSave = new FlxSave();
				save.bind(name, CoolUtil.getSavePath(folder));
				PlayState.instance.modchartSaves.set(name, save);

				return;
			}
	
			luaTrace('initSaveData: Save file already initialized: ' + name);
		});

		Lua_helper.add_callback(lua, "flushSaveData", function(name:String):Void
		{
			if (PlayState.instance.modchartSaves.exists(name))
			{
				PlayState.instance.modchartSaves.get(name).flush();
				return;
			}

			luaTrace('flushSaveData: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "getDataFromSave", function(name:String, field:String):Dynamic
		{
			if (PlayState.instance.modchartSaves.exists(name))
			{
				var retVal:Dynamic = Reflect.field(PlayState.instance.modchartSaves.get(name).data, field);
				return retVal;
			}

			luaTrace('getDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
			return null;
		});

		Lua_helper.add_callback(lua, "setDataFromSave", function(name:String, field:String, value:Dynamic):Void
		{
			if (PlayState.instance.modchartSaves.exists(name))
			{
				Reflect.setField(PlayState.instance.modchartSaves.get(name).data, field, value);
				return;
			}

			luaTrace('setDataFromSave: Save file not initialized: ' + name, false, false, FlxColor.RED);
		});

		Lua_helper.add_callback(lua, "checkFileExists", function(filename:String, ?absolute:Bool = false):Bool
		{
			#if MODS_ALLOWED
			if (absolute) {
				return FileSystem.exists(filename);
			}

			var path:String = Paths.modFolders(filename);

			if (FileSystem.exists(path)) {
				return true;
			}
			return FileSystem.exists(Paths.getPath('assets/$filename', TEXT));
			#else
			if (absolute) {
				return Assets.exists(filename);
			}
			return Assets.exists(Paths.getPath('assets/$filename', TEXT));
			#end
		});

		Lua_helper.add_callback(lua, "saveFile", function(path:String, content:String, ?absolute:Bool = false):Bool
		{
			try
			{
				if (!absolute) {
					File.saveContent(Paths.mods(path), content);
				}
				else {
					File.saveContent(path, content);
				}

				return true;
			}
			catch (e:Dynamic) {
				luaTrace("saveFile: Error trying to save " + path + ": " + e, false, false, FlxColor.RED);
			}

			return false;
		});

		Lua_helper.add_callback(lua, "deleteFile", function(path:String, ?ignoreModFolders:Bool = false):Bool
		{
			try
			{
				#if MODS_ALLOWED
				if (!ignoreModFolders)
				{
					var lePath:String = Paths.modFolders(path);

					if (FileSystem.exists(lePath))
					{
						FileSystem.deleteFile(lePath);
						return true;
					}
				}
				#end

				var lePath:String = Paths.getPath(path, TEXT);

				if (Assets.exists(lePath))
				{
					FileSystem.deleteFile(lePath);
					return true;
				}
			}
			catch (e:Dynamic) {
				luaTrace("deleteFile: Error trying to delete " + path + ": " + e, false, false, FlxColor.RED);
			}

			return false;
		});

		Lua_helper.add_callback(lua, "getTextFromFile", function(path:String, ?ignoreModFolders:Bool = false):String
		{
			return Paths.getTextFromFile(path, ignoreModFolders);
		});

		Lua_helper.add_callback(lua, "objectPlayAnimation", function(obj:String, name:String, forced:Bool = false, ?startFrame:Int = 0):Bool // DEPRECATED, DONT MESS WITH THESE SHITS, ITS JUST THERE FOR BACKWARD COMPATIBILITY
		{
			luaTrace("objectPlayAnimation is deprecated! Use playAnim instead", false, true);

			if (PlayState.instance.getLuaObject(obj,false) != null)
			{
				PlayState.instance.getLuaObject(obj,false).animation.play(name, forced, false, startFrame);
				return true;
			}

			var spr:FlxSprite = Reflect.getProperty(getInstance(), obj);

			if (spr != null)
			{
				spr.animation.play(name, forced, false, startFrame);
				return true;
			}

			return false;
		});

		Lua_helper.add_callback(lua, "characterPlayAnim", function(curCharacter:String, anim:String, ?forced:Bool = false):Void
		{
			luaTrace("characterPlayAnim is deprecated! Use playAnim instead", false, true);

			switch (curCharacter.toLowerCase())
			{
				case 'dad':
				{
					if (PlayState.instance.dad.animOffsets.exists(anim)) {
						PlayState.instance.dad.playAnim(anim, forced);
					}
				}
				case 'gf' | 'girlfriend':
				{
					if (PlayState.instance.gf != null && PlayState.instance.gf.animOffsets.exists(anim)) {
						PlayState.instance.gf.playAnim(anim, forced);
					}
				}
				default:
				{
					if (PlayState.instance.boyfriend.animOffsets.exists(anim)) {
						PlayState.instance.boyfriend.playAnim(anim, forced);
					}
				}
			}
		});

		Lua_helper.add_callback(lua, "luaSpriteMakeGraphic", function(tag:String, width:Int, height:Int, color:String):Void
		{
			luaTrace("luaSpriteMakeGraphic is deprecated! Use makeGraphic instead", false, true);

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var colorNum:Int = Std.parseInt(color);
				if (!color.startsWith('0x')) colorNum = Std.parseInt('0xff' + color);

				PlayState.instance.modchartSprites.get(tag).makeGraphic(width, height, colorNum);
			}
		});

		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true):Void
		{
			luaTrace("luaSpriteAddAnimationByPrefix is deprecated! Use addAnimationByPrefix instead", false, true);

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var cock:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
	
				if (cock.animation.curAnim == null) {
					cock.animation.play(name, true);
				}
			}
		});

		Lua_helper.add_callback(lua, "luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24):Void
		{
			luaTrace("luaSpriteAddAnimationByIndices is deprecated! Use addAnimationByIndices instead", false, true);

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];

				for (i in 0...strIndices.length) {
					die.push(Std.parseInt(strIndices[i]));
				}

				var pussy:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);

				if (pussy.animation.curAnim == null) {
					pussy.animation.play(name, true);
				}
			}
		});

		Lua_helper.add_callback(lua, "luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false):Void
		{
			luaTrace("luaSpritePlayAnimation is deprecated! Use playAnim instead", false, true);

			if (PlayState.instance.modchartSprites.exists(tag)) {
				PlayState.instance.modchartSprites.get(tag).animation.play(name, forced);
			}
		});

		Lua_helper.add_callback(lua, "setLuaSpriteCamera", function(tag:String, camera:String = ''):Bool
		{
			luaTrace("setLuaSpriteCamera is deprecated! Use setObjectCamera instead", false, true);

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				PlayState.instance.modchartSprites.get(tag).cameras = [cameraFromString(camera)];
				return true;
			}

			luaTrace("Lua sprite with tag: " + tag + " doesn't exist!");

			return false;
		});

		Lua_helper.add_callback(lua, "setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float):Bool
		{
			luaTrace("setLuaSpriteScrollFactor is deprecated! Use setScrollFactor instead", false, true);
	
			if (PlayState.instance.modchartSprites.exists(tag))
			{
				PlayState.instance.modchartSprites.get(tag).scrollFactor.set(scrollX, scrollY);
				return true;
			}
	
			return false;
		});

		Lua_helper.add_callback(lua, "scaleLuaSprite", function(tag:String, x:Float, y:Float):Bool
		{
			luaTrace("scaleLuaSprite is deprecated! Use scaleObject instead", false, true);

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var sprite:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
				sprite.scale.set(x, y);
				sprite.updateHitbox();

				return true;
			}

			return false;
		});

		Lua_helper.add_callback(lua, "getPropertyLuaSprite", function(tag:String, variable:String):Dynamic
		{
			luaTrace("getPropertyLuaSprite is deprecated! Use getProperty instead", false, true);

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var fieldArray:Array<String> = variable.split('.');

				if (fieldArray.length > 1)
				{
					var fieldFromSprite:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), fieldArray[0]);
	
					for (i in 1...fieldArray.length - 1) {
						fieldFromSprite = Reflect.getProperty(fieldFromSprite, fieldArray[i]);
					}
	
					return Reflect.getProperty(fieldFromSprite, fieldArray[fieldArray.length - 1]);
				}
	
				return Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), variable);
			}

			return null;
		});

		Lua_helper.add_callback(lua, "setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic):Bool
		{
			luaTrace("setPropertyLuaSprite is deprecated! Use setProperty instead", false, true);

			if (PlayState.instance.modchartSprites.exists(tag))
			{
				var fieldArray:Array<String> = variable.split('.');

				if (fieldArray.length > 1)
				{
					var fieldFromSprite:Dynamic = Reflect.getProperty(PlayState.instance.modchartSprites.get(tag), fieldArray[0]);

					for (i in 1...fieldArray.length - 1) {
						fieldFromSprite = Reflect.getProperty(fieldFromSprite, fieldArray[i]);
					}
	
					Reflect.setProperty(fieldFromSprite, fieldArray[fieldArray.length - 1], value);
					return true;
				}
	
				Reflect.setProperty(PlayState.instance.modchartSprites.get(tag), variable, value);
				return true;
			}

			luaTrace("setPropertyLuaSprite: Lua sprite with tag: " + tag + " doesn't exist!");

			return false;
		});

		Lua_helper.add_callback(lua, "musicFadeIn", function(duration:Float, fromValue:Float = 0, toValue:Float = 1):Void
		{
			FlxG.sound.music.fadeIn(duration, fromValue, toValue);
			luaTrace('musicFadeIn is deprecated! Use soundFadeIn instead.', false, true);
		});

		Lua_helper.add_callback(lua, "musicFadeOut", function(duration:Float, toValue:Float = 0):Void
		{
			FlxG.sound.music.fadeOut(duration, toValue);
			luaTrace('musicFadeOut is deprecated! Use soundFadeOut instead.', false, true);
		});

		Lua_helper.add_callback(lua, "stringStartsWith", function(str:String, start:String):Bool
		{
			return str.startsWith(start);
		});

		Lua_helper.add_callback(lua, "stringEndsWith", function(str:String, end:String):Bool
		{
			return str.endsWith(end);
		});

		Lua_helper.add_callback(lua, "stringContains", function(str:String, whatThe:String):Bool
		{
			return str.contains(whatThe);
		});

		Lua_helper.add_callback(lua, "stringSplit", function(str:String, split:String):Array<String>
		{
			return str.split(split);
		});

		Lua_helper.add_callback(lua, "stringTrim", function(str:String):String
		{
			return str.trim();
		});

		Lua_helper.add_callback(lua, "directoryFileList", function(folder:String):Array<String>
		{
			var list:Array<String> = [];

			#if sys
			if (FileSystem.exists(folder))
			{
				for (folder in FileSystem.readDirectory(folder))
				{
					if (!list.contains(folder)) {
						list.push(folder);
					}
				}
			}
			#end

			return list;
		});

		#if DISCORD_ALLOWED
		DiscordClient.addLuaCallbacks(lua);
		#end

		call('onCreate', []);
		#end
	}

	public static function isOfTypes(value:Any, types:Array<Dynamic>):Bool
	{
		for (type in types) {
			return Std.isOfType(value, type);
		}
	
		return false;
	}

	#if hscript
	public function initHaxeModule():Void
	{
		if (hscript == null)
		{
			Debug.logInfo('initializing haxe interp for: $scriptName');
			hscript = new HScript(); //TO DO: Fix issue with 2 scripts not being able to use the same variable names
		}
	}
	#end

	public static function setVarInArray(instance:Dynamic, variable:String, value:Dynamic):Any
	{
		var field:Array<String> = variable.split('[');

		if (field.length > 1)
		{
			var blah:Dynamic = null;

			if (PlayState.instance.variables.exists(field[0]))
			{
				var retVal:Dynamic = PlayState.instance.variables.get(field[0]);

				if (retVal != null) {
					blah = retVal;
				}
			}
			else {
				blah = Reflect.getProperty(instance, field[0]);
			}

			for (i in 1...field.length)
			{
				var leNum:Dynamic = field[i].substr(0, field[i].length - 1);

				if (i >= field.length - 1) { // Last array
					blah[leNum] = value;
				}
				else { // Anything else
					blah = blah[leNum];
				}
			}

			return blah;
		}

		if (PlayState.instance.variables.exists(variable))
		{
			PlayState.instance.variables.set(variable, value);
			return true;
		}

		Reflect.setProperty(instance, variable, value);
		return true;
	}

	public static function getVarInArray(instance:Dynamic, variable:String):Any
	{
		var field:Array<String> = variable.split('[');

		if (field.length > 1)
		{
			var blah:Dynamic = null;

			if (PlayState.instance.variables.exists(field[0]))
			{
				var retVal:Dynamic = PlayState.instance.variables.get(field[0]);

				if (retVal != null) {
					blah = retVal;
				}
			}
			else {
				blah = Reflect.getProperty(instance, field[0]);
			}

			for (i in 1...field.length)
			{
				var leNum:Dynamic = field[i].substr(0, field[i].length - 1);
				blah = blah[leNum];
			}

			return blah;
		}

		if (PlayState.instance.variables.exists(variable))
		{
			var retVal:Dynamic = PlayState.instance.variables.get(variable);

			if (retVal != null) {
				return retVal;
			}
		}

		return Reflect.getProperty(instance, variable);
	}

	public static function getTextObject(name:String):FlxText
	{
		return PlayState.instance.modchartTexts.exists(name) ? PlayState.instance.modchartTexts.get(name) : Reflect.getProperty(PlayState.instance, name);
	}

	#if (!flash && MODS_ALLOWED)
	public function getShader(obj:String):FlxRuntimeShader
	{
		var fieldArray:Array<String> = obj.split('.');
		var leObj:FlxSprite = getObjectDirectly(fieldArray[0]);

		if (fieldArray.length > 1) {
			leObj = getVarInArray(getPropertyLoopThingWhatever(fieldArray), fieldArray[fieldArray.length - 1]);
		}

		if (leObj != null)
		{
			var shader:Dynamic = leObj.shader;
			var shader:FlxRuntimeShader = shader;

			return shader;
		}

		return null;
	}

	function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if (!OptionData.shaders) return false;

		#if (!flash && MODS_ALLOWED)
		if (PlayState.instance.runtimeShaders.exists(name))
		{
			luaTrace('Shader $name was already initialized!');
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
				else frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if (found)
				{
					PlayState.instance.runtimeShaders.set(name, [frag, vert]);
					return true;
				}
			}
		}
		luaTrace('Missing shader $name .frag AND .vert files!', false, false, FlxColor.RED);
		#else
		luaTrace('This platform doesn\'t support Runtime Shaders!', false, false, FlxColor.RED);
		#end

		return false;
	}
	#end

	public static function getGroupStuff(leArray:Dynamic, variable:String):Dynamic
	{
		var fieldArray:Array<String> = variable.split('.');

		if (fieldArray.length > 1)
		{
			var fieldFromArray:Dynamic = Reflect.getProperty(leArray, fieldArray[0]);

			for (i in 1...fieldArray.length - 1) {
				fieldFromArray = Reflect.getProperty(fieldFromArray, fieldArray[i]);
			}

			switch (Type.typeof(fieldFromArray))
			{
				case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
					return fieldFromArray.get(fieldArray[fieldArray.length - 1]);
				default:
					return Reflect.getProperty(fieldFromArray, fieldArray[fieldArray.length - 1]);
			};
		}

		switch (Type.typeof(leArray))
		{
			case ValueType.TClass(haxe.ds.StringMap) | ValueType.TClass(haxe.ds.ObjectMap) | ValueType.TClass(haxe.ds.IntMap) | ValueType.TClass(haxe.ds.EnumValueMap):
				return leArray.get(variable);
			default:
				return Reflect.getProperty(leArray, variable);
		}

		return null;
	}

	function loadFrames(spr:FlxSprite, image:String, spriteType:String):Void
	{
		switch (spriteType.toLowerCase().trim())
		{
			case "texture" | "textureatlas" | "tex":
				spr.frames = AtlasFrameMaker.construct(image);
			case "texture_noaa" | "textureatlas_noaa" | "tex_noaa":
				spr.frames = AtlasFrameMaker.construct(image, null, true);
			case "packer" | "packeratlas" | "pac":
				spr.frames = Paths.getPackerAtlas(image);
			default:
				spr.frames = Paths.getSparrowAtlas(image);
		}
	}

	public static function setGroupStuff(leArray:Dynamic, variable:String, value:Dynamic):Void
	{
		var fieldArray:Array<String> = variable.split('.');

		if (fieldArray.length > 1)
		{
			var fieldFromArray:Dynamic = Reflect.getProperty(leArray, fieldArray[0]);

			for (i in 1...fieldArray.length - 1) {
				fieldFromArray = Reflect.getProperty(fieldFromArray, fieldArray[i]);
			}

			Reflect.setProperty(fieldFromArray, fieldArray[fieldArray.length - 1], value);
			return;
		}

		Reflect.setProperty(leArray, variable, value);
	}

	public static function resetTextTag(tag:String):Void
	{
		if (!PlayState.instance.modchartTexts.exists(tag)) {
			return;
		}

		var text:ModchartText = PlayState.instance.modchartTexts.get(tag);
		text.kill();

		if (text.wasAdded) {
			PlayState.instance.remove(text, true);
		}

		text.destroy();

		PlayState.instance.modchartTexts.remove(tag);
	}

	public static function resetSpriteTag(tag:String):Void
	{
		if (!PlayState.instance.modchartSprites.exists(tag)) {
			return;
		}

		var sprite:ModchartSprite = PlayState.instance.modchartSprites.get(tag);
		sprite.kill();

		if (sprite.wasAdded) {
			PlayState.instance.remove(sprite, true);
		}

		sprite.destroy();
		PlayState.instance.modchartSprites.remove(tag);
	}

	public static function cancelTween(tag:String):Void
	{
		if (PlayState.instance.modchartTweens.exists(tag))
		{
			PlayState.instance.modchartTweens.get(tag).cancel();
			PlayState.instance.modchartTweens.get(tag).destroy();
			PlayState.instance.modchartTweens.remove(tag);
		}
	}

	public static function getTween(tag:String, vars:String):Dynamic
	{
		cancelTween(tag);

		var variables:Array<String> = vars.split('.');
		var valueFromField:Dynamic = getObjectDirectly(variables[0]);

		if (variables.length > 1) {
			valueFromField = getVarInArray(getPropertyLoopThingWhatever(variables), variables[variables.length - 1]);
		}

		return valueFromField;
	}

	public static function cancelTimer(tag:String):Void
	{
		if (PlayState.instance.modchartTimers.exists(tag))
		{
			var theTimer:FlxTimer = PlayState.instance.modchartTimers.get(tag);
			theTimer.cancel();
			theTimer.destroy();

			PlayState.instance.modchartTimers.remove(tag);
		}
	}

	public static function getFlxEaseByString(?ease:String = ''):Float->Float // Better optimized than using some getProperty shit or idk
	{
		switch (ease.toLowerCase().trim())
		{
			case 'backin': return FlxEase.backIn;
			case 'backinout': return FlxEase.backInOut;
			case 'backout': return FlxEase.backOut;
			case 'bouncein': return FlxEase.bounceIn;
			case 'bounceinout': return FlxEase.bounceInOut;
			case 'bounceout': return FlxEase.bounceOut;
			case 'circin': return FlxEase.circIn;
			case 'circinout': return FlxEase.circInOut;
			case 'circout': return FlxEase.circOut;
			case 'cubein': return FlxEase.cubeIn;
			case 'cubeinout': return FlxEase.cubeInOut;
			case 'cubeout': return FlxEase.cubeOut;
			case 'elasticin': return FlxEase.elasticIn;
			case 'elasticinout': return FlxEase.elasticInOut;
			case 'elasticout': return FlxEase.elasticOut;
			case 'expoin': return FlxEase.expoIn;
			case 'expoinout': return FlxEase.expoInOut;
			case 'expoout': return FlxEase.expoOut;
			case 'quadin': return FlxEase.quadIn;
			case 'quadinout': return FlxEase.quadInOut;
			case 'quadout': return FlxEase.quadOut;
			case 'quartin': return FlxEase.quartIn;
			case 'quartinout': return FlxEase.quartInOut;
			case 'quartout': return FlxEase.quartOut;
			case 'quintin': return FlxEase.quintIn;
			case 'quintinout': return FlxEase.quintInOut;
			case 'quintout': return FlxEase.quintOut;
			case 'sinein': return FlxEase.sineIn;
			case 'sineinout': return FlxEase.sineInOut;
			case 'sineout': return FlxEase.sineOut;
			case 'smoothstepin': return FlxEase.smoothStepIn;
			case 'smoothstepinout': return FlxEase.smoothStepInOut;
			case 'smoothstepout': return FlxEase.smoothStepInOut;
			case 'smootherstepin': return FlxEase.smootherStepIn;
			case 'smootherstepinout': return FlxEase.smootherStepInOut;
			case 'smootherstepout': return FlxEase.smootherStepOut;
		}

		return FlxEase.linear;
	}

	public static function blendModeFromString(blend:String):BlendMode
	{
		switch (blend.toLowerCase().trim())
		{
			case 'add': return ADD;
			case 'alpha': return ALPHA;
			case 'darken': return DARKEN;
			case 'difference': return DIFFERENCE;
			case 'erase': return ERASE;
			case 'hardlight': return HARDLIGHT;
			case 'invert': return INVERT;
			case 'layer': return LAYER;
			case 'lighten': return LIGHTEN;
			case 'multiply': return MULTIPLY;
			case 'overlay': return OVERLAY;
			case 'screen': return SCREEN;
			case 'subtract': return SUBTRACT;
		}

		return NORMAL;
	}

	public static function cameraFromString(cam:String):FlxCamera
	{
		switch (cam.toLowerCase())
		{
			case 'camhud' | 'hud': return PlayState.instance.camHUD;
			case 'camother' | 'other': return PlayState.instance.camOther;
		}

		return PlayState.instance.camGame;
	}

	public function luaTrace(text:String, ignoreCheck:Bool = false, deprecated:Bool = false, color:FlxColor = FlxColor.WHITE)
	{
		#if LUA_ALLOWED
		if (ignoreCheck || getBool('luaDebugMode'))
		{
			if (deprecated && !getBool('luaDeprecatedWarnings')) {
				return;
			}

			PlayState.instance.addTextToDebug(text, color);
			Debug.logInfo(text);
		}
		#end
	}

	function getErrorMessage(status:Int):String
	{
		#if LUA_ALLOWED
		var v:String = Lua.tostring(lua, -1);
		Lua.pop(lua, 1);

		if (v != null) v = v.trim();

		if (v == null || v == "")
		{
			switch (status)
			{
				case Lua.LUA_ERRRUN: return "Runtime Error";
				case Lua.LUA_ERRMEM: return "Memory Allocation Error";
				case Lua.LUA_ERRERR: return "Critical Error";
			}

			return "Unknown Error";
		}

		return v;
		#else
		return null;
		#end
	}

	var lastCalledFunction:String = '';

	public function call(func:String, args:Array<Dynamic>):Dynamic
	{
		#if LUA_ALLOWED
		if (closed) return Function_Continue;

		lastCalledFunction = func;

		try
		{
			if (lua == null) return Function_Continue;

			Lua.getglobal(lua, func);

			var type:Int = Lua.type(lua, -1);

			if (type != Lua.LUA_TFUNCTION)
			{
				if (type > Lua.LUA_TNIL) {
					luaTrace("ERROR (" + func + "): attempt to call a " + typeToString(type) + " value", false, false, FlxColor.RED);
				}

				Lua.pop(lua, 1);
				return Function_Continue;
			}

			for (arg in args) Convert.toLua(lua, arg);

			var status:Int = Lua.pcall(lua, args.length, 1, 0);

			if (status != Lua.LUA_OK)
			{
				var error:String = getErrorMessage(status);
				luaTrace("ERROR (" + func + "): " + error, false, false, FlxColor.RED);

				return Function_Continue;
			}

			var result:Dynamic = cast Convert.fromLua(lua, -1);
			if (result == null) result = Function_Continue;

			Lua.pop(lua, 1);

			return result;
		}
		catch (e:Dynamic) {
			Debug.logError(e);
		}
		#end

		return Function_Continue;
	}

	public static function addAnimByIndices(obj:String, name:String, prefix:String, indices:String, framerate:Int = 24, loop:Bool = false):Bool
	{
		var strIndices:Array<String> = indices.trim().split(',');
		var die:Array<Int> = [];

		for (i in 0...strIndices.length) {
			die.push(Std.parseInt(strIndices[i]));
		}

		if (PlayState.instance.getLuaObject(obj, false)!=null)
		{
			var pussy:FlxSprite = PlayState.instance.getLuaObject(obj, false);
			pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);

			if (pussy.animation.curAnim == null) {
				pussy.animation.play(name, true);
			}

			return true;
		}

		var pussy:FlxSprite = Reflect.getProperty(getInstance(), obj);

		if (pussy != null)
		{
			pussy.animation.addByIndices(name, prefix, die, '', framerate, loop);

			if (pussy.animation.curAnim == null) {
				pussy.animation.play(name, true);
			}

			return true;
		}

		return false;
	}

	public static function getPropertyLoopThingWhatever(fieldArray:Array<String>, ?checkForTextsToo:Bool = true, ?getProperty:Bool = true):Dynamic
	{
		var fieldFromObject:Dynamic = getObjectDirectly(fieldArray[0], checkForTextsToo);
		var end = fieldArray.length;

		if (getProperty) end = fieldArray.length - 1;

		for (i in 1...end) {
			fieldFromObject = getVarInArray(fieldFromObject, fieldArray[i]);
		}

		return fieldFromObject;
	}

	public static function getObjectDirectly(objectName:String, ?checkForTextsToo:Bool = true):Dynamic
	{
		var fieldFromObject:Dynamic = PlayState.instance.getLuaObject(objectName, checkForTextsToo);

		if (fieldFromObject == null) {
			fieldFromObject = getVarInArray(getInstance(), objectName);
		}

		return fieldFromObject;
	}

	public static function getClassNameByPrefix(prefix:String):String
	{
		var classVar:String = null;

		switch (prefix.trim())
		{
			case 'ClientPrefs': classVar = 'OptionData';
			case 'GameOverSubstate': classVar = 'GameOverSubState';
			case 'InputFormatter': classVar = 'CoolUtil';
			case 'MusicBeatSubstate': classVar = 'MusicBeatSubState';
		}

		if (classVar == null) {
			classVar = prefix.trim();
		}

		return classVar.trim();
	}

	public static function getVariableByPrefix(o:String, prefix:String):String
	{
		var newVar:String = null;

		switch (o.trim())
		{
			case 'PlayState.instance':
			{
				switch (prefix.trim())
				{
					case 'ratingPercent': {
						newVar = 'songAccuracy';
					}
					case 'ratingName': {
						newVar = 'ratingString';
					}
					case 'ratingFC': {
						newVar = 'comboRank';
					}
				}
			}
			case 'OptionData':
			{
				switch (prefix.trim())
				{
					case 'showFPS': {
						newVar = 'fpsCounter';
					}
					case 'fullscreen': {
						newVar = 'fullScreen';
					}
				}
			}
		}

		if (newVar == null) {
			newVar = prefix.trim();
		}

		return newVar;
	}

	public static function getCallerByPrefix(o:String, prefix:String):String
	{
		var newCaller:String = null;

		switch (o.trim())
		{
			case 'PlayState.instance':
			{
				switch (prefix.trim())
				{
					case 'moveCamera': {
						newCaller = 'cameraMovement';
					}
					case 'moveCameraSection': {
						newCaller = 'cameraMovementSection';
					}
					default: {
						newCaller = prefix.trim();
					}
				}
			}
			case 'OptionData':
			{
				switch (prefix.trim())
				{
					case 'saveSettings': {
						newCaller = 'savePrefs';
					}
					default: {
						newCaller = prefix.trim();
					}
				}
			}
		}

		if (newCaller == null) {
			newCaller = prefix.trim();
		}

		return newCaller;
	}

	function typeToString(type:Int):String
	{
		#if LUA_ALLOWED
		switch (type)
		{
			case Lua.LUA_TBOOLEAN: return "boolean";
			case Lua.LUA_TNUMBER: return "number";
			case Lua.LUA_TSTRING: return "string";
			case Lua.LUA_TTABLE: return "table";
			case Lua.LUA_TFUNCTION: return "function";
		}

		if (type <= Lua.LUA_TNIL) return "nil";
		#end

		return "unknown";
	}

	public function set(variable:String, data:Dynamic):Void
	{
		#if LUA_ALLOWED
		if (lua == null) {
			return;
		}

		Convert.toLua(lua, data);
		Lua.setglobal(lua, variable);
		#end
	}

	#if LUA_ALLOWED
	public function getBool(variable:String):Bool
	{
		var result:String = null;

		Lua.getglobal(lua, variable);

		result = Convert.fromLua(lua, -1);
		Lua.pop(lua, 1);

		if (result == null) {
			return false;
		}

		return (result == 'true');
	}
	#end

	public function stop():Void
	{
		#if LUA_ALLOWED
		if (lua == null) {
			return;
		}

		Lua.close(lua);
		lua = null;
		#end
	}

	public static function getInstance():Dynamic
	{
		return PlayState.instance.isDead ? GameOverSubState.instance : PlayState.instance;
	}

	public static function getInstanceName():String
	{
		return PlayState.instance.isDead ? 'GameOverSubState.instance' : 'PlayState.instance';
	}
}

class ModchartSprite extends FlxSprite
{
	public var wasAdded:Bool = false;
	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();

	public function new(?x:Float = 0, ?y:Float = 0):Void
	{
		super(x, y);

		antialiasing = OptionData.globalAntialiasing;
	}
}

class ModchartText extends FlxText
{
	public var wasAdded:Bool = false;

	public function new(x:Float, y:Float, text:String, width:Float):Void
	{
		super(x, y, width, text, 16);

		setFormat(Paths.getFont("vcr.ttf"), 16, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		cameras = [PlayState.instance.camHUD];

		scrollFactor.set();
		borderSize = 2;
	}
}

class DebugLuaText extends FlxText
{
	private var disableTime:Float = 6;

	public var parentGroup:FlxTypedGroup<DebugLuaText>;

	public function new(text:String, parentGroup:FlxTypedGroup<DebugLuaText>, color:FlxColor):Void
	{
		this.parentGroup = parentGroup;

		super(10, 10, 0, text, 16);

		setFormat(Paths.getFont("vcr.ttf"), 20, color, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		scrollFactor.set();
		borderSize = 1;
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		disableTime -= elapsed;

		if (disableTime < 0) disableTime = 0;
		if (disableTime < 1) alpha = disableTime;
	}
}

class CustomSubState extends MusicBeatSubState
{
	public static var instance:CustomSubState = null;
	public static var name:String = 'unnamed';

	override function create():Void
	{
		instance = this;

		PlayState.instance.callOnLuas('onCustomSubstateCreate', [name]);
		super.create();

		PlayState.instance.callOnLuas('onCustomSubstateCreatePost', [name]);
	}

	public function new(name:String):Void
	{
		CustomSubState.name = name;

		super();
	}

	override function update(elapsed:Float):Void
	{
		PlayState.instance.callOnLuas('onCustomSubstateUpdate', [name, elapsed]);

		super.update(elapsed);

		PlayState.instance.callOnLuas('onCustomSubstateUpdatePost', [name, elapsed]);
	}

	override function destroy():Void
	{
		PlayState.instance.callOnLuas('onCustomSubstateDestroy', [name]);

		super.destroy();
	}
}

#if hscript
class HScript
{
	public static var parser:Parser = new Parser();
	public var interp:Interp;

	public var variables(get, never):Map<String, Dynamic>;

	public function get_variables():Map<String, Dynamic>
	{
		return interp.variables;
	}

	public function new():Void
	{
		interp = new Interp();
		interp.variables.set('FlxG', FlxG);
		interp.variables.set('FlxSprite', FlxSprite);
		interp.variables.set('FlxCamera', FlxCamera);
		interp.variables.set('FlxTimer', FlxTimer);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('game', PlayState.instance);
		interp.variables.set('Paths', Paths);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('OptionData', OptionData);
		interp.variables.set('ClientPrefs', OptionData);
		interp.variables.set('Character', Character);
		interp.variables.set('Alphabet', Alphabet);
		interp.variables.set('CustomSubState', CustomSubState);
		#if (!flash && MODS_ALLOWED)
		interp.variables.set('FlxRuntimeShader', FlxRuntimeShader);
		interp.variables.set('ShaderFilter', openfl.filters.ShaderFilter);
		#end
		interp.variables.set('StringTools', StringTools);

		interp.variables.set('setVar', function(name:String, value:Dynamic):Void
		{
			PlayState.instance.variables.set(name, value);
		});

		interp.variables.set('getVar', function(name:String):Dynamic
		{
			var result:Dynamic = PlayState.instance.variables.exists(name) ? PlayState.instance.variables.get(name) : null;
			return result;
		});

		interp.variables.set('removeVar', function(name:String):Bool
		{
			if (PlayState.instance.variables.exists(name))
			{
				PlayState.instance.variables.remove(name);
				return true;
			}

			return false;
		});
	}

	public function execute(codeToRun:String):Dynamic
	{
		@:privateAccess
		HScript.parser.line = 1;
		HScript.parser.allowTypes = true;
		return interp.execute(HScript.parser.parseString(codeToRun));
	}
}
#end