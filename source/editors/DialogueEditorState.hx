package editors;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import haxe.Json;

import DialogueBoxPsych;

#if sys
import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
#end

import Alphabet;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import openfl.events.Event;
import flixel.util.FlxColor;
import lime.system.Clipboard;
import openfl.net.FileFilter;
import flixel.addons.ui.FlxUI;
import openfl.net.FileReference;
import openfl.events.IOErrorEvent;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;

using StringTools;

class DialogueEditorState extends MusicBeatUIState
{
	var character:DialogueCharacter;
	var box:FlxSprite;
	var daText:Null<TypedAlphabet>;

	var selectedText:FlxText;
	var animText:FlxText;

	var defaultLine:DialogueLine;
	var dialogueFile:DialogueFile = null;

	public override function create():Void
	{
		persistentUpdate = persistentDraw = true;

		FlxG.camera.bgColor = FlxColor.fromHSL(0, 0, 0.5);

		defaultLine = {
			portrait: DialogueCharacter.DEFAULT_CHARACTER,
			expression: 'talk',
			text: DEFAULT_TEXT,
			boxState: DEFAULT_BUBBLETYPE,
			speed: 0.05,
			sound: ''
		};

		dialogueFile = {
			dialogue: [
				copyDefaultLine()
			]
		};
		
		character = new DialogueCharacter();
		character.scrollFactor.set();
		add(character);

		box = new FlxSprite(70, 370);
		if (Paths.fileExists('images/speech_bubble.png', IMAGE)) {
			box.frames = Paths.getSparrowAtlas('speech_bubble');
		}
		else {
			box.frames = Paths.getSparrowAtlas('dialogue/speech_bubble');
		}
		box.scrollFactor.set();
		box.antialiasing = OptionData.globalAntialiasing;
		box.animation.addByPrefix('normal', 'speech bubble normal', 24);
		box.animation.addByPrefix('angry', 'AHH speech bubble', 24);
		box.animation.addByPrefix('center', 'speech bubble middle', 24);
		box.animation.addByPrefix('center-angry', 'AHH Speech Bubble middle', 24);
		box.animation.play('normal', true);
		box.setGraphicSize(Std.int(box.width * 0.9));
		box.updateHitbox();
		add(box);

		addEditorBox();

		FlxG.mouse.visible = true;

		var addLineText:FlxText = new FlxText(10, 10, FlxG.width - 20, 'Press O to remove the current dialogue line, Press P to add another line after the current one.', 8);
		addLineText.setFormat(Paths.getFont('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		addLineText.scrollFactor.set();
		add(addLineText);

		selectedText = new FlxText(10, 32, FlxG.width - 20, '', 8);
		selectedText.setFormat(Paths.getFont('vcr.ttf'), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		selectedText.scrollFactor.set();
		add(selectedText);

		animText = new FlxText(10, 62, FlxG.width - 20, '', 8);
		animText.setFormat(Paths.getFont('vcr.ttf'), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		animText.scrollFactor.set();
		add(animText);

		daText = new TypedAlphabet(DialogueBoxPsych.DEFAULT_TEXT_X, DialogueBoxPsych.DEFAULT_TEXT_Y, DEFAULT_TEXT);
		daText.scaleX = 0.7;
		daText.scaleY = 0.7;
		add(daText);

		changeText();

		super.create();
	}

	var UI_box:FlxUITabMenu;

	function addEditorBox():Void
	{
		var tabs = [
			{name: 'Dialogue Line', label: 'Dialogue Line'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(250, 210);
		UI_box.x = FlxG.width - UI_box.width - 10;
		UI_box.y = 10;
		UI_box.scrollFactor.set();
		UI_box.alpha = 0.8;

		addDialogueLineUI();

		add(UI_box);
	}

	var characterInputText:FlxUIInputText;
	var lineInputText:FlxUIInputText;
	var angryCheckbox:FlxUICheckBox;
	var speedStepper:FlxUINumericStepper;
	var soundInputText:FlxUIInputText;

	function addDialogueLineUI():Void
	{
		var tab_group:FlxUI = new FlxUI(null, UI_box);
		tab_group.name = "Dialogue Line";

		characterInputText = new FlxUIInputText(10, 20, 80, DialogueCharacter.DEFAULT_CHARACTER, 8);
		blockPressWhileTypingOn.push(characterInputText);

		speedStepper = new FlxUINumericStepper(10, characterInputText.y + 40, 0.005, 0.05, 0, 0.5, 3);

		angryCheckbox = new FlxUICheckBox(speedStepper.x + 120, speedStepper.y, null, null, "Angry Textbox", 200);
		angryCheckbox.callback = function():Void
		{
			updateTextBox();
			dialogueFile.dialogue[curSelected].boxState = (angryCheckbox.checked ? 'angry' : 'normal');
		};

		soundInputText = new FlxUIInputText(10, speedStepper.y + 40, 150, '', 8);
		blockPressWhileTypingOn.push(soundInputText);
		
		lineInputText = new FlxUIInputText(10, soundInputText.y + 35, 200, DEFAULT_TEXT, 8);
		blockPressWhileTypingOn.push(lineInputText);

		var loadButton:FlxUIButton = new FlxUIButton(20, lineInputText.y + 25, "Load Dialogue", loadDialogue);
		var saveButton:FlxUIButton = new FlxUIButton(loadButton.x + 120, loadButton.y, "Save Dialogue", saveDialogue);

		tab_group.add(new FlxText(10, speedStepper.y - 18, 0, 'Interval/Speed (ms):'));
		tab_group.add(new FlxText(10, characterInputText.y - 18, 0, 'Character:'));
		tab_group.add(new FlxText(10, soundInputText.y - 18, 0, 'Sound file name:'));
		tab_group.add(new FlxText(10, lineInputText.y - 18, 0, 'Text:'));
		tab_group.add(characterInputText);
		tab_group.add(angryCheckbox);
		tab_group.add(speedStepper);
		tab_group.add(soundInputText);
		tab_group.add(lineInputText);
		tab_group.add(loadButton);
		tab_group.add(saveButton);
		UI_box.addGroup(tab_group);
	}

	function copyDefaultLine():DialogueLine
	{
		var copyLine:DialogueLine = {
			portrait: defaultLine.portrait,
			expression: defaultLine.expression,
			text: defaultLine.text,
			boxState: defaultLine.boxState,
			speed: defaultLine.speed,
			sound: ''
		};

		return copyLine;
	}

	function updateTextBox():Void
	{
		box.flipX = false;

		var isAngry:Bool = angryCheckbox.checked;
		var anim:String = isAngry ? 'angry' : 'normal';

		switch (character.jsonFile.dialogue_pos)
		{
			case 'left':
			{
				box.flipX = true;
			}
			case 'center':
			{
				if (isAngry) {
					anim = 'center-angry';
				}
				else {
					anim = 'center';
				}
			}
		}

		box.animation.play(anim, true);
		DialogueBoxPsych.updateBoxOffsets(box);
	}

	function reloadCharacter():Void
	{
		character.frames = Paths.getSparrowAtlas('dialogue/' + character.jsonFile.image);
		character.jsonFile = character.jsonFile;
		character.reloadAnimations();
		character.setGraphicSize(Std.int(character.width * DialogueCharacter.DEFAULT_SCALE * character.jsonFile.scale));
		character.updateHitbox();
		character.x = DialogueBoxPsych.LEFT_CHAR_X;
		character.y = DialogueBoxPsych.DEFAULT_CHAR_Y;

		switch (character.jsonFile.dialogue_pos)
		{
			case 'right':
			{
				character.x = FlxG.width - character.width + DialogueBoxPsych.RIGHT_CHAR_X;
			}
			case 'center':
			{
				character.x = FlxG.width / 2;
				character.x -= character.width / 2;
			}
		}

		character.x += character.jsonFile.position[0];
		character.y += character.jsonFile.position[1];
		character.playAnim(); // Plays random animation

		characterAnimSpeed();

		if (character.animation.curAnim != null && character.jsonFile.animations != null) {
			animText.text = 'Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';
		}
		else {
			animText.text = 'ERROR! NO ANIMATIONS FOUND';
		}
	}

	private static var DEFAULT_TEXT:String = "coolswag";
	private static var DEFAULT_SPEED:Float = 0.05;
	private static var DEFAULT_BUBBLETYPE:String = "normal";

	function reloadText(skipDialogue:Bool):Void
	{
		var textToType:String = lineInputText.text;
		if (textToType == null || textToType.length < 1) textToType = ' ';

		daText.text = textToType;
		daText.resetDialogue();

		if (skipDialogue) {
			daText.finishText();
		}
		else if (daText.delay > 0)
		{
			if (character.jsonFile.animations.length > curAnim && character.jsonFile.animations[curAnim] != null) {
				character.playAnim(character.jsonFile.animations[curAnim].anim);
			}

			characterAnimSpeed();
		}

		daText.y = DialogueBoxPsych.DEFAULT_TEXT_Y;
		if (daText.rows > 2) daText.y -= DialogueBoxPsych.LONG_TEXT_ADD;

		#if DISCORD_ALLOWED
		var rpcText:String = lineInputText.text;
		if (rpcText == null || rpcText.length < 1) rpcText = '(Empty)';
		if (rpcText.length < 3) rpcText += '   '; // Fixes a bug on RPC that triggers an error when the text is too short

		DiscordClient.changePresence("Dialogue Editor", rpcText); // Updating Discord Rich Presence
		#end
	}

	public override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>):Void 
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == characterInputText)
			{
				character.reloadCharacterJson(characterInputText.text);
				reloadCharacter();

				if (character.jsonFile.animations.length > 0)
				{
					curAnim = 0;

					if (character.jsonFile.animations.length > curAnim && character.jsonFile.animations[curAnim] != null)
					{
						character.playAnim(character.jsonFile.animations[curAnim].anim, daText.finishedText);
						animText.text = 'Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';
					}
					else {
						animText.text = 'ERROR! NO ANIMATIONS FOUND';
					}

					characterAnimSpeed();
				}

				dialogueFile.dialogue[curSelected].portrait = characterInputText.text;

				reloadText(false);
				updateTextBox();
			}
			else if (sender == lineInputText)
			{
				dialogueFile.dialogue[curSelected].text = lineInputText.text;
				
				daText.text = lineInputText.text;
				if (daText.text == null) daText.text = '';

				reloadText(true);
			}
			else if (sender == soundInputText)
			{
				daText.finishText();
				dialogueFile.dialogue[curSelected].sound = soundInputText.text;

				daText.sound = soundInputText.text;
				if (daText.sound == null) daText.sound = '';
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender == speedStepper))
		{
			dialogueFile.dialogue[curSelected].speed = speedStepper.value;

			if (Math.isNaN(dialogueFile.dialogue[curSelected].speed) || dialogueFile.dialogue[curSelected].speed == null || dialogueFile.dialogue[curSelected].speed < 0.001) {
				dialogueFile.dialogue[curSelected].speed = 0.0;
			}

			daText.delay = dialogueFile.dialogue[curSelected].speed;
			reloadText(false);
		}
	}

	var curSelected:Int = 0;
	var curAnim:Int = 0;
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	var transitioning:Bool = false;

	public override function update(elapsed:Float):Void
	{
		if (transitioning)
		{
			super.update(elapsed);
			return;
		}

		if (character.animation.curAnim != null)
		{
			if (daText.finishedText)
			{
				if (character.animationIsLoop() && character.animation.curAnim.finished) {
					character.playAnim(character.animation.curAnim.name, true);
				}
			}
			else if (character.animation.curAnim.finished) {
				character.animation.curAnim.restart();
			}
		}

		var blockInput:Bool = false;

		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];

				blockInput = true;

				if (FlxG.keys.justPressed.ENTER)
				{
					if (inputText == lineInputText)
					{
						inputText.text += '\\n';
						inputText.caretIndex += 2;
					}
					else {
						inputText.hasFocus = false;
					}
				}

				break;
			}
		}

