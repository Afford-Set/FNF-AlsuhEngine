package;

#if desktop
import Discord.DiscordClient;
#end

import Achievements;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxObject;
import flixel.FlxCamera;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.FlxFlicker;
import flixel.input.keyboard.FlxKey;
import transition.TransitionableState;

using StringTools;

class MainMenuState extends TransitionableState
{
	private static var curSelected:Int = 0;

	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var menuItems:Array<String> =
	[
		'story_mode',
		'freeplay',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		#if !switch 'donate', #end
		'options'
	];

	var grpMenuItems:FlxTypedGroup<FlxSprite>;

	var magenta:FlxSprite;

	var camFollowPos:FlxObject;
	var camFollow:FlxPoint;

	public static var engineVersion:String = '1.6.4';
	public static var psychEngineVersion:String = '0.6.4';

	public static var gameVersion:String = '0.2.8';

	var debugKeys:Array<FlxKey>;

	public override function create():Void
	{
		super.create();

		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end

		WeekData.loadTheFirstEnabledMod();

		#if desktop
		DiscordClient.changePresence("In the Menus", null); // Updating Discord Rich Presence
		#end

		debugKeys = OptionData.copyKey(OptionData.keyBinds.get('debug_1'));

		if (FlxG.sound.music.playing == false || FlxG.sound.music.volume == 0) {
			FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		camGame = new FlxCamera();
		FlxG.cameras.reset(camGame);

		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;
		FlxG.cameras.add(camAchievement, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		var yScroll:Float = Math.max(0.25 - (0.05 * (menuItems.length - 4)), 0.1);

		var bg:FlxSprite = new FlxSprite(-80);
		if (Paths.fileExists('images/menuBG.png', IMAGE)) {
			bg.loadGraphic(Paths.getImage('menuBG'));
		}
		else {
			bg.loadGraphic(Paths.getImage('bg/menuBG'));
		}
		bg.scrollFactor.set(0, yScroll);
		bg.setGraphicSize(Std.int(bg.width * 1.175));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = OptionData.globalAntialiasing;
		add(bg);

		magenta = new FlxSprite(-80);
		if (Paths.fileExists('images/menuDesat.png', IMAGE)) {
			magenta.loadGraphic(Paths.getImage('menuDesat'));
		}
		else {
			magenta.loadGraphic(Paths.getImage('bg/menuDesat'));
		}
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = OptionData.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);

		camFollow = new FlxPoint(0, 0);

		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollowPos);

		grpMenuItems = new FlxTypedGroup<FlxSprite>();
		add(grpMenuItems);

		var scale:Float = 1;

		for (i in 0...menuItems.length)
		{
			var offset:Float = 108 - (Math.max(menuItems.length, 4) - 4) * 80;

			var menuItem:FlxSprite = new FlxSprite(0, (i * 140)  + offset);

			menuItem.scale.x = scale;
			menuItem.scale.y = scale;

			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + menuItems[i]);
			menuItem.animation.addByPrefix('idle', menuItems[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', menuItems[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);

			var scr:Float = (menuItems.length - 4) * 0.135;

			if (menuItems.length < 6) scr = 0;

			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = OptionData.globalAntialiasing;
			menuItem.updateHitbox();

			grpMenuItems.add(menuItem);
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var text:String = 'v ' + gameVersion + (OptionData.watermarks ? ' - FNF | v ' + engineVersion.trim() + ' - Alsuh Engine' : '');

		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, text, 12);
		versionShit.setFormat(Paths.getFont('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		versionShit.scrollFactor.set();
		add(versionShit);

		changeSelection();
		
		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();

		var leDate = Date.now();

		if (leDate.getDay() == 5 && leDate.getHours() >= 18)
		{
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');

			if (!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) //It's a friday night. WEEEEEEEEEEEEEEEEEE
			{
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();

				OptionData.savePrefs();
			}
		}
		#end
	}

	#if ACHIEVEMENTS_ALLOWED
	function giveAchievement():Void
	{
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.getSound('confirmMenu'), 0.7);
	}
	#end

	var selectedSomethin:Bool = false;
	var holdTime:Float = 0;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if (FreeplayMenuState.vocals != null) FreeplayMenuState.vocals.volume += 0.5 * elapsed;
		}

		camFollowPos.setPosition(CoolUtil.coolLerp(camFollowPos.x, camFollow.x, 0.13), CoolUtil.coolLerp(camFollowPos.y, camFollow.y, 0.13));

		if (!selectedSomethin)
		{
			if (controls.BACK || FlxG.mouse.justPressedRight)
			{
				FlxG.sound.play(Paths.getSound('cancelMenu'));
				FlxG.switchState(new TitleState());
			}

			if (menuItems.length > 1)
			{
				if (controls.UI_UP_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));
					changeSelection(-1);

					holdTime = 0;
				}

				if (controls.UI_DOWN_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));
					changeSelection(1);

					holdTime = 0;
				}
	
				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
	
					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						FlxG.sound.play(Paths.getSound('scrollMenu'));
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
					}
				}
	
				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));

					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}

			if (controls.ACCEPT || FlxG.mouse.justPressed)
			{
				if (menuItems[curSelected] == 'donate') {
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					if (OptionData.flashingLights) FlxFlicker.flicker(magenta, 1.1, 0.15, false);

					selectedSomethin = true;

					grpMenuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							new FlxTimer().start(1, function(tmr:FlxTimer)
							{
								FlxTween.tween(spr, {alpha: 0}, 0.4,
								{
									ease: FlxEase.quadOut,
									onComplete: function(twn:FlxTween) {
										spr.kill();
									}
								});
							});
						}
						else
						{
							if (OptionData.flashingLights)
							{
								FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
								{
									new FlxTimer().start(0.4, function(tmr:FlxTimer) {
										goToState(menuItems[curSelected]);
									});
								});
							}
							else
							{
								new FlxTimer().start(1.4, function(tmr:FlxTimer) {
									goToState(menuItems[curSelected]);
								});
							}
						}
					});

					FlxG.sound.play(Paths.getSound('confirmMenu'));
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;

				FlxG.switchState(new editors.MasterEditorMenu());
			}
			#end
		}

		grpMenuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
	}

	function goToState(daChoice:String):Void
	{
		switch (daChoice)
		{
			case 'story_mode':
				FlxG.switchState(new StoryMenuState());
			case 'freeplay':
				FlxG.switchState(new FreeplayMenuState());
			#if MODS_ALLOWED
			case 'mods':
				FlxG.switchState(new ModsMenuState());
			#end
			case 'awards':
				FlxG.switchState(new AchievementsMenuState());
			case 'credits':
				FlxG.switchState(new CreditsMenuState());
			case 'options':
				LoadingState.loadAndSwitchState(new options.OptionsMenuState());
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = CoolUtil.boundSelection(curSelected + change, menuItems.length);

		grpMenuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');

				var add:Float = 0;

				if (menuItems.length > 4) {
					add = menuItems.length * 8;
				}

				camFollow.set(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);

				spr.centerOffsets();
			}
		});
	}
}
