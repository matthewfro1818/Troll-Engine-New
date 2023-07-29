package;

import flixel.util.FlxColor;
import shaders.RGBPalette;
import editors.ChartingState;
import JudgmentManager.Judgment;
import math.Vector3;
import scripts.*;
import playfields.*;

using StringTools;

typedef EventNote = {
	strumTime:Float,
	event:String,
	value1:String,
	value2:String
}

typedef HitResult = {
	judgment: Judgment,
	hitDiff: Float
}

@:enum abstract SplashBehaviour(Int) from Int to Int
{
	var DEFAULT = 0; // only splashes on judgements that have splashes
	var DISABLED = -1; // never splashes
	var FORCED = 1; // always splashes
}
class Note extends NoteObject
{
	public var vec3Cache:Vector3 = new Vector3(); // for vector3 operations in modchart code
	public var hitResult:HitResult = {
		judgment: UNJUDGED,
		hitDiff: 0
	}

	override function destroy()
	{
		defScale.put();
		super.destroy();
	}
	public var mAngle:Float = 0;
	public var bAngle:Float = 0;
	
	public var noteScript:FunkinScript;
	public var skinScript:FunkinScript;


	public static var quants:Array<Int> = [
		4, // quarter note
		8, // eight
		12, // etc
		16,
		20,
		24,
		32,
		48,
		64,
		96,
		192
	];

	public static function getQuant(beat:Float){
		var row = Conductor.beatToNoteRow(beat);
		for(data in quants){
			if(row%(Conductor.ROWS_PER_MEASURE/data) == 0){
				return data;
			}
		}
		return quants[quants.length-1]; // invalid
	}
	public var noteDiff:Float = 1000;

	// quant shit
	public var quant:Int = 4;
	public var extraData:Map<String, Dynamic> = [];
	public var isQuant:Bool = false; // mainly for color swapping, so it changes color depending on which set (quants or regular notes)
	
	// basic stuff
	public var beat:Float = 0;
	public var strumTime:Float = 0;
	public var visualTime:Float = 0;
	public var mustPress:Bool = false;
	@:isVar
	public var canBeHit(get, null):Bool = false;
	public var tooLate:Bool = false;
	public var wasGoodHit:Bool = false;
	public var ignoreNote:Bool = false;
	public var hitByOpponent:Bool = false;
	public var noteWasHit:Bool = false;
	public var prevNote:Note;
	public var nextNote:Note;
	public var spawned:Bool = false;
	public var causedMiss:Bool = false;
	function get_canBeHit()return PlayState.instance.judgeManager.judgeNote(this)!=UNJUDGED;
	
	
	// note type/customizable shit
	public var canQuant:Bool = true; // whether a quant texture should be searched for or not
	public var noteType(default, set):String = null;  // the note type

	public var blockHit:Bool = false; // whether you can hit this note or not
	#if PE_MOD_COMPATIBILITY
	public var lowPriority:Bool = false; // Shadowmario's shitty workaround for really bad mine placement, yet still no *real* hitbox customization lol! Only used when PE Mod Compat is enabled in project.xml
	#end
	@:isVar
	public var noteSplashDisabled(get, set):Bool = false; // disables the notesplash when you hit this note
	function get_noteSplashDisabled()
		return noteSplashBehaviour==DISABLED;
	function set_noteSplashDisabled(val:Bool){
		noteSplashBehaviour = val?DISABLED:DEFAULT;
		return val;
	}

	public var noteSplashBehaviour:SplashBehaviour = DEFAULT;
	public var usesDefaultColours:Bool = true; // whether this note uses the default note colours (lets you change colours in options menu)
	// This automatically gets set if a notetype changes the ColorSwap values

	public var requiresTap:Bool = true; // If you need to tap the note to hit it, or just have the direction be held when it can be judged to hit.
	public var noteSplashTexture:String = null; // spritesheet for the notesplash
	//public var ratingDisabled:Bool = false; // disables judging this note
	public var missHealth:Float = 0; // damage when hitCausesMiss = true and you hit this note	
	public var texture(default, set):String = null; // texture for the note
	public var noAnimation:Bool = false; // disables the animation for hitting this note
	public var noMissAnimation:Bool = false; // disables the animation for missing this note
	public var hitCausesMiss:Bool = false; // hitting this causes a miss
	public var breaksCombo:Bool = false; // hitting this will cause a combo break
	public var hitsoundDisabled:Bool = false; // hitting this does not cause a hitsound when user turns on hitsounds
	public var gfNote:Bool = false; // gf sings this note (pushes gf into characters array when the note is hit)
	public var characters:Array<Character> = []; // which characters sing this note, leave blank for the playfield's characters
	public var fieldIndex:Int = -1; // Used to denote which PlayField to be placed into
	// Leave -1 if it should be automatically determined based on mustPress and placed into either bf or dad's based on that.
	// Note that holds automatically have this set to their parent's fieldIndex
	public var field:PlayField; // same as fieldIndex but lets you set the field directly incase you wanna do that i  guess

