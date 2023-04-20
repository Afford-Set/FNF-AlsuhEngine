package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

using StringTools;

typedef GameOverSubstate = GameOverSubState;

class GameOverSubState extends MusicBeatSubState
{
	public static var instance:GameOverSubState = null;

	public var boyfriend:Boyfriend;

	var camFollow:FlxPoint;
	var camFollowPos:FlxObject;

	public var camDeath:SwagCamera;

	var updateCamera:Bool = false;
	var playingDeathSound:Bool = false;

	public static var danceDelay:Int = OptionData.danceOffset;
	public static var cameraSpeed:Float = 1; // Camera Speed after fractures of the boyfriend's skeleton
	public static var bpm:Float = 100; // BPM on game over
	public static var allowFading:Bool = true; // Allows fade in/flashing on game over screen
	public static var allowShaking:Bool = true; // Allows shaking camera on game over screen
	public static var shakeDuration:Float = 0.3; // Duration of shaking
	public static var fadeDurationStart:Float = 0.85; // Duration of fade in on start of game over screen
	public static var fadeDurationMicDown:Float = 0.85; // Duration of fade in then finished timer with duration from variable `flashStart`
	public static var fadeDurationConfirm:Float = 1; // Duration of fade in then on confirm to end game over screen
	public static var confirmFadeOutDuration:Float = 2.3; // Duration of fade out then on finished timer with duration from variable `startConfirmFadeOut`
	public static var colorOnFadeOut:FlxColor = FlxColor.BLACK; // Color of fade out then on confirm to end game over screen
	public static var startConfirmFadeOut:Float = 0.7; // Time of timer then on confirm to end game over screen
	public static var colorStartFlash:FlxColor = FlxColor.RED; // Color of fade in then start of the game over screen
	public static var colorFlash:FlxColor = FlxColor.WHITE; // Color of fade in then finished timer with duration from variable `flashStart`
	public static var colorConfirmFlash:FlxColor = 0x85FFFFFF; // Color of fade in then on confirm to end game over screen
	public static var flashStart:Float = 1; // Time of timer to fade in or stuff, To disable, set the variable's value to -1
	public static var micDownStart:Float = 1; // Time of timer to mic down or stuff, To disable, set the variable's value to -1
	public static var characterName:String = 'bf-dead';
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';

	public static function resetVariables():Void
	{
		danceDelay = OptionData.danceOffset;
		bpm = 100;
		allowFading = true;
		allowShaking = true;
		shakeDuration = 0.3;
		fadeDurationStart = 0.85;
		fadeDurationMicDown = 0.85;
		fadeDurationConfirm = 0.85;
		confirmFadeOutDuration = 2;
		colorOnFadeOut = FlxColor.BLACK;
		startConfirmFadeOut = 0.7;
		colorStartFlash = FlxColor.RED;
		colorFlash = FlxColor.WHITE;
		colorConfirmFlash = 0x85FFFFFF;
		flashStart = 1;
		micDownStart = 1;
		characterName = 'bf-dead';
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';
	}

	var randomGameover:Int = 1; // for week 7 from funkin source code update

	public override function create():Void
	{
		instance = this;
		PlayState.instance.callOnLuas('onGameOverStart', []);

		super.create();
	}

