package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;

using StringTools;

class PhillyGlowParticle extends FlxSprite
{
	var lifeTime:Float = 0;
	var decay:Float = 0;

	var originalScale:Float = 1;

	public function new(x:Float, y:Float, color:FlxColor):Void
	{
		super(x, y);

		this.color = color;

		loadGraphic(Paths.getImage('philly/particle'));

		antialiasing = OptionData.globalAntialiasing;

		lifeTime = FlxG.random.float(0.6, 0.9);
		decay = FlxG.random.float(0.8, 1);

		if (!OptionData.flashingLights)
		{
			decay *= 0.5;
			alpha = 0.5;
		}

		originalScale = FlxG.random.float(0.75, 1);
		scale.set(originalScale, originalScale);

		scrollFactor.set(FlxG.random.float(0.3, 0.75), FlxG.random.float(0.65, 0.75));
		velocity.set(FlxG.random.float(-40, 40), FlxG.random.float(-175, -250));
		acceleration.set(FlxG.random.float(-10, 10), 25);
	}

	public override function update(elapsed:Float):Void
	{
		lifeTime -= elapsed;

		if (lifeTime < 0)
		{
			lifeTime = 0;
			alpha -= decay * elapsed;

			if (alpha > 0) {
				scale.set(originalScale * alpha, originalScale * alpha);
			}
		}

		super.update(elapsed);
	}
}

class PhillyGlowGradient extends FlxSprite
{
	public var originalY:Float;
	public var originalHeight:Int = 400;

	public var intendedAlpha:Float = 1;

	public function new(x:Float, y:Float):Void
	{
		super(x, y);

		originalY = y;

		loadGraphic(Paths.getImage('philly/gradient'));

		antialiasing = OptionData.globalAntialiasing;
		scrollFactor.set(0, 0.75);

		setGraphicSize(2000, originalHeight);
		updateHitbox();
	}

	public override function update(elapsed:Float):Void
	{
		var newHeight:Int = Math.round(height - 1000 * elapsed);

		if (newHeight > 0)
		{
			alpha = intendedAlpha;

			setGraphicSize(2000, newHeight);
			updateHitbox();

			y = originalY + (originalHeight - height);
		}
		else
		{
			alpha = 0;
			y = -5000;
		}

		super.update(elapsed);
	}

	public function bop():Void
	{
		setGraphicSize(2000, originalHeight);
		updateHitbox();

		y = originalY;
		alpha = intendedAlpha;
	}
}