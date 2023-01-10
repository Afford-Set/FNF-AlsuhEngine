package;

import Controls;
import flixel.FlxG;
import flixel.util.FlxSignal;
import flixel.input.gamepad.FlxGamepad;

using StringTools;

class PlayerSettings
{
	public static var numPlayers(default, null):Int = 0;
	public static var numAvatars(default, null):Int = 0;

	public static var player1(default, null):PlayerSettings;
	public static var player2(default, null):PlayerSettings;

	#if (haxe >= "4.0.0")
	public static final onAvatarAdd:FlxTypedSignal<PlayerSettings->Void> = new FlxTypedSignal<PlayerSettings->Void>();
	public static final onAvatarRemove:FlxTypedSignal<PlayerSettings->Void> = new FlxTypedSignal<PlayerSettings->Void>();
	#else
	public static var onAvatarAdd:FlxTypedSignal<PlayerSettings->Void> = new FlxTypedSignal<PlayerSettings->Void>();
	public static var onAvatarRemove:FlxTypedSignal<PlayerSettings->Void> = new FlxTypedSignal<PlayerSettings->Void>();
	#end

	public var id(default, null):Int;

	#if (haxe >= "4.0.0")
	public final controls:Controls;
	#else
	public var controls:Controls;
	#end

	function new(id:Int, scheme:KeyboardScheme):Void
	{
		this.id = id;
		this.controls = new Controls('player$id', scheme);
	}

	public function setKeyboardScheme(scheme):Void
	{
		controls.setKeyboardScheme(scheme);
	}

	public static function init():Void
	{
		if (player1 == null)
		{
			player1 = new PlayerSettings(0, Solo);
			++numPlayers;
		}

		var numGamepads = FlxG.gamepads.numActiveGamepads;

		if (numGamepads > 0)
		{
			var gamepad:FlxGamepad = FlxG.gamepads.getByID(0);
	
			if (gamepad == null) {
				throw 'Unexpected null gamepad. id:0';
			}

			player1.controls.addDefaultGamepad(0);
		}

		if (numGamepads > 1)
		{
			if (player2 == null)
			{
				player2 = new PlayerSettings(1, None);
				++numPlayers;
			}

			var gamepad:FlxGamepad = FlxG.gamepads.getByID(1);

			if (gamepad == null) {
				throw 'Unexpected null gamepad. id:0';
			}

			player2.controls.addDefaultGamepad(1);
		}
	}

	public static function reset():Void
	{
		player1 = null;
		player2 = null;

		numPlayers = 0;
	}
}
