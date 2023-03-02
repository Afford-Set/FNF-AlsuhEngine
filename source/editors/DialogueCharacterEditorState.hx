package editors;

import haxe.Json;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import DialogueBoxPsych;

#if sys
import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxSubState;
import flixel.text.FlxText;
import openfl.utils.Assets;
import flixel.ui.FlxButton;
import openfl.events.Event;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.system.Clipboard;
import openfl.net.FileFilter;
import flixel.addons.ui.FlxUI;
import openfl.net.FileReference;
import flixel.input.FlxKeyManager;
import openfl.events.IOErrorEvent;
import flixel.group.FlxSpriteGroup;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;

using StringTools;

class DialogueCharacterEditorState extends MusicBeatUIState
{
	var box:FlxSprite;
	var daText:Null<TypedAlphabet> = null;

	private static var TIP_TEXT_MAIN:String =
		'JKLI - Move camera (Hold Shift to move 4x faster)
		\nQ/E - Zoom out/in
		\nR - Reset Camera
		\nH - Toggle Speech Bubble
		\nSpace - Reset text';

	private static var TIP_TEXT_OFFSET:String =
		'JKLI - Move camera (Hold Shift to move 4x faster)
		\nQ/E - Zoom out/in
		\nR - Reset Camera
		\nH - Toggle Ghosts
		\nWASD - Move Looping animation offset (Red)
		\nArrow Keys - Move Idle/Finished animation offset (Blue)
		\nHold Shift to move offsets 10x faster';

	var tipText:FlxText;
	var offsetLoopText:FlxText;
	var offsetIdleText:FlxText;
	var animText:FlxText;

	var camGame:FlxCamera;
	var camHUD:FlxCamera;

	var mainGroup:FlxSpriteGroup;
	var hudGroup:FlxSpriteGroup;

	var character:DialogueCharacter;
	var ghostLoop:DialogueCharacter;
	var ghostIdle:DialogueCharacter;

	var curAnim:Int = 0;

