package;

import flixel.addons.display.FlxRuntimeShader;
import JudgmentManager;
import Cache.AssetPreload;

import Song;
import Note.EventNote;
import Section.SwagSection;
import Stage.StageFile;
import shaders.Shaders;
import JudgmentManager;
import hud.*;
import playfields.*;
import modchart.*;
import scripts.*;
import scripts.FunkinLua;
import editors.*;
import flixel.*;
import flixel.util.*;
import flixel.math.*;
import flixel.tweens.*;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.text.FlxText;
import flixel.ui.FlxBar;
import haxe.Json;
import lime.media.openal.AL;
import lime.media.openal.ALFilter;
import lime.media.openal.ALEffect;
import openfl.events.KeyboardEvent;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;

#if sys
import sys.FileSystem;
import sys.io.File;
#end

#if discord_rpc
import Discord.DiscordClient;
#end
#if VIDEOS_ALLOWED 
#if (hxCodec >= "3.0.0")
import video.VideoHandler;
import video.VideoSprite;
import lime.app.Event;
#elseif (hxCodec >= "2.6.1") import hxcodec.VideoHandler as VideoHandler;
#elseif (hxCodec == "2.6.0") import VideoHandler as VideoHandler;
#else import vlc.VideoHandler; #end
#end

using StringTools;

/*
okay SO im gonna explain how these work

All speed changes are stored in an array, .sort()'d by the time
if changes[0].songTime is above conductor.songposition then 
	- it'll remove the first element of changes
	- it'll store the position, songTime and speed of the change somewhere
	- and then it'll songVisualPos = event.position + getVisPos(conductor.songPosition - event.songTime, songSpeed * event.speed)

all notes will also store their visualPos in a variable when creation and then when moving notes it's just
	note.y = note.visualPos - event.position
:3

EDIT: not EXACTLY how it works but its a good enough summary
*/
typedef SpeedEvent =
{
	position:Float, // the y position when the change happens (modManager.getVisPos(songTime))
	songTime:Float, // the song position (conductor.songTime) when the changer happens
	speed:Float // speed mult after the change
}

// Etterna
class Wife3
{
	public static var missWeight:Float = -5.5;
	public static var mineWeight:Float = -7;
	public static var holdDropWeight:Float = -4.5;
	public static var a1 = 0.254829592;
	public static var a2 = -0.284496736;
	public static var a3 = 1.421413741;
	public static var a4 = -1.453152027;
	public static var a5 = 1.061405429;
	public static var p = 0.3275911;

	public static function werwerwerwerf(x:Float):Float
	{
		var sign = 1;
		if (x < 0)sign = -1;
		x = Math.abs(x);
		var t = 1 / (1+p*x);
		var y = 1 - (((((a5*t+a4)*t)+a3)*t+a2)*t+a1)*t*Math.exp(-x*x);
		return sign*y;
	}

	public static var timeScale:Float = 1;
	public static function getAcc(noteDiff:Float, ?ts:Float):Float{ // https://github.com/etternagame/etterna/blob/0a7bd768cffd6f39a3d84d76964097e43011ce33/src/RageUtil/Utils/RageUtil.h
		if(ts==null)ts=timeScale;
		if(ts>1)ts=1;
		var jPow:Float = 0.75;
		var maxPoints:Float = 2.0;
		var ridic:Float = 5 * ts;
		var shit_weight:Float = 200;
		var absDiff = Math.abs(noteDiff);
		var zero:Float = 65 * Math.pow(ts, jPow);
		var dev:Float = 22.7 * Math.pow(ts, jPow);

		if(absDiff<=ridic){
			return maxPoints;
		} else if(absDiff<=zero){
			return maxPoints*werwerwerwerf((zero-absDiff)/dev);
		}else if(absDiff<=shit_weight){
			return (absDiff-zero)*missWeight/(shit_weight-zero);
		}
		return missWeight;
	}


}
class PlayState extends MusicBeatState
{
	var sndFilter:ALFilter = AL.createFilter();
    var sndEffect:ALEffect = AL.createEffect();

	public var showDebugTraces:Bool = #if debug true #else Main.showDebugTraces #end;

	var speedChanges:Array<SpeedEvent> = [];
	public var currentSV:SpeedEvent = {position: 0, songTime:0, speed: 1};
	public var judgeManager:JudgmentManager;

	var notefields:NotefieldManager = new NotefieldManager();
	public var modManager:ModManager; // andromeda modcharts :D

	/*
	public static var STRUM_X = 42;
	public static var STRUM_X_MIDDLESCROLL = -278;

	public var spawnTime:Float = 2000;
	*/
	public static var arrowSkinbf:String = null;
	public static var arrowSkindad:String = null;

	public var gameFont:String = 'Normal Text.ttf';
	public var gameFontBold:String = 'Bold Normal Text.ttf';

	public var stats:Stats = new Stats();
	public var noteHits:Array<Float> = [];
	public var nps:Int = 0;
	public var ratingStuff:Array<Array<Dynamic>> = Highscore.grades.get(ClientPrefs.gradeSet);
	
	public var hud:BaseHUD;
	// public var scoreTxt:FlxText = new FlxText(); // just so psych mods n shit dont error
	public var botplayTxt:FlxText;
	var subtitles:Null<SubtitleDisplay>;

	public var modchartTweens:Map<String, FlxTween> = new Map<String, FlxTween>();
	public var modchartSprites:Map<String, ModchartSprite> = new Map<String, ModchartSprite>();
	public var modchartTimers:Map<String, FlxTimer> = new Map<String, FlxTimer>();
	public var modchartSounds:Map<String, FlxSound> = new Map<String, FlxSound>();
	public var modchartTexts:Map<String, ModchartText> = new Map<String, ModchartText>();
	public var modchartSaves:Map<String, FlxSave> = new Map<String, FlxSave>();
	public var modchartObjects:Map<String, FlxSprite> = new Map<String, FlxSprite>();

	public var boyfriendMap:Map<String, Character> = new Map();
	public var extraMap:Map<String, Character> = new Map();
	public var dadMap:Map<String, Character> = new Map();
	public var gfMap:Map<String, Character> = new Map();
	public var variables:Map<String, Dynamic> = new Map();

	public var BF_X:Float = 770;
	public var BF_Y:Float = 100;
	public var DAD_X:Float = 100;
	public var DAD_Y:Float = 100;
	public var GF_X:Float = 400;
	public var GF_Y:Float = 130;

	public var boyfriendGroup:FlxSpriteGroup;
	public var dadGroup:FlxSpriteGroup;
	public var gfGroup:FlxSpriteGroup;

	public static var curStage:String = '';
	public static var SONG:SwagSong = null;
	public static var isStoryMode:Bool = false;
	public static var storyWeek:Int = 0;
	public static var storyPlaylist:Array<String> = [];
	public static var difficulty:Int = 1; // for psych mod shit
	public static var difficultyName:String = ''; // for psych mod shit
	public static var arrowSkin:String = '';
	public static var splashSkin:String = '';

	public var metadata:SongCreditdata; // metadata for the songs (artist, etc)

	public var tracks:Array<FlxSound> = [];
	public var vocals:FlxSound;
	public var inst:FlxSound;

	public var dad:Character = null;
	public var gf:Character = null;
	public var boyfriend:Character = null;

	public var focusedChar:Character;
	public var gfSpeed:Int = 1;

	public var notes = new FlxTypedGroup<Note>();
	public var unspawnNotes:Array<Note> = [];
	public var allNotes:Array<Note> = []; // all notes

	public var eventNotes:Array<EventNote> = [];
	 
	public var strumLineNotes = new FlxTypedGroup<StrumNote>();
	public var opponentStrums = new FlxTypedGroup<StrumNote>();
	public var playerStrums = new FlxTypedGroup<StrumNote>();

	public var playerField:PlayField;
	public var dadField:PlayField;

	public var playfields = new FlxTypedGroup<PlayField>();

	public var grpNoteSplashes = new FlxTypedGroup<NoteSplash>();
	
	////

	public var showRating:Bool = true;
	public var showCombo:Bool = false;
	public var showComboNum:Bool = true;
	
	public var ratingTxtGroup = new FlxTypedGroup<RatingSprite>();
	public var comboNumGroup = new FlxTypedGroup<RatingSprite>();
	public var comboNumTxt = new FlxTypedGroup<RatingText>();
	public var timingTxt:FlxText;

	public var displayedHealth(default, set):Float = 1;
	function set_displayedHealth(value:Float){
		healthBar.value = value;
		if (ClientPrefs.etternaHUD == 'ITG')
			healthBar2.value = value;
		displayedHealth = value;

		return value;
	}
	public var health(default, set):Float = 1;
	public var maxHealth:Float = 2;
	function set_health(value:Float){
		health = value > maxHealth ? maxHealth : value;
		displayedHealth = health;

		return health;
	}

	@:isVar
	public var songScore(get, set):Int = 0;
	@:isVar
	public var totalPlayed(get, set):Float = 0;
	@:isVar
	public var totalNotesHit(get, set):Float = 0.0;
	@:isVar
	public var combo(get, set):Int = 0;
	@:isVar
	public var cbCombo(get, set):Int = 0;
	@:isVar
	public var ratingName(get, set):String = '?';
	@:isVar
	public var ratingPercent(get, set):Float;
	@:isVar
	public var ratingFC(get, set):String;

	public inline function get_songScore()return stats.score;
	public inline function get_totalPlayed()return stats.totalPlayed;
	public inline function get_totalNotesHit()return stats.totalNotesHit;
	public inline function get_combo()return stats.combo;
	public inline function get_cbCombo()return stats.cbCombo;
	public inline function get_ratingName()return stats.grade;
	public inline function get_ratingPercent()return stats.ratingPercent;
	public inline function get_ratingFC()return stats.clearType;

	public inline function set_songScore(val:Int)return stats.score = val;
	public inline function set_totalPlayed(val:Float)return stats.totalPlayed = val;
	public inline function set_totalNotesHit(val:Float)return stats.totalNotesHit = val;
	public inline function set_combo(val:Int)return stats.combo = val;
	public inline function set_cbCombo(val:Int)return stats.cbCombo = val;
	public inline function set_ratingName(val:String)return stats.grade = val;
	public inline function set_ratingPercent(val:Float)return stats.ratingPercent = val;
	public inline function set_ratingFC(val:String)return stats.clearType = val;

	private var generatedMusic:Bool = false;
	public var endingSong:Bool = false;
	public var startingSong:Bool = false;
	public static var changedDifficulty:Bool = false;
	public static var chartingMode:Bool = false;

	//Gameplay settings
	var midScroll = false;
	
	public var healthGain:Float = 1;
	public var healthLoss:Float = 1;
	public var playOpponent:Bool = false;
	public var opponentHPDrain:Float = 0.0;
	public var healthDrain:Float = 0.0;

	public var instakillOnMiss:Bool = false;
	public var cpuControlled(default, set) = false;

	public var playbackRate:Float = 1;

	public var songSpeedTween:FlxTween;
	public var songSpeed(default, set):Float = 1;
	public var songSpeedType:String = "multiplicative";
	public var noteKillOffset:Float = 350;

	function set_cpuControlled(value){
		cpuControlled = value;

		setOnScripts('botPlay', value);

		/// oughhh
		for (playfield in playfields.members){
			if (playfield.isPlayer)
				playfield.autoPlayed = cpuControlled; 
		}

		return value;
	}
	public var saveScore:Bool = true; // whether to save the score. modcharted songs should set this to false if disableModcharts is true
	
	public var disableModcharts:Bool = false;
	public var practiceMode:Bool = false;
	public var perfectMode:Bool = false;
	public var instaRespawn:Bool = false;

	public var healthBar:FNFHealthBar;
	public var healthBarBG:FlxSprite;

	public var healthBar2:FNFHealthBar;
	public var healthBarBG2:FlxSprite;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var camGame:FlxCamera;
	public var camVideo:FlxCamera;
	public var camStageUnderlay:FlxCamera; // retarded
	public var camHUD:FlxCamera;
	public var camOverlay:FlxCamera; // shit that should go above all else and not get affected by camHUD changes, but still below camOther (pause menu, etc)
	public var camOther:FlxCamera;

	public var overlayBG:FlxSprite;
	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	private static var prevCamFollow:Null<FlxPoint> = null;
	private static var prevCamFollowPos:Null<FlxObject> = null;

	public var camZooming:Bool = false;
	public var camZoomingMult:Float = 1;
	public var camZoomingDecay:Float = 1;

	public var cameraSpeed:Float = 1;
	public var defaultCamZoom:Float = 1;

	public var sectionCamera = new FlxPoint(); // Default camera focus point
	public var customCamera = new FlxPoint(); // Used for the 'Camera Follow Pos' event
	public var cameraPoints:Array<FlxPoint>;

	// how big to stretch the pixel art assets
	public static var daPixelZoom:Float = 6;

	public function addCameraPoint(point:FlxPoint){
		cameraPoints.remove(point);
		cameraPoints.push(point);
	}

	public var stage:Stage;
	var stageData:StageFile;

	//public var songScore:Int = 0;
	public var songHits:Int = 0;
	public var songMisses:Int = 0;

	public var songName:String = "";
	public var songHighscore:Int = 0;
	public var songLength:Float = 0;

	var songPercent:Float = 0;

	public static var campaignScore:Int = 0;
	public static var campaignMisses:Int = 0;
	public static var seenCutscene:Bool = false;
	public static var deathCounter:Int = 0;

	private var singAnimations:Array<String> = ['singLEFT', 'singDOWN', 'singUP', 'singRIGHT'];

	public var inCutscene:Bool = false;
	public var skipCountdown:Bool = false;

	public var boyfriendCameraOffset:Array<Float> = null;
	public var opponentCameraOffset:Array<Float> = null;
	public var girlfriendCameraOffset:Array<Float> = null;

	#if discord_rpc
	// Discord RPC variables
	var detailsText:String = "";
	var detailsPausedText:String = "";
	#end

	//Achievement shit
	var keysPressed:Array<Bool> = [];
	var boyfriendIdleTime:Float = 0.0;
	var boyfriendIdled:Bool = false;

	// Script shit
	public static var instance:PlayState;
	public var funkyScripts:Array<FunkinScript> = [];
	public var hscriptArray:Array<FunkinHScript> = [];
	#if LUA_ALLOWED
	public var luaArray:Array<FunkinLua> = [];
	#end

	public var noteskinScripts:Map<String, FunkinHScript> = []; // custom noteskins for scriptVer '1'
	public var notetypeScripts:Map<String, FunkinHScript> = []; // custom notetypes for scriptVer '1'
	public var eventScripts:Map<String, FunkinHScript> = []; // custom events for scriptVer '1'

	private var luaDebugGroup:FlxTypedGroup<DebugLuaText>;
	public var introSoundsSuffix:String = '';

	// Debug buttons
	private var debugKeysChart:Array<FlxKey>;
	private var debugKeysBotplay:Array<FlxKey>;
	private var debugKeysCharacter:Array<FlxKey>;

	// Less laggy controls
	private var keysArray:Array<Dynamic>;
	private var controlArray:Array<String>;

	// Loading
	var shitToLoad:Array<AssetPreload> = [];
	var finishedCreating = false;

	// MP4 vids var
	#if (VIDEOS_ALLOWED)
	public var videoSprite:VideoSprite;
	public var video:VideoHandler;
	#end
	
	override public function create()
	{
		judgeManager = new JudgmentManager();
		Conductor.safeZoneOffset = ClientPrefs.hitWindow;
		Wife3.timeScale = Conductor.judgeScales.get(ClientPrefs.judgeDiff);
		judgeManager.judgeTimescale = Wife3.timeScale;

		Paths.clearStoredMemory();

		//// Reset to default
		Note.quantShitCache.clear();
		FunkinHScript.defaultVars.clear();

		PauseSubState.songName = null;
		GameOverSubstate.resetVariables();

		////
		FlxG.fixedTimestep = false;
		FlxG.worldBounds.set(0, 0, FlxG.width, FlxG.height);

		persistentUpdate = true;
		persistentDraw = true;

		// for lua
		instance = this;

		if (FlxG.sound.music != null)
			FlxG.sound.music.stop();

		if (MusicBeatState.menuVox != null){
			MusicBeatState.menuVox.stop();
			MusicBeatState.menuVox.destroy();
			MusicBeatState.menuVox = null;
		}

		debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
		debugKeysBotplay = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('botplay'));

		keysArray = [
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
			ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
		];

		controlArray = [
			'NOTE_LEFT',
			'NOTE_DOWN',
			'NOTE_UP',
			'NOTE_RIGHT'
		];

		speedChanges.push({
			position: 0,
			songTime: 0,
			speed: 1
		});

		// For the "Just the Two of Us" achievement
		for (i in 0...keysArray.length)
			keysPressed.push(false);
		// Gameplay settings
		playbackRate = ClientPrefs.getGameplaySetting('songspeed', 1);
		healthGain = ClientPrefs.getGameplaySetting('healthgain', 1);
		healthLoss = ClientPrefs.getGameplaySetting('healthloss', 1);
		playOpponent = ClientPrefs.getGameplaySetting('opponentPlay', false);
		instakillOnMiss = ClientPrefs.getGameplaySetting('instakill', false);
		practiceMode = ClientPrefs.getGameplaySetting('practice', false);
		perfectMode = ClientPrefs.getGameplaySetting('perfect', false);
		instaRespawn = ClientPrefs.getGameplaySetting('instaRespawn', false);
		cpuControlled = ClientPrefs.getGameplaySetting('botplay', false);
		disableModcharts = !ClientPrefs.modcharts; //ClientPrefs.getGameplaySetting('disableModcharts', false);
		midScroll = ClientPrefs.midScroll;
		playbackRate *= (ClientPrefs.ruin ? 0.8 : 1);
		FlxG.timeScale = playbackRate;
		
		if(perfectMode){
			practiceMode = false;
			instakillOnMiss = true;
		}
		saveScore = !cpuControlled;
		healthDrain = switch(ClientPrefs.getGameplaySetting('healthDrain', "Disabled")){
			default: 0;
			case "Basic": 0.00055;
			case "Average": 0.0007;
			case "Heavy": 0.00085;
		};
		opponentHPDrain = ClientPrefs.getGameplaySetting('opponentFightsBack', false) ? 0.0182 : 0;

		//// Camera shit
		camGame = new FlxCamera();
		camVideo = new FlxCamera();
		camHUD = new FlxCamera();
		camOverlay = new FlxCamera();
		camOther = new FlxCamera();
		camStageUnderlay = new FlxCamera();

