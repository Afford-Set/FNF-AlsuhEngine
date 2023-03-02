package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;

using StringTools;

class Number extends FlxSprite
{
	public var number:Int = 0;

	public function new(number:Int, suffix:String, coolText:FlxText, daLoop:Int):Void
	{
		super();

		this.number = number;

		var ourPath:String = 'num' + number;

		if (Paths.fileExists('images/' + ourPath + '.png', IMAGE)) {
			loadGraphic(Paths.getImage(ourPath));
		}
		else if (Paths.fileExists('images/pixelUI/' + ourPath + '.png', IMAGE)) {
			loadGraphic(Paths.getImage('pixelUI/' + ourPath));
		}
		else if (Paths.fileExists('images/numbers/' + ourPath + '.png', IMAGE)) {
			loadGraphic(Paths.getImage('numbers/' + ourPath));
		}

		if (suffix != null && suffix.length > 0)
		{
			var ourPath:String = 'num' + number + suffix;

			if (Paths.fileExists('images/' + ourPath + '.png', IMAGE)) {
				loadGraphic(Paths.getImage(ourPath));
			}
			else if (Paths.fileExists('images/pixelUI/' + ourPath + '.png', IMAGE)) {
				loadGraphic(Paths.getImage('pixelUI/' + ourPath));
			}
			else if (Paths.fileExists('images/numbers/' + ourPath + '.png', IMAGE)) {
				loadGraphic(Paths.getImage('numbers/' + ourPath));
			}
		}

		screenCenter();

		x = coolText.x + (43 * daLoop) - 175;
		y += 80;

		antialiasing = suffix.contains('pixel') ? false : OptionData.globalAntialiasing;

		setGraphicSize(Std.int(width * (suffix.contains('pixel') ? PlayState.daPixelZoom : 0.5)));
		updateHitbox();

		acceleration.y = FlxG.random.int(200, 300) * PlayStateChangeables.playbackRate * PlayStateChangeables.playbackRate;

		velocity.y -= FlxG.random.int(140, 160) * PlayStateChangeables.playbackRate;
		velocity.x = FlxG.random.float(-5, 5) * PlayStateChangeables.playbackRate;

		goToVisible();

		x += OptionData.comboOffset[2];
		y -= OptionData.comboOffset[3];
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		goToVisible();
	}

	public function goToVisible():Void
	{
		visible = OptionData.showNumbers;
	}
}