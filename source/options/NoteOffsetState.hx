package options;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.ui.FlxBar;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import transition.Transition;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxSpriteGroup;

using StringTools;

class NoteOffsetState extends MusicBeatState
{
	var boyfriend:Character;
	var gf:Character;

	var camHUD:FlxCamera;
	var camGame:FlxCamera;
	var camOther:FlxCamera;

	var coolText:FlxText;
	var rating:FlxSprite;
	var comboNums:FlxSpriteGroup;
	var dumbTexts:FlxTypedGroup<FlxText>;

	var barPercent:Float = 0;

	var delayMin:Int = 0;
	var delayMax:Int = 500;

	var timeBarBG:FlxSprite;
	var timeBar:FlxBar;
	var timeTxt:FlxText;

	var beatText:Alphabet;
	var beatTween:FlxTween;

	var changeModeText:FlxText;

	public override function create():Void
	{
		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camOther = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOther, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		Transition.nextCamera = camOther;
		FlxG.camera.scroll.set(120, 130);

		super.create();

		persistentUpdate = true;

		FlxG.sound.pause();

		var bg:BGSprite = new BGSprite('stage/stageback', -600, -200, 0.9, 0.9);
		add(bg);

		var stageFront:BGSprite = new BGSprite('stage/stagefront', -650, 600, 0.9, 0.9);
		stageFront.setGraphicSize(Std.int(stageFront.width * 1.1));
		stageFront.updateHitbox();
		add(stageFront);

		if (!OptionData.lowQuality)
		{
			var stageLight:BGSprite = new BGSprite('stage/stage_light', -125, -100, 0.9, 0.9);
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			add(stageLight);

			var stageLight:BGSprite = new BGSprite('stage/stage_light', 1225, -100, 0.9, 0.9);
			stageLight.setGraphicSize(Std.int(stageLight.width * 1.1));
			stageLight.updateHitbox();
			stageLight.flipX = true;
			add(stageLight);

			var stageCurtains:BGSprite = new BGSprite('stage/stagecurtains', -500, -300, 1.3, 1.3);
			stageCurtains.setGraphicSize(Std.int(stageCurtains.width * 0.9));
			stageCurtains.updateHitbox();
			add(stageCurtains);
		}

		gf = new Character(400, 130, 'gf');
		gf.x += gf.positionArray[0];
		gf.y += gf.positionArray[1];
		gf.scrollFactor.set(0.95, 0.95);
		add(gf);

		boyfriend = new Character(770, 100, 'bf', true);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		coolText = new FlxText(0, 0, 0, '', 32);
		coolText.screenCenter();
		coolText.x = FlxG.width * 0.55;

		rating = new FlxSprite();
		rating.loadGraphic(Paths.getImage('ratings/sick'));
		rating.cameras = [camHUD];
		rating.setGraphicSize(Std.int(rating.width * 0.7));
		rating.updateHitbox();
		rating.antialiasing = OptionData.globalAntialiasing;
		add(rating);

		comboNums = new FlxSpriteGroup();
		comboNums.cameras = [camHUD];
		add(comboNums);

		var seperatedScore:Array<Int> = [];

		for (i in 0...3) {
			seperatedScore.push(FlxG.random.int(0, 9));
		}

		var daLoop:Int = 0;

		for (i in seperatedScore)
		{
			var numScore:FlxSprite = new FlxSprite(43 * daLoop);
			numScore.loadGraphic(Paths.getImage('numbers/num' + i));
			numScore.cameras = [camHUD];
			numScore.setGraphicSize(Std.int(numScore.width * 0.5));
			numScore.updateHitbox();
			numScore.antialiasing = OptionData.globalAntialiasing;
			comboNums.add(numScore);
			daLoop++;
		}

		dumbTexts = new FlxTypedGroup<FlxText>();
		dumbTexts.cameras = [camHUD];
		add(dumbTexts);

		createTexts();

		repositionCombo();

		beatText = new Alphabet(0, 0, 'Beat Hit!', true);
		beatText.scaleX = 0.6;
		beatText.scaleY = 0.6;
		beatText.x += 260;
		beatText.alpha = 0;
		beatText.acceleration.y = 250;
		beatText.visible = false;
		add(beatText);
		
		timeTxt = new FlxText(0, 600, FlxG.width, "", 32);
		timeTxt.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		timeTxt.borderSize = 2;
		timeTxt.visible = false;
		timeTxt.cameras = [camHUD];

		barPercent = menu == 'dance' ? OptionData.danceOffset : OptionData.noteOffset;

		updateNoteDelay();
		
		timeBarBG = new FlxSprite(0, timeTxt.y + 8);

		if (Paths.fileExists('images/timeBar.png', IMAGE)) {
			timeBarBG.loadGraphic(Paths.getImage('timeBar'));
		}
		else {
			timeBarBG.loadGraphic(Paths.getImage('ui/timeBar'));
		}

		timeBarBG.setGraphicSize(Std.int(timeBarBG.width * 1.2));
		timeBarBG.updateHitbox();
		timeBarBG.cameras = [camHUD];
		timeBarBG.screenCenter(X);
		timeBarBG.visible = false;

		timeBar = new FlxBar(0, timeBarBG.y + 4, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 8), Std.int(timeBarBG.height - 8), this, 'barPercent', delayMin, delayMax);
		timeBar.scrollFactor.set();
		timeBar.screenCenter(X);
		timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
		timeBar.numDivisions = 800;
		timeBar.visible = false;
		timeBar.cameras = [camHUD];

