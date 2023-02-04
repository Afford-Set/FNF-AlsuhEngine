package;

import haxe.Json;
import haxe.format.JsonParser;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxSort;
import Section.SwagSection;
import flixel.tweens.FlxTween;
import animateatlas.AtlasFrameMaker;

using StringTools;

typedef CharacterFile =
{
	var char_name:String;
	var animations:Array<AnimArray>;
	var image:String;
	var scale:Float;
	var sing_duration:Float;
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

	public var animOffsets:Map<String, Array<Float>>;
	public var debugMode:Bool = false;

	public var isPlayer:Bool = false;
	public var curCharacter:String = DEFAULT_CHARACTER;

	public var colorTween:FlxTween;
	public var holdTimer:Float = 0;
	public var heyTimer:Float = 0;
	public var specialAnim:Bool = false;
	public var animationNotes:Array<Dynamic> = [];
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

	public function new(x:Float, y:Float, ?curCharacter:String = 'bf', ?isPlayer:Bool = false):Void
	{
		super(x, y);

		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end

		this.curCharacter = curCharacter;
		this.isPlayer = isPlayer;

		antialiasing = OptionData.globalAntialiasing;

		switch (curCharacter)
		{
			// case 'your character name in case you want to hardcode them instead':
			// {
			// }
			default:
			{
				var path:String = Paths.getFile('characters/' + DEFAULT_CHARACTER + '.json', TEXT);
				var characterPath:String = 'characters/' + curCharacter + '.json';

				if (Paths.fileExists(characterPath, TEXT)) {
					path = Paths.getFile(characterPath, TEXT);
				}

				var rawJson:String = Paths.getTextFromFile(path);

				var json:CharacterFile = cast Json.parse(rawJson);
				var spriteType:String = 'sparrow';

				var txtToFind:String = Paths.getFile('images/' + json.image + '.txt', TEXT);
				
				if (Paths.fileExists(txtToFind, TEXT)) {
					spriteType = 'packer';
				}

				var animToFind:String = Paths.getFile('images/' + json.image + '/Animation.json', TEXT);

				if (Paths.fileExists(animToFind, TEXT)) {
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
				flipX = !!json.flip_x;

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

				antialiasing = noAntialiasing ? false : OptionData.globalAntialiasing;
				animationsArray = json.animations;

				if (animationsArray != null && animationsArray.length > 0)
				{
					for (anim in animationsArray)
					{
						var animAnim:String = '' + anim.anim;
						var animName:String = '' + anim.name;
						var animFps:Int = anim.fps;
						var animLoop:Bool = !!anim.loop; // Bruh
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

		if (animOffsets.exists('singLEFTmiss') || animOffsets.exists('singDOWNmiss') || animOffsets.exists('singUPmiss') || animOffsets.exists('singRIGHTmiss')) hasMissAnimations = true;

		recalculateDanceIdle();
		dance();

		if (isPlayer) {
			flipX = !flipX;
		}

		switch (curCharacter)
		{
			case 'pico-speaker':
			{
				skipDance = true;

				loadMappedAnims();
				playAnim("shoot1");
			}
		}
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!debugMode && animation.curAnim != null)
		{
			if (heyTimer > 0)
			{
				heyTimer -= elapsed;

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
			
			switch (curCharacter)
			{
				case 'pico-speaker':
				{
					if (animationNotes.length > 0 && Conductor.songPosition > animationNotes[0][0])
					{
						var noteData:Int = 1;
						if (animationNotes[0][1] > 2) noteData = 3;

						noteData += FlxG.random.int(0, 1);
						playAnim('shoot' + noteData, true);
						animationNotes.shift();
					}

					if (animation.curAnim.finished) playAnim(animation.curAnim.name, false, false, animation.curAnim.frames.length - 3);
				}
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

			if (animation.curAnim.finished && animation.getByName(animation.curAnim.name + '-loop') != null)
			{
				playAnim(animation.curAnim.name + '-loop');
			}
		}
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

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0, ?finishCallBack:(name:String)->Void = null, ?callback:(name:String, frameNumber:Int, frameIndex:Int)->Void = null):Void
	{
		specialAnim = false;
		animation.play(AnimName, Force, Reversed, Frame);

		if (finishCallBack != null) {
			animation.finishCallback = finishCallBack;
		}

		if (callback != null) {
			animation.callback = callback;
		}

		var daOffset = animOffsets.get(AnimName);

		if (animOffsets.exists(AnimName)) {
			offset.set(daOffset[0], daOffset[1]);
		}
		else {
			offset.set(0, 0);
		}

		if (curCharacter.startsWith('gf'))
		{
			if (AnimName == 'singLEFT') {
				danced = true;
			}
			else if (AnimName == 'singRIGHT') {
				danced = false;
			}

			if (AnimName == 'singUP' || AnimName == 'singDOWN') {
				danced = !danced;
			}
		}
	}
	
	function loadMappedAnims():Void
	{
		var noteData:Array<SwagSection> = Song.loadFromJson('picospeaker', PlayState.SONG.songID).notes;

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes) {
				animationNotes.push(songNotes);
			}
		}

		TankmenBG.animationNotes = animationNotes;

		animationNotes.sort(sortAnims);
	}

	function sortAnims(Obj1:Array<Dynamic>, Obj2:Array<Dynamic>):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1[0], Obj2[0]);
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
		animOffsets[name] = [x, y];
	}

	public function quickAnimAdd(name:String, anim:String):Void
	{
		animation.addByPrefix(name, anim, 24, false);
	}
}