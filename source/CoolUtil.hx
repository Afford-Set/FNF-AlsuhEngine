package;

import flixel.FlxG;
import flixel.math.FlxMath;
import flixel.util.FlxSave;
import flixel.util.FlxColor;
import flixel.input.keyboard.FlxKey;

#if sys
import sys.io.File;
import sys.FileSystem;
#else
import openfl.utils.Assets;
#end

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

		return Paths.formatToSongPath(fileSuffix);
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
		return Paths.formatToSongPath(song + '-' + diff);
	}

	public static function formatToName(name:String):String
	{
		var splitter:Array<String> = name.trim().split('-');

		for (i in 0...splitter.length)
		{
			var str:String = splitter[i];
			str = '' + str.charAt(0).toUpperCase().trim() + str.substr(1).toLowerCase().trim();
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
			{
				var label:String = '' + key;

				if (label.toLowerCase() == 'null') {
					return '---';
				}

				return '' + label.charAt(0).toUpperCase() + label.substr(1).toLowerCase();
			} 
		}
	}

	@:deprecated("`CoolUtil.interpolateColor()` is deprecated, use 'FlxTween.color()' instead")
	public static function interpolateColor(from:FlxColor, to:FlxColor, speed:Float = 0.045, multiplier:Float = 54.5):FlxColor
	{
		Debug.logWarn("`CoolUtil.interpolateColor()` is deprecated! use 'FlxTween.color()' instead");

		return FlxColor.interpolate(from, to, boundTo(FlxG.elapsed * (speed * multiplier), 0, 1));
	}

	public static function coolLerp(a:Float, b:Float, ratio:Float, multiplier:Float = 54.5, ?integerShitKillMeLoopWhatEver:Null<Float> = null):Float
	{
		if (integerShitKillMeLoopWhatEver != null) {
			return FlxMath.lerp(a, b, boundTo(integerShitKillMeLoopWhatEver - (FlxG.elapsed * (ratio * multiplier)), 0, 1));
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

	public static function coolTextFile(path:String):Array<String>
	{
		var daList:Array<String> = [];

		#if sys
		if (FileSystem.exists(path)) daList = File.getContent(path).trim().split('\n');
		#else
		if (Assets.exists(path)) daList = Assets.getText(path).trim().split('\n');
		#end

		for (i in 0...daList.length) {
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function listFromString(string:String):Array<String>
	{
		var daList:Array<String> = [];
		daList = string.trim().split('\n');

		for (i in 0...daList.length) {
			daList[i] = daList[i].trim();
		}

		return daList;
	}

	public static function numberArray(max:Int, ?min = 0):Array<Int>
	{
		var dumbArray:Array<Int> = [];

		for (i in min...max) {
			dumbArray.push(i);
		}

		return dumbArray;
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
	}
	#end
}