package;

import haxe.Json;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.tweens.FlxTween;
import animateatlas.AtlasFrameMaker;
import flixel.animation.FlxAnimation;

using StringTools;

typedef CharacterFile =
{
	var char_name:String;
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
	var skip_dance:Bool;
	var healthicon:String;

	var position:Array<Float>;
	var camera_position:Array<Float>;

	var flip_x:Bool;
	var no_antialiasing:Bool;
	var healthbar_colors:Array<Int>;

	var gameover_properties:Array<String>;
}

typedef AnimArray =
{
	var anim:String;
	var name:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
	var offsets:Array<Int>;
}

class Character extends FlxSprite
{
	public var char_name:String = 'Boyfriend';

	public var animOffsets:Map<String, Array<Float>> = new Map<String, Array<Float>>();
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var stunned:Bool = false;
	public var singDuration:Float = 4; //Multiplier of how long a character holds the sing pose
	public var idleSuffix:String = '';
	public var danceIdle:Bool = false; //Character use "danceLeft" and "danceRight" instead of "idle"
	public var skipDance:Bool = false;

	public var healthIcon:String = 'face';
	public var animationsArray:Array<AnimArray> = [];

	public var positionArray:Array<Float> = [0, 0];
	public var cameraPosition:Array<Float> = [0, 0];

	public var hasMissAnimations:Bool = false;

	public var deathChar:String = 'bf-dead';
	public var deathSound:String = 'fnf_loss_sfx';
	public var deathConfirm:String = 'gameOverEnd';
	public var deathMusic:String = 'gameOver';

	// Used on Character Editor
	public var imageFile:String = '';
	public var jsonScale:Float = 1;
	public var noAntialiasing:Bool = false;
	public var originalFlipX:Bool = false;
	public var healthColorArray:Array<Int> = [255, 0, 0];

	public static var DEFAULT_CHARACTER:String = 'bf'; //In case a character is missing, it will use BF on its place

	public function new(x:Float, y:Float, ?character:String = 'bf', ?isPlayer:Bool = false):Void
	{
		super(x, y);

		this.curCharacter = character;
		this.isPlayer = isPlayer;

		antialiasing = OptionData.globalAntialiasing;

		switch (curCharacter)
		{
			// case 'your character name in case you want to hardcode them instead':
			// {
			// }
			default:
			{
				var path:String = 'characters/' + DEFAULT_CHARACTER + '.json';
				var characterPath:String = 'characters/' + curCharacter + '.json';

				if (Paths.fileExists(characterPath, TEXT)) {
					path = characterPath;
				}

				var json:CharacterFile = getCharacterFile(path);
				var spriteType:String = 'sparrow';
				
				if (Paths.fileExists('images/' + json.image + '.txt', TEXT, true)) {
					spriteType = 'packer';
				}
				else if (Paths.fileExists('images/' + json.image + '/Animation.json', TEXT, true)) {
					spriteType = 'texture';
				}

				switch (spriteType)
				{
					case 'packer':
						frames = Paths.getPackerAtlas(json.image);
					case 'sparrow':
						frames = Paths.getSparrowAtlas(json.image);
					case 'texture':
						frames = AtlasFrameMaker.construct(json.image);
				}

				imageFile = json.image;

				if (json.scale != 1)
				{
					jsonScale = json.scale;

					setGraphicSize(Std.int(width * jsonScale));
					updateHitbox();
				}

				char_name = (json.char_name != null && json.char_name.length > 0) ? json.char_name : 'Unknown';

				positionArray = json.position;
				cameraPosition = json.camera_position;

				healthIcon = json.healthicon;
				singDuration = json.sing_duration;
				flipX = json.flip_x == true;
				skipDance = json.skip_dance == true; // ????

				if (json.no_antialiasing)
				{
					antialiasing = false;
					noAntialiasing = true;
				}

				if (json.gameover_properties != null)
				{
					deathChar = json.gameover_properties[0];
					deathSound = json.gameover_properties[1];
					deathMusic = json.gameover_properties[2];
					deathConfirm = json.gameover_properties[3];
				}

				if (json.healthbar_colors != null && json.healthbar_colors.length > 2) {
					healthColorArray = json.healthbar_colors;
				}

				antialiasing = OptionData.globalAntialiasing && !noAntialiasing;
				animationsArray = json.animations;

				if (animationsArray != null && animationsArray.length > 0)
				{
					for (anim in animationsArray)
					{
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = anim.loop == true; // Bruh
						var animIndices:Array<Int> = anim.indices;

						if (animIndices != null && animIndices.length > 0) {
							animation.addByIndices(animAnim, animName, animIndices, "", animFps, animLoop);
						}
						else {
							animation.addByPrefix(animAnim, animName, animFps, animLoop);
						}

						if (anim.offsets != null && anim.offsets.length > 1) {
							addOffset(anim.anim, anim.offsets[0], anim.offsets[1]);
						}
					}
				}
				else {
					quickAnimAdd('idle', 'BF idle dance');
				}
			}
		}

		originalFlipX = flipX;

		if (animExists('singLEFTmiss') || animExists('singDOWNmiss') || animExists('singUPmiss') || animExists('singRIGHTmiss')) {
			hasMissAnimations = true;
		}

		recalculateDanceIdle();
		dance();
		animation.finish();

		if (isPlayer)
		{
			flipX = !flipX;

			if (!curCharacter.startsWith('bf') && !curCharacter.endsWith('-player') && !debugMode) // Doesn't flip for BF, since his are already in the right place???
			{
				if (animation.exists('singLEFT') && animation.exists('singRIGHT'))
				{
					var oldRight:Array<Int> = animation.getByName('singRIGHT').frames;
					animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
					animation.getByName('singLEFT').frames = oldRight;
				}

				if (animation.exists('singLEFT-loop') && animation.exists('singRIGHT-loop'))
				{
					var oldRight:Array<Int> = animation.getByName('singRIGHT-loop').frames;
					animation.getByName('singRIGHT-loop').frames = animation.getByName('singLEFT-loop').frames;
					animation.getByName('singLEFT-loop').frames = oldRight;
				}

				if (animation.exists('singLEFTmiss') && animation.exists('singRIGHTmiss'))
				{
					var oldRight:Array<Int> = animation.getByName('singRIGHTmiss').frames;
					animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
					animation.getByName('singLEFTmiss').frames = oldRight;
				}

				if (animation.exists('singLEFTmiss-loop') && animation.exists('singRIGHTmiss-loop'))
				{
					var oldRight:Array<Int> = animation.getByName('singRIGHTmiss-loop').frames;
					animation.getByName('singRIGHTmiss-loop').frames = animation.getByName('singLEFTmiss-loop').frames;
					animation.getByName('singLEFTmiss-loop').frames = oldRight;
				}
			}
		}
	}

