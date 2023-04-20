package;

import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class ComboSprite extends FlxSprite
{
	public function new(suffix:String = null):Void
	{
		super();

		var ourPath:String = 'ratings/combo';

		if (suffix != null && suffix.length > 0)
		{
			ourPath += suffix;
			var pathShit:String = 'combo' + suffix;

			if (Paths.fileExists('images/pixelUI/' + pathShit + '.png', IMAGE) && PlayState.isPixelStage) {
				ourPath = 'pixelUI/' + pathShit;
			}
			else if (Paths.fileExists('images/' + pathShit + '.png', IMAGE)) {
				ourPath = pathShit;
			}
		}
		else
		{
			if (Paths.fileExists('images/pixelUI/combo.png', IMAGE) && PlayState.isPixelStage) {
				ourPath = 'pixelUI/combo';
			}
			else if (Paths.fileExists('images/combo.png', IMAGE)) {
				ourPath = 'combo';
			}
		}

		loadGraphic(Paths.getImage(ourPath));
		setPosition(705, (FlxG.height - height) / 2);

		antialiasing = OptionData.globalAntialiasing && !PlayState.isPixelStage;

		setGraphicSize(Std.int(width * (PlayState.isPixelStage ? PlayState.daPixelZoom * 0.85 : 0.7)));
		updateHitbox();

		var playbackRate:Float = 1;

		if (PlayState.instance != null) {
			playbackRate = PlayState.instance.playbackRate;
		}

		acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		velocity.set(velocity.x + (FlxG.random.int(1, 10) * playbackRate), velocity.y - (FlxG.random.int(140, 160) * playbackRate));

		var offset:Array<Int> = OptionData.comboOffset.copy();
		setPosition(x + offset[4], y - offset[5] + 60);
	}
}