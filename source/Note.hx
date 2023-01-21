package;

import flixel.FlxG;
import flixel.FlxSprite;
import shaders.ColorSwap;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import editors.ChartingState;
import flash.display.BitmapData;
import flixel.graphics.FlxGraphic;

using StringTools;

typedef EventNote =
{
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

class Note extends FlxSprite
{
	public var strumTime:Float = 0;

	public var spawned:Bool = false;

	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; // 9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick
	public var ratingDisabled:Bool = false;

	public var parent:Note;

	public var blockHit:Bool = false; // only works for player

	public var tail:Array<Note> = []; // for sustains lol
	public var mustPress:Bool = false;
	public var noteData:Int = 0;
	public var canBeHit:Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;

	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var noteType(default, set):String = null;

	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	public var scoreDisabled:Bool = false;
	public var healthDisabled:Bool = false;

	public var colorSwap:ColorSwap;
	public var inEditor:Bool = false;
	private var earlyHitMult:Float = 0.5;

	public static var maxNote:Int = 4;
	public static var swagWidth:Float = 160 * 0.7;
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];

	private var pixelInt:Array<Int> = [0, 1, 2, 3];

	// Lua shit
	public var quickNoteSplash:Bool = false;
	public var noteSplashHitByOpponent:Bool = false;
	public var noteSplashDisabled:Bool = false;
	public var noteSplashTexture:String = null;

	public var noteSplashHue:Float = 0;
	public var noteSplashSat:Float = 0;
	public var noteSplashBrt:Float = 0;

	public var offsetX:Float = 0;
	public var offsetY:Float = 0;
	public var offsetAngle:Float = 0;

	public var multAlpha:Float = 1;
	public var multSpeed(default, set):Float = 1;
	public var distance:Float = 2000; //plan on doing scroll directions soon -bb

	public var copyX:Bool = true;
	public var copyY:Bool = true;

	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var hithealth_sick:Float = 0.025;
	public var hithealth_sick_sus:Float = 0.0125;
	public var hithealth_good:Float = 0.020;
	public var hithealth_good_sus:Float = 0.010;
	public var hithealth_bad:Float = 0.010;
	public var hithealth_bad_sus:Float = 0.005;
	public var hithealth_shit:Float = 0;
	public var hithealth_shit_sus:Float = 0;

	public var missHealth:Float = 0.0475;

	public var animSuffix:String = '';
	public var gfNote:Bool = false;
	public var noAnimation:Bool = false;
	public var noMissAnimation:Bool = false;

	public var lowPriority:Bool = false;
	public var texture(default, set):String = null;
	public var hitsoundDisabled:Bool = false;

	private function set_multSpeed(value:Float):Float
	{
		resizeByRatio(value / multSpeed);
		multSpeed = value;

		return value;
	}

	public function resizeByRatio(ratio:Float):Void // haha funny twitter shit
	{
		if (isSustainNote && !animation.curAnim.name.endsWith('end'))
		{
			scale.y *= ratio;
			updateHitbox();
		}
	}

	public var hitCausesMiss:Bool = false;

	private function set_texture(value:String):String
	{
		if (texture != value) {
			reloadNote('', value);
		}

		texture = value;
		return value;
	}

	private function set_noteType(value:String):String
	{
		noteSplashTexture = PlayState.SONG.splashSkin;

		if (noteData > -1 && noteData < OptionData.arrowHSV.length)
		{
			colorSwap.hue = OptionData.arrowHSV[noteData % maxNote][0] / 360;
			colorSwap.saturation = OptionData.arrowHSV[noteData % maxNote][1] / 100;
			colorSwap.brightness = OptionData.arrowHSV[noteData % maxNote][2] / 100;
		}

		if (noteData > -1 && noteType != value)
		{
			switch (value)
			{
				case 'Hurt Note':
				{
					ignoreNote = mustPress;
					reloadNote('HURT');

					noteSplashTexture = 'HURTNOTE_splashes';

					colorSwap.hue = 0;
					colorSwap.saturation = 0;
					colorSwap.brightness = 0;

					lowPriority = true;

					if (isSustainNote) {
						missHealth = 0.1;
					}
					else {
						missHealth = 0.3;
					}

					hitCausesMiss = true;
				}
				case 'Alt Animation': {
					animSuffix = '-alt';
				}
				case 'No Animation':
				{
					noAnimation = true;
					noMissAnimation = true;
				}
				case 'GF Sing': {
					gfNote = true;
				}
			}

			noteType = value;
		}

		noteSplashHue = colorSwap.hue;
		noteSplashSat = colorSwap.saturation;
		noteSplashBrt = colorSwap.brightness;

		return value;
	}

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?isSustainNote:Bool = false, ?inEditor:Bool = false, ?mustPress:Bool = false):Void
	{
		super();

		if (prevNote == null) {
			prevNote = this;
		}

		this.prevNote = prevNote;
		this.isSustainNote = isSustainNote;
		this.inEditor = inEditor;
		this.mustPress = mustPress;

		x += (OptionData.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X) + 50;

		y -= 2000;

		this.strumTime = strumTime;

		if (!inEditor) this.strumTime += OptionData.noteOffset;

		this.noteData = noteData;

		if (noteData > -1)
		{
			texture = '';

			colorSwap = new ColorSwap();
			shader = colorSwap.shader;

			x += swagWidth * (noteData % maxNote);

			if (!isSustainNote) // Doing this 'if' check to fix the warnings on Senpai songs
			{
				var animToPlay:String = '';

				animToPlay = colArray[noteData % maxNote];
				animation.play(animToPlay + 'Scroll');
			}
		}

		if (isSustainNote && prevNote != null)
		{
			alpha = 0.6;
			multAlpha = 0.6;

			hitsoundDisabled = true;

			if (OptionData.downScroll == true) flipY = true;

			offsetX += width / 2;
			copyAngle = false;

			animation.play(colArray[noteData % maxNote] + 'holdend');

			updateHitbox();

			offsetX -= width / 2;

			if (PlayState.isPixelStage) {
				offsetX += 30;
			}

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % maxNote] + 'hold');
				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.05 * PlayState.SONG.speed;

				if (PlayState.isPixelStage) {
					prevNote.scale.y *= 1.19;
				}

				prevNote.updateHitbox();
			}

			if (PlayState.isPixelStage)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
		}
		else if (!isSustainNote) {
			earlyHitMult = 1;
		}

		x += offsetX;
	}

	public var originalHeightForCalcs:Float = 6;

	function reloadNote(?prefix:String = '', ?texture:String = '', ?suffix:String = ''):Void
	{
		if (prefix == null) prefix = '';
		if (texture == null) texture = '';
		if (suffix == null) suffix = '';
		
		var skin:String = texture;

		if (texture.length < 1)
		{
			skin = mustPress ? PlayState.SONG.arrowSkin : PlayState.SONG.arrowSkin2;
	
			if (skin == null || skin.length < 1) {
				skin = 'NOTE_assets';
			}
		}

		var animName:String = null;

		if (animation.curAnim != null) {
			animName = animation.curAnim.name;
		}

		var arraySkin:Array<String> = skin.split('/');
		arraySkin[arraySkin.length - 1] = prefix + arraySkin[arraySkin.length - 1] + suffix;

		var lastScaleY:Float = scale.y;
		var blahblah:String = arraySkin.join('/');

		if (PlayState.isPixelStage)
		{
			if (isSustainNote)
			{
				var ourGraphic:FlxGraphic = Paths.getImage('notes/' + blahblah + 'ENDS');

				if (Paths.fileExists('images/' + blahblah + 'ENDS' + '.png', IMAGE)) {
					ourGraphic = Paths.getImage(blahblah + 'ENDS');
				}
				else if (Paths.fileExists('images/pixelUI/' + blahblah + 'ENDS' + '.png', IMAGE)) {
					ourGraphic = Paths.getImage('pixelUI/' + blahblah + 'ENDS');
				}
				else if (Paths.fileExists('images/notes/pixel/' + blahblah + 'ENDS' + '.png', IMAGE)) {
					ourGraphic = Paths.getImage('notes/pixel/' + blahblah + 'ENDS');
				}

				loadGraphic(ourGraphic);

				width = width / 4;
				height = height / 2;

				originalHeightForCalcs = height;

				loadGraphic(ourGraphic, true, Math.floor(width), Math.floor(height));
			}
			else
			{
				var ourGraphic:FlxGraphic = Paths.getImage('notes/' + blahblah);

				if (Paths.fileExists('images/' + blahblah + '.png', IMAGE)) {
					ourGraphic = Paths.getImage(blahblah);
				}
				else if (Paths.fileExists('images/pixelUI/' + blahblah + '.png', IMAGE)) {
					ourGraphic = Paths.getImage('pixelUI/' + blahblah);
				}
				else if (Paths.fileExists('images/notes/pixel/' + blahblah + '.png', IMAGE)) {
					ourGraphic = Paths.getImage('notes/pixel/' + blahblah);
				}

				loadGraphic(ourGraphic);

				width = width / 4;
				height = height / 5;

				loadGraphic(ourGraphic, true, Math.floor(width), Math.floor(height));
			}

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
			loadPixelNoteAnims();
			antialiasing = false;
		}
		else
		{
			if (Paths.fileExists('images/' + blahblah + '.png', IMAGE)) {
				frames = Paths.getSparrowAtlas(blahblah);
			}
			else {
				frames = Paths.getSparrowAtlas('notes/' + blahblah);
			}

			loadNoteAnims();
			antialiasing = OptionData.globalAntialiasing;
		}

		if (isSustainNote) {
			scale.y = lastScaleY;
		}

		updateHitbox();

		if (animName != null) {
			animation.play(animName, true);
		}

		if (inEditor)
		{
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE); // fucking import
			updateHitbox();
		}
	}

	function loadNoteAnims():Void
	{
		var ourCol:String = colArray[noteData];
		var blyad:String = ourCol + ' instance';
		var fuck:String = blyad + ' 10000';

		if (frames.getByName(fuck) == null) blyad = ourCol + '0';

		animation.addByPrefix(ourCol + 'Scroll', blyad);

		if (isSustainNote)
		{
			animation.addByPrefix('purpleholdend', 'pruple end hold'); // plz not delete this

			animation.addByPrefix(ourCol + 'holdend', ourCol + ' hold end');
			animation.addByPrefix(ourCol + 'hold', ourCol + ' hold piece');
		}

		setGraphicSize(Std.int(width * 0.7));
		updateHitbox();
	}

	function loadPixelNoteAnims():Void
	{
		var ourCol:String = colArray[noteData];

		if (isSustainNote)
		{
			animation.add(ourCol + 'holdend', [pixelInt[noteData] + maxNote]);
			animation.add(ourCol + 'hold', [pixelInt[noteData]]);
		}
		else {
			animation.add(ourCol + 'Scroll', [pixelInt[noteData] + maxNote]);
		}
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (noteData > -1)
		{
			colorSwap.hue = OptionData.arrowHSV[noteData % maxNote][0] / 360;
			colorSwap.saturation = OptionData.arrowHSV[noteData % maxNote][1] / 100;
			colorSwap.brightness = OptionData.arrowHSV[noteData % maxNote][2] / 100;
		}

		if (mustPress)
		{
			if (strumTime > Conductor.songPosition - Conductor.safeZoneOffset && strumTime < Conductor.songPosition + (Conductor.safeZoneOffset * earlyHitMult)) {
				canBeHit = true;
			}
			else {
				canBeHit = false;
			}

			if (strumTime < Conductor.songPosition - Conductor.safeZoneOffset && !wasGoodHit) {
				tooLate = true;
			}
		}
		else
		{
			canBeHit = false;

			if (strumTime <= Conductor.songPosition) {
				wasGoodHit = true;
			}
		}

		if (tooLate)
		{
			if (alpha > 0.3) {
				alpha = 0.3;
			}
		}
	}
}