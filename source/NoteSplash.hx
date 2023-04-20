package;

import flixel.FlxG;
import flixel.FlxSprite;
import shaderslmfao.ColorSwap;
import flixel.graphics.FlxGraphic;

using StringTools;

class NoteSplash extends FlxSprite
{
	public static var amountOfSparePerson:Int = 2;

	public var colorSwap:ColorSwap = null;
	public var isCustomHSB:Bool = false;

	public var note:Int = 0;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0):Void
	{
		super(x, y);

		this.note = note;

		var skin:String = 'noteSplashes';

		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) {
			skin = PlayState.SONG.splashSkin;
		}

		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		antialiasing = OptionData.globalAntialiasing;
	}

	private var isPsychArray:Array<Array<Bool>> = [for (i in 0...Note.maxNote) [for (j in 0...amountOfSparePerson) false]];

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = null, mustPress:Bool = true, isCustomHSB:Bool = false, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0):Void
	{
		if (PlayState.isPixelStage) {
			setPosition(x + 30, y + (Note.swagWidth / 2));
		}
		else {
			setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		}

		alpha = OptionData.splashOpacity;

		this.note = note;
		this.isCustomHSB = isCustomHSB;

		if (texture == null || texture.length < 1)
		{
			texture = 'noteSplashes';

			if (mustPress)
			{
				if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) {
					texture = PlayState.SONG.splashSkin;
				}
			}
			else
			{
				if (PlayState.SONG.splashSkin2 != null && PlayState.SONG.splashSkin2.length > 0) {
					texture = PlayState.SONG.splashSkin2;
				}
			}
		}

		loadTexture(texture);

		if (PlayState.isPixelStage) {
			loadPixelAnims();
		}
		else {
			loadAnims();
		}

		if (!isCustomHSB)
		{
			colorSwap.hue = hueColor;
			colorSwap.saturation = satColor;
			colorSwap.brightness = brtColor;
		}

		var animNum:Int = FlxG.random.int(1, amountOfSparePerson);

		if (isPsychArray[note][animNum] || PlayState.isPixelStage) {
			offset.set(10, 10);
		}
		else {
			offset.set(-30, -15);
		}

		var ourPrefix:String = 'note$note-$animNum';
		animation.play(ourPrefix, true);

		if (animation.curAnim != null) {
			animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
		}
	}

	var pixelQuantity:Int = 4;

	function loadTexture(skin:String):Void
	{
		if (PlayState.isPixelStage)
		{
			var pathShit:String = 'notes/pixel/' + skin;

			if (Paths.fileExists('images/pixelUI/' + skin + '.png', IMAGE)) {
				pathShit = 'pixelUI/' + skin;
			}

			var graphic:FlxGraphic = Paths.getImage(pathShit);
			loadGraphic(graphic);

			width = width / (pixelQuantity * amountOfSparePerson);
			height = height / Note.maxNote;
	
			loadGraphic(graphic, true, Math.floor(width), Math.floor(height));
	
			antialiasing = false;
			setGraphicSize(Std.int(width * PlayState.daPixelZoom));
		}
		else
		{
			var pathShit:String = 'notes/' + skin;

			if (Paths.fileExists('images/' + skin + '.png', IMAGE)) {
				pathShit = skin;
			}

			frames = Paths.getSparrowAtlas(pathShit);
			scale.set(1, 1);
		}
	}

	function loadAnims():Void
	{
		for (i in 0...Note.maxNote)
		{
			for (j in 1...amountOfSparePerson + 1)
			{
				var color:String = Note.colArray[i];
				var ourPrefix:String = 'note' + i + '-' + j;

				var tempPsych:String = 'note splash ' + color + ' ' + j;
				var animName:String = tempPsych + '0000';
				isPsychArray[i][j] = frames.getByName(animName) != null;

				if (isPsychArray[i][j]) {
					animation.addByPrefix(ourPrefix, tempPsych, 24, false);
				}
				else
				{
					var shit:String = 'note impact ' + j + ' ' + color;
					var fuck:String = 'note impact ' + j + '  ' + color;

					if (frames.getByName(fuck + '0000') != null) // plz not delete this
						animation.addByPrefix(ourPrefix, fuck, 24, false);
					else
						animation.addByPrefix(ourPrefix, shit, 24, false);
				}

				animation.finishCallback = (_:String) -> kill();
			}
		}
	}

	function loadPixelAnims():Void
	{
		for (i in 0...Note.maxNote)
		{
			for (j in 1...amountOfSparePerson + 1)
			{
				var min:Int = pixelQuantity * (j - 1) + i * (Note.maxNote * amountOfSparePerson);
				var max:Int = min + pixelQuantity;

				animation.add('note' + i + '-' + j, [for (k in min...max) k], 12, false);
				animation.finishCallback = (_:String) -> kill();
			}
		}
	}
}