		camVideo.bgColor.alpha = 0;
		camStageUnderlay.bgColor = FlxColor.BLACK; 
		camHUD.bgColor.alpha = 0; 
		camOverlay.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		// Video Camera if you put funni videos or smth
		FlxG.cameras.add(camVideo, false);
		FlxG.cameras.add(camStageUnderlay, false);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camOverlay, false);
		FlxG.cameras.add(camOther, false);

		FlxG.cameras.setDefaultDrawTarget(camGame, true);
		CustomFadeTransition.nextCamera = camOther;

		camFollow = prevCamFollow != null ? prevCamFollow : new FlxPoint();
		camFollowPos = prevCamFollowPos != null ? prevCamFollowPos : new FlxObject(0, 0, 1, 1);

		prevCamFollow = null;
		prevCamFollowPos = null;

		FlxG.camera.follow(camFollowPos, LOCKON, 1);
		FlxG.camera.zoom = defaultCamZoom;
		FlxG.camera.focusOn(camFollow);

		////
		if (SONG == null)
			SONG = Song.loadFromJson('tutorial', 'tutorial');

		Conductor.mapBPMChanges(SONG);
		Conductor.changeBPM(SONG.bpm);
		Conductor.songPosition = -5000;

		songName = Paths.formatToSongPath(SONG.song);
		songHighscore = Highscore.getScore(SONG.song, difficulty);

		modManager = new ModManager(this);
		setDefaultHScripts("modManager", modManager);

		if (SONG != null){
			if(SONG.metadata != null)
				metadata = SONG.metadata;
			else{
				var jason = Paths.songJson(songName + '/metadata');

				if (!Paths.exists(jason))
					jason = Paths.modsSongJson(songName + '/metadata');

				if (Paths.exists(jason))
					metadata = cast Json.parse(Paths.getContent(jason));
				else{
					if(showDebugTraces)
						trace("No metadata for " + songName + ". Maybe add some?");
				}
			}
		}

		////
		arrowSkinbf = SONG.arrowSkinbf;
		arrowSkindad = SONG.arrowSkindad;
		splashSkin = SONG.splashSkin;

		if (arrowSkin == null || arrowSkin.trim().length == 0)
			arrowSkin = "NOTE_assets";

		if (splashSkin == null || splashSkin.trim().length == 0)
			splashSkin = "noteSplashes";

		// The quant prefix gets handled in the Note class

		//// STAGE SHIT
		if (SONG.stage == null || SONG.stage.length < 1)
			curStage = 'stage';
		else
			curStage = SONG.stage;

		//// GLOBAL SCRIPTS
		var filesPushed:Array<String> = [];

		for (folder in Paths.getFolders('scripts'))
		{
			Paths.iterateDirectory(folder, function(file:String)
			{
				if(filesPushed.contains(file) || !file.endsWith('.hscript'))
					return;

				var script = FunkinHScript.fromFile(folder + file);
				hscriptArray.push(script);
				funkyScripts.push(script);
				filesPushed.push(file);
			});
		}

		//// STAGE SCRIPTS
		stage = new Stage(curStage, true);
		stageData = stage.stageData;
		setStageData(stageData);

		//callOnHScripts("onStageCreated");

		if (stage.stageScript != null){
			hscriptArray.push(cast stage.stageScript);
			funkyScripts.push(stage.stageScript);
		}

		// SONG SPECIFIC SCRIPTS
		var foldersToCheck:Array<String> = Paths.getFolders('songs/$songName');
		#if PE_MOD_COMPATIBILITY
		for (dir in Paths.getFolders('data/$songName'))
			foldersToCheck.push(dir);
		#end

		var filesPushed:Array<String> = [];
		for (folder in foldersToCheck)
		{
			Paths.iterateDirectory(folder, function(file:String)
			{
				if(filesPushed.contains(file) || !file.endsWith('.hscript'))
					return;

				var script = FunkinHScript.fromFile(folder + file);
				hscriptArray.push(script);
				funkyScripts.push(script);
				filesPushed.push(file);
			});
		}

		//// Asset precaching start	
		for (judgeData in judgeManager.judgmentData)
			shitToLoad.push({path: judgeData.internalName});

		for (number in 0...10)
			shitToLoad.push({path: 'num$number'});

		if (ClientPrefs.hitsoundVolume > 0)
			shitToLoad.push({path: 'hitsound', type: 'SOUND'});

		if (ClientPrefs.missVolume != 0){
			shitToLoad.push({path: 'missnote1', type: 'SOUND'});
			shitToLoad.push({path: 'missnote2', type: 'SOUND'});
			shitToLoad.push({path: 'missnote3', type: 'SOUND'});
		}

		 
		if (PauseSubState.songName != null)
			shitToLoad.push({path: PauseSubState.songName, type: 'MUSIC'});
		else if (PauseSubState.songName != 'None')
			shitToLoad.push({path: Paths.formatToSongPath('Breakfast'), type: 'MUSIC'}); 
		
		shitToLoad.push({path: "breakfast", type: 'MUSIC'}); 
		

		////
		shitToLoad.push({path: 'noteSkin/$arrowSkin'});
		shitToLoad.push({path: 'noteSplash/$splashSkin'});

		////
		if (stageData.preloadStrings != null)
		{
			var lib = stageData.directory.trim().length > 0 ? stageData.directory : null;
			for (i in stageData.preloadStrings)
				shitToLoad.push({path: i, library: lib});
		}

		if (stageData.preload != null)
		{
			for (i in stageData.preload)
				shitToLoad.push(i);
		}

		var characters:Array<String> = [SONG.player1, SONG.player2];
		if (!stageData.hide_girlfriend)
		{
			characters.push(SONG.gfVersion);
		}

		for (character in characters)
		{
			for (data in Character.returnCharacterPreload(character))
				shitToLoad.push(data);
		}

		for (event in getEvents())
		{
			for (data in preloadEvent(event))
			{ // preloads everythin for events
				if (!shitToLoad.contains(data))
					shitToLoad.push(data);
			}
		}

		shitToLoad.push({
			path: '$songName/Inst',
			type: 'SONG'
		});

		if (SONG.needsVoices)
			shitToLoad.push({
				path: '$songName/Voices',
				type: 'SONG'
			});

		// extra tracks (ex: die batsards bullet track)
		for (track in SONG.extraTracks){
			shitToLoad.push({
				path: '$songName/$track',
				type: 'SONG'
			});
		}

		Cache.loadWithList(shitToLoad);
		shitToLoad = [];

		//// Asset precaching end

		var splash:NoteSplash = new NoteSplash(100, 100,'' ,0);
		splash.alpha = 0.0;
		grpNoteSplashes.add(splash);

		//// Characters

		var gfVersion:String = SONG.gfVersion;

		if (stageData.hide_girlfriend != true)
		{
			gf = new Character(0, 0, gfVersion);

			if (stageData.camera_girlfriend != null){
				gf.cameraPosition[0] += stageData.camera_girlfriend[0];
				gf.cameraPosition[1] += stageData.camera_girlfriend[1];
			}

			startCharacter(gf);
			gf.scrollFactor.set(0.95, 0.95);
			gfMap.set(gf.curCharacter, gf);
			gfGroup.add(gf);
		}

		dad = new Character(0, 0, SONG.player2);

		if (stageData.camera_opponent != null){
			dad.cameraPosition[0] += stageData.camera_opponent[0];
			dad.cameraPosition[1] += stageData.camera_opponent[1];
		}
		startCharacter(dad, true);
		
		dadMap.set(dad.curCharacter, dad);
		dadGroup.add(dad);

		boyfriend = new Character(0, 0, SONG.player1, true);
		if (stageData.camera_boyfriend != null){
			boyfriend.cameraPosition[0] += stageData.camera_boyfriend[0];
			boyfriend.cameraPosition[1] += stageData.camera_boyfriend[1];
		}
		startCharacter(boyfriend);

		boyfriendMap.set(boyfriend.curCharacter, boyfriend);
		boyfriendGroup.add(boyfriend);

		if(dad.curCharacter.startsWith('gf')) {
			dad.setPosition(GF_X, GF_Y);
			if(gf != null)
				gf.visible = false;
		}
		
		
		if (hud == null){
			switch(ClientPrefs.etternaHUD){
				case 'Advanced': hud = new AdvancedHUD(boyfriend.healthIcon, dad.healthIcon, SONG.song, stats);
				case 'ITG': hud = new hud.ITGHUD(boyfriend.healthIcon, dad.healthIcon, SONG.song, stats);
				default: hud = new PsychHUD(boyfriend.healthIcon, dad.healthIcon, SONG.song, stats);
			}
		}
		
		// TODO: remove all dependencies on healthbar in here
		// aka make the HUD handle all of this (so that you can make custom HP bars, etc)
		healthBar = hud.healthBar;
		healthBarBG = healthBar.healthBarBG;

		if (ClientPrefs.etternaHUD == 'ITG')
		{
			healthBar2 = hud.healthBar2;
			healthBarBG2 = healthBar2.healthBarBG;
		}
		iconP1 = healthBar.iconP1;
		iconP2 = healthBar.iconP2;

		botplayTxt = new BotplayText(0, (ClientPrefs.downScroll ? FlxG.height - 44 : 19) + 15 + (ClientPrefs.downScroll ? -78 : 55), FlxG.width, ClientPrefs.etternaHUD == 'ITG' ? "AutoPlay" :"[BOTPLAY]", 32);
		botplayTxt.setFormat(Paths.font(ClientPrefs.etternaHUD == 'ITG' ? 'miso-bold.ttf' : gameFont), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.exists = false;
		
		stage.buildStage();

		// in case you want to layer characters or objects in a specific way (like in infimario for example)
		// RICO CAN WE STOP USING SLURS IN THE CODE
		// we???
		// fine, can YOU stop using slurs in the code >:(
		if (Globals.Function_Stop != callOnHScripts("onAddSpriteGroups"))
		{
			add(stage);

			add(gfGroup);
			add(dadGroup);
			add(boyfriendGroup);

			add(stage.foreground);
		}

		//// Generate playfields so you can actually, well, play the game
		callOnScripts("prePlayfieldCreation");
		playerField = new PlayField(modManager);
		playerField.modNumber = 0;
		playerField.characters = [];
		for(n => ch in boyfriendMap)playerField.characters.push(ch);
		
		playerField.isPlayer = !playOpponent;
		playerField.autoPlayed = !playerField.isPlayer || cpuControlled;
		playerField.noteHitCallback = playOpponent ? opponentNoteHit : goodNoteHit;

		dadField = new PlayField(modManager);
		dadField.isPlayer = playOpponent;
		dadField.autoPlayed = !dadField.isPlayer || cpuControlled;
		dadField.modNumber = 1;
		dadField.characters = [];
		for(n => ch in dadMap)dadField.characters.push(ch);
		dadField.noteHitCallback = playOpponent ? goodNoteHit : opponentNoteHit;

		dad.idleWhenHold = !dadField.isPlayer;
		boyfriend.idleWhenHold = !playerField.isPlayer;

		playfields.add(dadField);
		playfields.add(playerField);

		initPlayfield(dadField);
		initPlayfield(playerField);
		
		callOnScripts("postPlayfieldCreation");


		////
		cameraPoints = [sectionCamera];
		moveCameraSection(SONG.notes[0]);

		////
		
		hud.songName = SONG.song;
		hud.alpha = ClientPrefs.hudOpacity;
		add(hud);

		//
		lastJudge = RatingSprite.newRating();
		ratingTxtGroup.add(lastJudge).kill();
		if (ClientPrefs.etternaHUD != "ITG") {
			for (i in 0...3)
				comboNumGroup.add(RatingSprite.newNumber()).kill();
		} else {
			for (i in 0...3)
				comboNumTxt.add(RatingText.newNumber()).kill();
		}
		
		timingTxt = new FlxText();
		timingTxt.setFormat(Paths.font(gameFont), 28, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timingTxt.cameras = [camHUD];
		timingTxt.scrollFactor.set();
		timingTxt.borderSize = 1.25;
		
		timingTxt.visible = false;
		timingTxt.alpha = 0;



		// init shit
		health = 1;
		reloadHealthBarColors();

		startingSong = true;

		#if LUA_ALLOWED
		//// "GLOBAL" LUA SCRIPTS
		var filesPushed:Array<String> = [];
		for (folder in Paths.getFolders('scripts'))
		{
			Paths.iterateDirectory(folder, function(file:String)
			{
				if(filesPushed.contains(file))
					return;

				if(file.endsWith('.lua')) {
					var script = new FunkinLua(folder + file);
					luaArray.push(script);
					funkyScripts.push(script);
					filesPushed.push(file);
				}			
			});
		}

		//// STAGE LUA SCRIPTS
		var baseFile:String = 'stages/$curStage.lua';
		for (file in [#if MODS_ALLOWED Paths.modFolders(baseFile), #end Paths.getPreloadPath(baseFile)])
		{
			if (!Paths.exists(file))
				continue;

			var script = new FunkinLua(file);
			luaArray.push(script);
			funkyScripts.push(script);

			break;
		}


		// SONG SPECIFIC LUA SCRIPTS
		var foldersToCheck:Array<String> = Paths.getFolders('songs/$songName');
		#if PE_MOD_COMPATIBILITY
		for (dir in Paths.getFolders('data/$songName'))
			foldersToCheck.push(dir);
		
		#end
		var filesPushed:Array<String> = [];


		var filesPushed:Array<String> = [];
		for (folder in foldersToCheck){
			Paths.iterateDirectory(folder, function(file:String)
			{
				if(filesPushed.contains(file) || !file.endsWith('.lua'))
					return;

				var script = new FunkinLua(folder + file);
				luaArray.push(script);
				funkyScripts.push(script);
				filesPushed.push(file);	
			});
		}
		#end

		var cH = [camHUD];
		hud.cameras = cH;
		playerField.cameras = cH;
		dadField.cameras = cH;
		playfields.cameras = cH;
		strumLineNotes.cameras = cH;
		grpNoteSplashes.cameras = cH;
		notes.cameras = cH;
		botplayTxt.cameras = cH;

		// EVENT AND NOTE SCRIPTS WILL GET LOADED HERE
		generateSong(SONG.song);

		#if discord_rpc
		// Discord RPC texts
		detailsText = isStoryMode ? "Story Mode" : "Freeplay";
		detailsPausedText = "Paused - " + detailsText;

		// Updating Discord Rich Presence.
		DiscordClient.changePresence(detailsText, SONG.song, songName);
		#end

		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.addEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}

		////

		subtitles = SubtitleDisplay.fromSong(SONG.song);
		if (subtitles != null){
			add(subtitles);
			subtitles.y = 550;
			subtitles.cameras = [camOther];
		}else if(showDebugTraces)
			trace(SONG.song + " doesnt have subtitles!");

		////
		callOnAllScripts('onCreatePost');
		if(ClientPrefs.judgeBehind){
			add(ratingTxtGroup);
			if (ClientPrefs.etternaHUD != "ITG")
				add(comboNumGroup);
			else
				add(comboNumTxt);
			add(timingTxt);
		}
		add(strumLineNotes);
		add(playfields);
		add(notefields);
		if (!ClientPrefs.judgeBehind)
		{
			add(ratingTxtGroup);
			if (ClientPrefs.etternaHUD != "ITG")
				add(comboNumGroup);
			else
				add(comboNumTxt);
			add(timingTxt);
		}
		add(botplayTxt);
		add(grpNoteSplashes);

		#if LUA_ALLOWED
		luaDebugGroup = new FlxTypedGroup<DebugLuaText>();
		luaDebugGroup.cameras = [camOther];
		add(luaDebugGroup);
		#end

		/*
		if(SONG.notes[0].mustHitSection){
			var cam = boyfriend.getCamera();
			camFollow.set(cam[0], cam[1]);
		}else if(SONG.notes[0].gfSection && gf != null){
			var cam = gf.getCamera();
			camFollow.set(cam[0], cam[1]);
		}else{
			var cam = dad.getCamera();
			camFollow.set(cam[0], cam[1]);
		}
		sectionCamera.copyFrom(camFollow);
		camFollowPos.setPosition(camFollow.x, camFollow.y);
		*/

		// Load all of the countdown intro assets!!!!!
		shitToLoad.push({path: 'intro3', type: "SOUND"});
		shitToLoad.push({path: 'intro2', type: "SOUND"});
		shitToLoad.push({path: 'intro1', type: "SOUND"});
		shitToLoad.push({path: 'introGo', type: "SOUND"});
		for (introPath in introAlts){
			if (introPath != null)
				shitToLoad.push({path: introPath});
		}

		Cache.loadWithList(shitToLoad);

		shitToLoad = [];

		super.create();

		RecalculateRating();
		startCountdown();

		finishedCreating = true;

		Paths.clearUnusedMemory();

		noteSkinMap.clear();
		noteSkinMap = null;
		noteTypeMap.clear();
		noteTypeMap = null;
		eventPushedMap.clear();
		eventPushedMap = null;

		CustomFadeTransition.nextCamera = camOther;
	}

	function setStageData(stageData:StageFile)
	{
		defaultCamZoom = stageData.defaultZoom;
		camGame.zoom = defaultCamZoom;

		var color = FlxColor.fromString(stageData.bg_color);
		camGame.bgColor = color != null ? color : FlxColor.BLACK;
		

		BF_X = stageData.boyfriend[0];
		BF_Y = stageData.boyfriend[1];
		GF_X = stageData.girlfriend[0];
		GF_Y = stageData.girlfriend[1];
		DAD_X = stageData.opponent[0];
		DAD_Y = stageData.opponent[1];

		if(stageData.camera_speed != null)
			cameraSpeed = stageData.camera_speed;

		boyfriendCameraOffset = stageData.camera_boyfriend;
		if(boyfriendCameraOffset == null){ //Fucks sake should have done it since the start :rolling_eyes:
			boyfriendCameraOffset = [0, 0];
			stageData.camera_boyfriend = [0, 0];
		}

		opponentCameraOffset = stageData.camera_opponent;
		if(opponentCameraOffset == null){
			opponentCameraOffset = [0, 0];
			stageData.camera_opponent = [0, 0];
		}

		girlfriendCameraOffset = stageData.camera_girlfriend;
		if(girlfriendCameraOffset == null){
			girlfriendCameraOffset = [0, 0];
			stageData.camera_girlfriend = [0, 0];
		}

		if(boyfriendGroup==null)
			boyfriendGroup = new FlxSpriteGroup(BF_X, BF_Y);
		else{
			boyfriendGroup.x = BF_X;
			boyfriendGroup.y = BF_Y;
		}
		if(dadGroup==null)
			dadGroup = new FlxSpriteGroup(DAD_X, DAD_Y);
		else{
			dadGroup.x = DAD_X;
			dadGroup.y = DAD_Y;
		}

		if(gfGroup==null)
			gfGroup = new FlxSpriteGroup(GF_X, GF_Y);
		else{
			gfGroup.x = GF_X;
			gfGroup.y = GF_Y;
		}
	}	

	function set_songSpeed(value:Float):Float
	{
		if(generatedMusic)
		{
			var ratio:Float = value / songSpeed; //funny word huh
/* 			for (note in notes) note.resizeByRatio(ratio);
			for (note in unspawnNotes) note.resizeByRatio(ratio); */
			for(note in allNotes)note.resizeByRatio(ratio);
		}
		songSpeed = value;
		noteKillOffset = 350 / songSpeed;
		return value;
	}

	public function addTextToDebug(text:String, ?color:FlxColor = FlxColor.WHITE) {
		#if LUA_ALLOWED
		luaDebugGroup.forEachAlive(function(spr:DebugLuaText) {
			spr.y += 20;
		});

		if(luaDebugGroup.members.length > 34) {
			var blah = luaDebugGroup.members[34];
			blah.destroy();
			luaDebugGroup.remove(blah);
		}
		luaDebugGroup.insert(0, new DebugLuaText(text, luaDebugGroup));
		#end
	}

	public function reloadHealthBarColors() {
		if(callOnHScripts('reloadHealthBarColors', [healthBar]) == Globals.Function_Stop)
			return;

		if (ClientPrefs.etternaHUD == 'ITG') {
			if (healthBar != null){
				healthBar.createFilledBar(
					FlxColor.BLACK,
					0xFFdce0e6
				);
				healthBar.updateBar();
			}

			if (healthBar2 != null){
				healthBar2.createFilledBar(
					FlxColor.BLACK,
					0xFFdce0e6
				);
				healthBar2.updateBar();
			}	
		} else {
			if (healthBar != null){
				healthBar.createFilledBar(
					FlxColor.fromRGB(dad.healthColorArray[0], dad.healthColorArray[1], dad.healthColorArray[2]),
					FlxColor.fromRGB(boyfriend.healthColorArray[0], boyfriend.healthColorArray[1], boyfriend.healthColorArray[2])
				);
				healthBar.updateBar();
			}	
		}
	}

	public function addCharacterToList(newCharacter:String, type:Int) {
		switch(type) {
			case 0:
				if(!boyfriendMap.exists(newCharacter)) {
					var newBoyfriend:Character = new Character(0, 0, newCharacter, true);
					newBoyfriend.cameraPosition[0] += stageData.camera_boyfriend[0];
					newBoyfriend.cameraPosition[1] += stageData.camera_boyfriend[1];

					newBoyfriend.alpha = 0.00001;
					if(playerField!=null)
						playerField.characters.push(newBoyfriend);

					boyfriendMap.set(newCharacter, newBoyfriend);
					boyfriendGroup.add(newBoyfriend);

					startCharacter(newBoyfriend);
				}

			case 1:
				if(!dadMap.exists(newCharacter)) {
					var newDad:Character = new Character(0, 0, newCharacter);
					newDad.cameraPosition[0] += stageData.camera_opponent[0];
					newDad.cameraPosition[1] += stageData.camera_opponent[1];
					if(dadField!=null)
						dadField.characters.push(newDad);
					dadMap.set(newCharacter, newDad);
					dadGroup.add(newDad);
					startCharacter(newDad, true);
					newDad.alpha = 0.00001;
				}

			case 2:
				if(gf != null && !gfMap.exists(newCharacter)) {
					var newGf:Character = new Character(0, 0, newCharacter);
					newGf.cameraPosition[0] += stageData.camera_girlfriend[0];
					newGf.cameraPosition[1] += stageData.camera_girlfriend[1];
					newGf.scrollFactor.set(0.95, 0.95);

					newGf.alpha = 0.00001;

					gfMap.set(newCharacter, newGf);
					gfGroup.add(newGf);
					startCharacter(newGf);

				}
		}
	}

	function startCharacter(char:Character, gf:Bool=false){
		startCharacterPos(char, gf);
		startCharacterScript(char);
	}

	function startCharacterScript(char:Character)
	{
		char.startScripts();

		if (char.characterScript != null){
			#if LUA_ALLOWED
			if (char.characterScript is FunkinLua)
				luaArray.push(cast char.characterScript);
			else
			#end
			hscriptArray.push(cast char.characterScript);

			funkyScripts.push(char.characterScript);
		}
	}

	public function getLuaObject(tag:String, text:Bool=true):FlxSprite {
		if(modchartObjects.exists(tag)) return modchartObjects.get(tag);
		if(modchartSprites.exists(tag)) return modchartSprites.get(tag);
		if(text && modchartTexts.exists(tag)) return modchartTexts.get(tag);
		return null;
	}

	function startCharacterPos(char:Character, ?gfCheck:Bool = false) {
		if(gfCheck && char.curCharacter.startsWith('gf')) { //IF DAD IS GIRLFRIEND, HE GOES TO HER POSITION
			char.setPosition(GF_X, GF_Y);
			char.scrollFactor.set(0.95, 0.95);
			char.danceEveryNumBeats = 2;
		}
		char.x += char.positionArray[0];
		char.y += char.positionArray[1];
	}

	/**
	 * Start The video in the middle of the song
	 * @param name Video Name
	 * @param extension (Mp4)
	 */
	public function startMidSongVideo(name:String, extension:String)
	{
		#if VIDEOS_ALLOWED
		inCutscene = false;
	
		var filepath:String = Paths.video(name, extension);
		#if sys
		if (!FileSystem.exists(filepath))
		#else
		if (!OpenFlAssets.exists(filepath))
		#end
		{
			return;
		}
	
		if (ClientPrefs.bgvid)
		{
			/*var appliedWidth:Float = Lib.current.stage.stageHeight * (FlxG.width / FlxG.height);
			var appliedHeight:Float = Lib.current.stage.stageWidth * (FlxG.height / FlxG.width);
	
			if (appliedHeight > Lib.current.stage.stageHeight)
				appliedHeight = Lib.current.stage.stageHeight;
	
			if (appliedWidth > Lib.current.stage.stageWidth)
				appliedWidth = Lib.current.stage.stageWidth;*/
	
			videoSprite = new VideoSprite();
			videoSprite.cameras = [camVideo];
			
			var aspectRatio:Float = FlxG.width / FlxG.height;

			var vidWidth:Float;
			var vidHeight:Float;

			if (FlxG.stage.stageWidth / FlxG.stage.stageHeight > aspectRatio)
			{
				// stage is wider than video
				vidWidth = FlxG.stage.stageHeight * aspectRatio;
				vidHeight = FlxG.stage.stageHeight;
			}
			else
			{
				// stage is taller than video
				vidWidth = FlxG.stage.stageWidth;
				vidHeight = FlxG.stage.stageWidth * (1 / aspectRatio);
			}
			videoSprite.canvasWidth = Std.int(vidWidth);
			videoSprite.canvasHeight =  Std.int(vidHeight);
			add(videoSprite);
			videoSprite.play(filepath, true);
		}
		else
			return;
		#else
		FlxG.log.warn('Platform not supported!');
		return;
		#end
	}

	/**
	 * Start Before or After The Song
	 * @param name Video Name 
	 * @param extension (Mp4)
	 * @param isSkippable
	 */
	public function startVideo(name:String, extension:String, isSkippable:Bool)
	{
		#if VIDEOS_ALLOWED
		inCutscene = true;

		var filepath:String = Paths.video(name, extension);
		if (!Paths.exists(filepath))
		{
			FlxG.log.warn('Couldnt find video file: ' + name);
			startAndEnd();
			return;
		}

		video = new VideoHandler();
		#if (hxCodec >= "3.0.0")
		//Recent
		video.play(filepath);
		video.onFinishReached = function () 
		{
			startAndEnd();
			return;
		}

		video.onEndReached.add(function () 
		{
			video.dispose();
			startAndEnd();
			return;
		}, true);
		#else
		// Older versions
		video.playVideo(filepath);
		video.finishCallback = function()
		{
			startAndEnd();
			return;
		}
		#end
		#else
		FlxG.log.warn('Video not supported!');
		startAndEnd();
		return;
		#end
	}

	function startAndEnd()
	{
		if(endingSong){
			endSong();
		}
		else{
			startCountdown();
		}
	}

	/*
	function songIntroCutscene(){
		if (isStoryMode && !seenCutscene)
		{
			switch (songName)
			{
				default:
					startCountdown();
			}
			seenCutscene = true;
		}
		else
		{
			startCountdown();
		}
	}
	*/

	var startTimer:FlxTimer;
	var finishTimer:FlxTimer = null;

	// For being able to mess with the sprites on Lua
	public var introAlts:Array<Null<String>> = [null, 'ready', 'set', 'go'];

	public var countdownSpr:FlxSprite;
	var countdownTwn:FlxTween;
	public static var startOnTime:Float = 0;
	
	public var skipArrowStartTween:Bool = false; //for lua
	public function startCountdown():Void
	{
		if(startedCountdown) {
			callOnScripts('onStartCountdown');
			return;
		}

		inCutscene = false;

		if (callOnScripts('onStartCountdown') == Globals.Function_Stop){
			return;
		}
		if (skipCountdown || startOnTime > 0)
			skipArrowStartTween = true;

		for(i in 0...4){
			playerStrums.add(new StrumNote(0, 0, 0,arrowSkinbf));
			opponentStrums.add(new StrumNote(0, 0, 0,arrowSkindad));
		}

		callOnScripts('preReceptorGeneration');
		playerField.generateStrums(arrowSkinbf);
		dadField.generateStrums(arrowSkindad);
		//for(field in playfields.members)
		//	field.generateStrums();

		callOnScripts('postReceptorGeneration');
		for(field in playfields.members)
			field.fadeIn(isStoryMode || skipArrowStartTween); // TODO: check if its the first song so it should fade the notes in on song 1 of story mode
		modManager.receptors = [playerField.strumNotes, dadField.strumNotes];

		callOnScripts('preModifierRegister');
		modManager.registerDefaultModifiers();
		callOnScripts('postModifierRegister');

		/*if(midScroll){
			modManager.setValue("opponentSwap", 0.5);
			for(field in notefields.members){
				if(field.field==null)continue;
				field.alpha = field.field.isPlayer ? 0 : 1;
			}
			
		}*/

		startedCountdown = true;
		Conductor.songPosition = 0;
		Conductor.songPosition -= Conductor.crochet * 5;
		setOnScripts('startedCountdown', true);
		callOnScripts('onCountdownStarted');

		if(startOnTime < 0)
			startOnTime = 0;

		if (startOnTime > 0) {
			clearNotesBefore(startOnTime);
			setSongTime(startOnTime - 350);
			return;
		}
		else if (skipCountdown)
		{
			setSongTime(0);
			return;
		}

		// Do the countdown.
		var swagCounter:Int = 0;
		startTimer = new FlxTimer().start(Conductor.crochet * 0.001, function(tmr:FlxTimer)
		{
			if (gf != null)
			{
				var gfDanceEveryNumBeats = Math.round(gfSpeed * gf.danceEveryNumBeats);
				if ((gfDanceEveryNumBeats != 0 && tmr.loopsLeft % gfDanceEveryNumBeats == 0) && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
					gf.dance();
			}

			for(field in playfields){
				for(char in field.characters){
					if(char!=gf){
						if ((char.danceEveryNumBeats != 0 && tmr.loopsLeft % char.danceEveryNumBeats == 0)
							&& char.animation.curAnim != null
							&& !char.animation.curAnim.name.startsWith('sing')
							&& !char.stunned)
						{
							char.dance();
						}

					}
				}
			}


			var sprImage:Null<String> = introAlts[swagCounter];
			if (sprImage != null){
				if (countdownTwn != null)
					countdownTwn.cancel();

				countdownSpr = new FlxSprite(0, 0, Paths.image(sprImage));
				countdownSpr.scrollFactor.set();
				countdownSpr.updateHitbox();
				countdownSpr.cameras = [camHUD];

				countdownSpr.screenCenter();

				insert(members.indexOf(notes), countdownSpr);

				countdownTwn = FlxTween.tween(countdownSpr, {alpha: 0}, Conductor.crochet * 0.001, {
					ease: FlxEase.cubeInOut,
					onComplete: function(twn){
						countdownTwn.destroy();
						countdownTwn = null;
						remove(countdownSpr).destroy();
						countdownSpr = null;
					}
				});
			}

			var sound = switch (swagCounter){
				case 0: 'intro3' + introSoundsSuffix;
				case 1: 'intro2' + introSoundsSuffix;
				case 2: 'intro1' + introSoundsSuffix;
				case 3: 'introGo' + introSoundsSuffix;
				default: null;
			};
			if(sound != null){
				var snd = FlxG.sound.play(Paths.sound(sound), 0.6);
				snd.endTime = snd.length;
				snd.effect = ClientPrefs.ruin ? sndEffect : null;
				snd.onComplete = ()->{ snd.volume = 0; }
			}
			/*
				notes.forEachAlive(function(note:Note) {
				if(ClientPrefs.opponentStrums || note.mustPress)
				{
					note.copyAlpha = false;
					note.alpha = note.multAlpha;
					if(ClientPrefs.middleScroll && !note.mustPress) {
						note.alpha *= 0.35;
					}
				}
			}); 
			*/

			callOnHScripts('onCountdownTick', [swagCounter, tmr]);
			#if LUA_ALLOWED
			callOnLuas('onCountdownTick', [swagCounter]);
			#end

			swagCounter += 1;
		}, 5);

	}

	public function addBehindGF(obj:FlxObject)
	{
		insert(members.indexOf(gfGroup), obj);
	}
	public function addBehindBF(obj:FlxObject)
	{
		insert(members.indexOf(boyfriendGroup), obj);
	}
	public function addBehindDad(obj:FlxObject)
	{
		insert(members.indexOf(dadGroup), obj);
	}

	public function clearNotesBefore(time:Float)
	{

		var i:Int = allNotes.length - 1;
		while (i >= 0) {
			var daNote:Note = allNotes[i];
			if(daNote.strumTime - 350 < time)
			{
				daNote.ignoreNote = true;
				if (modchartObjects.exists('note${daNote.ID}'))
					modchartObjects.remove('note${daNote.ID}');
				for (field in playfields)
					field.removeNote(daNote);




			}
			--i;
		}
	}

	public function setSongTime(time:Float)
	{
		if(time < 0) time = 0;

		inst.pause();
		vocals.pause();
		for (track in tracks)
			track.pause();

		inst.time = time;
		inst.play();

		vocals.time = time;
		vocals.play();
		for (track in tracks){
			track.time = time;
			track.play();
		}

		Conductor.songPosition = time;
		songTime = time;
	}

	var previousFrameTime:Int = 0;
	//var lastReportedPlayheadPosition:Int = 0;
	var songTime:Float = 0;
	var vocalsEnded:Bool = false;
	function startSong():Void
	{
		startingSong = false;

		previousFrameTime = FlxG.game.ticks;
		//lastReportedPlayheadPosition = 0;

		
		inst.onComplete = function(){
			trace("song ended!?");
			finishSong(false);
		};

		vocals.onComplete = function(){
			vocalsEnded = true;
			vocals.volume = 0; // just so theres no like vocal restart stuff at the end of the song lol
		};
		for (track in tracks)
			track.play();
		

		vocals.play();
		inst.play();
		if(startOnTime > 0)
		{
			setSongTime(startOnTime - 500);
		}
		startOnTime = 0;

		if(paused) {
			//trace('Oopsie doopsie! Paused sound');
			inst.pause();
			vocals.pause();
			for (track in tracks)
				track.play();
		}

		// Song duration in a float, useful for the time left feature
		songLength = inst.length;
		hud.songLength = songLength;
		hud.songStarted();

		resyncVocals();

		#if discord_rpc
		// Updating Discord Rich Presence (with Time Left)
		DiscordClient.changePresence(detailsText, SONG.song, Paths.formatToSongPath(SONG.song), true, songLength);
		#end
		setOnScripts('songLength', songLength);
		callOnScripts('onSongStart');
	}

	var debugNum:Int = 0;
	private var noteSkinMap:Map<String, Bool> = new Map<String, Bool>();
	private var noteTypeMap:Map<String, Bool> = new Map<String, Bool>();
	private var eventPushedMap:Map<String, Bool> = new Map<String, Bool>();

	function shouldPush(event:EventNote){
		switch(event.event){
			default:
				if (eventScripts.exists(event.event))
				{
					var eventScript:FunkinScript = eventScripts.get(event.event);
					var returnVal:Dynamic = callScript(eventScript, "shouldPush", [event]);

					if (returnVal == Globals.Function_Stop) returnVal = false;

					return !(returnVal == false);
				}
		}
		return true;
	}

	function eventSort(a:Array<Dynamic>, b:Array<Dynamic>)
		return Std.int(a[0] - b[0]);

	function getEvents()
	{
		var songData = SONG;
		var events:Array<EventNote> = [];

		var eventsJSON = Song.loadFromJson('events', songName);
		if (eventsJSON != null)
		{
			var rawEventsData:Array<Array<Dynamic>> = eventsJSON.events;
			rawEventsData.sort(eventSort);
			var eventsData:Array<Array<Dynamic>> = [];
			for (event in rawEventsData){
				var last = eventsData[eventsData.length-1];
				if (last != null && Math.abs(last[0] - event[0]) <= Conductor.stepCrochet / (192 / 16)){
					var fuck:Array<Array<Dynamic>> = event[1];
					for (shit in fuck) eventsData[eventsData.length - 1][1].push(shit);
				}else
					eventsData.push(event);
			}

			for (event in eventsData) //Event Notes
			{
				var eventTime:Float = event[0] + ClientPrefs.noteOffset;
				var subEvents:Array<Dynamic> = event[1];

				for (eventData in subEvents)
				{
					var eventNote:EventNote = {
						strumTime: eventTime,
						event: eventData[0],
						value1: eventData[1],
						value2: eventData[2]
					};
					if (shouldPush(eventNote)) events.push(eventNote);
				}
			}
		}

		var rawEventsData:Array<Array<Dynamic>> = songData.events;
		rawEventsData.sort(eventSort);
		var eventsData:Array<Array<Dynamic>>  = [];
		for (event in rawEventsData){
			var last = eventsData[eventsData.length-1];
			if (last != null && Math.abs(last[0] - event[0]) <= Conductor.stepCrochet / (192 / 16)){
				var fuck:Array<Array<Dynamic>> = event[1];
				for (shit in fuck) eventsData[eventsData.length - 1][1].push(shit);
			}else
				eventsData.push(event);
		}

		songData.events = eventsData;		

		for (event in songData.events) //Event Notes
		{
			var eventTime:Float = event[0] + ClientPrefs.noteOffset;
			var subEvents:Array<Dynamic> = event[1];

			for (eventData in subEvents)
			{
				var eventNote:EventNote = {
					strumTime: eventTime,
					event: eventData[0],
					value1: eventData[1],
					value2: eventData[2]
				};
				if (shouldPush(eventNote)) events.push(eventNote);
			}
		}


		return events;
	}

	private function generateSong(dataPath:String):Void
	{
		songSpeedType = ClientPrefs.getGameplaySetting('scrolltype','multiplicative');

		switch(songSpeedType)
		{
			case "multiplicative":
				songSpeed = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1);
			case "constant":
				songSpeed = ClientPrefs.getGameplaySetting('scrollspeed', 1);
		}

		var songData = SONG;
		Conductor.changeBPM(songData.bpm);

		inst = new FlxSound().loadEmbedded(Paths.inst(PlayState.SONG.song));
		vocals = new FlxSound();

		if (SONG.needsVoices)
			vocals.loadEmbedded(Paths.voices(PlayState.SONG.song));
		else
			vocalsEnded = true;

		vocals.exists = true; // so it doesn't get recycled

		FlxG.sound.list.add(inst);
		FlxG.sound.list.add(vocals);

		if (SONG.extraTracks != null){
			for (trackName in SONG.extraTracks){
				var newTrack = new FlxSound().loadEmbedded(Paths.track(PlayState.SONG.song, trackName));
				tracks.push(newTrack);
				FlxG.sound.list.add(newTrack);
			}
		}

		AL.filteri(sndFilter, AL.FILTER_TYPE, AL.FILTER_NULL);
 		if(ClientPrefs.ruin){
			AL.effecti(sndEffect, AL.EFFECT_TYPE, AL.EFFECT_REVERB);
			AL.effectf(sndEffect, AL.REVERB_DECAY_TIME, 5);
			AL.effectf(sndEffect, AL.REVERB_GAIN, 0.75);
			AL.effectf(sndEffect, AL.REVERB_DIFFUSION, 0.5);
		}else
			AL.effecti(sndEffect, AL.EFFECT_TYPE, AL.EFFECT_NULL);
		

		for (track in tracks){
			track.effect = ClientPrefs.ruin?sndEffect:null;
			track.filter = null;
			track.pitch = playbackRate;
		}

		inst.filter = null;
		vocals.filter = null;
		inst.effect = ClientPrefs.ruin?sndEffect:null;
		vocals.effect = ClientPrefs.ruin?sndEffect:null;
		
		inst.pitch = playbackRate;
		vocals.pitch = playbackRate;

		add(notes);

		// NEW SHIT
		var noteData:Array<SwagSection> = songData.notes;

		for (section in noteData)
			{
				var type:Dynamic = section.mustHitSection ? arrowSkinbf : arrowSkindad;
	
				if (!noteSkinMap.exists(type)) {
					noteSkinMap.set(type, true);
				}
			}
	
		#if (LUA_ALLOWED && PE_MOD_COMPATIBILITY)
		var luaNoteskinScripts = [];
		#end
		for (noteskins in noteSkinMap.keys())
			{
				var doPush:Bool = false;
				for(file in ["noteskins", #if PE_MOD_COMPATIBILITY "custom_noteskins" #end])
				{
					var baseScriptFile:String = '$file/$noteskins';
					for (ext in ["hscript", #if LUA_ALLOWED "lua" #end])
					{
						if (doPush)
							break;
						var baseFile = '$baseScriptFile.$ext';
						var files = [#if MODS_ALLOWED Paths.modFolders(baseFile), #end Paths.getPreloadPath(baseFile)];
						for (file in files)
						{
							if (!Paths.exists(file))
								continue;
		
							#if LUA_ALLOWED
							if (ext == 'lua')
							{
								var script = new FunkinLua(file, noteskins, #if PE_MOD_COMPATIBILITY true #else false #end);
								luaArray.push(script);
								funkyScripts.push(script);
								#if PE_MOD_COMPATIBILITY
								// PE_MOD_COMPATIBILITY to call onCreate at the end of this function
								luaNoteskinScripts.push(script);
								#end
								doPush = true;
							}
							else if (ext == 'hscript') #end
							{
								var script = FunkinHScript.fromFile(file, noteskins);
								hscriptArray.push(script);
								funkyScripts.push(script);
								noteskinScripts.set(noteskins, script);
								doPush = true;
							}
							if (doPush)
								break;
						}
					}
				}
			}

		// loads note types
		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var type:Dynamic = songNotes[3];
				/*
				if (Std.isOfType(type, Int)) 
					type = editors.ChartingState.noteTypeList[type];
				*/

				if (!noteTypeMap.exists(type)) {
					firstNotePush(type);
					noteTypeMap.set(type, true);
				}
			}
		}

		#if (LUA_ALLOWED && PE_MOD_COMPATIBILITY)
		var luaNotetypeScripts = [];
		#end
		for (notetype in noteTypeMap.keys())
		{
			var doPush:Bool = false;
			for(file in ["notetypes", #if PE_MOD_COMPATIBILITY "custom_notetypes" #end])
			{
				var baseScriptFile:String = '$file/$notetype';
				for (ext in ["hscript", #if LUA_ALLOWED "lua" #end])
				{
					if (doPush)
						break;
					var baseFile = '$baseScriptFile.$ext';
					var files = [#if MODS_ALLOWED Paths.modFolders(baseFile), #end Paths.getPreloadPath(baseFile)];
					for (file in files)
					{
						if (!Paths.exists(file))
							continue;

						#if LUA_ALLOWED
						if (ext == 'lua')
						{
							var script = new FunkinLua(file, notetype, #if PE_MOD_COMPATIBILITY true #else false #end);
							luaArray.push(script);
							funkyScripts.push(script);
							#if PE_MOD_COMPATIBILITY
							// PE_MOD_COMPATIBILITY to call onCreate at the end of this function
							luaNotetypeScripts.push(script);
							#end
							doPush = true;
						}
						else if (ext == 'hscript') #end
						{
							var script = FunkinHScript.fromFile(file, notetype);
							hscriptArray.push(script);
							funkyScripts.push(script);
							notetypeScripts.set(notetype, script);
							doPush = true;
						}
						if (doPush)
							break;
					}
				}
			}
		}
		//// load events
		var daEvents = getEvents();
		for (event in daEvents){
			if (!eventPushedMap.exists(event.event))
			{
				eventPushedMap.set(event.event, true);
				firstEventPush(event);
			}
		}

		for (event in eventPushedMap.keys())
		{
			var doPush:Bool = false;
			
			for(file in ["events", #if PE_MOD_COMPATIBILITY "custom_events" #end]){
				var baseScriptFile:String = '$file/$event';
				for (ext in ["hscript", #if LUA_ALLOWED "lua" #end])
				{
					if (doPush)
						break;
					var baseFile = '$baseScriptFile.$ext';
					var files = [#if MODS_ALLOWED Paths.modFolders(baseFile), #end Paths.getPreloadPath(baseFile)];
					for (file in files)
					{
						if (!Paths.exists(file))
							continue;

						#if LUA_ALLOWED
						if (ext == 'lua')
						{
							var script = new FunkinLua(file, event);
							luaArray.push(script);
							funkyScripts.push(script);
							// psych lua scripts work the exact same no matter what type of script they are 
							doPush = true;
						}
						else #end if (ext == 'hscript')
						{
							var script = FunkinHScript.fromFile(file, event);
							hscriptArray.push(script);
							funkyScripts.push(script);
							eventScripts.set(event, script);

							script.call("onLoad");

							doPush = true;
						}

						if (doPush)
							break;
					}
				}
			}
		}

		for (subEvent in daEvents){
			subEvent.strumTime -= eventNoteEarlyTrigger(subEvent);
			eventNotes.push(subEvent);
			eventPushed(subEvent);
		}

		if (eventNotes.length > 1)
			eventNotes.sort(sortByTime);


		speedChanges.sort(svSort);

		for (section in noteData)
		{
			for (songNotes in section.sectionNotes)
			{
				var daStrumTime:Float = songNotes[0];
				var daNoteData:Int = Std.int(songNotes[1] % 4);

				var gottaHitNote:Bool = section.mustHitSection;

				if (songNotes[1]%8 > 3)
					gottaHitNote = !gottaHitNote;

				var oldNote:Note;
				if (allNotes.length > 0)
					oldNote = allNotes[Std.int(allNotes.length - 1)];
				else
					oldNote = null;

				var type:Dynamic = songNotes[3];
				/*
				if (Std.isOfType(songNotes[3], Int))
					type = editors.ChartingState.noteTypeList[songNotes[3]]; //Backward compatibility + compatibility with Week 7 charts;
				*/
				
				var swagNote:Note = new Note(daStrumTime, daNoteData, oldNote, false, gottaHitNote ? arrowSkinbf : arrowSkindad);
				swagNote.realNoteData = songNotes[1];
				swagNote.mustPress = gottaHitNote;
				swagNote.sustainLength = songNotes[2];

				swagNote.gfNote = (section.gfSection && (songNotes[1]<4));
				swagNote.noteType = type;
				swagNote.scrollFactor.set();

				swagNote.ID = allNotes.length;
				modchartObjects.set('note${swagNote.ID}', swagNote);


				if(swagNote.fieldIndex==-1 && swagNote.field==null)
					swagNote.field = swagNote.mustPress ? playerField : dadField;

				if(swagNote.field!=null)
					swagNote.fieldIndex = playfields.members.indexOf(swagNote.field);


				var playfield:PlayField = playfields.members[swagNote.fieldIndex];

				if (playfield!=null){
					playfield.queue(swagNote); // queues the note to be spawned
					allNotes.push(swagNote); // just for the sake of convenience
				}else{
					swagNote.destroy();
					continue;
				}
				oldNote = swagNote;

				var susLength:Float = swagNote.sustainLength / Conductor.stepCrochet;
				var floorSus:Int = Math.round(susLength);
				for (susNote in 0...floorSus)
				{
					var sustainNote:Note = new Note(daStrumTime + Conductor.stepCrochet * (susNote + 1), daNoteData, oldNote, true, gottaHitNote ? arrowSkinbf : arrowSkindad);
					sustainNote.mustPress = gottaHitNote;
					sustainNote.gfNote = swagNote.gfNote;
					sustainNote.noteType = type;
					if (sustainNote==null || !sustainNote.alive)
						break;
					
					sustainNote.scrollFactor.set();

					sustainNote.ID = allNotes.length;
					modchartObjects.set('note${sustainNote.ID}', sustainNote);
					swagNote.tail.push(sustainNote);
					swagNote.unhitTail.push(sustainNote);
					sustainNote.parent = swagNote;
					sustainNote.fieldIndex = swagNote.fieldIndex;
					playfield.queue(sustainNote);
					allNotes.push(sustainNote);

					oldNote = sustainNote;
				}

			}
		}
		allNotes.sort(sortByShit);

		for(fuck in allNotes)
			unspawnNotes.push(fuck);
		
		
		for (field in playfields.members)
			field.clearStackedNotes();


		#if(LUA_ALLOWED && PE_MOD_COMPATIBILITY)
		for (script in luaNotetypeScripts)
			script.call("onCreate");
		luaNotetypeScripts = null;

		for (script in luaNoteskinScripts)
			script.call("onCreate");
		luaNoteskinScripts = null;
		#end
		checkEventNote();
		generatedMusic = true;
	}

	// everything returned here gets preloaded by the preloader up-top ^
	function preloadEvent(event:EventNote):Array<AssetPreload>{
		var preload:Array<AssetPreload> = [];

		switch(event.event){
			case "Change Character":
				return Character.returnCharacterPreload(event.value2);
		}

		return preload;
	}

	public function getNoteInitialTime(time:Float)
	{
		var event:SpeedEvent = getSV(time);
		return getTimeFromSV(time, event);
	}

	public inline function getTimeFromSV(time:Float, event:SpeedEvent)
		return event.position + (modManager.getBaseVisPosD(time - event.songTime, 1) * event.speed);

	public function getSV(time:Float){
		var event:SpeedEvent = {
			position: 0,
			songTime: 0,
			speed: 1
		};
		for (shit in speedChanges)
		{
			if (shit.songTime <= time && shit.songTime >= shit.songTime)
				event = shit;
		}

		return event;
	}


	public inline function getVisualPosition()
		return getTimeFromSV(Conductor.songPosition, currentSV);
	

	function eventPushed(event:EventNote) {
		switch(event.event){
			case 'Mult SV' | 'Constant SV':
				var speed:Float = 1;
				if(event.event == 'Constant SV'){
					var b = Std.parseFloat(event.value1);
					speed = Math.isNaN(b) ? songSpeed : songSpeed / b;
				}else{
					speed = Std.parseFloat(event.value1);
					if(Math.isNaN(speed))speed = 1;
				}

				speedChanges.sort(svSort);
				speedChanges.push({
					position: getNoteInitialTime(event.strumTime),
					songTime: event.strumTime,
					speed: speed
				});
				
			case 'Change Character':
				var charType:Int = 0;
				switch(event.value1.toLowerCase()) {
					case 'gf' | 'girlfriend' | '1':
						charType = 2;
					case 'dad' | 'opponent' | '0':
						charType = 1;
					default:
						charType = Std.parseInt(event.value1);
						if(Math.isNaN(charType)) charType = 0;
				}
				
				trace(event.value2, charType);

				addCharacterToList(event.value2, charType);
			default:
				if (eventScripts.exists(event.event))
				{
					var eventScript:FunkinScript = eventScripts.get(event.event);

					callScript(eventScript, "onPush", [event]);
				}

		}
	}

	function firstNotePush(type:String){
		switch(type){
			default:
				if (notetypeScripts.exists(type))
				{
					callScript(notetypeScripts.get(type), "onLoad", []);
				}
		}
	}

	function firstEventPush(event:EventNote){
		switch (event.event)
		{
			default:
				// should PROBABLY turn this into a function, callEventScript(eventNote, "func") or something, idk
				if (eventScripts.exists(event.event))
				{
					var eventScript:FunkinScript = eventScripts.get(event.event);

					callScript(eventScript, "onLoad", [event]);
				}
		}
	}

	public function optionsChanged(options:Array<String>){
		if (options.length < 1)
			return;

		for(note in allNotes)
			note.updateColours();

		hud.changedOptions(options);

		if(options.contains("gradeSet"))
			ratingStuff = Highscore.grades.get(ClientPrefs.gradeSet);

		callOnScripts('optionsChanged', [options]);

		var reBind:Bool = false;
		for(opt in options){
			if(opt.startsWith("bind")){
				reBind = true;
				break;
			}
		}

		if (!ClientPrefs.coloredCombos)
			comboColor = 0xFFFFFFFF;

		remove(ratingTxtGroup);
		if (ClientPrefs.etternaHUD != "ITG")
			remove(comboNumGroup);
		else
			remove(comboNumTxt);
		remove(timingTxt);
		if(ClientPrefs.judgeBehind){
			insert(members.indexOf(notefields) - 1, timingTxt);
			if (ClientPrefs.etternaHUD != "ITG"){
				insert(members.indexOf(timingTxt) - 1, comboNumGroup);
				insert(members.indexOf(comboNumGroup) - 1, ratingTxtGroup);
			}
			else {
				insert(members.indexOf(timingTxt) - 1, comboNumTxt);
				insert(members.indexOf(comboNumTxt) - 1, ratingTxtGroup);
			}
		}else{
			insert(members.indexOf(notefields) + 1, timingTxt);
			if (ClientPrefs.etternaHUD != "ITG"){
				insert(members.indexOf(timingTxt) + 1, comboNumGroup);
				insert(members.indexOf(comboNumGroup) + 1, ratingTxtGroup);
			}
			else {
				insert(members.indexOf(timingTxt) + 1, comboNumTxt);
				insert(members.indexOf(comboNumTxt) + 1, ratingTxtGroup);
			}
		}

		botplayTxt.y = (ClientPrefs.downScroll ? FlxG.height - 44 : 19) + 15 + (ClientPrefs.downScroll ? -78 : 55);

		for(field in playfields){
			field.noteField.optimizeHolds = ClientPrefs.optimizeHolds;
			field.noteField.drawDistMod = ClientPrefs.drawDistanceModifier;
			field.noteField.holdSubdivisions = Std.int(ClientPrefs.holdSubdivs) + 1;
		}

		if(reBind){
			debugKeysChart = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
			debugKeysCharacter = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_2'));
			debugKeysBotplay = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('botplay'));

			keysArray = [
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_left')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_down')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_up')),
				ClientPrefs.copyKey(ClientPrefs.keyBinds.get('note_right'))
			];

			// unpress everything
			for (field in playfields.members)
			{
				if (field.inControl && !field.autoPlayed && field.isPlayer)
				{
					for (idx in 0...field.keysPressed.length)
						field.keysPressed[idx] = false;

					for (obj in field.strumNotes)
					{
							obj.playAnim("static");
							obj.resetAnim = 0;
					}
				}
			}
		}
	}

	override function draw(){
		camStageUnderlay.bgColor.alphaFloat = ClientPrefs.stageOpacity;
		super.draw();
	}

	function eventNoteEarlyTrigger(event:EventNote):Float {
		var returnedValue:Float = 0;
		var currentRV:Float = callOnAllScripts('eventEarlyTrigger', [event.event, event.value1, event.value2]);

		if (eventScripts.exists(event.event)){
			var eventScript:FunkinScript = eventScripts.get(event.event);
			returnedValue = callScript(eventScript, "getOffset", [event]);
		}
		if(currentRV!=0 && returnedValue==0)returnedValue = currentRV;

		if(returnedValue != 0)
			return returnedValue;

		switch(event.event) {
			case 'Kill Henchmen': //Better timing so that the kill sound matches the beat intended
				return 280; //Plays 280ms before the actual position
		}
		return 0;
	}

	function sortByShit(Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	function sortByOrderNote(wat:Int, Obj1:Note, Obj2:Note):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.zIndex, Obj2.zIndex);
	}

	function sortByOrderStrumNote(wat:Int, Obj1:StrumNote, Obj2:StrumNote):Int
	{
		return FlxSort.byValues(FlxSort.DESCENDING, Obj1.zIndex, Obj2.zIndex);
	}

	function sortByTime(Obj1:EventNote, Obj2:EventNote):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.strumTime, Obj2.strumTime);
	}

	
	function svSort(Obj1:SpeedEvent, Obj2:SpeedEvent):Int
	{
		return FlxSort.byValues(FlxSort.ASCENDING, Obj1.songTime, Obj2.songTime);
	}

	override function openSubState(SubState:FlxSubState)
	{
		if (paused)
		{
			#if (VIDEOS_ALLOWED)
			if (videoSprite != null)
			{
				if (videoSprite.alive)
					videoSprite.bitmap.pause();
			}
			#end

			if (inst != null)
			{
				inst.pause();
				vocals.pause();
				for (track in tracks)
					track.pause();
			}

			if (startTimer != null && !startTimer.finished)
				startTimer.active = false;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = false;
			if (songSpeedTween != null)
				songSpeedTween.active = false;


			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = false;
				}
			}

			for (tween in modchartTweens) {
				tween.active = false;
			}
			for (timer in modchartTimers) {
				timer.active = false;
			}
		}

		super.openSubState(SubState);
	}

	override function closeSubState()
	{
		if (paused)
		{
			#if (VIDEOS_ALLOWED)
			if (videoSprite != null)
			{
				if (videoSprite.alive)
					videoSprite.bitmap.resume();
			}
			#end
			if (inst != null && !startingSong)
				resyncVocals();

			if (startTimer != null && !startTimer.finished)
				startTimer.active = true;
			if (finishTimer != null && !finishTimer.finished)
				finishTimer.active = true;
			if (songSpeedTween != null)
				songSpeedTween.active = true;

			var chars:Array<Character> = [boyfriend, gf, dad];
			for (char in chars) {
				if(char != null && char.colorTween != null) {
					char.colorTween.active = true;
				}
			}

			for (tween in modchartTweens) {
				tween.active = true;
			}
			for (timer in modchartTimers) {
				timer.active = true;
			}
			paused = false;
			callOnScripts('onResume');

			hud.alpha = ClientPrefs.hudOpacity;


			#if discord_rpc
			if (startTimer != null && startTimer.finished)
			{
				DiscordClient.changePresence(detailsText, SONG.song, Paths.formatToSongPath(SONG.song), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song, Paths.formatToSongPath(SONG.song));
			}
			#end
		}

		super.closeSubState();
	}

	override public function onFocus():Void
	{
		#if discord_rpc
		if (health > 0 && !paused)
		{
			if (Conductor.songPosition > 0.0)
			{
				DiscordClient.changePresence(detailsText, SONG.song, Paths.formatToSongPath(SONG.song), true, songLength - Conductor.songPosition - ClientPrefs.noteOffset);
			}
			else
			{
				DiscordClient.changePresence(detailsText, SONG.song, Paths.formatToSongPath(SONG.song));
			}
		}
		#end

		super.onFocus();
	}

	override public function onFocusLost():Void
	{
		#if discord_rpc
		if (health > 0)
			DiscordClient.changePresence(detailsPausedText, SONG.song, Paths.formatToSongPath(SONG.song));
		#end

		super.onFocusLost();
	}


	// good to call this whenever you make a playfield
	public function initPlayfield(field:PlayField){
		notefields.add(field.noteField);

		field.judgeManager = judgeManager;

		field.noteRemoved.add((note:Note, field:PlayField) -> {
			if(modchartObjects.exists('note${note.ID}'))modchartObjects.remove('note${note.ID}');
			allNotes.remove(note);
			unspawnNotes.remove(note);
			notes.remove(note);
		});
		field.noteMissed.add((daNote:Note, field:PlayField) -> {
			if (field.isPlayer && !field.autoPlayed && !daNote.ignoreNote && !endingSong && (daNote.tooLate || !daNote.wasGoodHit))
				noteMiss(daNote, field);

		});
		field.noteSpawned.add((dunceNote:Note, field:PlayField) -> {
			callOnHScripts('onSpawnNote', [dunceNote]);
			#if LUA_ALLOWED
			callOnLuas('onSpawnNote', [
				allNotes.indexOf(dunceNote),
				dunceNote.noteData,
				dunceNote.noteType,
				dunceNote.isSustainNote,
				dunceNote.strumTime
			]);
			#end

			notes.add(dunceNote);
			var index:Int = unspawnNotes.indexOf(dunceNote);
			unspawnNotes.splice(index, 1);

			callOnHScripts('onSpawnNotePost', [dunceNote]);
			if (dunceNote.noteScript != null)
			{
				var script:FunkinScript = dunceNote.noteScript;

				callScript(script, "postSpawnNote", [dunceNote]);
			}
		});
	}

	function resyncVocals():Void
	{
		if(finishTimer != null || transitioning || isDead) return;

		if(showDebugTraces)
			trace("resync vocals!!");
		vocals.pause();
		for (track in tracks)
			track.pause();

		inst.play();
		Conductor.songPosition = inst.time;

		vocals.time = vocalsEnded ? vocals.length : Conductor.songPosition;
		vocals.play();
		for (track in tracks){
			track.time = Conductor.songPosition;
			track.play();
		}
	}

	public var paused:Bool = false;
	public var canReset:Bool = true;
	var startedCountdown:Bool = false;
	var canPause:Bool = true;
	var resyncTimer:Float = 0;
	var prevNoteCount:Int = 0;

	override public function update(elapsed:Float)
	{
		for(field in playfields)
			field.noteField.songSpeed = songSpeed;


		setOnScripts('curDecStep', curDecStep);
		setOnScripts('curDecBeat', curDecBeat);
		/*
		for (key => script in notetypeScripts)
			script.call("onUpdate", [elapsed]); 

		#if(LUA_ALLOWED && PE_MOD_COMPATIBILITY)
		for (key => script in eventScripts)
			script.call("onUpdate", [elapsed]);
		*/

		callOnScripts('onUpdate', [elapsed]);

		if (inst.playing && !inCutscene && health > healthDrain)
		{
			health -= healthDrain * (elapsed / (1/60));
		}

		if(!inCutscene) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 2.4 * cameraSpeed, 0, 1);

			var xOff:Float = 0;
			var yOff:Float = 0;

			if (ClientPrefs.directionalCam && focusedChar != null){
				xOff = focusedChar.camOffX;
				yOff = focusedChar.camOffY;
			}

			var currentCameraPoint = cameraPoints[cameraPoints.length-1];
			if (currentCameraPoint != null)
				camFollow.copyFrom(currentCameraPoint);

			camFollowPos.setPosition(
				FlxMath.lerp(camFollowPos.x, camFollow.x + xOff, lerpVal),
				FlxMath.lerp(camFollowPos.y, camFollow.y + yOff, lerpVal)
			);

			if (!startingSong
				&& !endingSong
				&& boyfriend != null
				&& boyfriend.animation.curAnim != null && boyfriend.animation.curAnim.name.startsWith('idle')) {
				boyfriendIdleTime += elapsed;
				if(boyfriendIdleTime >= 0.15) { // Kind of a mercy thing for making the achievement easier to get as it's apparently frustrating to some playerss
					boyfriendIdled = true;
				}
			} else {
				boyfriendIdleTime = 0;
			}
		}

		for (key => script in notetypeScripts)
			script.call("update", [elapsed]);

		for (key => script in eventScripts)
			eventScripts.get(key).call("update", [elapsed]);

		callOnHScripts('update', [elapsed]);



	/* 	for (shit in speedChanges)
		{
			if (shit.songTime <= Conductor.songPosition)
				event = shit;
			else
				break;
		} */
/* 		if(speedChanges.length > 1){
			if(speedChanges[1].songTime < Conductor.songPosition)
				while (speedChanges.length > 1 && speedChanges[1].songTime < Conductor.songPosition)
					speedChanges.shift();
		} */
		

		if (camZooming)
		{
			var lerpVal = CoolUtil.boundTo(1 - (elapsed * 3.125 * camZoomingDecay), 0, 1);

			camGame.zoom = FlxMath.lerp(
				1 * defaultCamZoom,
				camGame.zoom,
				lerpVal
			);
			camHUD.zoom = FlxMath.lerp(
				1,
				camHUD.zoom,
				lerpVal
			);

		}
		camOverlay.zoom = camHUD.zoom;
		camOverlay.angle = camHUD.angle;

		if(noteHits.length > 0){
			while (noteHits.length > 0 && (noteHits[0] + 2000) < Conductor.songPosition)
				noteHits.shift();
		}

		nps = Math.floor(noteHits.length / 2);
		FlxG.watch.addQuick("notes per second", nps);
		stats.nps = nps;
		if(stats.npsPeak < nps)
			stats.npsPeak = nps;

		if (ClientPrefs.downScroll)
		{
			if (chartingMode)
				Overlay.offset.y = 50;
			else
				Overlay.offset.y = 0;
		}
		
		if (!endingSong){
			//// time travel
			if (!startingSong #if !debug && chartingMode #end){
				if (FlxG.keys.justPressed.ONE) {
					KillNotes();
					inst.onComplete();
				}else if(FlxG.keys.justPressed.TWO) { //Go 10 seconds into the future :O
					setSongTime(Conductor.songPosition + 10000);
					clearNotesBefore(Conductor.songPosition);
				}
			}

			//// editors
			if (FlxG.keys.anyJustPressed(debugKeysChart))
				openChartEditor();

			if (FlxG.keys.anyJustPressed(debugKeysCharacter))
			{
				persistentUpdate = false;
				paused = true;
				cancelMusicFadeTween();
				MusicBeatState.switchState(new CharacterEditorState(SONG.player2));
			}

			if (FlxG.keys.anyJustPressed(debugKeysBotplay))
				cpuControlled = !cpuControlled;
			

			// RESET = Quick Game Over Screen
			if (controls.RESET && canReset && !inCutscene && startedCountdown)
				health = 0;
			
			doDeathCheck();

			if (controls.PAUSE)
				pause();
		}

		////
		if (startedCountdown)
		{
			var addition:Float = elapsed * 1000;
			if(inst.playing){
				if(inst.time == Conductor.lastSongPos)
					resyncTimer += addition;
				else
					resyncTimer = 0;
				
				Conductor.songPosition = inst.time + resyncTimer;
				Conductor.lastSongPos = inst.time;
				if (Math.abs(vocals.time - inst.time) > 25 && !vocalsEnded){
					resyncVocals();
				}
				
			}else
				Conductor.songPosition += addition;
		}

		if (startingSong)
		{
			if (startedCountdown && Conductor.songPosition >= 0)
				startSong();
			else if(!startedCountdown)
				Conductor.songPosition = -Conductor.crochet * 5;
		}

		FlxG.watch.addQuick("beatShit", curBeat);
		FlxG.watch.addQuick("stepShit", curStep);

		currentSV = getSV(Conductor.songPosition);
		Conductor.visualPosition = getVisualPosition();
		FlxG.watch.addQuick("visualPos", Conductor.visualPosition);

		checkEventNote();
		
		botplayTxt.exists = PlayState.instance.cpuControlled;

		/*if(midScroll){
			for(field in notefields.members){
				if(field.field==null)continue;
				if(field.field.isPlayer){
					if(field.alpha < 1){
						field.alpha += 0.1 * elapsed;
						if(field.alpha>1)field.alpha=1;
					}
				}else{
					if(field.alpha > 0){
						field.alpha -= 0.1 * elapsed;
						if(field.alpha<0)field.alpha=0;
					}
				}
			}
		}*/
		super.update(elapsed);
		modManager.updateTimeline(curDecStep);
		modManager.update(elapsed);

		if (generatedMusic)
		{
			if (!inCutscene){
				keyShit();
			}

			for(field in playfields){
				if(field.isPlayer){
					for(char in field.characters){
						if (char.animation.curAnim != null
							&& char.holdTimer > Conductor.stepCrochet * (0.0011 / inst.pitch) * char.singDuration
								&& char.animation.curAnim.name.startsWith('sing')
								&& !char.animation.curAnim.name.endsWith('miss')
								&& (char.idleWhenHold || !pressedGameplayKeys.contains(true)))
							char .dance();

					}
				}
			}
		}
		

		setOnScripts('cameraX', camFollowPos.x);
		setOnScripts('cameraY', camFollowPos.y);
		callOnScripts('onUpdatePost', [elapsed]);
	}

	function openChartEditor()
	{
		persistentUpdate = false;
		paused = true;
		cancelMusicFadeTween();
		MusicBeatState.switchState(new ChartingState());

		#if discord_rpc
		DiscordClient.changePresence("Chart Editor", null, null, true);
		#end
	}

	public var isDead:Bool = false; //Don't mess with this on Lua!!!
	function doDeathCheck(?skipHealthCheck:Bool = false) {
		if (
			(
				(skipHealthCheck && instakillOnMiss)
				|| health <= 0
			)
			&& !practiceMode
			&& !isDead
		)
		{
			var ret:Dynamic = callOnScripts('onGameOver');
			if(ret != Globals.Function_Stop) {
				boyfriend.stunned = true;
				deathCounter++;

				paused = true;

				vocals.stop();
				inst.stop();
				for (track in tracks)
					track.stop();

				for (tween in modchartTweens)
					tween.active = true;
				for (timer in modchartTimers)
					timer.active = true;

				persistentUpdate = false;
				persistentDraw = false;

				if(instaRespawn){
					isDead = true;
					MusicBeatState.resetState(true);
					return true;
				}else{
					var char = playOpponent ? dad : boyfriend;

					inst.stop();
					vocals.stop();

					openSubState(new GameOverSubstate(
						char.getScreenPosition().x - char.positionArray[0],
						char.getScreenPosition().y - char.positionArray[1],
						camFollowPos.x,
						camFollowPos.y,
						char.isPlayer
					));
				}

				#if discord_rpc
				// Game Over doesn't get his own variable because it's only used here
				DiscordClient.changePresence("Game Over - " + detailsText, SONG.song, Paths.formatToSongPath(SONG.song));
				#end
				isDead = true;
				return true;
			}
		}
		return false;
	}

	public function checkEventNote() {
		while(eventNotes.length > 0) {
			var daEvent = eventNotes[0];

			if(Conductor.songPosition < daEvent.strumTime)
				break;

			var value1:Null<String> = daEvent.value1;
			if(value1 == null) value1 = '';

			var value2:Null<String> = daEvent.value2;
			if(value2 == null) value2 = '';

			triggerEventNote(daEvent.event, value1, value2);
			eventNotes.shift();
		}
	}

	public function getControl(key:String) {
		var pressed:Bool = Reflect.getProperty(controls, key);
		//trace('Control result: ' + pressed);
		return pressed;
	}

	function changeCharacter(name:String, charType:Int){
		switch(charType) {
			case 0:
				if(boyfriend.curCharacter != name) {
					trace("turned bf into " + name);
					var shiftFocus:Bool = focusedChar==boyfriend;
					var oldChar = boyfriend;
					if(!boyfriendMap.exists(name)) {
						addCharacterToList(name, charType);
					}

					var lastAlpha:Float = boyfriend.alpha;
					boyfriend.alpha = 0.00001;
					boyfriend = boyfriendMap.get(name);
					boyfriend.alpha = lastAlpha;
					if(shiftFocus)focusedChar=boyfriend;
					hud.iconP1.changeIcon(boyfriend.healthIcon);
				}
				setOnScripts('boyfriendName', boyfriend.curCharacter);

			case 1:
				if(dad.curCharacter != name) {
					trace("turned dad into " + name);
					var shiftFocus:Bool = focusedChar==dad;
					var oldChar = dad;
					if(!dadMap.exists(name)) {
						addCharacterToList(name, charType);
					}

					var wasGf:Bool = dad.curCharacter.startsWith('gf');
					var lastAlpha:Float = dad.alpha;
					dad.alpha = 0.00001;
					dad = dadMap.get(name);
					if(!dad.curCharacter.startsWith('gf')) {
						if(wasGf && gf != null) {
							gf.visible = true;
						}
					} else if(gf != null) {
						gf.visible = false;
					}
					if(shiftFocus)focusedChar=dad;
					dad.alpha = lastAlpha;
					hud.iconP2.changeIcon(dad.healthIcon);
				}
				setOnScripts('dadName', dad.curCharacter);

			case 2:
				if(gf != null)
				{
					if(gf.curCharacter != name)
					{
						trace("turned gf into " + name);
						var shiftFocus:Bool = focusedChar==gf;
						var oldChar = gf;
						if(!gfMap.exists(name))
						{
							addCharacterToList(name, charType);
						}

						var lastAlpha:Float = gf.alpha;
						gf.alpha = 0.00001;
						gf = gfMap.get(name);
						gf.alpha = lastAlpha;
						if(shiftFocus)focusedChar=gf;
					}
					setOnScripts('gfName', gf.curCharacter);
				}
		}
		reloadHealthBarColors();
	}

	public function triggerEventNote(eventName:String = "", value1:String = "", value2:String = "") {
		if(showDebugTraces)
			trace('Event: ' + eventName + ', Value 1: ' + value1 + ', Value 2: ' + value2 + ', at Time: ' + Conductor.songPosition);

		switch(eventName) {
			case 'Change Focus':
				switch(value1.toLowerCase().trim()){
					case 'dad' | 'opponent':
						if (callOnScripts('onMoveCamera', ["dad"]) != Globals.Function_Stop)
							moveCamera(dad);
					case 'gf':
						if (callOnScripts('onMoveCamera', ["gf"]) != Globals.Function_Stop)
							moveCamera(gf);
					default:
						if (callOnScripts('onMoveCamera', ["bf"]) != Globals.Function_Stop)
							moveCamera(boyfriend);
				}
			case 'Game Flash':
				var dur:Float = Std.parseFloat(value2);
				if(Math.isNaN(dur)) dur = 0.5;

				var col:Null<FlxColor> = FlxColor.fromString(value1);
				if (col == null) col = 0xFFFFFFFF;

				FlxG.camera.flash(col, dur, null, true);
			case 'Hey!':
				var value:Int = 2;
				switch(value1.toLowerCase().trim()) {
					case 'bf' | 'boyfriend' | '0':
						value = 0;
					case 'gf' | 'girlfriend' | '1':
						value = 1;
				}

				var time:Float = Std.parseFloat(value2);
				if(Math.isNaN(time) || time <= 0) time = 0.6;

				if(value != 0) {
					if(dad.curCharacter.startsWith('gf')) { //Tutorial GF is actually Dad! The GF is an imposter!! ding ding ding ding ding ding ding, dindinding, end my suffering
						dad.playAnim('cheer', true);
						dad.specialAnim = true;
						dad.heyTimer = time;
					} else if (gf != null) {
						gf.playAnim('cheer', true);
						gf.specialAnim = true;
						gf.heyTimer = time;
					}
				}
				if(value != 1) {
					boyfriend.playAnim('hey', true);
					boyfriend.specialAnim = true;
					boyfriend.heyTimer = time;
				}

			case 'Set GF Speed':
				var value:Int = Std.parseInt(value1);
				if(Math.isNaN(value) || value < 1) value = 1;
				gfSpeed = value;
			case 'Add Camera Zoom':
				if (ClientPrefs.camZoomP > 0) {
					var camZoom:Float = Std.parseFloat(value1);
					var hudZoom:Float = Std.parseFloat(value2);
					if(Math.isNaN(camZoom)) camZoom = 0.015;
					if(Math.isNaN(hudZoom)) hudZoom = 0.03;

					if(FlxG.camera.zoom < (defaultCamZoom * 1.35))
						FlxG.camera.zoom += camZoom * ClientPrefs.camZoomP;
					camHUD.zoom += hudZoom * ClientPrefs.camZoomP;
				}
			case 'Play Animation':
				//trace('Anim to play: ' + value1);
				var char:Character = dad;
				switch(value2.toLowerCase().trim()) {
					case 'bf' | 'boyfriend':
						char = boyfriend;
					case 'gf' | 'girlfriend':
						char = gf;
					default:
						var val2:Int = Std.parseInt(value2);
						if(Math.isNaN(val2)) val2 = 0;

						switch(val2) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null){
					char.playAnim(value1, true);
					char.specialAnim = true;
				}


			case 'Camera Follow Pos':
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);

				var isNan1 = Math.isNaN(val1);
				var isNan2 = Math.isNaN(val2);

				if (isNan1 && isNan2) 
					cameraPoints.remove(customCamera);
				else{
					if (!isNan1) customCamera.x = val1;
					if (!isNan2) customCamera.y = val2;
					addCameraPoint(customCamera);
				}

			case 'Alt Idle Animation':
				var char:Character = dad;
				switch(value1.toLowerCase()) {
					case 'gf' | 'girlfriend':
						char = gf;
					case 'boyfriend' | 'bf':
						char = boyfriend;
					default:
						var val:Int = Std.parseInt(value1);
						if(Math.isNaN(val)) val = 0;

						switch(val) {
							case 1: char = boyfriend;
							case 2: char = gf;
						}
				}

				if (char != null)
				{
					char.idleSuffix = value2;
					char.recalculateDanceIdle();
				}

			case 'Screen Shake':
				var valuesArray:Array<String> = [value1, value2];
				var targetsArray:Array<FlxCamera> = [camGame, camHUD];
				for (i in 0...targetsArray.length) {
					var split:Array<String> = valuesArray[i].split(',');
					var duration:Float = 0;
					var intensity:Float = 0;
					if(split[0] != null) duration = Std.parseFloat(split[0].trim());
					if(split[1] != null) intensity = Std.parseFloat(split[1].trim());
					if(Math.isNaN(duration)) duration = 0;
					if(Math.isNaN(intensity)) intensity = 0;

					if(duration > 0 && intensity != 0) {
						targetsArray[i].shake(intensity, duration);
					}
				}

			case 'Change Character':
				var charType:Int = 0;
				switch(value1.toLowerCase().trim()) {
					case 'gf' | 'girlfriend':
						charType = 2;
					case 'dad' | 'opponent':
						charType = 1;
					default:
						charType = Std.parseInt(value1);
						if(Math.isNaN(charType)) charType = 0;
				}

				var curChar:Character = boyfriend;
				switch(charType){
					case 2:
						curChar = gf;
					case 1:
						curChar = dad;
					case 0:
						curChar = boyfriend;
				}

				var newCharacter:String = value2;
				var anim:String = '';
				var frame:Int = 0;
				if(newCharacter.startsWith(curChar.curCharacter) || curChar.curCharacter.startsWith(newCharacter)){
					if(curChar.animation!=null && curChar.animation.curAnim!=null){
						anim = curChar.animation.curAnim.name;
						frame = curChar.animation.curAnim.curFrame;
					}
				}

				trace(value2, charType);

				changeCharacter(value2, charType);
				if(anim!=''){
					var char:Character = boyfriend;
					switch(charType){
						case 2:
							char = gf;
						case 1:
							char = dad;
						case 0:
							char = boyfriend;
					}

					if(char.animation.getByName(anim)!=null){
						char.playAnim(anim, true);
						char.animation.curAnim.curFrame = frame;
					}
				}

			case 'Change Scroll Speed':
				if (songSpeedType == "constant")
					return;
				var val1:Float = Std.parseFloat(value1);
				var val2:Float = Std.parseFloat(value2);
				if(Math.isNaN(val1)) val1 = 1;
				if(Math.isNaN(val2)) val2 = 0;

				var newValue:Float = SONG.speed * ClientPrefs.getGameplaySetting('scrollspeed', 1) * val1;

				if(val2 <= 0)
				{
					songSpeed = newValue;
				}
				else
				{
					songSpeedTween = FlxTween.tween(this, {songSpeed: newValue}, val2, {ease: FlxEase.linear, onComplete:
						function (twn:FlxTween)
						{
							songSpeedTween = null;
						}
					});
				}

			case 'Set Property':
				var value2:Dynamic = value2;
				switch (value2){
					case "true":
						value2 = true;
					case "false":
						value2 = false;
				}

				var killMe:Array<String> = value1.split('.');
				try{
					if(killMe.length > 1)
						FunkinLua.setVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe, true, true), killMe[killMe.length - 1], value2);
					else
						FunkinLua.setVarInArray(this, value1, value2);
				}catch (e:haxe.Exception){

				}
		}
		callOnScripts('onEvent', [eventName, value1, value2]);
		if(eventScripts.exists(eventName)){
			var script = eventScripts.get(eventName);
			callScript(script, "onTrigger", [value1, value2]);
		}
	}

	//// Kinda rewrote the camera shit so that its 'easier' to mod
	public function moveCameraSection(section:SwagSection)
	{
		if (section.gfSection && gf != null){
			if (callOnScripts('onMoveCamera', ["gf"]) != Globals.Function_Stop)
				moveCamera(gf);
		}else if (section.mustHitSection){
			if (callOnScripts('onMoveCamera', ["bf"]) != Globals.Function_Stop)
				moveCamera(boyfriend);
		}else{
			if (callOnScripts('onMoveCamera', ["dad"]) != Globals.Function_Stop)
				moveCamera(dad);
		}
	}
	public function moveCamera(?char:Character)
	{
		focusedChar = char;
		if (char != null){
			var cam = char.getCamera();
			sectionCamera.set(cam[0], cam[1]);
		}
	}

	static public function getCharacterCamera(char:Character)return char.getCamera();
	

	public function finishSong(?ignoreNoteOffset:Bool = false):Void
	{
		var finishCallback:Void->Void = endSong; //In case you want to change it in a specific song.

		hud.updateTime = false;

		inst.volume = 0;
		inst.pause();

		vocals.volume = 0;
		vocals.pause();

		for (track in tracks){
			track.volume = 0;
			track.pause();
		}

		////
		if(ClientPrefs.noteOffset <= 0 || ignoreNoteOffset) {
			finishCallback();
		} else {
			finishTimer = new FlxTimer().start(ClientPrefs.noteOffset / 1000, function(tmr:FlxTimer) {
				finishCallback();
			});
		}
	}

	public static function gotoMenus()
	{
		FlxTransitionableState.skipNextTransIn = false;
		CustomFadeTransition.nextCamera = null;

		MusicBeatState.switchState(isStoryMode ? new StoryMenuState() : new PsychFreeplayState());

		deathCounter = 0;
		seenCutscene = false;
		chartingMode = false;

		if (instance != null)
			instance.cancelMusicFadeTween(); // Doesn't do anything now

		MusicBeatState.playMenuMusic(1, true);
	}

	public var transitioning = false;
	public function endSong():Void
	{
		
		//Should kill you if you tried to cheat
		if(!startingSong) {
			/*for (daNote in allNotes) {
				if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
					health -= 0.05 * healthLoss;
				}
			}*/
			for(field in playfields.members){
				if(field.isPlayer){
					for(daNote in field.spawnedNotes){
						if(daNote.strumTime < songLength - Conductor.safeZoneOffset) {
							health -= 0.05 * healthLoss;
						}
					}
				}
			}

			if(doDeathCheck())
				return;
		}

		hud.songEnding();
		hud.updateTime = false;
		canPause = false;
		endingSong = true;
		camZooming = false;
		inCutscene = false;

		deathCounter = 0;
		seenCutscene = false;

		#if ACHIEVEMENTS_ALLOWED
		if(achievementObj != null) {
			return;
		} else {
			var achieve:String = checkForAchievement(['week1_nomiss', 'week2_nomiss', 'week3_nomiss', 'week4_nomiss',
				'week5_nomiss', 'week6_nomiss', 'ur_bad',
				'ur_good', 'hype', 'two_keys', 'toastie', 'debugger']);

			if(achieve != null) {
				startAchievement(achieve);
				return;
			}
		}
		#end

		#if (LUA_ALLOWED || hscript)
		var ret:Dynamic = callOnScripts('onEndSong');
		#else
		var ret:Dynamic = Globals.Function_Continue;
		#end

		if(ret != Globals.Function_Stop && !transitioning) {
			// Save song score and rating.
			if (SONG.validScore){
				var percent:Float = stats.ratingPercent;

				if(Math.isNaN(percent)) percent = 0;

				// TODO: different score saving for Wife3
				// TODO: Save more stats?

				if (!playOpponent && saveScore && ratingFC!='Fail')
					Highscore.saveScore(SONG.song, stats.score, difficulty, percent, stats.totalNotesHit);
			}


			transitioning = true;

			if (chartingMode)
			{
				openChartEditor();
				return;
			}

			if (isStoryMode)
			{
				// TODO: add a modcharted variable which songs w/ modcharts should set to true, then make it so if modcharts are disabled the score wont get added
				// same check should be in the saveScore check above too
				if (ratingFC != 'Fail')
					campaignScore += stats.score;
				campaignMisses += songMisses;

				storyPlaylist.remove(storyPlaylist[0]);

				if (storyPlaylist.length <= 0)
				{
					//// WEEK END

					// Save week score
					if (ChapterData.curChapter != null && !playOpponent){
						if(!ClientPrefs.getGameplaySetting('practice', false) && !ClientPrefs.getGameplaySetting('botplay', false)) {
							Highscore.saveWeekScore(ChapterData.curChapter.directory, campaignScore, difficulty);
							
							StoryMenuState.weekCompleted.set(ChapterData.curChapter.directory, true);
							FlxG.save.data.weekCompleted = StoryMenuState.weekCompleted;

							FlxG.save.flush();
						}
					}

					if(FlxTransitionableState.skipNextTransIn)
						CustomFadeTransition.nextCamera = null;

					cancelMusicFadeTween();

					function gotoMenus(){
						MusicBeatState.switchState(new StoryMenuState());
						MusicBeatState.playMenuMusic(1, true);
					}

					#if VIDEOS_ALLOWED
					var videoPath:String = Paths.video('${Paths.formatToSongPath(SONG.song)}-end');
					if (Paths.exists(videoPath))
						MusicBeatState.switchState(new VideoPlayerState(videoPath, gotoMenus));
					else
						gotoMenus();
					#else
					gotoMenus();
					#end

					changedDifficulty = false;
				}
				else
				{
					var difficulty:String = Difficulty.getFilePath();
					var nextSong = PlayState.storyPlaylist[0];
					trace('LOADING NEXT SONG: $nextSong');

					prevCamFollow = camFollow;
					prevCamFollowPos = camFollowPos;

					cancelMusicFadeTween();
					inst.stop();

					function playNextSong(){
						PlayState.SONG = Song.loadFromJson(nextSong  + difficulty, nextSong);
						LoadingState.loadAndSwitchState(new PlayState());
					}

					#if VIDEOS_ALLOWED
					var videoPath:String = Paths.video('${Paths.formatToSongPath(nextSong)}');
					if (Paths.exists(videoPath))
						MusicBeatState.switchState(new VideoPlayerState(videoPath, playNextSong));
					else #end
					{
						FlxTransitionableState.skipNextTransIn = true;
						FlxTransitionableState.skipNextTransOut = true;
						playNextSong();
					}
				}
			}
			else
			{
				trace('WENT BACK TO FREEPLAY??');
				cancelMusicFadeTween();

				if(FlxTransitionableState.skipNextTransIn)
					CustomFadeTransition.nextCamera = null;
				
				MusicBeatState.switchState(new PsychFreeplayState());
				MusicBeatState.playMenuMusic(1, true);
				changedDifficulty = false;
			}
		}
	}

	public function KillNotes() {
		while(allNotes.length > 0) {
			var daNote:Note = allNotes[0];
			daNote.active = false;
			daNote.visible = false;

			daNote.kill();
			notes.remove(daNote, true);
			// daNote.destroy();
		}
		allNotes = [];
		unspawnNotes = [];
		for(field in playfields){
			field.clearDeadNotes();
			field.spawnedNotes = [];
			field.noteQueue = [[], [], [], []];
		}

		eventNotes = [];
	}

	var lastJudge:RatingSprite;
	var lastCombos:Array<RatingSprite> = [];
	var lastCombosTxt:Array<RatingText> = [];

	var msNumber = 0;
	var msTotal = 0.0;

	private function displayJudgment(image:String){
		var rating:RatingSprite;
		var time = (Conductor.stepCrochet * 0.001);
		var itgRatingScale:Float = ClientPrefs.etternaHUD == 'ITG' ? 1.4 : 0.7;

		if (ClientPrefs.simpleJudge)
		{
			rating = lastJudge;
			rating.moves = false;
			rating.revive();

			if (rating.tween != null)
			{
				rating.tween.cancel();
				rating.tween.destroy();
			}

			rating.scale.set(itgRatingScale * 1.1, itgRatingScale * 1.1);

			rating.tween = FlxTween.tween(rating.scale, {x: itgRatingScale, y: itgRatingScale}, 0.1, {
				ease: FlxEase.quadOut,
				onComplete: function(tween:FlxTween)
				{
					if (!rating.alive)
						return;
	
					rating.tween = FlxTween.tween(rating.scale, {x: 0, y: 0}, time, {
						startDelay: time * 8,
						ease: FlxEase.quadIn,
						onComplete: function(tween:FlxTween)
						{
							rating.kill();
						}
					});
				}
			});
		}
		else
		{
			rating = ratingTxtGroup.recycle(RatingSprite, RatingSprite.newRating);
			rating.moves = true;
			rating.acceleration.y = 550;
			rating.scale.set(itgRatingScale, itgRatingScale);
			rating.velocity.set(FlxG.random.int(-10, 10), -FlxG.random.int(140, 175));

			rating.alpha = 1;

			rating.tween = FlxTween.tween(rating, {alpha: 0}, 0.2, {
				startDelay: Conductor.crochet * 0.001,
				onComplete: function(wtf)
				{
					rating.kill();
				}
			});
		}

		rating.alpha = ClientPrefs.judgeOpacity;

		rating.visible = showRating;
		if (ClientPrefs.etternaHUD == 'ITG') {
			rating.frames = Paths.getSparrowAtlas('SimplyLoveHud/judgements');
			rating.animation.addByPrefix(image, image, 0);
			rating.animation.play(image);
		} else
			rating.loadGraphic(Paths.image(image));
		rating.updateHitbox();

		rating.screenCenter();
		if (ClientPrefs.etternaHUD == 'ITG') {
			rating.x = 843;
			rating.y = 280 - 80;
		} else {
			rating.x += ClientPrefs.comboOffset[0];
			rating.y -= ClientPrefs.comboOffset[1];
		}

		ratingTxtGroup.remove(rating, true);
		ratingTxtGroup.add(rating);
	}
	var comboColor = 0xFFFFFFFF;

	private function displayCombo(?combo:Int){
		if(combo==null)combo=stats.combo;
		if (ClientPrefs.simpleJudge)
		{
			if (ClientPrefs.etternaHUD != "ITG") {
				for (prevCombo in lastCombos)
				{
					prevCombo.kill();
				}
			} else {
				for (prevCombo in lastCombosTxt)
				{
					prevCombo.kill();
				}
			}
			if (combo == 0)
				return;
		}
		else if (combo > 0 && combo < 10 && combo != 0)
			return;

		var separatedScore:Array<String> = Std.string(Math.abs(combo)).split("");
		while (separatedScore.length < 3)
			separatedScore.unshift("0");
		if(combo < 0)
			separatedScore.unshift("-");

		var daLoop:Int = 0;

		var col;
		col = combo < 0 ? hud.judgeColours.get("miss") : comboColor;
		var numStartX:Float = (FlxG.width - separatedScore.length * 41) * 0.5 + ClientPrefs.comboOffset[2];

		switch (ClientPrefs.etternaHUD) {
			case "ITG":
				var comboScale:Float = 1.2;
				var comboTxt:RatingText = comboNumTxt.recycle(RatingText, RatingText.newNumber);
				comboTxt.setFormat(Paths.font("wendy.ttf"), 60, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				comboTxt.text = Std.string(combo);
				if (combo == 0)
					comboTxt.visible = false;
				else
					comboTxt.visible = true;

				comboTxt.scale.x = comboScale * 1.25;
				comboTxt.updateHitbox();
				comboTxt.scale.y = comboScale * 0.75;

				comboTxt.setPosition(843 + 90, 280 - 10);

				comboTxt.color = col;
				comboTxt.visible = showComboNum;

				comboTxt.ID = daLoop;
				if (comboTxt.tween != null){
					comboTxt.tween.cancel();
					comboTxt.tween.destroy();
				}

				comboNumTxt.remove(comboTxt, true);
				comboNumTxt.add(comboTxt);

				comboTxt.alpha = ClientPrefs.judgeOpacity;
				comboTxt.tween = FlxTween.tween(comboTxt.scale, {x: comboScale, y: comboScale}, 0.2, {ease: FlxEase.circOut});
				lastCombosTxt.push(comboTxt);

				daLoop++;
			default:
				for (i in separatedScore)
				{
					var numScore:RatingSprite = comboNumGroup.recycle(RatingSprite, RatingSprite.newNumber);
					numScore.loadGraphic(Paths.image('num' + (i == "-" ? "neg" : i)));

					if (ClientPrefs.simpleJudge){
						numScore.scale.x = 0.5 * 1.25;
						numScore.updateHitbox();
						numScore.scale.y = 0.5 * 0.75;
					}else{
						numScore.updateHitbox();
					}
					
					numScore.x = numStartX + 41.5 * daLoop;
					numScore.screenCenter(Y);
					numScore.y -= ClientPrefs.comboOffset[3];

					numScore.color = col;
					numScore.visible = showComboNum;

					numScore.ID = daLoop;
					numScore.moves = !ClientPrefs.simpleJudge;
					if (numScore.tween != null){
						numScore.tween.cancel();
						numScore.tween.destroy();
					}

					comboNumGroup.remove(numScore, true);
					comboNumGroup.add(numScore);

					numScore.alpha = ClientPrefs.judgeOpacity;
					if (ClientPrefs.simpleJudge)
					{
						numScore.tween = FlxTween.tween(numScore.scale, {x: 0.5, y: 0.5}, 0.2, {ease: FlxEase.circOut});
						lastCombos.push(numScore);
					}
					else
					{
						numScore.acceleration.y = FlxG.random.int(200, 300);
						numScore.velocity.set(FlxG.random.float(-10, 10), -FlxG.random.int(140, 160));

						numScore.tween = FlxTween.tween(numScore, {alpha: 0}, 0.2, {
							onComplete: function(wtf)
							{
								numScore.kill();
							},
							startDelay: Conductor.crochet * 0.002
						});
					}

					daLoop++;
				}
		}
	}

	private function applyJudgmentData(judgeData:JudgmentData, diff:Float, ?bot:Bool = false, ?show:Bool = true){
		if(judgeData==null){
			trace("you didnt give a valid JudgmentData to applyJudgmentData!");
			return;
		}
		if (!bot)stats.score += Math.floor(judgeData.score * playbackRate);
		health += (judgeData.health * 0.02) * (judgeData.health < 0 ? healthLoss : healthGain);
		songHits++;


		if(ClientPrefs.wife3){
			if (judgeData.wifePoints == null)
				stats.totalNotesHit += Wife3.getAcc(diff);
			else
				stats.totalNotesHit += judgeData.wifePoints;
			stats.totalPlayed += 2;
		}else{
			stats.totalNotesHit += judgeData.accuracy * 0.01;
			stats.totalPlayed++;
		}

		switch(judgeData.comboBehaviour){
			default:
				stats.cbCombo = 0;
				stats.combo++;
			case BREAK:
				breakCombo();
			case IGNORE:
		}

		if (!stats.judgements.exists(judgeData.internalName))
			stats.judgements.set(judgeData.internalName, 0);

		stats.judgements.set(judgeData.internalName, stats.judgements.get(judgeData.internalName) + 1);
		
		RecalculateRating();

		if (ClientPrefs.coloredCombos)
			{
				if (ClientPrefs.etternaHUD == "ITG") {
					if (stats.judgements.get("bad") > 0 || stats.judgements.get("shit") > 0 || stats.comboBreaks > 0)
						comboColor = 0xFFFFFFFF;
					else if (stats.judgements.get("good") > 0)
						comboColor = hud.itgJudgeColours.get("good");
					else if (stats.judgements.get("sick") > 0)
						comboColor = hud.itgJudgeColours.get("sick");
					else if (stats.judgements.get("epic") > 0)
						comboColor = hud.itgJudgeColours.get("epic");
				} else {
					if (stats.judgements.get("bad") > 0 || stats.judgements.get("shit") > 0 || stats.comboBreaks > 0)
						comboColor = 0xFFFFFFFF;
					else if (stats.judgements.get("good") > 0)
						comboColor = hud.judgeColours.get("good");
					else if (stats.judgements.get("sick") > 0)
						comboColor = hud.judgeColours.get("sick");
					else if (stats.judgements.get("epic") > 0)
						comboColor = hud.judgeColours.get("epic");
				}
			}

		if(show){
			if(judgeData.hideJudge!=true)
				displayJudgment(judgeData.internalName);
			if(judgeData.comboBehaviour != IGNORE)
				displayCombo(judgeData.comboBehaviour == BREAK ? (stats.cbCombo > 1 ? -stats.cbCombo : 0) : stats.combo);
		}
	}

	private function applyNoteJudgment(note:Note, bot:Bool = false):Null<JudgmentData>
	{
		if(note.hitResult.judgment == UNJUDGED)return null;
		var judgeData:JudgmentData = judgeManager.judgmentData.get(note.hitResult.judgment);
		if(judgeData==null)return null;

		if (callOnHScripts("preApplyJudgment", [note, judgeData]) == Globals.Function_Stop)
			return null;

		var mutatedJudgeData:Dynamic = callOnHScripts("mutateJudgeData", [note, judgeData]);
		if(mutatedJudgeData != null && mutatedJudgeData != Globals.Function_Continue)
			judgeData = cast mutatedJudgeData; // so you can return your own custom judgements or w/e
		// Note: Be careful while changing values from the judgeData, cause it will also change the judgeData of every other note with the same judgement.
		// You should use Reflect.copy() on your script.

		applyJudgmentData(judgeData, note.hitResult.hitDiff, bot, true);

		callOnHScripts("postApplyJudgment", [note, judgeData]);
		
		return judgeData;
	}

	private function applyJudgment(judge:Judgment, ?diff:Float = 0, ?show:Bool = true)
		applyJudgmentData(judgeManager.judgmentData.get(judge), diff);

	var msJudges = [];

	private function judge(note:Note, field:PlayField=null){
		if (field == null)
			field = getFieldFromNote(note);

		var hitTime = note.hitResult.hitDiff + ClientPrefs.ratingOffset;
		var judgeData:JudgmentData = applyNoteJudgment(note, field.autoPlayed);
		if(judgeData==null)return;

		note.ratingMod = judgeData.accuracy * 0.01;
		note.rating = judgeData.internalName;
		if (note.noteSplashBehaviour == FORCED || judgeData.noteSplash && !note.noteSplashDisabled)
			spawnNoteSplashOnNote(note, field);
		
		msJudges.push({hitTime: hitTime, strumTime: note.strumTime});

		if(ClientPrefs.showMS && (field==null || !field.autoPlayed))
		{
			FlxTween.cancelTweensOf(timingTxt);
			FlxTween.cancelTweensOf(timingTxt.scale);
			
			timingTxt.text = '${FlxMath.roundDecimal(hitTime, 2)}ms';
			timingTxt.screenCenter();
			timingTxt.x += ClientPrefs.comboOffset[4];
			timingTxt.y -= ClientPrefs.comboOffset[5];

			if (ClientPrefs.etternaHUD == "ITG")
				timingTxt.color = hud.itgJudgeColours.get(judgeData.internalName);
			else
				timingTxt.color = hud.judgeColours.get(judgeData.internalName);

			timingTxt.visible = true;
			timingTxt.alpha = ClientPrefs.judgeOpacity;
			timingTxt.y -= 8;
			timingTxt.scale.set(1, 1);
			
			var time = (Conductor.stepCrochet * 0.001);
			FlxTween.tween(timingTxt, 
				{y: timingTxt.y + 8}, 
				0.1,
				{onComplete: function(_){
					if (ClientPrefs.simpleJudge){
						FlxTween.tween(timingTxt.scale, {x: 0, y: 0}, time, {
							ease: FlxEase.quadIn,
							onComplete: function(_){timingTxt.visible = false;},
							startDelay: time * 8
						});
					}else{
						FlxTween.tween(timingTxt, {alpha: 0}, time, {
							// ease: FlxEase.circOut,
							onComplete: function(_){timingTxt.visible = false;},
							startDelay: time * 8
						});
					}
				}}
			);
		}

		hud.noteJudged(judgeData, note, field);
	}

	public var strumsBlocked:Array<Bool> = [];
	var pressed:Array<FlxKey> = [];

	private function onKeyPress(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var data:Int = getKeyFromEvent(eventKey);

		if (startedCountdown && !paused && data > -1 && !pressed.contains(eventKey)){
			pressed.push(eventKey);
			var hitNotes:Array<Note> = [];
			if(strumsBlocked[data]) return;

			callOnScripts('onKeyPress', [data]);

			for(field in playfields.members){
				if(!field.autoPlayed && field.isPlayer && field.inControl){
					field.keysPressed[data] = true;
					if(generatedMusic && !endingSong){
						var note:Note = field.input(data);
						if(note==null){
							var spr:StrumNote = field.strumNotes[data];
							if (spr != null && spr.animation.curAnim.name != 'confirm')
							{
								spr.playAnim('pressed');
								spr.resetAnim = 0;
							}
						}else
							hitNotes.push(note);

					}
				}
			}
			if(hitNotes.length==0){
				callOnScripts('onGhostTap', [data]);
				if (!ClientPrefs.ghostTapping)
				{
					noteMissPress(data);
					callOnScripts('noteMissPress', [data]);
				}
			}
		}
	}
	private function onKeyRelease(event:KeyboardEvent):Void
	{
		var eventKey:FlxKey = event.keyCode;
		var key:Int = getKeyFromEvent(eventKey);
		if(pressed.contains(eventKey))pressed.remove(eventKey);
		if(startedCountdown && key > -1)
		{
			// doesnt matter if THIS is done while paused
			// only worry would be if we implemented Lifts
			// but afaik we arent doing that
			// (though could be interesting to add)
			for(field in playfields.members){
				if (field.inControl && !field.autoPlayed && field.isPlayer)
				{
					field.keysPressed[key] = false;
					var spr:StrumNote = field.strumNotes[key];
					if (spr != null)
					{
						spr.playAnim('static');
						spr.resetAnim = 0;
					}
				}
			}
			callOnScripts('onKeyRelease', [key]);
		}
		//trace('released: ' + controlArray);
	}

	private function getKeyFromEvent(key:FlxKey):Int
	{
		if(key != NONE)
		{
			for (i in 0...keysArray.length)
			{
				for (j in 0...keysArray[i].length)
				{
					if(key == keysArray[i][j])
					{
						return i;
					}
				}
			}
		}
		return -1;
	}

	// Hold notes
	public static var pressedGameplayKeys:Array<Bool> = [];

	private function keyShit():Void
	{
		// HOLDING
		var parsedHoldArray:Array<Bool> = parseKeys();
		pressedGameplayKeys = parsedHoldArray;

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode)
		{
			var parsedArray:Array<Bool> = parseKeys('_P');
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] && strumsBlocked[i] != true)
						onKeyPress(new KeyboardEvent(KeyboardEvent.KEY_DOWN, true, true, -1, keysArray[i][0]));
				}
			}
		}

		// FlxG.watch.addQuick('asdfa', upP);
		if (startedCountdown && !boyfriend.stunned && generatedMusic)
		{

			if (parsedHoldArray.contains(true) && !endingSong) {
				#if ACHIEVEMENTS_ALLOWED
				var achieve:String = checkForAchievement(['oversinging']);
				if (achieve != null) {
					startAchievement(achieve);
				}
				#end
			}


		}

		// TO DO: Find a better way to handle controller inputs, this should work for now
		if (ClientPrefs.controllerMode || strumsBlocked.contains(true))
		{
			var parsedArray:Array<Bool> = parseKeys('_R');
			if (parsedArray.contains(true))
			{
				for (i in 0...parsedArray.length)
				{
					if (parsedArray[i] || strumsBlocked[i] == true)
						onKeyRelease(new KeyboardEvent(KeyboardEvent.KEY_UP, true, true, -1, keysArray[i][0]));
				}
			}
		}
	}

	private function parseKeys(?suffix:String = ''):Array<Bool>
	{
		var ret:Array<Bool> = [];
		for (i in 0...controlArray.length)
			ret[i] = Reflect.getProperty(controls, controlArray[i] + suffix);
		return ret;
	}

	function breakCombo(){
		stats.comboBreaks++;
		stats.cbCombo++;
		stats.combo = 0;
		if (ClientPrefs.etternaHUD != "ITG") {
			while (lastCombos.length > 0)
				lastCombos.shift().kill();
		} else {
			while (lastCombosTxt.length > 0)
				lastCombosTxt.shift().kill();
		}
		RecalculateRating();
	}

	function noteMiss(daNote:Note, field:PlayField, ?mine:Bool=false):Void { //You didn't hit the key and let it go offscreen, also used by Hurt Notes
		//Dupe note remove
		//field.spawnedNotes.forEachAlive(function(note:Note) {
		for(note in field.spawnedNotes){
			if(!note.alive || daNote.tail.contains(note) || note.isSustainNote) continue;
			if (daNote != note && field.isPlayer && daNote.noteData == note.noteData && Math.abs(daNote.strumTime - note.strumTime) < 1) 
				field.removeNote(note);
			
		}
		if (daNote.sustainLength > 0 && ClientPrefs.wife3)
			daNote.hitResult.judgment = DROPPED_HOLD;
		else
			daNote.hitResult.judgment = MISS;

		if(callOnHScripts("preNoteMiss", [daNote, field]) == Globals.Function_Stop)
			return;
		#if LUA_ALLOWED
		if(callOnLuas('preNoteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, daNote.ID]) == Globals.Function_Stop)
			return;
		#end
		
		if (daNote.noteScript!=null)
		{
			var script:FunkinScript = daNote.noteScript;

			if(callScript(script, "preNoteMiss", [daNote, field]) == Globals.Function_Stop)
				return;
		}

		////
		if(!daNote.isSustainNote && daNote.unhitTail.length > 0){
			for(tail in daNote.unhitTail){
				tail.tooLate = true;
				tail.blockHit = true;
				tail.ignoreNote = true;
				//health -= daNote.missHealth * healthLoss; // this is kinda dumb tbh no other VSRG does this just FNF
			}
		}

		if(!daNote.noMissAnimation)
		{
			var chars:Array<Character> = daNote.characters;

			if (daNote.gfNote && gf != null)
				chars.push(gf);
			else if (chars.length == 0)
				chars = field.characters;

			if (stats.combo > 10 && gf!=null && chars.contains(gf) == false && gf.animOffsets.exists('sad'))
			{
				gf.playAnim('sad');
				gf.specialAnim = true;
			}

			for(char in chars){
				if(char != null && char.animTimer <= 0 && !char.voicelining)
				{
					var daAlt = (daNote.noteType == 'Alt Animation') ? '-alt' : '';
					var animToPlay:String = singAnimations[Std.int(Math.abs(daNote.noteData))] + daAlt + 'miss';

					char.playAnim(animToPlay, true);

					if (!char.hasMissAnimations)
						char.colorOverlay = 0xFFC6A6FF;
				}	
			}
		}


/* 		breakCombo();
		
		health -= daNote.missHealth * healthLoss;	 */
		
		if (!mine){
			songMisses++;
			applyJudgment(daNote.hitResult.judgment);
		}else{
			applyJudgment(MISS_MINE);
			health -= daNote.missHealth * healthLoss;
		}
		
		vocals.volume = 0;

/* 		if(!practiceMode) 
			songScore -= 10; */

/* 		if(!daNote.isSustainNote ){
			if (daNote.sustainLength > 0 && ClientPrefs.wife3)
			{
				totalPlayed += 2;
				totalNotesHit += Wife3.holdDropWeight;
			}else{
				totalPlayed += ClientPrefs.wife3?2:1;
				if(ClientPrefs.wife3)
					totalNotesHit += mine?Wife3.mineWeight:Wife3.missWeight;
			}
			
			if(!mine)displayJudgment("miss");
			RecalculateRating();
		} */

		if (!daNote.isSustainNote && ClientPrefs.missVolume > 0) // i missed this sound
			FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), ClientPrefs.missVolume * FlxG.random.float(0.9, 1));

		if(instakillOnMiss)
			doDeathCheck(true);

		////
		callOnHScripts("noteMiss", [daNote, field]);
		#if LUA_ALLOWED
		callOnLuas('noteMiss', [notes.members.indexOf(daNote), daNote.noteData, daNote.noteType, daNote.isSustainNote, daNote.ID]);
		#end
		////
		if (daNote.noteScript != null)
		{
			var script:FunkinScript = daNote.noteScript;

			callScript(script, "noteMiss", [daNote, field]);
		}
	}

	function noteMissPress(direction:Int = 1):Void //You pressed a key when there was no notes to press for this key
	{
		if(ClientPrefs.ghostTapping) return; //fuck it

		health -= 0.05 * healthLoss;
		if(instakillOnMiss)
		{
			vocals.volume = 0;
			doDeathCheck(true);
		}

		if (stats.combo > 10 && gf != null && gf.animOffsets.exists('sad')) {
			gf.playAnim('sad');
			gf.specialAnim = true;
		}
		
/* 		combo = 0;
		while (lastCombos.length > 0)
			lastCombos.shift().kill(); */
		breakCombo();

		if(!practiceMode) stats.score -= 10;
		if(!endingSong) songMisses++;
		
		// i dont think this should reduce acc lol
		//totalPlayed++;
		//RecalculateRating();

		FlxG.sound.play(Paths.soundRandom('missnote', 1, 3), ClientPrefs.missVolume*FlxG.random.float(0.9, 1));

		for (field in playfields.members)
		{
			if (!field.isPlayer)
				continue;

			for(char in field.characters)
			{
				if(char.animTimer <= 0 && !char.voicelining)
				{
					char.playAnim(singAnimations[Std.int(Math.abs(direction))] + 'miss', true);
					if(!char.hasMissAnimations)
						char.colorOverlay = 0xFFC6A6FF;	
				}
			}
		}

		vocals.volume = 0;

		callOnScripts('noteMissPress', [direction]);
	}

	function opponentNoteHit(note:Note, field:PlayField):Void
	{
		if (Paths.formatToSongPath(SONG.song) != 'tutorial')
			camZooming = true;

		// Script shit
		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		if (note.noteScript != null)
		{
			var script:FunkinScript = note.noteScript;
			if (callScript(script, "preOpponentNoteHit", [note, field]) == Globals.Function_Stop)
				return;
		}
		if (callOnHScripts("preOpponentNoteHit", [note, field]) == Globals.Function_Stop)
			return;
		#if LUA_ALLOWED
		if (callOnLuas('preOpponentNoteHit', [notes.members.indexOf(note), leData, leType, isSus, note.ID]) == Globals.Function_Stop)
			return;
		#end

		var chars:Array<Character> = note.characters;
		if (note.gfNote)
			chars.push(gf);
		else if (chars.length == 0)
			chars = field.characters;

		for(char in chars){
			char.callOnScripts("playNote", [note, field]);

			if(note.noteType == 'Hey!' && char.animOffsets.exists('hey')) {
				char.playAnim('hey', true);
				char.specialAnim = true;
				char.heyTimer = 0.6;
			} else if(!note.noAnimation) {
				var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

				var curSection = SONG.notes[curSection];
				if ((curSection != null && curSection.altAnim) || note.noteType == 'Alt Animation')
					animToPlay += '-alt';

				if (char != null && char.animTimer <= 0 && !char.voicelining){
					char.playAnim(animToPlay, true);
					char.holdTimer = 0;
					char.callOnScripts("playNoteAnim", [animToPlay, note]);
				}
			}
		}

		if (SONG.needsVoices)
			vocals.volume = vocalsEnded?0:1;

		if (note.visible){
			StrumPlayAnim(field, Std.int(Math.abs(note.noteData)) % 4, Conductor.stepCrochet * 1.5 / 1000, note);
		}

		note.hitByOpponent = true;

		callOnHScripts("opponentNoteHit", [note, field]);
		#if LUA_ALLOWED
		callOnLuas('opponentNoteHit', [notes.members.indexOf(note), Math.abs(note.noteData), note.noteType, note.isSustainNote, note.ID]);
		#end

		if (note.noteScript != null)
		{
			var script:FunkinScript = note.noteScript;

			callScript(script, "opponentNoteHit", [note, field]);
		}

					

		if (!note.isSustainNote)
		{
			if (opponentHPDrain > 0 && health > opponentHPDrain)
				health -= opponentHPDrain;

			if(note.sustainLength == 0)
				field.removeNote(note);
		}
		else if (note.isSustainNote)
			if (note.parent.unhitTail.contains(note))
				note.parent.unhitTail.remove(note);
		
	}

	function goodNoteHit(note:Note, field:PlayField):Void
	{
		
		if (note.wasGoodHit || (field.autoPlayed && (note.ignoreNote || note.breaksCombo)))
			return;

		if(!note.isSustainNote)
			noteHits.push(Conductor.songPosition);

		if (ClientPrefs.hitsoundVolume > 0 && !note.hitsoundDisabled)
			FlxG.sound.play(Paths.sound('hitsound/' + ClientPrefs.hitsoundType.toLowerCase()), ClientPrefs.hitsoundVolume);

		// Strum animations
		if (note.visible){
			if(field.autoPlayed){
				StrumPlayAnim(field, Std.int(Math.abs(note.noteData)) % 4, Conductor.stepCrochet * 1.5 / 1000, note);
			}else{
				var spr = field.strumNotes[note.noteData];
				if(spr != null && field.keysPressed[note.noteData])
					spr.playAnim('confirm', true, note);
			}
		}

		// Script shit

		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;

		if (note.noteScript != null)
		{
			var script:FunkinScript = note.noteScript;
			if (callScript(script, "preGoodNoteHit", [note, field]) == Globals.Function_Stop)
				return;
		}
		if (callOnHScripts("preGoodNoteHit", [note, field]) == Globals.Function_Stop)
			return;
		#if LUA_ALLOWED
		if (callOnLuas('preGoodNoteHit', [notes.members.indexOf(note), leData, leType, isSus, note.ID]) == Globals.Function_Stop)
			return;
		#end

		if (cpuControlled)saveScore = false; // if botplay hits a note, then you lose scoring

		// tbh I hate hitCausesMiss lol its retarded
		// added a shitty judge to deal w/ it tho!!
 		if(note.hitResult.judgment == MISS_MINE) {
			noteMiss(note, field, true);

			if (!note.noMissAnimation)
			{
				switch (note.noteType)
				{
					case 'Hurt Note': // Hurt note
						var chars:Array<Character> = note.characters;
						if (note.gfNote)
							chars.push(gf);
						else if (chars.length == 0)
							chars = field.characters;

						for(char in chars){
							if (char.animation.getByName('hurt') != null){
								char.playAnim('hurt', true);
								char.specialAnim = true;
							}
						}

				}
			}

			note.wasGoodHit = true;
			if (!note.isSustainNote && note.tail.length==0)
				field.removeNote(note);
			else if(note.isSustainNote){
				if (note.parent != null)
					if (note.parent.unhitTail.contains(note))
						note.parent.unhitTail.remove(note);
				
			}
			return;
		} 

		if (!note.isSustainNote)
			judge(note, field);
		

		// Sing animations


		var chars:Array<Character> = note.characters;
		if (note.gfNote)
			chars.push(gf);
		else if(chars.length==0)
			chars = field.characters;


		for(char in chars)
			char.callOnScripts("playNote", [note]);


		if(!note.noAnimation) {
			var animToPlay:String = singAnimations[Std.int(Math.abs(note.noteData))];

			var curSection = SONG.notes[curSection];
			if ((curSection != null && curSection.altAnim) || note.noteType == 'Alt Animation')
				animToPlay += '-alt';
			
			for(char in chars){
				if (char != null && char.animTimer <= 0 && !char.voicelining){
					char.playAnim(animToPlay, true);
					char.holdTimer = 0;
					char.callOnScripts("playNoteAnim", [animToPlay, note]);
				}
			}

			if(note.noteType == 'Hey!') {
				for(char in chars){
					if (char.animTimer <= 0 && !char.voicelining){
						if(char.animOffsets.exists('hey')) {
							char.playAnim('hey', true);
							char.specialAnim = true;
							char.heyTimer = 0.6;
						}
					}
				}
				if(gf != null && gf.animOffsets.exists('cheer')) {
					gf.playAnim('cheer', true);
					gf.specialAnim = true;
					gf.heyTimer = 0.6;
				}
			}
		}
		note.wasGoodHit = true;
		vocals.volume = vocalsEnded?0:1;

		// Script shit
		callOnHScripts("goodNoteHit", [note, field]);
		#if LUA_ALLOWED
		var isSus:Bool = note.isSustainNote; //GET OUT OF MY HEAD, GET OUT OF MY HEAD, GET OUT OF MY HEAD
		var leData:Int = Math.round(Math.abs(note.noteData));
		var leType:String = note.noteType;
		callOnLuas('goodNoteHit', [notes.members.indexOf(note), leData, leType, isSus, note.ID]);
		#end

		if (note.noteScript != null)
		{
			var script:FunkinScript = note.noteScript;
			callScript(script, "goodNoteHit", [note, field]);
		}
		if (!note.isSustainNote && note.tail.length == 0)
			field.removeNote(note);
		else if (note.isSustainNote)
		{
			if (note.parent != null)
				if (note.parent.unhitTail.contains(note))
					note.parent.unhitTail.remove(note);
		}
	}

	function getFieldFromNote(note:Note){

		for (playfield in playfields)
		{
			if (playfield.hasNote(note))
				return playfield;
		}

		return playfields.members[0];
	}

	public function spawnNoteSplashOnNote(note:Note, ?field:PlayField) {
		if(ClientPrefs.noteSplashes && note != null) {
			if(field==null)
				field = getFieldFromNote(note);

			var strum:StrumNote = field.strumNotes[note.noteData];
			if(strum != null) {
				spawnNoteSplash(strum.x + strum.width * 0.5, strum.y + strum.height * 0.5, note.noteData, field, note);
			}
		}
	}

	public function spawnNoteSplash(x:Float, y:Float, data:Int, field:PlayField, ?note:Note = null) {
		field.spawnSplash(x,y,data, note);
	}


	private var preventLuaRemove:Bool = false;
	override function destroy() 
	{
		// Could probably do a results screen like the one on kade engine but for freeplay only. I think that could be cool.
		// ^ I was JUST thinking this. We can show the average NPS, accuracy, grade, judge counters, etc
		// I think just in general adding more stats could be neat & since we have the new options menu we can just put it in UI in a seperate category
		// so you can set exactly which stats show up in the scoretxt, etc

		/*
		trace(msJudges.length / {
			var total = 0.0;
			for (n in msJudges) total+=n;
			total;
		});*/

		stats.changedEvent.removeAll();
		stats.changedEvent = null;

		preventLuaRemove = true;

		for(script in funkyScripts){
			script.call("onDestroy");
			script.stop();
		}
		hscriptArray = [];
		funkyScripts = [];
		#if LUA_ALLOWED
		luaArray = [];
		#end

		Overlay.offset.y = 0;

		notetypeScripts.clear();
		eventScripts.clear();
		if(!ClientPrefs.controllerMode)
		{
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyPress);
			FlxG.stage.removeEventListener(KeyboardEvent.KEY_UP, onKeyRelease);
		}
		Note.globalRgbShaders = [];
		super.destroy();
	}

	public function cancelMusicFadeTween() {
		if (videoSprite != null)
		{
			videoSprite.bitmap.dispose();
			videoSprite.bitmap.stop();
			videoSprite.destroy();
			remove(videoSprite);
		}
	}

	#if LUA_ALLOWED
	public function removeLua(lua:FunkinLua) {
		if(luaArray != null && !preventLuaRemove) {
			luaArray.remove(lua);
		}
	}
	#end

	var lastStepHit:Int = -9999;
	override function stepHit()
	{
		if (Math.abs(FlxG.sound.music.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)
			|| (SONG.needsVoices && Math.abs(vocals.time - (Conductor.songPosition - Conductor.offset)) > (20 * playbackRate)))
		{
			resyncVocals();
		}
		super.stepHit();
		if(curStep == lastStepHit) 
			return;
		
		hud.stepHit(curStep);
		lastStepHit = curStep;
		setOnScripts('curStep', curStep);
		callOnScripts('onStepHit');
	}

	public function cameraBump()
	{
		if(FlxG.camera.zoom < (defaultCamZoom * 1.35))
			FlxG.camera.zoom += 0.015 * camZoomingMult * ClientPrefs.camZoomP;
		camHUD.zoom += 0.03 * camZoomingMult * ClientPrefs.camZoomP;
	}

	public var zoomEveryBeat:Int = 4;
	public var beatToZoom:Int = 0;

	var lastBeatHit:Int = -1;
	override function beatHit()
	{
		super.beatHit();

		if(lastBeatHit >= curBeat) 
			return;
	
		
		hud.beatHit(curBeat);

		if (camZooming && ClientPrefs.camZoomP>0 && zoomEveryBeat > 0 && curBeat % zoomEveryBeat == beatToZoom)
		{
			cameraBump();
		}

		if (gf != null)
		{
			var gfDanceEveryNumBeats = Math.round(gfSpeed * gf.danceEveryNumBeats);
			if ((gfDanceEveryNumBeats != 0 && curBeat % gfDanceEveryNumBeats == 0) && gf.animation.curAnim != null && !gf.animation.curAnim.name.startsWith("sing") && !gf.stunned)
				gf.dance();
		}
		
		for(field in playfields)
		{
			for(char in field.characters)
			{
				if(char!=gf)
				{
					if ((char.danceEveryNumBeats != 0 && curBeat % char.danceEveryNumBeats == 0)
						&& char.animation.curAnim != null
						&& !char.animation.curAnim.name.startsWith('sing')
						&& !char.stunned)
					{
						char.dance();
					}
				}
			}
		}

		lastBeatHit = curBeat;

		setOnScripts('curBeat', curBeat); //DAWGG?????
		callOnScripts('onBeatHit');
	}

	var lastSection:Int = -1;
	override function sectionHit(){
		var sectionNumber = curSection;
		var curSection = SONG.notes[sectionNumber];

		if (curSection == null)
			return;

		if (curSection.changeBPM)
		{
			Conductor.changeBPM(curSection.bpm);
			
			setOnScripts('curBpm', Conductor.bpm);
			setOnScripts('crochet', Conductor.crochet);
			setOnScripts('stepCrochet', Conductor.stepCrochet);
		}
		
		#if LUA_ALLOWED
		setOnLuas("curSection", sectionNumber);
		#end
		setOnHScripts("curSection", curSection);
		setOnScripts('sectionNumber', sectionNumber);

		setOnScripts('mustHitSection', curSection.mustHitSection == true);
		setOnScripts('altAnim', curSection.altAnim == true);
		setOnScripts('gfSection', curSection.gfSection  == true);

		if (lastSection != sectionNumber)
		{
			lastSection = sectionNumber;
			callOnScripts("onSectionHit");
		}

		if (generatedMusic && !endingSong)
		{
			moveCameraSection(curSection);
		}
	}

	inline public function callOnAllScripts(event:String, ?args:Array<Dynamic>, ignoreStops:Bool = false, ?exclusions:Array<String>, ?scriptArray:Array<Dynamic>,
			?vars:Map<String, Dynamic>):Dynamic
			return callOnScripts(event,args,ignoreStops,exclusions,scriptArray,vars,false);

	public function callOnScripts(event:String, ?args:Array<Dynamic>, ignoreStops:Bool = false, ?exclusions:Array<String>, ?scriptArray:Array<Dynamic>,
			?vars:Map<String, Dynamic>, ?ignoreSpecialShit:Bool = true):Dynamic
	{
		var args:Array<Dynamic> = args != null ? args : [];

		if (scriptArray == null)
			scriptArray = funkyScripts;
		if(exclusions==null)exclusions = [];
		var returnVal:Dynamic = Globals.Function_Continue;
		for (script in scriptArray)
		{
			if (exclusions.contains(script.scriptName)
				|| ignoreSpecialShit
				&& (notetypeScripts.exists(script.scriptName) || eventScripts.exists(script.scriptName) ) )
			{
				continue;
			}
			var ret:Dynamic = script.call(event, args, vars);
			if (ret == Globals.Function_Halt)
			{
				ret = returnVal;
				if (!ignoreStops)
					return returnVal;
			};
			if (ret != Globals.Function_Continue && ret!=null){
				returnVal = ret;
			}
		}
		
		if(returnVal==null)returnVal = Globals.Function_Continue;
		return returnVal;
	}

	public function setOnScripts(variable:String, value:Dynamic, ?scriptArray:Array<Dynamic>)
	{
		if (scriptArray == null)
			scriptArray = funkyScripts;

		for (script in scriptArray){
			script.set(variable, value);
			// trace('set $variable, $value, on ${script.scriptName}');
		}	
	}

	public function callScript(script:Dynamic, event:String, args:Array<Dynamic>):Dynamic
	{
		if((script is FunkinScript)){
			return callOnScripts(event, args, true, [], [script], false);
		}
		else if((script is Array)){
			return callOnScripts(event, args, true, [], script, false);
		}
		else if((script is String)){
			var scripts:Array<FunkinScript> = [];

			for(scr in funkyScripts){
				if(scr.scriptName == script)
					scripts.push(scr);
			}

			return callOnScripts(event, args, true, [], scripts, false);
		}

		return Globals.Function_Continue;
	}

	#if hscript
	public function callOnHScripts(event:String, ?args:Array<Dynamic>, ?vars:Map<String, Dynamic>, ignoreStops = false, ?exclusions:Array<String>):Dynamic
		return callOnScripts(event, args, ignoreStops, exclusions, hscriptArray, vars);
	
	public function setOnHScripts(variable:String, arg:Dynamic)
		return setOnScripts(variable, arg, hscriptArray);

	public function setDefaultHScripts(variable:String, arg:Dynamic){
		FunkinHScript.defaultVars.set(variable, arg);
		return setOnScripts(variable, arg, hscriptArray);
	}
	#end

	#if LUA_ALLOWED
	public function callOnLuas(event:String, ?args:Array<Dynamic>, ignoreStops = false, ?exclusions:Array<String>):Dynamic
		return callOnScripts(event, args, ignoreStops, exclusions, luaArray);
	
	public function setOnLuas(variable:String, arg:Dynamic)
		setOnScripts(variable, arg, luaArray);
	#end

	function StrumPlayAnim(field:PlayField, id:Int, time:Float, ?note:Note) {
		var spr:StrumNote = field.strumNotes[id];

		if(spr != null) {
			spr.playAnim('confirm', true, note);
			spr.resetAnim = time;
		}
	}
	
	public function RecalculateRating() {
		setOnScripts('score', stats.score);
		setOnScripts('misses', songMisses);
		setOnScripts('comboBreaks', stats.comboBreaks);
		setOnScripts('hits', songHits);

		var ret:Dynamic = callOnScripts('onRecalculateRating');
		
/* 		if(ret != Globals.Function_Stop)
		{
			if(totalPlayed < 1) //Prevent divide by 0
				ratingName = '?';
			else
			{
				// Rating Percent
				if(ClientPrefs.wife3)
					ratingPercent = totalNotesHit / totalPlayed;
				else
					ratingPercent = Math.min(1, Math.max(0, totalNotesHit / totalPlayed));
				//trace((totalNotesHit / totalPlayed) + ', Total: ' + totalPlayed + ', notes hit: ' + totalNotesHit);

				// Rating Name
				if(ratingPercent >= 1)
					ratingName = ratingStuff[0][0]; //Uses first string
				else
				{
					ratingName = ratingStuff[ratingStuff.length-1][0];
					for (i in 0...ratingStuff.length)
					{
						if(ratingPercent >= ratingStuff[i][1])
						{
							ratingName = ratingStuff[i][0];
							break;
						}
					}
				}
			}

			// Rating FC
			ratingFC = getClearType();
		}*/

		stats.updateVariables();

		// maybe move all of this to a stats class that I can easily give to objects?
/* 		hud.ratingFC = ratingFC;
		hud.grade = ratingName;
		hud.ratingPercent = ratingPercent;
		hud.misses = songMisses;
		hud.combo = combo;
		//hud.comboBreaks = comboBreaks;
		//hud.judgements.set("miss", songMisses);
		//hud.judgements.set("cb", comboBreaks);
		hud.totalNotesHit = totalNotesHit;
		hud.totalPlayed = totalPlayed;
		hud.score = songScore;*/
		
		hud.recalculateRating();

		callOnScripts('postRecalculateRating'); // incase you wanna add custom rating stuff
		setOnScripts('rating', ratingPercent);
		setOnScripts('ratingName', ratingName);
		setOnScripts('ratingFC', ratingFC);
	}

	#if (!flash && sys)
	public var runtimeShaders:Map<String, Array<String>> = new Map<String, Array<String>>();
	public function createRuntimeShader(name:String):FlxRuntimeShader
	{
		if(ClientPrefs.shaders == "None") return new FlxRuntimeShader();

		#if (!flash && MODS_ALLOWED && sys)
		if(!runtimeShaders.exists(name) && !initLuaShader(name))
		{
			FlxG.log.warn('Shader $name is missing!');
			return new FlxRuntimeShader();
		}

		var arr:Array<String> = runtimeShaders.get(name);
		return new FlxRuntimeShader(arr[0], arr[1]);
		#else
		FlxG.log.warn("Platform unsupported for Runtime Shaders!");
		return null;
		#end
	}

	public function initLuaShader(name:String, ?glslVersion:Int = 120)
	{
		if(ClientPrefs.shaders == "None") return false;

		if(runtimeShaders.exists(name))
		{
			FlxG.log.warn('Shader $name was already initialized!');
			return true;
		}

		var foldersToCheck:Array<String> = [Paths.mods('shaders/')];
		if(Paths.currentModDirectory != null && Paths.currentModDirectory.length > 0)
			foldersToCheck.insert(0, Paths.mods(Paths.currentModDirectory + '/shaders/'));

		for(mod in Paths.getGlobalContent())
			foldersToCheck.insert(0, Paths.mods(mod + '/shaders/'));
		
		for (folder in foldersToCheck)
		{
			if(FileSystem.exists(folder))
			{
				var frag:String = folder + name + '.frag';
				var vert:String = folder + name + '.vert';
				var found:Bool = false;
				if(FileSystem.exists(frag))
				{
					frag = File.getContent(frag);
					found = true;
				}
				else frag = null;

				if (FileSystem.exists(vert))
				{
					vert = File.getContent(vert);
					found = true;
				}
				else vert = null;

				if(found)
				{
					runtimeShaders.set(name, [frag, vert]);
					//trace('Found shader $name!');
					return true;
				}
			}
		}
		FlxG.log.warn('Missing shader $name .frag AND .vert files!');
		return false;
	}

	public function setSpriteShader(obj:String, shader:String)
	{
		if (runtimeShaders.exists(shader) && !initLuaShader(shader))
		{
			trace('setSpriteShader: Shader $shader is missing!');
			return false;
		}

		var killMe:Array<String> = obj.split('.');
		var leObj:FlxSprite = FunkinLua.getObjectDirectly(killMe[0]);
		if(killMe.length > 1) {
			leObj = FunkinLua.getVarInArray(FunkinLua.getPropertyLoopThingWhatever(killMe), killMe[killMe.length-1]);
		}

		if(leObj != null) {
			var arr:Array<String> = runtimeShaders.get(shader);
			leObj.shader = new FlxRuntimeShader(arr[0], arr[1]);
			return true;
		}

		return false;
	}
	#end

	////
	public function pause(?OpenPauseMenu = true){
		if (startedCountdown && canPause && health > 0 && !paused)
		{
			if(callOnScripts('onPause') != Globals.Function_Stop) {
				persistentUpdate = false;
				persistentDraw = true;
				paused = true;

				// 0 chance for Gitaroo Man easter egg

				if(inst != null) 
				{
					inst.pause();
					vocals.pause();
					for (track in tracks)
						track.pause();
				}

				if (OpenPauseMenu)
					openSubState(new PauseSubState(boyfriend.getScreenPosition().x, boyfriend.getScreenPosition().y));

				#if discord_rpc
				DiscordClient.changePresence(detailsPausedText, SONG.song, Paths.formatToSongPath(SONG.song));
				#end
			}
		}
	}

	override public function switchTo(nextState: Dynamic){
		callOnHScripts("switchingState", [nextState]);
		#if LUA_ALLOWED
		callOnLuas("switchingState");
		#end
		FlxG.timeScale = 1;
		pressedGameplayKeys = [];
		FunkinHScript.defaultVars.clear();
		return super.switchTo(nextState);
	}

}

