package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

class MenuItem extends FlxSprite
{
	public static var DEFAULT_COLOR:FlxColor = 0xFF33ffff;

	public var targetY:Float = 0;
	public var itemColor:FlxColor = DEFAULT_COLOR;

	public function new(x:Float, y:Float, weekName:String = ''):Void
	{
		super(x, y);

		if (Paths.fileExists('images/storymenu/' + weekName + '.png', IMAGE)) {
			loadGraphic(Paths.getImage('storymenu/' + weekName));
		}
		else if (Paths.fileExists('images/menuitems/' + weekName + '.png', IMAGE)) {
			loadGraphic(Paths.getImage('menuitems/' + weekName));
		}
		else {
			loadGraphic(Paths.getImage('storymenu/menuitems/' + weekName));
		}

		antialiasing = OptionData.globalAntialiasing;
	}

	public var isFlashing:Bool = false;
	private var isColored:Bool = false;

	public function startFlashing(inEditor:Bool = false):Void
	{
		isFlashing = true;

		new FlxTimer().start(0.06, (tmr:FlxTimer) ->
		{
			isColored = !isColored;

			if (tmr.loops > 0 && tmr.loopsLeft == 0 && inEditor)
			{
				isFlashing = false;
				color = FlxColor.WHITE;
			}
		}, Std.int((inEditor ? 1 : 2) / 0.06));
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		y = FlxMath.lerp(y, (targetY * 120) + 465, CoolUtil.boundTo(elapsed * 10.2, 0, 1));

		if (isColored) {
			color = itemColor;
		}
		else if (OptionData.flashingLights) {
			color = FlxColor.WHITE;
		}
	}
}