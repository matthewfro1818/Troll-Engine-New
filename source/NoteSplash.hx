package;

import shaders.RGBPalette;
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import math.Vector3;

class NoteSplash extends NoteObject
{
	public var noteType:String;
	public var useRGBColors:Bool = true;

	public var animOffsets:Map<String, Array<Dynamic>>;
	public var rgbShader:RGBPalette = null;
	public var vec3Cache:Vector3 = new Vector3();

	public var animationAmount:Int = 2;

	public function new(x:Float = 0, y:Float = 0, type:String, data:Int, redColor:FlxColor = 0, greenColor:FlxColor = 0, blueColor:FlxColor = 0)
	{
		super(x, y);
		#if (haxe >= "4.0.0")
		animOffsets = new Map();
		#else
		animOffsets = new Map<String, Array<Dynamic>>();
		#end

		noteType = type;
		noteData = data;
		rgbShader = new RGBPalette();
		rgbShader.enabled = true;
		rgbShader.r = redColor;
		rgbShader.g = 0xffffff;
		rgbShader.b = 0xffffff;

		switch (noteType)
		{
			default:
				switch (PlayState.splashSkin)
				{
					case 'tenzus':
						frames = Paths.getSparrowAtlas('noteSplash/tenzus_splash', 'shared');

						for (i in 1...animationAmount+1) {
							animation.addByPrefix("note1-" + i, "note splash blue " + i, 24, false);
							animation.addByPrefix("note2-" + i, "note splash green " + i, 24, false);
							animation.addByPrefix("note0-" + i, "note splash purple " + i, 24, false);
							animation.addByPrefix("note3-" + i, "note splash red " + i, 24, false);
						}

						rgbShader.enabled = false;

						scale.set(0.8, 0.8);
						updateHitbox();
					default:
						frames = Paths.getSparrowAtlas('noteSplash/noteSplashes', 'shared');

						for (i in 1...animationAmount+1)
						{
							animation.addByPrefix("note1-" + i, "note splash blue " + i, 24, false);
							animation.addByPrefix("note2-" + i, "note splash green " + i, 24, false);
							animation.addByPrefix("note0-" + i, "note splash purple " + i, 24, false);
							animation.addByPrefix("note3-" + i, "note splash red " + i, 24, false);
						}

						scale.set(0.8, 0.8);
						updateHitbox();
	
						offset.x += 90;
						offset.y += 80;
				}
		}

		shader = rgbShader.shader;
		alpha = 0.6;
	}

	public function playStatePlay()
	{
		switch (noteType)
		{
			default:
				switch (PlayState.splashSkin)
				{
					case 'tenzus':
						animation.play('note$noteData-${FlxG.random.int(1, animationAmount)}', true);
						if (animation.curAnim != null) 
							animation.curAnim.frameRate = 24 + FlxG.random.int(-2, 2);
					default:
						if (ClientPrefs.noteSkin == 'Quants') 
							animation.play('note$noteData-${FlxG.random.int(1, animationAmount)}', true);
						else
							animation.play('note$noteData-${FlxG.random.int(1, animationAmount)}', true);
				}
		}
	}

	override function update(elapsed:Float) 
	{
		if(animation.curAnim != null && animation.curAnim.finished) 
			kill();

		super.update(elapsed);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
}
