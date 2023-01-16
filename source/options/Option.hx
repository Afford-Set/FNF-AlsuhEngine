package options;

using StringTools;

class Option
{
	private var child:Alphabet;
	public var text(get, set):String;
	public var onChange:Void->Void = null; //Pressed enter (on Bool type options) or pressed/held left/right (on other types)

	public var type(get, default):String = 'bool'; //bool, int (or integer), float (or fl), percent, string (or str)
	// Bool will use checkboxes
	// Everything else will use a text

	public var selected:Bool = false; // If false, then skip the label.

	public var onPause:Bool = false;
	public var blockedOnPause(default, set):Bool = false;

	public var isIgnoriteFunctionOnReset:Bool = false;

	public var showBoyfriend:Bool = false;
	public var scrollSpeed:Float = 50; //Only works on int/float, defines how fast it scrolls per second while holding left/right

	private var variable:String = null; //Variable from OptionData.hx
	public var defaultValue:Dynamic = null;

	public var curOption:Int = 0; //Don't change this
	public var options:Array<String> = null; //Only used in string type
	public var changeValue:Dynamic = 1; //Only used in int/float/percent type, how much is changed when you PRESS
	public var minValue:Dynamic = null; //Only used in int/float/percent type
	public var maxValue:Dynamic = null; //Only used in int/float/percent type
	public var decimals:Int = 1; //Only used in float/percent type

	public var displayFormat:String = '%v'; //How String/Float/Percent/Int values are shown, %v = Current value, %d = Default value
	public var description:String = '';
	public var name:String = 'Unknown';

	public function new(name:String, selected:Bool = false, description:String = '', ?variable:String = null, type:String = 'bool', defaultValue:Dynamic = 'null variable value', ?options:Array<String> = null):Void
	{
		this.name = name;
		this.selected = selected;
		this.description = description;
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
		if (onChange != null) { // nothing lol
			onChange();
		}
	}

	public function getValue():Dynamic
	{
		return Reflect.getProperty(OptionData, variable);
	}

	public function setValue(value:Dynamic):Void
	{
		Reflect.setProperty(OptionData, variable, value);

		#if LUA_ALLOWED
		if (onPause && PlayState.instance != null && !blockedOnPause) // for lua shit
		{
			var existsShit:Bool = OptionData.luaPrefsMap.exists(variable);
			var ourName:String = existsShit ? OptionData.luaPrefsMap.get(variable)[0] : null;

			if (existsShit && ourName != null) {
				PlayState.instance.setOnLuas(ourName, value);
			}

			OptionData.loadLuaPrefs();
		}
		#end
	}

	private function set_blockedOnPause(value:Bool):Bool
	{
		if (value) {
			description = 'This preference cannot be toggled in the pause menu.';
		}

		return blockedOnPause = value;
	}

	public function setChild(child:Alphabet):Void
	{
		this.child = child;
	}

	public function resetToDefault():Void
	{
		setValue(defaultValue);
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

	private function get_type():String
	{
		var newValue:String = 'bool';

		switch (type.toLowerCase().trim())
		{
			case 'int' | 'float' | 'percent' | 'string' | 'menu':
				newValue = type;
			case 'menus':
				newValue = 'menu';
			case 'men':
				newValue = 'menu';
			case 'integer':
				newValue = 'int';
			case 'str':
				newValue = 'string';
			case 'fl':
				newValue = 'float';
		}

		type = newValue;
		return type;
	}
}