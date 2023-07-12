package options;

import shaders.RGBPalette;
#if discord_rpc
import Discord.DiscordClient;
#end
import Controls;
import flash.text.TextField;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.display.FlxGridOverlay;
import flixel.graphics.FlxGraphic;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxSave;
import flixel.util.FlxTimer;
import haxe.Json;
import flixel.math.FlxPoint;
import lime.utils.Assets;

using StringTools;

class NotesSubStateRGB extends MusicBeatSubstate
{
	var curSelected:Int = 0;
	var typeSelected:Int = 0;
	private var grpNumbers:FlxTypedGroup<Alphabet>;
	private var grpNotes:FlxTypedGroup<FlxSprite>;
	private var shaderArray:Array<RGBPalette> = [];
	var curValue:Float = 0;
	var holdTime:Float = 0;
	var nextAccept:Int = 5;

	var blackBG:FlxSprite;
	var hsbText:Alphabet;

	var posX = 230;
	var daCam:FlxCamera;
	var cambg:FlxCamera;

	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var origCamFollow:FlxPoint = new FlxPoint();

	public var defaultColumnColors:Array<Array<Int>> = [
		[0xC24B99, 0xFFFFFFFF, 0x3C1F56], // Left
		[0x00FFFF, 0xFFFFFFFF, 0x004a54], // Down
		[0x12FA05, 0xFFFFFFFF, 0x034415], // UP
		[0xF9393F, 0xFFFFFFFF, 0x651038], // Right
	];

	public function new() {
		super();

		cambg = new FlxCamera();
		cambg.bgColor.alpha = 0;
		FlxG.cameras.add(cambg, false);

		daCam = new FlxCamera();
		daCam.bgColor.alpha = 0;
		FlxG.cameras.add(daCam, false);

		origCamFollow.copyFrom(daCam.scroll);
		
		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

/* 		var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('newmenuu/optionsbg'));
		//bg.color = 0xFFea71fd;
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		var backdrop = new flixel.addons.display.FlxBackdrop(Paths.image("grid"));
		var time = Sys.time();
		backdrop.setPosition(time * 30, time * 30);
		backdrop.velocity.set(30, 30);
		backdrop.alpha = 0.15;
		add(backdrop); */

		var backdrop = new FlxSprite().makeGraphic(1, 1, FlxColor.BLACK);
		backdrop.setGraphicSize(FlxG.width, FlxG.height);
		backdrop.updateHitbox();
		backdrop.screenCenter(XY);
		backdrop.alpha = 0.5;
		add(backdrop);


		blackBG = new FlxSprite(posX - 25).makeGraphic(870, 200, FlxColor.BLACK);
		blackBG.alpha = 0.4;
		add(blackBG);

		grpNotes = new FlxTypedGroup<FlxSprite>();
		add(grpNotes);
		grpNumbers = new FlxTypedGroup<Alphabet>();
		add(grpNumbers);

		daCam.follow(camFollowPos, null, 1);

		var optionText:Alphabet;
		var spacing:Float = 200;
		var off:Float = 250;
		for (i in 0...ClientPrefs.columnColors.length) {
			var yPos:Float = (165 * i) + 35;
			yPos = (195 * i) + 35;
			for (j in 0...9) {
				var set = ClientPrefs.columnColors[i];
				var color:FlxColor = set[Std.int(j/3)];
				var text = [color.red, color.green, color.blue][j%3];
				optionText = new Alphabet(0, yPos + 60 - 20 + (70 * Std.int(j/3)), Std.string(text), true);
				optionText.x = posX + (spacing * (j % 3)) + off;
				updateOffset(optionText, text);
				grpNumbers.add(optionText);
			}

			var note:FlxSprite = new FlxSprite(posX, yPos);
			note.frames = Paths.getSparrowAtlas(('noteSkin/NOTE_assets'));
			var animations:Array<String> = ['purple0', 'blue0', 'green0', 'red0'];
			note.animation.addByPrefix('idle', animations[i]);
			note.animation.play('idle');
			note.antialiasing = ClientPrefs.globalAntialiasing;
			grpNotes.add(note);

			var newShader:RGBPalette = new RGBPalette();
			note.shader = newShader.shader;
			newShader.r = ClientPrefs.columnColors[i][0];
			newShader.g = ClientPrefs.columnColors[i][1];
			newShader.b = ClientPrefs.columnColors[i][2];
			shaderArray.push(newShader);
		}

		hsbText = new Alphabet(0, 0, "R       G       B", true, false, 0, 0.65);
		hsbText.x = posX + 240;
		add(hsbText);

		changeSelection();
		camFollowPos.setPosition(camFollow.x, camFollow.y);
		cameras = [daCam];
		backdrop.cameras = [cambg];
	}