		if (!blockInput)
		{
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;

			if (FlxG.keys.justPressed.SPACE) {
				reloadText(false);
			}

			if (FlxG.keys.justPressed.ESCAPE) {
				FlxG.switchState(new MasterEditorMenu());
			}

			var negaMult:Array<Int> = [1, -1];
			var controlAnim:Array<Bool> = [FlxG.keys.justPressed.W, FlxG.keys.justPressed.S];
			var controlText:Array<Bool> = [FlxG.keys.justPressed.D, FlxG.keys.justPressed.A];

			for (i in 0...controlAnim.length)
			{
				if (controlAnim[i] && character.jsonFile.animations.length > 0)
				{
					curAnim -= negaMult[i];

					if (curAnim < 0)
						curAnim = character.jsonFile.animations.length - 1;
					else if (curAnim >= character.jsonFile.animations.length)
						curAnim = 0;

					var animToPlay:String = character.jsonFile.animations[curAnim].anim;

					if (character.dialogueAnimations.exists(animToPlay))
					{
						character.playAnim(animToPlay, daText.finishedText);
						dialogueFile.dialogue[curSelected].expression = animToPlay;
					}

					animText.text = 'Animation: ' + animToPlay + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';
				}

				if (controlText[i]) {
					changeText(negaMult[i]);
				}
			}

			if (FlxG.keys.justPressed.O)
			{
				dialogueFile.dialogue.remove(dialogueFile.dialogue[curSelected]);

				if (dialogueFile.dialogue.length < 1) //You deleted everything, dumbo!
				{
					dialogueFile.dialogue = [
						copyDefaultLine()
					];
				}

				changeText();
			}
			else if (FlxG.keys.justPressed.P)
			{
				dialogueFile.dialogue.insert(curSelected + 1, copyDefaultLine());
				changeText(1);
			}
		}

