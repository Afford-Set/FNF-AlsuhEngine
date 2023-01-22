package editors;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end

import haxe.Json;

import WeekData;

#if sys
import sys.io.File;
import sys.FileSystem;
#end

import flixel.FlxG;
import flixel.FlxSprite;
import openfl.utils.Assets;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import openfl.events.Event;
import flixel.util.FlxColor;
import lime.system.Clipboard;
import flixel.group.FlxGroup;
import openfl.net.FileFilter;
import transition.Transition;
import flixel.addons.ui.FlxUI;
import openfl.net.FileReference;
import openfl.events.IOErrorEvent;
import flixel.addons.ui.FlxUITabMenu;
import flixel.addons.ui.FlxUICheckBox;
import flixel.addons.ui.FlxUIInputText;
import flixel.addons.ui.FlxUINumericStepper;

using StringTools;

class WeekEditorState extends MusicBeatUIState
{
	var txtWeekTitle:FlxText;

	var bgSprite:FlxSprite;
	var lock:FlxSprite;

	var txtTracklist:FlxText;

	var grpWeekCharacters:FlxTypedGroup<MenuCharacter>;
	var weekThing:MenuItem;

	var missingFileText:FlxText;

	var weekFile:WeekFile = null;

	public function new(weekFile:WeekFile = null):Void
	{
		super();

		this.weekFile = WeekData.createWeekFile();

		if (weekFile != null)
			this.weekFile = weekFile;
		else
			weekFileName = 'week1';
	}

	public override function create():Void
	{
		super.create();

		persistentUpdate = true;

		Conductor.changeBPM(102);

		txtWeekTitle = new FlxText(FlxG.width * 0.7, 10, 0, "", 32);
		txtWeekTitle.setFormat(Paths.getFont('vcr.ttf'), 32, FlxColor.WHITE, RIGHT);
		txtWeekTitle.alpha = 0.7;
		
		var ui_tex = Paths.getSparrowAtlas('storymenu/campaign_menu_UI_assets');

		var bgYellow:FlxSprite = new FlxSprite(0, 56).makeGraphic(FlxG.width, 386, 0xFFF9CF51);
		bgSprite = new FlxSprite(0, 56);
		bgSprite.antialiasing = OptionData.globalAntialiasing;

		weekThing = new MenuItem(0, bgSprite.y + 396, weekFileName);
		weekThing.y += weekThing.height + 20;
		weekThing.antialiasing = OptionData.globalAntialiasing;
		add(weekThing);

		var blackBarThingie:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 56, FlxColor.BLACK);
		add(blackBarThingie);
		
		grpWeekCharacters = new FlxTypedGroup<MenuCharacter>();
		
		lock = new FlxSprite();
		lock.frames = ui_tex;
		lock.animation.addByPrefix('lock', 'lock');
		lock.animation.play('lock');
		lock.antialiasing = OptionData.globalAntialiasing;
		add(lock);
		
		missingFileText = new FlxText(0, 0, FlxG.width, "");
		missingFileText.setFormat(Paths.getFont("vcr.ttf"), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		missingFileText.borderSize = 2;
		missingFileText.visible = false;
		add(missingFileText); 
		
		var charArray:Array<String> = weekFile.weekCharacters;

		for (char in 0...3)
		{
			var weekCharacterThing:MenuCharacter = new MenuCharacter((FlxG.width * 0.25) * (1 + char) - 150, charArray[char]);
			weekCharacterThing.y += 70;
			grpWeekCharacters.add(weekCharacterThing);
		}

		add(bgYellow);
		add(bgSprite);
		add(grpWeekCharacters);

		var tracksSprite:FlxSprite = new FlxSprite(FlxG.width * 0.07, bgSprite.y + 435);
		tracksSprite.loadGraphic(Paths.getImage('storymenu/Menu_Tracks'));
		tracksSprite.antialiasing = OptionData.globalAntialiasing;
		add(tracksSprite);

		txtTracklist = new FlxText(FlxG.width * 0.05, tracksSprite.y + 60, 0, "", 32);
		txtTracklist.alignment = CENTER;
		txtTracklist.font = Paths.getFont("vcr.ttf");
		txtTracklist.color = 0xFFe55777;
		add(txtTracklist);
		add(txtWeekTitle);

		addEditorBox();
		reloadAllShit();

		FlxG.mouse.visible = true;
	}