// mental gymnastics
class FNFHealthBar extends FlxBar{
	public var healthBarBG:FlxSprite;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	var leftIcon:HealthIcon;
	var rightIcon:HealthIcon;

	public var iconOffset:Int = 26;

	// public var value:Float = 1;
	public var isOpponentMode:Bool = false; // going insane

	override function set_flipX(value:Bool){
		iconP1.flipX = value;
		iconP2.flipX = value;

		// aughhh
		if (value){
			leftIcon = iconP1;
			rightIcon = iconP2;
		}else{
			leftIcon = iconP2;
			rightIcon = iconP1;
		}

		updateHealthBarPos();

		return super.set_flipX(value);
	}

	override function set_visible(value:Bool){
		healthBarBG.visible = value;
		if (ClientPrefs.etternaHUD == 'ITG') {
			iconP1.visible = false;
			iconP2.visible = false;
		} else {
			iconP1.visible = value;
			iconP2.visible = value;
		}

		return super.set_visible(value);
	}

	override function set_alpha(value:Float){
		healthBarBG.alpha = value;
		if (ClientPrefs.etternaHUD == 'ITG') {
			iconP1.alpha = 0;
			iconP2.alpha = 0;
		} else {
			iconP1.alpha = value;
			iconP2.alpha = value;
		}

		return super.set_alpha(value);
	}

