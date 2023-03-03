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
	public static function getDifficultyIndex(diff:String, ?difficulties:Array<Dynamic> = null):Int
	{
		if (difficulties == null) {
			difficulties = PlayState.difficulties;
		}

		return difficulties[1].indexOf(diff);
	}

	public static function getDifficultyName(diff:String, ?isSuffix:Null<Bool> = false, ?difficulties:Array<Dynamic> = null):String
	{
		if (difficulties == null) {
			difficulties = PlayState.difficulties;
		}

		return difficulties[0][difficulties[isSuffix ? 2 : 1].indexOf(diff)];
	}

	public static function getDifficultyID(diff:String, ?isSuffix:Null<Bool> = false, ?difficulties:Array<Dynamic> = null):String
	{
		if (difficulties == null) {
			difficulties = PlayState.difficulties;
		}

		return difficulties[1][difficulties[isSuffix ? 2 : 0].indexOf(diff)];
	}

	public static function getDifficultySuffix(diff:String, ?isName:Null<Bool> = false, ?difficulties:Array<Dynamic> = null):String
	{
		if (difficulties == null) {
			difficulties = PlayState.difficulties;
		}

		return difficulties[2][difficulties[isName ? 0 : 1].indexOf(diff)];
	}

	public static function getDifficultyFilePath(diff:String = 'normal'):String
	{
		var fileSuffix:String = diff;

		if (fileSuffix != 'normal') {
			fileSuffix = '-' + fileSuffix;
		}
		else {
			fileSuffix = '';
		}

		var result:String = Paths.formatToSongPath(fileSuffix);

		if (result == diff) {
			return diff;
		}

		if (diff.contains('normal')) {
			return '';
		}

		if (diff.startsWith('-')) {
			return diff.substring(1, diff.length);
		}

		return result;
	}

	public static function difficultyString():String
	{
		return PlayState.difficulties[0][PlayState.storyDifficulty].toUpperCase();
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

		return splitter.join(' ');
	}

	public static function getKeyName(key:FlxKey):String
	{
		return switch (key)
		{
			case BACKSPACE: "BckSpc";
			case CONTROL: "Ctrl";
			case ALT: "Alt";
			case CAPSLOCK: "Caps";
			case PAGEUP: "PgUp";
			case PAGEDOWN: "PgDown";
			case ZERO: "0";
			case ONE: "1";
			case TWO: "2";
			case THREE: "3";
			case FOUR: "4";
			case FIVE: "5";
			case SIX: "6";
			case SEVEN: "7";
			case EIGHT: "8";
			case NINE: "9";
			case NUMPADZERO: "#0";
			case NUMPADONE: "#1";
			case NUMPADTWO: "#2";
			case NUMPADTHREE: "#3";
			case NUMPADFOUR: "#4";
			case NUMPADFIVE: "#5";
			case NUMPADSIX: "#6";
			case NUMPADSEVEN: "#7";
			case NUMPADEIGHT: "#8";
			case NUMPADNINE: "#9";
			case NUMPADMULTIPLY: "#*";
			case NUMPADPLUS: "#+";
			case NUMPADMINUS: "#-";
			case NUMPADPERIOD: "#.";
			case SEMICOLON: ";";
			case COMMA: ",";
			case PERIOD: ".";
			case GRAVEACCENT: "`";
			case LBRACKET: "[";
			case RBRACKET: "]";
			case QUOTE: "'";
			case PRINTSCREEN: "PrtScrn";
			case NONE: '---';
			default:
			{
				var label:String = '' + key;

				if (label.toLowerCase() == 'null') {
					'---';
				}

				'' + label.charAt(0).toUpperCase() + label.substr(1).toLowerCase();
			} 
		}
	}

	@:deprecated("`CoolUtil.interpolateColor()` is deprecated, use 'FlxTween.color()' instead")
	public static function interpolateColor(from:FlxColor, to:FlxColor, speed:Float = 0.045, multiplier:Float = 54.5):FlxColor
	{
		Debug.logWarn("`CoolUtil.interpolateColor()` is deprecated! use 'FlxTween.color()' instead");

		return FlxColor.interpolate(from, to, boundTo(FlxG.elapsed * (speed * multiplier), 0, 1));
	}

	@:deprecated("`CoolUtil.coolLerp()` is deprecated, use `FlxMath.lerp()` instead")
	public static function coolLerp(a:Float, b:Float, ratio:Float, multiplier:Float = 54.5, ?integer:Null<Float> = null):Float
	{
		Debug.logWarn("`CoolUtil.coolLerp()` is deprecated! use `FlxMath.lerp()` instead");

		if (integer != null) {
			return FlxMath.lerp(a, b, boundTo(integer - (FlxG.elapsed * (ratio * multiplier)), 0, 1));
		}

		return FlxMath.lerp(a, b, boundTo(FlxG.elapsed * (ratio * multiplier), 0, 1));
	}

	public static function boundTo(value:Float, min:Float, max:Float):Float
	{
		return Math.max(min, Math.min(max, value));
	}

	@:deprecated("`CoolUtil.truncateFloat()` is deprecated, use `CoolUtil.floorDecimal()` or 'FlxMath.roundDecimal()' instead")
	public static function truncateFloat(number:Float, precision:Int):Float
	{
		Debug.logWarn("`CoolUtil.truncateFloat()` is deprecated! use `CoolUtil.floorDecimal()` or 'FlxMath.roundDecimal()' instead");

		var num:Float = number;

		if (Math.isNaN(num)) num = 0;

		num = num * Math.pow(10, precision);
		num = Math.round(num) / Math.pow(10, precision);

		return num;
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

	public static function coolTextFile(path:String, ?ignoreWarnMsg:Bool = false, ?optimize:Bool = false):Array<String>
	{
		if (Paths.fileExists(path, TEXT, null, optimize)) {
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

	public static function dominantColor(sprite:FlxSprite):Int
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
						countByColor[colorOfThisPixel] =  countByColor[colorOfThisPixel] + 1;
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

		return maxKey;
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

	#if !mobile
	private static var colorArray:Array<FlxColor> =
	[
		FlxColor.fromRGB(148, 0, 211),
		FlxColor.fromRGB(75, 0, 130),
		FlxColor.fromRGB(0, 0, 255),
		FlxColor.fromRGB(0, 255, 0),
		FlxColor.fromRGB(255, 255, 0),
		FlxColor.fromRGB(255, 127, 0),
		FlxColor.fromRGB(255, 0 , 0)
	];

	private static var currentColor:Int = 0;
	private static var currentColor2:Int = 0;

	public static function recolorCounters(skippedFrames:Int = 0, skippedFrames2:Int = 0):Void
	{
		if (OptionData.rainFPS && skippedFrames >= 6)
		{
			if (currentColor >= colorArray.length) {
				currentColor = 0;
			}

			Main.fpsCounter.textColor = colorArray[currentColor];

			currentColor++;
			skippedFrames = 0;
		}
		else {
			skippedFrames++;
		}

		#if !hl
		if (OptionData.rainMemory && skippedFrames >= 6)
		{
			if (currentColor2 >= colorArray.length) {
				currentColor2 = 0;
			}

			Main.memoryCounter.textColor = colorArray[currentColor2];

			currentColor2++;
			skippedFrames2 = 0;
		}
		else {
			skippedFrames2++;
		}
		#end
	}
	#end

	#if sys
	public static function convPathShit(path:String):String
	{
		return Path.normalize(Sys.getCwd() + path) #if windows .replace('/', '\\') #end;
	}
	#end
}