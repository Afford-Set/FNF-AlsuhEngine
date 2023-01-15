package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.effects.FlxFlicker;

using StringTools;

class GameplayChangersSubState extends BaseSubState
{
	private static var curSelected:Int = 0;

	var optionsArray:Array<GameplayOption> = [];
	var curOption:GameplayOption;
	var defaultValue:GameplayOption = new GameplayOption('Reset to Default Values');

	var isPause:Bool = false;

	public function new(?isPause:Bool = false):Void
	{
		super();

		this.isPause = isPause;
	}

	var grpOptions:FlxTypedGroup<Alphabet>;
	var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	var grpTexts:FlxTypedGroup<AttachedText>;

	function getOptions():Void
	{
		if (!isPause)
		{
			var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrollType', 'string', 'multiplicative', ["multiplicative", "constant"]);
			optionsArray.push(goption);
	
			var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollSpeed', 'float', 1);
			option.scrollSpeed = 2.0;
			option.minValue = 0.35;
			option.changeValue = 0.05;
			option.decimals = 2;
	
			if (goption.getValue() != "constant")
			{
				option.displayFormat = '%vX';
				option.maxValue = 3;
			}
			else
			{
				option.displayFormat = "%v";
				option.maxValue = 6;
			}
	
			optionsArray.push(option);
		}

		var option:GameplayOption = new GameplayOption('Playback Rate', 'playbackRate', 'float', 1);
		option.scrollSpeed = 1;
		option.minValue = 0.5;
		option.maxValue = 3.0;
		option.changeValue = 0.05;
		option.displayFormat = '%vX';
		option.decimals = 2;
		option.luaAllowed = true;
		option.luaString = 'playbackRate';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthGain', 'float', 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		option.luaAllowed = true;
		option.luaString = 'healthGainMult';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthLoss', 'float', 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0.5;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		option.luaAllowed = true;
		option.luaString = 'healthLossMult';
		optionsArray.push(option);

		if (!isPause)
		{
			var option:GameplayOption = new GameplayOption('Instakill on Miss', 'instaKill', 'bool', false);
			option.luaAllowed = true;
			option.luaString = 'instakillOnMiss';
			optionsArray.push(option);
		}

		var option:GameplayOption = new GameplayOption('Botplay', 'botPlay', 'bool', false);
		option.onChange = function():Void
		{
			if (isPause && PlayState.instance != null)
			{
				PlayState.instance.cpuControlled = PlayStateChangeables.botPlay;
				PlayState.instance.botplayTxt.alpha = 1;
				PlayState.instance.botplaySine = 0;
			}
	
			PlayState.usedPractice = PlayStateChangeables.botPlay;
		};

		option.luaAllowed = true;
		option.luaString = 'botPlay';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Practice Mode', 'practiceMode', 'bool', false);
		option.onChange = function():Void
		{
			if (isPause)
			{
				if (PlayState.instance != null) {
					PlayState.instance.practiceMode = PlayStateChangeables.practiceMode;
				}
	
				if (PlayState.instance.practiceMode) {
					FlxTween.tween(practiceText, {alpha: 1, y: practiceText.y + 5}, 0.4, {ease: FlxEase.quartInOut});
				}
				else {
					FlxTween.tween(practiceText, {alpha: 0, y: practiceText.y - 5}, 0.4, {ease: FlxEase.quartInOut});
				}
			}
	
			PlayState.usedPractice = PlayStateChangeables.practiceMode;
		};
		option.luaAllowed = true;
		option.luaString = 'practiceMode';
		optionsArray.push(option);

		defaultValue.type = 'amogus';
		optionsArray.push(defaultValue);
	}

	public function getOptionByName(name:String)
	{
		for (i in optionsArray)
		{
			var opt:GameplayOption = i;

			if (opt.name == name) {
				return opt;
			}
		}

		return null;
	}

	var practiceText:FlxText;

	public override function create():Void
	{
		super.create();

		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
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
	
			practiceText = new FlxText(20, 15 + (PlayState.chartingMode ? 128 : 96) + (PlayStateChangeables.practiceMode ? 5 : 0), 0, 'PRACTICE MODE', 32);
			practiceText.scrollFactor.set();
			practiceText.setFormat(Paths.getFont('vcr.ttf'), 32);
			practiceText.x = FlxG.width - (practiceText.width + 20);
			practiceText.updateHitbox();
			practiceText.alpha = PlayStateChangeables.practiceMode ? 1 : 0;
			add(practiceText);
		}

		grpOptions = new FlxTypedGroup<Alphabet>();
		add(grpOptions);

