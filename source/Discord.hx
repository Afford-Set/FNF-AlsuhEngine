package;

#if LUA_ALLOWED
import llua.Lua;
import llua.State;
#end

import lime.app.Application;

#if DISCORD_ALLOWED
import Sys.sleep;
import sys.thread.Thread;
import discord_rpc.DiscordRpc;
#end

using StringTools;

class DiscordClient
{
	public static var clientID:String = '990565623425814568';
	public static var isInitialized:Bool = false;

	public static function shutdown():Void
	{
		#if DISCORD_ALLOWED
		DiscordRpc.shutdown();
		#end
	}

	static function onReady():Void
	{
		#if DISCORD_ALLOWED
		DiscordRpc.presence({
			details: "In the Menus",
			state: null,
			largeImageKey: 'icon',
			largeImageText: "Friday Night Funkin' - Alsuh Engine"
		});
		#end
	}

	static function onError(_code:Int, _message:String):Void
	{
		Debug.logError('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String):Void
	{
		Debug.logWarn('Disconnected! $_code : $_message');
	}

	public static function initialize():Void
	{
		#if DISCORD_ALLOWED
		Debug.logInfo('Discord Client starting...');

		var id:String = null;
		var path:String = 'data/discordClientID.txt';

		if (Paths.fileExists(path, TEXT)) {
			id = Paths.getTextFromFile(path);
		}

		if (id != null && id.length > 0) {
			clientID = id;
		}

		Thread.create(() ->
		{
			DiscordRpc.start({
				clientID: clientID,
				onReady: onReady,
				onError: onError,
				onDisconnected: onDisconnected
			});

			while (true) // using a FlxG.stage.addEventListener is too much fuss!
			{
				DiscordRpc.process();
				sleep(2);
			}

			Debug.logInfo('Discord Client started.');
			DiscordRpc.shutdown();

			Application.current.window.onClose.add(function():Void {
				DiscordClient.shutdown();
			});
		});
		#end

		isInitialized = true;
		Debug.logInfo("Discord Client initialized");
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float):Void
	{
		var startTimestamp:Float = hasStartTimestamp ? Date.now().getTime() : 0;

		if (endTimestamp > 0) {
			endTimestamp = startTimestamp + endTimestamp;
		}

		#if DISCORD_ALLOWED
		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: 'icon',
			largeImageText: "Engine Version: " + MainMenuState.engineVersion,
			smallImageKey : smallImageKey,

			startTimestamp : Std.int(startTimestamp / 1000),
			endTimestamp : Std.int(endTimestamp / 1000)
		});
		#end
	}

	#if LUA_ALLOWED
	public static function addLuaCallbacks(lua:State):Void
	{
		Lua_helper.add_callback(lua, "changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float):Void {
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});
	}
	#end
}