	public override function create():Void
	{
		super.create();

		persistentUpdate = persistentDraw = true;

		camGame = new FlxCamera();
		camHUD = new FlxCamera();
		camGame.bgColor = FlxColor.fromHSL(0, 0, 0.5);
		camHUD.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camHUD, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		mainGroup = new FlxSpriteGroup();
		mainGroup.cameras = [camGame];
		add(mainGroup);

		hudGroup = new FlxSpriteGroup();
		hudGroup.cameras = [camGame];
		add(hudGroup);

		character = new DialogueCharacter();
		character.scrollFactor.set();
		mainGroup.add(character);
		
		ghostLoop = new DialogueCharacter();
		ghostLoop.alpha = 0;
		ghostLoop.color = FlxColor.RED;
		ghostLoop.isGhost = true;
		ghostLoop.jsonFile = character.jsonFile;
		ghostLoop.cameras = [camGame];
		add(ghostLoop);
		
		ghostIdle = new DialogueCharacter();
		ghostIdle.alpha = 0;
		ghostIdle.color = FlxColor.BLUE;
		ghostIdle.isGhost = true;
		ghostIdle.jsonFile = character.jsonFile;
		ghostIdle.cameras = [camGame];
		add(ghostIdle);

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
		box.animation.addByPrefix('center', 'speech bubble middle', 24);
		box.animation.play('normal', true);
		box.setGraphicSize(Std.int(box.width * 0.9));
		box.updateHitbox();
		hudGroup.add(box);

		tipText = new FlxText(10, 10, FlxG.width - 20, TIP_TEXT_MAIN, 8);
		tipText.setFormat(Paths.getFont('vcr.ttf'), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		tipText.cameras = [camHUD];
		tipText.scrollFactor.set();
		add(tipText);

		offsetLoopText = new FlxText(10, 10, 0, '', 32);
		offsetLoopText.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		offsetLoopText.cameras = [camHUD];
		offsetLoopText.scrollFactor.set();
		offsetLoopText.visible = false;
		add(offsetLoopText);

		offsetIdleText = new FlxText(10, 46, 0, '', 32);
		offsetIdleText.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		offsetIdleText.cameras = [camHUD];
		offsetIdleText.scrollFactor.set();
		offsetIdleText.visible = false;
		add(offsetIdleText);

		animText = new FlxText(10, 22, FlxG.width - 20, '', 8);
		animText.setFormat(Paths.getFont('vcr.ttf'), 24, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		animText.scrollFactor.set();
		add(animText);

		reloadCharacter();
		updateTextBox();

		daText = new TypedAlphabet(DialogueBoxPsych.DEFAULT_TEXT_X, DialogueBoxPsych.DEFAULT_TEXT_Y, '', 0.05, false);
		daText.scaleX = 0.7;
		daText.scaleY = 0.7;
		daText.text = DEFAULT_TEXT;
		hudGroup.add(daText);

		addEditorBox();

		FlxG.mouse.visible = true;

		updateCharTypeBox();
	}

	var UI_typebox:FlxUITabMenu;
	var UI_mainbox:FlxUITabMenu;

	function addEditorBox():Void
	{
		var tabs = [
			{name: 'Character Type', label: 'Character Type'},
		];

		UI_typebox = new FlxUITabMenu(null, tabs, true);
		UI_typebox.resize(120, 180);
		UI_typebox.x = 900;
		UI_typebox.y = FlxG.height - UI_typebox.height - 50;
		UI_typebox.scrollFactor.set();
		UI_typebox.camera = camGame;
		addTypeUI();
		add(UI_typebox);

		var tabs = [
			{name: 'Animations', label: 'Animations'},
			{name: 'Character', label: 'Character'},
		];

		UI_mainbox = new FlxUITabMenu(null, tabs, true);
		UI_mainbox.resize(200, 250);
		UI_mainbox.x = UI_typebox.x + UI_typebox.width;
		UI_mainbox.y = FlxG.height - UI_mainbox.height - 50;
		UI_mainbox.scrollFactor.set();
		UI_mainbox.camera = camGame;

		addAnimationsUI();
		addCharacterUI();

		add(UI_mainbox);

		UI_mainbox.selected_tab_id = 'Character';
		lastTab = UI_mainbox.selected_tab_id;
	}

	var leftCheckbox:FlxUICheckBox;
	var centerCheckbox:FlxUICheckBox;
	var rightCheckbox:FlxUICheckBox;

	function addTypeUI():Void
	{
		var tab_group = new FlxUI(null, UI_typebox);
		tab_group.name = "Character Type";

		leftCheckbox = new FlxUICheckBox(10, 20, null, null, "Left", 100);
		leftCheckbox.callback = function():Void
		{
			character.jsonFile.dialogue_pos = 'left';
			updateCharTypeBox();
		};

		centerCheckbox = new FlxUICheckBox(leftCheckbox.x, leftCheckbox.y + 40, null, null, "Center", 100);
		centerCheckbox.callback = function():Void
		{
			character.jsonFile.dialogue_pos = 'center';
			updateCharTypeBox();
		};

		rightCheckbox = new FlxUICheckBox(centerCheckbox.x, centerCheckbox.y + 40, null, null, "Right", 100);
		rightCheckbox.callback = function():Void
		{
			character.jsonFile.dialogue_pos = 'right';
			updateCharTypeBox();
		};

		tab_group.add(leftCheckbox);
		tab_group.add(centerCheckbox);
		tab_group.add(rightCheckbox);

		UI_typebox.addGroup(tab_group);
	}

	var curSelectedAnim:String;
	var animationArray:Array<String> = [];
	var animationDropDown:FlxUIDropDownMenuCustom;
	var animationInputText:FlxUIInputText;
	var loopInputText:FlxUIInputText;
	var idleInputText:FlxUIInputText;

	function addAnimationsUI():Void
	{
		var tab_group = new FlxUI(null, UI_mainbox);
		tab_group.name = "Animations";

		animationDropDown = new FlxUIDropDownMenuCustom(10, 30, FlxUIDropDownMenuCustom.makeStrIdLabelArray([''], true), function(animation:String):Void
		{
			var anim:String = animationArray[Std.parseInt(animation)];

			if (character.dialogueAnimations.exists(anim))
			{
				ghostLoop.playAnim(anim);
				ghostIdle.playAnim(anim, true);

				curSelectedAnim = anim;

				var animShit:DialogueAnimArray = character.dialogueAnimations.get(curSelectedAnim);
				offsetLoopText.text = 'Loop: ' + animShit.loop_offsets;
				offsetIdleText.text = 'Idle: ' + animShit.idle_offsets;

				animationInputText.text = animShit.anim;
				loopInputText.text = animShit.loop_name;
				idleInputText.text = animShit.idle_name;
			}
		});
		
		animationInputText = new FlxUIInputText(15, 85, 80, '', 8);
		blockPressWhileTypingOn.push(animationInputText);

		loopInputText = new FlxUIInputText(animationInputText.x, animationInputText.y + 35, 150, '', 8);
		blockPressWhileTypingOn.push(loopInputText);

		idleInputText = new FlxUIInputText(loopInputText.x, loopInputText.y + 40, 150, '', 8);
		blockPressWhileTypingOn.push(idleInputText);
		
		var addUpdateButton:FlxButton = new FlxButton(10, idleInputText.y + 30, "Add/Update", function():Void
		{
			var theAnim:String = animationInputText.text.trim();

			if (character.dialogueAnimations.exists(theAnim)) // Update
			{
				for (i in 0...character.jsonFile.animations.length)
				{
					var animArray:DialogueAnimArray = character.jsonFile.animations[i];

					if (animArray.anim.trim() == theAnim)
					{
						animArray.loop_name = loopInputText.text;
						animArray.idle_name = idleInputText.text;
						break;
					}
				}

				character.reloadAnimations();
				ghostLoop.reloadAnimations();
				ghostIdle.reloadAnimations();

				if (curSelectedAnim == theAnim)
				{
					ghostLoop.playAnim(theAnim);
					ghostIdle.playAnim(theAnim, true);
				}
			}
			else // Add
			{
				var newAnim:DialogueAnimArray = {
					anim: theAnim,
					loop_name: loopInputText.text,
					loop_offsets: [0, 0],
					idle_name: idleInputText.text,
					idle_offsets: [0, 0]
				}

				character.jsonFile.animations.push(newAnim);

				var lastSelected:String = animationDropDown.selectedLabel;
				character.reloadAnimations();
				ghostLoop.reloadAnimations();
				ghostIdle.reloadAnimations();
				reloadAnimationsDropDown();

				animationDropDown.selectedLabel = lastSelected;
			}
		});
		
		var removeUpdateButton:FlxButton = new FlxButton(100, addUpdateButton.y, "Remove", function():Void
		{
			for (i in 0...character.jsonFile.animations.length) 
			{
				var animArray:DialogueAnimArray = character.jsonFile.animations[i];

				if (animArray != null && animArray.anim.trim() == animationInputText.text.trim())
				{
					var lastSelected:String = animationDropDown.selectedLabel;
					character.jsonFile.animations.remove(animArray);
					character.reloadAnimations();
					ghostLoop.reloadAnimations();
					ghostIdle.reloadAnimations();

					reloadAnimationsDropDown();

					if (character.jsonFile.animations.length > 0 && lastSelected == animArray.anim.trim())
					{
						var animToPlay:String = character.jsonFile.animations[0].anim;
						ghostLoop.playAnim(animToPlay);
						ghostIdle.playAnim(animToPlay, true);
					}

					animationDropDown.selectedLabel = lastSelected;
					animationInputText.text = '';
					loopInputText.text = '';
					idleInputText.text = '';

					break;
				}
			}
		});
		
		tab_group.add(new FlxText(animationDropDown.x, animationDropDown.y - 18, 0, 'Animations:'));
		tab_group.add(new FlxText(animationInputText.x, animationInputText.y - 18, 0, 'Animation name:'));
		tab_group.add(new FlxText(loopInputText.x, loopInputText.y - 18, 0, 'Loop name on .XML file:'));
		tab_group.add(new FlxText(idleInputText.x, idleInputText.y - 18, 0, 'Idle/Finished name on .XML file:'));

		tab_group.add(animationInputText);
		tab_group.add(loopInputText);
		tab_group.add(idleInputText);
		tab_group.add(addUpdateButton);
		tab_group.add(removeUpdateButton);
		tab_group.add(animationDropDown);

		UI_mainbox.addGroup(tab_group);

		reloadAnimationsDropDown();
	}

	function reloadAnimationsDropDown():Void
	{
		animationArray = [];

		for (anim in character.jsonFile.animations) {
			animationArray.push(anim.anim);
		}

		if (animationArray.length < 1) animationArray = [''];

		animationDropDown.setData(FlxUIDropDownMenuCustom.makeStrIdLabelArray(animationArray, true));
	}

	var imageInputText:FlxUIInputText;
	var scaleStepper:FlxUINumericStepper;
	var xStepper:FlxUINumericStepper;
	var yStepper:FlxUINumericStepper;
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];

	function addCharacterUI():Void
	{
		var tab_group = new FlxUI(null, UI_mainbox);
		tab_group.name = "Character";

		imageInputText = new FlxUIInputText(10, 30, 80, character.jsonFile.image, 8);
		blockPressWhileTypingOn.push(imageInputText);
		xStepper = new FlxUINumericStepper(imageInputText.x, imageInputText.y + 50, 10, character.jsonFile.position[0], -2000, 2000, 0);
		yStepper = new FlxUINumericStepper(imageInputText.x + 80, xStepper.y, 10, character.jsonFile.position[1], -2000, 2000, 0);
		scaleStepper = new FlxUINumericStepper(imageInputText.x, xStepper.y + 50, 0.05, character.jsonFile.scale, 0.1, 10, 2);

		var noAntialiasingCheckbox:FlxUICheckBox = new FlxUICheckBox(scaleStepper.x + 80, scaleStepper.y, null, null, "No Antialiasing", 100);
		noAntialiasingCheckbox.checked = character.jsonFile.no_antialiasing;
		noAntialiasingCheckbox.callback = function():Void
		{
			character.jsonFile.no_antialiasing = noAntialiasingCheckbox.checked;
			character.antialiasing = !character.jsonFile.no_antialiasing;
		};
		
		tab_group.add(new FlxText(10, imageInputText.y - 18, 0, 'Image file name:'));
		tab_group.add(new FlxText(10, xStepper.y - 18, 0, 'Position Offset:'));
		tab_group.add(new FlxText(10, scaleStepper.y - 18, 0, 'Scale:'));
		tab_group.add(imageInputText);
		tab_group.add(xStepper);
		tab_group.add(yStepper);
		tab_group.add(scaleStepper);
		tab_group.add(noAntialiasingCheckbox);

		var reloadImageButton:FlxButton = new FlxButton(10, scaleStepper.y + 60, "Reload Image", function():Void
		{
			reloadCharacter();
		});

		var loadButton:FlxButton = new FlxButton(reloadImageButton.x + 100, reloadImageButton.y, "Load Character", function():Void
		{
			loadCharacter();
		});

		var saveButton:FlxButton = new FlxButton(loadButton.x, reloadImageButton.y - 25, "Save Character", function():Void
		{
			saveCharacter();
		});

		tab_group.add(reloadImageButton);
		tab_group.add(loadButton);
		tab_group.add(saveButton);

		UI_mainbox.addGroup(tab_group);
	}
	
	function updateCharTypeBox():Void
	{
		leftCheckbox.checked = false;
		centerCheckbox.checked = false;
		rightCheckbox.checked = false;

		switch (character.jsonFile.dialogue_pos)
		{
			case 'left':
				leftCheckbox.checked = true;
			case 'center':
				centerCheckbox.checked = true;
			case 'right':
				rightCheckbox.checked = true;
		}

		reloadCharacter();
		updateTextBox();
	}

	private static var DEFAULT_TEXT:String = 'Lorem ipsum dolor sit amet';

	function reloadCharacter():Void
	{
		var charsArray:Array<DialogueCharacter> = [character, ghostLoop, ghostIdle];

		for (char in charsArray)
		{
			char.frames = Paths.getSparrowAtlas('dialogue/' + character.jsonFile.image);
			char.jsonFile = character.jsonFile;
			char.reloadAnimations();
			char.setGraphicSize(Std.int(char.width * DialogueCharacter.DEFAULT_SCALE * character.jsonFile.scale));
			char.updateHitbox();
		}

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

		character.x += character.jsonFile.position[0] + mainGroup.x;
		character.y += character.jsonFile.position[1] + mainGroup.y;
		character.playAnim(character.jsonFile.animations[0].anim);

		if (character.jsonFile.animations.length > 0)
		{
			curSelectedAnim = character.jsonFile.animations[0].anim;

			var animShit:DialogueAnimArray = character.dialogueAnimations.get(curSelectedAnim);
			ghostLoop.playAnim(animShit.anim);
			ghostIdle.playAnim(animShit.anim, true);

			offsetLoopText.text = 'Loop: ' + animShit.loop_offsets;
			offsetIdleText.text = 'Idle: ' + animShit.idle_offsets;
		}

		curAnim = 0;
		animText.text = 'Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Dialogue Character Editor", "Editting: " + character.jsonFile.image); // Updating Discord Rich Presence
		#end
	}

	function updateTextBox():Void
	{
		box.flipX = false;

		var anim:String = 'normal';

		switch (character.jsonFile.dialogue_pos)
		{
			case 'left':
				box.flipX = true;
			case 'center':
				anim = 'center';
		}

		box.animation.play(anim, true);
		DialogueBoxPsych.updateBoxOffsets(box);
	}

	public override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>):Void
	{
		if (id == FlxUIInputText.CHANGE_EVENT && sender == imageInputText)
		{
			character.jsonFile.image = imageInputText.text;
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			if (sender == scaleStepper)
			{
				character.jsonFile.scale = scaleStepper.value;
				reloadCharacter();
			}
			else if (sender == xStepper)
			{
				character.jsonFile.position[0] = xStepper.value;
				reloadCharacter();
			}
			else if (sender == yStepper)
			{
				character.jsonFile.position[1] = yStepper.value;
				reloadCharacter();
			}
		}
	}