	public function new(bfHealthIcon = "face", dadHealthIcon = "face")
	{
		//
		if (ClientPrefs.etternaHUD == 'ITG') {
			healthBarBG = new FlxSprite(10, FlxG.height - 706);
			healthBarBG.loadGraphic(Paths.image('SimplyLoveHud/HealthBG'));
			healthBarBG.scrollFactor.set();
			healthBarBG.antialiasing = true;
		}else {
			healthBarBG = new FlxSprite(0, FlxG.height * (ClientPrefs.downScroll ? 0.11 : 0.89));
			healthBarBG.loadGraphic(Paths.image('healthBar'));
			healthBarBG.screenCenter(X);
			healthBarBG.scrollFactor.set();
			healthBarBG.antialiasing = true;
		}

		//
		iconP1 = new HealthIcon(bfHealthIcon, true);
		iconP2 = new HealthIcon(dadHealthIcon, false);
		leftIcon = iconP2;
		rightIcon = iconP1;

		//
		if (ClientPrefs.etternaHUD != 'ITG')
			isOpponentMode = PlayState.instance.playOpponent;

		if (ClientPrefs.etternaHUD == 'ITG') {
			super(
				healthBarBG.x + 5, healthBarBG.y + 5,
				LEFT_TO_RIGHT,
				Std.int(healthBarBG.width - 10), Std.int(healthBarBG.height - 10),
				null, null,
				0, 2
			);
		} else {
			super(
				healthBarBG.x + 5, healthBarBG.y + 5,
				RIGHT_TO_LEFT,
				Std.int(healthBarBG.width - 10), Std.int(healthBarBG.height - 10),
				null, null,
				0, 2
			);
		}
		
		value = 1;

		//
		iconP2.setPosition(
			healthBarPos - 75 - iconOffset * 2,
			y - 75
		);
		iconP1.setPosition(
			healthBarPos - iconOffset,
			y - 75
		);

		//
		antialiasing = false;
		scrollFactor.set();
		visible = alpha > 0;
	}

