package;

import flixel.FlxG;
import flixel.input.gamepad.FlxGamepadInputID;

using StringTools;

class Controls
{
	public static var player1:Controls = null;
	public static var player2:Controls = null;

	public static var instance:Controls = null;

	public function new():Void {}

	public var UI_LEFT_P(get, never):Bool;		private function get_UI_LEFT_P():Bool return justPressed('ui_left');
	public var UI_DOWN_P(get, never):Bool;		private function get_UI_DOWN_P():Bool return justPressed('ui_down');
	public var UI_UP_P(get, never):Bool;		private function get_UI_UP_P():Bool return justPressed('ui_up');
	public var UI_RIGHT_P(get, never):Bool;		private function get_UI_RIGHT_P():Bool return justPressed('ui_right');
	public var UI_LEFT(get, never):Bool;		private function get_UI_LEFT():Bool return pressed('ui_left');
	public var UI_DOWN(get, never):Bool;		private function get_UI_DOWN():Bool return pressed('ui_down');
	public var UI_UP(get, never):Bool;			private function get_UI_UP():Bool return pressed('ui_up');
	public var UI_RIGHT(get, never):Bool;		private function get_UI_RIGHT():Bool return pressed('ui_right');
	public var UI_LEFT_R(get, never):Bool;		private function get_UI_LEFT_R():Bool return justReleased('ui_left');
	public var UI_DOWN_R(get, never):Bool;		private function get_UI_DOWN_R():Bool return justReleased('ui_down');
	public var UI_UP_R(get, never):Bool;		private function get_UI_UP_R():Bool return justReleased('ui_up');
	public var UI_RIGHT_R(get, never):Bool;		private function get_UI_RIGHT_R():Bool return justReleased('ui_right');

	public var NOTE_LEFT_P(get, never):Bool;	private function get_NOTE_LEFT_P():Bool return justPressed('note_left');
	public var NOTE_DOWN_P(get, never):Bool;	private function get_NOTE_DOWN_P():Bool return justPressed('note_down');
	public var NOTE_UP_P(get, never):Bool;		private function get_NOTE_UP_P():Bool return justPressed('note_up');
	public var NOTE_RIGHT_P(get, never):Bool;	private function get_NOTE_RIGHT_P():Bool return justPressed('note_right');
	public var NOTE_LEFT(get, never):Bool;		private function get_NOTE_LEFT():Bool return pressed('note_left');
	public var NOTE_DOWN(get, never):Bool;		private function get_NOTE_DOWN():Bool return pressed('note_down');
	public var NOTE_UP(get, never):Bool;		private function get_NOTE_UP():Bool return pressed('note_up');
	public var NOTE_RIGHT(get, never):Bool;		private function get_NOTE_RIGHT():Bool return pressed('note_right');
	public var NOTE_LEFT_R(get, never):Bool;	private function get_NOTE_LEFT_R():Bool return justReleased('note_left');
	public var NOTE_DOWN_R(get, never):Bool;	private function get_NOTE_DOWN_R():Bool return justReleased('note_down');
	public var NOTE_UP_R(get, never):Bool;		private function get_NOTE_UP_R():Bool return justReleased('note_up');
	public var NOTE_RIGHT_R(get, never):Bool;	private function get_NOTE_RIGHT_R():Bool return justReleased('note_right');

	public var RESET(get, never):Bool;			private function get_RESET():Bool return justPressed('reset');
	public var ACCEPT(get, never):Bool;			private function get_ACCEPT():Bool return justPressed('accept');
	public var BACK(get, never):Bool;			private function get_BACK():Bool return justPressed('back');
	public var PAUSE(get, never):Bool;			private function get_PAUSE():Bool return justPressed('pause');
	public var RESET_P(get, never):Bool;		private function get_RESET_P():Bool return pressed('reset');
	public var ACCEPT_P(get, never):Bool;		private function get_ACCEPT_P():Bool return pressed('accept');
	public var BACK_P(get, never):Bool;			private function get_BACK_P():Bool return pressed('back');
	public var PAUSE_P(get, never):Bool;		private function get_PAUSE_P():Bool return pressed('pause');
	public var RESET_R(get, never):Bool;		private function get_RESET_R():Bool return justReleased('reset');
	public var ACCEPT_R(get, never):Bool;		private function get_ACCEPT_R():Bool return justReleased('accept');
	public var BACK_R(get, never):Bool;			private function get_BACK_R():Bool return justReleased('back');
	public var PAUSE_R(get, never):Bool;		private function get_PAUSE_R():Bool return justReleased('pause');

	public var controllerMode:Bool = false;

	public function justPressed(key:String):Bool
	{
		var result:Bool = (FlxG.keys.anyJustPressed(OptionData.keyBinds.get(key)) == true);
		if (result) controllerMode = false;

		return result || _myGamepadJustPressed(OptionData.gamepadBinds.get(key)) == true;
	}

	public function pressed(key:String):Bool
	{
		var result:Bool = (FlxG.keys.anyPressed(OptionData.keyBinds.get(key)) == true);
		if (result) controllerMode = false;

		return result || _myGamepadPressed(OptionData.gamepadBinds.get(key)) == true;
	}

	public function justReleased(key:String):Bool
	{
		var result:Bool = (FlxG.keys.anyJustReleased(OptionData.keyBinds.get(key)) == true);
		if (result) controllerMode = false;

		return result || _myGamepadJustReleased(OptionData.gamepadBinds.get(key)) == true;
	}

	private function _myGamepadJustPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if (keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyJustPressed(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}

		return false;
	}

	private function _myGamepadPressed(keys:Array<FlxGamepadInputID>):Bool
	{
		if (keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyPressed(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}

		return false;
	}

	private function _myGamepadJustReleased(keys:Array<FlxGamepadInputID>):Bool
	{
		if (keys != null)
		{
			for (key in keys)
			{
				if (FlxG.gamepads.anyJustReleased(key) == true)
				{
					controllerMode = true;
					return true;
				}
			}
		}

		return false;
	}
}