package;

import haxe.io.Path;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.util.FlxSave;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;

using StringTools;

class CoolUtil
{
	//[Difficulty id, Difficulty custom name, Chart file suffix]
	public static var defaultDifficultes(default, never):Array<Dynamic> = [
		['easy',	'Easy',		'-easy'],
		['normal',	'Normal',	''],
		['hard',	'Hard',		'-hard']
	];
	public static var defaultDifficulty(default, never):String = 'Normal';
	public static var difficultyStuff:Array<Dynamic> = [];
	public static function loadDifficultiesFromLevel(level:Dynamic):Void {
		var difficulties:Dynamic = level.difficulties;
		if(difficulties != null && difficulties.length > 0) {
			if(Std.isOfType(difficulties, String)) {
				var diffStr:String = difficulties;
				if(diffStr != null && diffStr.length > 0) {
					var diffs:Array<String> = diffStr.trim().split(',');
					var i:Int = diffs.length - 1;
					while(i > 0) {
						if(diffs[i] != null) {
							diffs[i] = diffs[i].trim();
							if(diffs[i].length < 1) diffs.remove(diffs[i]);
						}
						--i;
					}
					if(diffs.length > 0 && diffs[0].length > 0) {
						difficultyStuff=[];
						for(i in diffs) {
							difficultyStuff.push([
								Paths.formatToSongPath(i),
								formatToName(i),
								getDifficultyFilePath(i)
							]);
						}
					}
				}
			} else {
				var diffs:Array<Dynamic> = difficulties;
				difficultyStuff = diffs;
			}
		} else {
			resetDifficulties();
		}
	}
	public static function resetDifficulties():Void {
		difficultyStuff = defaultDifficultes.copy();
	}
	public static function copyDifficultiesFrom(diffs:Array<Dynamic>):Void {
		difficultyStuff = diffs.copy();
	}

	public static function getDifficultyFilePath(diff:String = null):String
	{
		if (diff == null || diff.length < 1) diff = defaultDifficulty;
		var fileSuffix:String = diff;

		if (fileSuffix != defaultDifficulty) {
			fileSuffix = '-' + fileSuffix;
		}
		else {
			fileSuffix = '';
		}

		return Paths.formatToSongPath(fileSuffix);
	}

	public static function difficultyString(last:Bool = false):String
	{
		return difficultyStuff[last ? PlayState.lastDifficulty : PlayState.storyDifficulty][1].toUpperCase();
	}

	public static function getDifficultyIndex(diff:String):Int
	{
		for (i in 0...difficultyStuff.length)
		{
			if (diff == difficultyStuff[i][0]) {
				return i;
			}
		}

		return -1;
	}

	public static function difficultyExists(diff:String):Bool
	{
		for (i in difficultyStuff) {
			if (diff == i[0]) return true;
		}

		return false;
	}

	public static function fromSuffixToID(suffix:String):String
	{
		return suffix.substring(1, suffix.length);
	}

	public static function boundSelection(selection:Int, max:Int):Int
	{
		if (selection < 0) {
			return max - 1;
		}

		if (selection >= max) {
			return 0;
		}

		return selection;
	}

	public static function quantize(f:Float, snap:Float):Float
	{
		return (Math.fround(f * snap) / snap);
	}

	public static function formatSong(song:String, diff:String):String
	{
		var song:String = Paths.formatToSongPath(song);
		var diff:String = Paths.formatToSongPath(diff);

		if (diff != null && diff.length > 0) {
			return song + '-' + diff;
		}

		return song;
	}

	public static function formatToName(name:String):String
	{
		var splitter:Array<String> = name.trim().split('-');

		for (i in 0...splitter.length) {
			splitter[i] = '' + splitter[i].charAt(0).toUpperCase().trim() + splitter[i].substr(1).toLowerCase().trim();
		}

		var splitter:Array<String> = splitter.join(' ').trim().split(' ');

		for (i in 0...splitter.length) {
			splitter[i] = '' + splitter[i].charAt(0).toUpperCase().trim() + splitter[i].substr(1).toLowerCase().trim();
		}

		return splitter.join(' ');
	}

	public static function getKeyName(key:FlxKey):String
	{
		switch (key)
		{
			case BACKSPACE: return "BckSpc";
			case CONTROL: return "Ctrl";
			case ALT: return "Alt";
			case CAPSLOCK: return "Caps";
			case PAGEUP: return "PgUp";
			case PAGEDOWN: return "PgDown";
			case ZERO: return "0";
			case ONE: return "1";
			case TWO: return "2";
			case THREE: return "3";
			case FOUR: return "4";
			case FIVE: return "5";
			case SIX: return "6";
			case SEVEN: return "7";
			case EIGHT: return "8";
			case NINE: return "9";
			case NUMPADZERO: return "#0";
			case NUMPADONE: return "#1";
			case NUMPADTWO: return "#2";
			case NUMPADTHREE: return "#3";
			case NUMPADFOUR: return "#4";
			case NUMPADFIVE: return "#5";
			case NUMPADSIX: return "#6";
			case NUMPADSEVEN: return "#7";
			case NUMPADEIGHT: return "#8";
			case NUMPADNINE: return "#9";
			case NUMPADMULTIPLY: return "#*";
			case NUMPADPLUS: return "#+";
			case NUMPADMINUS: return "#-";
			case NUMPADPERIOD: return "#.";
			case SEMICOLON: return ";";
			case COMMA: return ",";
			case PERIOD: return ".";
			case GRAVEACCENT: return "`";
			case LBRACKET: return "[";
			case RBRACKET: return "]";
			case QUOTE: return "'";
			case PRINTSCREEN: return "PrtScrn";
			case NONE: return '---';
			default:
		}

		var label:String = '' + key;

		if (label.toLowerCase() == 'null') {
			return '---';
		}

		return '' + label.charAt(0).toUpperCase() + label.substr(1).toLowerCase();
	}

