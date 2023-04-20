package;

import flixel.FlxG;
import haxe.io.Path;
import flixel.FlxState;
import lime.app.Future;
import flixel.FlxSprite;
import lime.app.Promise;
import openfl.media.Sound;
import openfl.utils.Assets;
import flixel.math.FlxMath;
import flixel.util.FlxTimer;
import openfl.utils.ByteArray;
import lime.utils.AssetLibrary;
import lime.utils.AssetManifest;
import lime.utils.Assets as LimeAssets;

using StringTools;

class LoadingState extends MusicBeatState
{
	inline static var MIN_TIME = 0.5;
	static var loadedPaths:Array<String> = [];

	// Browsers will load create(), you can make your song load a custom directory there
	// If you're compiling to desktop (or something that doesn't use NO_PRELOAD_ALL), search for getNextState instead
	// I'd recommend doing it on both actually lol
	
	// TO DO: Make this easier
	
	var target:FlxState;
	var stopMusic = false;
	var directory:String;
	var callbacks:MultiCallback;
	var targetShit:Float = 0;

	function new(target:FlxState, stopMusic:Bool, directory:String)
	{
		super();
		this.target = target;
		this.stopMusic = stopMusic;
		this.directory = directory;
	}

	var funkay:FlxSprite;
	var loadBar:FlxSprite;
	override function create()
	{
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFFcaff4d);
		add(bg);

		funkay = new FlxSprite();
		if(Paths.fileExists('images/funkay.png', IMAGE))
			funkay.loadGraphic(Paths.getImage('funkay'));
		else
			funkay.loadGraphic(Paths.getImage('bg/funkay'));
		funkay.setGraphicSize(0, FlxG.height);
		funkay.updateHitbox();
		funkay.antialiasing = true;
		add(funkay);
		funkay.scrollFactor.set();
		funkay.screenCenter();

		loadBar = new FlxSprite(0, FlxG.height - 20).makeGraphic(FlxG.width, 10, 0xFFff16d2);
		loadBar.screenCenter(X);
		loadBar.scale.x = FlxMath.EPSILON;
		add(loadBar);

		CustomFadeTransition.nextCamera = null;
		var fadeTime = 0.5;

