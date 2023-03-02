package;

import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;

using StringTools;

class WarningState extends MusicBeatState
{
	override function create():Void
	{
		super.create();

		var txt:FlxText = new FlxText(0, 0, FlxG.width, "WARNING!\n\nAlsuh Engine will soon stop supporting\nfile extensions such as .OGG, .WAV, .WEBM."
			+ "\n\nModcharters who have chosen this engine, you\nmust replace the old file extensions with the new ones.\n\nSound files must be .MP3."
			+ "\nVideo files must be .MP4.\n\nPress ENTER to play new mods with optimized new formats.\nor press ESCAPE to keep playing mods with older file formats.", 32);
		txt.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txt.scrollFactor.set();
		txt.screenCenter();
		txt.borderSize = 2.4;
		add(txt);
	}

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var back:Bool = controls.BACK || FlxG.mouse.justPressedRight;

		if ((controls.ACCEPT || FlxG.mouse.justPressed) || back)
		{
			FlxG.save.data.seenWarningExt = true;

			if (back)
			{
				OptionData.loadingOggFiles = true;
				OptionData.loadingWavFiles = true;
				OptionData.savePrefs();
			}

			FlxG.switchState(new MainMenuState());
			FlxG.sound.play(Paths.getSound('cancelMenu'));
		}
	}
}