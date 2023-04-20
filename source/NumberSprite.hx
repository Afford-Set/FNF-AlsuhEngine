package;

import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class NumberSprite extends FlxSprite
{
	public var number:Int = 0;

	public function new(number:Int, suffix:String = null, i:Int = 0):Void
	{
		super();

		this.number = number;

		if (suffix == null && PlayState.isPixelStage) suffix = '-pixel';

		var instance:String = 'num' + number;
		var ourPath:String = 'numbers/' + instance;

		if (suffix != null && suffix.length > 0)
		{
			ourPath += suffix;
			var pathShit:String = instance + suffix;

			if (Paths.fileExists('images/pixelUI/' + pathShit + '.png', IMAGE) && PlayState.isPixelStage) {
				ourPath = 'pixelUI/' + pathShit;
			}
			else if (Paths.fileExists('images/' + pathShit + '.png', IMAGE)) {
				ourPath = pathShit;
			}
		}
		else
		{
			if (Paths.fileExists('images/pixelUI/' + instance + '.png', IMAGE) && PlayState.isPixelStage) {
				ourPath = 'pixelUI/' + instance;
			}
			else if (Paths.fileExists('images/' + instance + '.png', IMAGE)) {
				ourPath = instance;
			}
		}

		loadGraphic(Paths.getImage(ourPath));
		setPosition(705 + (43 * i) - 175, ((FlxG.height - height) / 2) + 80);

		antialiasing = OptionData.globalAntialiasing && !PlayState.isPixelStage;

		setGraphicSize(Std.int(width * (PlayState.isPixelStage ? PlayState.daPixelZoom : 0.5)));
		updateHitbox();

		var playbackRate:Float = 1;

		if (PlayState.instance != null) {
			playbackRate = PlayState.instance.playbackRate;
		}
		
		acceleration.y = FlxG.random.int(200, 300) * playbackRate * playbackRate;
		velocity.set(FlxG.random.float(-5, 5) * playbackRate, velocity.y - (FlxG.random.int(140, 160) * playbackRate));

		var offset:Array<Int> = OptionData.comboOffset.copy();
		setPosition(x + offset[2], y + offset[3]);

		visible = OptionData.showNumbers;
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		visible = OptionData.showNumbers;
	}
}