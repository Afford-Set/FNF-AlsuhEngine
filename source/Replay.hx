package;

import haxe.Json;
import haxe.format.JsonParser;

#if sys
import sys.io.File;
#end

using StringTools;

typedef KeyPress =
{
	var time:Float;
	var key:String;
}

typedef KeyRelease =
{
	var time:Float;
	var key:String;
}

typedef ReplayJSON =
{
	var timestamp:Date;
	var weekID:String;
	var weekName:String;
	var songID:String;
	var songName:String;
	var songDiff:Int;
	var difficulties:Array<Dynamic>;
	var songNotes:Array<Float>;
	var keyPresses:Array<KeyPress>;
	var keyReleases:Array<KeyRelease>;
	var currentModDirectory:Null<String>;
	var noteSpeed:Float;
	var isDownscroll:Bool;
}

class Replay
{
	public var path:String = '';
	public var replay:ReplayJSON;

	public function new(path:String):Void
	{
		this.path = path;

		replay = {
			songID: "tutorial",
			songName: "Tutorial", 
			songDiff: 1,
			difficulties: CoolUtil.defaultDifficultes,
			weekID: 'tutorial',
			weekName: 'Tutorial',
			noteSpeed: 1,
			isDownscroll: false,
			keyPresses: [],
			songNotes: [],
			keyReleases: [],
			currentModDirectory: Paths.currentModDirectory,
			timestamp: Date.now()
		};
	}

	public static function loadReplay(path:String):Replay
	{
		return new Replay(path).roadFromJson();
	}

	public function saveReplay(noteArray:Array<Float>):Void
	{
		#if REPLAYS_ALLOWED
		var json = {
			"songID": PlayState.SONG.songID,
			"songName": PlayState.SONG.songName,
			"weekID": PlayState.storyWeekID,
			"weekName": PlayState.storyWeekName,
			"songDiff": PlayState.lastDifficulty,
			"difficulties": CoolUtil.difficultyStuff,
			"songNotes": noteArray,
			"keyPresses": replay.keyPresses,
			"keyReleases": replay.keyReleases,
			"noteSpeed": PlayState.instance.songSpeed,
			"isDownscroll": OptionData.downScroll,
			"directory": Paths.currentModDirectory,
			"timestamp": Date.now()
		};

		var data:String = Json.stringify(json, '\t');
		var path:String = 'replays/replay-' + PlayState.SONG.songID + '-' + PlayState.lastDifficulty + '-time-' + Date.now().getTime() + '.json';
		File.saveContent(Paths.getPreloadPath(path), data);
		#end
	}

	public function roadFromJson():Replay
	{
		#if REPLAYS_ALLOWED
		try {
			var repl:ReplayJSON = cast Json.parse(File.getContent(Paths.getPreloadPath('replays/' + path)));
			replay = repl;
		}
		catch (e:Dynamic) {
			Debug.logError(e);
		}
		#end

		return this;
	}
}