package;

import flixel.FlxG;
import flixel.FlxBasic;
import flixel.util.typeLimit.OneOfTwo;

#if VIDEOS_ALLOWED
#if desktop
#if (hxCodec >= "2.6.1")
import hxcodec.VideoSprite as MP4Sprite;
import hxcodec.VideoHandler;
#elseif (hxCodec == "2.6.0")
import VideoSprite as MP4Sprite;
import VideoHandler;
#else 
import vlc.MP4Sprite;
import vlc.MP4Handler as VideoHandler;
#end
import webm.WebmPlayer;
import webmlmfao.WebmSprite;
import webmlmfao.WebmHandler;
#else
import openfl.media.Video;
import openfl.net.NetStream;
import openfl.net.NetConnection;
import openfl.events.NetStatusEvent;
#end
#end

using StringTools;

#if VIDEOS_ALLOWED
#if desktop
typedef VideoSprite = OneOfTwo<MP4Sprite, WebmSprite>;
#end

class FlxVideo extends FlxBasic
{
	#if web
	var netStream:NetStream;
	#end

	public var finishCallback:Void->Void;

	/*#if desktop
	var webm:WebmHandler = null;
	#end*/

	/**
	 * Doesn't actually interact with Flixel shit, only just a pleasant to use class    
	 */
	public function new(vidSrc:String):Void
	{
		super();

		var newPath:String = Paths.getVideo(vidSrc);

		if (newPath.contains(':')) {
			newPath = newPath.substring(newPath.indexOf(':') + 1, newPath.length);
		}

		#if desktop
		// extension webm is no longer needed
		// why? because volume for SampleDataEvent is very hardy for me
		/*if (newPath.endsWith('.webm'))
		{
			webm = new WebmHandler();
			webm.playVideo(newPath);

			var bitmap:WebmPlayer = webm.webm; // lol
			webm.onEnd = function():Void
			{
				FlxG.removeChild(bitmap);
				finishVideo();
			}
			FlxG.addChildBelowMouse(bitmap);
		}
		else
		{*/
			var video:VideoHandler=new VideoHandler();
			video.playVideo(newPath);
			video.finishCallback = finishVideo;
			#if (hxCodec >= "2.6.0")
			video.canSkip = false;
			#end
		//}
		#elseif web
		var video:Video = new Video();
		video.x = 0;
		video.y = 0;
		FlxG.addChildBelowMouse(video);

		var netConnection:NetConnection = new NetConnection();
		netConnection.connect(null);

		netStream = new NetStream(netConnection);
		netStream.client = {
			onMetaData: function():Void {
				video.attachNetStream(netStream);
				video.width = FlxG.width;
				video.height = FlxG.height;
			}
		};

		netConnection.addEventListener(NetStatusEvent.NET_STATUS, function(event:NetStatusEvent):Void
		{
			if (event.info.code == 'NetStream.Play.Complete')
			{
				netStream.dispose();
				FlxG.removeChild(video);

				finishVideo();
			}
		});

		netStream.play(newPath);
		updateVolume();
		#end
	}

	override function update(elapsed:Float):Void
	{
		#if web
		updateVolume();
		/*#elseif desktop
		if (webm != null) {
			webm.update(elapsed);
		}*/
		#end

		super.update(elapsed);
	}

	#if web
	function updateVolume():Void
	{
		@:privateAccess
		if (netStream != null && netStream.__video != null) {
			netStream.__video.volume = FlxG.sound.volume;
		}
	}
	#end

	public function finishVideo():Void
	{
		if (finishCallback != null) {
			finishCallback();
		}

		kill();
	}
}
#end