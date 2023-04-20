package options;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import options.OptionsMenuState;
import flixel.group.FlxSpriteGroup;

using StringTools;

class ComboSubState extends MusicBeatSubState
{
	var rating:FlxSprite;
	var comboNums:FlxSpriteGroup;
	var dumbTexts:FlxTypedGroup<FlxText>;

	public override function create():Void
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Options Menu - Combo Position", null);
		#end

		FlxG.mouse.visible = true;

		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 20, 0, '', 32);
		levelInfo.text += PlayState.SONG.songName;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.getFont('vcr.ttf'), 32);
		levelInfo.updateHitbox();
		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 20 + 32, 0, '', 32);
		levelDifficulty.text += CoolUtil.difficultyString(true);
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.getFont('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
		add(levelDifficulty);

		var pos:Int = 64;
		var blueballedTxt:FlxText = null;
		
		if (OptionData.naughtyness)
		{
			blueballedTxt = new FlxText(20, 20 + 64, 0, '', 32);
			blueballedTxt.text = 'Blue balled: ' + PlayState.deathCounter;
			blueballedTxt.scrollFactor.set();
			blueballedTxt.setFormat(Paths.getFont('vcr.ttf'), 32);
			blueballedTxt.updateHitbox();
			blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);
			add(blueballedTxt);

			pos = 96;
		}

		var chartingText:FlxText = new FlxText(20, 20 + pos, 0, "CHARTING MODE", 32);
		chartingText.scrollFactor.set();
		chartingText.setFormat(Paths.getFont('vcr.ttf'), 32);
		chartingText.x = FlxG.width - (chartingText.width + 20);
		chartingText.updateHitbox();
		chartingText.visible = PlayState.chartingMode;
		add(chartingText);

		var practiceText:FlxText = new FlxText(20, 20 + (pos + (PlayState.chartingMode ? 32 : 0)), 0, 'PRACTICE MODE', 32);
		practiceText.scrollFactor.set();
		practiceText.setFormat(Paths.getFont('vcr.ttf'), 32);
		practiceText.x = FlxG.width - (practiceText.width + 20);
		practiceText.updateHitbox();
		practiceText.alpha = PlayState.instance.practiceMode ? 1 : 0;
		add(practiceText);

		rating = new FlxSprite();

		if (Paths.fileExists('images/sick.png', IMAGE)) {
			rating.loadGraphic(Paths.getImage('sick'));
		}
		else {
			rating.loadGraphic(Paths.getImage('ratings/sick'));
		}

		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		rating.antialiasing = OptionData.globalAntialiasing;
		add(rating);

		comboNums = new FlxSpriteGroup();
		add(comboNums);

		var seperatedScore:Array<Int> = [];

		for (i in 0...3) {
			seperatedScore.push(FlxG.random.int(0, 9));
		}

		var daLoop:Int = 0;

		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite(43 * daLoop);

			if (Paths.fileExists('images/num' + i + '.png', IMAGE)) {
				numScore.loadGraphic(Paths.getImage('num'));
			}
			else {
				numScore.loadGraphic(Paths.getImage('numbers/num' + i));
			}

			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();
			numScore.antialiasing = OptionData.globalAntialiasing;
			comboNums.add(numScore);

			daLoop++;
		}

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);

		createTexts();
		repositionCombo();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

		super.create();
	}

	var holdingObjectType:String = '';

	var startMousePos:FlxPoint = new FlxPoint();
	var startComboOffset:FlxPoint = new FlxPoint();

	public override function update(elapsed:Float):Void
	{
		var pauseMusic:FlxSound = PauseSubState.pauseMusic;

		if (OptionData.pauseMusic != 'None' && pauseMusic != null && pauseMusic.volume < 0.5) {
			pauseMusic.volume += 0.01 * elapsed;
		}

		var addNum:Int = FlxG.keys.pressed.SHIFT ? 10 : 1;

		var controlArray:Array<Bool> =
		[
			FlxG.keys.justPressed.LEFT,
			FlxG.keys.justPressed.RIGHT,
			FlxG.keys.justPressed.UP,
			FlxG.keys.justPressed.DOWN,
		
			FlxG.keys.justPressed.A,
			FlxG.keys.justPressed.D,
			FlxG.keys.justPressed.W,
			FlxG.keys.justPressed.S,

			FlxG.keys.justPressed.J,
			FlxG.keys.justPressed.L,
			FlxG.keys.justPressed.I,
			FlxG.keys.justPressed.K
		];

		if (controlArray.contains(true))
		{
			for (i in 0...controlArray.length)
			{
				if (controlArray[i])
				{
					switch (i)
					{
						case 0:
							OptionData.comboOffset[0] -= addNum;
						case 1:
							OptionData.comboOffset[0] += addNum;
						case 2:
							OptionData.comboOffset[1] += addNum;
						case 3:
							OptionData.comboOffset[1] -= addNum;
						case 4:
							OptionData.comboOffset[2] -= addNum;
						case 5:
							OptionData.comboOffset[2] += addNum;
						case 6:
							OptionData.comboOffset[3] += addNum;
						case 7:
							OptionData.comboOffset[3] -= addNum;
						case 8:
							OptionData.comboOffset[4] -= addNum;
						case 9:
							OptionData.comboOffset[4] += addNum;
						case 10:
							OptionData.comboOffset[5] += addNum;
						case 11:
							OptionData.comboOffset[5] -= addNum;
					}
				}
			}

			repositionCombo();
		}

		if (FlxG.mouse.justPressed)
		{
			holdingObjectType = null;
			FlxG.mouse.getScreenPosition(FlxG.cameras.list[FlxG.cameras.list.length], startMousePos);

			if (startMousePos.x - rating.x >= 0 && startMousePos.x - rating.x <= rating.width &&
				startMousePos.y - rating.y >= 0 && startMousePos.y - rating.y <= rating.height)
			{
				holdingObjectType = 'rating';
				startComboOffset.x = OptionData.comboOffset[0];
				startComboOffset.y = OptionData.comboOffset[1];
			}
			else if (startMousePos.x - comboNums.x >= 0 && startMousePos.x - comboNums.x <= comboNums.width &&
				startMousePos.y - comboNums.y >= 0 && startMousePos.y - comboNums.y <= comboNums.height)
			{
				holdingObjectType = 'numscore';
				startComboOffset.x = OptionData.comboOffset[2];
				startComboOffset.y = OptionData.comboOffset[3];
			}
		}

		if (FlxG.mouse.justReleased) {
			holdingObjectType = null;
		}

		if (holdingObjectType != null)
		{
			if (FlxG.mouse.justMoved)
			{
				var mousePos:FlxPoint = FlxG.mouse.getScreenPosition(FlxG.cameras.list[FlxG.cameras.list.length - 1]);

				switch (holdingObjectType)
				{
					case 'rating':
					{
						OptionData.comboOffset[0] = Math.round((mousePos.x - startMousePos.x) + startComboOffset.x);
						OptionData.comboOffset[1] = -Math.round((mousePos.y - startMousePos.y) - startComboOffset.y);
					}
					case 'numscore':
					{
						OptionData.comboOffset[2] = Math.round((mousePos.x - startMousePos.x) + startComboOffset.x);
						OptionData.comboOffset[3] = -Math.round((mousePos.y - startMousePos.y) - startComboOffset.y);
					}
				}

				repositionCombo();
			}
		}

		if (controls.RESET)
		{
			for (i in 0...OptionData.comboOffset.length) {
				OptionData.comboOffset[i] = 0;
			}

			repositionCombo();
		}

		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			FlxG.sound.play(Paths.getSound('cancelMenu'));
			
			OptionData.savePrefs();

			FlxG.mouse.visible = false;

			PlayState.isNextSubState = true;
			
			FlxG.state.closeSubState();
			FlxG.state.openSubState(new OptionsSubState());
		}

		super.update(elapsed);
	}

	function createTexts():Void
	{
		for (i in 0...4)
		{
			var text:FlxText = new FlxText(10, 48 + (i * 30), 0, '', 24);
			text.setFormat(Paths.getFont('vcr.ttf'), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 2;
			dumbTexts.add(text);

			if (i > 1) {
				text.y += 24;
			}
		}
	}

	function reloadTexts():Void
	{
		for (i in 0...dumbTexts.length)
		{
			switch (i)
			{
				case 0: dumbTexts.members[i].text = 'Rating Offset:';
				case 1: dumbTexts.members[i].text = '[' + OptionData.comboOffset[0] + ', ' + OptionData.comboOffset[1] + ']';
				case 2: dumbTexts.members[i].text = 'Numbers Offset:';
				case 3: dumbTexts.members[i].text = '[' + OptionData.comboOffset[2] + ', ' + OptionData.comboOffset[3] + ']';
			}
		}
	}

	function repositionCombo():Void
	{
		rating.screenCenter();
		rating.x = 580 + OptionData.comboOffset[0];
		rating.y -= 60 + OptionData.comboOffset[1];

		comboNums.screenCenter();
		comboNums.x = 529 + OptionData.comboOffset[2];
		comboNums.y += 80 - OptionData.comboOffset[3];

		reloadTexts();
	}
}