		super.update(elapsed);
	}

	function changeText(add:Int = 0):Void
	{
		curSelected = CoolUtil.boundSelection(curSelected + add, dialogueFile.dialogue.length);

		var curDialogue:DialogueLine = dialogueFile.dialogue[curSelected];

		characterInputText.text = curDialogue.portrait;
		lineInputText.text = curDialogue.text;

		angryCheckbox.checked = (curDialogue.boxState == 'angry');
		speedStepper.value = curDialogue.speed;

		if (curDialogue.sound == null) curDialogue.sound = '';
		soundInputText.text = curDialogue.sound;

		daText.delay = speedStepper.value;
		daText.sound = soundInputText.text;
		if (daText.sound != null && daText.sound.trim() == '') daText.sound = 'dialogue';

		daText.y = DialogueBoxPsych.DEFAULT_TEXT_Y;
		if (daText.rows > 2) daText.y -= DialogueBoxPsych.LONG_TEXT_ADD;

		curAnim = 0;
		character.reloadCharacterJson(characterInputText.text);

		reloadCharacter();
		reloadText(false);
		updateTextBox();

		var leLength:Int = character.jsonFile.animations.length;

		if (leLength > 0)
		{
			for (i in 0...leLength) 
			{
				var leAnim:DialogueAnimArray = character.jsonFile.animations[i];

				if (leAnim != null && leAnim.anim == curDialogue.expression)
				{
					curAnim = i;
					break;
				}
			}

			character.playAnim(character.jsonFile.animations[curAnim].anim, daText.finishedText);
			animText.text = 'Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + leLength + ') - Press W or S to scroll';
		}
		else {
			animText.text = 'ERROR! NO ANIMATIONS FOUND';
		}

		characterAnimSpeed();

		selectedText.text = 'Line: (' + (curSelected + 1) + ' / ' + dialogueFile.dialogue.length + ') - Press A or D to scroll';
	}

	function characterAnimSpeed():Void
	{
		if (character.animation.curAnim != null)
		{
			var speed:Float = speedStepper.value;
			var rate:Float = 24 - (((speed - 0.05) / 5) * 480);

			if (rate < 12)
				rate = 12;
			else if (rate > 48)
				rate = 48;

			character.animation.curAnim.frameRate = rate;
		}
	}

	var _file:FileReference = null;

	function loadDialogue():Void
	{
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');
		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([jsonFilter]);
	}

	function onLoadComplete(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		#if sys
		var fullPath:String = null;
		@:privateAccess
		if (_file.__path != null) fullPath = _file.__path;

		if (fullPath != null)
		{
			var rawJson:String = File.getContent(fullPath);

			if (rawJson != null)
			{
				var loadedDialog:DialogueFile = cast Json.parse(rawJson);

				if (loadedDialog.dialogue != null && loadedDialog.dialogue.length > 0) //Make sure it's really a dialogue file
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);

					Debug.logInfo("Successfully loaded file: " + cutName);

					dialogueFile = loadedDialog;

					changeText();
					_file = null;
	
					return;
				}
			}
		}

		_file = null;
		#else
		Debug.logError("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onLoadCancel(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		_file = null;

		Debug.logInfo("Cancelled file loading.");
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onLoadError(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		_file = null;

		Debug.logError("Problem loading file");
	}

	function saveDialogue():Void
	{
		var data:String = Json.stringify(dialogueFile, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);

			#if MODS_ALLOWED
			_file.save(data.trim(), #if sys CoolUtil.convPathShit(Paths.modFolders('data/' + #end 'dialogue.json' #if sys )) #end);
			#else
			_file.save(data.trim(), #if sys CoolUtil.convPathShit(Paths.getJson('data/' + #end 'dialogue.json' #if sys )) #end);
			#end
		}
	}

	function onSaveComplete(event:Event):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);

		_file = null;

		Debug.logInfo("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	function onSaveCancel(event:Event):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);

		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	function onSaveError(event:Event):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);

		_file = null;

		Debug.logError("Problem saving file");
	}
}