	var changingNote:Bool = false;
	override function update(elapsed:Float) {
		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if(changingNote) {
			if(holdTime < 0.5) {
				if(controls.UI_LEFT_P) {
					updateValue(-1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.UI_RIGHT_P) {
					updateValue(1);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				} else if(controls.RESET) {
					resetValue(curSelected, typeSelected);
					FlxG.sound.play(Paths.sound('scrollMenu'));
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					holdTime = 0;
				} else if(controls.UI_LEFT || controls.UI_RIGHT) {
					holdTime += elapsed;
				}
			} else {
				var add:Float = 90;
				switch(typeSelected) {
					case 1 | 2: add = 50;
				}
				if(controls.UI_LEFT) {
					updateValue(elapsed * -add);
				} else if(controls.UI_RIGHT) {
					updateValue(elapsed * add);
				}
				if(controls.UI_LEFT_R || controls.UI_RIGHT_R) {
					FlxG.sound.play(Paths.sound('scrollMenu'));
					holdTime = 0;
				}
			}
		} else {
			if (controls.UI_UP_P) {
				changeSelection(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_DOWN_P) {
				changeSelection(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_LEFT_P) {
				changeType(-1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.UI_RIGHT_P) {
				changeType(1);
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if(controls.RESET) {
				var perNums = 9;
				for (i in 0...perNums) {
					resetValue(curSelected, i);
				}
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
			if (controls.ACCEPT && nextAccept <= 0) {
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changingNote = true;
				holdTime = 0;
				var perNums = 9;
				for (i in 0...grpNumbers.length) {
					var item = grpNumbers.members[i];
					item.alpha = 0;
					if ((curSelected * perNums) + typeSelected == i) {
						item.alpha = 1;
					}
				}
				for (i in 0...grpNotes.length) {
					var item = grpNotes.members[i];
					item.alpha = 0;
					if (curSelected == i) {
						item.alpha = 1;
					}
				}
				super.update(elapsed);
				return;
			}
		}

		if (controls.BACK || (changingNote && controls.ACCEPT)) {
			if(!changingNote) {
				camFollowPos.setPosition(origCamFollow.x, origCamFollow.y);
				daCam.follow(null, null, 1);
				daCam.scroll.copyFrom(origCamFollow);
				FlxG.cameras.remove(daCam);
				close();
			} else {
				changeSelection();
			}
			changingNote = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
		}

		if(nextAccept > 0) {
			nextAccept -= 1;
		}
		super.update(elapsed);
	}

	function changeSelection(change:Int = 0) {
		if(!FlxG.keys.pressed.SHIFT) {
			if(change > 0) {
				if(typeSelected < 3) {
					changeType(3);
					return;
				} else {
					changeType(-3);
				}
			} else if(change < 0) {
				if(typeSelected >= 3) {
					changeType(-3);
					return;
				} else {
					changeType(3);
				}
			}
		}
		curSelected += change;
		if (curSelected < 0)
			curSelected = ClientPrefs.columnColors.length-1;
		if (curSelected >= ClientPrefs.columnColors.length)
			curSelected = 0;

		var set = ClientPrefs.columnColors[curSelected];
		var color:FlxColor = set[Std.int(typeSelected/3)];
		curValue = [color.red, color.green, color.blue][typeSelected%3];
		updateValue();

		var perNums = 9;

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * perNums) + typeSelected == i) {
				item.alpha = 1;
			}
		}
		for (i in 0...grpNotes.length) {
			var item = grpNotes.members[i];
			item.alpha = 0.6;
			item.scale.set(0.75, 0.75);
			if (curSelected == i) {
				item.alpha = 1;
				item.scale.set(1, 1);
				hsbText.y = item.y - 70;
				blackBG.y = item.y - 20;

				camFollow.setPosition(FlxG.width / 2, item.getGraphicMidpoint().y);
			}
		}
		FlxG.sound.play(Paths.sound('scrollMenu'));
	}

	function changeType(change:Int = 0) {
		var perNums = 9;
		typeSelected += change;
		if (typeSelected < 0)
			typeSelected = perNums-1;
		if (typeSelected > perNums-1)
			typeSelected = 0;

		var set = ClientPrefs.columnColors[curSelected];
		var color:FlxColor = set[Std.int(typeSelected/3)];

		curValue = [color.red, color.green, color.blue][typeSelected%3];
		updateValue();

		for (i in 0...grpNumbers.length) {
			var item = grpNumbers.members[i];
			item.alpha = 0.6;
			if ((curSelected * perNums) + typeSelected == i) {
				item.alpha = 1;
			}
		}
	}

	function resetValue(selected:Int, type:Int) {
		var rbI = Std.int(type/3);
		var color:FlxColor = defaultColumnColors[selected][rbI];
		curValue = [color.red, color.green, color.blue][type%3];

		var red:FlxColor = ClientPrefs.columnColors[selected][0];
		var green:FlxColor = ClientPrefs.columnColors[selected][1];
		var blue:FlxColor = ClientPrefs.columnColors[selected][2];

		var rounded = Math.round(curValue);

		if(FlxG.keys.pressed.SHIFT) {
			switch(type) {
				case 0: red.red = 0;
				case 1: red.green = 0;
				case 2: red.blue = 0;
				case 3: green.red = 0;
				case 4: green.green = 0;
				case 5: green.blue = 0;
				case 6: blue.red = 0;
				case 7: blue.green = 0;
				case 8: blue.blue = 0;
			}
		} else {
			switch(type) {
				case 0: red.red = rounded;
				case 1: red.green = rounded;
				case 2: red.blue = rounded;
				case 3: green.red = rounded;
				case 4: green.green = rounded;
				case 5: green.blue = rounded;
				case 6: blue.red = rounded;
				case 7: blue.green = rounded;
				case 8: blue.blue = rounded;
			}
		}

		ClientPrefs.columnColors[selected] = [red,green, blue];

		shaderArray[selected].r = ClientPrefs.columnColors[selected][0];
		shaderArray[selected].g = ClientPrefs.columnColors[selected][1];
		shaderArray[selected].b = ClientPrefs.columnColors[selected][2];

		var perNums = 9;
		var item = grpNumbers.members[(selected * perNums) + type];
		if(FlxG.keys.pressed.SHIFT)
			item.changeText('0');
		else
			item.changeText(Std.string(curValue));
		item.offset.x = (40 * (item.lettersArray.length - 1))* 0.5;
	}
	function updateValue(change:Float = 0) {
		curValue += change;
		var roundedValue:Int = Math.round(curValue);
		var max:Float = 255;
		var min:Float = 0;

		if(roundedValue < min) {
			curValue = min;
		} else if(roundedValue > max) {
			curValue = max;
		}
		roundedValue = Math.round(curValue);
		var red:FlxColor = ClientPrefs.columnColors[curSelected][0];
		var green:FlxColor = ClientPrefs.columnColors[curSelected][1];
		var blue:FlxColor = ClientPrefs.columnColors[curSelected][2];

		//var currentColor:FlxColor = ClientPrefs.columnColors[curSelected][Std.int(typeSelected/3)];

		switch(typeSelected) {
			case 0: red.red = roundedValue;
			case 1: red.green = roundedValue;
			case 2: red.blue = roundedValue;
			case 3: blue.red = roundedValue;
			case 4: blue.green = roundedValue;
			case 5: blue.blue = roundedValue;
			case 6: green.red = roundedValue;
			case 7: green.green = roundedValue;
			case 8: green.blue = roundedValue;
		}

		ClientPrefs.columnColors[curSelected] = [red,green, blue];

		shaderArray[curSelected].r = red;
		shaderArray[curSelected].g = green;
		shaderArray[curSelected].b = blue;

		var perNums = 9;
		var item = grpNumbers.members[(curSelected * perNums) + typeSelected];
		item.changeText(Std.string(roundedValue));
		item.offset.x = (40 * (item.lettersArray.length - 1))* 0.5;
		if(roundedValue < 0) item.offset.x += 10;
	}

	function updateOffset(alph:Alphabet, value:Int) {
		alph.offset.x = (40 * (alph.lettersArray.length - 1)) / 2;
		if(value < 0) alph.offset.x += 10;
	}
}
