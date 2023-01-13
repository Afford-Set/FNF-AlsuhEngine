package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import Achievements;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import transition.TransitionableState;

using StringTools;

class AchievementsMenuState extends TransitionableState
{
	#if ACHIEVEMENTS_ALLOWED
	private static var curSelected:Int = 0;

	var achievements:Array<String> = [];
	var achievementIndex:Array<Int> = [];

	private var grpTexts:FlxTypedGroup<Alphabet>;
	private var grpAchievements:FlxTypedGroup<AttachedAchievement>;

	private var descBox:FlxSprite;
	private var descText:FlxText;

	override function create():Void
	{
		super.create();

		persistentUpdate = persistentDraw = true;

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Achievements Menu", null);
		#end

		var menuBG:FlxSprite = new FlxSprite();
		if (Paths.fileExists('images/menuBGBlue.png', IMAGE)) {
			menuBG.loadGraphic(Paths.getImage('menuBGBlue'));
		}
		else {
			menuBG.loadGraphic(Paths.getImage('bg/menuBGBlue'));
		}
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = OptionData.globalAntialiasing;
		add(menuBG);

		grpTexts = new FlxTypedGroup<Alphabet>();
		add(grpTexts);

		grpAchievements = new FlxTypedGroup<AttachedAchievement>();
		add(grpAchievements);

		Achievements.loadAchievements();
	
		for (i in 0...Achievements.achievementsStuff.length)
		{
			if (!Achievements.achievementsStuff[i][3] || Achievements.achievementsMap.exists(Achievements.achievementsStuff[i][2]))
			{
				achievements.push(Achievements.achievementsStuff[i]);
				achievementIndex.push(i);
			}
		}

		for (i in 0...achievements.length)
		{
			var achieveName:String = Achievements.achievementsStuff[achievementIndex[i]][2];
			var unlocked:String = Achievements.isAchievementUnlocked(achieveName) ? Achievements.achievementsStuff[achievementIndex[i]][0] : '?';

			var leText:Alphabet = new Alphabet(280, 270, unlocked, false);
			leText.isMenuItem = true;
			leText.targetY = i - curSelected;
			leText.snapToPosition();
			grpTexts.add(leText);

			var icon:AttachedAchievement = new AttachedAchievement(leText.x - 105, leText.y, achieveName);
			icon.sprTracker = leText;
			icon.ID = i;
			grpAchievements.add(icon);
		}

		descBox = new FlxSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.getFont("vcr.ttf"), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		changeSelection();
	}

	var holdTime:Float = 0;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			persistentUpdate = false;

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

		for (achievement in grpAchievements)
		{
			achievement.alpha = 0.6;

			if (achievement.ID == curSelected) {
				achievement.alpha = 1;
			}
		}
	
		descText.text = Achievements.achievementsStuff[achievementIndex[curSelected]][1];
		descText.screenCenter(Y);
		descText.y += 270;

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
	}
	#end
}