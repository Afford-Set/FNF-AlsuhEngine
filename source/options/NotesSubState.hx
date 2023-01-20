package options;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import shaders.ColorSwap;
import options.OptionsMenuState;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.system.FlxSound;
import flixel.effects.FlxFlicker;

using StringTools;

class NotesSubState extends MusicBeatSubState
{
	private static var curSelected:Int = 0;
	private static var typeSelected:Int = 0;

	private var grpNumbers:FlxTypedGroup<Alphabet>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;
	private var shaderArray:Array<ColorSwap> = [];

	var curValue:Float = 0;

	var blackBG:FlxSprite;
	var hsbText:Alphabet;

	var posX:Int = 230;

	var isPause:Bool = false;

	public function new(?isPause:Bool = false):Void
	{
		super();

		this.isPause = isPause;
	}

	public override function create():Void
	{
		super.create();
		
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Options Menu - Notes", null);
		#end

		var bg:FlxSprite = new FlxSprite();

		if (isPause)
		{
			bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
			bg.alpha = 0.6;
			bg.scrollFactor.set();
		}
		else
		{
			if (Paths.fileExists('images/menuDesat.png', IMAGE)) {
				bg.loadGraphic(Paths.getImage('menuDesat'));
			}
			else {
				bg.loadGraphic(Paths.getImage('bg/menuDesat'));
			}
			bg.color = 0xFFea71fd;
			bg.updateHitbox();
			bg.screenCenter();
			bg.antialiasing = OptionData.globalAntialiasing;
		}

		add(bg);

		if (isPause)
		{
			var levelInfo:FlxText = new FlxText(20, 20, 0, '', 32);
			levelInfo.text += PlayState.SONG.songName;
			levelInfo.scrollFactor.set();
			levelInfo.setFormat(Paths.getFont('vcr.ttf'), 32);
			levelInfo.updateHitbox();
			levelInfo.x = FlxG.width - (levelInfo.width + 20);
			add(levelInfo);
	
			var levelDifficulty:FlxText = new FlxText(20, 20 + 32, 0, '', 32);
			levelDifficulty.text += CoolUtil.getDifficultyName(PlayState.lastDifficulty, PlayState.difficulties).toUpperCase();
			levelDifficulty.scrollFactor.set();
			levelDifficulty.setFormat(Paths.getFont('vcr.ttf'), 32);
			levelDifficulty.updateHitbox();
			levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);
			add(levelDifficulty);
	
			var blueballedTxt:FlxText = new FlxText(20, 20 + 64, 0, '', 32);
			blueballedTxt.text = 'Blue balled: ' + PlayState.deathCounter;
			blueballedTxt.scrollFactor.set();
			blueballedTxt.setFormat(Paths.getFont('vcr.ttf'), 32);
			blueballedTxt.updateHitbox();
			blueballedTxt.x = FlxG.width - (blueballedTxt.width + 20);
			add(blueballedTxt);
	
			var chartingText:FlxText = new FlxText(20, 20 + 96, 0, "CHARTING MODE", 32);
			chartingText.scrollFactor.set();
			chartingText.setFormat(Paths.getFont('vcr.ttf'), 32);
			chartingText.x = FlxG.width - (chartingText.width + 20);
			chartingText.updateHitbox();
			chartingText.visible = PlayState.chartingMode;
			add(chartingText);
	
			var practiceText:FlxText = new FlxText(20, 20 + (PlayState.chartingMode ? 128 : 96), 0, 'PRACTICE MODE', 32);
			practiceText.scrollFactor.set();
			practiceText.setFormat(Paths.getFont('vcr.ttf'), 32);
			practiceText.x = FlxG.width - (practiceText.width + 20);
			practiceText.updateHitbox();
			practiceText.alpha = PlayStateChangeables.practiceMode ? 1 : 0;
			add(practiceText);
		}
		
