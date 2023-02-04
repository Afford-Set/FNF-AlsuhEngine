package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.group.FlxSpriteGroup;
import flixel.addons.text.FlxTypeText;

using StringTools;

class DialogueBox extends FlxSpriteGroup
{
	var box:FlxSprite;

	var curCharacter:String = '';
	var dialogueList:Array<String> = [];
	var swagDialogue:FlxTypeText;
	var dropText:FlxText;

	public var finishThing:Void->Void;

	var portraitLeft:FlxSprite;
	var portraitRight:FlxSprite;

	var handSelect:FlxSprite;
	var bgFade:FlxSprite;

	public function new(talkingRight:Bool = true, ?dialogueList:Array<String>):Void
	{
		super();

		switch (PlayState.SONG.songID)
		{
			case 'senpai':
			{
				FlxG.sound.playMusic(Paths.getMusic('Lunchbox'), 0);
				FlxG.sound.music.fadeIn(1, 0, 0.8);
			}
			case 'thorns':
			{
				FlxG.sound.playMusic(Paths.getMusic('LunchboxScary'), 0);
				FlxG.sound.music.fadeIn(1, 0, 0.8);
			}
		}

		bgFade = new FlxSprite(-200, -200).makeGraphic(Std.int(FlxG.width * 1.3), Std.int(FlxG.height * 1.3), 0xFFB3DFd8);
		bgFade.scrollFactor.set();
		bgFade.alpha = 0;
		add(bgFade);

		new FlxTimer().start(0.83, function(tmr:FlxTimer):Void
		{
			bgFade.alpha += (1 / 5) * 0.7;

			if (bgFade.alpha > 0.7) {
				bgFade.alpha = 0.7;
			}
		}, 5);
		
		portraitLeft = new FlxSprite(-20, 40);
		portraitLeft.frames = Paths.getSparrowAtlas('weeb/senpaiPortrait');
		portraitLeft.animation.addByPrefix('enter', 'Senpai Portrait Enter', 24, false);
		portraitLeft.setGraphicSize(Std.int(portraitLeft.width * PlayState.daPixelZoom * 0.9));
		portraitLeft.updateHitbox();
		portraitLeft.scrollFactor.set();
		portraitLeft.visible = false;
		add(portraitLeft);

		portraitRight = new FlxSprite(0, 40);
		portraitRight.frames = Paths.getSparrowAtlas('weeb/bfPortrait');
		portraitRight.animation.addByPrefix('enter', 'Boyfriend portrait enter', 24, false);
		portraitRight.setGraphicSize(Std.int(portraitRight.width * PlayState.daPixelZoom * 0.9));
		portraitRight.updateHitbox();
		portraitRight.scrollFactor.set();
		portraitRight.visible = false;
		add(portraitRight);

		box = new FlxSprite(-20, 45);
		
		var hasDialog:Bool = false;

		switch (PlayState.SONG.songID)
		{
			case 'senpai':
			{
				hasDialog = true;

				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-pixel');
				box.animation.addByPrefix('normalOpen', 'Text Box Appear', 24, false);
				box.animation.addByIndices('normal', 'Text Box Appear', [4], "", 24);
			}
			case 'roses':
			{
				hasDialog = true;

				FlxG.sound.play(Paths.getSound('ANGRY_TEXT_BOX'));

				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-senpaiMad');
				box.animation.addByPrefix('normalOpen', 'SENPAI ANGRY IMPACT SPEECH', 24, false);
				box.animation.addByIndices('normal', 'SENPAI ANGRY IMPACT SPEECH', [4], "", 24);
			}
			case 'thorns':
			{
				hasDialog = true;

				box.frames = Paths.getSparrowAtlas('weeb/pixelUI/dialogueBox-evil');
				box.animation.addByPrefix('normalOpen', 'Spirit Textbox spawn', 24, false);
				box.animation.addByIndices('normal', 'Spirit Textbox spawn', [11], "", 24);

				var face:FlxSprite = new FlxSprite(320, 170);
				face.loadGraphic(Paths.getImage('weeb/spiritFaceForward'));
				face.setGraphicSize(Std.int(face.width * 6));
				add(face);
			}
		}

		this.dialogueList = dialogueList;
		
		if (!hasDialog) return;
		
		box.animation.play('normalOpen');
		box.setGraphicSize(Std.int(box.width * PlayState.daPixelZoom * 0.9));
		box.updateHitbox();
		add(box);

		box.screenCenter(X);
		portraitLeft.screenCenter(X);

		handSelect = new FlxSprite(1042, 590);
		handSelect.loadGraphic(Paths.getImage('weeb/pixelUI/hand_textbox'));
		handSelect.setGraphicSize(Std.int(handSelect.width * PlayState.daPixelZoom * 0.9));
		handSelect.updateHitbox();
		handSelect.visible = false;
		add(handSelect);

		talkingRight = !talkingRight;

		dropText = new FlxText(242, 502, Std.int(FlxG.width * 0.6), "", 32);
		dropText.font = Paths.getFont('pixel.otf');
		dropText.color = 0xFFD89494;
		add(dropText);

		swagDialogue = new FlxTypeText(240, 500, Std.int(FlxG.width * 0.6), "", 32);
		swagDialogue.font = Paths.getFont('pixel.otf');
		swagDialogue.color = 0xFF3F2021;
		swagDialogue.sounds = [FlxG.sound.load(Paths.getSound('pixelText'), 0.6)];
		add(swagDialogue);
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;
	var dialogueEnded:Bool = false;

	public override function update(elapsed:Float)
	{
		super.update(elapsed);

		switch (PlayState.SONG.songID)
		{
			case 'roses':
			{
				portraitLeft.visible = false;
			}
			case 'thorns':
			{
				portraitLeft.color = FlxColor.BLACK;
				swagDialogue.color = FlxColor.WHITE;
				dropText.color = FlxColor.BLACK;
			}
		}

		dropText.text = swagDialogue.text;

		if (box.animation.curAnim != null)
		{
			if (box.animation.curAnim.name == 'normalOpen' && box.animation.curAnim.finished)
			{
				box.animation.play('normal');
				dialogueOpened = true;
			}
		}

		if (dialogueOpened && !dialogueStarted)
		{
			startDialogue();
			dialogueStarted = true;
		}

		if (FlxG.keys.justPressed.ANY && dialogueEnded)
		{
			FlxG.sound.play(Paths.getSound('clickText'), 0.8);

			if (dialogueList[1] == null && dialogueList[0] != null)
			{
				if (!isEnding)
				{
					isEnding = true;

					switch (PlayState.SONG.songID)
					{
						case 'senpai' | 'thorns':
						{
							FlxG.sound.music.fadeOut(2.2, 0);
						}
					}

					new FlxTimer().start(0.2, function(tmr:FlxTimer):Void
					{
						box.alpha -= 1 / 5;
						bgFade.alpha -= 1 / 5 * 0.7;
						portraitLeft.visible = false;
						portraitRight.visible = false;
						swagDialogue.alpha -= 1 / 5;
						handSelect.alpha -= 1 / 5;
						dropText.alpha = swagDialogue.alpha;
					}, 5);

					new FlxTimer().start(1.2, function(tmr:FlxTimer):Void
					{
						if (finishThing != null) {
							finishThing();
						}

						kill();
					});
				}
			}
			else
			{
				FlxG.sound.play(Paths.getSound('clickText'), 0.8);

				dialogueList.remove(dialogueList[0]);
				startDialogue();
			}
		}
		else if (FlxG.keys.justPressed.ANY && dialogueStarted)
		{
			FlxG.sound.play(Paths.getSound('clickText'), 0.8);

			swagDialogue.skip();
		}
	}

	var isEnding:Bool = false;

	function startDialogue():Void
	{
		cleanDialog();

		swagDialogue.resetText(dialogueList[0]);
		swagDialogue.start(0.04, true);
		swagDialogue.completeCallback = function():Void
		{
			handSelect.visible = true;
			dialogueEnded = true;
		};

		handSelect.visible = false;
		dialogueEnded = false;

		switch (curCharacter)
		{
			case 'dad':
			{
				portraitRight.visible = false;

				if (!portraitLeft.visible)
				{
					portraitLeft.visible = true;
					portraitLeft.animation.play('enter');
				}
			}
			case 'bf':
			{
				portraitLeft.visible = false;

				if (!portraitRight.visible)
				{
					portraitRight.visible = true;
					portraitRight.animation.play('enter');
				}
			}
		}
	}

	function cleanDialog():Void
	{
		var splitName:Array<String> = dialogueList[0].split(":");
		curCharacter = splitName[1];
		dialogueList[0] = dialogueList[0].substr(splitName[1].length + 2).trim();
	}
}