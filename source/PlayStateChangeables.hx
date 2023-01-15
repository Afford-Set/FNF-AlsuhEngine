package;

import flixel.FlxG;
import flixel.animation.FlxAnimationController;

using StringTools;

class PlayStateChangeables
{
	public static var scrollType:String = 'multiplicative';
	public static var scrollSpeed:Float = 1.0;
	public static var playbackRate:Float = 1.0;
	public static var healthGain:Float = 1.0;
	public static var healthLoss:Float = 1.0;
	public static var instaKill:Bool = false;
	public static var botPlay:Bool = false;
	public static var practiceMode:Bool = false;

	public static function saveChangeables():Void
	{
		FlxG.save.data.scrollType = scrollType;
		FlxG.save.data.scrollSpeed = scrollSpeed;
		FlxG.save.data.playbackRate = playbackRate;
		FlxG.save.data.healthGain = healthGain;
		FlxG.save.data.healthLoss = healthLoss;
		FlxG.save.data.instaKill = instaKill;
		FlxG.save.data.botPlay = botPlay;
		FlxG.save.data.practiceMode = practiceMode;
		FlxG.save.flush();
	}

	public static function loadChangeables():Void
	{
		if (FlxG.save.data.scrollType != null) {
			scrollType = FlxG.save.data.scrollType;
		}
		if (FlxG.save.data.scrollSpeed != null) {
			scrollSpeed = FlxG.save.data.scrollSpeed;
		}
		if (FlxG.save.data.playbackRate != null) {
			playbackRate = FlxG.save.data.playbackRate;
		}
		if (FlxG.save.data.healthGain != null) {
			healthGain = FlxG.save.data.healthGain;
		}
		if (FlxG.save.data.healthLoss != null) {
			healthLoss = FlxG.save.data.healthLoss;
		}
		if (FlxG.save.data.instaKill != null) {
			instaKill = FlxG.save.data.instaKill;
		}
		if (FlxG.save.data.botPlay != null) {
			botPlay = FlxG.save.data.botPlay;
			PlayState.usedPractice = botPlay;
		}
		if (FlxG.save.data.practiceMode != null) {
			practiceMode = FlxG.save.data.practiceMode;
			PlayState.usedPractice = practiceMode;
		}
	}
}