		blackBG = new FlxSprite(posX - 25);
		blackBG.makeGraphic(870, 200, FlxColor.BLACK);
		blackBG.alpha = 0.4;
		add(blackBG);

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);

		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);

		for (i in 0...OptionData.arrowHSV.length)
		{
			var yPos:Float = (165 * i) + 35;

			for (j in 0...3)
			{
				var optionText:Alphabet = new Alphabet(posX + (225 * j) + 250, yPos + 60, Std.string(OptionData.arrowHSV[i][j]), true);
				grpNumbers.add(optionText);
			}

			var note:FlxSprite = new FlxSprite(posX, yPos);
			note.frames = Paths.getSparrowAtlas('notes/NOTE_assets');

			var animations:Array<String> = Note.colArray.copy();
			animations[i] = animations[i] + ' instance';
			//trace(animations[i]);
			//trace(animations[i] + ' 10000');
			if (note.frames.getByName(animations[i] + ' 10000') == null) animations[i] = Note.colArray[i] + '0';

			note.animation.addByPrefix('idle', animations[i]);
			note.animation.play('idle');
			note.antialiasing = OptionData.globalAntialiasing;
			grpNotes.add(note);

			var newShader:ColorSwap = new ColorSwap();
			note.shader = newShader.shader;
			newShader.hue = OptionData.arrowHSV[i][0] / 360;
			newShader.saturation = OptionData.arrowHSV[i][1] / 100;
			newShader.brightness = OptionData.arrowHSV[i][2] / 100;
			shaderArray.push(newShader);
		}

		hsbText = new Alphabet(posX + 560, 0, "Hue      Saturation  Brightness", false);
		hsbText.scaleX = 0.6;
		hsbText.scaleY = 0.6;
		add(hsbText);

		changeSelection();

		if (isPause) cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var nextAccept:Int = 5;

	var holdTime:Float = 0;
	var holdTimeType:Float = 0;

	var holdTimeValue:Float = 0;

	var flickering:Bool = false;
	var changingNote:Bool = false;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var pauseMusic:FlxSound = PauseSubState.pauseMusic;

		if (isPause && pauseMusic != null && pauseMusic.volume < 0.5) {
			pauseMusic.volume += 0.01 * elapsed;
		}

		if (!flickering)
		{
			if (changingNote)
			{
				if (controls.BACK || (controls.ACCEPT || FlxG.mouse.justPressed))
				{
					changingNote = false;
					changeSelection();
				}

				if (holdTimeValue < 0.5)
				{
					if (controls.UI_LEFT_P)
					{
						updateValue(-1);
						FlxG.sound.play(Paths.getSound('scrollMenu'));
					}
					else if (controls.UI_RIGHT_P)
					{
						updateValue(1);
						FlxG.sound.play(Paths.getSound('scrollMenu'));
					}
					else if (controls.RESET)
					{
						resetValue(curSelected, typeSelected);
						FlxG.sound.play(Paths.getSound('scrollMenu'));
					}

					if (controls.UI_LEFT_R || controls.UI_RIGHT_R) {
						holdTimeValue = 0;
					}
					else if (controls.UI_LEFT || controls.UI_RIGHT) {
						holdTimeValue += elapsed;
					}
				}
				else
				{
					var add:Float = 90;
		
					switch (typeSelected)
					{
						case 1 | 2: add = 50;
					}
			
					if (controls.UI_LEFT) {
						updateValue(elapsed * -add);
					}
					else if (controls.UI_RIGHT) {
						updateValue(elapsed * add);
					}
				
					if (controls.UI_LEFT_R || controls.UI_RIGHT_R)
					{
						FlxG.sound.play(Paths.getSound('scrollMenu'));
						holdTimeValue = 0;
					}
				}

				if (FlxG.mouse.wheel != 0) {
					updateValue(-1 * FlxG.mouse.wheel);
				}
			}
			else
			{
				if (OptionData.arrowHSV.length > 1)
				{
					if (controls.UI_UP_P)
					{
						changeSelection(-1);
						holdTime = 0;
					}
		
					if (controls.UI_DOWN_P)
					{
						changeSelection(1);
						holdTime = 0;
					}
		
					if (controls.UI_DOWN || controls.UI_UP)
					{
						var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
						holdTime += elapsed;
						var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);
		
						if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
							changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1));
						}
					}
		
					if (FlxG.mouse.wheel != 0 && !FlxG.keys.pressed.ALT) {
						changeSelection(-1 * FlxG.mouse.wheel);
					}
				}

				if (controls.UI_LEFT_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));

					changeType(-1);
					holdTimeType = 0;
				}

				if (controls.UI_RIGHT_P)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));

					changeType(1);
					holdTimeType = 0;
				}

				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					var checkLastHold:Int = Math.floor((holdTimeType - 0.5) * 10);
					holdTimeType += elapsed;
					var checkNewHold:Int = Math.floor((holdTimeType - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0)
					{
						FlxG.sound.play(Paths.getSound('scrollMenu'));
						changeType((checkNewHold - checkLastHold) * (controls.UI_LEFT ? -1 : 1));
					}
				}

				if (FlxG.mouse.wheel != 0 && FlxG.keys.pressed.ALT) {
					changeType(-1 * FlxG.mouse.wheel);
				}

				if (controls.RESET)
				{
					for (i in 0...3) {
						resetValue(curSelected, i);
					}

					FlxG.sound.play(Paths.getSound('scrollMenu'));
				}
		
				if ((controls.ACCEPT || FlxG.mouse.justPressed) && nextAccept <= 0)
				{
					if (OptionData.flashingLights)
					{
						flickering = true;

						FlxFlicker.flicker(grpNotes.members[curSelected], 1, 0.06, true);

						FlxFlicker.flicker(grpNumbers.members[(curSelected * 3) + typeSelected], 1, 0.06, true, false, function(flick:FlxFlicker):Void {
							selectType();
						});

						FlxG.sound.play(Paths.getSound('confirmMenu'));
					}
					else {
						selectType();
					}
				}

				if (controls.BACK || FlxG.mouse.justPressedRight)
				{
					FlxG.sound.play(Paths.getSound('cancelMenu'));
	
					if (isPause)
					{
						OptionData.savePrefs();
	
						PlayState.isNextSubState = true;
	
						FlxG.state.closeSubState();
						FlxG.state.openSubState(new OptionsSubState());
					}
					else {
						close();
					}
				}
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function selectType():Void
	{
		FlxG.sound.play(Paths.getSound('scrollMenu'));

		flickering = false;
		changingNote = true;
		holdTimeValue = 0;

		for (i in 0...grpNumbers.length)
		{
			var item = grpNumbers.members[i];
			item.alpha = 0;

			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}

		for (i in 0...grpNotes.length)
		{
			var item = grpNotes.members[i];
			item.alpha = 0;

			if (curSelected == i) {
				item.alpha = 1;
			}
		}
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected = CoolUtil.boundSelection(curSelected + change, OptionData.arrowHSV.length);

		curValue = OptionData.arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length)
		{
			var item = grpNumbers.members[i];
			item.alpha = 0.6;

			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}

		for (i in 0...grpNotes.length)
		{
			var item = grpNotes.members[i];
			item.alpha = 0.6;
			item.scale.set(0.75, 0.75);
	
			if (curSelected == i)
			{
				item.alpha = 1;
				item.scale.set(1, 1);
		
				hsbText.y = item.y - 70;
				blackBG.y = item.y - 20;
			}
		}

		FlxG.sound.play(Paths.getSound('scrollMenu'));
	}

	function changeType(change:Int = 0):Void
	{
		typeSelected += change;

		if (typeSelected < 0)
			typeSelected = 2;
		if (typeSelected > 2)
			typeSelected = 0;

		curValue = OptionData.arrowHSV[curSelected][typeSelected];
		updateValue();

		for (i in 0...grpNumbers.length)
		{
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
	
			if ((curSelected * 3) + typeSelected == i) {
				item.alpha = 1;
			}
		}
	}

	function resetValue(selected:Int, type:Int):Void
	{
		curValue = 0;

		OptionData.arrowHSV[selected][type] = 0;

		switch (type)
		{
			case 0: shaderArray[selected].hue = 0;
			case 1: shaderArray[selected].saturation = 0;
			case 2: shaderArray[selected].brightness = 0;
		}

		var item = grpNumbers.members[(selected * 3) + type];
		item.text = '0';

		var add:Float = (40 * (item.letters.length - 1)) / 2;

		for (letter in item.letters) {
			letter.offset.x += add;
		}

		reloadAllShitOnGame();
	}

	function updateValue(change:Float = 0):Void
	{
		curValue += change;

		var roundedValue:Int = Math.round(curValue);
		var max:Float = 180;

		switch (typeSelected)
		{
			case 1 | 2: max = 100;
		}

		if (roundedValue < -max) {
			curValue = -max;
		}
		else if (roundedValue > max) {
			curValue = max;
		}

		roundedValue = Math.round(curValue);

		OptionData.arrowHSV[curSelected][typeSelected] = roundedValue;

		switch (typeSelected)
		{
			case 0: shaderArray[curSelected].hue = roundedValue / 360;
			case 1: shaderArray[curSelected].saturation = roundedValue / 100;
			case 2: shaderArray[curSelected].brightness = roundedValue / 100;
		}

		var item = grpNumbers.members[(curSelected * 3) + typeSelected];
		item.text = Std.string(roundedValue);

		var add:Float = (40 * (item.letters.length - 1)) / 2;
	
		for (letter in item.letters)
		{
			letter.offset.x += add;
			if (roundedValue < 0) letter.offset.x += 10;
		}

		reloadAllShitOnGame();
	}

	function reloadAllShitOnGame():Void
	{
		if (isPause && PlayState.instance != null)
		{
			PlayState.instance.notes.forEachAlive(function(note:Note):Void
			{
				@:privateAccess
				var maxNote:Int = note.maxNote;
				var noteData:Int = note.noteData;

				if (noteData > -1 && noteData < OptionData.arrowHSV.length)
				{
					note.colorSwap.hue = OptionData.arrowHSV[noteData % maxNote][0] / 360;
					note.colorSwap.saturation = OptionData.arrowHSV[noteData % maxNote][1] / 100;
					note.colorSwap.brightness = OptionData.arrowHSV[noteData % maxNote][2] / 100;
				}

				note.noteSplashHue = note.colorSwap.hue;
				note.noteSplashSat = note.colorSwap.saturation;
				note.noteSplashBrt = note.colorSwap.brightness;
			});

			PlayState.instance.playerStrums.forEachAlive(function(note:StrumNote):Void
			{
				var noteData:Int = note.noteData;

				if (note.animation.curAnim == null || note.animation.curAnim.name == 'static') 
				{
					note.colorSwap.hue = 0;
					note.colorSwap.saturation = 0;
					note.colorSwap.brightness = 0;
				}
				else
				{
					if (noteData > -1 && noteData < OptionData.arrowHSV.length)
					{
						note.colorSwap.hue = OptionData.arrowHSV[noteData][0] / 360;
						note.colorSwap.saturation = OptionData.arrowHSV[noteData][1] / 100;
						note.colorSwap.brightness = OptionData.arrowHSV[noteData][2] / 100;
					}
				}
			});

			PlayState.instance.opponentStrums.forEachAlive(function(note:StrumNote):Void
			{
				var noteData:Int = note.noteData;

				if (note.animation.curAnim == null || note.animation.curAnim.name == 'static') 
				{
					note.colorSwap.hue = 0;
					note.colorSwap.saturation = 0;
					note.colorSwap.brightness = 0;
				}
				else
				{
					if (noteData > -1 && noteData < OptionData.arrowHSV.length)
					{
						note.colorSwap.hue = OptionData.arrowHSV[noteData][0] / 360;
						note.colorSwap.saturation = OptionData.arrowHSV[noteData][1] / 100;
						note.colorSwap.brightness = OptionData.arrowHSV[noteData][2] / 100;
					}
				}
			});

			PlayState.instance.grpNoteSplashes.forEachAlive(function(noteSpl:NoteSplash):Void
			{
				if (noteSpl.note > -1 && noteSpl.note < OptionData.arrowHSV.length)
				{
					noteSpl.colorSwap.hue = OptionData.arrowHSV[noteSpl.note][0] / 360;
					noteSpl.colorSwap.saturation = OptionData.arrowHSV[noteSpl.note][1] / 100;
					noteSpl.colorSwap.brightness = OptionData.arrowHSV[noteSpl.note][2] / 100;
				}
			});
		}
	}
}