	public function new(x:Float, y:Float):Void
	{
		super();

		PlayState.instance.setOnLuas('inGameOver', true);

		Conductor.changeBPM(bpm);
		Conductor.songPosition = 0;

		camDeath = new SwagCamera();
		camDeath.bgColor.alpha = 0;
		camDeath.zoom = FlxG.camera.zoom;
		FlxG.cameras.add(camDeath, false);

		boyfriend = new Boyfriend(x, y, characterName);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		boyfriend.cameras = [camDeath];
		add(boyfriend);

		FlxG.sound.play(Paths.getSound(deathSoundName));

		if (OptionData.camShakes && allowShaking) {
			camDeath.shake(0.02, shakeDuration, null, true, Y);
		}

		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		if (allowFading)
		{
			colorStartFlash.alphaFloat -= (!OptionData.flashingLights ? 0.5 : 0);
			FlxG.camera.fade(colorStartFlash, fadeDurationStart, true);
		}

		boyfriend.playAnim('firstDeath');

		camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width / 2), FlxG.camera.scroll.y + (FlxG.camera.height / 2));
		add(camFollowPos);

		if (micDownStart > -1)
		{
			new FlxTimer().start(micDownStart, function(tmr:FlxTimer):Void {
				micIsDown = true;
			});
		}

		if (flashStart > -1)
		{
			new FlxTimer().start(flashStart, function(tmr:FlxTimer):Void
			{
				if (allowFading)
				{
					colorFlash.alphaFloat -= (!OptionData.flashingLights ? 0.5 : 0);
					FlxG.camera.fade(colorFlash, fadeDurationMicDown, true);
				}
			});
		}

		var randomCensor:Array<Int> = [];

		if (OptionData.naughtyness) {
			randomCensor = [1, 3, 8, 13, 17, 21];
		}

		randomGameover = FlxG.random.int(1, 25, randomCensor);
		PlayState.instance.setOnLuas('inGameOverPost', true);
	}

	public var micIsDown:Bool = false;
	var isFollowingAlready:Bool = false;

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		PlayState.instance.callOnLuas('onUpdate', [elapsed]);

		if (updateCamera)
		{
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6 * cameraSpeed, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
		}

		var exit:Bool = controls.BACK || FlxG.mouse.justPressedRight;

		if (exit)
		{
			PlayState.deathCounter = 0;

			PlayState.usedPractice = false;
			PlayState.changedDifficulty = false;
			PlayState.seenCutscene = false;
			PlayState.chartingMode = false;

			WeekData.loadTheFirstEnabledMod();

			switch (PlayState.gameMode)
			{
				case 'story': FlxG.switchState(new StoryMenuState());
				case 'freeplay': FlxG.switchState(new FreeplayMenuState());
				case 'replay': FlxG.switchState(new options.ReplaysMenuState());
				default: FlxG.switchState(new MainMenuState());
			}

			PlayState.instance.callOnLuas('onGameOverConfirm', [false]);
		}

		if (controls.ACCEPT || FlxG.mouse.justPressed) {
			endBullshit();
		}

		if (boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name == 'firstDeath')
		{
			if (boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
			{
				camDeath.follow(camFollowPos, null, 1);

				updateCamera = true;
				isFollowingAlready = true;
			}

			if (boyfriend.animation.curAnim.finished && !boyfriend.startedDeath)
			{
				if (!playingDeathSound)
				{
					switch (PlayState.SONG.stage)
					{
						case 'tank':
						{
							coolStartDeath(0.2);

							var jeffGameOver:String = 'jeffGameover/jeffGameover-' + randomGameover;

							if (Paths.fileExists(Paths.getSound(jeffGameOver, true), SOUND, true))
							{
								FlxG.sound.play(Paths.getSound(jeffGameOver), 1, false, null, true, function():Void
								{
									if (!isEnding) {
										FlxG.sound.music.fadeIn(4, 0.2, 1);
									}
								});
							}
						}
						default: coolStartDeath();
					}

					playingDeathSound = true;
				}

				boyfriend.startedDeath = true;
				boyfriend.playAnim('deathLoop');
			}
		}

		if (FlxG.sound.music != null && FlxG.sound.music.playing) {
			Conductor.songPosition = FlxG.sound.music.time;
		}

		PlayState.instance.callOnLuas('onUpdatePost', [elapsed]);
	}

	function coolStartDeath(?vol:Float = 1):Void
	{
		if (!isEnding) {
			FlxG.sound.playMusic(Paths.getMusic(loopSoundName), vol);
		}
	}

	override function beatHit():Void
	{
		super.beatHit();

		if (curBeat % danceDelay == 0 && boyfriend.startedDeath) {
			boyfriend.playAnim('deathLoop');
		}
	}

	var isEnding:Bool = false;

	function endBullshit():Void
	{
		if (!isEnding)
		{
			isEnding = true;

			if (allowFading)
			{
				colorConfirmFlash.alphaFloat -= (!OptionData.flashingLights ? 0.5 : 0);
				FlxG.camera.fade(colorConfirmFlash, fadeDurationConfirm, true);
			}

			boyfriend.playAnim('deathConfirm', true);

			var perVolume:Float = FlxG.sound.music.volume;

			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.getMusic(endSoundName), perVolume);

			new FlxTimer().start(startConfirmFadeOut, function(tmr:FlxTimer):Void
			{
				camDeath.fade(colorOnFadeOut, confirmFadeOutDuration, false, function():Void
				{
					StageData.loadDirectory(PlayState.SONG);
					LoadingState.loadAndSwitchState(new PlayState(), true);
				});
			});

			PlayState.instance.callOnLuas('onGameOverConfirm', [true]);
		}
	}
}