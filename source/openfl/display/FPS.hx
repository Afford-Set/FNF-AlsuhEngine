package openfl.display;

import haxe.Timer;
#if flash
import openfl.Lib;
#end
#if (openfl && !hl)
import openfl.system.System;
#end
import openfl.events.Event;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.text.TextField;
import openfl.text.TextFormat;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class FPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;
	#if (openfl && !hl)
	private var memoryMegas:Float = 0;
	private var memoryTotal:Float = 0;
	#end

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000):Void
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;

		selectable = false;
		mouseEnabled = false;

		defaultTextFormat = new TextFormat("_sans", 14, color);

		autoSize = LEFT;
		multiline = true;

		cacheCount = 0;
		currentTime = 0;
		times = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e):Void
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end
	}

	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void // Event Handlers
	{
		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000) {
			times.shift();
		}

		var currentCount:Int = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);
		if (currentFPS > OptionData.framerate) currentFPS = OptionData.framerate;

		if (currentCount != cacheCount)
		{
			text = '';
			if (OptionData.fpsCounter) text += "FPS: " + currentFPS + "\n";

			#if (openfl && !hl)
			memoryMegas = Math.abs(CoolUtil.roundDecimal(System.totalMemory / 1000000, 1));
			if (memoryMegas > memoryTotal) memoryTotal = memoryMegas;

			if (OptionData.memoryCounter) text += "Memory: " + memoryMegas + " MB / " + memoryTotal + " MB";
			#end

			if (Main.fpsCounter != null) {
				Main.fpsCounter.visible = text != null || text != '';
			}

			textColor = FlxColor.WHITE;

			if (#if !hl memoryMegas > 3000 || #end currentFPS <= OptionData.framerate / 2) {
				textColor = FlxColor.RED;
			}

			#if (gl_stats && !disable_cffi && (!html5 || !canvas))
			text += "\ntotalDC: " + Context3DStats.totalDrawCalls();
			text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
			text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
			#end

			text += "\n";
		}

		cacheCount = currentCount;
	}
}