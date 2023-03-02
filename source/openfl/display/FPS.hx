package openfl.display;

import haxe.Timer;
#if flash
import openfl.Lib;
#end
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;

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
		text = "FPS: ";

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

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);

		var framerateOption:Int = #if html5 60 #else OptionData.framerate #end;
		if (currentFPS > framerateOption) currentFPS = framerateOption;

		if (currentCount != cacheCount)
		{
			text = "FPS: " + currentFPS;
			textColor = 0xFFFFFFFF;

			if (currentFPS < framerateOption / 2) {
				textColor = 0xFFFF0000;
			}
		}

		cacheCount = currentCount;
	}
}