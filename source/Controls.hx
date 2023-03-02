package;

import flixel.FlxG;
import flixel.input.FlxInput;
import flixel.input.keyboard.FlxKey;
import flixel.input.actions.FlxAction;
import flixel.input.actions.FlxActionSet;
import flixel.input.actions.FlxActionInput;
import flixel.input.actions.FlxActionManager;
import flixel.input.gamepad.FlxGamepadButton;
import flixel.input.gamepad.FlxGamepadInputID;
import flixel.input.actions.FlxActionInputDigital;

using StringTools;

#if (haxe >= "4.0.0")
enum abstract Action(String) to String from String
{
	var UI_UP = "ui_up";
	var UI_LEFT = "ui_left";
	var UI_RIGHT = "ui_right";
	var UI_DOWN = "ui_down";
	var UI_UP_P = "ui_up-press";
	var UI_LEFT_P = "ui_left-press";
	var UI_RIGHT_P = "ui_right-press";
	var UI_DOWN_P = "ui_down-press";
	var UI_UP_R = "ui_up-release";
	var UI_LEFT_R = "ui_left-release";
	var UI_RIGHT_R = "ui_right-release";
	var UI_DOWN_R = "ui_down-release";
	var NOTE_UP = "note_up";
	var NOTE_LEFT = "note_left";
	var NOTE_RIGHT = "note_right";
	var NOTE_DOWN = "note_down";
	var NOTE_UP_P = "note_up-press";
	var NOTE_LEFT_P = "note_left-press";
	var NOTE_RIGHT_P = "note_right-press";
	var NOTE_DOWN_P = "note_down-press";
	var NOTE_UP_R = "note_up-release";
	var NOTE_LEFT_R = "note_left-release";
	var NOTE_RIGHT_R = "note_right-release";
	var NOTE_DOWN_R = "note_down-release";
	var ACCEPT = "accept";
	var BACK = "back";
	var PAUSE = "pause";
	var RESET = "reset";
}
#else
@:enum
abstract Action(String) to String from String
{
	var UI_UP = "ui_up";
	var UI_LEFT = "ui_left";
	var UI_RIGHT = "ui_right";
	var UI_DOWN = "ui_down";
	var UI_UP_P = "ui_up-press";
	var UI_LEFT_P = "ui_left-press";
	var UI_RIGHT_P = "ui_right-press";
	var UI_DOWN_P = "ui_down-press";
	var UI_UP_R = "ui_up-release";
	var UI_LEFT_R = "ui_left-release";
	var UI_RIGHT_R = "ui_right-release";
	var UI_DOWN_R = "ui_down-release";
	var NOTE_UP = "note_up";
	var NOTE_LEFT = "note_left";
	var NOTE_RIGHT = "note_right";
	var NOTE_DOWN = "note_down";
	var NOTE_UP_P = "note_up-press";
	var NOTE_LEFT_P = "note_left-press";
	var NOTE_RIGHT_P = "note_right-press";
	var NOTE_DOWN_P = "note_down-press";
	var NOTE_UP_R = "note_up-release";
	var NOTE_LEFT_R = "note_left-release";
	var NOTE_RIGHT_R = "note_right-release";
	var NOTE_DOWN_R = "note_down-release";
	var ACCEPT = "accept";
	var BACK = "back";
	var PAUSE = "pause";
	var RESET = "reset";
}
#end

enum Device
{
	Keys;
	Gamepad(id:Int);
}

/**
 * Since, in many cases multiple actions should use similar keys, we don't want the
 * rebinding UI to list every action. ActionBinders are what the user percieves as
 * an input so, for instance, they can't set jump-press and jump-release to different keys.
 */
enum Control
{
	UI_UP;
	UI_LEFT;
	UI_RIGHT;
	UI_DOWN;
	NOTE_UP;
	NOTE_LEFT;
	NOTE_RIGHT;
	NOTE_DOWN;
	RESET;
	ACCEPT;
	BACK;
	PAUSE;
}

enum KeyboardScheme
{
	Solo;
	Duo(first:Bool);
	None;
	Custom;
}

