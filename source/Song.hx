package;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import haxe.Json;
import lime.utils.Assets;
import Section.SwagSection;
import haxe.format.JsonParser;

using StringTools;

typedef SwagSong =
{
	var song:String;
	var songID:String;
	var songName:String;

	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;

	var needsVoices:Bool;

	var bpm:Float;
	var speed:Float;

	var player1:String;
	var player2:String;
	var player3:String;
	var gfVersion:String;
	var stage:String;

	var arrowSkin:String;
	var arrowSkin2:String;
	var splashSkin:String;
	var splashSkin2:String;
}

class Song
{
	private static function onLoadJson(songJson:SwagSong):Void
	{
		if (songJson.songID == null) {
			songJson.songID = Paths.formatToSongPath(songJson.song);
		}

		if (songJson.songName == null) {
			songJson.songName = CoolUtil.formatToName(songJson.song);
		}

		if (songJson.arrowSkin == null) {
			songJson.arrowSkin = '';
		}

		if (songJson.arrowSkin2 == null) {
			songJson.arrowSkin2 = songJson.arrowSkin;
		}

		if (songJson.splashSkin == null) {
			songJson.splashSkin = 'noteSplashes';
		}

		if (songJson.splashSkin2 == null) {
			songJson.splashSkin2 = songJson.splashSkin;
		}

		if (songJson.gfVersion == null) // from Psych Charts
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		songJson.songID = songJson.songID.toLowerCase();

		if (songJson.events == null) // from Psych Charts
		{
			songJson.events = [];

			for (secNum in 0...songJson.notes.length)
			{
				var sec:SwagSection = songJson.notes[secNum];

				var i:Int = 0;
				var notes:Array<Dynamic> = sec.sectionNotes;
				var len:Int = notes.length;

				while (i < len)
				{
					var note:Array<Dynamic> = notes[i];

					if (note[1] < 0)
					{
						songJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
						notes.remove(note);

						len = notes.length;
					}
					else {
						i++;
					}
				}
			}
		}
	}

	public static function loadFromJson(jsonInput:String, ?folder:Null<String> = null):Null<SwagSong>
	{
		var path:String = Paths.getJson('data/${Paths.formatToSongPath(folder)}/${Paths.formatToSongPath(jsonInput)}');
		var rawJson:String = Paths.getTextFromFile(path);

		while (!rawJson.endsWith('}')) {
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		var songJson:SwagSong = parseJSONshit(rawJson);

		if (songJson != null)
		{
			if (jsonInput != 'events') {
				StageData.loadDirectory(songJson);
			}
	
			onLoadJson(songJson);
			return songJson;
		}

		return null;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		if (rawJson != null)
		{
			try {
				return cast Json.parse(rawJson).song;
			}
			catch (e:Dynamic) {
				Debug.logError(e);
			}
		}

		return null;
	}
}