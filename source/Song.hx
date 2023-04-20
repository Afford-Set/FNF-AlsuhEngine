package;

import haxe.Json;

import Section;

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

private typedef SwagEvents =
{
	var notes:Array<SwagSection>;
	var events:Array<Dynamic>;
}

class Song
{
	private static function onLoadJson(songJson:SwagSong):SwagSong // Convert old charts to newest format
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

		if (songJson.gfVersion == null)
		{
			songJson.gfVersion = songJson.player3;
			songJson.player3 = null;
		}

		if (songJson.events == null)
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

		return songJson;
	}

	public static function loadFromJson(jsonInput:String, ?folder:Null<String> = null):Null<SwagSong>
	{
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var formattedSong:String = Paths.formatToSongPath(jsonInput);

		var rawJson:String = Paths.getTextFromFile('data/$formattedFolder/$formattedSong.json').trim();

		while (!rawJson.endsWith('}')) {
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		var songJson:SwagSong = null;

		try {
			songJson = parseJSONshit(rawJson);
		}
		catch (e:Dynamic) {
			Debug.logError('Cannot load level file "' + 'data/$formattedFolder/$formattedSong.json' + '" because of: ' + e);
		}

		if (songJson != null)
		{
			if (jsonInput != 'events') {
				StageData.loadDirectory(songJson);
			}

			return onLoadJson(songJson);
		}

		return null;
	}

	public static function getEvents(?folder:Null<String> = null):Array<Dynamic>
	{
		var formattedFolder:String = Paths.formatToSongPath(folder);
		var rawJson:String = Paths.getTextFromFile('data/$formattedFolder/events.json').trim();

		while (!rawJson.endsWith('}')) {
			rawJson = rawJson.substr(0, rawJson.length - 1);
		}

		var eventsJson:SwagEvents = null;

		try {
			eventsJson = cast Json.parse(rawJson).song;
		}
		catch (e:Dynamic) {
			Debug.logError('Cannot load events because of: ' + e);
		}

		if (eventsJson != null)
		{
			if (eventsJson.events == null)
			{
				eventsJson.events = [];
	
				for (secNum in 0...eventsJson.notes.length)
				{
					var sec:SwagSection = eventsJson.notes[secNum];
	
					var i:Int = 0;
					var notes:Array<Dynamic> = sec.sectionNotes;
					var len:Int = notes.length;
	
					while (i < len)
					{
						var note:Array<Dynamic> = notes[i];
	
						if (note[1] < 0)
						{
							eventsJson.events.push([note[0], [[note[2], note[3], note[4]]]]);
							notes.remove(note);
	
							len = notes.length;
						}
						else {
							i++;
						}
					}
				}
			}

			return eventsJson.events;
		}

		return null;
	}

	public static function parseJSONshit(rawJson:String):SwagSong
	{
		return cast Json.parse(rawJson).song;
	}
}