/**
 * A list of actions that a player would invoke via some input device.
 * Uses FlxActions to funnel various inputs to a single action.
 */
class Controls extends FlxActionSet
{
	var _ui_up:FlxActionDigital = new FlxActionDigital(Action.UI_UP);
	var _ui_left:FlxActionDigital = new FlxActionDigital(Action.UI_LEFT);
	var _ui_right:FlxActionDigital = new FlxActionDigital(Action.UI_RIGHT);
	var _ui_down:FlxActionDigital = new FlxActionDigital(Action.UI_DOWN);
	var _ui_upP:FlxActionDigital = new FlxActionDigital(Action.UI_UP_P);
	var _ui_leftP:FlxActionDigital = new FlxActionDigital(Action.UI_LEFT_P);
	var _ui_rightP:FlxActionDigital = new FlxActionDigital(Action.UI_RIGHT_P);
	var _ui_downP:FlxActionDigital = new FlxActionDigital(Action.UI_DOWN_P);
	var _ui_upR:FlxActionDigital = new FlxActionDigital(Action.UI_UP_R);
	var _ui_leftR:FlxActionDigital = new FlxActionDigital(Action.UI_LEFT_R);
	var _ui_rightR:FlxActionDigital = new FlxActionDigital(Action.UI_RIGHT_R);
	var _ui_downR:FlxActionDigital = new FlxActionDigital(Action.UI_DOWN_R);
	var _note_up:FlxActionDigital = new FlxActionDigital(Action.NOTE_UP);
	var _note_left:FlxActionDigital = new FlxActionDigital(Action.NOTE_LEFT);
	var _note_right:FlxActionDigital = new FlxActionDigital(Action.NOTE_RIGHT);
	var _note_down:FlxActionDigital = new FlxActionDigital(Action.NOTE_DOWN);
	var _note_upP:FlxActionDigital = new FlxActionDigital(Action.NOTE_UP_P);
	var _note_leftP:FlxActionDigital = new FlxActionDigital(Action.NOTE_LEFT_P);
	var _note_rightP:FlxActionDigital = new FlxActionDigital(Action.NOTE_RIGHT_P);
	var _note_downP:FlxActionDigital = new FlxActionDigital(Action.NOTE_DOWN_P);
	var _note_upR:FlxActionDigital = new FlxActionDigital(Action.NOTE_UP_R);
	var _note_leftR:FlxActionDigital = new FlxActionDigital(Action.NOTE_LEFT_R);
	var _note_rightR:FlxActionDigital = new FlxActionDigital(Action.NOTE_RIGHT_R);
	var _note_downR:FlxActionDigital = new FlxActionDigital(Action.NOTE_DOWN_R);
	var _accept:FlxActionDigital = new FlxActionDigital(Action.ACCEPT);
	var _back:FlxActionDigital = new FlxActionDigital(Action.BACK);
	var _pause:FlxActionDigital = new FlxActionDigital(Action.PAUSE);
	var _reset:FlxActionDigital = new FlxActionDigital(Action.RESET);

	#if (haxe >= "4.0.0")
	var byName:Map<String, FlxActionDigital> = [];
	#else
	var byName:Map<String, FlxActionDigital> = new Map<String, FlxActionDigital>();
	#end

	public var gamepadsAdded:Array<Int> = [];
	public var keyboardScheme = KeyboardScheme.None;

	public var UI_UP(get, never):Bool;			inline function get_UI_UP():Bool return _ui_up.check();
	public var UI_LEFT(get, never):Bool;		inline function get_UI_LEFT():Bool return _ui_left.check();
	public var UI_RIGHT(get, never):Bool;		inline function get_UI_RIGHT():Bool return _ui_right.check();
	public var UI_DOWN(get, never):Bool;		inline function get_UI_DOWN():Bool return _ui_down.check();

