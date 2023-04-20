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

class GameplayChangersSubState extends MusicBeatSubState
{
	private static var curSelected:Int = 0;

	var optionsArray:Array<GameplayOption> = [];
	var curOption:GameplayOption;
	var defaultValue:GameplayOption = new GameplayOption('Reset to Default Values');

	var grpOptions:FlxTypedGroup<Alphabet>;
	var checkboxGroup:FlxTypedGroup<CheckboxThingie>;
	var grpTexts:FlxTypedGroup<AttachedText>;

	function getOptions():Void
	{
		var goption:GameplayOption = new GameplayOption('Scroll Type', 'scrolltype', 'string', 'multiplicative', ["multiplicative", "constant"]);
		optionsArray.push(goption);

		var option:GameplayOption = new GameplayOption('Scroll Speed', 'scrollspeed', 'float', 1);
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

		var option:GameplayOption = new GameplayOption('Playback Rate', 'songspeed', 'float', 1);
		option.scrollSpeed = 1;
		option.minValue = 0.5;
		option.maxValue = 3.0;
		option.changeValue = 0.05;
		option.displayFormat = '%vX';
		option.decimals = 2;
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Gain Multiplier', 'healthgain', 'float', 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Health Loss Multiplier', 'healthloss', 'float', 1);
		option.scrollSpeed = 2.5;
		option.minValue = 0.5;
		option.maxValue = 5;
		option.changeValue = 0.1;
		option.displayFormat = '%vX';
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Random Notes', 'randomnotes', 'bool', false);
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Instakill on Miss', 'instakill', 'bool', false);
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Practice Mode', 'practice', 'bool', false);
		optionsArray.push(option);

		var option:GameplayOption = new GameplayOption('Botplay', 'botplay', 'bool', false);
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

			var optionText:Alphabet = new Alphabet(200, 360, leOption.name, true);
			optionText.isMenuItem = true;
			optionText.scaleX = 0.8;
			optionText.scaleY = 0.8;
			optionText.targetY = i;
			optionText.setPosition(300, 70 * i);
			grpOptions.add(optionText);

			switch (leOption.type)
			{
				case 'bool':
				{
					optionText.x += 110;
					optionText.startPosition.x += 110;
					optionText.hasIcon = true;

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
					var valueText:AttachedText = new AttachedText(Std.string(leOption.getValue()), optionText.width, -72, true, 0.8);
					valueText.sprTracker = optionText;
					valueText.copyAlpha = true;
					valueText.ID = i;
					valueText.snapToUpdateVariables();
					grpTexts.add(valueText);

					leOption.setChild(valueText);
				}
			}

			updateTextFrom(leOption);
		}

		changeSelection();
		reloadCheckboxes();
	}

	var flickering:Bool = false;

	var nextAccept:Int = 5;

	var holdTime:Float = 0;
	var holdTimeValue:Float = 0;

	var holdValue:Float = 0;

	public override function update(elapsed:Float):Void
	{
		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			OptionData.savePrefs();
			close();

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

						FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flk:FlxFlicker):Void
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
					if (curOption.type == 'bool')
					{
						if (OptionData.flashingLights)
						{
							flickering = true;

							FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flk:FlxFlicker):Void {
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

							FlxFlicker.flicker(grpOptions.members[curSelected], 1, 0.06, true, false, function(flk:FlxFlicker):Void
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

			if (curOption.type != 'bool' && curOption.type != 'menu' && curOption != defaultValue)
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
									holdValue = CoolUtil.boundTo(curOption.getValue() + add, curOption.minValue, curOption.maxValue);

									switch (curOption.type)
									{
										case 'int':
										{
											holdValue = Math.round(holdValue);
											curOption.setValue(holdValue);
										}
										case 'float' | 'percent':
										{
											holdValue = CoolUtil.roundDecimal(holdValue, curOption.decimals);
											curOption.setValue(holdValue);
										}
									}
								}
								case 'string':
								{
									var num:Int = curOption.curOption; // lol
									num = CoolUtil.boundSelection(num + (controls.UI_LEFT_P ? -1 : 1), curOption.options.length);

									curOption.curOption = num;
									curOption.setValue(curOption.options[num]); //lol
									
									if (curOption.name == "Scroll Type")
									{
										var oOption:GameplayOption = getOptionByName("Scroll Speed");

										if (oOption != null)
										{
											if (curOption.getValue() == "constant")
											{
												oOption.displayFormat = "%v";
												oOption.maxValue = 6;
											}
											else
											{
												oOption.displayFormat = "%vX";
												oOption.maxValue = 3;

												if (oOption.getValue() > 3) oOption.setValue(3);
											}

											updateTextFrom(oOption);
										}
									}
								}
							}

							updateTextFrom(curOption);

							curOption.change();
							FlxG.sound.play(Paths.getSound('scrollMenu'));
						}
						else if (curOption.type != 'string')
						{
							holdValue = CoolUtil.boundTo(holdValue + curOption.scrollSpeed * elapsed * (controls.UI_LEFT ? -1 : 1), curOption.minValue, curOption.maxValue);

							switch (curOption.type)
							{
								case 'int':
									curOption.setValue(Math.round(holdValue));
								case 'float' | 'percent':
								{
									var blah:Float = CoolUtil.boundTo(holdValue + curOption.changeValue - (holdValue % curOption.changeValue), curOption.minValue, curOption.maxValue);
									curOption.setValue(CoolUtil.roundDecimal(blah, curOption.decimals));
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
						holdValue = CoolUtil.boundTo(holdValue + (curOption.scrollSpeed / 50) * FlxG.mouse.wheel, curOption.minValue, curOption.maxValue);

						switch (curOption.type)
						{
							case 'int':
								curOption.setValue(Math.round(holdValue));
							case 'float' | 'percent':
							{
								var blah:Float = CoolUtil.boundTo(holdValue + curOption.changeValue - (holdValue % curOption.changeValue), curOption.minValue, curOption.maxValue);
								curOption.setValue(CoolUtil.roundDecimal(blah, curOption.decimals));
							}
						}
		
						updateTextFrom(curOption);
						curOption.change();

						FlxG.sound.play(Paths.getSound('scrollMenu'));
					}
					else if (curOption.type == 'string')
					{
						var num:Int = curOption.curOption; // lol
						num = CoolUtil.boundSelection(num + (1 * FlxG.mouse.wheel), curOption.options.length);

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

				if (curOption.type != 'bool')
				{
					if (curOption.type == 'string') {
						curOption.curOption = curOption.options.indexOf(curOption.getValue());
					}

					updateTextFrom(curOption);
				}

				if (curOption.name == 'Scroll Speed')
				{
					curOption.displayFormat = "%vX";
					curOption.maxValue = 3;

					if (curOption.getValue() > 3) {
						curOption.setValue(3);
					}

					updateTextFrom(curOption);
				}

				curOption.change();
			}
		}

		if (nextAccept > 0) {
			nextAccept -= 1;
		}

		super.update(elapsed);
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

	public var type(get, default):String = 'bool'; //bool, int (or integer), float (or fl), percent, string (or str)
	// Bool will use checkboxes
	// Everything else will use a text

	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right

	private var variable:String = null; //Variable from OptionData.hx's gameplaySettings
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
		return OptionData.gameplaySettings.get(variable);
	}

	public function setValue(value:Dynamic):Void
	{
		OptionData.gameplaySettings.set(variable, value);
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

	private function get_type():String
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