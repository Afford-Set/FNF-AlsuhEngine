package;

import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;

using StringTools;

class HealthIcon extends FlxSprite
{
	public static var DEFAULT_WIDTH:Int = 150;

	public var sprTracker:FlxSprite;

	public var isPlayer:Bool = false;
	public var character:String = '';

	private var char(get, never):String;

	public function new(char:String = 'bf', isPlayer:Bool = false):Void
	{
		super();

		this.isPlayer = isPlayer;

		changeIcon(char);
		scrollFactor.set();
	}

	public var iconOffsets:Array<Float> = [0, 0, 0];

	public function changeIcon(char:String = 'face'):Void
	{
		if (character != char)
		{
			var name:String = 'icons/icon-' + char;

			if (Paths.fileExists('images/icons/' + char + '.png', IMAGE)) {
				name = 'icons/' + char;
			}

			if (Paths.fileExists('images/' + name + '.png', IMAGE))
			{
				var file:FlxGraphic = Paths.getImage(name);
				loadGraphic(file); // Load stupidly first for getting the file size

				var ken:Int = 3; // 3 - these alive, dead and win icons

				if (width < DEFAULT_WIDTH * ken) {
					ken = 2; // 2 - these alive and dead icons
				}

				loadGraphic(file, true, Math.floor(width / ken), Math.floor(height)); // Then load it fr

				var pos:Float = (width - DEFAULT_WIDTH) / ken;
				for (i in 0...ken) iconOffsets[i] = pos;

				animation.add(char, [for (i in 0...ken) i], 0, false, isPlayer);

				animation.play(char);
				antialiasing = OptionData.globalAntialiasing && !char.endsWith('-pixel');

				character = char;
			}
			else {
				changeIcon();
			}
		}
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		snapToPosition();
	}

	public var usePsych:Bool = false; // for lua

	public override function updateHitbox():Void
	{
		super.updateHitbox();

		if (usePsych)
		{
			offset.x = iconOffsets[0];
			offset.y = iconOffsets[1];
		}
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

	private function get_char():String return character;
}