		checkboxGroup = new FlxTypedGroup<CheckboxThingie>();
		add(checkboxGroup);

		grpTexts = new FlxTypedGroup<AttachedText>();
		add(grpTexts);

		getOptions();

		for (i in 0...optionsArray.length)
		{
			var leOption:GameplayOption = optionsArray[i];

			if (isPause) {
				leOption.onPause = true;
			}

			var optionText:Alphabet = new Alphabet(200, 360, leOption.name, true);
			optionText.isMenuItem = true;
			optionText.scaleX = 0.8;
			optionText.scaleY = 0.8;
			optionText.targetY = i;
			grpOptions.add(optionText);

			switch (leOption.type)
			{
				case 'bool':
				{
					optionText.x += 110;
					optionText.startPosition.x += 110;
					optionText.snapToPosition();

					var checkbox:CheckboxThingie = new CheckboxThingie(optionText.x - 105, optionText.y, leOption.getValue() == true);
					checkbox.sprTracker = optionText;

					if (checkbox.isVanilla)
					{
						checkbox.offsetX -= 64;
						checkbox.offsetY -= 110;
					}
					else
					{
						checkbox.offsetX -= 32;
						checkbox.offsetY = -120;
					}

					checkbox.ID = i;
					checkbox.snapToUpdateVariables();
					checkboxGroup.add(checkbox);
				}
				case 'int' | 'float' | 'percent' | 'string':
				{
					optionText.snapToPosition();

					var valueText:AttachedText = new AttachedText(Std.string(leOption.getValue()), optionText.width, -72, true, 0.8);
					valueText.sprTracker = optionText;
					valueText.copyAlpha = true;
					valueText.ID = i;
					valueText.snapToUpdateVariables();
					grpTexts.add(valueText);

					leOption.setChild(valueText);
				}
				default: {
					optionText.snapToPosition();
				}
			}

			updateTextFrom(leOption);
		}

		changeSelection();
		reloadCheckboxes();

		if (isPause) cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	var flickering:Bool = false;

	var nextAccept:Int = 5;

	var holdTime:Float = 0;
	var holdTimeValue:Float = 0;

	var holdValue:Float = 0;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			PlayStateChangeables.saveChangeables();

			if (isPause)
			{
				PlayState.isNextSubState = true;

				FlxG.state.closeSubState();
				FlxG.state.openSubState(new PauseSubState(true));
			}
			else {
				close();
			}