	var currentGhosts:Int = 0;
	var lastTab:String = 'Character';
	var transitioning:Bool = false;

	public override function update(elapsed:Float)
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
				if (character.animationIsLoop()) {
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

				if (FlxG.keys.justPressed.ENTER) inputText.hasFocus = false;

				break;
			}
		}

		if (!blockInput && !animationDropDown.dropPanel.visible)
		{
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;

			if (FlxG.keys.justPressed.SPACE && UI_mainbox.selected_tab_id == 'Character')
			{
				character.playAnim(character.jsonFile.animations[curAnim].anim);

				updateTextBox();
				daText.resetDialogue();
			}

			var offsetAdd:Int = FlxG.keys.pressed.SHIFT ? 10 : 1;
			var speed:Float = FlxG.keys.pressed.SHIFT ? 1200 : 300;

			var negaMult:Array<Int> = [1, 1, -1, -1];
			var controlArray:Array<Bool> = [FlxG.keys.pressed.J, FlxG.keys.pressed.I, FlxG.keys.pressed.L, FlxG.keys.pressed.K];
	
			for (i in 0...controlArray.length)
			{
				if (controlArray[i])
				{
					if (i % 2 == 1) {
						mainGroup.y += speed * elapsed * negaMult[i];
					}
					else {
						mainGroup.x += speed * elapsed * negaMult[i];
					}
				}
			}

			if (UI_mainbox.selected_tab_id == 'Animations' && curSelectedAnim != null && character.dialogueAnimations.exists(curSelectedAnim))
			{
				var moved:Bool = false;
				var animShit:DialogueAnimArray = character.dialogueAnimations.get(curSelectedAnim);

				var controlArrayLoop:Array<Bool> = [FlxG.keys.justPressed.A, FlxG.keys.justPressed.W, FlxG.keys.justPressed.D, FlxG.keys.justPressed.S];
				var controlArrayIdle:Array<Bool> = [FlxG.keys.justPressed.LEFT, FlxG.keys.justPressed.UP, FlxG.keys.justPressed.RIGHT, FlxG.keys.justPressed.DOWN];

				for (i in 0...controlArrayLoop.length)
				{
					if (controlArrayLoop[i])
					{
						if (i % 2 == 1) {
							animShit.loop_offsets[1] += offsetAdd * negaMult[i];
						}
						else {
							animShit.loop_offsets[0] += offsetAdd * negaMult[i];
						}

						moved = true;
					}
				}

				for (i in 0...controlArrayIdle.length)
				{
					if (controlArrayIdle[i])
					{
						if (i % 2 == 1) {
							animShit.idle_offsets[1] += offsetAdd * negaMult[i];
						}
						else {
							animShit.idle_offsets[0] += offsetAdd * negaMult[i];
						}

						moved = true;
					}
				}

				if (moved)
				{
					offsetLoopText.text = 'Loop: ' + animShit.loop_offsets;
					offsetIdleText.text = 'Idle: ' + animShit.idle_offsets;
					ghostLoop.offset.set(animShit.loop_offsets[0], animShit.loop_offsets[1]);
					ghostIdle.offset.set(animShit.idle_offsets[0], animShit.idle_offsets[1]);
				}
			}

			if (FlxG.keys.pressed.Q && camGame.zoom > 0.1)
			{
				camGame.zoom -= elapsed * camGame.zoom;
				if (camGame.zoom < 0.1) camGame.zoom = 0.1;
			}

			if (FlxG.keys.pressed.E && camGame.zoom < 1)
			{
				camGame.zoom += elapsed * camGame.zoom;
				if (camGame.zoom > 1) camGame.zoom = 1;
			}

			if (FlxG.keys.justPressed.H)
			{
				if (UI_mainbox.selected_tab_id == 'Animations')
				{
					currentGhosts++;
					if (currentGhosts > 2) currentGhosts = 0;

					ghostLoop.visible = (currentGhosts != 1);
					ghostIdle.visible = (currentGhosts != 2);
					ghostLoop.alpha = (currentGhosts == 2 ? 1 : 0.6);
					ghostIdle.alpha = (currentGhosts == 1 ? 1 : 0.6);
				}
				else
				{
					hudGroup.visible = !hudGroup.visible;
				}
			}

			if (FlxG.keys.justPressed.R)
			{
				camGame.zoom = 1;

				mainGroup.setPosition(0, 0);
				hudGroup.visible = true;
			}

			if (UI_mainbox.selected_tab_id != lastTab)
			{
				if (UI_mainbox.selected_tab_id == 'Animations')
				{
					hudGroup.alpha = 0;
					mainGroup.alpha = 0;
					ghostLoop.alpha = 0.6;
					ghostIdle.alpha = 0.6;

					tipText.text = TIP_TEXT_OFFSET;

					offsetLoopText.visible = true;
					offsetIdleText.visible = true;
					animText.visible = false;

					currentGhosts = 0;
				}
				else
				{
					hudGroup.alpha = 1;
					mainGroup.alpha = 1;
					ghostLoop.alpha = 0;
					ghostIdle.alpha = 0;

					tipText.text = TIP_TEXT_MAIN;

					offsetLoopText.visible = false;
					offsetIdleText.visible = false;
					animText.visible = true;

					updateTextBox();
					daText.resetDialogue();
					
					if (curAnim < 0)
						curAnim = character.jsonFile.animations.length - 1;
					else if (curAnim >= character.jsonFile.animations.length)
						curAnim = 0;
					
					character.playAnim(character.jsonFile.animations[curAnim].anim);
					animText.text = 'Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';
				}

				lastTab = UI_mainbox.selected_tab_id;
				currentGhosts = 0;
			}
			
			if (UI_mainbox.selected_tab_id == 'Character')
			{
				var negaMult:Array<Int> = [1, -1];
				var controlAnim:Array<Bool> = [FlxG.keys.justPressed.W, FlxG.keys.justPressed.S];

				if (controlAnim.contains(true))
				{
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

							if (character.dialogueAnimations.exists(animToPlay)) {
								character.playAnim(animToPlay, daText.finishedText);
							}
						}
					}

					animText.text = 'Animation: ' + character.jsonFile.animations[curAnim].anim + ' (' + (curAnim + 1) +' / ' + character.jsonFile.animations.length + ') - Press W or S to scroll';
				}
			}

			if (FlxG.keys.justPressed.ESCAPE)
			{
				FlxG.switchState(new MasterEditorMenu());
				transitioning = true;
			}

			ghostLoop.setPosition(character.x, character.y);
			ghostIdle.setPosition(character.x, character.y);
			hudGroup.x = mainGroup.x;
			hudGroup.y = mainGroup.y;
		}

		super.update(elapsed);
	}
	
	var _file:FileReference = null;

	function loadCharacter():Void
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
				var loadedChar:DialogueCharacterFile = cast Json.parse(rawJson);

				if (loadedChar.dialogue_pos != null) // Make sure it's really a dialogue character
				{
					var cutName:String = _file.name.substr(0, _file.name.length - 5);

					Debug.logInfo("Successfully loaded file: " + cutName);
					character.jsonFile = loadedChar;

					reloadCharacter();
					reloadAnimationsDropDown();
					updateCharTypeBox();
					updateTextBox();
					daText.resetDialogue();

					imageInputText.text = character.jsonFile.image;
					scaleStepper.value = character.jsonFile.scale;

					xStepper.value = character.jsonFile.position[0];
					yStepper.value = character.jsonFile.position[1];

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

		Debug.logError("Cancelled file loading.");
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

	function saveCharacter():Void
	{
		var data:String = Json.stringify(character.jsonFile, "\t");

		if (data.length > 0)
		{
			var splittedImage:Array<String> = imageInputText.text.trim().split('_');
			var characterName:String = splittedImage[0].toLowerCase().replace(' ', '');

			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);

			#if MODS_ALLOWED
			_file.save(data, #if sys CoolUtil.convPathShit(Paths.modFolders('portraits/' + #end characterName + ".json" #if sys )) #end);
			#else
			_file.save(data, #if sys CoolUtil.convPathShit(Paths.getJson('portraits/' + #end characterName + ".json" #if sys )) #end);
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