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
	public var note:Int = 0;

	private var idleAnim:String;
	private var textureLoaded:String = null;

	public function new(x:Float = 0, y:Float = 0, ?note:Int = 0):Void
	{
		super(x, y);

		this.note = note;

		var skin:String = 'noteSplashes';
		if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) skin = PlayState.SONG.splashSkin;

		loadAnims(skin);
		
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		setupNoteSplash(x, y, note);

		antialiasing = OptionData.globalAntialiasing;
	}

	private var isPsychArray:Array<Array<Bool>> =
	[
		[false, false],
		[false, false],
		[false, false],
		[false, false]
	];

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = null, mustPress:Bool = true, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0):Void
	{
		if (PlayState.isPixelStage) {
			setPosition(x + 30, (y + Note.swagWidth) / 2);
		}
		else {
			setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
		}

		alpha = OptionData.splashOpacity;

		this.note = note;

		if (texture == null)
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

		if (textureLoaded != texture)
		{
			if (PlayState.isPixelStage) {
				loadPixelAnims(texture);
			}
			else {
				loadAnims(texture);
			}
		}

		colorSwap.hue = hueColor;
		colorSwap.saturation = satColor;
		colorSwap.brightness = brtColor;

		var animNum:Int = FlxG.random.int(1, 2);

		if (isPsychArray[note][animNum]) {
			offset.set(-10, 0);
		}
		else
		{
			if (PlayState.isPixelStage) {
				offset.set(10, 10);
			}
			else {
				offset.set(-25, -15);
			}
		}

		var ourPrefix:String = 'note$note-$animNum';
		animation.play(ourPrefix, true);

		if (animation.curAnim != null) {
			animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
		}
	}

	function loadAnims(skin:String):Void
	{
		if (Paths.fileExists('images/' + skin + '.png', IMAGE)) {
			frames = Paths.getSparrowAtlas(skin);
		}
		else if (Paths.fileExists('images/pixelUI/' + skin + '.png', IMAGE)) {
			frames = Paths.getSparrowAtlas('pixelUI/' + skin);
		}
		else {
			frames = Paths.getSparrowAtlas('notes/' + skin);
		}

		scale.set(1, 1);

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

				animation.play(ourPrefix, true); // does precaches
			}
		}
	}

	function loadPixelAnims(skin:String):Void
	{
		var graphic:FlxGraphic = Paths.getImage('notes/' + skin);

		if (Paths.fileExists('images/' + skin + '.png', IMAGE)) {
			graphic = Paths.getImage(skin);
		}
		else if (Paths.fileExists('images/pixelUI/' + skin + '.png', IMAGE)) {
			graphic = Paths.getImage('pixelUI/' + skin);
		}
		else if (Paths.fileExists('images/notes/pixel/' + skin + '.png', IMAGE)) {
			graphic = Paths.getImage('notes/pixel/' + skin);
		}

		loadGraphic(graphic);

		width = width / 8;
		height = height / Note.maxNote;

		loadGraphic(graphic, true, Math.floor(width), Math.floor(height));

		antialiasing = false;

		setGraphicSize(Std.int(width * PlayState.daPixelZoom));

		for (i in 0...Note.maxNote)
		{
			for (j in 1...amountOfSparePerson + 1) // I've been messing with this shit for a day already
			{
				var quantity:Int = 4;

				var min:Int = quantity * (j - 1) + i * (Note.maxNote * amountOfSparePerson);
				var max:Int = min + quantity;
		
				animation.add('note' + i + '-' + j, [for (k in min...max) k], 12, false);
			}
		}
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (animation.curAnim != null) if (animation.curAnim.finished) kill();
	}
}