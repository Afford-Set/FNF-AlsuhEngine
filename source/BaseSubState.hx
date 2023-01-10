package;

import flixel.FlxSubState;

using StringTools;

class BaseSubState extends FlxSubState
{
	private var controls(get, never):Controls;

	inline function get_controls():Controls {
		return PlayerSettings.player1.controls;
	}

	public function new():Void
	{
		super();
	}

	public override function create():Void
	{
		super.create();
	}

	#if !mobile
	var skippedFrames:Int = 0;
	var skippedFrames2:Int = 0;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		#if !mobile
		CoolUtil.recolorCounters(skippedFrames, skippedFrames2);
		#end
	}
	#end
}