	function get_alpha()
		return alpha * ClientPrefs.hpOpacity;

	public var real_alpha(get, set):Float;
	function get_real_alpha()
		@:bypassAccessor return alpha;
	function set_real_alpha(val:Float)
		return alpha = val;

	public var iconScale(default, set) = 1.0;
	function set_iconScale(value:Float){
		iconP1.scale.set(value, value);
		iconP2.scale.set(value, value);

		iconP1.updateHitbox();
		iconP2.updateHitbox();

		return iconScale = value;
	}

	private var healthBarPos:Float;
	private function updateHealthBarPos()
	{
		healthBarPos = x + width * (flipX ? value * 0.5 : 1 - value * 0.5) ;
	}

	override function set_value(val:Float){
		var val = isOpponentMode ? max-val : val;

		iconP1.animation.curAnim.curFrame = val < 0.4 ? 1 : 0; // 20% ?
		iconP2.animation.curAnim.curFrame = val > 1.6 ? 1 : 0; // 80% ?

		super.set_value(val);

		updateHealthBarPos();

		return value;
	}

	override function update(elapsed:Float)
	{
		if (!visible){
			super.update(elapsed);
			return;
		}

		healthBarBG.setPosition(x - 5, y - 5);

		if (iconScale != 1){
			iconScale = FlxMath.lerp(1, iconScale, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));

			var scaleOff = 75 * iconScale;
			leftIcon.x = healthBarPos - scaleOff - iconOffset * 2;
			rightIcon.x = healthBarPos + scaleOff - 75 - iconOffset;
		}
		else
		{
			leftIcon.x = healthBarPos - 75 - iconOffset * 2;
			rightIcon.x = healthBarPos - iconOffset;
		}

