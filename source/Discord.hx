package;

#if LUA_ALLOWED
import llua.Lua;
import llua.State;
#end

#if desktop
import Sys.sleep;
import discord_rpc.DiscordRpc;
#end

using StringTools;

class DiscordClient
{
	public function new():Void
	{
		Debug.logInfo("Discord Client starting...");

		#if desktop
		DiscordRpc.start({
			clientID: "990565623425814568",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		#end

		Debug.logInfo("Discord Client started.");

		#if desktop
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
		#if desktop
		DiscordRpc.shutdown();
		#end
	}
	
	static function onReady():Void
	{
		#if desktop
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
		Debug.logInfo('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String):Void
	{
		Debug.logInfo('Disconnected! $_code : $_message');
	}

	public static function initialize():Void
	{
		#if desktop
		var DiscordDaemon = sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});
		#end

		Debug.logInfo("Discord Client initialized");
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float):Void
	{
		var startTimestamp:Float = hasStartTimestamp ? Date.now().getTime() : 0;

		if (endTimestamp > 0) {
			endTimestamp = startTimestamp + endTimestamp;
		}

		#if desktop
		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: 'icon',
			largeImageText: "Friday Night Funkin'",
			smallImageKey : smallImageKey,

			startTimestamp : Std.int(startTimestamp / 1000),
			endTimestamp : Std.int(endTimestamp / 1000)
		});
		#end
	}

	#if (desktop && LUA_ALLOWED)
	public static function addLuaCallbacks(lua:State):Void
	{
		Lua_helper.add_callback(lua, "changePresence", function(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float):Void {
			changePresence(details, state, smallImageKey, hasStartTimestamp, endTimestamp);
		});
	}
	#end
}
