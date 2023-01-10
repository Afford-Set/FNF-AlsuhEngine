package;

import flixel.FlxSprite;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var sprTracker:FlxSprite;

	public var isPlayer:Bool = false;
	public var character:String = 'bf';

	public function new(char:String = 'bf', isPlayer:Bool = false):Void
	{
		super();

		this.character = '';
		this.isPlayer = isPlayer;

		changeIcon(char);

		antialiasing = char.endsWith('-pixel') ? false : OptionData.globalAntialiasing;
		scrollFactor.set();
	}

	public function changeIcon(char:String):Void
	{
		if (char != this.character)
		{
			var name:String = Paths.fileExists('images/icons/' + char + '.png', IMAGE) ? 'icons/' + char : 'icons/icon-' + char;

			if (Paths.fileExists('images/' + name + '.png', IMAGE))
			{
				var file:Dynamic = Paths.getImage(name);
				loadGraphic(file); // Load stupidly first for getting the file size

				if (width >= 450)
				{
					loadGraphic(file, true, Math.floor(width / 3), Math.floor(height)); // Then load it fr
					animation.add(char, [0, 1, 2], 0, false, this.isPlayer);
				}
				else
				{
					loadGraphic(file, true, Math.floor(width / 2), Math.floor(height)); // Then load it fr
					animation.add(char, [0, 1], 0, false, this.isPlayer);
				}

				animation.play(char);
				this.character = char;
			}
			else {
				changeIcon("face");
			}

			antialiasing = char.endsWith('-pixel') ? false : OptionData.globalAntialiasing;
		}
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		snapToPosition();
	}

	public function snapToPosition():Void
	{
		if (sprTracker != null) {
			setPosition(sprTracker.x + sprTracker.width + 12, sprTracker.y - 30);
		}
	}

	public function getCharacter():String
	{
		return character;
	}
}