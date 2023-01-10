package transition;

import flixel.FlxG;
import flixel.FlxState;

using StringTools;

class TransitionableState extends FlxState
{
	private var controls(get, never):Controls;

	inline function get_controls():Controls {
		return PlayerSettings.player1.controls;
	}

	public override function create():Void
	{
		super.create();

		if (!Transition.skipNextTransOut)
		{
			onTransOut();

			var trans:Transition = new Transition(0.7, true);
			openSubState(trans);
		}

		Transition.skipNextTransOut = false;
	}

	#if !mobile
	var skippedFrames:Int = 0;
	var skippedFrames2:Int = 0;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		CoolUtil.recolorCounters(skippedFrames, skippedFrames2);
	}
	#end

	public function onTransIn():Void
	{
		// override per subclass
	}

	public function onTransInFinished():Void
	{
		// override per subclass
	}

	public function onTransOut():Void
	{
		// override per subclass
	}

	public function onTransOutFinished():Void
	{
		// override per subclass
	}

	var exiting:Bool = false;

	public override function switchTo(nextState:FlxState):Bool
	{
		if (!Transition.skipNextTransIn)
		{
			onTransIn();

			if (!exiting)
			{
				var trans:Transition = new Transition(0.6, false);
				trans.finishCallback = function():Void
				{
					onTransInFinished();

					exiting = true;
					FlxG.switchState(nextState);
				};
				openSubState(trans);
			}

			return exiting;
		}

		Transition.skipNextTransIn = false;
		return true;
	}
}