	public var UI_UP_P(get, never):Bool;		inline function get_UI_UP_P():Bool return _ui_upP.check();
	public var UI_LEFT_P(get, never):Bool;		inline function get_UI_LEFT_P():Bool return _ui_leftP.check();
	public var UI_RIGHT_P(get, never):Bool;		inline function get_UI_RIGHT_P():Bool return _ui_rightP.check();
	public var UI_DOWN_P(get, never):Bool;		inline function get_UI_DOWN_P():Bool return _ui_downP.check();

	public var UI_UP_R(get, never):Bool;		inline function get_UI_UP_R():Bool return _ui_upR.check();
	public var UI_LEFT_R(get, never):Bool;		inline function get_UI_LEFT_R():Bool return _ui_leftR.check();
	public var UI_RIGHT_R(get, never):Bool;		inline function get_UI_RIGHT_R():Bool return _ui_rightR.check();
	public var UI_DOWN_R(get, never):Bool;		inline function get_UI_DOWN_R():Bool return _ui_downR.check();

	public var NOTE_UP(get, never):Bool;		inline function get_NOTE_UP():Bool return _note_up.check();
	public var NOTE_LEFT(get, never):Bool;		inline function get_NOTE_LEFT():Bool return _note_left.check();
	public var NOTE_RIGHT(get, never):Bool;		inline function get_NOTE_RIGHT():Bool return _note_right.check();
	public var NOTE_DOWN(get, never):Bool;		inline function get_NOTE_DOWN():Bool return _note_down.check();

	public var NOTE_UP_P(get, never):Bool;		inline function get_NOTE_UP_P():Bool return _note_upP.check();
	public var NOTE_LEFT_P(get, never):Bool;	inline function get_NOTE_LEFT_P():Bool return _note_leftP.check();
	public var NOTE_RIGHT_P(get, never):Bool;	inline function get_NOTE_RIGHT_P():Bool return _note_rightP.check();
	public var NOTE_DOWN_P(get, never):Bool;	inline function get_NOTE_DOWN_P():Bool return _note_downP.check();

	public var NOTE_UP_R(get, never):Bool;		inline function get_NOTE_UP_R():Bool return _note_upR.check();
	public var NOTE_LEFT_R(get, never):Bool;	inline function get_NOTE_LEFT_R():Bool return _note_leftR.check();
	public var NOTE_RIGHT_R(get, never):Bool;	inline function get_NOTE_RIGHT_R():Bool return _note_rightR.check();
	public var NOTE_DOWN_R(get, never):Bool;	inline function get_NOTE_DOWN_R():Bool return _note_downR.check();

	public var ACCEPT(get, never):Bool;			inline function get_ACCEPT():Bool return _accept.check();
	public var BACK(get, never):Bool;			inline function get_BACK():Bool return _back.check();
	public var PAUSE(get, never):Bool;			inline function get_PAUSE():Bool return _pause.check();
	public var RESET(get, never):Bool;			inline function get_RESET():Bool return _reset.check();

	#if (haxe >= "4.0.0")
	public function new(name:String, scheme:KeyboardScheme = None):Void
	{
		super(name);

		add(_ui_up);
		add(_ui_left);
		add(_ui_right);
		add(_ui_down);
		add(_ui_upP);
		add(_ui_leftP);
		add(_ui_rightP);
		add(_ui_downP);
		add(_ui_upR);
		add(_ui_leftR);
		add(_ui_rightR);
		add(_ui_downR);
		add(_note_up);
		add(_note_left);
		add(_note_right);
		add(_note_down);
		add(_note_upP);
		add(_note_leftP);
		add(_note_rightP);
		add(_note_downP);
		add(_note_upR);
		add(_note_leftR);
		add(_note_rightR);
		add(_note_downR);
		add(_accept);
		add(_back);
		add(_pause);
		add(_reset);

		for (action in digitalActions) {
			byName[action.name] = action;
		}

		setKeyboardScheme(scheme, false);
	}
	#else
	public function new(name:String, scheme:KeyboardScheme = null):Void
	{
		super(name);

		add(_ui_up);
		add(_ui_left);
		add(_ui_right);
		add(_ui_down);
		add(_ui_upP);
		add(_ui_leftP);
		add(_ui_rightP);
		add(_ui_downP);
		add(_ui_upR);
		add(_ui_leftR);
		add(_ui_rightR);
		add(_ui_downR);
		add(_note_up);
		add(_note_left);
		add(_note_right);
		add(_note_down);
		add(_note_upP);
		add(_note_leftP);
		add(_note_rightP);
		add(_note_downP);
		add(_note_upR);
		add(_note_leftR);
		add(_note_rightR);
		add(_note_downR);
		add(_accept);
		add(_back);
		add(_pause);
		add(_reset);

		for (action in digitalActions) {
			byName[action.name] = action;
		}

		if (scheme == null) {
			scheme = None;
		}

		setKeyboardScheme(scheme, false);
	}
	#end

