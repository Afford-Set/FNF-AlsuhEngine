package webmlmfao;

import flixel.system.FlxSound;
#if (VIDEOS_ALLOWED && desktop)
import webm.WebmIo;
import webm.WebmEvent;
import webm.WebmIoFile;
import webm.WebmPlayer;
#end

import openfl.Lib;
import openfl.events.Event;
import openfl.display.Sprite;
import openfl.media.SoundChannel;
import openfl.media.SoundTransform;
import openfl.events.EventDispatcher;

import flixel.FlxG;

#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.util.FlxDestroyUtil;

using StringTools;

class WebmHandler implements IFlxDestroyable
{
	#if (VIDEOS_ALLOWED && desktop)
	public var canUseSound:Bool = true;

	public var webm:WebmPlayer = null;
	public var initialized:Bool = false;

	public var stopped:Bool = false;
	public var restarted:Bool = false;
	public var played:Bool = false;
	public var ended:Bool = false;
	public var paused:Bool = false;

	public var onPlay:Void->Void = null;
	public var onEnd:Void->Void = null;
	public var onStop:Void->Void = null;
	public var onRestart:Void->Void = null;

	public function new(canUseSound:Bool = true):Void
	{
		this.canUseSound = canUseSound;
	}

	public function playVideo(path:String, loop:Bool = false):Void
	{
		webm = new WebmPlayer();
		webm.fuck(new WebmIoFile(path), canUseSound);

		webm.addEventListener(WebmEvent.PLAY, function(_:Event):Void
		{
			played = true;

			if (onPlay != null) {
				onPlay();
			}
		});

		webm.addEventListener(WebmEvent.COMPLETE, function(_:Event):Void
		{
			ended = true;

			if (onEnd != null) {
				onEnd();
			}
		});

		webm.addEventListener(WebmEvent.STOP, function(_:Event):Void
		{
			stopped = true;

			if (onStop != null) {
				onStop();
			}
		});

		webm.addEventListener(WebmEvent.RESTART, function(_:Event):Void
		{
			restarted = true;

			if (onRestart != null) {
				onRestart();
			}
		});

		initialized = true;
		play();
	}

	var sound:FlxSound = null;

	public function play():Void
	{
		if (initialized && webm != null) {
			webm.play();
			sound = FlxG.sound.play(webm.sound);
		}
	}

	public function stop():Void
	{
		if (initialized && webm != null) {
			webm.stop();
			sound.destroy();
		}
	}

	public function restart():Void
	{
		if (initialized && webm != null) {
			webm.restart();
		}
	}

	public function update(_:Float):Void
	{
		if (webm != null) {
			webm.x = calc(0);
			webm.y = calc(1);
	
			webm.width = calc(2);
			webm.height = calc(3);	
		}
	}

	public function pause():Void
	{
		if(webm != null) webm.changePlaying(false);
		paused = true;
	}

	public function resume():Void
	{
		if(webm != null) webm.changePlaying(true);
		paused = false;
	}

	public function togglePause():Void
	{
		if (paused) {
			resume();
		}
		else {
			pause();
		}
	}

	public function clearPause():Void
	{
		paused = false;
		if(webm != null) webm.removePause();
	}
	#else
	public var webm:Sprite;

	public function new():Void {
		Debug.logWarn("THIS IS ANDROID! or some shit...");
	}
	#end

	public function destroy():Void
	{
		#if desktop
		@:privateAccess
		webm.dispose();
		#end
	}

	public static function calc(ind:Int):Float
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		var width:Float = 1280;
		var height:Float = 720;

		var ratioX:Float = height / width;
		var ratioY:Float = width / height;

		var appliedWidth:Float = stageHeight * ratioY;
		var appliedHeight:Float = stageWidth * ratioX;

		var remainingX:Float = stageWidth - appliedWidth;
		var remainingY:Float = stageHeight - appliedHeight;

		remainingX = remainingX / 2;
		remainingY = remainingY / 2;

		appliedWidth = Std.int(appliedWidth);
		appliedHeight = Std.int(appliedHeight);

		if (appliedHeight > stageHeight)
		{
			remainingY = 0;
			appliedHeight = stageHeight;
		}

		if (appliedWidth > stageWidth)
		{
			remainingX = 0;
			appliedWidth = stageWidth;
		}

		switch (ind)
		{
			case 0:
				return remainingX;
			case 1:
				return remainingY;
			case 2:
				return appliedWidth;
			case 3:
				return appliedHeight;
		}

		return -1;
	}
}