package;

#if sys
import sys.FileSystem;
import sys.thread.Thread;
#end

import flixel.FlxG;
import haxe.io.Path;
import lime.app.Future;
import flixel.FlxState;
import flixel.FlxSprite;
import lime.app.Promise;
import flash.media.Sound;
import flixel.math.FlxMath;
import openfl.utils.Assets;
import flixel.util.FlxTimer;
import lime.utils.AssetLibrary;
import flash.display.BitmapData;
import openfl.utils.AssetManifest;
import flixel.graphics.FlxGraphic;
import lime.utils.Assets as LimeAssets;

using StringTools;

class LoadingState extends MusicBeatState
{
	var targetShit:Float = 0;

	var funkay:FlxSprite;
	var loadBar:FlxSprite;
	
	var target:FlxState;
	var stopMusic:Bool = false;
	var directory:String;

	function new(target:FlxState, stopMusic:Bool, directory:String):Void
	{
		super();

		this.target = target;
		this.stopMusic = stopMusic;
		this.directory = directory;
	}

	public static var loadedPaths:Map<String, Bool> = new Map<String, Bool>();

	var curFile:Int = 0;
	var filesToCheck:Array<String> = [];

	var extenstions:Array<String> = [];

	public override function create():Void
	{
		#if sys
		extenstions.push('.png');
		#end
		extenstions.push('.${Paths.SOUND_EXT}');
		#if sys
		#if FEATURE_OGG
		extenstions.push('.ogg');
		#end
		#if FEATURE_WAV
		extenstions.push('.wav');
		#end
		#end

		var bg:FlxSprite = new FlxSprite();
		bg.makeGraphic(FlxG.width, FlxG.height, 0xFFCAFF4D);
		add(bg);

		funkay = new FlxSprite();
	
		if (Paths.fileExists('images/funkay.png', IMAGE))
			funkay.loadGraphic(Paths.getImage('funkay'));
		else
			funkay.loadGraphic(Paths.getImage('bg/funkay'));

		funkay.setGraphicSize(0, FlxG.height);
		funkay.updateHitbox();
		funkay.antialiasing = OptionData.globalAntialiasing;
		funkay.scrollFactor.set();
		funkay.screenCenter();
		add(funkay);

		loadBar = new FlxSprite(0, FlxG.height - 20);
		loadBar.makeGraphic(FlxG.width, 10, 0xFFFF16D2);
		loadBar.antialiasing = OptionData.globalAntialiasing;
		loadBar.screenCenter(X);
		loadBar.scale.x = 0.00001;
		add(loadBar);

		if (CustomFadeTransition.nextCamera != null) {
			CustomFadeTransition.nextCamera = null;
		}

		FlxG.camera.fade(FlxG.camera.bgColor, 0.5, true, function():Void
		{
			#if web
			initSongsManifest().onComplete(function(lib:AssetLibrary):Void
			{
			#end
				if (PlayState.SONG != null)
				{
					filesToCheck.push(getSongPath());

					if (PlayState.SONG.needsVoices) {
						filesToCheck.push(getVocalPath());
					}
				}

				#if sys
				checkLibrary('shared');
				#else
				filesToCheck.push('shared');
				#end

				if (directory != null && directory.length > 0 && directory != 'shared')
				{
					#if sys
					checkLibrary(directory);
					#else
					filesToCheck.push(directory);
					#end
				}

				new FlxTimer().start(1, function(_:FlxTimer):Void
				{
					#if web
					checkFile(filesToCheck[curFile]);
					#elseif sys
					trace(filesToCheck);

					Thread.create(function():Void {
						checkFile(filesToCheck[curFile]);
					});
					#end
				});
			#if web });
			#end
		});
	}

	function checkLibrary(library:String):Void
	{
		#if sys
		var libraryPath:String = Paths.getPreloadPath(library);

		if (FileSystem.exists(libraryPath)) {
			loadFolderForce(libraryPath);
		}
		#if MODS_ALLOWED
		var modPath:String = 'mods';

		if (FileSystem.exists(modPath)) {
			loadFolderForce(modPath);
		}

		if (Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
		{
			var modPath:String = Paths.mods(Paths.currentModDirectory);

			if (FileSystem.exists(modPath)) {
				loadFolderForce(modPath);
			}
		}

		for (mod in Paths.getGlobalMods())
		{
			var fileToCheck:String = Paths.mods(mod);
		
			if (FileSystem.exists(fileToCheck)) {
				loadFolderForce(fileToCheck);
			}
		}
		#end
		#end
	}

	#if sys
	function loadFolderForce(pathFolder:String):Void
	{
		for (path in FileSystem.readDirectory(pathFolder))
		{
			var gottenPath:String = Path.join([pathFolder, path]);

			if (FileSystem.exists(gottenPath))
			{
				if (FileSystem.isDirectory(gottenPath))
				{
					if (path != Paths.songLibrary) {
						loadFolderForce(gottenPath);
					}
				}
				else
				{
					if (!loadedPaths.exists(gottenPath) && !gottenPath.endsWith('pack.png')) {
						filesToCheck.push(gottenPath);
					}
				}
			}
		}
	}
	#end

	function checkFile(path:String):Void
	{
		#if sys
		if (path.endsWith('.png'))
		{
			if (!Paths.currentTrackedAssets.exists(path) && !loadedPaths.exists(path))
			{
				BitmapData.loadFromFile(path).onComplete(function(newBitmap:BitmapData):Void
				{
					var newGraphic:FlxGraphic = FlxG.bitmap.add(newBitmap, false, path);
					newGraphic.persist = true;
					Paths.currentTrackedAssets.set(path, newGraphic);

					loadedPaths.set(path, true);

					Debug.logInfo('loaded path: ' + path);
					onLoadComplete();
				})
				.onError(function(e:Dynamic):Void
				{
					Debug.logError('Error: ' + e);
					onLoadComplete();
				});
			}
			else {
				onLoadComplete();
			}
		}
		#end

		if (path.endsWith('.${Paths.SOUND_EXT}') #if FEATURE_OGG || path.endsWith('.ogg') #end #if FEATURE_WAV || path.endsWith('.wav') #end)
		{
			if (!Paths.currentTrackedSounds.exists(path) && !loadedPaths.exists(path))
			{
				#if sys Sound.loadFromFile(path) #else Assets.loadSound(path) #end.onComplete(function(sound:Sound):Void
				{
					Paths.currentTrackedSounds.set(path, sound);
					loadedPaths.set(path, true);

					Debug.logInfo('loaded path: ' + path);
					onLoadComplete();
				})
				.onError(function(e:Dynamic):Void
				{
					Debug.logError('Error: ' + e);
					onLoadComplete();
				});
			}
			else {
				onLoadComplete();
			}
		}

		#if web
		if (path == 'shared' || path == directory)
		{
			if (!isLibraryLoaded(path))
			{
				@:privateAccess
				if (LimeAssets.libraryPaths.exists(path))
				{
					Assets.loadLibrary(path).onComplete(function(_:AssetLibrary):Void {
						onLoadComplete();
					}).onError(function(e:Dynamic):Void
					{
						Debug.logError('Error: ' + e);
						onLoadComplete();
					});
				}
				else
				{
					Debug.logError('Error: Library "' + path + '" does not exist!');
					onLoadComplete();
				}
			}
			else {
				onLoadComplete();
			}
		}
		#end
	}

	function onLoadComplete():Void
	{
		curFile++;

		if (curFile < filesToCheck.length)
		{
			var ourFile:String = filesToCheck[curFile];

			if (#if web ourFile == 'shared' || ourFile == directory || #end extenstions.contains(ourFile.substring(ourFile.indexOf('.'), ourFile.length))) {
				checkFile(ourFile);
			}
			else {
				onLoadComplete();
			}
		}
		else {
			onLoad();
		}
	}

	public override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		var wacky:Float = FlxG.width * 0.88;

		funkay.setGraphicSize(Std.int(wacky + 0.9 * (funkay.width - wacky)));
		funkay.updateHitbox();

		if (controls.ACCEPT || FlxG.mouse.justPressed)
		{
			funkay.setGraphicSize(Std.int(funkay.width + 60));
			funkay.updateHitbox();
		}

		var length:Int = filesToCheck.length > 0 ? filesToCheck.length : 1;
		targetShit = FlxMath.remapToRange(curFile / length, 0, length, 0, length);

		loadBar.scale.x = FlxMath.lerp(loadBar.scale.x, targetShit, CoolUtil.boundTo(elapsed * 28, 0, 1));
	}
	
	function onLoad():Void
	{
		if (stopMusic && FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			FlxG.sound.music.volume = 0;
		}

		FreeplayMenuState.destroyFreeplayVocals();
		FlxG.switchState(target);
	}

	static function getSongPath():String
	{
		return Paths.getInst(PlayState.SONG.songID, PlayState.lastDifficulty, true);
	}

	static function getVocalPath():String
	{
		return Paths.getVoices(PlayState.SONG.songID, PlayState.lastDifficulty, true);
	}

	public static function loadAndSwitchState(target:FlxState, stopMusic:Bool = false, skipLoading:Bool = false):Void
	{
		FlxG.switchState(getNextState(target, stopMusic, skipLoading));
	}
	
	static function getNextState(target:FlxState, stopMusic:Bool = false, skipLoading:Bool = false):FlxState
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;

		StageData.forceNextDirectory = null;
		if (weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);

		var loaded:Bool = false;

		if (OptionData.loadingScreen && !skipLoading)
		{
			if (PlayState.SONG != null) {
				loaded = isSoundLoaded(getSongPath()) && (!PlayState.SONG.needsVoices || isSoundLoaded(getVocalPath())) #if web && isLibraryLoaded('shared') && isLibraryLoaded(directory) #end;
			}

			if (!loaded) {
				return new LoadingState(target, stopMusic, directory);
			}
		}

		if (stopMusic && FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			FlxG.sound.music.volume = 0;
		}

		FreeplayMenuState.destroyFreeplayVocals();
		return target;
	}

	static function isSoundLoaded(path:String):Bool
	{
		return #if sys loadedPaths.exists(path) #else Assets.cache.hasSound(path) #end;
	}

	#if web
	static function isLibraryLoaded(library:String):Bool
	{
		return Assets.getLibrary(library) != null;
	}

	static function initSongsManifest():Future<AssetLibrary>
	{
		var id:String = 'songs';
		var promise:Promise<AssetLibrary> = new Promise<AssetLibrary>();

		var library:AssetLibrary = LimeAssets.getLibrary(id);

		if (library != null) {
			return Future.withValue(library);
		}

		var path:String = id;
		var rootPath:Null<String> = null;

		@:privateAccess
		var libraryPaths:Map<String, String> = LimeAssets.libraryPaths;
		if (libraryPaths.exists(id))
		{
			path = libraryPaths[id];
			rootPath = Path.directory(path);
		}
		else
		{
			if (StringTools.endsWith(path, ".bundle"))
			{
				rootPath = path;
				path += "/library.json";
			}
			else {
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest:AssetManifest):Void
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library:AssetLibrary = AssetLibrary.fromManifest(manifest);

			if (library == null) {
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_:Dynamic):Void {
			promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		return promise.future;
	}
	#end
}