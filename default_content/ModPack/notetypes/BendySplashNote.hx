function setupNote(note:Note){
    note.noteTypeTexture = "bendySplash";
    note.ignoreNote = true;
    note.hitCausesMiss = false;
    note.noAnimation = true;
    note.noMissAnimation = true;
}

var MINE_JUDGE:String = 'BendySplash';
var UNJUDGED = 'none';

function onCreate(){
	judgeManager.judgmentData.set(MINE_JUDGE, {
		internalName: "bendysplash", // name used for the image, counters internally, etc. Leave this as 'miss' so when you miss it'll show the fail image, add to the miss counter, etc.
		displayName: "BendySplash", // display name, not used atm but will prob be used in judge counter
		window: 45, // hit window in ms
		score: -350, // score to take away
		accuracy: -100, // % accuracy to add/take away on non-Wife3
		health: 0, // % of health to add/remove
		wifePoints: Wife3.missWeight, // makes it so that it'll take away the appropriate amount from accuracy on Wife3
        badJudgment: true, // so the hit window will never get smaller on higher judge difficulties
        hideJudge: true, // so the judgement image wont show up
		comboBehaviour: 0, // defines how this judgement affects combo. setting this to 1 makes the combo increease, -1 makes it break, and 0 makes it stay untouched.
		noteSplash: false, // whether this judge causes a notesplash
	});
}

function judgeNote(note:Note, msDiff:Float){
    if(msDiff <= judgeManager.getWindow(MINE_JUDGE))
        return MINE_JUDGE;

    return UNJUDGED;
}

var inkObj:FlxSprite;
function onCreatePost(){
    inkObj = new FlxSprite().loadGraphic(Paths.image('bendy/Damage01'));
    inkObj.setGraphicSize(Std.int(FlxG.width / game.camOverlay.zoom), Std.int(FlxG.height / game.camOverlay.zoom));
    inkObj.updateHitbox();
    inkObj.screenCenter();
    inkObj.alpha = 0.0001;
    inkObj.scrollFactor.set();
    game.add(inkObj);

    inkObj.cameras = [game.camOverlay];
}
var inkProg:Int = 0;
var inkTime:Float = 0;
var inkTimer:FlxTimer;
var inkTween:FlxTween;
function updateInkProg(num:Int = 1)
{
    FlxG.sound.play(Paths.sound('bendy/inked'));
    FlxG.camera.shake(0.03, 0.05);
    //inkTime = 1000;

    if (inkTimer != null)
        inkTimer.cancel();

    FlxTween.cancelTweensOf(inkObj);
    inkObj.alpha = 1;
    if (inkProg + 1 < 5)
    {
        inkObj.loadGraphic(Paths.image('bendy/Damage0' + (inkProg + 1)));
        switch (inkProg)
        {
            case 0:
                inkObj.alpha = 0.3;
            case 1:
                inkObj.alpha = 0.5;
            case 2:
                inkObj.alpha = 0.7;
            case 3:
                inkObj.alpha = 0.8;
            case 4:
                inkObj.alpha = 0.9;
            case 5:
                inkObj.alpha = 1;
        }
    }
    // add(inkObj);

    if (inkProg <= 4)
    {
        inkProg += num;
    }
    else
    {
        game.health = 0;
    }

    //Timer that handles the length of the ink
    inkTimer = new FlxTimer().start(2,function(tmr)
        {
            FlxTween.tween(inkObj,{alpha:0},1.2,{onComplete:function(twn)
                {
                    inkProg = 0;
                }
            });

            //inkProg = 0;

        }
        );
}

function goodNoteHit(note:Note){
    updateInkProg(1);
}

function loadNoteTypeAnims(note:Note, type:String){
    if (type == 'bendySplash'){
        note.frames = Paths.getSparrowAtlas('bendy/NOTE_ink_notes2');
        note.animation.addByPrefix("greenScroll", "up");
        note.animation.addByPrefix("redScroll", "right");
        note.animation.addByPrefix("blueScroll", "down");
        note.animation.addByPrefix("purpleScroll", "left");

        note.usesDefaultColours = false;
        note.rgbShader.enabled = false;

        if (!ClientPrefs.mechanics && !note.inEditor) {
            note.alpha = 0;
            note.kill();
        }

        note.setGraphicSize(Std.int(note.width * 0.7));
		note.updateHitbox();
    }
}
