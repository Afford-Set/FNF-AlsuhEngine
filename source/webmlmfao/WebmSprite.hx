package webmlmfao;

import webm.WebmPlayer;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;

using StringTools;

class WebmSprite extends FlxSprite
{
	public var handler:WebmHandler = null;

	public var canvasWidth:Null<Int> = null;
	public var canvasHeight:Null<Int> = null;

	public var openingCallback:Void->Void = null;
	public var graphicLoadedCallback:Void->Void = null;
	public var finishCallback:Void->Void = null;

	public function new(x:Float = 0, y:Float = 0, ?width:Null<Int> = null, ?height:Null<Int> = null):Void
	{
		super(x, y);

		canvasWidth = width;
		canvasHeight = height;

		makeGraphic(1, 1, FlxColor.TRANSPARENT);

		handler = new WebmHandler();
		handler.onPlay = function():Void
		{
			if (openingCallback != null) {
				openingCallback();
			}
		}

		handler.onEnd = function():Void
		{
			kill();

			if (finishCallback != null) {
				finishCallback();
			}
		}
	}

	public function playVideo(path:String, ?loop:Bool = false):Void
	{
		handler.playVideo(path, loop);
	}

	var oneTime:Bool = false;

	override function update(elapsed:Float):Void
	{
		if (handler != null)
		{
			handler.update(elapsed);

			var bitmap:WebmPlayer = handler.webm;

			if (bitmap.bitmapData != null && handler.played && !handler.ended && !handler.stopped && !oneTime)
			{
				var graphic:FlxGraphic = FlxG.bitmap.add(bitmap.bitmapData, false);

				if (graphic.imageFrame != null && graphic.imageFrame.frame != null)
				{
					loadGraphic(graphic);

					if (canvasWidth != null && canvasHeight != null)
					{
						setGraphicSize(canvasWidth, canvasHeight);
						updateHitbox();
					}

					if (graphicLoadedCallback != null) {
						graphicLoadedCallback();
					}

					oneTime = true;
				}
			}
		}

		super.update(elapsed);
	}

	override function destroy():Void
	{
		super.destroy();

		var bitmap:WebmPlayer = handler.webm;

		if (handler != null && bitmap != null)
		{
			@:privateAccess
			bitmap.dispose();
			bitmap = null;
		}

		handler.destroy();
		handler = null;
	}
}