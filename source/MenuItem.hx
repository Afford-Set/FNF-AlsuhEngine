package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

using StringTools;

class MenuItem extends FlxSprite
{
	public var targetY:Float = 0;
	public var flashingInt:Int = 0;

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

	/**
	 * if it runs at 60fps, fake framerate will be 6
	 * if it runs at 144 fps, fake framerate will be like 14, and will update the graphic every 0.016666 * 3 seconds still???
	 * so it runs basically every so many seconds, not dependant on framerate??
	 * I'm still learning how math works thanks whoever is reading this lol
	 */
	var fakeFramerate:Int = Math.round((1 / FlxG.elapsed) / 10);

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		y = CoolUtil.coolLerp(y, (targetY * 120) + 465, 0.17);

		if (isFlashing) {
			flashingInt++;
		}

		if (flashingInt % fakeFramerate >= Math.floor(fakeFramerate / 2)) {
			color = 0xFF33FFFF;
		}
		else if (OptionData.flashingLights) {
			color = FlxColor.WHITE;
		}
	}
}