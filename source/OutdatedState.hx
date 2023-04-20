package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;

using StringTools;

#if CHECK_FOR_UPDATES
class OutdatedState extends MusicBeatState
{
	public static var leftState:Bool = false;

	private var bg:FlxSprite;
	private var txt:FlxText;

	public override function create():Void
	{
		super.create();

		bg = new FlxSprite();

		if (Paths.fileExists('images/menuDesat.png', IMAGE)) {
			bg.loadGraphic(Paths.getImage('menuDesat'));
		}
		else {
			bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		}

		bg.antialiasing = OptionData.globalAntialiasing;
		bg.color = 0xFF0F0F0F;
		add(bg);

		txt = new FlxText(0, 0, FlxG.width, "Your used version " + MainMenuState.engineVersion.trim() + "\nof Alsuh Engine is outdated."
			+ "\nUse the latest version " + TitleState.updateVersion.trim() + " instead."
			+ "\n\nWhat new?\n\n" + TitleState.updateChanges + "\n\nPress ENTER to download latest version\nor ESCAPE to ignore this message.", 32);
		txt.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		txt.scrollFactor.set();
		txt.screenCenter();
		txt.borderSize = 2.4;
		add(txt);
	}

	public override function update(elapsed:Float):Void
	{
		if (!leftState)
		{
			if (controls.ACCEPT || FlxG.mouse.justPressed)
			{
				leftState = true;
				CoolUtil.browserLoad('https://github.com/Afford-Set/FNF-AlsuhEngine/releases/latest');
			}

			if (controls.BACK || FlxG.mouse.justPressedRight) {
				leftState = true;
			}

			if (leftState)
			{
				FlxTween.tween(txt, {alpha: 0}, 1,
				{
					onComplete: function(twn:FlxTween):Void {
						FlxG.switchState(new MainMenuState());
					}
				});

				FlxTween.tween(bg, {alpha: 0}, 0.5);
				FlxG.sound.play(Paths.getSound('cancelMenu'));
			}
		}

		super.update(elapsed);
	}
}
#end