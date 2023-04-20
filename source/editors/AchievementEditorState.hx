package editors;

import haxe.Json;
import haxe.io.Path;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import Achievements;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.text.FlxText;
import openfl.events.Event;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.group.FlxGroup;
import openfl.net.FileFilter;
import flixel.addons.ui.FlxUI;
import openfl.net.FileReference;
import openfl.events.IOErrorEvent;
import flixel.graphics.FlxGraphic;
import flixel.addons.ui.FlxUIButton;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;
import flixel.system.debug.interaction.tools.Pointer;
import flixel.addons.transition.FlxTransitionableState;

using StringTools;

class AchievementEditorState extends MusicBeatUIState
{
	#if ACHIEVEMENTS_ALLOWED
	var award:AchievementFile = null;

	var icon:AttachedAchievement = null;
	var text:Alphabet = null;
	var bg:FlxSprite = null;

	var misses:Int = 0;
	var diff:String = 'hard';
	var color:Array<Int> = [255, 228, 0];
	var name(default, set):String = 'Your Achievement';
	var tag(default, set):String = 'your-achievement';
	var hidden:Bool = false;
	var week_nomiss:String = 'your-week_nomiss';
	var lua_code:String = '';
	var index:Int = -1;
	var song:String = 'your-song';
	var desc(default, set):String = 'Your description';

	function set_tag(value:String):String
	{
		if (value == null) {
			value = '';
		}

		tag = value;
		icon.changeAchievement(tag, true);

		return value;
	}

	function set_name(value:String):String
	{
		if (value == null || value.length < 1) {
			value = 'Invalid name';
		}

		name = value;
		text.text = name; // lol

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Achievement Editor", "Editting: " + name); // Updating Discord Rich Presence
		#end

		return value;
	}

	function set_desc(value:String):String
	{
		desc = value;

		descText.text = desc;
		descText.screenCenter(Y);
		descText.y += 270;

		descBox.setPosition(descText.x - 10, descText.y - 10);
		descBox.setGraphicSize(Std.int(descText.width + 20), Std.int(descText.height + 25));
		descBox.updateHitbox();

		var visible:Bool = desc != null && desc.length > 0;

		descText.visible = visible;
		descBox.visible = visible;

		return value;
	}

	private var descBox:FlxSprite = null;
	private var descText:FlxText = null;

	override function create():Void
	{
		if (award == null) {
			award = formatToAchievementFile();
		}

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
		bg.antialiasing = OptionData.globalAntialiasing;
		add(bg);

		text = new Alphabet(280, 270, name, false);
		add(text);

		icon = new AttachedAchievement(text.x - 105, text.y, tag);
		icon.sprTracker = text;
		add(icon);

		descBox = new FlxSprite();
		descBox.makeGraphic(1, 1, FlxColor.BLACK);
		descBox.alpha = 0.6;
		add(descBox);

		descText = new FlxText(50, 600, 1180, "", 32);
		descText.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		descText.scrollFactor.set();
		descText.borderSize = 2.4;
		add(descText);

		reloadVariables();
		addEditorBox();
		reloadAllShit();

		super.create();

		FlxG.mouse.visible = true;
	}

