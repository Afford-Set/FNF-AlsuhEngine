package;

import flixel.FlxG;
import flixel.FlxSprite;
import shaders.ColorSwap;
import flixel.graphics.FlxGraphic;

using StringTools;

class StrumNote extends FlxSprite
{
	public var colorSwap:ColorSwap;

	public var noteData:Int = 0;
	public var resetAnim:Float = 0;

	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;

	public var player:Int;

	public function new(x:Float, y:Float, leData:Int, player:Int):Void
	{
		colorSwap = new ColorSwap();
		shader = colorSwap.shader;

		noteData = leData;

		this.player = player;
		this.noteData = leData;

		super(x, y);

		var skin:String = 'NOTE_assets';

		if (player == 1)
		{
			if (PlayState.SONG.arrowSkin != null && PlayState.SONG.arrowSkin.length > 1) {
				skin = PlayState.SONG.arrowSkin;
			}
		}
		else
		{
			if (PlayState.SONG.arrowSkin2 != null && PlayState.SONG.arrowSkin2.length > 1) {
				skin = PlayState.SONG.arrowSkin2;
			}
		}

		if (PlayState.isPixelStage)
		{
			var ourGraphic:FlxGraphic = null;

			if (Paths.fileExists('images/' + skin + '.png', IMAGE)) {
				ourGraphic = Paths.getImage(skin);
			}
			else if (Paths.fileExists('images/pixelUI/' + skin + '.png', IMAGE)) {
				ourGraphic = Paths.getImage('pixelUI/' + skin);
			}
			else if (Paths.fileExists('images/notes/pixel/' + skin + '.png', IMAGE)) {
				ourGraphic = Paths.getImage('notes/pixel/' + skin);
			}
			else {
				ourGraphic = Paths.getImage('notes/' + skin);
			}

			loadGraphic(ourGraphic);

			width = width / 4;
			height = height / 5;

			loadGraphic(ourGraphic, true, Math.floor(width), Math.floor(height));
		
			animation.add('green', [6]);
			animation.add('red', [7]);
			animation.add('blue', [5]);
			animation.add('purple', [4]);

			antialiasing = false;

			setGraphicSize(Std.int(width * PlayState.daPixelZoom));

			switch (Math.abs(leData))
			{
				case 0:
				{
					animation.add('static', [0]);
					animation.add('pressed', [4, 8], 12, false);
					animation.add('confirm', [12, 16], 24, false);
				}
				case 1:
				{
					animation.add('static', [1]);
					animation.add('pressed', [5, 9], 12, false);
					animation.add('confirm', [13, 17], 24, false);
				}
				case 2:
				{
					animation.add('static', [2]);
					animation.add('pressed', [6, 10], 12, false);
					animation.add('confirm', [14, 18], 12, false);
				}
				case 3:
				{
					animation.add('static', [3]);
					animation.add('pressed', [7, 11], 12, false);
					animation.add('confirm', [15, 19], 24, false);
				}
			}
		}
		else
		{
			if (Paths.fileExists('images/' + skin + '.png', IMAGE)) {
				frames = Paths.getSparrowAtlas(skin);
			}
			else {
				frames = Paths.getSparrowAtlas('notes/' + skin);
			}

			animation.addByPrefix('green', 'arrowUP');
			animation.addByPrefix('blue', 'arrowDOWN');
			animation.addByPrefix('purple', 'arrowLEFT');
			animation.addByPrefix('red', 'arrowRIGHT');

			antialiasing = OptionData.globalAntialiasing;

			setGraphicSize(Std.int(width * 0.7));

			switch (Math.abs(leData))
			{
				case 0:
				{
					animation.addByPrefix('static', 'arrowLEFT');
					animation.addByPrefix('pressed', 'left press', 24, false);
					animation.addByPrefix('confirm', 'left confirm', 24, false);
				}
				case 1:
				{
					animation.addByPrefix('static', 'arrowDOWN');
					animation.addByPrefix('pressed', 'down press', 24, false);
					animation.addByPrefix('confirm', 'down confirm', 24, false);
				}
				case 2:
				{
					animation.addByPrefix('static', 'arrowUP');
					animation.addByPrefix('pressed', 'up press', 24, false);
					animation.addByPrefix('confirm', 'up confirm', 24, false);
				}
				case 3:
				{
					animation.addByPrefix('static', 'arrowRIGHT');
					animation.addByPrefix('pressed', 'right press', 24, false);
					animation.addByPrefix('confirm', 'right confirm', 24, false);
				}
			}
		}

		updateHitbox();
		scrollFactor.set();
	}

	public function postAddedToGroup():Void
	{
		playAnim('static');

		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width / 2) * player);

		ID = noteData;
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (resetAnim > 0)
		{
			resetAnim -= elapsed;

			if (resetAnim <= 0)
			{
				playAnim('static');
				resetAnim = 0;
			}
		}

		if (animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
			centerOrigin();
		}
	}

	public function playAnim(anim:String, ?force:Bool = false, ?finishCallback:Null<(name:String)->Void>):Void
	{
		animation.play(anim, force);

		if (finishCallback != null) {
			animation.finishCallback = finishCallback;
		}

		centerOffsets();
		centerOrigin();

		if (animation.curAnim == null || animation.curAnim.name == 'static') 
		{
			colorSwap.hue = 0;
			colorSwap.saturation = 0;
			colorSwap.brightness = 0;
		}
		else
		{
			if (noteData > -1 && noteData < OptionData.arrowHSV.length)
			{
				colorSwap.hue = OptionData.arrowHSV[noteData][0] / 360;
				colorSwap.saturation = OptionData.arrowHSV[noteData][1] / 100;
				colorSwap.brightness = OptionData.arrowHSV[noteData][2] / 100;
			}

			if (animation.curAnim.name == 'confirm' && !PlayState.isPixelStage) {
				centerOrigin();
			}
		}
	}

	function updateConfirmOffset():Void // TO DO: Find a calc to make the offset work fine on other angles
	{
		centerOffsets();

		offset.x -= 13;
		offset.y -= 13;
	}
}