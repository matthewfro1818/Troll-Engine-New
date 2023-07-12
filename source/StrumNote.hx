package;

import shaders.RGBPalette;
import scripts.FunkinHScript;
import scripts.FunkinScript;
import flixel.util.FlxColor;
#if !macro
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
#end
import math.Vector3;

using StringTools;

class StrumNote extends NoteObject
{

	public var vec3Cache:Vector3 = new Vector3(); // for vector3 operations in modchart code

	public var zIndex:Float = 0;
	public var desiredZIndex:Float = 0;
	public var z:Float = 0;

	public var skinScript:FunkinScript;
	
	override function destroy()
	{
		defScale.put();
		super.destroy();
	}	
	public var isQuant:Bool = false;
	public var rgbShader:RGBPalette;
	public var currentRed:FlxColor;
	public var pixelStrums:Bool = false;
	public var resetAnim:Float = 0;
	public var direction:Float = 90;//plan on doing scroll directions soon -bb
	public var downScroll:Bool = false;//plan on doing scroll directions soon -bb
	public var sustainReduce:Bool = true;
	
	//private var player:Int;

	public var texture(default, set):String = null;
	private function set_texture(value:String):String {
		if(texture != value) {
			texture = value;
			reloadNote();
		}
		return value;
	}

	public function getZIndex(?daZ:Float)
	{
		if(daZ==null)daZ = z;
		var animZOffset:Float = 0;
		if (animation.curAnim != null && animation.curAnim.name == 'confirm')
			animZOffset += 1;
		return z + desiredZIndex + animZOffset;
	}

	function updateZIndex()
	{
		zIndex = getZIndex();
	}
	

	public function new(x:Float, y:Float, leData:Int, ?skin:String = 'NOTE_assets') {
		rgbShader = new RGBPalette();
		shader = rgbShader.shader;
		super(x, y);
		noteData = leData;
		// trace(noteData);

		currentRed = 0xffffff;
		if (skin == '' || skin == null)
			skin = 'NOTE_assets';
		texture = skin; // Load texture and anims

		scrollFactor.set();
	}

	public function reloadNote()
	{
		isQuant = false;
	
		if (texture == null || texture.length < 1)
		{
			texture = 'noteSkin/QUANTNOTE_assets';
		}
	
		var lastAnim:String = null;
		if(animation.curAnim != null) lastAnim = animation.curAnim.name;
	
		if (ClientPrefs.noteSkin == 'Quants')
		{
			isQuant = true;
		}
		else
		{
			isQuant = false; 
		}
	
		switch (texture)
		{
			case 'pixel':
				loadGraphic(Paths.image('noteSkin/PIXEL_NOTE_assets'));
				width = width / 4;
				height = height / 5;
				loadGraphic(Paths.image('noteSkin/PIXEL_NOTE_assets'), true, Math.floor(width), Math.floor(height));
	
				antialiasing = false;
				rgbShader.enabled = false;
				setGraphicSize(Std.int(width * PlayState.daPixelZoom));
				updateHitbox();
	
				// animation.add('green', [6]);
				// animation.add('red', [7]);
				// animation.add('blue', [5]);
				// animation.add('purple', [4]);
				switch (Math.abs(noteData) % 4)
				{
					case 0:
						animation.add('static', [0]);
						animation.add('pressed', [4, 8], 12, false);
						animation.add('confirm', [12, 16], 24, false);
					case 1:
						animation.add('static', [1]);
						animation.add('pressed', [5, 9], 12, false);
						animation.add('confirm', [13, 17], 24, false);
					case 2:
						animation.add('static', [2]);
						animation.add('pressed', [6, 10], 12, false);
						animation.add('confirm', [14, 18], 12, false);
					case 3:
						animation.add('static', [3]);
						animation.add('pressed', [7, 11], 12, false);
						animation.add('confirm', [15, 19], 24, false);
				}
			default:
				frames = Paths.getSparrowAtlas('noteSkin/NOTE_assets');
				loadStrumAnims();
		}
	
		if (PlayState.instance != null)
			skinScript = PlayState.instance.noteskinScripts.get(texture);
	
		if (skinScript != null && skinScript.scriptType == 'hscript'){
			var skinScript:FunkinHScript = cast skinScript;
			skinScript.executeFunc("ReloadStrumsSkin", [this], this);
		}
			
		defScale.copyFrom(scale);
		updateHitbox();
	
		if(lastAnim != null)
		{
			playAnim(lastAnim, true);
		}
	}

