package;

import haxe.Json;
import haxe.format.JsonParser;

import flixel.FlxSprite;

using StringTools;

typedef MenuCharacterFile =
{
	var image:String;
	var scale:Float;
	var position:Array<Int>;
	var idle_anim:String;
	var idle_animAlt:String;
	var indices:Array<Int>;
	var indicesAlt:Array<Int>;
	var fps:Null<Int>;
	var fpsAlt:Null<Int>;
	var fpsConfirm:Null<Int>;
	var confirm_anim:String;
	var isGF:Bool;
	var flipX:Bool;
}

class MenuCharacter extends FlxSprite
{
	public var character:String;
	public var hasConfirmAnimation:Bool = false;

	public var isDanced:Bool = false;

	public var heyed:Bool = false;

	private static var DEFAULT_CHARACTER:String = 'bf';

	public function new(x:Float, character:String = 'bf'):Void
	{
		super(x);

		changeCharacter(character);
	}

	public function changeCharacter(?character:String = 'bf'):Void
	{
		if (character == null) character = '';
		if (character == this.character) return;

		this.character = character;

		antialiasing = OptionData.globalAntialiasing;
		visible = true;

		var dontPlayAnim:Bool = false;
		scale.set(1, 1);
		updateHitbox();

		hasConfirmAnimation = false;

		switch (character)
		{
			case '':
			{
				visible = false;
				dontPlayAnim = true;
			}
			default:
			{
				var rawJson:String = null;
				var path:String = Paths.getFile('menucharacters/$DEFAULT_CHARACTER.json', TEXT);

				if (Paths.fileExists('images/menucharacters/$character.json', TEXT)) {
					path = Paths.getFile('images/menucharacters/$character.json', TEXT);
				}
				else if (Paths.fileExists('images/storymenu/menucharacters/$character.json', TEXT)) {
					path = Paths.getFile('images/storymenu/menucharacters/$character.json', TEXT);
				}
				else if (Paths.fileExists('menucharacters/$character.json', TEXT)) {
					path = Paths.getFile('menucharacters/$character.json', TEXT);
				}

				rawJson = Paths.getTextFromFile(path);
				
				var charFile:MenuCharacterFile = cast Json.parse(rawJson);

				if (Paths.fileExists('images/menucharacters/' + charFile.image + '.png', IMAGE)) {
					frames = Paths.getSparrowAtlas('menucharacters/' + charFile.image);
				}
				else {
					frames = Paths.getSparrowAtlas('storymenu/menucharacters/' + charFile.image);
				}

				isDanced = charFile.isGF;

				if (isDanced)
				{
					if (charFile.indicesAlt != null && charFile.indicesAlt.length > 0 && charFile.idle_animAlt != null) {
						animation.addByIndices('danceRight', charFile.idle_animAlt, charFile.indicesAlt, '', charFile.fpsAlt, false);
					}

					if (charFile.indices != null && charFile.indices.length > 0) {
						animation.addByIndices('danceLeft', charFile.idle_anim, charFile.indices, '', charFile.fps, false);
					}
				}
				else {
					animation.addByPrefix('idle', charFile.idle_anim, 24, false);
				}

				var confirmAnim:String = charFile.confirm_anim;

				if (confirmAnim != null && confirmAnim.length > 0 && confirmAnim != charFile.idle_anim)
				{
					animation.addByPrefix('confirm', confirmAnim, charFile.fpsConfirm, false);

					if (animation.getByName('confirm') != null) { // check for invalid animation
						hasConfirmAnimation = true;
					}
				}

				flipX = charFile.flipX == true;

				if (charFile.scale != 1)
				{
					scale.set(charFile.scale, charFile.scale);
					updateHitbox();
				}

				offset.set(charFile.position[0], charFile.position[1]);
				dance();
			}
		}
	}

	var danced:Bool = false;

	public function dance():Void
	{
		if (isDanced)
		{
			danced = !danced;

			if (danced)
				animation.play('danceRight');
			else
				animation.play('danceLeft');
		}
		else {
			animation.play('idle');
		}
	}

	public function hey():Void
	{
		heyed = true;
		animation.play('confirm');
	}
}