package;

import Note;
import Song;
import Section;
import editors.ChartingState;

import flixel.FlxG;
import flixel.math.FlxMath;
import editors.EditorPlayState;
import flixel.util.FlxStringUtil;

using StringTools;

class ChartParser
{
	public static function parseSongChart(songData:SwagSong, ?inEditor:Bool = false):Array<Note>
	{
		var result:Array<Note> = [];

		var instance:Dynamic = inEditor ? EditorPlayState.instance : PlayState.instance;
		var noteData:Array<SwagSection> = songData.notes;

		for (section in noteData)
		{
			for (notes in section.sectionNotes)
			{
				var daStrumTime:Float = notes[0];
				var daNoteData:Int = Std.int(notes[1] % Note.maxNote);

				if (!inEditor && instance.randomNotes) {
					daNoteData = FlxG.random.int(0, Note.maxNote - 1);
				}

				var gottaHitNote:Bool = section.mustHitSection;

				if (notes[1] > 3) {
					gottaHitNote = !section.mustHitSection;
				}

				var oldNote:Note = null;

				if (result.length > 0) {
					oldNote = result[Std.int(result.length - 1)];
				}

				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, false, gottaHitNote);
				swagNote.sustainLength = notes[2];
				swagNote.gfNote = (section.gfSection && (notes[1] < 4));

				var typeShit:String = !Std.isOfType(notes[3], String) ? ChartingState.noteTypeList[notes[3]] : notes[3];
				swagNote.noteType = typeShit;
				swagNote.scrollFactor.set();
				result.push(swagNote);

				var stepCroch:Float = Conductor.stepCrochet;
				var floorSus:Int = Math.floor(swagNote.sustainLength / stepCroch);

				if (floorSus > 0)
				{
					for (susNote in 0...floorSus + 1)
					{
						oldNote = result[result.length - 1];

						var sustainNote:Note = new Note(daStrumTime + (stepCroch * susNote) + (stepCroch / FlxMath.roundDecimal(instance.songSpeed, 2)), swagNote.noteData, oldNote, true, false, gottaHitNote);
						sustainNote.gfNote = (section.gfSection && (notes[1] < 4));
						sustainNote.noteType = swagNote.noteType;
						sustainNote.scrollFactor.set();
						swagNote.tail.push(sustainNote);
						sustainNote.parent = swagNote;
						result.push(sustainNote);

						if (sustainNote.mustPress) {
							sustainNote.x += FlxG.width / 2; // general offset
						}
						else if (OptionData.middleScroll)
						{
							sustainNote.x += 310;
		
							if (daNoteData > 1) { // Up and Right
								sustainNote.x += FlxG.width / 2 + 25;
							}
						}
					}
				}

				if (swagNote.mustPress) {
					swagNote.x += FlxG.width / 2; // general offset
				}
				else if (OptionData.middleScroll)
				{
					swagNote.x += 310;

					if (daNoteData > 1) { // Up and Right
						swagNote.x += FlxG.width / 2 + 25;
					}
				}

				if (!instance.noteTypeMap.exists(swagNote.noteType)) {
					instance.noteTypeMap.set(swagNote.noteType, true);
				}
			}
		}

		return result;
	}

	@:deprecated("`ChartParser.parse()` is deprecated, use 'ChartParser.parseSongChart()' instead")
	public static function parse(songName:String, section:Int):Array<Dynamic>
	{
		Debug.logWarn("`ChartParser.parse()` is deprecated! use 'ChartParser.parseSongChart()' instead");

		var regex:EReg = ~/[ \t]*((\r\n)|\r|\n)[ \t]*", "g"/;
		var csvData:String = FlxStringUtil.imageToCSV(Paths.getFile('data/' + songName + '/' + songName + '_section' + section + '.png'));

		var lines:Array<String> = regex.split(csvData);
		var rows:Array<String> = lines.filter(function(line:String):Bool return line != '');

		csvData = csvData.replace('\n', ',');

		var heightInTiles:Int = rows.length;
		var widthInTiles:Int = 0;

		var row:Int = 0;
		var dopeArray:Array<Int> = [];

		while (row < heightInTiles)
		{
			var rowString:String = rows[row];

			if (rowString.endsWith(',')) {
				rowString = rowString.substr(0, rowString.length - 1);
			}

			var columns:Array<String> = rowString.split(',');

			if (columns.length == 0)
			{
				heightInTiles--;
				continue;
			}

			if (widthInTiles == 0) {
				widthInTiles = columns.length;
			}

			var column:Int = 0;
			var pushedInColumn:Bool = false;

			while (column < widthInTiles)
			{
				var columnString:String = columns[column];
				var curTile:Null<Int> = Std.parseInt(columnString);

				if (curTile == null) throw 'String in row $row, column $column is not a valid integer: "$columnString"';

				if (curTile == 1)
				{
					var neverGonnaGiveYouUpNeverGonnaLetYouDown:Int = (column + 1);

					if (column < 4) {
						dopeArray.push(neverGonnaGiveYouUpNeverGonnaLetYouDown);
					}
					else {
						dopeArray.push((neverGonnaGiveYouUpNeverGonnaLetYouDown * -1) + 4);
					}

					pushedInColumn = true;
				}

				column++;
			}

			if (!pushedInColumn) {
				dopeArray.push(0);
			}

			row++;
		}

		return dopeArray;
	}
}