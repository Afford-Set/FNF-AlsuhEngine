package;

import haxe.Json;
import haxe.io.Path;
import haxe.format.JsonParser;

#if MODS_ALLOWED
import sys.io.File;
import sys.FileSystem;
#end

import flixel.FlxG;
import flash.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;
import flixel.system.FlxAssets;
import flash.display.BitmapData;
import flixel.graphics.FlxGraphic;
import lime.utils.Assets as LimeAssets;
import openfl.utils.Assets as OpenFlAssets;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class Paths
{
	public static var songLibrary:String = 'songs';

	public static var SOUND_EXT:String = #if MP3_ALLOWED 'mp3' #else 'ogg' #end;
	public static var VIDEO_EXT:Array<String> = ['mp4', 'webm', 'mov', 'wmv', 'avi', 'flv'];

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
		'shared:assets/shared/music/breakfast.$SOUND_EXT',
		'shared:assets/shared/music/tea-time.$SOUND_EXT'
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
				LimeAssets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		localTrackedAssets = []; #if PRELOAD_ALL
		openfl.Assets.cache.clear(songLibrary); #end
	}

	public static var currentLevel:String = null;

	public static function setCurrentLevel(name:String):Void
	{
		currentLevel = formatToSongPath(name);
	}

	public static function getPath(file:String, ?type:Null<AssetType> = TEXT, ?library:Null<String> = null):String
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

				if (OpenFlAssets.exists(levelPath, type)) {
					return levelPath;
				}
			}

			levelPath = getLibraryPath(file, 'shared');

			if (OpenFlAssets.exists(levelPath, type)) {
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
		return '$library:' + getPreloadPath('$library/$file');
	}

	public static function getPreloadPath(file:String = ''):String
	{
		return 'assets/$file';
	}

	public static function getFile(file:String, ?type:Null<AssetType> = TEXT, ?library:Null<String> = null, ?ignoreMods:Null<Bool> = false):String
	{
		#if MODS_ALLOWED
		if (!ignoreMods)
		{
			var path:String = getModPath(file, library);

			if (FileSystem.exists(path)) {
				return path;
			}
		}
		#end

		return getPath(file, type, library);
	}

	@:deprecated("`Paths.file()` is deprecated. use 'Paths.getFile()' instead.")
	public static function file(file:String, ?type:Null<AssetType> = TEXT, ?library:String, ?ignoreMods:Null<Bool> = false):String
	{
		Debug.logWarn("`Paths.file()` is deprecated! use 'Paths.getFile()' instead.");
		return getFile(file, type, library, ignoreMods);
	}

	public static function getTxt(key:String, ?library:String, ?ignoreMods:Null<Bool> = false):String
	{
		if (key.endsWith('.txt')) {
			key = key.substring(0, key.lastIndexOf('.'));
		}

		return getFile('$key.txt', library, ignoreMods);
	}

	@:deprecated("`Paths.txt()` is deprecated. use 'Paths.getTxt()' instead.")
	public static function txt(key:String, ?library:String, ?ignoreMods:Null<Bool> = false):String
	{
		Debug.logWarn("`Paths.txt()` is deprecated! use 'Paths.getTxt()' instead.");
		return getTxt(key, library, ignoreMods);
	}

	public static function getXml(key:String, ?library:String, ?ignoreMods:Null<Bool> = false):String
	{
		if (key.endsWith('.xml')) {
			key = key.substring(0, key.lastIndexOf('.'));
		}

		return getFile('$key.xml', library, ignoreMods);
	}

	@:deprecated("`Paths.xml()` is deprecated. use 'Paths.getXml()' instead.")
	public static function xml(key:String, ?library:String, ?ignoreMods:Null<Bool> = false):String
	{
		Debug.logWarn("`Paths.xml()` is deprecated! use 'Paths.getXml()' instead.");
		return getXml(key, library, ignoreMods);
	}

	public static function getJson(key:String, ?library:String, ?ignoreMods:Null<Bool> = false):String
	{
		if (key.endsWith('.json')) {
			key = key.substring(0, key.lastIndexOf('.'));
		}

		return getFile('$key.json', library, ignoreMods);
	}

	@:deprecated("`Paths.json()` is deprecated. use 'Paths.getJson()' instead.")
	public static function json(key:String, ?library:String, ?ignoreMods:Null<Bool> = false):String
	{
		Debug.logWarn("`Paths.json()` is deprecated! use 'Paths.getJson()' instead.");
		return getJson(key, library, ignoreMods);
	}

	public static function getLua(key:String, ?library:String, ?ignoreMods:Null<Bool> = false):String
	{
		if (key.endsWith('.lua')) {
			key = key.substring(0, key.lastIndexOf('.'));
		}

		return getFile('$key.lua', library, ignoreMods);
	}

	@:deprecated("`Paths.lua()` is deprecated. use 'Paths.getLua()' instead.")
	public static function lua(key:String, ?library:String, ?ignoreMods:Null<Bool> = false):String
	{
		Debug.logWarn("`Paths.lua()` is deprecated! use 'Paths.getLua()' instead.");
		return getLua(key, library, ignoreMods);
	}

	public static function getSound(key:String, ?library:String, ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxSoundAsset
	{
		return returnSound('sounds', key, library, getId, ignoreMods);
	}

	@:deprecated("`Paths.sound()` is deprecated. use 'Paths.getSound()' instead.")
	public static function sound(key:String, ?library:String, ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxSoundAsset
	{
		Debug.logWarn("`Paths.sound()` is deprecated! use 'Paths.getSound()' instead.");
		return getSound(key, library, getId, ignoreMods);
	}

	public static function getSoundRandom(key:String, min:Int, max:Int, ?library:String, ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxSoundAsset
	{
		return getSound(key + FlxG.random.int(min, max), library, getId, ignoreMods);
	}

	@:deprecated("`Paths.soundRandom()` is deprecated. use 'Paths.getSoundRandom()' instead.")
	public static function soundRandom(key:String, min:Int, max:Int, ?library:String, ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxSoundAsset
	{
		Debug.logWarn("`Paths.soundRandom()` is deprecated! use 'Paths.getSoundRandom()' instead.");
		return getSoundRandom(key, min, max, library, getId, ignoreMods);
	}

	public static function getMusic(key:String, ?library:String, ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxSoundAsset
	{
		return returnSound('music', key, library, getId, ignoreMods);
	}

	@:deprecated("`Paths.music()` is deprecated. use 'Paths.getMusic()' instead.")
	public static function music(key:String, ?library:String, ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxSoundAsset
	{
		Debug.logWarn("`Paths.music()` is deprecated! use 'Paths.getMusic()' instead.");
		return getMusic(key, library, getId, ignoreMods);
	}

	public static function getInst(song:String, ?diffPath:String = '', ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxSoundAsset
	{
		var songPath:String = formatToSongPath(song);
		var path:String = returnSound(songPath + diffPath, 'Inst', songLibrary, true, ignoreMods);

		if (fileExists(path, SOUND)) {
			return returnSound(null, path, null, getId, ignoreMods);
		}

		return returnSound(songPath, 'Inst', songLibrary, getId, ignoreMods);
	}

	@:deprecated("`Paths.inst()` is deprecated. use 'Paths.getInst()' instead.")
	public static function inst(song:String, ?diffPath:String = '', ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxSoundAsset
	{
		Debug.logWarn("`Paths.inst()` is deprecated! use 'Paths.getInst()' instead.");
		return getInst(song, diffPath, getId, ignoreMods);
	}

	public static function getVoices(song:String, ?diffPath:String = '', ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxSoundAsset
	{
		var songPath:String = formatToSongPath(song);
		var path:String = returnSound(songPath + diffPath, 'Voices', songLibrary, true, ignoreMods);

		if (fileExists(path, SOUND)) {
			return returnSound(null, path, null, getId, ignoreMods);
		}

		return returnSound(songPath, 'Voices', songLibrary, getId, ignoreMods);
	}

	@:deprecated("`Paths.voices()` is deprecated. use 'Paths.getVoices()' instead.")
	public static function voices(song:String, ?diffPath:String = '', ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxSoundAsset
	{
		Debug.logWarn("`Paths.voices()` is deprecated! use 'Paths.getVoices()' instead.");
		return getVoices(song, diffPath, getId, ignoreMods);
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	public static function getImage(key:String, ?library:String, ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxGraphicAsset
	{
		return returnGraphic(key, library, getId, ignoreMods);
	}

	@:deprecated("`Paths.image()` is deprecated. use 'Paths.getImage()' instead.")
	public static function image(key:String, ?library:String = null, ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxGraphicAsset
	{
		Debug.logWarn("`Paths.image()` is deprecated! use 'Paths.getImage()' instead.");
		return getImage(key, library, getId, ignoreMods);
	}

	public static function returnGraphic(key:String, ?library:String, ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxGraphicAsset
	{
		if (key.endsWith('.png')) {
			key = key.substring(0, key.lastIndexOf('.'));
		}

		#if MODS_ALLOWED
		if (!ignoreMods)
		{
			var modKey:String = getModPath('images/$key.png', library);

			if (FileSystem.exists('$key.png')) {
				modKey = '$key.png';
			}

			if (FileSystem.exists(modKey))
			{
				if (getId) {
					return modKey;
				}

				if (!currentTrackedAssets.exists(modKey))
				{
					var newBitmap:BitmapData = BitmapData.fromFile(modKey);

					var newGraphic:FlxGraphic = FlxG.bitmap.add(newBitmap, false, modKey);
					newGraphic.persist = true;
					currentTrackedAssets.set(modKey, newGraphic);
				}

				localTrackedAssets.push(modKey);
				return currentTrackedAssets.get(modKey);
			}
		}
		#end

		var path:String = getPath('images/$key.png', IMAGE, library);

		if (OpenFlAssets.exists('$key.png', IMAGE)) {
			path = '$key.png';
		}

		if (getId) {
			return path;
		}

		if (OpenFlAssets.exists(path, IMAGE))
		{
			if (!currentTrackedAssets.exists(path))
			{
				var newBitmap:BitmapData = OpenFlAssets.getBitmapData(path);

				var newGraphic:FlxGraphic = FlxG.bitmap.add(newBitmap, false, path);
				newGraphic.persist = true;
				currentTrackedAssets.set(path, newGraphic);
			}

			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}

		if (!getId) {
			Debug.logWarn('Could not find a image asset with key "$key".');
		}

		return null;
	}

	public static function getVideo(key:String, ?library:String, ?ignoreMods:Null<Bool> = false):String
	{
		#if desktop
		for (i in VIDEO_EXT)
		{
			if (i != 'mp4')
			{
				var path:String = getFile('videos/$key.$i', BINARY, library, ignoreMods);

				if (fileExists(path, BINARY, true, ignoreMods)) {
					return path;
				}
			}
		}
		#end

		return getFile('videos/$key.mp4', BINARY, library, ignoreMods);
	}

	@:deprecated("`Paths.video()` is deprecated. use 'Paths.getVideo()' instead.")
	public static function video(key:String, ?library:String, ?ignoreMods:Null<Bool> = false):String
	{
		Debug.logWarn("`Paths.video()` is deprecated! use 'Paths.getVideo()' instead.");
		return getVideo(key, library, ignoreMods);
	}

	public static function getFont(key:String, ?library:String, ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):String
	{
		return getFile('fonts/$key', FONT, library, ignoreMods);
	}

	public static var cachedAtlasFrames:Map<Array<String>, FlxAtlasFrames> = [];

	public static function getSparrowAtlas(key:String, ?library:String, ?ignoreMods:Null<Bool> = false):FlxAtlasFrames
	{
		var imagePath:String = getImage(key, library, true, ignoreMods);
		var descPath:String = getXml('images/$key', library, ignoreMods);

		if (fileExists(imagePath, IMAGE, true, ignoreMods) && fileExists(descPath, TEXT, true, ignoreMods))
		{
			var array:Array<String> = [imagePath, descPath];

			if (!cachedAtlasFrames.exists(array))
			{
				if (OpenFlAssets.exists(descPath, TEXT)) {
					cachedAtlasFrames.set(array, FlxAtlasFrames.fromSparrow(getImage(key, null, false, ignoreMods), descPath));
				}
				else {
					cachedAtlasFrames.set(array, FlxAtlasFrames.fromSparrow(getImage(key, null, false, ignoreMods), getTextFromFile(descPath, ignoreMods)));
				}
			}

			return cachedAtlasFrames.get(array);
		}

		Debug.logWarn('Could not find a sparrow asset with key "$key".');
		return null;
	}

	public static function getPackerAtlas(key:String, ?library:String, ?ignoreMods:Null<Bool> = false):FlxAtlasFrames
	{
		var imagePath:String = getImage(key, library, true, ignoreMods);
		var descPath:String = getTxt('images/$key', library, ignoreMods);

		if (fileExists(imagePath, IMAGE, true, ignoreMods) && fileExists(descPath, TEXT, true, ignoreMods))
		{
			var array:Array<String> = [imagePath, descPath];

			if (!cachedAtlasFrames.exists(array))
			{
				if (OpenFlAssets.exists(descPath, TEXT)) {
					cachedAtlasFrames.set(array, FlxAtlasFrames.fromSpriteSheetPacker(getImage(key, null, false, ignoreMods), descPath));
				}
				else {
					cachedAtlasFrames.set(array, FlxAtlasFrames.fromSpriteSheetPacker(getImage(key, null, false, ignoreMods), getTextFromFile(descPath, ignoreMods)));
				}
			}

			return cachedAtlasFrames.get(array);
		}

		Debug.logWarn('Could not find a packer asset with key "$key".');
		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function returnSound(path:String, key:String, ?library:String, ?getId:Bool = false, ?ignoreMods:Null<Bool> = false):FlxSoundAsset
	{
		if (key.endsWith('.$SOUND_EXT') #if FEATURE_OGG || key.endsWith('.ogg') #end #if FEATURE_WAV || key.endsWith('.wav') #end) {
			key = key.substring(0, key.lastIndexOf('.'));
		}

		#if MODS_ALLOWED
		if (!ignoreMods)
		{
			var file:String = getModPath('$key.$SOUND_EXT', library);

			if (path != null && path.length > 0) {
				file = getModPath('$path/$key.$SOUND_EXT', library);
			}
			#if FEATURE_OGG
			var ogg:String = getModPath('$key.ogg', library);

			if (path != null && path.length > 0) {
				ogg = getModPath('$path/$key.ogg', library);
			}

			if (OptionData.loadingOggFiles && FileSystem.exists(ogg)) {
				file = ogg;
			}
			#end

			#if FEATURE_WAV
			var wav:String = getModPath('$key.wav', library);

			if (path != null && path.length > 0) {
				wav = getModPath('$path/$key.ogg', library);
			}

			if (OptionData.loadingWavFiles && FileSystem.exists(wav)) {
				file = wav;
			}
			#end

			if (FileSystem.exists('$key.$SOUND_EXT'))
				file = '$key.$SOUND_EXT';
			#if FEATURE_OGG
			if (OptionData.loadingOggFiles && FileSystem.exists('$key.ogg'))
				file = '$key.ogg';
			#end
			#if FEATURE_WAV
			if (OptionData.loadingWavFiles && FileSystem.exists('$key.wav'))
				file = '$key.wav';
			#end

			if (FileSystem.exists(file))
			{
				if (getId) {
					return file;
				}

				if (!currentTrackedSounds.exists(file)) {
					currentTrackedSounds.set(file, Sound.fromFile(file));
				}
		
				localTrackedAssets.push(key);
				return currentTrackedSounds.get(file);
			}
		}
		#end

		var gottenPath:String = getPath('$key.$SOUND_EXT', SOUND, library);

		if (path != null && path.length > 0) {
			gottenPath = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		}

		#if FEATURE_OGG
		var ogg:String = getPath('$key.ogg', SOUND, library);

		if (path != null && path.length > 0) {
			ogg = getPath('$path/$key.ogg', SOUND, library);
		}

		if (OptionData.loadingOggFiles && OpenFlAssets.exists(ogg, SOUND)) {
			gottenPath = ogg;
		}
		#end

		#if FEATURE_WAV
		var wav:String = getPath('$key.wav', SOUND, library);

		if (path != null && path.length > 0) {
			wav = getPath('$path/$key.wav', SOUND, library);
		}

		if (OptionData.loadingWavFiles && OpenFlAssets.exists(wav, SOUND)) {
			gottenPath = wav;
		}
		#end

		if (OpenFlAssets.exists('$key.$SOUND_EXT', SOUND))
			gottenPath = '$key.$SOUND_EXT';
		#if FEATURE_OGG
		if (OptionData.loadingOggFiles && OpenFlAssets.exists('$key.ogg', SOUND))
			gottenPath = '$key.ogg';
		#end
		#if FEATURE_WAV
		if (OptionData.loadingWavFiles && OpenFlAssets.exists('$key.wav', SOUND))
			gottenPath = '$key.wav';
		#end

		if (getId) {
			return gottenPath;
		}

		if (OpenFlAssets.exists(gottenPath, SOUND))
		{
			if (!currentTrackedSounds.exists(gottenPath))
			{ #if (MP3_ALLOWED && cpp)
				if (gottenPath.endsWith('.$SOUND_EXT'))
					currentTrackedSounds.set(gottenPath, Sound.fromMP3(OpenFlAssets.getBytes(gottenPath)));
				else #end
					currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound(gottenPath));
			}

			localTrackedAssets.push(gottenPath);
			return currentTrackedSounds.get(gottenPath);
		}

		if (!getId) {
			Debug.logWarn('Could not find a sound asset with key "$gottenPath".');
		}

		return null;
	}

	public static function formatToSongPath(path:String):String
	{
		var invalidChars:EReg = ~/[~&\\;:<>#]/;
		var hideChars:EReg = ~/[.,'"%?!]/;

		var path:String = invalidChars.split(path.replace(' ', '-')).join('-');
		return hideChars.split(path).join('').toLowerCase();
	}

	public static function fileExists(key:String, type:Null<AssetType> = TEXT, ?library:String, ?absolute:Bool = false, ?ignoreMods:Null<Bool> = false):Bool
	{
		if (absolute)
		{
			#if MODS_ALLOWED
			if (!ignoreMods && FileSystem.exists(key)) {
				return true;
			}
			#end

			if (OpenFlAssets.exists(key, type)) {
				return true;
			}
		}

		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(getModPath(key, library))) {
			return true;
		}
		#end

		if (OpenFlAssets.exists(getPath(key, type, library), type)) {
			return true;
		}

		return false;
	}

	public static function getTextFromFile(key:String, ?library:String = null, ?ignoreMods:Null<Bool> = false):String
	{
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(key)) {
			return File.getContent(key);
		}
		#end

		if (OpenFlAssets.exists(key)) {
			return OpenFlAssets.getText(key);
		}

		#if MODS_ALLOWED
		if (!ignoreMods)
		{
			var modpath:String = getModPath(key, library);

			if (FileSystem.exists(modpath)) {
				return File.getContent(modpath);
			}
		}
		#end

		return OpenFlAssets.getText(getPath(key, TEXT, library));
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

	public static function getModPath(file:String, ?library:Null<String> = null):String
	{
		if (library != null && library.length > 0 && library != 'preload' && library != 'default')
		{
			var modLibraryPath:String = modFolders(library + '/' + file);

			if (FileSystem.exists(modLibraryPath)) {
				return modLibraryPath;
			}
		}

		return modFolders(file);
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
			var list:Array<String> = CoolUtil.listFromString(File.getContent(path));

			for (i in list)
			{
				var dat:Array<String> = i.split('|');
	
				if (dat[1] == '1')
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
								var global:Bool = Reflect.getProperty(stuff, 'runsGlobally');
							
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