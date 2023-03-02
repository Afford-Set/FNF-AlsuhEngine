package openfl.display;

import haxe.Timer;
import openfl.display.FPS;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

class Memory extends TextField
{
	private var times:Array<Float>;
	private var memPeak:Float = 0;

	public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000):Void
	{
		super();

		x = inX;
		y = inY;

		selectable = false;
		defaultTextFormat = new TextFormat("_sans", 14, inCol);

		addEventListener(Event.ENTER_FRAME, onEnter);

		width = 150;
		height = 70;
	}

	private function onEnter(_):Void
	{
		var mem:Float = Math.round(System.totalMemory / 1024 / 1024 * 100) / 100;

		if (mem > memPeak) {
			memPeak = mem;
		}

		if (visible)
		{
			text = "\nMEM: " + mem + " MB\nMEM peak: " + memPeak + " MB";

			if (mem > 3000) {
				textColor = 0xFFFF0000;
			}
		}
	}
}