	// custom health values
	public var ratingHealth:Map<String, Float> = [];

	// hold/roll shit
	public var sustainMult:Float = 1;
	public var tail:Array<Note> = []; 
	public var unhitTail:Array<Note> = [];
	public var parent:Note;
	public var sustainLength:Float = 0;
	public var isSustainNote:Bool = false;
	public var holdingTime:Float = 0;
	public var tripTimer:Float = 0;
	public var isRoll:Bool = false;

	// event shit (prob can be removed??????)
	public var eventName:String = '';
	public var eventLength:Int = 0;
	public var eventVal1:String = '';
	public var eventVal2:String = '';

	// etc

	public var rgbShader:RGBPalette;
	public static var globalRgbShaders:Array<RGBPalette> = [];
	public var inEditor:Bool = false;
	public var desiredZIndex:Float = 0;
	
	// do not tuch
	public var baseScaleX:Float = 1;
	public var baseScaleY:Float = 1;
	public var zIndex:Float = 0;
	public var z:Float = 0;
	public var realNoteData:Int;
	public static var swagWidth:Float = 160 * 0.7;
	
	
	public static var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
	private var pixelInt:Array<Int> = [0, 1, 2, 3];
	public var pixelNote:Bool = false;


	// mod manager
	public var garbage:Bool = false; // if this is true, the note will be removed in the next update cycle
	public var alphaMod:Float = 1;
	public var alphaMod2:Float = 1; // TODO: unhardcode this shit lmao
	public var typeOffsetX:Float = 0; // used to offset notes, mainly for note types. use in place of offset.x and offset.y when offsetting notetypes
	public var typeOffsetY:Float = 0;
	public var typeOffsetAngle:Float = 0;
	public var multSpeed(default, set):Float = 1;
	/* useless shit mostly
	public var offsetAngle:Float = 0;
	public var multAlpha:Float = 1;
	*/

	public var copyX:Bool = true;
	public var copyY:Bool = true;
	public var copyAngle:Bool = true;
	public var copyAlpha:Bool = true;

	public var rating:String = 'unknown';
	public var ratingMod:Float = 0; //9 = unknown, 0.25 = shit, 0.5 = bad, 0.75 = good, 1 = sick

	public var distance:Float = 2000; //plan on doing scroll directions soon -bb


	public static var defaultNotes = [
		'No Animation',
		'GF Sing',
		''
	];

	@:isVar
	public var isSustainEnd(get, null):Bool = false;

	public function get_isSustainEnd():Bool
	{
		if (isSustainNote && animation != null && animation.curAnim != null && animation.curAnim.name != null && animation.curAnim.name.endsWith("end"))
			return true;

		return false;
	}

	private function set_multSpeed(value:Float):Float {
		return multSpeed = value;
	}

	public function resizeByRatio(ratio:Float) //haha funny twitter shit
	{
		
	}

	public var noteTypeTexture(default, set):String = null; // texture for the noteType
	private function set_noteTypeTexture(value:String):String {
		if(noteTypeTexture != value) {
			reloadNote('',value);
		}
		noteTypeTexture = value;
		return value;
	}
	private function set_texture(value:String):String {
		if(texture != value) {
			reloadNote(value);
		}
		texture = value;
		return value;
	}

