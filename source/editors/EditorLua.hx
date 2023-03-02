package editors;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import Controls;
import Type.ValueType;
import DialogueBoxPsych;

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

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;

using StringTools;

class EditorLua
{
	public static var Function_Stop:Dynamic = 1;
	public static var Function_Continue:Dynamic = 0;

	#if LUA_ALLOWED
	public var lua:State = null;
	#end

	public function new(script:String):Void
	{
		#if LUA_ALLOWED
		lua = LuaL.newstate();
		LuaL.openlibs(lua);
		Lua.init_callbacks(lua);

		var result:Dynamic = LuaL.dofile(lua, script);
		var resultStr:String = Lua.tostring(lua, result);

		if (resultStr != null && result != 0)
		{
			lime.app.Application.current.window.alert(resultStr, 'Error on .LUA script!');
			Debug.logError('Error on .LUA script! ' + resultStr);
			lua = null;

			return;
		}

		Debug.logInfo('Lua file loaded succesfully:' + script);

		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);
		set('inChartEditor', true);

		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songID', PlayState.SONG.songID);
		set('songName', PlayState.SONG.songName);

		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		for (i in 0...4)
		{
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		set('downscroll', OptionData.downScroll);
		set('middlescroll', OptionData.middleScroll);

		Lua_helper.add_callback(lua, "getProperty", function(variable:String):Dynamic
		{
			var fieldArray:Array<String> = variable.split('.');

			if (fieldArray.length > 1)
			{
				var fieldArrayFromInstance:Dynamic = Reflect.getProperty(EditorPlayState.instance, fieldArray[0]);

				for (i in 1...fieldArray.length - 1) {
					fieldArrayFromInstance = Reflect.getProperty(fieldArrayFromInstance, fieldArray[i]);
				}

				return Reflect.getProperty(fieldArrayFromInstance, fieldArray[fieldArray.length - 1]);
			}

			return Reflect.getProperty(EditorPlayState.instance, variable);
		});

		Lua_helper.add_callback(lua, "setProperty", function(variable:String, value:Dynamic):Void
		{
			var fieldArray:Array<String> = variable.split('.');

			if (fieldArray.length > 1)
			{
				var fieldArrayFromInstance:Dynamic = Reflect.getProperty(EditorPlayState.instance, fieldArray[0]);

				for (i in 1...fieldArray.length - 1) {
					fieldArrayFromInstance = Reflect.getProperty(fieldArrayFromInstance, fieldArray[i]);
				}

				return Reflect.setProperty(fieldArrayFromInstance, fieldArray[fieldArray.length - 1], value);
			}

			return Reflect.setProperty(EditorPlayState.instance, variable, value);
		});

		Lua_helper.add_callback(lua, "callFromObject", function(variable:String, ?arguments:Array<Dynamic>):Dynamic
		{
			var fieldArray:Array<String> = variable.split('.');

			if (fieldArray.length > 1)
			{
				var fieldArrayFromInstance:Dynamic = Reflect.getProperty(EditorPlayState.instance, fieldArray[0]);

				for (i in 1...fieldArray.length - 1) {
					fieldArrayFromInstance = Reflect.getProperty(fieldArrayFromInstance, fieldArray[i]);
				}

				return Reflect.callMethod(null, Reflect.getProperty(fieldArrayFromInstance, fieldArray[fieldArray.length - 1]), arguments);
			}

			return Reflect.callMethod(null, Reflect.getProperty(EditorPlayState.instance, variable), arguments);
		});

		Lua_helper.add_callback(lua, "getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic):Dynamic
		{
			if (Std.isOfType(Reflect.getProperty(EditorPlayState.instance, obj), FlxTypedGroup)) {
				return Reflect.getProperty(Reflect.getProperty(EditorPlayState.instance, obj).members[index], variable);
			}

			var leArray:Dynamic = Reflect.getProperty(EditorPlayState.instance, obj)[index];

			if (leArray != null)
			{
				if (Type.typeof(variable) == ValueType.TInt) {
					return leArray[variable];
				}

				return Reflect.getProperty(leArray, variable);
			}

			return null;
		});

		Lua_helper.add_callback(lua, "setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic):Void
		{
			if (Std.isOfType(Reflect.getProperty(EditorPlayState.instance, obj), FlxTypedGroup)) {
				return Reflect.setProperty(Reflect.getProperty(EditorPlayState.instance, obj).members[index], variable, value);
			}

			var leArray:Dynamic = Reflect.getProperty(EditorPlayState.instance, obj)[index];

			if (leArray != null)
			{
				if (Type.typeof(variable) == ValueType.TInt) {
					return leArray[variable] = value;
				}

				return Reflect.setProperty(leArray, variable, value);
			}
		});

		Lua_helper.add_callback(lua, "removeFromGroup", function(obj:String, index:Int, dontDestroy:Bool = false):Void
		{
			if (Std.isOfType(Reflect.getProperty(EditorPlayState.instance, obj), FlxTypedGroup))
			{
				var sex:FlxBasic = Reflect.getProperty(EditorPlayState.instance, obj).members[index];

				if (!dontDestroy) {
					sex.kill();
				}

				Reflect.getProperty(EditorPlayState.instance, obj).remove(sex, true);

				if (!dontDestroy) {
					sex.destroy();
				}

				return;
			}

			Reflect.getProperty(EditorPlayState.instance, obj).remove(Reflect.getProperty(EditorPlayState.instance, obj)[index]);
		});

		Lua_helper.add_callback(lua, "callFromGroup", function(obj:String, index:Int, variable:Dynamic, ?arguments:Array<Dynamic>):Dynamic
		{
			var group:Dynamic = Reflect.getProperty(EditorPlayState.instance, obj);

			if (Std.isOfType(group, FlxTypedGroup))
			{
				var result:Dynamic = Reflect.getProperty(group.members[index], variable);
				return Reflect.callMethod(null, result, arguments);
			}

			var leArray:Dynamic = group[index];

			if (leArray != null)
			{
				var result:Dynamic = null;

				if (Type.typeof(variable) == ValueType.TInt) {
					result = leArray[variable];
				}
				else {
					result = Reflect.getProperty(leArray, variable);
				}

				return Reflect.callMethod(null, result, arguments);
			}

			return null;
		});

		Lua_helper.add_callback(lua, "getColorFromHex", function(color:String):Int
		{
			if (!color.startsWith('0x')) color = '0xff' + color;
			return Std.parseInt(color);
		});

		Lua_helper.add_callback(lua, "setGraphicSize", function(obj:String, x:Int, y:Int = 0):Void
		{
			var sprite:FlxSprite = Reflect.getProperty(EditorPlayState.instance, obj);

			if (sprite != null)
			{
				sprite.setGraphicSize(x, y);
				sprite.updateHitbox();
				return;
			}
		});

		Lua_helper.add_callback(lua, "scaleObject", function(obj:String, x:Float, y:Float):Void
		{
			var sprite:FlxSprite = Reflect.getProperty(EditorPlayState.instance, obj);

			if (sprite != null)
			{
				sprite.scale.set(x, y);
				sprite.updateHitbox();
				return;
			}
		});

		Lua_helper.add_callback(lua, "updateHitbox", function(obj:String):Void
		{
			var sprite:FlxSprite = Reflect.getProperty(EditorPlayState.instance, obj);

			if (sprite != null)
			{
				sprite.updateHitbox();
				return;
			}
		});

		#if DISCORD_ALLOWED
		DiscordClient.addLuaCallbacks(lua);
		#end

		call('onCreate', []);
		#end
	}
	