		super.update(elapsed);
	}
}

class RatingSprite extends FlxSprite
{
	public var tween:FlxTween;

	public function new(){
		super();
		moves = !ClientPrefs.simpleJudge;

		// antialiasing = ClientPrefs.globalAntialiasing;
		//cameras = [ClientPrefs.simpleJudge ? PlayState.instance.camHUD : PlayState.instance.camGame];
		cameras = [PlayState.instance.camHUD];

		scrollFactor.set();
	}

	override public function kill(){
		if (tween != null){
			tween.cancel();
			tween.destroy();
		}
		return super.kill();
	}

	public static function newRating()
	{
		var rating = new RatingSprite();
		// rating.acceleration.y = 550;
		rating.scale.set(0.7, 0.7);

		return rating;
	}

	public static function newNumber()
	{
		var numScore = new RatingSprite();
		numScore.scale.set(0.5, 0.5);

		return numScore;
	}
}

class RatingText extends FlxText
{
	public var tween:FlxTween;

	public function new(){
		super();
		moves = !ClientPrefs.simpleJudge;

		// antialiasing = ClientPrefs.globalAntialiasing;
		//cameras = [ClientPrefs.simpleJudge ? PlayState.instance.camHUD : PlayState.instance.camGame];
		cameras = [PlayState.instance.camHUD];

		scrollFactor.set();
	}

	override public function kill(){
		if (tween != null){
			tween.cancel();
			tween.destroy();
		}
		return super.kill();
	}
	public static function newNumber()
	{
		var numScore = new RatingText();

		return numScore;
	}
}

class BotplayText extends FlxText
{
	public var sine:Float = 0;

	override public function update(elapsed:Float){
		if (ClientPrefs.etternaHUD != 'ITG') {
			sine += 180 * elapsed;
			alpha = 1 - flixel.math.FlxMath.fastSin((Math.PI * sine) / 180);
		}

		super.update(elapsed);
	}
}