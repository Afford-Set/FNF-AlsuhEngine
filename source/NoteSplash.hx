package;

import flixel.FlxG;
import flixel.FlxSprite;
import shaderslmfao.ColorSwap;

using StringTools;

class NoteSplash extends FlxSprite
{
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
	private var colors:Array<String> = ['purple', 'blue', 'green', 'red'];

	public function setupNoteSplash(x:Float, y:Float, note:Int = 0, texture:String = null, mustPress:Bool = true, hueColor:Float = 0, satColor:Float = 0, brtColor:Float = 0):Void
	{
		setPosition(x - Note.swagWidth * 0.95, y - Note.swagWidth);
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

		if (textureLoaded != texture) {
			loadAnims(texture);
		}

		colorSwap.hue = hueColor;
		colorSwap.saturation = satColor;
		colorSwap.brightness = brtColor;

		var animNum:Int = FlxG.random.int(1, 2);

		if (isPsychArray[note][animNum]) {
			offset.set(-10, 0);
		}
		else {
			offset.set(-25, -15);
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

		for (i in 0...colors.length)
		{
			for (j in 1...3)
			{
				var color:String = colors[i];
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

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (animation.curAnim != null) if (animation.curAnim.finished) kill();
	}
}