	public function updateColours(){	
		if (!usesDefaultColours) return;
		if (rgbShader == null) return;	
		if(isQuant){
			var idx = quants.indexOf(quant);
			rgbShader.r = ClientPrefs.quantColors[idx][0];
			rgbShader.g = 0xFFFFFFFF;
			rgbShader.b = ClientPrefs.quantColors[idx][1];
		}else{
			rgbShader.r = ClientPrefs.columnColors[noteData % 4][0];
			rgbShader.g = ClientPrefs.columnColors[noteData % 4][1];
			rgbShader.b = ClientPrefs.columnColors[noteData % 4][2];
		}

		switch (ClientPrefs.noteType)
		{
			case 'Scalable':
				if (isSustainNote)
					rgbShader.enabled = false;

				rgbShader.b = FlxColor.BLACK;
				rgbShader.g = 0xafafaf;
		}

		if (noteScript != null && noteScript is FunkinHScript)
		{
			var noteScript:FunkinHScript = cast noteScript;
			noteScript.executeFunc("onUpdateColours", [this], this);
		}

		if (skinScript != null && skinScript is FunkinHScript)
		{
			var skinScript:FunkinHScript = cast skinScript;
			skinScript.executeFunc("onUpdateColours", [this], this);
		}
	}

	public static function initializeGlobalRGBShader(idx:Int, aQuant:Bool)
	{
		if (aQuant)
		{
			if(globalRgbShaders[idx] == null)
			{
				var newRGB:RGBPalette = new RGBPalette();
				globalRgbShaders[idx] = newRGB;
			
				var arr:Array<FlxColor> = ClientPrefs.quantColors[idx];
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
		}
		else
		{
			if(globalRgbShaders[idx] == null)
			{
				var newRGB:RGBPalette = new RGBPalette();
				globalRgbShaders[idx] = newRGB;
			
				var arr:Array<FlxColor> = ClientPrefs.columnColors[idx];
				newRGB.r = arr[0];
				newRGB.g = arr[1];
				newRGB.b = arr[2];
			}
		}
		return globalRgbShaders[idx];
	}

	private function set_noteType(value:String):String {
		noteSplashTexture = PlayState.SONG.splashSkin;

		updateColours();
		
		if(noteData > -1 && noteType != value) {
			noteScript = null;
			switch(value) {
				case 'Hurt Note':
					ignoreNote = mustPress;
					noteTypeTexture = value;
					noteSplashTexture = 'HURTnoteSplashes';
					rgbShader.enabled = false;
					if(isSustainNote) {
						missHealth = 0.1;
					} else {
						missHealth = 0.3;
					}
					hitCausesMiss = true;

				case 'No Animation':
					noAnimation = true;
					noMissAnimation = true;
				case 'GF Sing':
					gfNote = true;
				default:
					if (!inEditor && PlayState.instance != null)
						noteScript = PlayState.instance.notetypeScripts.get(value);
					else if(inEditor && ChartingState.instance!=null)
						noteScript = ChartingState.instance.notetypeScripts.get(value);
					
					if (noteScript != null && noteScript is FunkinHScript)
					{
						var noteScript:FunkinHScript = cast noteScript;
						noteScript.executeFunc("setupNote", [this], this, ["this" => this]);
					}
						
			}
			noteType = value;
		}

		if (noteScript != null && noteScript is FunkinHScript)
		{
			var noteScript:FunkinHScript = cast noteScript;
			noteScript.executeFunc("postSetupNote", [this], this, ["this" => this]);
		}
		return value;
	}

	public var style:String = '';

	public function new(strumTime:Float, noteData:Int, ?prevNote:Note, ?sustainNote:Bool = false,?style:String = '', ?inEditor:Bool = false)
	{
		super();
		this.strumTime = strumTime;
		this.noteData = noteData;
		this.prevNote = (prevNote==null) ? this : prevNote;
		this.isSustainNote = sustainNote;
		this.inEditor = inEditor;
		this.style = style;

		if (canQuant && ClientPrefs.noteSkin == 'Quants'){
			if(prevNote != null && isSustainNote)
				quant = prevNote.quant;
			else
				quant = getQuant(Conductor.getBeatSinceChange(strumTime));
		}
		beat = Conductor.getBeat(strumTime);

/*
		x += PlayState.STRUM_X + 50;
		y -= 2000; // MAKE SURE ITS DEFINITELY OFF SCREEN?
		*/

		if(!inEditor){ 
			this.strumTime += ClientPrefs.noteOffset;
			visualTime = PlayState.instance.getNoteInitialTime(this.strumTime);
		}

		if(noteData > -1) {
			texture = '';
			rgbShader = new RGBPalette();
			shader = rgbShader.shader;

			//x += swagWidth * (noteData);
			if(!isSustainNote && noteData > -1 && noteData < 4) { //Doing this 'if' check to fix the warnings on Senpai songs
				var animToPlay:String = '';
				animToPlay = colArray[noteData % 4];
				animation.play(animToPlay + 'Scroll');
			}
		}

		// trace(prevNote);

		if(prevNote!=null)
			prevNote.nextNote = this;

		if (isSustainNote && prevNote != null)
		{
			sustainMult = 0.5; // early hit mult but just so note-types can set their own and not have sustains fuck them
			if (ClientPrefs.noteType == "Scalable") {
				alpha = 1;
				// multAlpha = 1;
			} else {
				alpha = 0.6;
				// multAlpha = 0.6;
			}
			hitsoundDisabled = true;
			copyAngle = false;
			//if(ClientPrefs.downScroll) flipY = true;

			//offsetX += width* 0.5;

			if (pixelNote)
				offsetX += 30;

			animation.play(colArray[noteData % 4] + 'holdend');

			updateHitbox();

			//offsetX -= width* 0.5;

			if (prevNote.isSustainNote)
			{
				prevNote.animation.play(colArray[prevNote.noteData % 4] + 'hold');

				prevNote.scale.y *= Conductor.stepCrochet / 100 * 1.5 * PlayState.instance.songSpeed * 100;

				if (pixelNote)
				{
					prevNote.scale.y *= 1.19;
					prevNote.scale.y *= (6 / height); // Auto adjust note size
				}
				
				prevNote.updateHitbox();
				prevNote.defScale.copyFrom(prevNote.scale);
				// prevNote.setGraphicSize();
			}

			if (pixelNote)
			{
				scale.y *= PlayState.daPixelZoom;
				updateHitbox();
			}
		}
		defScale.copyFrom(scale);
		//x += offsetX;
	}

	public static var quantShitCache = new Map<String, String>();
	var lastNoteOffsetXForPixelAutoAdjusting:Float = 0;
	public var originalHeightForCalcs:Float = 6;

	public function reloadNote(skin:String = '',type:String = '')
	{
		if (noteScript != null && noteScript is FunkinHScript)
		{
			var noteScript:FunkinHScript = cast noteScript;
			if (noteScript.executeFunc("onReloadNote", [this,skin,type], this) == Globals.Function_Stop)
				return;
		}

		skin = style;
	
		var animName:String = animation.curAnim != null ? animation.curAnim.name : null;
		var lastScaleY:Float = scale.y;
	
		var wasQuant = isQuant;
		isQuant = false;
	
		if (canQuant && ClientPrefs.noteSkin == 'Quants')
		{
			isQuant = true;
		}
		else
		{
			isQuant = false;
		}
	
		switch (ClientPrefs.noteType)
		{
			case 'Scalable': // Force use the skin
				frames = Paths.getSparrowAtlas('noteSkin/ScalableNOTE_assets');
				loadNoteAnims();
			
				pixelNote = false;
			default:
				switch (skin)
				{
					case 'pixel':
						if (isSustainNote)
						{
							loadGraphic(Paths.image('noteSkin/PIXEL_NOTE_assets' + 'ENDS'));
							width = width / 4;
							height = height / 2;
							originalHeightForCalcs = height;
							loadGraphic(Paths.image('noteSkin/PIXEL_NOTE_assets' + 'ENDS'), true, Math.floor(width), Math.floor(height));
						}
						else
						{
							loadGraphic(Paths.image('noteSkin/PIXEL_NOTE_assets'));
							width = width / 4;
							height = height / 5;
							loadGraphic(Paths.image('noteSkin/PIXEL_NOTE_assets'), true, Math.floor(width), Math.floor(height));
						}
			
						if (isSustainNote)
						{
							offsetX += lastNoteOffsetXForPixelAutoAdjusting;
							lastNoteOffsetXForPixelAutoAdjusting = (width - 7) * (PlayState.daPixelZoom / 2);
							offsetX -= lastNoteOffsetXForPixelAutoAdjusting;
						}
			
						loadPixelNoteAnims();
			
						setGraphicSize(Std.int(width * PlayState.daPixelZoom));
						updateHitbox();
			
						antialiasing = false;
						usesDefaultColours = false;
						pixelNote = true;
					default:					
						frames = Paths.getSparrowAtlas('noteSkin/NOTE_assets');
						loadNoteAnims();
			
						pixelNote = false;
				}

				if (!inEditor && PlayState.instance != null)
					skinScript = PlayState.instance.noteskinScripts.get(skin);
				else if(inEditor && ChartingState.instance!=null)
					skinScript = ChartingState.instance.noteskinScripts.get(skin);
			
				if (skinScript != null && skinScript is FunkinHScript){
					var skinScript:FunkinHScript = cast skinScript;
					skinScript.executeFunc("ReloadNoteSkin", [this], this);
				}
		}
	
		addCustomNote(type);
	
		if (wasQuant != isQuant)
			updateColours();
			
		if(isSustainNote) {
			scale.y = lastScaleY;
		}
		defScale.copyFrom(scale);
		updateHitbox();
	
		if(animName != null)
			animation.play(animName, true);
	
		if(inEditor){
			setGraphicSize(ChartingState.GRID_SIZE, ChartingState.GRID_SIZE);
			updateHitbox();
		}
	
		if (noteScript != null && noteScript is FunkinHScript)
		{
			var noteScript:FunkinHScript = cast noteScript;
			noteScript.executeFunc("postReloadNote", [this,skin,type], this);
		}
	}

	function addCustomNote(type:String) {
		switch (type)
		{
			case 'Hurt Note':
				frames = Paths.getSparrowAtlas('noteType/HURTNOTE_assets');
				loadNoteAnims();

				pixelNote = false;
		}

		if (noteScript != null && noteScript is FunkinHScript){
			var noteScript:FunkinHScript = cast noteScript;
			if (noteScript.exists("loadNoteTypeAnims") && Reflect.isFunction(noteScript.get("loadNoteTypeAnims"))){
				noteScript.executeFunc("loadNoteTypeAnims", [this, type], this);
			}
		}
	}

	public function loadNoteAnims() {
		if (noteScript != null && noteScript is FunkinHScript){
			var noteScript:FunkinHScript = cast noteScript;
			if (noteScript.exists("loadNoteAnims") && Reflect.isFunction(noteScript.get("loadNoteAnims"))){
				noteScript.executeFunc("loadNoteAnims", [this], this, ["super" => _loadNoteAnims]);
				return;
			}
		}
		_loadNoteAnims();
	}

	function _loadNoteAnims() {
		switch (texture)
		{
			default:
				animation.addByPrefix(colArray[noteData] + 'Scroll', colArray[noteData] + '0');

				if (isSustainNote)
				{
					animation.addByPrefix('purpleholdend', 'pruple end hold'); // ?????
					animation.addByPrefix(colArray[noteData] + 'holdend', colArray[noteData] + ' hold end');
					animation.addByPrefix(colArray[noteData] + 'hold', colArray[noteData] + ' hold piece');
				}
		
				setGraphicSize(Std.int(width * 0.7));
				updateHitbox();
		}
	}

	function loadPixelNoteAnims()
	{
		if (isSustainNote)
		{
			animation.add(colArray[noteData] + 'holdend', [pixelInt[noteData] + 4]);
			animation.add(colArray[noteData] + 'hold', [pixelInt[noteData]]);
		}
		else
		{
			animation.add(colArray[noteData] + 'Scroll', [pixelInt[noteData] + 4]);
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

/* 		if (isSustainNote)
		{
			if (prevNote != null && prevNote.isSustainNote)
				zIndex = z + prevNote.zIndex;
			
			else if (prevNote != null && !prevNote.isSustainNote)
				zIndex = z + prevNote.zIndex - 1;
			
		}
		else
			zIndex = z;
		

		zIndex += desiredZIndex;
		zIndex -= (mustPress == true ? 0 : 1); */

		if(!inEditor){
			if (noteScript != null && noteScript is FunkinHScript){
				var noteScript:FunkinHScript = cast noteScript;
				noteScript.executeFunc("noteUpdate", [elapsed], this);
			}

			if (skinScript != null && skinScript is FunkinHScript){
				var skinScript:FunkinHScript = cast skinScript;
				skinScript.executeFunc("noteUpdate", [elapsed], this);
			}
		}
	
		
		if (hitByOpponent)
			wasGoodHit = true;
		var diff = (strumTime - Conductor.songPosition);
		if (diff < -Conductor.safeZoneOffset && !wasGoodHit)
			tooLate = true;

		if (tooLate && !inEditor)
		{
			if (alpha > 0.3)
				alpha = 0.3;
		}
	}
}
