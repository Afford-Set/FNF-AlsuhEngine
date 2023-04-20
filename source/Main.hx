package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

#if desktop
import lime.app.Application;
#end

import haxe.EnumFlags;
import haxe.Exception;

#if CRASH_HANDLER
import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
import haxe.CallStack;
import openfl.events.UncaughtErrorEvent;
#end

#if !mobile
import openfl.display.FPS;
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
	public static var fpsCounter:FPS;
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
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		if (gamePropeties.zoom == -1.0)
		{
			var ratioX:Float = stageWidth / gamePropeties.width;
			var ratioY:Float = stageHeight / gamePropeties.height;
			gamePropeties.zoom = Math.min(ratioX, ratioY);
			gamePropeties.width = Math.ceil(stageWidth / gamePropeties.zoom);
			gamePropeties.height = Math.ceil(stageHeight / gamePropeties.zoom);
		}

		Debug.onInitProgram();

		game = new FlxGame(gamePropeties.width,
			gamePropeties.height,
			gamePropeties.initialState,
			#if (flixel < "5.0.0") gamePropeties.zoom, #end
			gamePropeties.framerate,
			gamePropeties.framerate,
			gamePropeties.skipSplash,
		gamePropeties.startFullscreen);
		addChild(game);

		#if !mobile
		fpsCounter = new FPS(10, 3, 0xFFFFFF);
		addChild(fpsCounter);

		Lib.current.stage.align = "tl";
		Lib.current.stage.scaleMode = StageScaleMode.NO_SCALE;

		if (fpsCounter != null) {
			fpsCounter.visible = OptionData.fpsCounter;
		}
		#end

		Debug.onGameStart();

		#if DISCORD_ALLOWED
		if (!DiscordClient.isInitialized) {
			DiscordClient.initialize();
		}
		#end

		#if (CRASH_HANDLER && !hl)
		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onCrash);
		#end
		
		#if (CRASH_HANDLER && hl)
		hl.Api.setErrorHandler(onCrash);
		#end
	}

	#if CRASH_HANDLER
	function onCrash(e:UncaughtErrorEvent):Void
	{
		var errMsg:String = '';
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

		#if hl
		var flags:EnumFlags<hl.UI.DialogFlags> = new EnumFlags<hl.UI.DialogFlags>();
		flags.set(IsError);
		hl.UI.dialog("Error!", errMsg, flags);
		#else
		Application.current.window.alert(errMsg, "Error!");
		#end

		#if DISCORD_ALLOWED
		DiscordClient.shutdown();
		#end

		Sys.exit(1);
	}
	#end
}