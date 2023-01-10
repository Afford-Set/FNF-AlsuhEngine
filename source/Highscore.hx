package;

import flixel.util.FlxSave;

class Highscore
{
	private static var weekScores:Map<String, Int> = #if (haxe >= "4.0.0") new Map() #else new Map<String, Int>() #end;
	private static var songScores:Map<String, Int> = #if (haxe >= "4.0.0") new Map() #else new Map<String, Int>() #end;
	private static var songAccuracy:Map<String, Float> = #if (haxe >= "4.0.0") new Map() #else new Map<String, Float>() #end;

	public static function resetSong(song:String):Void
	{
		setScore(song, 0);
		setAccuracy(song, 0);
	}

	public static function resetWeek(week:String):Void
	{
		setWeekScore(week, 0);
	}

	public static function saveWeekScore(week:String, score:Int = 0):Void
	{
		if (weekScores.exists(week))
		{
			if (weekScores.get(week) < score) {
				setWeekScore(week, score);
			}
		}
		else {
			setWeekScore(week, score);
		}
	}

	public static function getWeekScore(week:String):Int
	{
		if (!weekScores.exists(week)) {
			weekScores.set(week, 0);
		}

		return weekScores.get(week);
	}

	public static function setWeekScore(week:String, score:Int = 0):Void
	{
		weekScores.set(week, score);

		var save:FlxSave = new FlxSave();
		save.bind('highscore_v2', CoolUtil.getSavePath());
		
		save.data.weekScores = weekScores;
		save.flush();
	}

	public static function saveScore(daSong:String, score:Int = 0, accuracy:Float = 0):Void
	{
		if (songScores.exists(daSong))
		{
			if (songScores.get(daSong) < score)
			{
				setScore(daSong, score);

				if (accuracy >= 0) setAccuracy(daSong, accuracy);
			}
		}
		else
		{
			setScore(daSong, score);

			if (accuracy >= 0) setAccuracy(daSong, accuracy);
		}
	}

	public static function getScore(daSong:String):Int
	{
		if (!songScores.exists(daSong)) {
			songScores.set(daSong, 0);
		}

		return songScores.get(daSong);
	}

	private static function setScore(daSong:String, score:Int = 0):Void
	{
		songScores.set(daSong, score);

		var save:FlxSave = new FlxSave();
		save.bind('highscore_v2', CoolUtil.getSavePath());

		save.data.songScores = songScores;
		save.flush();
	}

	public static function getAccuracy(daSong:String):Float 
	{
		if (!songAccuracy.exists(daSong)) {
			songAccuracy.set(daSong, 0);
		}

		return songAccuracy.get(daSong);
	}

	private static function setAccuracy(daSong:String, accuracy:Float):Void
	{
		songAccuracy.set(daSong, accuracy);

		var save:FlxSave = new FlxSave();
		save.bind('highscore_v2', CoolUtil.getSavePath());

		save.data.songAccuracy = songAccuracy;
		save.flush();
	}

	public static function load():Void 
	{
		var save:FlxSave = new FlxSave();
		save.bind('highscore_v2', CoolUtil.getSavePath());

		if (save.data.weekScores != null) {
			weekScores = save.data.weekScores;
		}

		if (save.data.songScores != null) {
			songScores = save.data.songScores;
		}

		if (save.data.songAccuracy != null) {
			songAccuracy = save.data.songAccuracy;
		}
	}

	public static function scoreText(deaths:Int, accuracy:Float, rating:String, comboRank:String, health:Float, misses:Int, score:Int):String
	{
		return 'Deaths: ' + deaths + ' | Accuracy: ' + CoolUtil.floorDecimal(accuracy, 2) + '% | Rating: ' + rating +
			(rating != 'N/A' ? ' (' + comboRank + ')' : '') + ' | Health: ' + Math.floor(health * 50) + '% | Combo Breaks: ' + misses + ' | Score: ' + score;
	}
}