	public override function update(elapsed:Float):Void
	{
		if (!debugMode && animation.curAnim != null)
		{
			if (heyTimer > 0)
			{
				heyTimer -= elapsed * PlayState.instance.playbackRate;

				if (heyTimer <= 0)
				{
					if (specialAnim && animation.curAnim.name == 'hey' || animation.curAnim.name == 'cheer')
					{
						specialAnim = false;
						dance();
					}

					heyTimer = 0;
				}
			}
			else if (specialAnim && animation.curAnim.finished)
			{
				specialAnim = false;
				dance();
			}

			if (!isPlayer)
			{
				if (animation.curAnim.name.startsWith('sing')) {
					holdTimer += elapsed;
				}

				if (holdTimer >= Conductor.stepCrochet * (0.0011 / (FlxG.sound.music != null ? FlxG.sound.music.pitch : 1)) * singDuration)
				{
					dance();
					holdTimer = 0;
				}
			}

			if (animation.curAnim.finished && animExists(animation.curAnim.name + '-loop')) {
				playAnim(animation.curAnim.name + '-loop');
			}
		}

		super.update(elapsed);
	}

	public var danced:Bool = false;

	public function dance():Void
	{
		if (!debugMode && !skipDance && !specialAnim)
		{
			if (danceIdle)
			{
				danced = !danced;

				if (danced)
					playAnim('danceRight' + idleSuffix);
				else
					playAnim('danceLeft' + idleSuffix);
			}
			else if (animation.getByName('idle' + idleSuffix) != null) {
				playAnim('idle' + idleSuffix);
			}
		}
	}

	public function playAnim(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0, ?finishCallBack:(name:String)->Void = null, ?callback:(name:String, frameNumber:Int, frameIndex:Int)->Void = null):Void
	{
		if (animation.getByName(animName) != null)
		{
			specialAnim = false;
			animation.play(animName, force, reversed, frame);

			if (finishCallBack != null) {
				animation.finishCallback = finishCallBack;
			}

			if (callback != null) {
				animation.callback = callback;
			}

			var daOffset:Array<Float> = animOffsets.get(animName);

			if (animOffsets.exists(animName)) {
				offset.set(daOffset[0], daOffset[1]);
			}
			else
			{
				Debug.logWarn(char_name + ': Offsets of animation "' + animName + '" not found!');
				offset.set(0, 0);
			}

			if (curCharacter.startsWith('gf'))
			{
				if (animName == 'singLEFT') {
					danced = true;
				}
				else if (animName == 'singRIGHT') {
					danced = false;
				}

				if (animName == 'singUP' || animName == 'singDOWN') {
					danced = !danced;
				}
			}
		}
		else {
			Debug.logWarn(char_name + ': Animation name "' + animName + '" not found!');
		}
	}

	public var danceEveryNumBeats:Int = OptionData.danceOffset;
	private var settingCharacterUp:Bool = true;

	public function recalculateDanceIdle():Void
	{
		var lastDanceIdle:Bool = danceIdle;
		danceIdle = (animation.getByName('danceLeft' + idleSuffix) != null && animation.getByName('danceRight' + idleSuffix) != null);

		if (settingCharacterUp) {
			danceEveryNumBeats = (danceIdle ? 1 : OptionData.danceOffset);
		}
		else if (lastDanceIdle != danceIdle)
		{
			var calc:Float = danceEveryNumBeats;

			if (danceIdle)
				calc /= 2;
			else
				calc *= 2;

			danceEveryNumBeats = Math.round(Math.max(calc, 1));
		}

		settingCharacterUp = false;
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0):Void
	{
		animOffsets.set(name, [x, y]);
	}

	public function quickAnimAdd(name:String, anim:String):Void
	{
		animation.addByPrefix(name, anim, 24, false);
	}

	public function animExists(name:String):Bool
	{
		return animation.getByName(name) != null && animOffsets.exists(name);
	}

	public static function getCharacterFile(path:String, ?absolute:Bool = false):CharacterFile
	{
		var rawJson:String = null;

		if (Paths.fileExists(path, TEXT, absolute)) {
			rawJson = Paths.getTextFromFile(path);
		}

		if (rawJson != null && rawJson.length > 0) {
			return cast Json.parse(rawJson);
		}

		return null;
	}
}