	public override function update():Void
	{
		super.update();
	}

	// inline
	public function checkByName(name:Action):Bool
	{
		#if debug
		if (!byName.exists(name)) throw 'Invalid name: $name';
		#end
		return byName[name].check();
	}

	public function getDialogueName(action:FlxActionDigital):String
	{
		var input:FlxActionInput = action.inputs[0];

		return switch input.device
		{
			case KEYBOARD: return '[${(input.inputID : FlxKey)}]';
			case GAMEPAD: return '(${(input.inputID : FlxGamepadInputID)})';
			case device: throw 'unhandled device: $device';
		}
	}

	public function getDialogueNameFromToken(token:String):String
	{
		return getDialogueName(getActionFromControl(Control.createByName(token.toUpperCase())));
	}

	function getActionFromControl(control:Control):FlxActionDigital
	{
		return switch (control)
		{
			case UI_UP: _ui_up;
			case UI_DOWN: _ui_down;
			case UI_LEFT: _ui_left;
			case UI_RIGHT: _ui_right;
			case NOTE_UP: _note_up;
			case NOTE_DOWN: _note_down;
			case NOTE_LEFT: _note_left;
			case NOTE_RIGHT: _note_right;
			case ACCEPT: _accept;
			case BACK: _back;
			case PAUSE: _pause;
			case RESET: _reset;
		}
	}

	static function init():Void
	{
		var actions = new FlxActionManager();
		FlxG.inputs.add(actions);
	}

	/**
	 * Calls a function passing each action bound by the specified control
	 * @param control
	 * @param func
	 * @return ->Void)
	 */
	function forEachBound(control:Control, func:FlxActionDigital->FlxInputState->Void):Void
	{
		switch (control)
		{
			case UI_UP:
			{
				func(_ui_up, PRESSED);
				func(_ui_upP, JUST_PRESSED);
				func(_ui_upR, JUST_RELEASED);
			}
			case UI_LEFT:
			{
				func(_ui_left, PRESSED);
				func(_ui_leftP, JUST_PRESSED);
				func(_ui_leftR, JUST_RELEASED);
			}
			case UI_RIGHT:
			{
				func(_ui_right, PRESSED);
				func(_ui_rightP, JUST_PRESSED);
				func(_ui_rightR, JUST_RELEASED);
			}
			case UI_DOWN:
			{
				func(_ui_down, PRESSED);
				func(_ui_downP, JUST_PRESSED);
				func(_ui_downR, JUST_RELEASED);
			}
			case NOTE_UP:
			{
				func(_note_up, PRESSED);
				func(_note_upP, JUST_PRESSED);
				func(_note_upR, JUST_RELEASED);
			}
			case NOTE_LEFT:
			{
				func(_note_left, PRESSED);
				func(_note_leftP, JUST_PRESSED);
				func(_note_leftR, JUST_RELEASED);
			}
			case NOTE_RIGHT:
			{
				func(_note_right, PRESSED);
				func(_note_rightP, JUST_PRESSED);
				func(_note_rightR, JUST_RELEASED);
			}
			case NOTE_DOWN:
			{
				func(_note_down, PRESSED);
				func(_note_downP, JUST_PRESSED);
				func(_note_downR, JUST_RELEASED);
			}
			case ACCEPT:
			{
				func(_accept, JUST_PRESSED);
			}
			case BACK:
			{
				func(_back, JUST_PRESSED);
			}
			case PAUSE:
			{
				func(_pause, JUST_PRESSED);
			}
			case RESET:
			{
				func(_reset, JUST_PRESSED);
			}
		}
	}

