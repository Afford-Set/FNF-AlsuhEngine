package;

#if LUA_ALLOWED
import llua.Lua;
import llua.State;
#end

#if DISCORD_ALLOWED
import Sys.sleep;
import sys.thread.Thread;
import discord_rpc.DiscordRpc;
#end

using StringTools;

class DiscordClient
{
	public static var isInitialized:Bool = false;

	public function new():Void
	{
		Debug.logInfo("Discord Client starting...");

		#if DISCORD_ALLOWED
		DiscordRpc.start({
			clientID: "990565623425814568",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		#end

		Debug.logInfo("Discord Client started.");

		#if DISCORD_ALLOWED
		while (true)
		{
			DiscordRpc.process();
			sleep(2);
		}

		DiscordRpc.shutdown();
		#end
	}

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
			largeImageText: "Friday Night Funkin' Alsuh Engine"
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
		Thread.create(function():Void {
			new DiscordClient();
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

	#if (DISCORD_ALLOWED && LUA_ALLOWED)
	public static function addLuaCallbacks(lua:State):Void
	{
		Lua_helper.add_callback(lua, "changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float):Void {
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});
	}
	#end
}