		add(timeBarBG);
		add(timeBar);
		add(timeTxt);

		var blackBox:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 40, FlxColor.BLACK);
		blackBox.scrollFactor.set();
		blackBox.alpha = 0.6;
		blackBox.cameras = [camHUD];
		add(blackBox);

		changeModeText = new FlxText(0, 4, FlxG.width, "", 32);
		changeModeText.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER);
		changeModeText.scrollFactor.set();
		changeModeText.cameras = [camHUD];
		add(changeModeText);

		updateMode();

		Conductor.changeBPM(128.0);
		FlxG.sound.playMusic(Paths.getMusic('offsetSong'), 1, true);
	}

	var holdTime:Float = 0;

	var menu:String = 'combo';
	var curMenu:Int = 0;
	
	var holdingObjectType:Null<Bool> = null;

	var startMousePos:FlxPoint = new FlxPoint();
	var startComboOffset:FlxPoint = new FlxPoint();

	public override function update(elapsed:Float):Void
	{
		var addNum:Int = FlxG.keys.pressed.ALT ? 10 : 1;

		switch (menu)
		{
			case 'combo':
			{
				var controlArray:Array<Bool> = [
					FlxG.keys.justPressed.LEFT,
					FlxG.keys.justPressed.RIGHT,
					FlxG.keys.justPressed.UP,
					FlxG.keys.justPressed.DOWN,
				
					FlxG.keys.justPressed.A,
					FlxG.keys.justPressed.D,
					FlxG.keys.justPressed.W,
					FlxG.keys.justPressed.S
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
							}
						}
					}
			
					repositionCombo();
				}

				if (FlxG.mouse.justPressed)
				{
					holdingObjectType = null;
					FlxG.mouse.getScreenPosition(camHUD, startMousePos);

					if (startMousePos.x - comboNums.x >= 0 && startMousePos.x - comboNums.x <= comboNums.width &&
						startMousePos.y - comboNums.y >= 0 && startMousePos.y - comboNums.y <= comboNums.height)
					{
						holdingObjectType = true;
						startComboOffset.x = OptionData.comboOffset[2];
						startComboOffset.y = OptionData.comboOffset[3];
					}
					else if (startMousePos.x - rating.x >= 0 && startMousePos.x - rating.x <= rating.width &&
							 startMousePos.y - rating.y >= 0 && startMousePos.y - rating.y <= rating.height)
					{
						holdingObjectType = false;
						startComboOffset.x = OptionData.comboOffset[0];
						startComboOffset.y = OptionData.comboOffset[1];
					}
				}
		
				if (FlxG.mouse.justReleased) {
					holdingObjectType = null;
				}

				if (holdingObjectType != null)
				{
					if (FlxG.mouse.justMoved)
					{
						var mousePos:FlxPoint = FlxG.mouse.getScreenPosition(camHUD);
						var addNum:Int = holdingObjectType ? 2 : 0;

						OptionData.comboOffset[addNum + 0] = Math.round((mousePos.x - startMousePos.x) + startComboOffset.x);
						OptionData.comboOffset[addNum + 1] = -Math.round((mousePos.y - startMousePos.y) - startComboOffset.y);

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
			}
			default:
			{
				if (controls.UI_LEFT_P)
				{
					if (menu == 'offset') {
						barPercent = Math.max(delayMin, Math.min(OptionData.noteOffset - 1, delayMax));
					}
					else if (menu == 'dance') {
						barPercent = Math.max(delayMin, Math.min(OptionData.danceOffset - 1, delayMax));
					}
		
					updateNoteDelay();
				}
				else if (controls.UI_RIGHT_P)
				{
					if (menu == 'offset') {
						barPercent = Math.max(delayMin, Math.min(OptionData.noteOffset + 1, delayMax));
					}
					else if (menu == 'dance') {
						barPercent = Math.max(delayMin, Math.min(OptionData.danceOffset + 1, delayMax));
					}
		
					updateNoteDelay();
				}

				var mult:Int = 1;
			
				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					holdTime += elapsed;
					if (controls.UI_LEFT) mult = -1;
				}

				if (controls.UI_LEFT_R || controls.UI_RIGHT_R) holdTime = 0;

				if (FlxG.mouse.wheel != 0)
				{
					barPercent += -(menu == 'dance' ? 10 : 100) * FlxG.mouse.wheel;
					barPercent = Math.max(delayMin, Math.min(barPercent, delayMax));
				}

				if (holdTime > 0.5)
				{
					barPercent += (menu == 'dance' ? 10 : 100) * elapsed * mult;
					barPercent = Math.max(delayMin, Math.min(barPercent, delayMax));

					updateNoteDelay();
				}

				if (controls.RESET)
				{
					holdTime = 0;

					if (menu == 'dance') {
						barPercent = 2;
					}
					else {
						barPercent = 0;
					}

					updateNoteDelay();
				}
			}
		}

		if ((controls.ACCEPT || FlxG.mouse.justPressed))
		{
			var menusArrayShit:Array<String> = ['combo', 'offset', 'dance'];

			curMenu++;

			if (curMenu < 0)
				curMenu = menusArrayShit.length - 1;
			if (curMenu >= menusArrayShit.length)
				curMenu = 0;

			menu = menusArrayShit[curMenu];

			updateMode();
			updateNoteDelay();
		}

		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			OptionData.savePrefs();

			if (zoomTween != null) zoomTween.cancel();
			if (beatTween != null) beatTween.cancel();

			persistentUpdate = false;

			Transition.nextCamera = camOther;

			FlxG.sound.music.pause();
			FlxG.sound.music.volume = 0;

			FlxG.mouse.visible = false;
			FlxG.switchState(new OptionsMenuState());
		}

		Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);
	}

	var zoomTween:FlxTween;
	var lastBeatHit:Int = -1;

	public override function beatHit():Void
	{
		super.beatHit();

		if (lastBeatHit == curBeat) {
			return;
		}

		if (curBeat % OptionData.danceOffset == 0)
		{
			boyfriend.dance();
			gf.dance();
		}
		
		if (curBeat % 4 == 2)
		{
			FlxG.camera.zoom = 1.15;

			if (zoomTween != null) zoomTween.cancel();

			zoomTween = FlxTween.tween(FlxG.camera, {zoom: 1}, 1, {ease: FlxEase.circOut, onComplete: function(twn:FlxTween):Void
			{
				zoomTween = null;
			}});

			beatText.alpha = 1;
			beatText.y = 320;
			beatText.velocity.y = -150;
	
			if (beatTween != null) beatTween.cancel();
	
			beatTween = FlxTween.tween(beatText, {alpha: 0}, 1, {ease: FlxEase.sineIn, onComplete: function(twn:FlxTween):Void
			{
				beatTween = null;
			}});
		}

		lastBeatHit = curBeat;
	}

	function repositionCombo():Void
	{
		rating.screenCenter();
		rating.x = coolText.x - 125 + OptionData.comboOffset[0];
		rating.y -= 60 + OptionData.comboOffset[1];

		comboNums.screenCenter();
		comboNums.x = coolText.x - 175 + OptionData.comboOffset[2];
		comboNums.y += 80 - OptionData.comboOffset[3];

		reloadTexts();
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
			text.cameras = [camHUD];

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

	function updateNoteDelay():Void
	{
		if (menu == 'offset')
		{
			OptionData.noteOffset = Math.round(barPercent);
			timeTxt.text = 'Current offset: ' + Math.floor(barPercent) + ' ms';
		}
		else if (menu == 'dance')
		{
			OptionData.danceOffset = Math.round(barPercent);
			timeTxt.text = 'Current offset: ' + Math.floor(barPercent) + ' beats';
		}
	}

	function updateMode():Void
	{
		rating.visible = menu == 'combo';
		comboNums.visible = menu == 'combo';
		dumbTexts.visible = menu == 'combo';
		
		timeBarBG.visible = menu != 'combo';
		timeBar.visible = menu != 'combo';
		timeTxt.visible = menu != 'combo';

		beatText.visible = menu == 'offset';

		switch (menu)
		{
			case 'combo':
			{
				changeModeText.text = '< Combo Offset (Press Accept to Switch) >';
			}
			case 'offset':
			{
				barPercent = OptionData.noteOffset;

				delayMin = 0;
				delayMax = 500;

				timeBar.setRange(delayMin, delayMax);

				changeModeText.text = '< Note/Beat Delay (Press Accept to Switch) >';
			}
			case 'dance':
			{
				barPercent = OptionData.danceOffset;

				delayMin = 1;
				delayMax = 20;

				timeBar.setRange(delayMin, delayMax);

				changeModeText.text = '< Dance Delay on Beats (Press Accept to Switch) >';
			}
		}

		changeModeText.text = changeModeText.text.toUpperCase();
		FlxG.mouse.visible = menu == 'combo';
	}
}