	public function replaceBinding(control:Control, device:Device, ?toAdd:Int, ?toRemove:Int):Void
	{
		if (toAdd == toRemove) return;

		switch (device)
		{
			case Keys:
			{
				if (toRemove != null) unbindKeys(control, [toRemove]);
				if (toAdd != null) bindKeys(control, [toAdd]);
			}
			case Gamepad(id):
			{
				if (toRemove != null) unbindButtons(control, id, [toRemove]);
				if (toAdd != null) bindButtons(control, id, [toAdd]);
			}
		}
	}

	public function copyFrom(controls:Controls, ?device:Device):Void
	{
		#if (haxe >= "4.0.0")
		for (name => action in controls.byName)
		{
			for (input in action.inputs)
			{
				if (device == null || isDevice(input, device)) {
					byName[name].add(cast input);
				}
			}
		}
		#else
		for (name in controls.byName.keys())
		{
			var action:FlxActionDigital = controls.byName[name];

			for (input in action.inputs)
			{
				if (device == null || isDevice(input, device))
				byName[name].add(cast input);
			}
		}
		#end

		switch (device)
		{
			case null: // add all
			{
				#if (haxe >= "4.0.0")
				for (gamepad in controls.gamepadsAdded)
				{
					if (!gamepadsAdded.contains(gamepad)) {
						gamepadsAdded.push(gamepad);
					}
				}
				#else
				for (gamepad in controls.gamepadsAdded)
				{
					if (gamepadsAdded.indexOf(gamepad) == -1) {
						gamepadsAdded.push(gamepad);
					}
				}
				#end

				mergeKeyboardScheme(controls.keyboardScheme);
			}
			case Gamepad(id):
			{
				gamepadsAdded.push(id);
			}
			case Keys:
			{
				mergeKeyboardScheme(controls.keyboardScheme);
			}
		}
	}

	inline public function copyTo(controls:Controls, ?device:Device):Void
	{
		controls.copyFrom(this, device);
	}