	public static function lerpColor(a:FlxColor, b:FlxColor, ratio:Float):FlxColor
	{
		return FlxColor.fromRGBFloat(
			FlxMath.lerp(a.red, b.red, ratio),
			FlxMath.lerp(a.green, b.green, ratio),
			FlxMath.lerp(a.blue, b.blue, ratio),
			FlxMath.lerp(a.alpha, b.alpha, ratio)
		);
	}

	public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	public static function roundDecimal(number:Float, precision:Int = 0):Float // copy of field `FlxMath.roundDecimal` you will ask why? answer at the bottom)
	{
		if (Math.isNaN(number)) number = 0;

		if (precision < 1) { // that's the because the `FlxMath.roundDecimal` callback does not have this, and the `CoolUtil.floorDecimal` callback already has this
			return Math.round(number);
		}

		return FlxMath.roundDecimal(number, precision);
	}

	public static function floorDecimal(number:Float, precision:Int = 0):Float
	{
		if (Math.isNaN(number)) number = 0;

		if (precision < 1) {
			return Math.floor(number);
		}

		var tempMult:Float = 1;

		for (i in 0...precision) {
			tempMult *= 10;
		}

		return Math.floor(number * tempMult) / tempMult;
	}

	public static function coolTextFile(path:String, ?ignoreWarnMsg:Bool = false, ?absolute:Bool = false):Array<String>
	{
		if (Paths.fileExists(path, TEXT, absolute)) {
			return listFromString(Paths.getTextFromFile(path));
		}

		if (!ignoreWarnMsg) {
			Debug.logWarn('Path "$path" not found!');
		}

		return [];
	}

	public static function listFromString(string:String):Array<String>
	{
		return [for (i in string.trim().split('\n')) i = i.trim()];
	}

	public static function getColorFromString(?str:Null<String> = null):FlxColor
	{
		var string:String = str;

		if (!string.startsWith('0x')) {
			string = '0xFF' + str;
		}

		return FlxColor.fromString(string);
	}

	public static function dominantColor(sprite:FlxSprite):FlxColor
	{
		var countByColor:Map<Int, Int> = new Map<Int, Int>();

		for (col in 0...sprite.frameWidth)
		{
			for (row in 0...sprite.frameHeight)
			{
				var colorOfThisPixel:Int = sprite.pixels.getPixel32(col, row);

				if (colorOfThisPixel != 0)
				{
					if (countByColor.exists(colorOfThisPixel)) {
						countByColor[colorOfThisPixel] = countByColor[colorOfThisPixel] + 1;
					}
					else if (countByColor[colorOfThisPixel] != 13520687 - (2 * 13520687)) {
						countByColor[colorOfThisPixel] = 1;
					}
				}
			}
		}

		var maxCount:Int = 0;
		var maxKey:Int = 0; // after the loop this will store the max color

		countByColor[FlxColor.BLACK] = 0;

		for (key in countByColor.keys())
		{
			if (countByColor[key] >= maxCount)
			{
				maxCount = countByColor[key];
				maxKey = key;
			}
		}

		return FlxColor.fromInt(maxKey);
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		return [for (i in min...max) i];
	}

	public static function browserLoad(site:String):Void
	{
		#if linux
		Sys.command('/usr/bin/xdg-open', [site]);
		#else
		FlxG.openURL(site);
		#end
	}

	/** Quick Function to Fix Save Files for Flixel 5
		if you are making a mod, you are gonna wanna change "Afford-Set" to something else
		so Base Alsuh saves won't conflict with yours
		@BeastlyGabi
	**/
	public static function getSavePath(folder:String = 'Afford-Set'):String
	{
		@:privateAccess
		return #if (flixel < "5.0.0") folder #else FlxG.stage.application.meta.get('company')
			+ '/'
			+ FlxSave.validate(FlxG.stage.application.meta.get('file')) #end;
	}

	public static function precacheImage(image:String, ?library:String = null):Void
	{
		Paths.getImage(image, library);
	}

	public static function precacheSound(sound:String, ?library:String = null):Void
	{
		Paths.getSound(sound, library);
	}

	public static function precacheMusic(sound:String, ?library:String = null):Void
	{
		Paths.getMusic(sound, library);
	}

	#if sys
	public static function convPathShit(path:String):String
	{
		return Path.normalize(Sys.getCwd() + path) #if windows .replace('/', '\\') #end;
	}
	#end
}