	var UI_box:FlxUITabMenu;
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];

	function addEditorBox():Void
	{
		var tabs = [
			{name: 'Week', label: 'Week'},
			{name: 'Other', label: 'Other'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(250, 375);
		UI_box.x = FlxG.width - UI_box.width;
		UI_box.y = FlxG.height - UI_box.height;
		UI_box.scrollFactor.set();

		addWeekUI();
		addOtherUI();
		
		UI_box.selected_tab_id = 'Week';
		add(UI_box);

		var loadWeekButton:FlxButton = new FlxButton(0, 650, "Load Week", function():Void
		{
			loadWeek();
		});

		loadWeekButton.screenCenter(X);
		loadWeekButton.x -= 120;
		add(loadWeekButton);
		
		var freeplayButton:FlxButton = new FlxButton(0, 650, "Freeplay", function():Void
		{
			FlxG.switchState(new WeekEditorFreeplayState(weekFile));
		});

		freeplayButton.screenCenter(X);
		add(freeplayButton);
	
		var saveWeekButton:FlxButton = new FlxButton(0, 650, "Save Week", function():Void
		{
			saveWeek(weekFile);
		});

		saveWeekButton.screenCenter(X);
		saveWeekButton.x += 120;
		add(saveWeekButton);
	}

	var songsIDsInputText:FlxUIInputText;
	var songsNamesInputText:FlxUIInputText;
	var backgroundInputText:FlxUIInputText;
	var displayNameInputText:FlxUIInputText;
	var weekIDInputText:FlxUIInputText;
	var weekNameInputText:FlxUIInputText;
	var weekFileInputText:FlxUIInputText;
	
	var opponentInputText:FlxUIInputText;
	var boyfriendInputText:FlxUIInputText;
	var girlfriendInputText:FlxUIInputText;

	var hideCheckbox:FlxUICheckBox;

	public static var weekFileName:String = 'week1';
	
	function addWeekUI():Void
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Week";
		
		songsIDsInputText = new FlxUIInputText(10, 25, 200, '', 8);
		blockPressWhileTypingOn.push(songsIDsInputText);

		songsNamesInputText = new FlxUIInputText(10, songsIDsInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(songsNamesInputText);

		opponentInputText = new FlxUIInputText(10, songsNamesInputText.y + 40, 70, '', 8);
		blockPressWhileTypingOn.push(opponentInputText);
	
		boyfriendInputText = new FlxUIInputText(opponentInputText.x + 75, opponentInputText.y, 70, '', 8);
		blockPressWhileTypingOn.push(boyfriendInputText);
	
		girlfriendInputText = new FlxUIInputText(boyfriendInputText.x + 75, opponentInputText.y, 70, '', 8);
		blockPressWhileTypingOn.push(girlfriendInputText);

		backgroundInputText = new FlxUIInputText(10, opponentInputText.y + 40, 120, '', 8);
		blockPressWhileTypingOn.push(backgroundInputText);

		displayNameInputText = new FlxUIInputText(10, backgroundInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(backgroundInputText);

		weekIDInputText = new FlxUIInputText(10, displayNameInputText.y + 40, 150, '', 8);
		blockPressWhileTypingOn.push(weekIDInputText);

		weekNameInputText = new FlxUIInputText(10, weekIDInputText.y + 40, 150, '', 8);
		blockPressWhileTypingOn.push(weekNameInputText);

		weekFileInputText = new FlxUIInputText(10, weekNameInputText.y + 40, 100, '', 8);
		blockPressWhileTypingOn.push(weekFileInputText);
		reloadWeekThing();

		hideCheckbox = new FlxUICheckBox(10, weekFileInputText.y + 25, null, null, "Hide Week from Story Mode?", 100);
		hideCheckbox.callback = function():Void
		{
			weekFile.hideStoryMode = hideCheckbox.checked;
		};

		tab_group.add(new FlxText(songsIDsInputText.x, songsIDsInputText.y - 18, 0, 'Songs\'s IDs (must be lower case):'));
		tab_group.add(new FlxText(songsNamesInputText.x, songsNamesInputText.y - 18, 0, 'Songs\'s Names:'));
		tab_group.add(new FlxText(opponentInputText.x, opponentInputText.y - 18, 0, 'Characters:'));
		tab_group.add(new FlxText(backgroundInputText.x, backgroundInputText.y - 18, 0, 'Background Asset:'));
		tab_group.add(new FlxText(displayNameInputText.x, displayNameInputText.y - 18, 0, 'Display Name:'));
		tab_group.add(new FlxText(weekIDInputText.x, weekIDInputText.y - 18, 0, 'Week\'s ID (must be lower case):'));
		tab_group.add(new FlxText(weekNameInputText.x, weekNameInputText.y - 18, 0, 'Week\'s Name (for Reset Score Menu):'));
		tab_group.add(new FlxText(weekFileInputText.x, weekFileInputText.y - 18, 0, 'Week File:'));

		tab_group.add(songsIDsInputText);
		tab_group.add(songsNamesInputText);
		tab_group.add(opponentInputText);
		tab_group.add(boyfriendInputText);
		tab_group.add(girlfriendInputText);
		tab_group.add(backgroundInputText);

		tab_group.add(displayNameInputText);
		tab_group.add(weekIDInputText);
		tab_group.add(weekNameInputText);
		tab_group.add(weekFileInputText);
		tab_group.add(hideCheckbox);

		UI_box.addGroup(tab_group);
	}

	var weekBeforeInputText:FlxUIInputText;
	var lockedCheckbox:FlxUICheckBox;
	var hiddenUntilUnlockCheckbox:FlxUICheckBox;

	var defaultDiffInputText:FlxUIInputText;
	var difficultiesInputText:FlxUIInputText;
	var difficultiesNamesInputText:FlxUIInputText;
	var difficultiesSuffixesInputText:FlxUIInputText;

	function addOtherUI():Void
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Other";

		lockedCheckbox = new FlxUICheckBox(10, 30, null, null, "Week starts Locked", 100);
		lockedCheckbox.callback = function():Void
		{
			weekFile.startUnlocked = !lockedCheckbox.checked;
			lock.visible = lockedCheckbox.checked;
			hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (lockedCheckbox.checked ? 1 : 0);
		};

		hiddenUntilUnlockCheckbox = new FlxUICheckBox(10, lockedCheckbox.y + 25, null, null, "Hidden until Unlocked", 110);
		hiddenUntilUnlockCheckbox.callback = function():Void
		{
			weekFile.hiddenUntilUnlocked = hiddenUntilUnlockCheckbox.checked;
		};
		hiddenUntilUnlockCheckbox.alpha = 0.4;

		weekBeforeInputText = new FlxUIInputText(10, hiddenUntilUnlockCheckbox.y + 55, 100, '', 8);
		blockPressWhileTypingOn.push(weekBeforeInputText);

		defaultDiffInputText = new FlxUIInputText(10, weekBeforeInputText.y + 60, 200, '', 8);
		blockPressWhileTypingOn.push(defaultDiffInputText);

		difficultiesInputText = new FlxUIInputText(10, defaultDiffInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(difficultiesInputText);

		difficultiesNamesInputText = new FlxUIInputText(10, difficultiesInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(difficultiesNamesInputText);

		difficultiesSuffixesInputText = new FlxUIInputText(10, difficultiesNamesInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(difficultiesSuffixesInputText);

		tab_group.add(new FlxText(weekBeforeInputText.x, weekBeforeInputText.y - 28, 0, 'Week File name of the Week you have\nto finish for Unlocking:'));
		tab_group.add(new FlxText(defaultDiffInputText.x, defaultDiffInputText.y - 20, 0, 'Default Difficulty\'s ID:'));
		tab_group.add(new FlxText(difficultiesInputText.x, difficultiesInputText.y - 20, 0, 'Difficulties\'s IDs (must be lower case):'));
		tab_group.add(new FlxText(difficultiesNamesInputText.x, difficultiesNamesInputText.y - 20, 0, 'Difficulties\'s Names:'));
		tab_group.add(new FlxText(difficultiesSuffixesInputText.x, difficultiesSuffixesInputText.y - 20, 0, 'Difficulties\'s Suffixes:'));
		tab_group.add(new FlxText(difficultiesSuffixesInputText.x, difficultiesSuffixesInputText.y + 20, 0, 'Default difficulties are "Easy, Normal, Hard"\nwithout quotes.'));
		tab_group.add(weekBeforeInputText);
		tab_group.add(defaultDiffInputText);
		tab_group.add(difficultiesInputText);
		tab_group.add(difficultiesNamesInputText);
		tab_group.add(difficultiesSuffixesInputText);
		tab_group.add(hiddenUntilUnlockCheckbox);
		tab_group.add(lockedCheckbox);

		UI_box.addGroup(tab_group);
	}

	function reloadAllShit():Void // Used on onCreate and when you load a week
	{
		var weekString:String = Paths.formatToSongPath(weekFile.songs[0].songID);

		for (i in 1...weekFile.songs.length) {
			weekString += ', ' + Paths.formatToSongPath(weekFile.songs[i].songID);
		}

		songsIDsInputText.text = weekString;

		var weekString:String = weekFile.songs[0].songName;

		for (i in 1...weekFile.songs.length) {
			weekString += ', ' + weekFile.songs[i].songName;
		}

		songsNamesInputText.text = weekString;

		backgroundInputText.text = weekFile.weekBackground;
		displayNameInputText.text = weekFile.storyName;
		weekNameInputText.text = weekFile.weekName;
		weekIDInputText.text = weekFile.weekID;
		weekFileInputText.text = weekFile.itemFile;
		
		opponentInputText.text = weekFile.weekCharacters[0];
		boyfriendInputText.text = weekFile.weekCharacters[1];
		girlfriendInputText.text = weekFile.weekCharacters[2];

		hideCheckbox.checked = weekFile.hideStoryMode;

		weekBeforeInputText.text = weekFile.weekBefore;

		defaultDiffInputText.text = '';
		difficultiesInputText.text = '';
		difficultiesNamesInputText.text = '';
		difficultiesSuffixesInputText.text = '';

		if (weekFile.difficulties != null)
		{
			var diffNames:String = weekFile.difficulties[0][0];

			for (i in 1...weekFile.difficulties[0].length) {
				diffNames += ', ' + weekFile.difficulties[0][i];
			}

			difficultiesNamesInputText.text = diffNames;

			var diffIDs:String = weekFile.difficulties[1][0];

			for (i in 1...weekFile.difficulties[1].length) {
				diffIDs += ', ' + weekFile.difficulties[1][i];
			}

			difficultiesInputText.text = diffIDs;

			var diffSuffixes:String = weekFile.difficulties[2][0];

			for (i in 1...weekFile.difficulties[2].length) {
				diffSuffixes += ', ' + weekFile.difficulties[2][i];
			}

			difficultiesSuffixesInputText.text = diffSuffixes;
		}

		if (weekFile.defaultDifficulty != null) {
			defaultDiffInputText.text = weekFile.defaultDifficulty;
		}

		lockedCheckbox.checked = !weekFile.startUnlocked;
		lock.visible = lockedCheckbox.checked;
		
		hiddenUntilUnlockCheckbox.checked = weekFile.hiddenUntilUnlocked;
		hiddenUntilUnlockCheckbox.alpha = 0.4 + 0.6 * (lockedCheckbox.checked ? 1 : 0);

		reloadBG();
		reloadWeekThing();
		updateText();
	}

	function updateText():Void
	{
		for (i in 0...grpWeekCharacters.length) {
			grpWeekCharacters.members[i].changeCharacter(weekFile.weekCharacters[i]);
		}

		var stringThing:Array<String> = [];

		for (i in 0...weekFile.songs.length) {
			stringThing.push(weekFile.songs[i].songName);
		}

		txtTracklist.text = '';

		for (i in 0...stringThing.length) {
			txtTracklist.text += stringThing[i] + '\n';
		}

		txtTracklist.text = txtTracklist.text.toUpperCase();

		txtTracklist.screenCenter(X);
		txtTracklist.x -= FlxG.width * 0.35;
		
		txtWeekTitle.text = weekFile.storyName.toUpperCase();
		txtWeekTitle.x = FlxG.width - (txtWeekTitle.width + 10);
	}

	function reloadBG():Void
	{
		bgSprite.visible = true;
		var assetName:String = weekFile.weekBackground;

		var isMissing:Bool = true;

		if (assetName != null && assetName.length > 0)
		{
			if (#if MODS_ALLOWED FileSystem.exists(Paths.modsImages('storymenu/menubackgrounds/menu_' + assetName)) || #end
				Assets.exists(Paths.getPath('images/storymenu/menubackgrounds/menu_' + assetName + '.png', IMAGE), IMAGE))
			{
				bgSprite.loadGraphic(Paths.getImage('storymenu/menubackgrounds/menu_' + assetName));
				isMissing = false;
			}
		}

		if (isMissing) {
			bgSprite.visible = false;
		}
	}

	function reloadWeekThing():Void
	{
		weekThing.visible = true;
		missingFileText.visible = false;

		var assetName:String = weekFileInputText.text.trim();
		
		var isMissing:Bool = true;

		if (assetName != null && assetName.length > 0)
		{
			if (#if MODS_ALLOWED FileSystem.exists(Paths.modsImages('storymenu/menuitems/' + assetName)) || #end
				Assets.exists(Paths.getPath('images/storymenu/menuitems/' + assetName + '.png', IMAGE), IMAGE))
			{
				weekThing.loadGraphic(Paths.getImage('storymenu/menuitems/' + assetName));
				isMissing = false;
			}
		}

		if (isMissing)
		{
			weekThing.visible = false;
			missingFileText.visible = true;
			missingFileText.text = 'MISSING FILE: images/storymenu/menuitems/' + assetName + '.png';
		}

		recalculateStuffPosition();

		#if DISCORD_ALLOWED
		DiscordClient.changePresence("Week Editor", "Editting: " + weekFile.weekName); // Updating Discord Rich Presence
		#end
	}
	
	public override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>):Void
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == weekFileInputText)
			{
				weekFile.itemFile = weekFileInputText.text.trim();
				reloadWeekThing();
			}
			else if (sender == opponentInputText || sender == boyfriendInputText || sender == girlfriendInputText)
			{
				weekFile.weekCharacters[0] = opponentInputText.text.trim();
				weekFile.weekCharacters[1] = boyfriendInputText.text.trim();
				weekFile.weekCharacters[2] = girlfriendInputText.text.trim();

				updateText();
			}
			else if (sender == backgroundInputText)
			{
				weekFile.weekBackground = backgroundInputText.text;
				reloadBG();
			}
			else if (sender == displayNameInputText)
			{
				weekFile.storyName = displayNameInputText.text.trim();
				updateText();
			}
			else if (sender == weekNameInputText) {
				weekFile.weekName = weekNameInputText.text.trim();
			}
			else if (sender == weekIDInputText) {
				weekFile.weekID = weekIDInputText.text.trim();
			}
			else if (sender == songsIDsInputText)
			{
				songsIDsInputText.text = songsIDsInputText.text.toLowerCase();

				var splittedText:Array<String> = songsIDsInputText.text.trim().split(',');

				for (i in 0...splittedText.length) {
					splittedText[i] = splittedText[i].trim();
				}

				while (splittedText.length < weekFile.songs.length) {
					weekFile.songs.pop();
				}

				for (i in 0...splittedText.length)
				{
					if (i >= weekFile.songs.length) // Add new song
					{
						weekFile.songs.push({
							songID: splittedText[i],
							songName: splittedText[i],
							character: 'dad',
							color: [146, 113, 253],
							difficulties: [
								['Easy',	'Normal',	'Hard'],
								['easy',	'normal',	'hard'],
								['-easy',	'',			'-hard']
							],
							defaultDifficulty: 'normal',
						});
					}
					else // Edit song
					{
						weekFile.songs[i].songID = Paths.formatToSongPath(splittedText[i]);

						if (weekFile.songs[i].songName == null) {
							weekFile.songs[i].songName = CoolUtil.formatToName(weekFile.songs[i].songID);
						}

						if (weekFile.songs[i].character == null) {
							weekFile.songs[i].character = 'dad';
						}

						if (weekFile.songs[i].color == null) {
							weekFile.songs[i].color = [146, 113, 253];
						}

						if (weekFile.songs[i].difficulties == null) {
							weekFile.songs[i].difficulties = weekFile.difficulties;
						}

						if (weekFile.songs[i].defaultDifficulty == null) {
							weekFile.songs[i].defaultDifficulty = weekFile.defaultDifficulty;
						}
					}
				}

				updateText();
			}
			else if (sender == songsNamesInputText)
			{
				var splittedText:Array<String> = songsNamesInputText.text.trim().split(',');

				for (i in 0...splittedText.length)
				{
					splittedText[i] = splittedText[i].trim();

					if (weekFile.songs[i] != null) {
						weekFile.songs[i].songName = splittedText[i];
					}
				}

				updateText();
			}
			else if (sender == weekBeforeInputText) {
				weekFile.weekBefore = weekBeforeInputText.text.trim();
			}
			else if (sender == difficultiesInputText)
			{
				var splittedText:Array<String> = difficultiesInputText.text.trim().split(',');

				for (i in 0...splittedText.length) {
					splittedText[i] = splittedText[i].trim();
				}

				weekFile.difficulties[1] = splittedText;
			}
			else if (sender == difficultiesNamesInputText)
			{
				var splittedText:Array<String> = difficultiesNamesInputText.text.trim().split(',');

				for (i in 0...splittedText.length) {
					splittedText[i] = splittedText[i].trim();
				}

				weekFile.difficulties[0] = splittedText;
			}
			else if (sender == difficultiesSuffixesInputText)
			{
				var splittedText:Array<String> = difficultiesSuffixesInputText.text.trim().split(',');

				for (i in 0...splittedText.length) {
					splittedText[i] = splittedText[i].trim();
				}

				weekFile.difficulties[2] = splittedText;
			}
			else if (sender == defaultDiffInputText) {
				weekFile.defaultDifficulty = defaultDiffInputText.text.trim();
			}
		}
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.sound.music != null) {
			Conductor.songPosition = FlxG.sound.music.time;
		}

		if (loadedWeek != null)
		{
			weekFile = loadedWeek;
			loadedWeek = null;

			reloadAllShit();
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

		if (!blockInput)
		{
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;

			if (FlxG.keys.justPressed.ESCAPE) {
				FlxG.switchState(new MasterEditorMenu());
			}
		}

		lock.y = weekThing.y;
		missingFileText.y = weekThing.y + 36;
	}

	public override function beatHit():Void
	{
		super.beatHit();

		for (i in 0...grpWeekCharacters.length)
		{
			var leChar:MenuCharacter = grpWeekCharacters.members[i];

			if (leChar.isDanced && !leChar.heyed) {
				leChar.dance();
			}
			else
			{
				if (curBeat % 2 == 0 && !leChar.heyed) {
					leChar.dance();
				}
			}
		}
	}

	function recalculateStuffPosition():Void
	{
		weekThing.screenCenter(X);
		lock.x = weekThing.width + 10 + weekThing.x;
	}

	private static var _file:FileReference;

	public static function loadWeek():Void
	{
		var jsonFilter:FileFilter = new FileFilter('JSON', 'json');

		_file = new FileReference();
		_file.addEventListener(Event.SELECT, onLoadComplete);
		_file.addEventListener(Event.CANCEL, onLoadCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onLoadError);
		_file.browse([jsonFilter]);
	}
	
	public static var loadedWeek:WeekFile = null;
	public static var loadError:Bool = false;

	private static function onLoadComplete(_):Void
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
				loadedWeek = cast Json.parse(rawJson);
				var cutName:String = _file.name.substr(0, _file.name.length - 5);

				WeekData.onLoadJson(loadedWeek, cutName);

				if (loadedWeek.weekID != null && loadedWeek.weekCharacters != null && loadedWeek.weekName != null) // Make sure it's really a week
				{
					Debug.logInfo("Successfully loaded file: " + cutName);
					loadError = false;

					weekFileName = cutName;
					_file = null;

					return;
				}
			}
		}

		loadError = true;
		loadedWeek = null;

		_file = null;

		#else
		Debug.logError("File couldn't be loaded! You aren't on Desktop, are you?");
		#end
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	private static function onLoadCancel(_):Void
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
	private static function onLoadError(_):Void
	{
		_file.removeEventListener(Event.SELECT, onLoadComplete);
		_file.removeEventListener(Event.CANCEL, onLoadCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onLoadError);

		_file = null;

		Debug.logError("Problem loading file");
	}

	public static function saveWeek(weekFile:WeekFile):Void
	{
		var data:String = Json.stringify(weekFile, "\t");

		if (data.length > 0)
		{
			_file = new FileReference();
			_file.addEventListener(Event.COMPLETE, onSaveComplete);
			_file.addEventListener(Event.CANCEL, onSaveCancel);
			_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
			_file.save(data, weekFile.weekID + ".json");
		}
	}
	
	private static function onSaveComplete(event:Event):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);

		_file = null;

		FlxG.log.notice("Successfully saved file.");
	}

	/**
		* Called when the save file dialog is cancelled.
		*/
	private static function onSaveCancel(event:Event):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);

		_file = null;
	}

	/**
		* Called if there is an error while saving the gameplay recording.
		*/
	private static function onSaveError(event:Event):Void
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);

		_file = null;

		FlxG.log.error("Problem saving file");
	}
}