	function mergeKeyboardScheme(scheme:KeyboardScheme):Void
	{
		if (scheme != None)
		{
			switch (keyboardScheme)
			{
				case None: keyboardScheme = scheme;
				default: keyboardScheme = Custom;
			}
		}
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public function bindKeys(control:Control, keys:Array<FlxKey>):Void
	{
		var copyKeys:Array<FlxKey> = keys.copy();

		for (i in 0...copyKeys.length) {
			if (i == NONE) copyKeys.remove(i);
		}

		#if (haxe >= "4.0.0")
		inline forEachBound(control, (action:FlxActionDigital, state) -> addKeys(action, copyKeys, state));
		#else
		forEachBound(control, function(action:FlxActionDigital, state):Void addKeys(action, copyKeys, state));
		#end
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public function unbindKeys(control:Control, keys:Array<FlxKey>):Void
	{
		var copyKeys:Array<FlxKey> = keys.copy();

		for (i in 0...copyKeys.length) {
			if (i == NONE) copyKeys.remove(i);
		}

		#if (haxe >= "4.0.0")
		inline forEachBound(control, (action:FlxActionDigital, _) -> removeKeys(action, copyKeys));
		#else
		forEachBound(control, function(action:FlxActionDigital, _):Void removeKeys(action, copyKeys));
		#end
	}

	inline static function addKeys(action:FlxActionDigital, keys:Array<FlxKey>, state:FlxInputState):Void
	{
		for (key in keys)
		{
			if (key != NONE) action.addKey(key, state);
		}
	}

	static function removeKeys(action:FlxActionDigital, keys:Array<FlxKey>):Void
	{
		var i:Int = action.inputs.length;

		while (i-- > 0)
		{
			var input:FlxActionInput = action.inputs[i];

			if (input.device == KEYBOARD && keys.indexOf(cast input.inputID) != -1) {
				action.remove(input);
			}
		}
	}

	public function setKeyboardScheme(scheme:KeyboardScheme, reset:Bool = true):Void
	{
		if (reset) {
			removeKeyboard();
		}

		keyboardScheme = scheme;

		var keysMap:Map<String, Array<FlxKey>> = OptionData.keyBinds;
		
		#if (haxe >= "4.0.0")
		switch (scheme)
		{
			case Solo:
			{
				inline bindKeys(Control.UI_UP, keysMap.get('ui_up'));
				inline bindKeys(Control.UI_DOWN, keysMap.get('ui_down'));
				inline bindKeys(Control.UI_LEFT, keysMap.get('ui_left'));
				inline bindKeys(Control.UI_RIGHT, keysMap.get('ui_right'));
				inline bindKeys(Control.NOTE_UP, keysMap.get('note_up'));
				inline bindKeys(Control.NOTE_DOWN, keysMap.get('note_down'));
				inline bindKeys(Control.NOTE_LEFT, keysMap.get('note_left'));
				inline bindKeys(Control.NOTE_RIGHT, keysMap.get('note_right'));

				inline bindKeys(Control.ACCEPT, keysMap.get('accept'));
				inline bindKeys(Control.BACK, keysMap.get('back'));
				inline bindKeys(Control.PAUSE, keysMap.get('pause'));
				inline bindKeys(Control.RESET, keysMap.get('reset'));
			}
			case Duo(true):
			{
				inline bindKeys(Control.UI_UP, [W]);
				inline bindKeys(Control.UI_DOWN, [S]);
				inline bindKeys(Control.UI_LEFT, [A]);
				inline bindKeys(Control.UI_RIGHT, [D]);
				inline bindKeys(Control.NOTE_UP, [W]);
				inline bindKeys(Control.NOTE_DOWN, [S]);
				inline bindKeys(Control.NOTE_LEFT, [A]);
				inline bindKeys(Control.NOTE_RIGHT, [D]);
				inline bindKeys(Control.ACCEPT, [G, Z]);
				inline bindKeys(Control.BACK, [H, X]);
				inline bindKeys(Control.PAUSE, [ONE]);
				inline bindKeys(Control.RESET, [R]);
			}
			case Duo(false):
			{
				inline bindKeys(Control.UI_UP, [FlxKey.UP]);
				inline bindKeys(Control.UI_DOWN, [FlxKey.DOWN]);
				inline bindKeys(Control.UI_LEFT, [FlxKey.LEFT]);
				inline bindKeys(Control.UI_RIGHT, [FlxKey.RIGHT]);
				inline bindKeys(Control.NOTE_UP, [FlxKey.UP]);
				inline bindKeys(Control.NOTE_DOWN, [FlxKey.DOWN]);
				inline bindKeys(Control.NOTE_LEFT, [FlxKey.LEFT]);
				inline bindKeys(Control.NOTE_RIGHT, [FlxKey.RIGHT]);
				inline bindKeys(Control.ACCEPT, [O]);
				inline bindKeys(Control.BACK, [P]);
				inline bindKeys(Control.PAUSE, [ENTER]);
				inline bindKeys(Control.RESET, [BACKSPACE]);
			}
			case None: // nothing
			case Custom: // nothing
		}
		#else
		switch (scheme)
		{
			case Solo:
				bindKeys(Control.UI_UP, [W, FlxKey.UP]);
				bindKeys(Control.UI_DOWN, [S, FlxKey.DOWN]);
				bindKeys(Control.UI_LEFT, [A, FlxKey.LEFT]);
				bindKeys(Control.UI_RIGHT, [D, FlxKey.RIGHT]);
				bindKeys(Control.NOTE_UP, [W, FlxKey.UP]);
				bindKeys(Control.NOTE_DOWN, [S, FlxKey.DOWN]);
				bindKeys(Control.NOTE_LEFT, [A, FlxKey.LEFT]);
				bindKeys(Control.NOTE_RIGHT, [D, FlxKey.RIGHT]);
				bindKeys(Control.ACCEPT, [Z, SPACE, ENTER]);
				bindKeys(Control.BACK, [BACKSPACE, ESCAPE]);
				bindKeys(Control.PAUSE, [P, ENTER, ESCAPE]);
				bindKeys(Control.RESET, [R]);
			case Duo(true):
			{
				bindKeys(Control.UI_UP, [W]);
				bindKeys(Control.UI_DOWN, [S]);
				bindKeys(Control.UI_LEFT, [A]);
				bindKeys(Control.UI_RIGHT, [D]);
				bindKeys(Control.NOTE_UP, [W]);
				bindKeys(Control.NOTE_DOWN, [S]);
				bindKeys(Control.NOTE_LEFT, [A]);
				bindKeys(Control.NOTE_RIGHT, [D]);
				bindKeys(Control.ACCEPT, [G, Z]);
				bindKeys(Control.BACK, [H, X]);
				bindKeys(Control.PAUSE, [ONE]);
				bindKeys(Control.RESET, [R]);
			}
			case Duo(false):
			{
				bindKeys(Control.UI_UP, [FlxKey.UP]);
				bindKeys(Control.UI_DOWN, [FlxKey.DOWN]);
				bindKeys(Control.UI_LEFT, [FlxKey.LEFT]);
				bindKeys(Control.UI_RIGHT, [FlxKey.RIGHT]);
				bindKeys(Control.NOTE_UP, [FlxKey.UP]);
				bindKeys(Control.NOTE_DOWN, [FlxKey.DOWN]);
				bindKeys(Control.NOTE_LEFT, [FlxKey.LEFT]);
				bindKeys(Control.NOTE_RIGHT, [FlxKey.RIGHT]);
				bindKeys(Control.ACCEPT, [O]);
				bindKeys(Control.BACK, [P]);
				bindKeys(Control.PAUSE, [ENTER]);
				bindKeys(Control.RESET, [BACKSPACE]);
			}
			case None: // nothing
			case Custom: // nothing
		}
		#end
	}

	function removeKeyboard():Void
	{
		for (action in this.digitalActions)
		{
			var i:Int = action.inputs.length;

			while (i-- > 0)
			{
				var input:FlxActionInput = action.inputs[i];

				if (input.device == KEYBOARD) {
					action.remove(input);
				}
			}
		}
	}

	public function addGamepad(id:Int, ?buttonMap:Map<Control, Array<FlxGamepadInputID>>):Void
	{
		gamepadsAdded.push(id);
		
		#if (haxe >= "4.0.0")
		for (control => buttons in buttonMap) inline bindButtons(control, id, buttons);
		#else
		for (control in buttonMap.keys()) bindButtons(control, id, buttonMap[control]);
		#end
	}

	inline function addGamepadLiteral(id:Int, ?buttonMap:Map<Control, Array<FlxGamepadInputID>>):Void
	{
		gamepadsAdded.push(id);

		#if (haxe >= "4.0.0")
		for (control => buttons in buttonMap) inline bindButtons(control, id, buttons);
		#else
		for (control in buttonMap.keys()) bindButtons(control, id, buttonMap[control]);
		#end
	}

	public function removeGamepad(deviceID:Int = FlxInputDeviceID.ALL):Void
	{
		for (action in this.digitalActions)
		{
			var i:Int = action.inputs.length;

			while (i-- > 0)
			{
				var input:FlxActionInput = action.inputs[i];

				if (input.device == GAMEPAD && (deviceID == FlxInputDeviceID.ALL || input.deviceID == deviceID)) {
					action.remove(input);
				}
			}
		}

		gamepadsAdded.remove(deviceID);
	}

	public function addDefaultGamepad(id:Int):Void
	{
		#if !switch
		addGamepadLiteral(id, [
			Control.ACCEPT => [A, START],
			Control.BACK => [B],
			Control.UI_UP => [DPAD_UP, LEFT_STICK_DIGITAL_UP],
			Control.UI_DOWN => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN],
			Control.UI_LEFT => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT],
			Control.UI_RIGHT => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT],
			Control.NOTE_UP => [DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP, Y],
			Control.NOTE_DOWN => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN, A],
			Control.NOTE_LEFT => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT, X],
			Control.NOTE_RIGHT => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT, B],
			Control.PAUSE => [START],
			Control.RESET => [8]
		]);
		#else
		addGamepadLiteral(id, [ // Swap A and B for switch
			Control.ACCEPT => [B, START],
			Control.BACK => [A],
			Control.UI_UP => [DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP],
			Control.UI_DOWN => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN],
			Control.UI_LEFT => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT],
			Control.UI_RIGHT => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT],
			Control.NOTE_UP => [DPAD_UP, LEFT_STICK_DIGITAL_UP, RIGHT_STICK_DIGITAL_UP, X],
			Control.NOTE_DOWN => [DPAD_DOWN, LEFT_STICK_DIGITAL_DOWN, RIGHT_STICK_DIGITAL_DOWN, B],
			Control.NOTE_LEFT => [DPAD_LEFT, LEFT_STICK_DIGITAL_LEFT, RIGHT_STICK_DIGITAL_LEFT, Y],
			Control.NOTE_RIGHT => [DPAD_RIGHT, LEFT_STICK_DIGITAL_RIGHT, RIGHT_STICK_DIGITAL_RIGHT, A],
			Control.PAUSE => [START],
			Control.RESET => [8],
		]);
		#end
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public function bindButtons(control:Control, id:Int, buttons:Array<FlxGamepadInputID>):Void
	{
		#if (haxe >= "4.0.0")
		inline forEachBound(control, (action:FlxActionDigital, state:FlxInputState) -> addButtons(action, buttons, state, id));
		#else
		forEachBound(control, function(action:FlxActionDigital, state:FlxInputState):Void addButtons(action, buttons, state, id));
		#end
	}

	/**
	 * Sets all actions that pertain to the binder to trigger when the supplied keys are used.
	 * If binder is a literal you can inline this
	 */
	public function unbindButtons(control:Control, gamepadID:Int, buttons:Array<FlxGamepadInputID>):Void
	{
		#if (haxe >= "4.0.0")
		inline forEachBound(control, (action:FlxActionDigital, _) -> removeButtons(action, gamepadID, buttons));
		#else
		forEachBound(control, function(action:FlxActionDigital, _):Void removeButtons(action, gamepadID, buttons));
		#end
	}

	inline static function addButtons(action:FlxActionDigital, buttons:Array<FlxGamepadInputID>, state:FlxInputState, id:Int):Void
	{
		for (button in buttons) action.addGamepad(button, state, id);
	}

	static function removeButtons(action:FlxActionDigital, gamepadID:Int, buttons:Array<FlxGamepadInputID>):Void
	{
		var i:Int = action.inputs.length;

		while (i-- > 0)
		{
			var input = action.inputs[i];
			if (isGamepad(input, gamepadID) && buttons.indexOf(cast input.inputID) != -1) {
				action.remove(input);
			}
		}
	}

	public function getInputsFor(control:Control, device:Device, ?list:Array<Int>):Array<Int>
	{
		if (list == null) list = [];

		switch (device)
		{
			case Keys:
			{
				for (input in getActionFromControl(control).inputs)
				{
					if (input.device == KEYBOARD) {
						list.push(input.inputID);
					}
				}
			}
			case Gamepad(id):
			{
				for (input in getActionFromControl(control).inputs)
				{
					if (input.deviceID == id) {
						list.push(input.inputID);
					}
				}
			}
		}

		return list;
	}

	public function removeDevice(device:Device):Void
	{
		switch (device)
		{
			case Keys: setKeyboardScheme(None);
			case Gamepad(id): removeGamepad(id);
		}
	}

	static function isDevice(input:FlxActionInput, device:Device):Bool
	{
		return switch device
		{
			case Keys: input.device == KEYBOARD;
			case Gamepad(id): isGamepad(input, id);
		}
	}

	inline static function isGamepad(input:FlxActionInput, deviceID:Int):Bool
	{
		return input.device == GAMEPAD && (deviceID == FlxInputDeviceID.ALL || input.deviceID == deviceID);
	}
}