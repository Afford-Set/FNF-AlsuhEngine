package editors;

import Song;
import Section;
import StageData;
import Conductor;
import PhillyGlow;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.math.FlxRect;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxSort;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup;
#if (flixel >= "5.3.0")
import flixel.sound.FlxSound;
#else
import flixel.system.FlxSound;
#end
import flixel.tweens.FlxTween;
import openfl.events.KeyboardEvent;
import flixel.input.keyboard.FlxKey;

using StringTools;

class EditorPlayState extends MusicBeatState // Yes, this is mostly a copy of PlayState, it's kinda dumb to make a direct copy of it but... ehhh
{
	public static var instance:EditorPlayState = null;

	var generatedMusic:Bool = false;

	var vocals:FlxSound;
	var vocalsFinished:Bool = false;

	var timerToStart:Float = 0;
	var startOffset:Float = 0;
	var startPos:Float = 0;
	var combo:Int = 0;

	public function new(startPos:Float):Void
	{
		super();

		this.startPos = startPos;

		Conductor.songPosition = startPos - startOffset;

		startOffset = Conductor.crochet;
		timerToStart = startOffset;
	}

	public var notes:FlxTypedGroup<Note>;
	public var unspawnNotes:Array<Note> = [];

	public var strumLineNotes:FlxTypedGroup<StrumNote>;
	public var opponentStrums:FlxTypedGroup<StrumNote>;
	public var playerStrums:FlxTypedGroup<StrumNote>;
	public var grpNoteSplashes:FlxTypedGroup<NoteSplash>;

	var grpRatings:FlxTypedGroup<RatingSprite>;
	var grpCombo:FlxTypedGroup<ComboSprite>;
	var grpNumbers:FlxTypedGroup<NumberSprite>;

	public var randomNotes:Bool = false;

	var scoreTxt:FlxText;
	var stepTxt:FlxText;
	var beatTxt:FlxText;
	var sectionTxt:FlxText;

	var songHits:Int = 0;
	var songMisses:Int = 0;

	public var songSpeed:Float = 1;

	private var keysArray:Array<Array<FlxKey>>;
	private var controlArray:Array<String>;

	public var noteTypeArray:Array<String> = [];

	var ratingsData:Array<Rating> = [];

