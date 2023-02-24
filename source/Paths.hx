package;

#if sys
import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
import openfl.display.BitmapData;

#if cpp
import audio.MiniMP3;
import lime.media.AudioBuffer;
import openfl.utils.ByteArray;
#end
#else
import openfl.utils.Assets as OpenFlAssets;
#end

import haxe.Json;
import haxe.format.JsonParser;

import flixel.FlxG;
import lime.utils.Assets;
import openfl.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class Paths
{
	public static var songLibrary:String = 'songs';

	public static var SOUND_EXT:String = #if MP3_ALLOWED 'mp3' #else 'ogg' #end;
	public static var VIDEO_EXT:String = 'mp4';

	public static var currentModDirectory:String = null;

	#if MODS_ALLOWED
	public static var ignoreModFolders:Array<String> =
	[
		'characters',
		'custom_events',
		'custom_notetypes',
		'menucharacters',
		'data',
		songLibrary,
		'music',
		'sounds',
		'title',
		'videos',
		'images',
		'portraits',
		'shaders',
		'stages',
		'weeks',
		'fonts',
		'scripts',
		'achievements'
	];
	#end

	public static function excludeAsset(key:String):Void
	{
		if (!dumpExclusions.contains(key)) dumpExclusions.push(key);
	}

	public static var dumpExclusions:Array<String> =
	[
		'assets/music/freakyMenu.$SOUND_EXT',
		'assets/shared/music/breakfast.$SOUND_EXT',
		'assets/shared/music/tea-time.$SOUND_EXT'
	];

	public static function clearUnusedMemory():Void
	{
		for (key in currentTrackedAssets.keys())
		{
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				var obj:Null<FlxGraphic> = currentTrackedAssets.get(key);

				@:privateAccess
				if (obj != null)
				{
					openfl.Assets.cache.removeBitmapData(key);
					FlxG.bitmap._cache.remove(key);
					obj.destroy();
					currentTrackedAssets.remove(key);
				}
			}
		}

		System.gc();
	}

	public static var localTrackedAssets:Array<String> = [];

	public static function clearStoredMemory():Void
	{
		@:privateAccess
		for (key in FlxG.bitmap._cache.keys())
		{
			var obj:Null<FlxGraphic> = FlxG.bitmap._cache.get(key);
			if (obj != null && !currentTrackedAssets.exists(key))
			{
				openfl.Assets.cache.removeBitmapData(key);
				FlxG.bitmap._cache.remove(key);
				obj.destroy();
			}
		}

		for (key in currentTrackedSounds.keys())
		{
			if (key != null && !localTrackedAssets.contains(key) && !dumpExclusions.contains(key))
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		localTrackedAssets = [];

		#if !html5
		openfl.Assets.cache.clear(songLibrary);
		#end
	}

	public static var currentLevel:String = null;

	public static function setCurrentLevel(name:String):Void
	{
		currentLevel = formatToSongPath(name);
	}

	public static function getPath(file:String, type:AssetType = TEXT, ?library:Null<String> = null):String
	{
		if (library != null && library.length > 0) {
			return getLibraryPath(file, library);
		}

		if (currentLevel != null && currentLevel.length > 0)
		{
			var levelPath:String = '';

			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPath(file, currentLevel);

				if (fileExists(levelPath, type, currentLevel, true)) {
					return levelPath;
				}
			}

			levelPath = getLibraryPath(file, 'shared');

			if (fileExists(levelPath, type, 'shared', true)) {
				return levelPath;
			}
		}

		return getPreloadPath(file);
	}

	public static function getLibraryPath(file:String = '', library:String = 'shared'):String
	{
		if (library == 'preload' || library == 'default') {
			return getPreloadPath(file);
		}

		return getLibraryPathForce(file, library);
	}

	public static function getLibraryPathForce(file:String = '', library:String = 'shared'):String
	{
		return #if web '$library:' + #end getPreloadPath('$library/$file');
	}

	public static function getPreloadPath(file:String = ''):String
	{
		return 'assets/$file';
	}

	public static function getFile(file:String, type:AssetType = TEXT, ?library:Null<String> = null):String
	{
		#if MODS_ALLOWED
		if (library != null && library.length > 0 && library != 'preload' && library != 'default')
		{
			var modLibraryPath:String = modFolders(library + '/' + file);

			if (FileSystem.exists(modLibraryPath)) {
				return modLibraryPath;
			}
		}

		if (currentLevel != null && currentLevel.length > 0 && currentLevel != 'preload' && currentLevel != 'default')
		{
			var modLibraryPath:String = modFolders(currentLevel + '/' + file);

			if (FileSystem.exists(modLibraryPath)) {
				return modLibraryPath;
			}
		}

		var modPath:String = modFolders(file);

		if (FileSystem.exists(modPath)) {
			return modPath;
		}
		#end

		return getPath(file, type, library);
	}

	@:deprecated("`Paths.file()` is deprecated, use 'Paths.getFile()' instead")
	public static function file(file:String, type:AssetType = TEXT, ?library:String):String
	{
		Debug.logWarn("`Paths.file()` is deprecated! use 'Paths.getFile()' instead");

		return getFile(file, type, library);
	}

	public static function getTxt(key:String, ?library:String):String
	{
		if (key.endsWith('.txt')) {
			key = key.replace('.txt', '');
		}

		return getFile('$key.txt', TEXT, library);
	}

	public static function getXml(key:String, ?library:String):String
	{
		if (key.endsWith('.xml')) {
			key = key.replace('.xml', '');
		}

		return getFile('$key.xml', TEXT, library);
	}

	public static function getJson(key:String, ?library:String):String
	{
		if (key.endsWith('.json')) {
			key = key.replace('.json', '');
		}

		return getFile('$key.json', TEXT, library);
	}

	public static function getLua(key:String, ?library:String):String
	{
		if (key.endsWith('.lua')) {
			key = key.replace('.lua', '');
		}

		return getFile('$key.lua', TEXT, library);
	}

	public static function getSound(key:String, ?library:String, ?getId:Bool = false):Dynamic
	{
		return getTrackedAudioFromFile('sounds', '$key', library, getId);
	}

	@:deprecated("`Paths.sound()` is deprecated, use 'Paths.getSound()' instead")
	public static function sound(key:String, ?library:String, ?getId:Bool = false):Dynamic
	{
		Debug.logWarn("`Paths.sound()` is deprecated! use 'Paths.getSound()' instead");

		return getSound(key, library, getId);
	}

	public static function getSoundRandom(key:String, min:Int, max:Int, ?library:String, ?getId:Bool = false):Dynamic
	{
		return getSound(key + FlxG.random.int(min, max), library, getId);
	}

	@:deprecated("`Paths.soundRandom()` is deprecated, use 'Paths.getSoundRandom()' instead")
	public static function soundRandom(key:String, min:Int, max:Int, ?library:String, ?getId:Bool = false):Dynamic
	{
		Debug.logWarn("`Paths.soundRandom()` is deprecated! use 'Paths.getSoundRandom()' instead");

		return getSoundRandom(key, min, max, library, getId);
	}

	public static function getMusic(key:String, ?library:String, ?getId:Bool = false):Dynamic
	{
		return getTrackedAudioFromFile('music', '$key', library, getId);
	}

	@:deprecated("`Paths.music()` is deprecated, use 'Paths.getMusic()' instead")
	public static function music(key:String, ?library:String, ?getId:Bool = false):Dynamic
	{
		Debug.logWarn("`Paths.music()` is deprecated! use 'Paths.getMusic()' instead");

		return getMusic(key, library, getId);
	}

	public static function getInst(song:String, ?diffPath:String = '', ?getId:Bool = false):Dynamic
	{
		var songPath:String = formatToSongPath(song);

		var path:String = getTrackedAudioFromFile(songPath + '-' + diffPath, 'Inst', songLibrary, true);

		if (fileExists(path, SOUND, songLibrary, true)) {
			return getTrackedAudioFromFile(null, path, null);
		}

		var path:String = getTrackedAudioFromFile(songPath, 'Inst' + '-' + diffPath, songLibrary, true);

		if (fileExists(path, SOUND, songLibrary, true)) {
			return getTrackedAudioFromFile(null, path, null);
		}

		var path:String = getTrackedAudioFromFile(songPath + '-' + diffPath, 'Inst' + '-' + diffPath, songLibrary, true);

		if (fileExists(path, SOUND, songLibrary, true)) {
			return getTrackedAudioFromFile(null, path, null);
		}

		return getTrackedAudioFromFile(songPath, 'Inst', songLibrary, getId);
	}

	@:deprecated("`Paths.inst()` is deprecated, use 'Paths.getInst()' instead")
	public static function inst(song:String, ?diffPath:String = '', ?getId:Bool = false):Dynamic
	{
		Debug.logWarn("`Paths.inst()` is deprecated! use 'Paths.getInst()' instead");

		return getInst(song, diffPath, getId);
	}

	public static function getVoices(song:String, ?diffPath:String = '', ?getId:Bool = false):Dynamic
	{
		var songPath:String = formatToSongPath(song);

		var path:String = getTrackedAudioFromFile(songPath + '-' + diffPath, 'Voices', songLibrary, true);

		if (fileExists(path, SOUND, songLibrary, true)) {
			return getTrackedAudioFromFile(null, path, null);
		}

		var path:String = getTrackedAudioFromFile(songPath, 'Voices' + '-' + diffPath, songLibrary, true);

		if (fileExists(path, SOUND, songLibrary, true)) {
			return getTrackedAudioFromFile(null, path, null);
		}

		var path:String = getTrackedAudioFromFile(songPath + '-' + diffPath, 'Voices' + '-' + diffPath, songLibrary, true);

		if (fileExists(path, SOUND, songLibrary, true)) {
			return getTrackedAudioFromFile(null, path, null);
		}

		return getTrackedAudioFromFile(songPath, 'Voices', songLibrary, getId);
	}

	@:deprecated("`Paths.voices()` is deprecated, use 'Paths.getVoices()' instead")
	public static function voices(song:String, ?diffPath:String = '', ?getId:Bool = false):Dynamic
	{
		Debug.logWarn("`Paths.voices()` is deprecated! use 'Paths.getVoices()' instead");

		return getVoices(song, diffPath, getId);
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	public static function getImage(key:String, ?library:String, ?getId:Bool = false):Dynamic
	{
		if (key.endsWith('.png')) {
			key.replace('.png', '');
		}

		var ourFile:String = getFile('images/$key.png', IMAGE, library);

		if (fileExists('$key.png', IMAGE, library, true)) {
			ourFile = '$key.png';
		}

		if (getId) {
			return ourFile;
		}

		if (fileExists(ourFile, IMAGE, library, true))
		{
			if (!currentTrackedAssets.exists(ourFile))
			{
				#if sys
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(BitmapData.fromFile(ourFile), false, ourFile);
				#else
				var newGraphic:FlxGraphic = FlxG.bitmap.add(ourFile, false, ourFile);
				#end

				newGraphic.persist = true;
				currentTrackedAssets.set(ourFile, newGraphic);
			}

			localTrackedAssets.push(ourFile);
			return currentTrackedAssets.get(ourFile);
		}

		return null;
	}

	@:deprecated("`Paths.image()` is deprecated, use 'Paths.getImage()' instead")
	public static function image(key:String, ?library:String = null):FlxGraphic
	{
		Debug.logWarn("`Paths.image()` is deprecated! use 'Paths.getImage()' instead");

		return getImage(key, library);
	}

	public static function getVideo(key:String, ?library:String):String
	{
		if (key.endsWith('.$VIDEO_EXT')) {
			key = key.replace('.$VIDEO_EXT', '');
		}

		return getFile('videos/$key.$VIDEO_EXT', BINARY, library);
	}

	@:deprecated("`Paths.video()` is deprecated, use 'Paths.getVideo()' instead")
	public static function video(key:String, ?library:String):String
	{
		Debug.logWarn("`Paths.video()` is deprecated! use 'Paths.getVideo()' instead");

		return getVideo(key, library);
	}

	public static function getWebm(key:String, ?library:String):String
	{
		if (key.endsWith('.webm')) {
			key = key.replace('.webm', '');
		}

		return getFile('videos/$key.webm', BINARY, library);
	}

	@:deprecated("`Paths.webm()` is deprecated, use 'Paths.getWebm()' instead")
	public static function webm(key:String, ?library:String):String
	{
		Debug.logWarn("`Paths.webm()` is deprecated! use 'Paths.getWebm()' instead");

		return getWebm(key, library);
	}

	public static function getWebmSound(key:String, ?library:String, ?getId:Bool = false):Dynamic
	{
		return getTrackedAudioFromFile('videos', key, library, getId);
	}

	@:deprecated("`Paths.webmSound()` is deprecated, use 'Paths.getWebmSound()' instead")
	public static function webmSound(key:String, ?library:String, ?getId:Bool = false):Dynamic
	{
		Debug.logWarn("`Paths.webmSound()` is deprecated! use 'Paths.getWebmSound()' instead");

		return getWebmSound(key, library, getId);
	}

	public static function getTextFromFile(key:String, ?library:String = null):String
	{
		var ourPath:String = getFile(key, TEXT, library);

		if (fileExists(ourPath, TEXT, library, true))
		{
			#if sys
			return File.getContent(ourPath);
			#else
			return OpenFlAssets.getText(ourPath);
			#end
		}

		#if sys
		return File.getContent(key);
		#else
		return OpenFlAssets.getText(key);
		#end
	}

	public static function getFont(key:String, ?library:String):String
	{
		return getFile('fonts/$key', FONT, library);
	}

	public static function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSparrow(getImage(key, library), getTextFromFile(getXml('images/$key', library)));
	}

	public static function getPackerAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		return FlxAtlasFrames.fromSpriteSheetPacker(getImage(key, library), getTextFromFile(getTxt('images/$key', library)));
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function getTrackedAudioFromFile(path:String, key:String, ?library:String, ?getId:Bool = false):Dynamic
	{
		if (key.endsWith('.$SOUND_EXT')) {
			key = key.replace('.$SOUND_EXT', '');
		}

		#if cpp
		if (key.endsWith('.ogg')) {
			key = key.replace('.ogg', '');
		}
		#end

		var gottenPath:String = getFile('$key.$SOUND_EXT', SOUND, library);

		if (path != null && path.length > 0) {
			gottenPath = getFile('$path/$key.$SOUND_EXT', SOUND, library);
		}

		#if cpp
		var fileToCheckOgg:String = getFile('$key.ogg', SOUND, library);

		if (path != null && path.length > 0) {
			fileToCheckOgg = getFile('$path/$key.ogg', SOUND, library);
		}

		if (fileExists(fileToCheckOgg, SOUND, library, true)) {
			gottenPath = fileToCheckOgg;
		}

		var fileToCheckWav:String = getFile('$key.wav', SOUND, library);

		if (path != null && path.length > 0) {
			fileToCheckWav = getFile('$path/$key.wav', SOUND, library);
		}

		if (fileExists(fileToCheckWav, SOUND, library, true)) {
			gottenPath = fileToCheckWav;
		}
		#end

		if (fileExists(key + '.$SOUND_EXT', SOUND, library, true)) {
			gottenPath = key + '.$SOUND_EXT';
		}

		#if cpp
		if (fileExists(key + '.ogg', SOUND, library, true)) {
			gottenPath = key + '.ogg';
		}

		if (fileExists(key + '.wav', SOUND, library, true)) {
			gottenPath = key + '.wav';
		}
		#end

		if (getId) {
			return gottenPath;
		}

		if (!currentTrackedSounds.exists(gottenPath))
		{
			if (fileExists(gottenPath, SOUND, library, true))
			{
				#if sys
				#if cpp
				if (gottenPath.endsWith('.$SOUND_EXT'))
				{
					var decoded = MiniMP3.decodeMP3(ByteArray.fromFile(gottenPath));
					var encoded:ByteArray = MiniMP3.encodeWav(decoded.data, decoded.sampleCount, decoded.sampleRate, decoded.channels);
	
					var audioBuffer:AudioBuffer = AudioBuffer.fromBytes(encoded);
					currentTrackedSounds.set(gottenPath, Sound.fromAudioBuffer(audioBuffer));
				}
				else #end currentTrackedSounds.set(gottenPath, Sound.fromFile(gottenPath));
				#else
				currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(gottenPath));
				#end
			}
		}

		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	public static function formatToSongPath(path:String):String
	{
		var invalidChars:EReg = ~/[~&\\;:<>#]/;
		var hideChars:EReg = ~/[.,'"%?!]/;

		var path:String = invalidChars.split(path.replace(' ', '-')).join('-');
		return hideChars.split(path).join('').toLowerCase();
	}

	public static function fileExists(key:String, type:AssetType, ?library:String, ?optimize:Bool = false):Bool
	{
		if (optimize)
		{
			#if sys
			if (FileSystem.exists(key)) {
				return true;
			}
			#else
			if (OpenFlAssets.exists(key, type)) {
				return true;
			}
			#end
		}

		var altPath:String = getFile(key, type, library);

		#if sys
		if (FileSystem.exists(altPath) || FileSystem.exists(key)) {
			return true;
		}
		#else
		if (OpenFlAssets.exists(altPath, type) || OpenFlAssets.exists(key, type)) {
			return true;
		}
		#end

		return false;
	}

	#if MODS_ALLOWED
	public static function mods(key:String = ''):String
	{
		return 'mods/' + key;
	}

	public static function modFolders(key:String):String
	{
		if (currentModDirectory != null && currentModDirectory.length > 0) 
		{
			var fileToCheck:String = mods(currentModDirectory + '/' + key);
	
			if (FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}

		for (mod in getGlobalMods())
		{
			var fileToCheck:String = mods(mod + '/' + key);
		
			if (FileSystem.exists(fileToCheck)) {
				return fileToCheck;
			}
		}

		return 'mods/' + key;
	}

	public static var globalMods:Array<String> = [];

	public static function getGlobalMods():Array<String>
	{
		return globalMods;
	}

	public static function pushGlobalMods():Array<String> // prob a better way to do this but idc
	{
		globalMods = [];

		var path:String = 'modsList.txt';

		if (FileSystem.exists(path))
		{
			var list:Array<String> = CoolUtil.coolTextFile(path, false, true);

			for (i in list)
			{
				var dat:Array<String> = i.split("|");
	
				if (dat[1] == "1")
				{
					var folder = dat[0];
					var path:String = Paths.mods(folder + '/pack.json');
			
					if (FileSystem.exists(path))
					{
						try
						{
							var rawJson:String = File.getContent(path);
				
							if (rawJson != null && rawJson.length > 0)
							{
								var stuff:Dynamic = Json.parse(rawJson);
								var global:Bool = Reflect.getProperty(stuff, "runsGlobally");
							
								if (global) globalMods.push(dat[0]);
							}
						}
						catch (e:Dynamic) {
							Debug.logError(e);
						}
					}
				}
			}
		}

		return globalMods;
	}

	public static function getModDirectories():Array<String>
	{
		var list:Array<String> = [];
		var modsFolder:String = mods();

		if (FileSystem.exists(modsFolder))
		{
			for (folder in FileSystem.readDirectory(modsFolder))
			{
				var path:String = Path.join([modsFolder, folder]);

				if (FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder) && !list.contains(folder)) {
					list.push(folder);
				}
			}
		}
	
		return list;
	}
	#end
}