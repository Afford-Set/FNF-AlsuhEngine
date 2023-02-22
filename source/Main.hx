package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

#if desktop
import lime.app.Application;
#end

#if CRASH_HANDLER
import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
import haxe.CallStack;
import openfl.events.UncaughtErrorEvent;
#end

#if WEBM_ALLOWED
import webmlmfao.*;
#end

#if !mobile
import counters.FPSCounter;
import counters.MemoryCounter;
#end

import openfl.Lib;
import flixel.FlxGame;
import openfl.events.Event;
import openfl.display.Sprite;
import openfl.display.StageScaleMode;

using StringTools;

class Main extends Sprite
{
	var gamePropeties:Dynamic = {
		width: 1280, // WINDOW width
		height: 720, // WINDOW height
		initialState: TitleState, // initial game state
		zoom: 1, // game state bounds
		framerate: 60, // default framerate
		skipSplash: true, // if the default flixel splash screen should be skipped
		startFullscreen: false // if the game should start at fullscreen mode
	};

	public var game:FlxGame;

	#if !mobile
	public static var fpsCounter:FPSCounter;
	public static var memoryCounter:MemoryCounter;
	#end

	// You can pretty much ignore everything from here on - your code should go in your states.

	public static function main():Void
	{
		Lib.current.addChild(new Main());
	}

	public function new():Void
	{
		super();

		if (stage != null) {
			init();
		}
		else {
			addEventListener(Event.ADDED_TO_STAGE, init);
		}
	}

	private function init(?E:Event):Void
	{
		if (hasEventListener(Event.ADDED_TO_STAGE)) {
			removeEventListener(Event.ADDED_TO_STAGE, init);
		}

		setupGame();
	}

	private function setupGame():Void
	{
		Debug.onInitProgram();
		OptionData.loadDefaultKeys();

		game = new FlxGame(gamePropeties.width,
			gamePropeties.height,
			gamePropeties.initialState,
			#if (flixel < "5.0.0") gamePropeties.zoom, #end
			gamePropeties.framerate,
			gamePropeties.framerate,
			gamePropeties.skipSplash,
		gamePropeties.startFullscreen);
		addChild(game);

		#if WEBM_ALLOWED
		var str1:String = "WEBM SHIT";
		var webmHandle = new WebmHandler();
		webmHandle.source(Paths.getWebm("DO NOT DELETE OR GAME WILL CRASH/dontDelete"));
		webmHandle.makePlayer();
		webmHandle.webm.name = str1;
		addChild(webmHandle.webm);
		GlobalVideo.setWebm(webmHandle);
		#end

		#if !mobile
		fpsCounter = new FPSCounter(10, 3, 0xFFFFFF);
		addChild(fpsCounter);

		if (fpsCounter != null) {
			fpsCounter.visible = OptionData.fpsCounter;
		}

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		memoryCounter = new MemoryCounter(10, 3, 0xFFFFFF);
		addChild(memoryCounter);

		if (memoryCounter != null) {
			memoryCounter.visible = OptionData.memoryCounter;
		}
		#end

		Debug.onGameStart();

		#if DISCORD_ALLOWED
		if (!DiscordClient.isInitialized)
		{
			DiscordClient.initialize();

			Application.current.window.onClose.add(function():Void {
				DiscordClient.shutdown();
			});
		}
		#end
		
		#if CRASH_HANDLER
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end
	}

	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = "";
		var path:String;

		var callStack:Array<StackItem> = CallStack.exceptionStack(true);
		var dateNow:String = Date.now().toString();

		dateNow = dateNow.replace(" ", "_");
		dateNow = dateNow.replace(":", "'");

		path = "./crash/" + "AlsuhEngine" + dateNow + ".txt";

		for (stackItem in callStack)
		{
			switch (stackItem)
			{
				case FilePos(s, file, line, column):
					errMsg += file + " (line " + line + ")\n";
				default:
					Sys.println(stackItem);
			}
		}

		errMsg += "\nUncaught Error: " + e.error + "\nPlease report this error to the GitHub page: https://github.com/Afford-Set/FNF-AlsuhEngine\n\n> Crash Handler written by: sqirra-rng";

		if (!FileSystem.exists("./crash/")) {
			FileSystem.createDirectory("./crash/");
		}

		File.saveContent(path, errMsg + "\n");

		Sys.println(errMsg);
		Sys.println("Crash dump saved in " + Path.normalize(path));

		Application.current.window.alert(errMsg, "Error!");
		DiscordClient.shutdown();

		Sys.exit(1);
	}
	#end
}