package;

#if hscript
import hscript.Expr;
import hscript.Parser;
import hscript.Interp;
#end

import FunkinLua;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

#if (!flash && sys)
import openfl.filters.ShaderFilter;
import flixel.addons.display.FlxRuntimeShader;
#end

using StringTools;

#if hscript
class HScript
{
	public static var parser:Parser = new Parser();
	public var interp:Interp;

	public var variables(get, never):Map<String, Dynamic>;

	public function get_variables():Map<String, Dynamic>
	{
		return interp.variables;
	}

	public function new():Void
	{
		interp = new Interp();
		interp.variables.set('FlxG', FlxG);
		interp.variables.set('FlxSprite', FlxSprite);
		interp.variables.set('FlxCamera', FlxCamera);
		interp.variables.set('FlxTimer', FlxTimer);
		interp.variables.set('FlxTween', FlxTween);
		interp.variables.set('FlxEase', FlxEase);
		interp.variables.set('PlayState', PlayState);
		interp.variables.set('SwagCamera', SwagCamera);
		interp.variables.set('game', PlayState.instance);
		interp.variables.set('Paths', Paths);
		interp.variables.set('Conductor', Conductor);
		interp.variables.set('OptionData', OptionData);
		interp.variables.set('ClientPrefs', OptionData);
		interp.variables.set('Character', Character);
		interp.variables.set('Alphabet', Alphabet);
		interp.variables.set('CustomSubState', CustomSubState);
		interp.variables.set('CustomSubstate', CustomSubState);
		#if (!flash && sys)
		interp.variables.set('FlxRuntimeShader', FlxRuntimeShader);
		interp.variables.set('ShaderFilter', ShaderFilter);
		#end
		interp.variables.set('StringTools', StringTools);

		interp.variables.set('setVar', function(name:String, value:Dynamic):Void
		{
			PlayState.instance.variables.set(name, value);
		});

		interp.variables.set('getVar', function(name:String):Dynamic
		{
			var result:Dynamic = PlayState.instance.variables.exists(name) ? PlayState.instance.variables.get(name) : null;
			return result;
		});

		interp.variables.set('removeVar', function(name:String):Bool
		{
			return PlayState.instance.variables.remove(name);
		});
	}

	public function execute(codeToRun:String):Dynamic
	{
		@:privateAccess
		HScript.parser.line = 1;
		HScript.parser.allowTypes = true;
		var expr:Expr = HScript.parser.parseString(codeToRun);
		return interp.execute(expr);
	}
}
#end