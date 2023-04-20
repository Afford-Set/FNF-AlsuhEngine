package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;

using StringTools;

class RatingSprite extends FlxSprite
{
	public var rating:String = 'sick';

	public function new(rating:String, suffix:String = null):Void
	{
		super();

		this.rating = rating;

		if (suffix == null && PlayState.isPixelStage) suffix = '-pixel';

		var ourPath:String = 'ratings/' + rating;

		if (suffix != null && suffix.length > 0)
		{
			ourPath += suffix;
			var pathShit:String = rating + suffix;

			if (Paths.fileExists('images/pixelUI/' + pathShit + '.png', IMAGE) && PlayState.isPixelStage) {
				ourPath = 'pixelUI/' + pathShit;
			}
			else if (Paths.fileExists('images/' + pathShit + '.png', IMAGE)) {
				ourPath = pathShit;
			}
		}
		else
		{
			if (Paths.fileExists('images/pixelUI/' + rating + '.png', IMAGE) && PlayState.isPixelStage) {
				ourPath = 'pixelUI/' + rating;
			}
			else if (Paths.fileExists('images/' + rating + '.png', IMAGE)) {
				ourPath = rating;
			}
		}

		loadGraphic(Paths.getImage(ourPath));
		setPosition(580, ((FlxG.height - height) / 2) - 60);

		antialiasing = OptionData.globalAntialiasing && !PlayState.isPixelStage;

		setGraphicSize(Std.int(width * (PlayState.isPixelStage ? PlayState.daPixelZoom * 0.85 : 0.7)));
		updateHitbox();

		var playbackRate:Float = 1;

		if (PlayState.instance != null) {
			playbackRate = PlayState.instance.playbackRate;
		}

		acceleration.y = 550 * playbackRate * playbackRate;
		velocity.set(velocity.x - (FlxG.random.int(0, 10) * playbackRate), velocity.y - (FlxG.random.int(140, 175) * playbackRate));

		var offset:Array<Int> = OptionData.comboOffset.copy();
		setPosition(x + offset[0], y - offset[1]);

		goToVisible();
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