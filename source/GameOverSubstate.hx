package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;

class GameOverSubstate extends MusicBeatSubstate
{
	public static var instance:GameOverSubstate;

	public var boyfriend:Boyfriend;
	public var genericBitch:FlxSprite;
	public var deathSound:FlxSound;

	public var defaultCamZoom:Float = 1;

	public var camFollow:FlxPoint;
	public var camFollowPos:FlxObject;
	public var updateCamera:Bool = false;

	public static var characterName:String = null;
	public static var deathSoundName:String = 'fnf_loss_sfx';
	public static var loopSoundName:String = 'gameOver';
	public static var endSoundName:String = 'gameOverEnd';
	
	public static var genericName:String;
	public static var genericSound:String;
	public static var genericMusic:String;

	// for bowser or tankman or whatever
	public static var voicelineNumber:Null<Int> = null; // set this value to play an specific voiceline (otherwise it will be randomly chosen using the voicelineAmount value)
	public static var voicelineAmount:Int = 0; // how many voicelines exist.
	public static var voicelineName:Null<String> = null; // if set to null then it will just use the character name
	// nvm maybe ill use this next time

	public static function resetVariables() {
		characterName = null;
		deathSoundName = 'fnf_loss_sfx';
		loopSoundName = 'gameOver';
		endSoundName = 'gameOverEnd';

		// maybe ill do something better for v5 idk i just wanna get over this
		genericName = 'characters/gameover/generic${FlxG.random.int(1,5)}'; 
		genericSound = "gameoverGeneric";
		genericMusic = "";

		voicelineNumber = null;
		voicelineAmount = 0;
		voicelineName = null;
	}

	override function create()
	{
		FlxG.timeScale = 1;
		
		instance = this;

		if (generic){
			FlxG.camera.bgColor = 0x00000000;
			FlxTween.num(0, 1, 0.6, {ease: FlxEase.quadOut, onComplete: (twn)->{
				loser.animation.play('lose');
				FlxTween.tween(restart, {alpha: 1}, 1, {ease: FlxEase.quartInOut});
				FlxTween.tween(restart, {y: restart.y + 40}, 7, {ease: FlxEase.quartInOut, type: PINGPONG});
			}}, (prog)->{
				FlxG.camera.bgColor.alphaFloat = prog;	
			});	
		}

		PlayState.instance.callOnScripts('onGameOverStart', []);
		super.create();
	}

	var generic:Bool = false;
	var loser:FlxSprite;
	var restart:FlxSprite;
	function doGenericGameOver()
	{
		generic = true;

		loser = new FlxSprite(100, 100);
		loser.frames = Paths.getSparrowAtlas("characters/gameover/lose");
		loser.animation.addByPrefix('lose', 'lose', 24, false);
		loser.animation.callback = (name, frameNumber, frameIndex)->{
			if (frameNumber == 6 && !isEnding)
				FlxG.sound.play(Paths.sound(genericSound));
		}
		loser.scrollFactor.set();
		add(loser);

		restart = new FlxSprite(500, 50, Paths.image("characters/gameover/restart"));
		restart.setGraphicSize(Std.int(restart.width * 0.6));
		restart.updateHitbox();
		restart.alpha = 0;
		restart.scrollFactor.set();
		add(restart);
	}