	public function call(event:String, args:Array<Dynamic>):Dynamic
	{
		#if LUA_ALLOWED
		if (lua == null) {
			return Function_Continue;
		}

		Lua.getglobal(lua, event);

		for (arg in args) {
			Convert.toLua(lua, arg);
		}

		var result:Null<Int> = Lua.pcall(lua, args.length, 1, 0);

		if (result != null && resultIsAllowed(lua, result))
		{
			if (Lua.type(lua, -1) == Lua.LUA_TSTRING)
			{
				var error:String = Lua.tostring(lua, -1);
				Lua.pop(lua, 1);
	
				if (error == 'attempt to call a nil value') { //Makes it ignore warnings and not break stuff if you didn't put the functions on your lua file
					return Function_Continue;
				}
			}

			var conv:Dynamic = Convert.fromLua(lua, result);

			return conv;
		}
		#end

		return Function_Continue;
	}

	#if LUA_ALLOWED
	function resultIsAllowed(leLua:State, leResult:Null<Int>):Bool // Makes it ignore warnings
	{
		switch (Lua.type(leLua, leResult))
		{
			case Lua.LUA_TNIL | Lua.LUA_TBOOLEAN | Lua.LUA_TNUMBER | Lua.LUA_TSTRING | Lua.LUA_TTABLE:
				return true;
		}

		return false;
	}
	#end

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
}