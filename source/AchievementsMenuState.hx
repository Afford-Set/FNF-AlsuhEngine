package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import Achievements;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tweens.FlxTween;

using StringTools;

class AchievementsMenuState extends MusicBeatState
{
	#if ACHIEVEMENTS_ALLOWED
	private static var curSelected:Int = 0;

	var curAchieve:Achievement = null;
	var achievements:Array<Achievement> = [];

	private var grpTexts:FlxTypedGroup<Alphabet>;
	private var grpAchievements:FlxTypedGroup<AttachedAchievement>;

	private var descBox:FlxSprite;
	private var descText:FlxText;

	var bg:FlxSprite;

	var startingTweenBGColor:Bool = true;
	var startColor:FlxColor = FlxColor.WHITE;
	var intendedColor:FlxColor;
	var colorTween:FlxTween;

	override function create():Void
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Achievements Menu", null);
		#end

		bg = new FlxSprite();

		if (Paths.fileExists('images/menuDesat.png', IMAGE)) {
			bg.loadGraphic(Paths.getImage('menuDesat'));
		}
		else {
			bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		}

		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.color = startColor;
		bg.antialiasing = OptionData.globalAntialiasing;
		add(bg);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		grpAchievements = new FlxTypedGroup<AttachedAchievement>();
		add(grpAchievements);

		Achievements.loadAchievements();

		for (i in 0...Achievements.achievementsStuff.length)
		{
			var daAchieve:Achievement = Achievements.achievementsStuff[i];

			if (!daAchieve.hidden || Achievements.achievementsMap.exists(daAchieve.save_tag)) {
				achievements.push(daAchieve);
			}
		}

		for (i in 0...achievements.length)
		{
			var daAchieve:Achievement = achievements[i];
			var unlocked:Bool = Achievements.isAchievementUnlocked(daAchieve.save_tag);

			if (daAchieve.fileName != null) {
				Paths.currentModDirectory = daAchieve.fileName;
			}

			var leText:Alphabet = new Alphabet(280, 270, unlocked ? daAchieve.name : '?', false);
			leText.isMenuItem = true;
			leText.targetY = i - curSelected;
			leText.setPosition(280, (100 * i) + 210);
			leText.hasIcon = true;
			grpTexts.add(leText);

			var icon:AttachedAchievement = new AttachedAchievement(leText.x - 105, leText.y, daAchieve.save_tag);
			icon.sprTracker = leText;
			icon.ID = i;
			grpAchievements.add(icon);

			Paths.currentModDirectory = '';
		}

		if (curSelected >= achievements.length) curSelected = 0;

		descBox = new FlxSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		changeSelection();

		super.create();
	}

	var holdTime:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			persistentUpdate = false;

			if (colorTween != null) {
				colorTween.cancel();
			}

			FlxG.sound.play(Paths.getSound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}

		if (achievements.length > 1)
		{
			var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

			if (controls.UI_UP_P)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}

			if (controls.UI_DOWN_P)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
				}
			}

			if (FlxG.mouse.wheel != 0) {
				changeSelection(-shiftMult * FlxG.mouse.wheel);
			}
		}
	}

	public override function openSubState(SubState:FlxSubState):Void
	{
		super.openSubState(SubState);

		if (!startingTweenBGColor && colorTween != null) {
			colorTween.active = false;
		}
	}

	public override function closeSubState():Void
	{
		super.closeSubState();

		if (startingTweenBGColor)
		{
			var newColor:FlxColor = 0xFF1B1B41;

			if (Achievements.isAchievementUnlocked(curAchieve.save_tag))
			{
				var col:Array<Int> = curAchieve.color;
				newColor = FlxColor.fromRGB(col[0], col[1], col[2]);
			}

			if (intendedColor != newColor)
			{
				if (colorTween != null) {
					colorTween.cancel();
				}

				intendedColor = newColor;

				colorTween = FlxTween.color(bg, 1, startColor, intendedColor,
				{
					onComplete: function(twn:FlxTween):Void {
						colorTween = null;
					}
				});
			}

			startingTweenBGColor = false;
		}
		else
		{
			if (colorTween != null) {
				colorTween.active = true;
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = CoolUtil.boundSelection(curSelected + change, achievements.length);

		var bullShit:Int = 0;

		for (item in grpTexts.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}

		curAchieve = achievements[curSelected];

		if (!startingTweenBGColor)
		{
			var newColor:FlxColor = 0xFF1B1B41;

			if (Achievements.isAchievementUnlocked(curAchieve.save_tag))
			{
				var col:Array<Int> = curAchieve.color;
				newColor = FlxColor.fromRGB(col[0], col[1], col[2]);
			}

			if (newColor != intendedColor)
			{
				if (colorTween != null) {
					colorTween.cancel();
				}

				intendedColor = newColor;

				colorTween = FlxTween.color(bg, 1, bg.color, intendedColor,
				{
					onComplete: function(twn:FlxTween):Void {
						colorTween = null;
					}
				});
			}
		}

		for (achievement in grpAchievements)
		{
			achievement.alpha = 0.6;

			if (achievement.ID == curSelected) {
				achievement.alpha = 1;
			}
		}

		var desc:String = curAchieve.desc;
		var visible:Bool = desc != null && desc.length > 0;

		descText.text = desc;
		descText.screenCenter(Y);
		descText.y += 270;

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		descText.visible = visible;
		descBox.visible = visible;

		FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
	}
	#end
}