package;

import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class TankmenBG extends FlxSprite
{
	private var tankSpeed:Float;
	private var endingOffset:Float;
	private var goingRight:Bool;

	public var strumTime:Float;

	public function new(x:Float, y:Float, facingRight:Bool):Void
	{
		tankSpeed = 0.7;
		goingRight = false;

		strumTime = 0;
		goingRight = facingRight;

		super(x, y);

		frames = Paths.getSparrowAtlas('tankmanKilled1');

		animation.addByPrefix('run', 'tankman running', 24, true);
		animation.addByPrefix('shot', 'John Shot ' + FlxG.random.int(1, 2), 24, false);
		animation.play('run');

		animation.curAnim.curFrame = FlxG.random.int(0, animation.curAnim.frames.length - 1);

		antialiasing = OptionData.globalAntialiasing;

		updateHitbox();
		setGraphicSize(Std.int(0.8 * width));
		updateHitbox();
	}

	public function resetShit(x:Float, y:Float, goingRight:Bool):Void
	{
		this.x = x;
		this.y = y;

		this.goingRight = goingRight;

		endingOffset = FlxG.random.float(50, 200);
		tankSpeed = FlxG.random.float(0.6, 1);

		flipX = goingRight;
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		visible = (x > -0.5 * FlxG.width && x < 1.2 * FlxG.width);

		if (animation.curAnim.name == 'run')
		{
			var endDirection:Float = (FlxG.width * 0.74) + endingOffset;

			if (goingRight)
			{
				endDirection = (FlxG.width * 0.02) - endingOffset;
				x = (endDirection + (Conductor.songPosition - strumTime) * tankSpeed);
			}
			else {
				x = (endDirection - (Conductor.songPosition - strumTime) * tankSpeed);
			}
		}

		if (Conductor.songPosition > strumTime)
		{
			animation.play('shot');

			if (goingRight)
			{
				offset.y = 200;
				offset.x = 300;
			}
		}

		if (animation.curAnim.name == 'shot' && animation.curAnim.curFrame >= animation.curAnim.frames.length - 1) {
			kill();
		}
	}
}