	public function loadStrumAnims() {
		if (skinScript != null && skinScript.scriptType == 'hscript'){
			var skinScript:FunkinHScript = cast skinScript;
			if (skinScript.exists("loadStrumAnims") && Reflect.isFunction(skinScript.get("loadStrumAnims"))){
				skinScript.executeFunc("loadStrumAnims", [this], this, ["super" => _loadStrumAnims]);
				return;
			}
		}
		_loadStrumAnims();
	}

	public function _loadStrumAnims() {
		switch (texture)
		{
			default:
				animation.addByPrefix('green', 'arrowUP');
				animation.addByPrefix('blue', 'arrowDOWN');
				animation.addByPrefix('purple', 'arrowLEFT');
				animation.addByPrefix('red', 'arrowRIGHT');
				switch (Math.abs(noteData) % 4)
				{
					case 0:
						animation.addByPrefix('static', 'arrowLEFT');
						animation.addByPrefix('pressed', 'left press', 24, false);
						animation.addByPrefix('confirm', 'left confirm', 24, false);
					case 1:
						animation.addByPrefix('static', 'arrowDOWN');
						animation.addByPrefix('pressed', 'down press', 24, false);
						animation.addByPrefix('confirm', 'down confirm', 24, false);
					case 2:
						animation.addByPrefix('static', 'arrowUP');
						animation.addByPrefix('pressed', 'up press', 24, false);
						animation.addByPrefix('confirm', 'up confirm', 24, false);
					case 3:
						animation.addByPrefix('static', 'arrowRIGHT');
						animation.addByPrefix('pressed', 'right press', 24, false);
						animation.addByPrefix('confirm', 'right confirm', 24, false);
				}
		
				antialiasing = ClientPrefs.globalAntialiasing;
				setGraphicSize(Std.int(width * 0.7));
		}
	}

/* 	public function postAddedToGroup() {
		playAnim('static');
		x += Note.swagWidth * noteData;
		x += 50;
		x += ((FlxG.width* 0.5) * player);
		ID = noteData;
	} */
	public function postAddedToGroup()
	{
		playAnim('static');
		x -= Note.swagWidth / 2;
		x = x - (Note.swagWidth * 2) + (Note.swagWidth * noteData) + 54;

		ID = noteData;
	}

	override function update(elapsed:Float) {
		if(resetAnim > 0) {
			resetAnim -= elapsed;
			if(resetAnim <= 0) {
				playAnim('static');
				resetAnim = 0;
			}
		}
		if(animation.curAnim != null){
			if(animation.curAnim.name == 'confirm') 
				centerOrigin();
			
		}
		updateZIndex();

		super.update(elapsed);
	}

	public function playAnim(anim:String, ?force:Bool = false, ?note:Note) {
		animation.play(anim, force);
		centerOffsets();
		centerOrigin();
		updateZIndex();

		rgbShader.enabled = false;
		
		if(animation.curAnim == null || animation.curAnim.name == 'static') {
			rgbShader.enabled = false;
		} else {
			if (note == null)
			{
				if(!isQuant){
					rgbShader.r = ClientPrefs.columnColors[noteData % 4][0];
					rgbShader.g = ClientPrefs.columnColors[noteData % 4][1];
					rgbShader.b = ClientPrefs.columnColors[noteData % 4][2];
					rgbShader.enabled = true;
				}
				else
				{
					rgbShader.enabled = false;
				}
			}
			else
			{
				// ok now the quants should b fine lol
				rgbShader.enabled = true;
				rgbShader.r = note.rgbShader.r;
				rgbShader.g = note.rgbShader.g;
				rgbShader.b = note.rgbShader.b;
			}
		}
	}
}