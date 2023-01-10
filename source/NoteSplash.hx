package;

import flixel.FlxG;
import flixel.FlxSprite;
import shaders.ColorSwap;

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

		offset.set(-10, -10);

		var animNum:Int = FlxG.random.int(1, 2);
		animation.play('note' + note + '-' + animNum, true);
		animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
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

		for (i in 1...3)
		{
			animation.addByPrefix("note0-" + i, "note impact " + i + " purple", 24, false);
			animation.addByPrefix("note1-" + i, "note impact " + i + " blue", 24, false);
			animation.addByPrefix("note2-" + i, "note impact " + i + " green", 24, false);
			animation.addByPrefix("note3-" + i, "note impact " + i + " red", 24, false);
		}
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (animation.curAnim != null) if (animation.curAnim.finished) kill();
	}
}