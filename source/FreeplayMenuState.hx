package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import Song;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.tweens.FlxTween;

using StringTools;

typedef FreeplayState = FreeplayMenuState; // in case, no jokes

class FreeplayMenuState extends MusicBeatState
{
	private static var curSelected:Int = -1;
	private static var lastDifficultyName:String = '';

	private var curDifficulty:Int = -1;

	private var songsArray:Array<SongMetaData> = [];
	private var curSong:SongMetaData;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var grpIcons:FlxTypedGroup<HealthIcon>;

	var bg:FlxSprite;

	var startingTweenBGColor:Bool = true;
	var startColor:FlxColor = FlxColor.WHITE;
	var intendedColor:FlxColor;
	var colorTween:FlxTween;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;

	public override function create():Void
	{
		#if DISCORD_ALLOWED
		DiscordClient.changePresence("In the Freeplay Menu", null); // Updating Discord Rich Presence
		#end

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing || FlxG.sound.music.volume == 0) {
				FlxG.sound.playMusic(Paths.getMusic('freakyMenu'));
			}
		}

		PlayState.gameMode = 'freeplay';
		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		for (i in 0...WeekData.weeksList.length)
		{
			if (WeekData.weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j].songID);
				leChars.push(leWeek.songs[j].character);
			}

			WeekData.setDirectoryFromWeek(leWeek);

			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song.color;

				if (colors == null || colors.length < 3) {
					colors = [146, 113, 253];
				}

				var songItem:SongMetaData = new SongMetaData(song.songID, song.songName, song.character, FlxColor.fromRGB(colors[0], colors[1], colors[2]));
				songItem.difficulties = song.difficulties;
				songItem.defaultDifficulty = song.defaultDifficulty;
				songItem.weekID = leWeek.weekID;
				songItem.weekName = leWeek.weekName;
				songsArray.push(songItem);
			}
		}

		WeekData.loadTheFirstEnabledMod();

		bg = new FlxSprite();

		if (Paths.fileExists('images/menuDesat.png', IMAGE)) {
			bg.loadGraphic(Paths.getImage('menuDesat'));
		}
		else {
			bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		}

		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		bg.color = startColor;
		bg.antialiasing = OptionData.globalAntialiasing;
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		grpIcons = new FlxTypedGroup<HealthIcon>();
		add(grpIcons);

		for (i in 0...songsArray.length)
		{
			if (curSelected < 0) curSelected = i;
			var leSong:SongMetaData = songsArray[i];

			Paths.currentModDirectory = leSong.folder;

			var songText:Alphabet = new Alphabet(90, 320, leSong.songName, true);
			songText.isMenuItem = true;
			songText.targetY = i - curSelected;
			songText.hasIcon = true;
			grpSongs.add(songText);

			var maxWidth:Int = 980;
	
			if (songText.width > maxWidth) {
				songText.scaleX = maxWidth / songText.width;
			}

			songText.setPosition(0, (70 * i) + 30);

			var icon:HealthIcon = new HealthIcon(leSong.songCharacter);
			icon.sprTracker = songText;
			icon.ID = i;
			icon.snapToPosition();
			grpIcons.add(icon);
		}

		WeekData.setDirectoryFromWeek();

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, RIGHT);
		add(scoreText);

		scoreBG = new FlxSprite(scoreText.x - 6, 0);
		scoreBG.makeGraphic(1, 66, 0x99000000);
		scoreBG.antialiasing = false;
		insert(members.indexOf(scoreText), scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song | Press CTRL to open the Gameplay Changers Menu | Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu | Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height);
		textBG.makeGraphic(FlxG.width, 26, FlxColor.BLACK);
		textBG.alpha = 0.6;
		add(textBG);

		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(Paths.getFont('vcr.ttf'), size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		FlxTween.tween(textBG, {y: FlxG.height - 26}, 2, {ease: FlxEase.circOut});
		FlxTween.tween(text, {y: FlxG.height - 26 + 4}, 2, {ease: FlxEase.circOut});

		if(curSelected >= songsArray.length) curSelected = 0;
		curSong = songsArray[curSelected];
		CoolUtil.loadDifficultiesFromLevel(curSong);

		if(lastDifficultyName == '') {
			lastDifficultyName = curSong.defaultDifficulty;
		}

		curDifficulty = Math.round(Math.max(0, CoolUtil.getDifficultyIndex(lastDifficultyName)));

		changeSelection();
		changeDifficulty();

		super.create();
	}

	public function addSong(song:SongMetaData):Void
	{
		songsArray.push(song);
	}

	public static var vocals:FlxSound = null;
	var instPlaying:Int = -1;

	public static function destroyFreeplayVocals():Void
	{
		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}

		vocals = null;
	}

	var lerpScore:Float = 0;
	var intendedScore:Int = 0;

	var lerpAccuracy:Float = 0;
	var intendedAccuracy:Float = 0;

	var holdTime:Float = 0;
	var holdTimeHos:Float = 0;

	public override function update(elapsed:Float):Void
	{
		if (FlxG.sound.music != null && FlxG.sound.music.volume < 0.7) {
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1));
		lerpAccuracy = FlxMath.lerp(lerpAccuracy, intendedAccuracy, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10) {
			lerpScore = intendedScore;
		}

		if (Math.abs(lerpAccuracy - intendedAccuracy) <= 0.01) {
			lerpAccuracy = intendedAccuracy;
		}

		var ratingSplit:Array<String> = ('' + CoolUtil.floorDecimal(lerpAccuracy, 2)).split('.');

		if (ratingSplit.length < 2) { // No decimals, add an empty space
			ratingSplit.push('');
		}

		while (ratingSplit[1].length < 2) { // Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = "PERSONAL BEST:" + Math.round(lerpScore) + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		if (controls.BACK || FlxG.mouse.justPressedRight)
		{
			persistentUpdate = false;

			if (colorTween != null) {
				colorTween.cancel();
			}

			FlxG.sound.play(Paths.getSound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}

		var shiftMult:Int = FlxG.keys.pressed.SHIFT ? 3 : 1;

		if (songsArray.length > 1)
		{
			if (controls.UI_UP_P)
			{
				changeSelection(-shiftMult, true);
				holdTime = 0;
			}

			if (controls.UI_DOWN_P)
			{
				changeSelection(shiftMult, true);
				holdTime = 0;
			}

			if (controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult), true);
				}
			}

			if (FlxG.mouse.wheel != 0 && !FlxG.keys.pressed.ALT) {
				changeSelection(-shiftMult * FlxG.mouse.wheel, true);
			}
		}

		if (CoolUtil.difficultyStuff.length > 1)
		{
			if (controls.UI_LEFT_P)
			{
				changeDifficulty(-1);
				holdTimeHos = 0;
			}

			if (controls.UI_RIGHT_P)
			{
				changeDifficulty(1);
				holdTimeHos = 0;
			}

			if (controls.UI_LEFT || controls.UI_RIGHT)
			{
				var checkLastHold:Int = Math.floor((holdTimeHos - 0.5) * 10);
				holdTimeHos += elapsed;
				var checkNewHold:Int = Math.floor((holdTimeHos - 0.5) * 10);

				if (holdTimeHos > 0.5 && checkNewHold - checkLastHold > 0) {
					changeDifficulty((checkNewHold - checkLastHold) * (controls.UI_LEFT ? -1 : 1));
				}
			}

			if (FlxG.mouse.wheel != 0 && FlxG.keys.pressed.ALT) {
				changeDifficulty(-1 * FlxG.mouse.wheel);
			}
		}

		if (FlxG.keys.justPressed.CONTROL)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubState());
		}
		#if PRELOAD_ALL
		else if (FlxG.keys.justPressed.SPACE)
		{
			var diffic:String = CoolUtil.difficultyStuff[curDifficulty][2];
			var ourPath:String = curSong.songID + diffic;

			if (Paths.fileExists('data/' + curSong.songID + '/' + ourPath + '.json', TEXT))
			{
				if (instPlaying != curSelected)
				{
					try
					{
						destroyFreeplayVocals();

						FlxG.sound.music.volume = 0;
						Paths.currentModDirectory = curSong.folder;

						PlayState.SONG = Song.loadFromJson(ourPath, curSong.songID);

						vocals = new FlxSound();

						if (PlayState.SONG.needsVoices) {
							vocals.loadEmbedded(Paths.getVoices(PlayState.SONG.songID, lastDifficultyName));
						}

						FlxG.sound.list.add(vocals);
						FlxG.sound.playMusic(Paths.getInst(PlayState.SONG.songID, lastDifficultyName), 0.7);

						vocals.play();
						vocals.persist = true;
						vocals.looped = true;
						vocals.volume = 0.7;

						instPlaying = curSelected;
					}
					catch (e:Dynamic) {
						Debug.logError('Error on loading file "' + curSong.songID + '/' + ourPath + '.json' + '": ' + e);
					}
				}
			}
			else {
				Debug.logError('File "' + curSong.songID + '/' + ourPath + '.json' + '" does not exist!');
			}
		}
		#end
		else if (controls.ACCEPT || FlxG.mouse.justPressed)
		{
			persistentUpdate = false;

			var diffic:String = CoolUtil.difficultyStuff[curDifficulty][2];
			var ourPath:String = curSong.songID + diffic;

			if (Paths.fileExists('data/' + curSong.songID + '/' + ourPath + '.json', TEXT))
			{
				PlayState.SONG = Song.loadFromJson(ourPath, curSong.songID);
				PlayState.storyWeekID = curSong.weekID;
				PlayState.storyWeekName = curSong.weekName;
				PlayState.seenCutscene = false;

				Debug.logInfo('Loading song "${PlayState.SONG.songName}" from week "${PlayState.storyWeekName}" into Free Play...');

				if (!OptionData.loadingScreen)
				{
					FlxG.sound.music.volume = 0;
					destroyFreeplayVocals();
				}

				try
				{ #if desktop
					if (FlxG.keys.pressed.SHIFT)
						LoadingState.loadAndSwitchState(new editors.ChartingState(), true);
					else #end
						LoadingState.loadAndSwitchState(new PlayState(), true);
				}
				catch (e:Dynamic) {
					Debug.logError('Cannot load level song "' + PlayState.SONG.songName + '" because of: ' + e);
				}
			}
			else {
				Debug.logError('File "' + curSong.songID + '/' + ourPath + '.json' + '" does not exist!');
			}
		}
		else if (controls.RESET)
		{
			persistentUpdate = false;
			openSubState(new ResetScoreSubState('freeplay', curSong.songName, curSong.songID, CoolUtil.difficultyStuff[curDifficulty][1], lastDifficultyName, curSong.songCharacter));
		}

		super.update(elapsed);
	}

	public override function openSubState(SubState:FlxSubState):Void
	{
		super.openSubState(SubState);

		if (!startingTweenBGColor && colorTween != null) {
			colorTween.active = false;
		}
	}

	public override function closeSubState():Void
	{
		super.closeSubState();

		if (startingTweenBGColor)
		{
			var newColor:FlxColor = curSong.color;

			if (intendedColor != newColor)
			{
				if (colorTween != null) {
					colorTween.cancel();
				}

				intendedColor = newColor;

				colorTween = FlxTween.color(bg, 1, startColor, intendedColor,
				{
					onComplete: function(twn:FlxTween):Void {
						colorTween = null;
					}
				});
			}

			startingTweenBGColor = false;
		}
		else
		{
			if (colorTween != null) {
				colorTween.active = true;
			}
		}

		#if !switch
		intendedScore = Highscore.getScore(CoolUtil.formatSong(curSong.songID, lastDifficultyName));
		intendedAccuracy = Highscore.getAccuracy(CoolUtil.formatSong(curSong.songID, lastDifficultyName));
		#end
	}

	function changeSelection(change:Int = 0, ?playSound:Bool = true):Void
	{
		curSelected = CoolUtil.boundSelection(curSelected + change, songsArray.length);

		curSong = songsArray[curSelected];
		PlayState.storyWeekID = curSong.weekID;

		var bullShit:Int = 0;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0) {
				item.alpha = 1;
			}
		}

		grpIcons.forEach(function(icon:HealthIcon):Void
		{
			icon.alpha = 0.6;

			if (icon.ID == curSelected) {
				icon.alpha = 1;
			}
		});

		if (!startingTweenBGColor)
		{
			var newColor:FlxColor = curSong.color;

			if (newColor != intendedColor)
			{
				if (colorTween != null) {
					colorTween.cancel();
				}

				intendedColor = newColor;

				colorTween = FlxTween.color(bg, 1, bg.color, intendedColor,
				{
					onComplete: function(twn:FlxTween):Void {
						colorTween = null;
					}
				});
			}
		}

		Paths.currentModDirectory = curSong.folder;
		CoolUtil.loadDifficultiesFromLevel(curSong);

		if (playSound) {
			FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
		}

		if (CoolUtil.difficultyExists(curSong.defaultDifficulty)) {
			curDifficulty = Math.round(Math.max(0, CoolUtil.getDifficultyIndex(curSong.defaultDifficulty)));
		}
		else {
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.getDifficultyIndex(lastDifficultyName);

		if (newPos > -1) {
			curDifficulty = newPos;
		}

		changeDifficulty();
		positionHighscore();
	}

	function changeDifficulty(change:Int = 0):Void
	{
		curDifficulty = CoolUtil.boundSelection(curDifficulty + change, CoolUtil.difficultyStuff.length);
		lastDifficultyName = CoolUtil.difficultyStuff[curDifficulty][0];

		PlayState.lastDifficulty = curDifficulty;
		PlayState.storyDifficulty = curDifficulty;

		#if !switch
		intendedScore = Highscore.getScore(CoolUtil.formatSong(curSong.songID, lastDifficultyName));
		intendedAccuracy = Highscore.getAccuracy(CoolUtil.formatSong(curSong.songID, lastDifficultyName));
		#end

		diffText.text = '< ' + CoolUtil.difficultyString() + ' >';
		positionHighscore();
	}

	function positionHighscore():Void
	{
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - scoreBG.scale.x / 2;

		diffText.x = Std.int(scoreBG.x + scoreBG.width / 2);
		diffText.x -= (diffText.width / 2);
	}
}

class SongMetaData
{
	public var songID:String = '';
	public var songName:String = '';

	public var songCharacter:String = '';

	public var weekID:String = '';
	public var weekName:String = '';
	public var color:FlxColor = FlxColor.WHITE;

	public var defaultDifficulty:String = '';
	public var difficulties:Dynamic;

	public var folder:String = '';

	public function new(songID:String = '', songName:String = '', songCharacter:String = '', color:FlxColor = FlxColor.WHITE):Void
	{
		this.songID = songID;
		this.songName = songName;
		this.songCharacter = songCharacter;
		this.color = color;

		this.folder = Paths.currentModDirectory;
		if (this.folder == null) this.folder = '';

		defaultDifficulty = CoolUtil.defaultDifficulty;
		difficulties = CoolUtil.defaultDifficultes.copy();
	}
}