			FlxG.sound.play(Paths.getSound('cancelMenu'));
		}

		if (!flickering)
		{
			if (optionsArray.length > 1)
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

				if (FlxG.mouse.wheel != 0 && !(FlxG.keys.pressed.ALT && curOption.type != 'bool')) {
					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}

			if ((controls.ACCEPT || FlxG.mouse.justPressed) && nextAccept <= 0)
			{
				if (curOption == defaultValue)
				{
					if (OptionData.flashingLights)
					{
						flickering = true;

						FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flick:FlxFlicker):Void
						{
							reset();
							FlxG.sound.play(Paths.getSound('cancelMenu'));
						});
					}
					else
					{
						reset();

						FlxG.sound.play(Paths.getSound('cancelMenu'));
						reloadCheckboxes();
					}

					FlxG.sound.play(Paths.getSound('confirmMenu'));
				}
				else
				{
					if (curOption.type == 'bool' && !curOption.blockedOnPause)
					{
						if (OptionData.flashingLights)
						{
							flickering = true;

							FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flick:FlxFlicker):Void {
								changeBool(curOption);
							});

							FlxG.sound.play(Paths.getSound('confirmMenu'));
						}
						else {
							changeBool(curOption);
						}
					}
					else if (curOption.type == 'menu')
					{
						if (OptionData.flashingLights)
						{
							flickering = true;

							FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flick:FlxFlicker):Void
							{
								flickering = false;
								curOption.change();
							});

							FlxG.sound.play(Paths.getSound('confirmMenu'));
						}
						else {
							curOption.change();
						}
					}
				}
			}

			if (curOption.type != 'bool' && curOption.type != 'menu' && curOption != defaultValue && !curOption.blockedOnPause)
			{
				if (controls.UI_LEFT || controls.UI_RIGHT)
				{
					var pressed:Bool = (controls.UI_LEFT_P || controls.UI_RIGHT_P);

					if (holdTimeValue > 0.5 || pressed) 
					{
						if (pressed)
						{
							var add:Dynamic = null;

							if (curOption.type != 'string') {
								add = controls.UI_LEFT ? -curOption.changeValue : curOption.changeValue;
							}

							switch (curOption.type)
							{
								case 'int' | 'float' | 'percent':
								{
									holdValue = curOption.getValue() + add;

									if (holdValue < curOption.minValue)
										holdValue = curOption.minValue;
									else if (holdValue > curOption.maxValue)
										holdValue = curOption.maxValue;

									switch (curOption.type)
									{
										case 'int':
										{
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);
										}
										case 'float' | 'percent':
										{
											holdValue = FlxMath.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
										}
									}
								}
								case 'string':
								{
									var num:Int = curOption.curOption; // lol

									if (controls.UI_LEFT_P)
										--num;
									else
										num++;

									if (num < 0)
										num = curOption.options.length - 1;
									else if (num >= curOption.options.length)
										num = 0;

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]); // lol
								}
							}

							updateTextFrom(curOption);

							curOption.change();
							FlxG.sound.play(Paths.getSound('scrollMenu'));
						}
						else if (curOption.type != 'string')
						{
							holdValue += curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1);

							if (holdValue < curOption.minValue) 
								holdValue = curOption.minValue;
							else if (holdValue > curOption.maxValue)
								holdValue = curOption.maxValue;

							switch (curOption.type)
							{
								case 'int':
								{
									curOption.setValue(Math.round(holdValue));
								}
								case 'float' | 'percent':
								{
									curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));
								}
							}

							updateTextFrom(curOption);
							curOption.change();
						}
					}

					if (curOption.type != 'string') {
						holdTimeValue += elapsed;
					}
				}
				else if (controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					clearHold();
				}

				if (FlxG.mouse.wheel != 0 && (FlxG.keys.pressed.ALT && curOption.type != 'bool'))
				{
					if (curOption.type != 'string')
					{
						holdValue += -(curOption.scrollSpeed / 50) * FlxG.mouse.wheel;

						if (holdValue < curOption.minValue) 
							holdValue = curOption.minValue;
						else if (holdValue > curOption.maxValue)
							holdValue = curOption.maxValue;

						switch (curOption.type)
						{
							case 'int':
							{
								curOption.setValue(Math.round(holdValue));
							}
							case 'float' | 'percent':
							{
								curOption.setValue(FlxMath.roundDecimal(holdValue, curOption.decimals));
							}
						}
		
						updateTextFrom(curOption);
						curOption.change();

						FlxG.sound.play(Paths.getSound('scrollMenu'));
					}
					else if (curOption.type == 'string')
					{
						var num:Int = curOption.curOption; // lol
						num += (-1 * FlxG.mouse.wheel);

						if (num < 0)
							num = curOption.options.length - 1;
						else if (num >= curOption.options.length)
							num = 0;

						curOption.curOption = num;
						curOption.setValue(curOption.options[num]); // lol

						updateTextFrom(curOption);
						curOption.change();

						FlxG.sound.play(Paths.getSound('scrollMenu'));
					}
				}
			}

			if (controls.RESET)
			{
				curOption.resetToDefault();
				curOption.change();

				FlxG.sound.play(Paths.getSound('scrollMenu'));

				updateTextFrom(curOption);
				reloadCheckboxes();
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}
	}

	function changeBool(option:GameplayOption):Void
	{
		flickering = false;

		FlxG.sound.play(Paths.getSound('scrollMenu'));

		option.setValue((option.getValue() == true) ? false : true);
		option.change();

		reloadCheckboxes();
	}

	function reset():Void
	{
		flickering = false;

		for (i in 0...optionsArray.length)
		{
			var leOption:GameplayOption = optionsArray[i];
			leOption.setValue(leOption.defaultValue);
	
			if (leOption.type != 'bool')
			{
				if (leOption.type == 'string') {
					leOption.curOption = leOption.options.indexOf(leOption.getValue());
				}

				updateTextFrom(leOption);
			}

			if (leOption.name == 'Scroll Speed')
			{
				leOption.displayFormat = "%vX";
				leOption.maxValue = 3;
	
				if (leOption.getValue() > 3) {
					leOption.setValue(3);
				}
		
				updateTextFrom(leOption);
			}
	
			leOption.change();
		}

		reloadCheckboxes();
	}

	function updateTextFrom(option:GameplayOption):Void
	{
		var text:String = option.displayFormat;
		var val:Dynamic = option.getValue();

		if (option.type == 'percent') val *= 100;

		var def:Dynamic = option.defaultValue;
		option.text = text.replace('%v', val).replace('%d', def);
	}

	function clearHold():Void
	{
		if (holdTimeValue > 0.5) {
			FlxG.sound.play(Paths.getSound('scrollMenu'));
		}

		holdTimeValue = 0;
	}

	function changeSelection(change:Int = 0)
	{
		curSelected = CoolUtil.boundSelection(curSelected + change, optionsArray.length);

		var bullShit:Int = 0;

		for (item in grpOptions.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)  {
				item.alpha = 1;
			}
		}

		for (checkbox in checkboxGroup)
		{
			checkbox.alpha = 0.6;
	
			if (checkbox.ID == curSelected) {
				checkbox.alpha = 1;
			}
		}

		for (text in grpTexts)
		{
			text.alpha = 0.6;
	
			if (text.ID == curSelected) {
				text.alpha = 1;
			}
		}

		curOption = optionsArray[curSelected]; //shorter lol

		FlxG.sound.play(Paths.getSound('scrollMenu'));
	}

	function reloadCheckboxes():Void
	{
		for (checkbox in checkboxGroup) {
			checkbox.daValue = (optionsArray[checkbox.ID].getValue() == true);
		}
	}
}

