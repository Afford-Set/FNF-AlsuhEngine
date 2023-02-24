package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.system.FlxSound;

using StringTools;

class GameOverSubState extends MusicBeatSubState
{
	public static var instance:GameOverSubState = null;

	public var boyfriend:Boyfriend;

	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;

	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;

	public static var colorStartFlash:FlxColor = FlxColor.RED;
	public static var colorFlash:FlxColor = FlxColor.WHITE;
	public static var colorConfirmFlash:FlxColor = 0x85FFFFFF;
	public static var flashStart:Float = 1;
	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static function resetVariables():Void
	{
		colorStartFlash = FlxColor.RED;
		colorFlash = FlxColor.WHITE;
		colorConfirmFlash = 0x85FFFFFF;
		flashStart = 1;
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}

	public override function create():Void
	{
		super.create();

		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);
	}

	var bg:FlxSprite;

	public function new(x:Float, y:Float):Void
	{
		super();

		FlxG.camera.fade(FlxColor.WHITE, 0.01, true);
		FlxG.camera.flash(FlxColor.WHITE, 0.01);

		PlayState.instance.setOnLuas('inGameOver', true);

		Conductor.changeBPM(100);
		Conductor.songPosition = 0;

		bg = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, FlxColor.WHITE);
		bg.scrollFactor.set();
		bg.scale.set(250, 250);
		bg.screenCenter();
		bg.color = colorStartFlash;
		bg.alpha = 1 - (OptionData.flashingLights ? 0 : 0.5);
		add(bg);

		boyfriend = new Boyfriend(x, y, characterName);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);

		var deathSound:FlxSound = new FlxSound();
		deathSound.loadEmbedded(Paths.getSound(deathSoundName), false, true);
		deathSound.play();
		FlxG.sound.list.add(deathSound);
		@:privateAccess
		if (deathSound._paused) deathSound.resume();

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);

		new FlxTimer().start(flashStart, function(tmr:FlxTimer):Void
		{
			bg.color = colorFlash;
			bg.alpha = 1 - (OptionData.flashingLights ? 0 : 0.5);

			micIsDown = true;
		});
	}

	public var micIsDown:Bool = false;
	var isFollowingAlready:Bool = false;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		bg.alpha = CoolUtil.coolLerp(bg.alpha, 0, 0.01);

		if (updateCamera) {
			camFollowPos.setPosition(CoolUtil.coolLerp(camFollowPos.x, camFollow.x, 0.025), CoolUtil.coolLerp(camFollowPos.y, camFollow.y, 0.025));
		}

		var exit:Bool = controls.BACK || FlxG.mouse.justPressedRight;

		if ((controls.ACCEPT || FlxG.mouse.justPressed) || exit) {
			endBullshit(exit);
		}

		if (boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name == 'firstDeath')
		{
			if (boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
			{
				FlxG.camera.follow(camFollowPos, LOCKON, 1);

				updateCamera = true;
				isFollowingAlready = true;
			}

			if (boyfriend.animation.curAnim.finished && !playingDeathSound)
			{
				if (OptionData.naughtyness && PlayState.SONG.stage == 'tank' && (PlayState.SONG.player2.contains('tankman') || PlayState.SONG.player2.contains('tankmen')))
				{
					playingDeathSound = true;
					coolStartDeath(0.2);
					
					var exclude:Array<Int> = [];

					FlxG.sound.play(Paths.getSound('jeffGameover/jeffGameover-' + FlxG.random.int(1, 25, exclude)), 1, false, null, true, function():Void
					{
						if (!isEnding) {
							FlxG.sound.music.fadeIn(4, 0.2, 1);
						}
					});
				}
				else {
					coolStartDeath(1);
				}

				boyfriend.startedDeath = true;
			}
		}

		if (FlxG.sound.music != null && FlxG.sound.music.playing) {
			Conductor.songPosition = FlxG.sound.music.time;
		}

		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	function coolStartDeath(?volume:Float = 1):Void
	{
		FlxG.sound.playMusic(Paths.getMusic(loopSoundName), volume);
	}

	var isEnding:Bool = false;

	function endBullshit(toMenu:Bool = false):Void
	{
		if (!isEnding)
		{
			isEnding = true;

			bg.alpha = 0.5 - (OptionData.flashingLights ? 0 : 0.3);
			bg.color = colorConfirmFlash;

			boyfriend.playAnim('deathConfirm', true);

			FlxG.sound.music.stop();

			var deathSound:FlxSound = new FlxSound();
			deathSound.loadEmbedded(Paths.getMusic(endSoundName), false, true);
			deathSound.play();
			FlxG.sound.list.add(deathSound);
			@:privateAccess
			if (deathSound._paused) deathSound.resume();

			new FlxTimer().start(0.7, function(tmr:FlxTimer):Void
			{
				FlxG.camera.fade(FlxColor.BLACK, 2, false, function():Void
				{
					if (toMenu)
					{
						PlayState.deathCounter = 0;

						PlayState.seenCutscene = false;
						PlayState.chartingMode = false;

						WeekData.loadTheFirstEnabledMod();

						switch (PlayState.gameMode)
						{
							case 'story': FlxG.switchState(new StoryMenuState());
							case 'freeplay': FlxG.switchState(new FreeplayMenuState());
							#if REPLAYS_ALLOWED
							case 'replay':
							{
								Replay.resetVariables();
								FlxG.switchState(new options.ReplaysMenuState());
							}
							#end
							default: FlxG.switchState(new MainMenuState());
						}
					}
					else {
						FlxG.resetState();
					}
				});
			});

			if (toMenu) {
				PlayState.instance.callOnLuas('onExitFromGameOver', [true]);
			}
			else {
				PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
			}
		}
	}
}