	var UI_box:FlxUITabMenu = null;
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];
	var blockPressWhileTypingOnStepper:Array<FlxUINumericStepper> = [];

	function addEditorBox():Void
	{
		var tabs = [
			{name: 'Achievement', label: 'Achievement'}
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(250, 375);
		UI_box.x = 1020;
		UI_box.y = 193;
		UI_box.scrollFactor.set();

		addAwardUI();

		UI_box.selected_tab_id = 'Achievement';
		add(UI_box);
	}

	var diffInputText:FlxUIInputText = null;
	var awardNameInputText:FlxUIInputText = null;
	var tagInputText:FlxUIInputText = null;
	var descInputText:FlxUIInputText = null;
	var luaFileInputText:FlxUIInputText = null;
	var weekInputText:FlxUIInputText = null;
	var indexStepper:FlxUINumericStepper = null;
	var bgColorStepperR:FlxUINumericStepper = null;
	var bgColorStepperG:FlxUINumericStepper = null;
	var bgColorStepperB:FlxUINumericStepper = null;
	var hiddenCheckbox:FlxUICheckBox = null;
	var songInputText:FlxUIInputText = null;
	var missesStepper:FlxUINumericStepper = null;

	var loadButton:FlxUIButton = null;
	var saveButton:FlxUIButton = null;
	var resetButton:FlxUIButton = null;

	function addAwardUI():Void
	{
		var tab_group:FlxUI = new FlxUI(null, UI_box);
		tab_group.name = "Achievement";

		awardNameInputText = new FlxUIInputText(10, 25, 150, name, 8);
		blockPressWhileTypingOn.push(awardNameInputText);

		tagInputText = new FlxUIInputText(10, awardNameInputText.y + 40, 75, tag, 8);
		blockPressWhileTypingOn.push(tagInputText);

		descInputText = new FlxUIInputText(10, tagInputText.y + 40, 230, desc, 8);
		blockPressWhileTypingOn.push(descInputText);

		luaFileInputText = new FlxUIInputText(10, descInputText.y + 40, 75, lua_code #if !LUA_ALLOWED + ' (platform not supported)' #end, 8);
		blockPressWhileTypingOn.push(luaFileInputText);

		weekInputText = new FlxUIInputText(10, luaFileInputText.y + 48, 100, week_nomiss, 8);
		blockPressWhileTypingOn.push(weekInputText);

		indexStepper = new FlxUINumericStepper(weekInputText.x + weekInputText.width + 72, awardNameInputText.y, 1, index, -1);

		bgColorStepperR = new FlxUINumericStepper(10, weekInputText.y + 40, 20, 255, 0, 255, 0);
		bgColorStepperG = new FlxUINumericStepper(bgColorStepperR.x + 86, bgColorStepperR.y, 20, 255, 0, 255, 0);
		bgColorStepperB = new FlxUINumericStepper(bgColorStepperG.x + 86, bgColorStepperG.y, 20, 255, 0, 255, 0);

		hiddenCheckbox = new FlxUICheckBox(10, bgColorStepperR.y + 35, null, null, 'Is Hidden?', 100, function():Void {
			hidden = hiddenCheckbox.checked;
		});

		songInputText = new FlxUIInputText(hiddenCheckbox.x + hiddenCheckbox.width + 25, hiddenCheckbox.y + 5, 84, song, 8);
		blockPressWhileTypingOn.push(songInputText);

		loadButton = new FlxUIButton(32, songInputText.y + 30, 'Load', loadAchievement);
		saveButton = new FlxUIButton(loadButton.x + loadButton.width + 20, loadButton.y, 'Save', saveAchievement);
		resetButton = new FlxUIButton(loadButton.x + loadButton.width - 30, loadButton.y + loadButton.height + 5, 'Reset', reset);

		diffInputText = new FlxUIInputText(songInputText.x, weekInputText.y, 75, song, 8);
		missesStepper = new FlxUINumericStepper(tagInputText.x + tagInputText.width + 96, tagInputText.y + 15, 1, misses, -1);

		tab_group.add(awardNameInputText);
		tab_group.add(tagInputText);
		tab_group.add(descInputText);
		tab_group.add(luaFileInputText);
		tab_group.add(weekInputText);
		tab_group.add(indexStepper);
		tab_group.add(bgColorStepperR);
		tab_group.add(bgColorStepperG);
		tab_group.add(bgColorStepperB);
		tab_group.add(hiddenCheckbox);
		tab_group.add(songInputText);
		tab_group.add(diffInputText);
		tab_group.add(missesStepper);

		tab_group.add(loadButton);
		tab_group.add(saveButton);
		tab_group.add(resetButton);

		tab_group.add(new FlxText(awardNameInputText.x, awardNameInputText.y - 18, 0, 'Achievement name:'));
		tab_group.add(new FlxText(tagInputText.x, tagInputText.y - 18, 0, 'Achievement save tag:'));
		tab_group.add(new FlxText(descInputText.x, descInputText.y - 18, 0, 'Achievement description:'));
		tab_group.add(new FlxText(luaFileInputText.x, luaFileInputText.y - 18, 0, 'Lua file\'s path:'));
		tab_group.add(new FlxText(weekInputText.x, weekInputText.y - 18, 0, 'Week ID to unlock:'));
		tab_group.add(new FlxText(indexStepper.x, indexStepper.y - 18, 0, 'Index:'));
		tab_group.add(new FlxText(10, bgColorStepperR.y - 18, 0, 'Selected background Color R/G/B:'));
		tab_group.add(new FlxText(songInputText.x, songInputText.y - 18, 0, 'Song ID to unlock:'));
		tab_group.add(new FlxText(diffInputText.x, diffInputText.y - 26, 0, 'Difficulty ID\nto unlock:'));
		tab_group.add(new FlxText(missesStepper.x - 10, missesStepper.y - 26, 0, 'Minimal Misses\n(-1 to disable):'));

		UI_box.addGroup(tab_group);
	}

	function reloadVariables():Void
	{
		misses = award.misses;
		diff = award.diff;
		color = award.color;
		name = award.name;
		tag = award.save_tag;
		hidden = award.hidden;
		week_nomiss = award.week_nomiss;
		lua_code = award.lua_code;
		index = award.index;
		song = award.song;
		desc = award.desc;
	}

	function formatToAchievementFile():AchievementFile
	{
		return {
			misses: misses,
			diff: diff,
			color: color,
			name: name,
			desc: desc,
			save_tag: tag,
			hidden: hidden,
			week_nomiss: week_nomiss,
			lua_code: lua_code,
			index: index,
			song: song
		};
	}

	function reloadAllShit():Void
	{
		awardNameInputText.text = name;
		tagInputText.text = tag;
		descInputText.text = desc;
		luaFileInputText.text = lua_code;
		diffInputText.text = diff;
		weekInputText.text = week_nomiss;
		indexStepper.value = index;
		missesStepper.value = misses;
		bgColorStepperR.value = color[0];
		bgColorStepperG.value = color[1];
		bgColorStepperB.value = color[2];
		hiddenCheckbox.checked = hidden;
		songInputText.text = song;

		updateBG();
	}

	function updateBG():Void
	{
		bg.color = FlxColor.fromRGB(color[0], color[1], color[2]);
	}

	override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>):Void
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == awardNameInputText) {
				name = awardNameInputText.text.trim();
			}
			else if (sender == tagInputText) {
				tag = tagInputText.text.trim();
			}
			else if (sender == descInputText) {
				desc = descInputText.text.trim();
			}
			else if (sender == luaFileInputText) {
				lua_code = luaFileInputText.text.trim();
			}
			else if (sender == diffInputText) {
				diff = diffInputText.text.trim();
			}
			else if (sender == weekInputText) {
				week_nomiss = weekInputText.text.trim();
			}
			else if (sender == songInputText) {
				song = songInputText.text.trim();
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			if (sender == bgColorStepperR || sender == bgColorStepperG || sender == bgColorStepperB)
			{
				color[0] = Math.round(bgColorStepperR.value);
				color[1] = Math.round(bgColorStepperG.value);
				color[2] = Math.round(bgColorStepperB.value);

				updateBG();
			}
			else if (sender == indexStepper) {
				index = Math.round(indexStepper.value);
			}
			else if (sender == missesStepper) {
				misses = Math.round(missesStepper.value);
			}
		}
	}

	override function update(elapsed:Float):Void
	{
		var blockInput:Bool = false;

		for (inputText in blockPressWhileTypingOn)
		{
			if (inputText.hasFocus)
			{
				FlxG.sound.muteKeys = [];
				FlxG.sound.volumeDownKeys = [];
				FlxG.sound.volumeUpKeys = [];

				blockInput = true;
				break;
			}
		}

		if (!blockInput)
		{
			for (stepper in blockPressWhileTypingOnStepper)
			{
				@:privateAccess
				var leText:Dynamic = stepper.text_field;
				var leText:FlxUIInputText = leText;

				if (leText.hasFocus)
				{
					FlxG.sound.muteKeys = [];
					FlxG.sound.volumeDownKeys = [];
					FlxG.sound.volumeUpKeys = [];

					blockInput = true;
					break;
				}
			}

			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;

			if (FlxG.keys.justPressed.ESCAPE)
			{
				FlxG.switchState(new MasterEditorMenu());
				FlxG.mouse.visible = false;
			}
		}
		else if (FlxG.keys.justPressed.ENTER)
		{
			for (i in 0...blockPressWhileTypingOn.length)
			{
				if (blockPressWhileTypingOn[i].hasFocus) {
					blockPressWhileTypingOn[i].hasFocus = false;
				}
			}
		}

		super.update(elapsed);
	}

	function reset():Void // sorry but a im lazy and dead inside
	{
		FlxTransitionableState.skipNextTransIn = true;
		FlxTransitionableState.skipNextTransOut = true;

		FlxG.resetState();
	}

	var _file:FileReference = null;

	function loadAchievement():Void
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
				var loadedAchievement:AchievementFile = Achievements.getAchievementFile(fullPath, true);
				var cutName:String = _file.name.substr(0, _file.name.length - 5);

				try
				{
					Debug.logInfo("Successfully loaded file: " + cutName);
					award = loadedAchievement;

					reloadVariables();
					reloadAllShit();
				}
				catch (e:Dynamic) {
					Debug.logError("Cannot load file " + cutName);
				}

				_file = null;
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

	function saveAchievement():Void
	{
		award = formatToAchievementFile();
		var data:String = Json.stringify(award, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);

			#if MODS_ALLOWED
			_file.save(data.trim(), #if sys CoolUtil.convPathShit(Paths.modFolders('achievements/' + #end tag + '.json' #if sys )) #end);
			#else
			_file.save(data.trim(), #if sys CoolUtil.convPathShit(Paths.getJson('achievements/' + #end tag + '.json' #if sys )) #end);
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
	#end
}