class GameplayOption
{
	private var child:Alphabet;
	public var text(get, set):String;
	public var onChange:Void->Void = null; //Pressed enter (on Bool type options) or pressed/held left/right (on other types)

	public var blockedOnPause:Bool = false;
	public var type(get, default):String = 'bool'; //bool, int (or integer), float (or fl), percent, string (or str)
	// Bool will use checkboxes
	// Everything else will use a text

	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right

	private var variable:String = null; //Variable from PlayStateChangeables.hx
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; //Don't change this
	public var options:Array<String> = null; //Only used in string type
	public var changeValue:Dynamic = 1; //Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; //Only used in int/float/percent type
	public var maxValue:Dynamic = null; //Only used in int/float/percent type
	public var decimals:Int = 1; //Only used in float/percent type

	public var displayFormat:String = '%v'; //How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var name:String = 'Unknown';

	public var onPause:Bool = false;
	public var luaAllowed:Bool = false;
	public var luaString:String = '';

	public function new(name:String, variable:String = null, type:String = 'bool', defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null):Void
	{
		this.name = name;
		this.variable = variable;
		this.type = type;
		this.defaultValue = defaultValue;
		this.options = options;

		if (defaultValue == 'null variable value')
		{
			switch (type)
			{
				case 'bool':
					defaultValue = false;
				case 'int' | 'float':
					defaultValue = 0;
				case 'percent':
					defaultValue = 1;
				case 'string':
				{
					defaultValue = '';
					if (options.length > 0) {
						defaultValue = options[0];
					}
				}
			}
		}

		if (getValue() == null) {
			setValue(defaultValue);
		}

		switch (type)
		{
			case 'string':
			{
				var num:Int = options.indexOf(getValue());

				if (num > -1) {
					curOption = num;
				}
			}	
			case 'percent':
			{
				displayFormat = '%v%';
				changeValue = 0.01;
	
				minValue = 0;
				maxValue = 1;
	
				scrollSpeed = 0.5;
				decimals = 2;
			}
		}
	}

	public function change():Void
	{
		if (onChange != null) {
			onChange();
		}
	}

	public function getValue():Dynamic
	{
		return Reflect.getProperty(PlayStateChangeables, variable);
	}

	public function setValue(value:Dynamic):Void
	{
		Reflect.setProperty(PlayStateChangeables, variable, value);

		#if LUA_ALLOWED
		if (onPause && luaAllowed && luaString.length > 0 && !blockedOnPause) {
			PlayState.instance.setOnLuas(luaString, value);
		}
		#end
	}

	public function setChild(child:Alphabet):Void
	{
		this.child = child;
	}

	private function get_text():String
	{
		if (child != null) {
			return child.text;
		}

		return null;
	}

	private function set_text(newValue:String = ''):String
	{
		if (child != null) {
			child.text = newValue;
		}

		return null;
	}

	public function resetToDefault():Void
	{
		setValue(defaultValue);

		if (name == 'Scroll Speed')
		{
			displayFormat = "%vX";
			maxValue = 3;

			if (getValue() > 3) {
				setValue(3);
			}
		}
	}

	private function get_type()
	{
		var newValue:String = 'bool';

		switch (type.toLowerCase().trim())
		{
			case 'int' | 'float' | 'percent' | 'string' | 'amogus': newValue = type;
			case 'integer': newValue = 'int';
			case 'str': newValue = 'string';
			case 'fl': newValue = 'float';
		}

		type = newValue;

		return type;
	}
}