	public override function create():Void
	{
		instance = this;

		controlArray = [for (i in 0...Note.maxNote) 'NOTE_' + Note.pointers[i]];
		keysArray = [for (i in controlArray) OptionData.keyBinds.get(i.toLowerCase()).copy()];
		songSpeed = PlayState.SONG.speed;

		var bg:FlxSprite = new FlxSprite();

		if (Paths.fileExists('images/menuDesat.png', IMAGE)) {
			bg.loadGraphic(Paths.getImage('menuDesat'));
		}
		else {
			bg.loadGraphic(Paths.getImage('bg/menuDesat'));
		}

		bg.scrollFactor.set();
		bg.color = FlxColor.fromHSB(FlxG.random.int(0, 359), FlxG.random.float(0, 0.8), FlxG.random.float(0.3, 1));
		add(bg);

		opponentStrums = new FlxTypedGroup<StrumNote>();
		add(opponentStrums);

		playerStrums = new FlxTypedGroup<StrumNote>();
		add(playerStrums);

		strumLineNotes = new FlxTypedGroup<StrumNote>();
		strumLineNotes.visible = false;
		add(strumLineNotes);

		generateStaticArrows(0);
		generateStaticArrows(1);

		grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
		add(grpNoteSplashes);

		grpRatings = new FlxTypedGroup<RatingSprite>();
		add(grpRatings);

		grpCombo = new FlxTypedGroup<ComboSprite>();
		add(grpCombo);

		grpNumbers = new FlxTypedGroup<NumberSprite>();
		add(grpNumbers);

		generateSong(PlayState.SONG);

		#if LUA_ALLOWED
		for (notetype in noteTypeArray)
		{
			var luaToLoad:String = Paths.getLua('custom_notetypes/' + notetype);

			if (Paths.fileExists(luaToLoad, TEXT, true))
			{
				var lua:EditorLua = new EditorLua(luaToLoad);

				new FlxTimer().start(0.1, function(tmr:FlxTimer):Void
				{
					if (lua != null)
					{
						lua.stop();
						lua = null;
					}
				});
			}
		}
		#end

		noteTypeArray = [];
		noteTypeArray = null;

		scoreTxt = new FlxText(0, FlxG.height - 50, FlxG.width, "Hits: 0 | Combo Breaks: 0", 20);
		scoreTxt.setFormat(Paths.getFont('vcr.ttf'), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		scoreTxt.visible = OptionData.scoreText;
		add(scoreTxt);
		
		sectionTxt = new FlxText(10, 580, FlxG.width - 20, "Section: 0", 20);
		sectionTxt.setFormat(Paths.getFont('vcr.ttf'), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		sectionTxt.scrollFactor.set();
		sectionTxt.borderSize = 1.25;
		add(sectionTxt);
		
		beatTxt = new FlxText(10, sectionTxt.y + 30, FlxG.width - 20, "Beat: 0", 20);
		beatTxt.setFormat(Paths.getFont('vcr.ttf'), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		beatTxt.scrollFactor.set();
		beatTxt.borderSize = 1.25;
		add(beatTxt);

		stepTxt = new FlxText(10, beatTxt.y + 30, FlxG.width - 20, "Step: 0", 20);
		stepTxt.setFormat(Paths.getFont('vcr.ttf'), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		stepTxt.scrollFactor.set();
		stepTxt.borderSize = 1.25;
		add(stepTxt);

		var tipText:FlxText = new FlxText(10, FlxG.height - 24, 0, 'Press ESC to Go Back to Chart Editor', 16);
		tipText.setFormat(Paths.getFont('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.borderSize = 2;
		tipText.scrollFactor.set();
		add(tipText);

		if (!controls.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		super.create();
	}

	private function generateSong(songData:SwagSong):Void
	{
		Conductor.changeBPM(songData.bpm);

		FlxG.sound.playMusic(Paths.getInst(songData.songID, CoolUtil.difficultyStuff[PlayState.lastDifficulty][2]), 0);
		FlxG.sound.music.pause();
		FlxG.sound.music.onComplete = endSong;

		vocals = new FlxSound();

		if (songData.needsVoices) {
			vocals.loadEmbedded(Paths.getVoices(songData.songID, CoolUtil.difficultyStuff[PlayState.lastDifficulty][2]));
		}

		vocals.onComplete = function():Void {
			vocalsFinished = true;
		}
		FlxG.sound.list.add(vocals);

		notes = new FlxTypedGroup<Note>();
		add(notes);

		unspawnNotes = ChartParser.parseSongChart(songData, true);
		unspawnNotes.sort(sortByTime);

		generatedMusic = true;
	}

	function sortByTime(obj1:Dynamic, obj2:Dynamic):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, obj1.strumTime, obj2.strumTime);
	}

	public var skipArrowStartTween:Bool = false; // for lua

	private function generateStaticArrows(player:Int):Void
	{
		for (i in 0...Note.maxNote)
		{
			var targetAlpha:Float = 1;

			if (player < 1)
			{
				if (!OptionData.opponentStrums) {
					targetAlpha = 0;
				}
				else if (OptionData.middleScroll) {
					targetAlpha = 0.35;
				}
			}

			var babyArrow:StrumNote = new StrumNote(OptionData.middleScroll ? PlayState.STRUM_X_MIDDLESCROLL : PlayState.STRUM_X, OptionData.downScroll ? FlxG.height - 150 : 50, i, player);
			babyArrow.downScroll = OptionData.downScroll;

			if (!skipArrowStartTween)
			{
				babyArrow.y -= 10;
				babyArrow.alpha = 0;

				FlxTween.tween(babyArrow, {y: babyArrow.y + 10, alpha: targetAlpha}, 1, {ease: FlxEase.circOut, startDelay: 0.5 + (0.2 * i)});
			}
			else {
				babyArrow.alpha = targetAlpha;
			}

			switch (player)
			{
				case 0:
				{
					if (OptionData.middleScroll)
					{
						babyArrow.x += 310;
	
						if (i > 1) { // Up and Right
							babyArrow.x += FlxG.width / 2 + 25;
						}
					}

					opponentStrums.add(babyArrow);
				}
				case 1: playerStrums.add(babyArrow);
			}

			strumLineNotes.add(babyArrow);
			babyArrow.postAddedToGroup();
		}
	}

	var startingSong:Bool = true;

	function startSong():Void
	{
		startingSong = false;

		FlxG.sound.music.time = startPos;
		FlxG.sound.music.volume = 1;
		FlxG.sound.music.play();

		if (vocals != null)
		{
			vocals.time = startPos;
			vocals.volume = 1;
			vocals.play();
		}
	}

	public var noteKillOffset:Float = 350;
	public var spawnTime:Float = 2000;

	public override function update(elapsed:Float):Void
	{
		if (FlxG.keys.justPressed.ESCAPE) {
			endSong();
		}

		if (startingSong)
		{
			timerToStart -= elapsed * 1000;
			Conductor.songPosition = startPos - timerToStart;

			if (timerToStart < 0) {
				startSong();
			}
		}
		else {
			Conductor.songPosition += elapsed * 1000;
		}

		if (unspawnNotes.length > 0 && unspawnNotes[0] != null)
		{
			var time:Float = spawnTime;

			if (songSpeed < 1) time /= songSpeed;
			if (unspawnNotes[0].multSpeed < 1) time /= unspawnNotes[0].multSpeed;

			while (unspawnNotes.length > 0 && unspawnNotes[0].strumTime - Conductor.songPosition < time)
			{
				var dunceNote:Note = unspawnNotes[0];
				notes.insert(0, dunceNote);
				dunceNote.spawned = true;

				var index:Int = unspawnNotes.indexOf(dunceNote);
				unspawnNotes.splice(index, 1);
			}
		}

		if (generatedMusic)
		{
			var fakeCrochet:Float = (60 / PlayState.SONG.bpm) * 1000;

			notes.forEachAlive(function(daNote:Note):Void
			{
				var strumGroup:FlxTypedGroup<StrumNote> = daNote.mustPress ? playerStrums : opponentStrums;
				var strum:StrumNote = strumGroup.members[daNote.noteData];

				var strumX:Float = strum.x;
				var strumY:Float = strum.y;
				var strumAngle:Float = strum.angle;
				var strumDirection:Float = strum.direction;
				var strumAlpha:Float = strum.alpha;
				var strumScroll:Bool = strum.downScroll;

				strumX += daNote.offsetX;
				strumY += daNote.offsetY;
				strumAngle += daNote.offsetAngle;
				strumAlpha *= daNote.multAlpha;

				if (strumScroll) {
					daNote.distance = (0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
				}
				else {
					daNote.distance = (-0.45 * (Conductor.songPosition - daNote.strumTime) * songSpeed * daNote.multSpeed);
				}

				var angleDir:Float = strumDirection * Math.PI / 180;

				if (daNote.copyAngle) {
					daNote.angle = strumDirection - 90 + strumAngle;
				}

				if (daNote.copyAlpha) {
					daNote.alpha = strumAlpha;
				}

				if (daNote.copyX) {
					daNote.x = strumX + Math.cos(angleDir) * daNote.distance;
				}

				if (daNote.copyY)
				{
					daNote.y = strumY + Math.sin(angleDir) * daNote.distance;

					if (strumScroll && daNote.isSustainNote) // Jesus fuck this took me so much mother fucking time AAAAAAAAAA
					{
						if (daNote.animation.curAnim.name.endsWith('end'))
						{
							daNote.y += 10.5 * (fakeCrochet / 400) * 1.5 * songSpeed + (46 * (songSpeed - 1));
							daNote.y -= 46 * (1 - (fakeCrochet / 600)) * songSpeed;

							if (PlayState.isPixelStage) {
								daNote.y += 8 + (6 - daNote.originalHeightForCalcs) * PlayState.daPixelZoom;
							}
							else {
								daNote.y -= 19;
							}
						}

						daNote.y += (Note.swagWidth / 2) - (60.5 * (songSpeed - 1));
						daNote.y += 27.5 * ((PlayState.SONG.bpm / 100) - 1) * (songSpeed - 1);
					}
				}

				if (!daNote.mustPress && daNote.wasGoodHit && !daNote.hitByOpponent && !daNote.ignoreNote) {
					opponentNoteHit(daNote);
				}

				var center:Float = strumY + Note.swagWidth / 2;

				if (strum.sustainReduce && daNote.isSustainNote && (daNote.mustPress || !daNote.ignoreNote) && (!daNote.mustPress || (daNote.wasGoodHit || (daNote.prevNote.wasGoodHit && !daNote.canBeHit))))
				{
					if (strumScroll)
					{
						var swagRect:FlxRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
						var result:Int = Std.int((daNote.y + daNote.height) - center);

						if (result > 0) {
							swagRect.y = result / daNote.scale.y;
						}

						daNote.clipRect = swagRect;
					}
					else
					{
						var swagRect:FlxRect = new FlxRect(0, 0, daNote.width / daNote.scale.x, daNote.height / daNote.scale.y);
						var result:Int = Std.int(center - daNote.y);

						if (result > 0) {
							swagRect.y = result / daNote.scale.y;
						}

						daNote.clipRect = swagRect;
					}
				}

				if (Conductor.songPosition > noteKillOffset + daNote.strumTime) // Kill extremely late notes and cause misses
				{
					if (daNote.mustPress && !daNote.ignoreNote && (daNote.tooLate || !daNote.wasGoodHit)) {
						noteMiss(daNote);
					}

					daNote.active = false;
					daNote.visible = false;

					daNote.kill();
					notes.remove(daNote, true);
					daNote.destroy();
				}
			});
		}
		else
		{
			notes.forEachAlive(function(daNote:Note):Void
			{
				daNote.canBeHit = false;
				daNote.wasGoodHit = false;
			});
		}

		keyShit();

		scoreTxt.text = 'Hits: ' + songHits + ' | Combo Breaks: ' + songMisses;
		sectionTxt.text = 'Section: ' + curSection;
		beatTxt.text = 'Beat: ' + curBeat;
		stepTxt.text = 'Step: ' + curStep;

		super.update(elapsed);
	}

	function killCombo(daNote:Note = null):Void
	{
		if (combo > 0)
		{
			combo = 0;
			displayCombo();
		}

		if (!daNote.isSustainNote && !daNote.hitCausesMiss) songMisses++;

		if (vocals != null) {
			vocals.volume = 0;
		}
	}

	public static var lastRating:RatingSprite;
	public static var lastCombo:ComboSprite;
	public static var lastScore:Array<NumberSprite> = [];

	public var showRating:Bool = true;
	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;

	private function popUpScore(daNote:Note):Void
	{
		var noteDiff:Float = Math.abs(daNote.strumTime - Conductor.songPosition + OptionData.ratingOffset);
		var daRating:Rating = Conductor.judgeNote(ratingsData, daNote, noteDiff);

		if (!daNote.isSustainNote)
		{
			if (daRating.noteSplash && daNote != null && !daNote.quickNoteSplash && !daNote.noteSplashDisabled) {
				spawnNoteSplashOnNote(daNote);
			}

			var rating:RatingSprite = new RatingSprite(daRating.image);

			if (!OptionData.comboStacking)
			{
				if (lastRating != null)
				{
					lastRating.kill();
					grpRatings.remove(lastRating);
				}

				lastRating = rating;
			}

			if (showRating) {
				grpRatings.add(rating);
			}

			FlxTween.tween(rating, {alpha: 0}, 0.2,
			{
				startDelay: Conductor.crochet * 0.001,
				onComplete: function(twn:FlxTween):Void
				{
					rating.kill();
					grpRatings.remove(rating, true);
					rating.destroy();
				}
			});

			displayCombo();
		}
	}

	function displayCombo():Void
	{
		var comboSpr:ComboSprite = new ComboSprite();

		if (!OptionData.comboStacking)
		{
			if (lastCombo != null)
			{
				lastCombo.kill();
				grpCombo.remove(lastCombo);
			}

			lastCombo = comboSpr;
		}

		if (showCombo) {
			grpCombo.add(comboSpr);
		}

		FlxTween.tween(comboSpr, {alpha: 0}, 0.2,
		{
			startDelay: Conductor.crochet * 0.002,
			onComplete: function(twn:FlxTween):Void
			{
				comboSpr.kill();
				grpCombo.remove(comboSpr, true);
				comboSpr.destroy();
			}
		});

		var seperatedScore:Array<Int> = [];
		var tempCombo:Int = combo;

		var stringCombo:String = '' + tempCombo;

		for (i in 0...stringCombo.length) {
			seperatedScore.push(Std.parseInt(stringCombo.charAt(i)));
		}

		while (seperatedScore.length < 3) {
			seperatedScore.insert(0, 0);
		}

		if (lastScore != null)
		{
			while (lastScore.length > 0)
			{
				var ndumb:NumberSprite = lastScore[0];

				ndumb.kill();
				lastScore.remove(ndumb);
				ndumb.destroy();

				grpNumbers.remove(ndumb);
			}
		}

		for (i in 0...seperatedScore.length)
		{
			var numScore:NumberSprite = new NumberSprite(seperatedScore[i], null, i);

			if (showComboNum) {
				grpNumbers.add(numScore);
			}

			if (!OptionData.comboStacking) {
				lastScore.push(numScore);
			}

			FlxTween.tween(numScore, {alpha: 0}, 0.2,
			{
				startDelay: Conductor.crochet * 0.002,
				onComplete: function(twn:FlxTween):Void
				{
					numScore.kill();
					grpNumbers.remove(numScore, true);
					numScore.destroy();
				}
			});
		}
	}

	public var strumsBlocked:Array<Bool> = [];

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var noteData:Int = getDataFromKeyEvent(eventKey);

		if (!startingSong && noteData > -1 && (FlxG.keys.checkStatus(eventKey, JUST_PRESSED) || controls.controllerMode))
		{
			if (generatedMusic)
			{
				var lastTime:Float = Conductor.songPosition;
				Conductor.songPosition = FlxG.sound.music.time;

				var canMiss:Bool = !OptionData.ghostTapping;

				var pressNotes:Array<Note> = [];
				var notesStopped:Bool = false;

				var sortedNotesList:Array<Note> = [];

				notes.forEachAlive(function(daNote:Note):Void
				{
					if (strumsBlocked[daNote.noteData] != true && daNote.canBeHit && daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.isSustainNote && !daNote.blockHit)
					{
						if (daNote.noteData == noteData) {
							sortedNotesList.push(daNote);
						}

						canMiss = true;
					}
				});

				sortedNotesList.sort(sortHitNotes);

				if (sortedNotesList.length > 0)
				{
					for (epicNote in sortedNotesList)
					{
						for (doubleNote in pressNotes) 
						{
							if (Math.abs(doubleNote.strumTime - epicNote.strumTime) < 1)
							{
								doubleNote.kill();
								notes.remove(doubleNote, true);
								doubleNote.destroy();
							}
							else {
								notesStopped = true;
							}
						}

						if (!notesStopped) // eee jack detection before was not super good
						{
							goodNoteHit(epicNote);
							pressNotes.push(epicNote);
						}
					}
				}
				else
				{
					if (canMiss) {
						noteMissPress(noteData);
					}
				}

				Conductor.songPosition = lastTime;
			}

			var spr:StrumNote = playerStrums.members[noteData];

			if (!strumsBlocked[noteData] && spr != null && spr.animation.curAnim.name != 'confirm')
			{
				spr.playAnim('pressed');
				spr.resetAnim = 0;
			}
		}
	}

	public function sortHitNotes(a:Note, b:Note):Int
	{
		if (a.lowPriority && !b.lowPriority) return 1;
		else if (!a.lowPriority && b.lowPriority) return -1;

		return FlxSort.byValues(FlxSort.ASCENDING, a.strumTime, b.strumTime);
	}

	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var noteData:Int = getDataFromKeyEvent(eventKey);

		if (!startingSong && noteData > -1)
		{
			var spr:StrumNote = playerStrums.members[noteData];

			if (spr != null)
			{
				spr.playAnim('static');
				spr.resetAnim = 0;
			}
		}
	}

	private function getDataFromKeyEvent(key:FlxKey):Int
	{
		if (key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if (key == keysArray[i][j]) {
						return i;
					}
				}
			}
		}

		return -1;
	}

	private function keyShit():Void
	{
		var parsedHoldArray:Array<Bool> = parseKeys();

		if (controls.controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
	
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] && !strumsBlocked[i]) {
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
					}
				}
			}
		}

		if (generatedMusic)
		{
			notes.forEachAlive(function(daNote:Note):Void
			{
				if (strumsBlocked[daNote.noteData] != true && daNote.isSustainNote && parsedHoldArray[daNote.noteData] && daNote.canBeHit
					&& daNote.mustPress && !daNote.tooLate && !daNote.wasGoodHit && !daNote.blockHit) { // hold note functions
					goodNoteHit(daNote);
				}
			});
		}

		if (controls.controllerMode || strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys('_R');

			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] || strumsBlocked[i] == true) {
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
					}
				}
			}
		}
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];

		for (i in 0...controlArray.length) {
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		}

		return ret;
	}

	function endSong():Void
	{
		FlxG.sound.music.pause();
		FlxG.sound.music.volume = 0;

		if (vocals != null)
		{
			vocals.pause();
			vocals.volume = 0;
		}

		FlxTimer.globalManager.forEach(function(tmr:FlxTimer):Void
		{
			if (!tmr.finished) tmr.active = false;
		});

		FlxG.sound.list.forEachAlive(function(sud:FlxSound):Void
		{
			@:privateAccess
			if (!sud._paused) sud.pause();
		});

		FlxTween.globalManager.forEach(function(twn:FlxTween):Void
		{
			if (!twn.finished) twn.active = false;
		});

		LoadingState.loadAndSwitchState(new ChartingState());
	}

	function noteMissPress(direction:Int = 1):Void
	{
		if (OptionData.ghostTapping) return;
		FlxG.sound.play(Paths.getSoundRandom('missnote', 1, 3), FlxG.random.float(0.1, 0.2));

		killCombo();
	}

	function noteMiss(daNote:Note):Void
	{
		notes.forEachAlive(function(note:Note):Void
		{
			if (daNote != note && daNote.mustPress && daNote.noteData == note.noteData && daNote.isSustainNote == note.isSustainNote && Math.abs(daNote.strumTime - note.strumTime) < 10)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		});

		killCombo(daNote);
	}

	function opponentNoteHit(daNote:Note):Void
	{
		if (vocals != null) {
			vocals.volume = 1;
		}

		var time:Float = 0.15;

		if (daNote.isSustainNote && !daNote.animation.curAnim.name.endsWith('end')) {
			time += 0.15;
		}

		StrumPlayAnim(daNote.noteData, time);

		if (daNote.noteSplashHitByOpponent && !daNote.noteSplashDisabled && !daNote.isSustainNote) {
			spawnNoteSplashOnNote(daNote);
		}

		daNote.hitByOpponent = true;

		if (!daNote.isSustainNote)
		{
			daNote.kill();
			notes.remove(daNote, true);
			daNote.destroy();
		}
	}

	function goodNoteHit(note:Note):Void
	{
		if (!note.wasGoodHit)
		{
			if (note.hitCausesMiss)
			{
				noteMiss(note);

				if (!note.noteSplashHitByOpponent && !note.noteSplashDisabled && !note.isSustainNote) {
					spawnNoteSplashOnNote(note);
				}

				note.wasGoodHit = true;

				if (!note.isSustainNote)
				{
					note.kill();
					notes.remove(note, true);
					note.destroy();
				}

				return;
			}
			else
			{
				if (note.quickNoteSplash) {
					spawnNoteSplashOnNote(note);
				}

				if (!note.ignoreNote)
				{
					if (!note.isSustainNote)
					{
						songHits++;
						combo++;
					}

					popUpScore(note);
				}
			}

			var spr:StrumNote = playerStrums.members[note.noteData];

			if (spr != null) {
				spr.playAnim('confirm', true);
			}

			note.wasGoodHit = true;

			if (vocals != null) {
				vocals.volume = 1;
			}

			if (!note.isSustainNote)
			{
				note.kill();
				notes.remove(note, true);
				note.destroy();
			}
		}
	}

	function spawnNoteSplashOnNote(note:Note):Void
	{
		if (OptionData.splashOpacity > 0 && note != null)
		{
			var strum:StrumNote = null;

			if (note.noteSplashHitByOpponent)
				strum = opponentStrums.members[note.noteData];
			else
				strum = playerStrums.members[note.noteData];

			if (strum != null) {
				spawnNoteSplash(strum.x, strum.y, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, ?daNote:Note = null):Void
	{
		if (daNote == null) return;
		var skin:String = 'noteSplashes';

		if (daNote.mustPress)
		{
			if (PlayState.SONG.splashSkin != null && PlayState.SONG.splashSkin.length > 0) {
				skin = PlayState.SONG.splashSkin;
			}
		}
		else
		{
			if (PlayState.SONG.splashSkin2 != null && PlayState.SONG.splashSkin2.length > 0) {
				skin = PlayState.SONG.splashSkin2;
			}
		}

		var data:Int = daNote.noteData;

		var hue:Float = OptionData.arrowHSV[data % Note.maxNote][0] / 360;
		var sat:Float = OptionData.arrowHSV[data % Note.maxNote][1] / 100;
		var brt:Float = OptionData.arrowHSV[data % Note.maxNote][2] / 100;

		if (data > -1 && data < OptionData.arrowHSV.length)
		{
			hue = OptionData.arrowHSV[data][0] / 360;
			sat = OptionData.arrowHSV[data][1] / 100;
			brt = OptionData.arrowHSV[data][2] / 100;

			if (daNote != null)
			{
				skin = daNote.noteSplashTexture;

				hue = daNote.noteSplashHue;
				sat = daNote.noteSplashSat;
				brt = daNote.noteSplashBrt;
			}
		}

		var splash:NoteSplash = new NoteSplash(x, y, data);
		splash.setupNoteSplash(x, y, data, skin, daNote.mustPress, daNote.isCustomHSB, hue, sat, brt);
		grpNoteSplashes.add(splash);
	}

	public function StrumPlayAnim(isDad:Null<Bool> = null, id:Int, time:Float):Void
	{
		if (isDad == null) isDad = id < Note.maxNote;
		var spr:StrumNote = null;

		if (isDad) {
			spr = opponentStrums.members[id % Note.maxNote];
		}
		else {
			spr = playerStrums.members[id % Note.maxNote];
		}

		if (spr != null)
		{
			spr.playAnim('confirm', true);
			spr.resetAnim = time;
		}
	}

	public override function stepHit():Void
	{
		super.stepHit();

		if (FlxG.sound.music.time > Conductor.songPosition + 20 || FlxG.sound.music.time < Conductor.songPosition - 20) {
			resyncVocals();
		}
	}

	public override function beatHit():Void
	{
		super.beatHit();

		if (generatedMusic) {
			notes.sort(FlxSort.byY, OptionData.downScroll ? FlxSort.ASCENDING : FlxSort.DESCENDING);
		}
	}

	function resyncVocals():Void
	{
		if (vocals != null) vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;

		if (vocals != null)
		{
			if (vocalsFinished) return;

			vocals.time = Conductor.songPosition;
			vocals.play();
		}
	}

	public override function destroy():Void
	{
		super.destroy();

		FlxG.sound.music.stop();

		if (vocals != null)
		{
			vocals.stop();
			vocals.destroy();
		}

		if (!controls.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
	}
}