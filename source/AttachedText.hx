package;

import flixel.FlxSprite;

class AttachedText extends Alphabet
{
	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public var sprTracker:FlxSprite;

	public var copyVisible:Bool = false;
	public var copyAlpha:Bool = false;

	public function new(text:String = '', ?offsetX:Float = 0, ?offsetY:Float = 0, ?bold:Bool = false, ?scale:Float = 1):Void
	{
		super(0, 0, text, bold);

		this.scaleX = scale;
		this.scaleY = scale;

		this.isMenuItem = false;

		this.offsetX = offsetX;
		this.offsetY = offsetY;
	}

	public override function update(elapsed:Float):Void
	{
		snapToUpdateVariables();

		super.update(elapsed);
	}

	public function snapToUpdateVariables():Void
	{
		if (sprTracker != null)
		{
			setPosition(sprTracker.x + offsetX, sprTracker.y + offsetY);

			if (copyVisible) {
				visible = sprTracker.visible;
			}

			if (copyAlpha) {
				alpha = sprTracker.alpha;
			}
		}
	}
}