class WeekEditorFreeplayState extends MusicBeatUIState
{
	var weekFile:WeekFile = null;

	public function new(weekFile:WeekFile = null):Void
	{
		super();

		this.weekFile = WeekData.createWeekFile();

		if (weekFile != null) this.weekFile = weekFile;
	}

	var bg:FlxSprite;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var grpIcons:FlxTypedGroup<HealthIcon>;

	var curSelected:Int = 0;

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
		bg.color = 0xFFFFFFFF;
		bg.updateHitbox();
		bg.screenCenter();
		bg.scrollFactor.set();
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		grpIcons = new FlxTypedGroup<HealthIcon>();
		add(grpIcons);

		for (i in 0...weekFile.songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, weekFile.songs[i].songName, true);
			songText.isMenuItem = true;
			songText.targetY = i - curSelected;
			songText.setPosition(0, (70 * i) + 30);
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(weekFile.songs[i].character);
			icon.sprTracker = songText;
			icon.ID = i;
			grpIcons.add(icon);
		}

		addEditorBox();
		changeSelection();
	}
	
	var UI_box:FlxUITabMenu;
	var blockPressWhileTypingOn:Array<FlxUIInputText> = [];

	function addEditorBox():Void
	{
		var tabs = [
			{name: 'Freeplay', label: 'Freeplay'},
		];

		UI_box = new FlxUITabMenu(null, tabs, true);
		UI_box.resize(250, 365);
		UI_box.x = FlxG.width - UI_box.width - 100;
		UI_box.y = FlxG.height - UI_box.height - 60;
		UI_box.scrollFactor.set();
		
		UI_box.selected_tab_id = 'Week';
		addFreeplayUI();
		add(UI_box);

		var blackBlack:FlxSprite = new FlxSprite(0, 670);
		blackBlack.makeGraphic(FlxG.width, 50, FlxColor.BLACK);
		blackBlack.alpha = 0.6;
		add(blackBlack);

		var loadWeekButton:FlxButton = new FlxButton(0, 685, "Load Week", function():Void {
			WeekEditorState.loadWeek();
		});

		loadWeekButton.screenCenter(X);
		loadWeekButton.x -= 120;
		add(loadWeekButton);
		
		var storyModeButton:FlxButton = new FlxButton(0, 685, "Story Mode", function():Void {
			FlxG.switchState(new WeekEditorState(weekFile));
		});

		storyModeButton.screenCenter(X);
		add(storyModeButton);
	
		var saveWeekButton:FlxButton = new FlxButton(0, 685, "Save Week", function():Void {
			WeekEditorState.saveWeek(weekFile);
		});

		saveWeekButton.screenCenter(X);
		saveWeekButton.x += 120;
		add(saveWeekButton);
	}
	
	public override function getEvent(id:String, sender:Dynamic, data:Dynamic, ?params:Array<Dynamic>):Void
	{
		if (id == FlxUIInputText.CHANGE_EVENT && (sender is FlxUIInputText))
		{
			if (sender == iconInputText)
			{
				weekFile.songs[curSelected].character = iconInputText.text;
				grpIcons.members[curSelected].changeIcon(iconInputText.text);
			}
			else if (sender == defaultDiffInputText) {
				weekFile.songs[curSelected].defaultDifficulty = defaultDiffInputText.text;
			}
			else if (sender == difficultiesInputText)
			{
				var splittedText:Array<String> = difficultiesInputText.text.trim().split(',');

				for (i in 0...splittedText.length) {
					splittedText[i] = splittedText[i].trim();
				}

				weekFile.songs[curSelected].difficulties[1] = splittedText;
			}
			else if (sender == difficultiesNamesInputText)
			{
				var splittedText:Array<String> = difficultiesNamesInputText.text.trim().split(',');

				for (i in 0...splittedText.length) {
					splittedText[i] = splittedText[i].trim();
				}

				weekFile.songs[curSelected].difficulties[0] = splittedText;
			}
			else if (sender == difficultiesSuffixesInputText)
			{
				var splittedText:Array<String> = difficultiesSuffixesInputText.text.trim().split(',');

				for (i in 0...splittedText.length) {
					splittedText[i] = splittedText[i].trim();
				}

				weekFile.songs[curSelected].difficulties[2] = splittedText;
			}
		}
		else if (id == FlxUINumericStepper.CHANGE_EVENT && (sender is FlxUINumericStepper))
		{
			if (sender == bgColorStepperR || sender == bgColorStepperG || sender == bgColorStepperB) {
				updateBG();
			}
		}
	}

	var bgColorStepperR:FlxUINumericStepper;
	var bgColorStepperG:FlxUINumericStepper;
	var bgColorStepperB:FlxUINumericStepper;
	var iconInputText:FlxUIInputText;

	var defaultDiffInputText:FlxUIInputText;
	var difficultiesInputText:FlxUIInputText;
	var difficultiesNamesInputText:FlxUIInputText;
	var difficultiesSuffixesInputText:FlxUIInputText;

	static var difficultiesCopy:Array<Array<String>> = null;
	static var defaultDifficultyCopy:String = null;

	function addFreeplayUI():Void
	{
		var tab_group = new FlxUI(null, UI_box);
		tab_group.name = "Freeplay";

		bgColorStepperR = new FlxUINumericStepper(10, 25, 20, 255, 0, 255, 0);
		bgColorStepperG = new FlxUINumericStepper(80, 25, 20, 255, 0, 255, 0);
		bgColorStepperB = new FlxUINumericStepper(150, 25, 20, 255, 0, 255, 0);

		var copyColor:FlxButton = new FlxButton(10, bgColorStepperR.y + 25, "Copy Color", function():Void {
			Clipboard.text = bg.color.red + ',' + bg.color.green + ',' + bg.color.blue;
		});

		var pasteColor:FlxButton = new FlxButton(140, copyColor.y, "Paste Color", function():Void
		{
			if (Clipboard.text != null)
			{
				var leColor:Array<Int> = [];
				var splitted:Array<String> = Clipboard.text.trim().split(',');

				for (i in 0...splitted.length)
				{
					var toPush:Int = Std.parseInt(splitted[i]);

					if (!Math.isNaN(toPush))
					{
						if (toPush > 255) {
							toPush = 255;
						}
						else if (toPush < 0) {
							toPush *= -1;
						}

						leColor.push(toPush);
					}
				}

				if (leColor.length > 2)
				{
					bgColorStepperR.value = leColor[0];
					bgColorStepperG.value = leColor[1];
					bgColorStepperB.value = leColor[2];

					updateBG();
				}
			}
		});

		iconInputText = new FlxUIInputText(10, bgColorStepperR.y + 70, 100, '', 8);
		blockPressWhileTypingOn.push(iconInputText);

		defaultDiffInputText = new FlxUIInputText(10, iconInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(defaultDiffInputText);

		difficultiesInputText = new FlxUIInputText(10, defaultDiffInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(difficultiesInputText);

		difficultiesNamesInputText = new FlxUIInputText(10, difficultiesInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(difficultiesNamesInputText);

		difficultiesSuffixesInputText = new FlxUIInputText(10, difficultiesNamesInputText.y + 40, 200, '', 8);
		blockPressWhileTypingOn.push(difficultiesSuffixesInputText);

		tab_group.add(new FlxText(defaultDiffInputText.x, defaultDiffInputText.y - 20, 0, 'Default Difficulty\'s ID:'));
		tab_group.add(new FlxText(difficultiesInputText.x, difficultiesInputText.y - 20, 0, 'Difficulties\'s IDs:'));
		tab_group.add(new FlxText(difficultiesNamesInputText.x, difficultiesNamesInputText.y - 20, 0, 'Difficulties\'s Names:'));
		tab_group.add(new FlxText(difficultiesSuffixesInputText.x, difficultiesSuffixesInputText.y - 20, 0, 'Difficulties\'s Suffixes:'));
		tab_group.add(new FlxText(difficultiesSuffixesInputText.x, difficultiesSuffixesInputText.y + 20, 0, 'Default difficulties are "Easy, Normal, Hard"\nwithout quotes.'));

		var hideFreeplayCheckbox:FlxUICheckBox = new FlxUICheckBox(10, 317.5, null, null, "Hide Week from Freeplay?", 100);
		hideFreeplayCheckbox.checked = weekFile.hideFreeplay;
		hideFreeplayCheckbox.callback = function():Void {
			weekFile.hideFreeplay = hideFreeplayCheckbox.checked;
		};
		
		var copyDiffs:FlxButton = new FlxButton(150, difficultiesSuffixesInputText.y + 40, "Copy Diffs", function():Void
		{
			difficultiesCopy = weekFile.songs[curSelected].difficulties;
			defaultDifficultyCopy = weekFile.songs[curSelected].defaultDifficulty;
		});

		var pasteDiffs:FlxButton = new FlxButton(150, copyDiffs.y + 25, "Paste Diffs", function():Void
		{
			if (difficultiesCopy != null) {
				weekFile.songs[curSelected].difficulties = difficultiesCopy;
			}

			if (defaultDifficultyCopy != null) {
				weekFile.songs[curSelected].defaultDifficulty = defaultDifficultyCopy;
			}

			defaultDiffInputText.text = '';
			difficultiesInputText.text = '';
			difficultiesNamesInputText.text = '';
			difficultiesSuffixesInputText.text = '';
	
			if (weekFile.songs[curSelected].difficulties != null)
			{
				var diffNames:String = weekFile.songs[curSelected].difficulties[0][0];

				for (i in 1...weekFile.songs[curSelected].difficulties[0].length) {
					diffNames += ', ' + weekFile.songs[curSelected].difficulties[0][i];
				}

				difficultiesNamesInputText.text = diffNames;

				var diffIDs:String = weekFile.songs[curSelected].difficulties[1][0];

				for (i in 1...weekFile.songs[curSelected].difficulties[1].length) {
					diffIDs += ', ' + weekFile.songs[curSelected].difficulties[1][i];
				}

				difficultiesInputText.text = diffIDs;

				var diffSuffixes:String = weekFile.songs[curSelected].difficulties[2][0];

				for (i in 1...weekFile.songs[curSelected].difficulties[2].length) {
					diffSuffixes += ', ' + weekFile.songs[curSelected].difficulties[2][i];
				}

				difficultiesSuffixesInputText.text = diffSuffixes;
			}
	
			if (weekFile.songs[curSelected].defaultDifficulty != null) {
				defaultDiffInputText.text = weekFile.songs[curSelected].defaultDifficulty;
			}
		});

		tab_group.add(new FlxText(10, bgColorStepperR.y - 18, 0, 'Selected background Color R/G/B:'));
		tab_group.add(new FlxText(10, iconInputText.y - 18, 0, 'Selected icon:'));
		tab_group.add(bgColorStepperR);
		tab_group.add(bgColorStepperG);
		tab_group.add(bgColorStepperB);
		tab_group.add(copyColor);
		tab_group.add(pasteColor);
		tab_group.add(copyDiffs);
		tab_group.add(pasteDiffs);
		tab_group.add(iconInputText);
		tab_group.add(defaultDiffInputText);
		tab_group.add(difficultiesInputText);
		tab_group.add(difficultiesNamesInputText);
		tab_group.add(difficultiesSuffixesInputText);
		tab_group.add(hideFreeplayCheckbox);

		UI_box.addGroup(tab_group);
	}

	function updateBG():Void
	{
		weekFile.songs[curSelected].color[0] = Math.round(bgColorStepperR.value);
		weekFile.songs[curSelected].color[1] = Math.round(bgColorStepperG.value);
		weekFile.songs[curSelected].color[2] = Math.round(bgColorStepperB.value);

		bg.color = FlxColor.fromRGB(weekFile.songs[curSelected].color[0], weekFile.songs[curSelected].color[1], weekFile.songs[curSelected].color[2]);
	}

	function changeSelection(change:Int = 0, ?playSound:Bool = true):Void
	{
		curSelected = CoolUtil.boundSelection(curSelected + change, weekFile.songs.length);

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

		for (icon in grpIcons)
		{
			icon.alpha = 0.6;

			if (icon.ID == curSelected) {
				icon.alpha = 1;
			}
		}

		Debug.logInfo(weekFile.songs[curSelected]);

		iconInputText.text = weekFile.songs[curSelected].character;

		bgColorStepperR.value = Math.round(weekFile.songs[curSelected].color[0]);
		bgColorStepperG.value = Math.round(weekFile.songs[curSelected].color[1]);
		bgColorStepperB.value = Math.round(weekFile.songs[curSelected].color[2]);

		defaultDiffInputText.text = '';
		difficultiesInputText.text = '';
		difficultiesNamesInputText.text = '';
		difficultiesSuffixesInputText.text = '';

		if (weekFile.songs[curSelected].difficulties != null)
		{
			var diffNames:String = weekFile.songs[curSelected].difficulties[0][0];

			for (i in 1...weekFile.songs[curSelected].difficulties[0].length) {
				diffNames += ', ' + weekFile.songs[curSelected].difficulties[0][i];
			}
			difficultiesNamesInputText.text = diffNames;

			var diffIDs:String = weekFile.songs[curSelected].difficulties[1][0];

			for (i in 1...weekFile.songs[curSelected].difficulties[1].length) {
				diffIDs += ', ' + weekFile.songs[curSelected].difficulties[1][i];
			}
			difficultiesInputText.text = diffIDs;

			var diffSuffixes:String = weekFile.songs[curSelected].difficulties[2][0];

			for (i in 1...weekFile.songs[curSelected].difficulties[2].length) {
				diffSuffixes += ', ' + weekFile.songs[curSelected].difficulties[2][i];
			}
			difficultiesSuffixesInputText.text = diffSuffixes;
		}

		if (weekFile.songs[curSelected].defaultDifficulty != null)
		{
			defaultDiffInputText.text = weekFile.songs[curSelected].defaultDifficulty;
		}

		updateBG();

		if (playSound) {
			FlxG.sound.play(Paths.getSound('scrollMenu'), 0.4);
		}
	}

	var holdTime:Float = 0;

	public override function update(elapsed:Float):Void
	{
		if (WeekEditorState.loadedWeek != null)
		{
			super.update(elapsed);

			Transition.skipNextTransIn = true;
			Transition.skipNextTransOut = true;

			FlxG.switchState(new WeekEditorFreeplayState(WeekEditorState.loadedWeek));
			WeekEditorState.loadedWeek = null;

			return;
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

		if (!blockInput)
		{
			FlxG.sound.muteKeys = TitleState.muteKeys;
			FlxG.sound.volumeDownKeys = TitleState.volumeDownKeys;
			FlxG.sound.volumeUpKeys = TitleState.volumeUpKeys;

			if (FlxG.keys.justPressed.ESCAPE)
			{
				difficultiesCopy = null;
				defaultDifficultyCopy = null;

				FlxG.switchState(new MasterEditorMenu());
			}

			if (weekFile.songs.length > 1)
			{
				if (controls.UI_UP_P)
				{
					changeSelection(-1, true);

					holdTime = 0;
				}

				if (controls.UI_DOWN_P)
				{
					changeSelection(1, true);

					holdTime = 0;
				}

				if (controls.UI_DOWN || controls.UI_UP)
				{
					var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
					holdTime += elapsed;
					var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

					if (holdTime > 0.5 && checkNewHold - checkLastHold > 0) {
						changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -1 : 1), true);
					}
				}

				if (FlxG.mouse.wheel != 0)
				{
					FlxG.sound.play(Paths.getSound('scrollMenu'));

					changeSelection(-1 * FlxG.mouse.wheel);
				}
			}
		}

		super.update(elapsed);
	}
}