		FlxG.camera.fade(FlxG.camera.bgColor, fadeTime, true, function () {
			initSongsManifest().onComplete
			(
				function (lib)
				{
					callbacks = new MultiCallback(onLoad);
					var introComplete = callbacks.add("introComplete");
					if(PlayState.SONG != null) {
						checkLoadSong(getSongPath());
						if(PlayState.SONG.needsVoices)
							checkLoadSong(getVocalPath());
					}
					#if NO_PRELOAD_ALL
					checkLibrary("shared");
					if(directory != null && directory.length > 0 && directory != 'shared') {
						checkLibrary(directory);
					}
					#end
					new FlxTimer().start(MIN_TIME, function(_) introComplete());
				}
			);
		});
	}
	
	function checkLoadSong(path:String)
	{
		if (!isSoundLoaded(path))
		{
			var library = Assets.getLibrary("songs");
			final symbolPath = path.split(":").pop();
			// @:privateAccess
			// library.types.set(symbolPath, SOUND);
			// @:privateAccess
			// library.pathGroups.set(symbolPath, [library.__cacheBreak(symbolPath)]);
			var callback = callbacks.add("song:" + path);
			//Assets.loadSound(path).onComplete(function (_) { callback(); });

			if(path.startsWith('${Paths.songLibrary}:')) {
				#if (MP3_ALLOWED && cpp)
				if(path.endsWith('.mp3')) {
					Assets.loadBytes(path).onComplete(function(byts:ByteArray) {
						Debug.logInfo('Loaded path: ' + path);
						#if MODS_ALLOWED loadedPaths.push(path); #end
						Paths.currentTrackedSounds.set(path, Sound.fromMP3(byts));
						callback();
					}).onError(function(e) {
						Debug.logError('Error: ' + e);
						callback();
					});
				} else { #end
					Assets.loadSound(path).onComplete(function(snd:Sound) {
						Debug.logInfo('Loaded path: ' + path);
						#if MODS_ALLOWED loadedPaths.push(path); #end
						Paths.currentTrackedSounds.set(path, snd);
						callback();
					}).onError(function(e) {
						Debug.logError('Error: ' + e);
						callback();
					});
				#if (MP3_ALLOWED && cpp) } #end
			} #if MODS_ALLOWED else {
				Sound.loadFromFile(path).onComplete(function(snd:Sound) {
					Debug.logInfo('Loaded path: ' + path);
					#if MODS_ALLOWED loadedPaths.push(path); #end
					Paths.currentTrackedSounds.set(path, snd);
					callback();
				}).onError(function(e) {
					Debug.logError('Error: ' + e);
					callback();
				});
			} #end
		}
	}

	#if NO_PRELOAD_ALL
	function checkLibrary(library:String) {
		Debug.logTrace(Assets.hasLibrary(library));
		if (!isLibraryLoaded(library))
		{
			@:privateAccess
			if (!LimeAssets.libraryPaths.exists(library))
				throw "Missing library: " + library;

			var callback = callbacks.add("library:" + library);
			Assets.loadLibrary(library).onComplete(function (_) { callback(); });
		}
	}
	#end

	override function update(elapsed:Float)
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

		if (callbacks != null)
		{
			targetShit = FlxMath.remapToRange(callbacks.numRemaining / callbacks.length, 1, 0, 0, 1);

			loadBar.scale.x = FlxMath.lerp(loadBar.scale.x, targetShit, CoolUtil.boundTo(elapsed * 28, 0, 1));
			FlxG.watch.addQuick('percentage?', callbacks.numRemaining / callbacks.length);
		}
	}
	
	function onLoad()
	{
		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.switchState(target);
	}
	
	static function getSongPath()
	{
		return Paths.getInst(PlayState.SONG.songID, CoolUtil.difficultyStuff[PlayState.lastDifficulty][2], true);
	}
	
	static function getVocalPath()
	{
		return Paths.getVoices(PlayState.SONG.songID, CoolUtil.difficultyStuff[PlayState.lastDifficulty][2], true);
	}

	public static function loadAndSwitchState(target:FlxState, stopMusic:Bool = false, ?skipLoading:Bool = false):Void
	{
		FlxG.switchState(getNextState(target, stopMusic, skipLoading));
	}

	static function getNextState(target:FlxState, stopMusic:Bool = false, ?skipLoading:Bool = false):FlxState
	{
		var directory:String = 'shared';
		var weekDir:String = StageData.forceNextDirectory;

		StageData.forceNextDirectory = null;

		if (weekDir != null && weekDir.length > 0 && weekDir != '') directory = weekDir;

		Paths.setCurrentLevel(directory);
		Debug.logInfo('Setting asset folder to "' + directory + '"');

		var loaded:Bool = isLibraryLoaded('shared') && isLibraryLoaded(directory);

		if (OptionData.loadingScreen #if PRELOAD_ALL && !skipLoading #end)
		{
			if (PlayState.SONG != null) {
				loaded = loaded && isSoundLoaded(getSongPath()) && (!PlayState.SONG.needsVoices || isSoundLoaded(getVocalPath()));
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
		return Assets.cache.hasSound(path) #if MODS_ALLOWED || loadedPaths.contains(path) #end;
	}

	static function isLibraryLoaded(library:String):Bool
	{
		return Assets.getLibrary(library) != null;
	}

	override function destroy()
	{
		super.destroy();
		
		callbacks = null;
	}
	
	static function initSongsManifest()
	{
		var id = "songs";
		var promise = new Promise<AssetLibrary>();

		var library = LimeAssets.getLibrary(id);

		if (library != null)
		{
			return Future.withValue(library);
		}

		var path = id;
		var rootPath = null;

		@:privateAccess
		var libraryPaths = LimeAssets.libraryPaths;
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
			else
			{
				rootPath = Path.directory(path);
			}
			@:privateAccess
			path = LimeAssets.__cacheBreak(path);
		}

		AssetManifest.loadFromFile(path, rootPath).onComplete(function(manifest)
		{
			if (manifest == null)
			{
				promise.error("Cannot parse asset manifest for library \"" + id + "\"");
				return;
			}

			var library = AssetLibrary.fromManifest(manifest);

			if (library == null)
			{
				promise.error("Cannot open library \"" + id + "\"");
			}
			else
			{
				@:privateAccess
				LimeAssets.libraries.set(id, library);
				library.onChange.add(LimeAssets.onChange.dispatch);
				promise.completeWith(Future.withValue(library));
			}
		}).onError(function(_)
		{
			promise.error("There is no asset library with an ID of \"" + id + "\"");
		});

		return promise.future;
	}
}

class MultiCallback
{
	public var callback:Void->Void;
	public var logId:String = null;
	public var length(default, null) = 0;
	public var numRemaining(default, null) = 0;
	
	var unfired = new Map<String, Void->Void>();
	var fired = new Array<String>();
	
	public function new (callback:Void->Void, logId:String = null)
	{
		this.callback = callback;
		this.logId = logId;
	}
	
	public function add(id = "untitled")
	{
		id = '$length:$id';
		length++;
		numRemaining++;
		var func:Void->Void = null;
		func = function ()
		{
			if (unfired.exists(id))
			{
				unfired.remove(id);
				fired.push(id);
				numRemaining--;
				
				if (logId != null)
					log('fired $id, $numRemaining remaining');
				
				if (numRemaining == 0)
				{
					if (logId != null)
						log('all callbacks fired');
					callback();
				}
			}
			else
				log('already fired $id');
		}
		unfired[id] = func;
		return func;
	}
	
	inline function log(msg):Void
	{
		if (logId != null)
			Debug.logInfo('$logId: $msg');
	}
	
	public function getFired() return fired.copy();
	public function getUnfired() return [for (id in unfired.keys()) id];
}