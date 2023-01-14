package;

import flixel.FlxSprite;

class CheckboxThingie extends FlxSprite
{
	public var sprTracker:FlxSprite;
	public var daValue(default, set):Bool;

	public var copyAlpha:Bool = true;
	public var copyVisible:Bool = true;

	public var isVanilla:Bool = false;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;

	public function new(x:Float = 0, y:Float = 0, ?checked:Bool = false):Void
	{
		super(x, y);

		if (Paths.fileExists('images/checkboxanim.png', IMAGE)) {
			frames = Paths.getSparrowAtlas('checkboxanim');
		}
		else if (Paths.fileExists('images/checkboxThingie.png', IMAGE)) {
			frames = Paths.getSparrowAtlas('checkboxThingie');
		}
		else if (Paths.fileExists('images/ui/checkboxanim.png', IMAGE)) {
			frames = Paths.getSparrowAtlas('ui/checkboxanim');
		}
		else {
			frames = Paths.getSparrowAtlas('ui/checkboxThingie');
		}

		isVanilla = frames.getByName('Check Box unselected0000') != null && frames.getByName('Check Box selecting animation0000') != null;

		if (isVanilla)
		{
			animation.addByPrefix('static', 'Check Box unselected', 24, false);
			animation.addByPrefix('checked', 'Check Box selecting animation', 24, false);
		}
		else
		{
			animation.addByPrefix('unchecked', 'checkbox0', 24, false);
			animation.addByPrefix('unchecking', 'checkbox anim reverse', 24, false);
			animation.addByPrefix('checking', 'checkbox anim0', 24, false);
			animation.addByPrefix('checked', 'checkbox finish', 24, false);
		}

		antialiasing = OptionData.globalAntialiasing;

		var sizeShit:Float = isVanilla ? 0.8 : 0.9;

		setGraphicSize(Std.int(sizeShit * width));
		updateHitbox();

		if (!isVanilla)
		{
			animationFinished(checked ? 'checking' : 'unchecking');
			animation.finishCallback = animationFinished;
		}

		animation.play('static');

		daValue = checked;
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		snapToUpdateVariables();
	}

	public function snapToUpdateVariables():Void
	{
		if (sprTracker != null)
		{
			if (isVanilla) {
				setPosition(sprTracker.x - 100 + offsetX, sprTracker.y + 5 + offsetY);
			}
			else {
				setPosition(sprTracker.x - 130 + offsetX, sprTracker.y + 30 + offsetY);
			}

			if (copyAlpha) {
				alpha = sprTracker.alpha;
			}

			if (copyVisible) {
				visible = sprTracker.visible;
			}
		}
	}

	private function set_daValue(check:Bool):Bool
	{
		daValue = check;

		if (isVanilla)
		{
			if (daValue)
			{
				if (animation.curAnim != null && animation.curAnim.name != 'checked')
				{
					animation.play('checked', true);
					offset.set(17, 70);
				}
			}
			else
			{
				animation.play('static');
				offset.set();
			}
		}
		else
		{
			if (daValue)
			{
				if (animation.curAnim.name != 'checked' && animation.curAnim.name != 'checking')
				{
					animation.play('checking', true);
					offset.set(34, 25);
				}
			}
			else if (animation.curAnim.name != 'unchecked' && animation.curAnim.name != 'unchecking')
			{
				animation.play('unchecking', true);
				offset.set(25, 28);
			}
		}

		return check;
	}

	private function animationFinished(name:String):Void
	{
		if (!isVanilla)
		{
			switch (name)
			{
				case 'checking':
				{
					animation.play('checked', true);
					offset.set(3, 12);
				}
				case 'unchecking':
				{
					animation.play('unchecked', true);
					offset.set(0, 2);
				}
			}
		}
	}
}