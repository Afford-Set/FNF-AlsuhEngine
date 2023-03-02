package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;

using StringTools;

class Rating extends FlxSprite
{
	public var rating:String = 'sick';

	public function new(rating:String, suffix:String, coolText:FlxText):Void
	{
		super();

		this.rating = rating;

		if (Paths.fileExists('images/' + rating + suffix + '.png', IMAGE)) {
			loadGraphic(Paths.getImage(rating + suffix));
		}
		else if (Paths.fileExists('images/pixelUI/' + rating + suffix + '.png', IMAGE)) {
			loadGraphic(Paths.getImage('pixelUI/' + rating + suffix));
		}
		else if (Paths.fileExists('images/ratings/' + rating + suffix + '.png', IMAGE)) {
			loadGraphic(Paths.getImage('ratings/' + rating + suffix));
		}

		if (suffix != null && suffix.length > 0)
		{
			var ourPath:String = rating + suffix;

			if (Paths.fileExists('images/' + ourPath + '.png', IMAGE)) {
				loadGraphic(Paths.getImage(ourPath));
			}
			else if (Paths.fileExists('images/pixelUI/' + ourPath + '.png', IMAGE)) {
				loadGraphic(Paths.getImage('pixelUI/' + ourPath));
			}
			else if (Paths.fileExists('images/ratings/' + ourPath + '.png', IMAGE)) {
				loadGraphic(Paths.getImage('ratings/' + ourPath));
			}
		}

		screenCenter();

		x = coolText.x - 125;
		y -= 60;

		acceleration.y = 550 * PlayStateChangeables.playbackRate * PlayStateChangeables.playbackRate;

		velocity.x -= FlxG.random.int(0, 10) * PlayStateChangeables.playbackRate;
		velocity.y -= FlxG.random.int(140, 175) * PlayStateChangeables.playbackRate;

		setGraphicSize(Std.int(width * (suffix.contains('pixel') ? PlayState.daPixelZoom * 0.7 : 0.7)));

		antialiasing = suffix.contains('pixel') ? false : OptionData.globalAntialiasing;

		goToVisible();

		x += OptionData.comboOffset[0];
		y -= OptionData.comboOffset[1];

		updateHitbox();
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		goToVisible();
	}

	public function goToVisible():Void
	{
		var iCanSayShit:Bool = (rating == 'shit' && !OptionData.naughtyness);
		visible = iCanSayShit ? false : OptionData.showRatings;
	}
}