	public function new(x:Float, y:Float, camX:Float, camY:Float, ?isPlayer:Bool)
	{
		super();

		var game = PlayState.instance;

		game.setOnScripts('inGameOver', true);

		var deathName:String = characterName;

		if (deathName == null){
			var character = game.playOpponent ? game.dad : game.boyfriend;
			if (character != null) deathName = character.deathName + "-dead";
		}

		var charInfo = deathName == null ? null : Character.getCharacterFile(deathName);
		if (charInfo == null || PlayState.curStage == "nothing"){
			if (PlayState.instance.showDebugTraces) trace('"$deathName" does not exist, using default.');

			deathName = "generic-gameover";
			charInfo = null;

			Cache.loadWithList([
				{path: "characters/gameover/lose"},
				{path: "characters/gameover/restart"},
			]);

			return doGenericGameOver(); 
		}

		game.inst.volume = 0;
		game.inst.stop();
		game.vocals.volume = 0;
		game.vocals.stop();
		for (track in game.tracks){
			track.volume = 0;
			track.stop();
		}

		Conductor.songPosition = 0;
		
		Cache.loadWithList([
			{path: charInfo.image, type: 'IMAGE'},
			{path: deathSoundName, type: 'SOUND'},
			{path: loopSoundName, type: 'MUSIC'},
			{path: endSoundName, type: 'MUSIC'}
		]);
		
		boyfriend = new Boyfriend(x, y, deathName, isPlayer);
		boyfriend.x += boyfriend.positionArray[0];
		boyfriend.y += boyfriend.positionArray[1];
		add(boyfriend);
		
		camFollow = new FlxPoint(boyfriend.getGraphicMidpoint().x, boyfriend.getGraphicMidpoint().y);
		
		deathSound = FlxG.sound.play(Paths.sound(deathSoundName));
		Conductor.changeBPM(100);
		FlxG.camera.bgColor = FlxColor.BLACK;
		FlxG.camera.scroll.set();
		FlxG.camera.target = null;

		boyfriend.playAnim('firstDeath');

		camFollowPos = new FlxObject(0, 0, 1, 1);
		camFollowPos.setPosition(FlxG.camera.scroll.x + (FlxG.camera.width* 0.5), FlxG.camera.scroll.y + (FlxG.camera.height* 0.5));
		add(camFollowPos);

		FlxG.camera.follow(camFollowPos, LOCKON, 1);

		if (PlayState.instance != null && PlayState.instance.stage != null)
			defaultCamZoom = PlayState.instance.stage.stageData.defaultZoom;
		else
			defaultCamZoom = FlxG.camera.zoom;
	}

	var isFollowingAlready:Bool = false;
	var isEnding:Bool = false;

	override function update(elapsed:Float)
	{
		PlayState.instance.callOnScripts('onUpdate', [elapsed]);

		if(updateCamera && genericBitch == null) {
			var lerpVal:Float = CoolUtil.boundTo(elapsed * 0.6, 0, 1);
			camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));
			FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, defaultCamZoom, CoolUtil.boundTo(elapsed * 2.2, 0, 1));
		}	

		if (controls.ACCEPT && !isEnding)
		{
			isEnding = true;

			if (boyfriend != null)
				boyfriend.playAnim('deathConfirm', true);

			if (genericBitch != null){
				FlxTween.cancelTweensOf(genericBitch);
				FlxTween.tween(genericBitch, {alpha: 0, "scale.x": 0, "scale.y": 0}, 100/120, {ease: FlxEase.quadIn, onComplete: (_)->{remove(genericBitch).destroy();}});
			}
			
			FlxG.sound.music.stop();
			FlxG.sound.play(Paths.music(endSoundName));

			new FlxTimer().start(0.7, function(tmr:FlxTimer){
				FlxG.camera.fade(FlxColor.BLACK, 2, false, MusicBeatState.resetState.bind(true));
			});

			PlayState.instance.callOnScripts('onGameOverConfirm', [true]);
		}

		if (controls.BACK)
		{
			isEnding = true;

			if (genericBitch != null)
				FlxTween.cancelTweensOf(genericBitch);

			FlxG.sound.music.stop();
			PlayState.deathCounter = 0;
			PlayState.seenCutscene = false;

			PlayState.instance.callOnScripts('onGameOverConfirm', [false]);

			if (PlayState.isStoryMode)
				MusicBeatState.switchState(new StoryMenuState());
			else
				MusicBeatState.switchState(new PsychFreeplayState());

			MusicBeatState.playMenuMusic(true);
		}

		if (!isEnding && boyfriend != null && boyfriend.animation.curAnim.name == 'firstDeath')
		{
			if(boyfriend.animation.curAnim.curFrame >= 12 && !isFollowingAlready)
			{
				updateCamera = true;
				isFollowingAlready = true;
			}

			if (boyfriend.animation.curAnim.finished)
			{
				FlxG.sound.playMusic(Paths.music(loopSoundName), 1);
				boyfriend.startedDeath = true;
			}
		}

		if (FlxG.sound.music.playing)
			Conductor.songPosition = FlxG.sound.music.time;
		
		PlayState.instance.callOnScripts('onUpdatePost', [elapsed]);
		super.update(elapsed);
	}

	override function beatHit()
	{
		super.beatHit();
	}
}