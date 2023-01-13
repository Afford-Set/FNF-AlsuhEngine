package;

#if sys
import sys.io.File;
import haxe.io.Path;
import sys.FileSystem;
#end

import haxe.Json;
import flixel.FlxG;
import lime.utils.Assets;
import flash.media.Sound;
import openfl.system.System;
import openfl.utils.AssetType;
import haxe.format.JsonParser;
import openfl.display.BitmapData;
import flixel.graphics.FlxGraphic;
import openfl.utils.Assets as OpenFlAssets;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

class Paths
{
	public static var SOUND_EXT:String = #if web 'mp3' #else 'ogg' #end;
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
		'songs',
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
		'assets/shared/music/tea-time.$SOUND_EXT',
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

	public static function clearStoredMemory(?cleanUnused:Bool = false):Void
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
			if (!localTrackedAssets.contains(key) && !dumpExclusions.contains(key) && key != null)
			{
				Assets.cache.clear(key);
				currentTrackedSounds.remove(key);
			}
		}

		localTrackedAssets = [];
		#if !html5 openfl.Assets.cache.clear("songs"); #end
	}

	public static var currentLevel:String;

	public static function setCurrentLevel(name:String):Void
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null):String
	{
		if (library != null) {
			return getLibraryPath(file, library);
		}

		if (currentLevel != null)
		{
			var levelPath:String = '';

			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(file, currentLevel);

				if (OpenFlAssets.exists(levelPath, type)) {
					return levelPath;
				}
			}

			levelPath = getLibraryPathForce(file, "shared");

			if (OpenFlAssets.exists(levelPath, type)) {
				return levelPath;
			}
		}

		return getPreloadPath(file);
	}

	public static function getLibraryPath(file:String, library = "preload"):String
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	public static function getLibraryPathForce(file:String, library:String):String
	{
		return '$library:assets/$library/$file';
	}

	public static function getPreloadPath(file:String = ''):String
	{
		return 'assets/$file';
	}

	public static function getFile(file:String, type:AssetType = TEXT, ?library:String):String
	{
		#if MODS_ALLOWED
		var path:String = modFolders(file);

		if (FileSystem.exists(path)) {
			return path;
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
		#if MODS_ALLOWED
		var path:String = modsTxt(key);

		if (FileSystem.exists(path)) {
			return path;
		}
		#end

		return getPath('data/$key.txt', TEXT, library);
	}

	@:deprecated("`Paths.txt()` is deprecated, use 'Paths.getTxt()' instead")
	public static function txt(key:String, ?library:String):String
	{
		Debug.logWarn("`Paths.txt()` is deprecated! use 'Paths.getTxt()' instead");

		return getTxt(key, library);
	}

	public static function getXml(key:String, ?library:String):String
	{
		#if MODS_ALLOWED
		var path:String = modsXml(key);

		if (FileSystem.exists(path)) {
			return path;
		}
		#end

		return getPath('data/$key.xml', TEXT, library);
	}

	@:deprecated("`Paths.xml()` is deprecated, use 'Paths.getXml()' instead")
	public static function xml(key:String, ?library:String):String
	{
		Debug.logWarn("`Paths.xml()` is deprecated! use 'Paths.getXml()' instead");

		return getXml(key, library);
	}

	public static function getJson(key:String, ?library:String):String
	{
		#if MODS_ALLOWED
		var path:String = modsJson(key);

		if (FileSystem.exists(path)) {
			return path;
		}
		#end

		return getPath('data/$key.json', TEXT, library);
	}

	@:deprecated("`Paths.json()` is deprecated, use 'Paths.getJson()' instead")
	public static function json(key:String, ?library:String):String
	{
		Debug.logWarn("`Paths.json()` is deprecated! use 'Paths.getJson()' instead");

		return getJson(key, library);
	}

	public static function getLua(key:String, ?library:String):String
	{
		#if MODS_ALLOWED
		var path:String = modsLua(key);

		if (FileSystem.exists(path)) {
			return path;
		}
		#end

		return getPath('$key.lua', TEXT, library);
	}

	@:deprecated("`Paths.lua()` is deprecated, use 'Paths.getLua()' instead")
	public static function lua(key:String, ?library:String):String
	{
		Debug.logWarn("`Paths.lua()` is deprecated! use 'Paths.getLua()' instead");

		return getLua(key, library);
	}

	public static function getSound(key:String, ?library:String):Sound
	{
		return returnSound('sounds', key, library);
	}

	@:deprecated("`Paths.sound()` is deprecated, use 'Paths.getSound()' instead")
	public static function sound(key:String, ?library:String):Sound
	{
		Debug.logWarn("`Paths.sound()` is deprecated! use 'Paths.getSound()' instead");

		return getSound(key, library);
	}

	public static function getSoundRandom(key:String, min:Int, max:Int, ?library:String):Sound
	{
		return getSound(key + FlxG.random.int(min, max), library);
	}

	@:deprecated("`Paths.soundRandom()` is deprecated, use 'Paths.getSoundRandom()' instead")
	public static function soundRandom(key:String, min:Int, max:Int, ?library:String):Sound
	{
		Debug.logWarn("`Paths.soundRandom()` is deprecated! use 'Paths.getSoundRandom()' instead");

		return getSoundRandom(key, min, max, library);
	}

	public static function getMusic(key:String, ?library:String):Sound
	{
		return returnSound('music', key, library);
	}

	@:deprecated("`Paths.music()` is deprecated, use 'Paths.getMusic()' instead")
	public static function music(key:String, ?library:String):Sound
	{
		Debug.logWarn("`Paths.music()` is deprecated! use 'Paths.getMusic()' instead");

		return getMusic(key, library);
	}

	public static function getInst(song:String, ?difficulty:String = '', ?string:Bool = false):Any
	{
		var path:String = 'songs/' + song.toLowerCase() + '/Inst' + '.' + SOUND_EXT;
		var pathAlt:String = 'songs/' + song.toLowerCase() + '/Inst' + difficulty + '.' + SOUND_EXT;

		if (string)
		{
			if (fileExists(pathAlt, SOUND) || fileExists(pathAlt, MUSIC))
			{
				#if MODS_ALLOWED
				if (FileSystem.exists(modFolders(pathAlt))) {
					return modFolders(pathAlt);
				}
				#end

				return #if !MODS_ALLOWED 'songs:' + #end 'assets/' + pathAlt;
			}

			if (Assets.exists('songs:assets/' + pathAlt)) {
				return #if !MODS_ALLOWED 'songs:' + #end 'assets/' + pathAlt;
			}

			return #if !MODS_ALLOWED 'songs:' + #end 'assets/' + path;
		}

		if (fileExists(pathAlt, SOUND) || fileExists(pathAlt, MUSIC)) {
			return returnSound('songs', song.toLowerCase() + '/Inst' + difficulty);
		}

		return returnSound('songs', song.toLowerCase() + '/Inst');
	}

	@:deprecated("`Paths.inst()` is deprecated, use 'Paths.getInst()' instead")
	public static function inst(song:String, ?difficulty:String = '', ?string:Bool = false):Any
	{
		Debug.logWarn("`Paths.inst()` is deprecated! use 'Paths.getInst()' instead");

		return getInst(song, difficulty, string);
	}

	public static function getVoices(song:String, ?difficulty:String = '', ?string:Bool = false):Any
	{
		var path:String = 'songs/' + song.toLowerCase() + '/Voices' + '.' + SOUND_EXT;
		var pathAlt:String = 'songs/' + song.toLowerCase() + '/Voices' + difficulty + '.' + SOUND_EXT;

		if (string)
		{
			if (fileExists(pathAlt, SOUND) || fileExists(pathAlt, MUSIC))
			{
				#if MODS_ALLOWED
				if (FileSystem.exists(modFolders(pathAlt))) {
					return modFolders(pathAlt);
				}
				#end

				return #if !MODS_ALLOWED 'songs:' + #end 'assets/' + pathAlt;
			}

			if (Assets.exists('songs:assets/' + pathAlt)) {
				return #if !MODS_ALLOWED 'songs:' + #end 'assets/' + pathAlt;
			}

			return #if !MODS_ALLOWED 'songs:' + #end 'assets/' + path;
		}

		if (fileExists(pathAlt, SOUND) || fileExists(pathAlt, MUSIC)) {
			return returnSound('songs', song.toLowerCase() + '/Voices' + difficulty);
		}

		return returnSound('songs', song.toLowerCase() + '/Voices');
	}

	@:deprecated("`Paths.voices()` is deprecated, use 'Paths.getVoices()' instead")
	public static function voices(song:String, ?difficulty:String = '', ?string:Bool = false):Any
	{
		Debug.logWarn("`Paths.voices()` is deprecated! use 'Paths.getVoices()' instead");

		return getVoices(song, difficulty, string);
	}

	public static function getImage(key:String, ?library:String):FlxGraphic
	{
		return returnGraphic(key, library);
	}

	@:deprecated("`Paths.image()` is deprecated, use 'Paths.getImage()' instead")
	public static function image(key:String, ?library:String):FlxGraphic
	{
		Debug.logWarn("`Paths.image()` is deprecated! use 'Paths.getImage()' instead");

		return getImage(key, library);
	}

	public static function getVideo(key:String, ?library:String, ?blyad:Bool = false):String
	{
		#if MODS_ALLOWED
		var file:String = modsVideo(key);

		if (FileSystem.exists(file)) {
			return file;
		}
		#end

		var shit:String = getPath('videos/$key.$VIDEO_EXT', BINARY, library);
		if (blyad) return shit;

		var replacedPath:String = shit.replace(currentLevel + ':', '');
		replacedPath = replacedPath.replace(library + ':', '');
		return replacedPath;
	}

	@:deprecated("`Paths.video()` is deprecated, use 'Paths.getVideo()' instead")
	public static function video(key:String, ?library:String):String
	{
		Debug.logWarn("`Paths.video()` is deprecated! use 'Paths.getVideo()' instead");

		return getVideo(key, library);
	}

	public static function getWebm(key:String, ?library:String, ?blyad:Bool = false):String
	{
		#if MODS_ALLOWED
		var file:String = modsWebm(key);

		if (FileSystem.exists(file)) {
			return file;
		}
		#end

		var shit:String = getPath('videos/$key.webm', BINARY, library);
		if (blyad) return shit;

		var replacedPath:String = shit.replace(currentLevel + ':', '');
		replacedPath = replacedPath.replace(library + ':', '');
		return replacedPath;
	}

	@:deprecated("`Paths.webm()` is deprecated, use 'Paths.getWebm()' instead")
	public static function webm(key:String, ?library:String):String
	{
		Debug.logWarn("`Paths.webm()` is deprecated! use 'Paths.getWebm()' instead");

		return getWebm(key, library);
	}

	public static function getWebmSound(key:String, ?library:String):Sound
	{
		return returnSound('videos', key, library);
	}

	@:deprecated("`Paths.webmSound()` is deprecated, use 'Paths.getWebmSound()' instead")
	public static function webmSound(key:String, ?library:String):Sound
	{
		Debug.logWarn("`Paths.webmSound()` is deprecated! use 'Paths.getWebmSound()' instead");

		return getWebmSound('videos', library);
	}

	public static function getTextFromFile(key:String, ?ignoreMods:Bool = false):String
	{
		#if sys
		#if MODS_ALLOWED
		if (!ignoreMods && FileSystem.exists(modFolders(key))) {
			return File.getContent(modFolders(key));
		}
		#end

		if (FileSystem.exists(getPreloadPath(key))) {
			return File.getContent(getPreloadPath(key));
		}

		if (currentLevel != null)
		{
			var levelPath:String = '';
	
			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(key, currentLevel);
	
				if (FileSystem.exists(levelPath)) {
					return File.getContent(levelPath);
				}
			}

			levelPath = getLibraryPathForce(key, 'shared');
	
			if (FileSystem.exists(levelPath)) {
				return File.getContent(levelPath);
			}
		}
		#end

		return Assets.getText(getPath(key, TEXT));
	}

	public static function getFont(key:String, ?library:String):String
	{
		#if MODS_ALLOWED
		var file:String = modsFont(key);

		if (FileSystem.exists(file)) {
			return file;
		}
		#end

		return getPath('fonts/$key', FONT, library);
	}

	@:deprecated("`Paths.font()` is deprecated, use 'Paths.getFont()' instead")
	public static function font(key:String, ?library:String):String
	{
		Debug.logWarn("`Paths.font()` is deprecated! use 'Paths.getFont()' instead");

		return getFont(key, library);
	}

	public static function getSparrowAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var xmlExists:Bool = false;

		if (FileSystem.exists(modsXml(key))) {
			xmlExists = true;
		}

		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : getImage(key, library)), (xmlExists ? File.getContent(modsXml(key)) : getFile('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(getImage(key, library), getFile('images/$key.xml', library));
		#end
	}

	public static function getPackerAtlas(key:String, ?library:String):FlxAtlasFrames
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = returnGraphic(key);
		var txtExists:Bool = false;

		if (FileSystem.exists(modsTxt(key))) {
			txtExists = true;
		}

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : getImage(key, library)), (txtExists ? File.getContent(modsTxt(key)) : getFile('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(getImage(key, library), getFile('images/$key.txt', library));
		#end
	}

	public static var currentTrackedAssets:Map<String, FlxGraphic> = [];

	public static function returnGraphic(key:String, ?library:String):FlxGraphic
	{
		#if MODS_ALLOWED
		var modKey:String = modsImages(key);

		if (FileSystem.exists(modKey))
		{
			if (!currentTrackedAssets.exists(modKey))
			{
				var newBitmap:BitmapData = BitmapData.fromFile(modKey);
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(newBitmap, false, modKey);

				newGraphic.persist = true;
				currentTrackedAssets.set(modKey, newGraphic);
			}

			localTrackedAssets.push(modKey);
			return currentTrackedAssets.get(modKey);
		}
		#end

		var path:String = getPath('images/$key.png', IMAGE, library);

		if (OpenFlAssets.exists(path, IMAGE))
		{
			if (!currentTrackedAssets.exists(path))
			{
				var newGraphic:FlxGraphic = FlxG.bitmap.add(path, false, path);
				newGraphic.persist = true;

				currentTrackedAssets.set(path, newGraphic);
			}

			localTrackedAssets.push(path);
			return currentTrackedAssets.get(path);
		}

		return null;
	}

	public static var currentTrackedSounds:Map<String, Sound> = [];

	public static function returnSound(path:String, key:String, ?library:String):Sound
	{
		#if MODS_ALLOWED
		var file:String = modsSounds(path, key);

		if (FileSystem.exists(file))
		{
			if (!currentTrackedSounds.exists(file)) {
				currentTrackedSounds.set(file, Sound.fromFile(file));
			}

			localTrackedAssets.push(key);
			return currentTrackedSounds.get(file);
		}
		#end

		var gottenPath:String = getPath('$path/$key.$SOUND_EXT', SOUND, library);
		gottenPath = gottenPath.substring(gottenPath.indexOf(':') + 1, gottenPath.length);

		if (!currentTrackedSounds.exists(gottenPath))
		{
			#if MODS_ALLOWED
			currentTrackedSounds.set(gottenPath, Sound.fromFile('./' + gottenPath));
			#else
			currentTrackedSounds.set(gottenPath, OpenFlAssets.getSound((path == 'songs' ? 'songs:' : '') + getPath('$path/$key.$SOUND_EXT', SOUND, library)));
			#end
		}

		localTrackedAssets.push(gottenPath);
		return currentTrackedSounds.get(gottenPath);
	}

	public static function formatToSongPath(path:String):String
	{
		var invalidChars:EReg = ~/[~&\\;:<>#]/;
		var hideChars:EReg = ~/[.,'"%?!]/;

		var path:String = invalidChars.split(path.replace(' ', '-')).join("-");
		return hideChars.split(path).join("").toLowerCase();
	}

	public static function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false):Bool
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(mods(currentModDirectory + '/' + key)) || FileSystem.exists(mods(key))) {
			return true;
		}
		#end
		
		if (OpenFlAssets.exists(Paths.getPath(key, type))) {
			return true;
		}

		return false;
	}

	#if MODS_ALLOWED
	public static function mods(key:String = ''):String
	{
		return 'mods/' + key;
	}

	public static function modsFont(key:String):String
	{
		return modFolders('fonts/' + key);
	}

	public static function modsJson(key:String):String
	{
		return modFolders('data/' + key + '.json');
	}

	public static function modsLua(key:String):String
	{
		return modFolders(key + '.lua');
	}

	public static function modsVideo(key:String):String
	{
		return modFolders('videos/' + key + '.' + VIDEO_EXT);
	}

	public static function modsWebm(key:String):String
	{
		return modFolders('videos/' + key + '.webm');
	}

	public static function modsSounds(path:String, key:String):String
	{
		return modFolders(path + '/' + key + '.' + SOUND_EXT);
	}

	public static function modsImages(key:String):String
	{
		return modFolders('images/' + key + '.png');
	}

	public static function modsXml(key:String):String
	{
		return modFolders('images/' + key + '.xml');
	}

	public static function modsTxt(key:String):String 
	{
		return modFolders('images/' + key + '.txt');
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
			var list:Array<String> = CoolUtil.coolTextFile(path);

			for (i in list)
			{
				var dat = i.split("|");
	
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

				if (sys.FileSystem.isDirectory(path) && !ignoreModFolders.contains(folder) && !list.contains(folder)) {
					list.push(folder);
				}
			}
		}
	
		return list;
	}
	#end
}