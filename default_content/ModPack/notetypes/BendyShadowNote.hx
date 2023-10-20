function setupNote(note:Note){
    note.noteTypeTexture = "bendyShadow";
    note.ignoreNote = true;
    note.hitCausesMiss = false;
    note.noAnimation = true;
    note.noMissAnimation = true;
}

var MINE_JUDGE:String = 'BendyShadow';
var UNJUDGED = 'none';

function onCreate(){
	judgeManager.judgmentData.set(MINE_JUDGE, {
		internalName: "bendyshadow", // name used for the image, counters internally, etc. Leave this as 'miss' so when you miss it'll show the fail image, add to the miss counter, etc.
		displayName: "BendyShadow", // display name, not used atm but will prob be used in judge counter
		window: 45, // hit window in ms
		score: -350, // score to take away
		accuracy: -100, // % accuracy to add/take away on non-Wife3
		health: -30, // % of health to add/remove
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

function goodNoteHit(note:Note){
    FlxG.sound.play(Paths.sound("bendy/inked"));
}

function loadNoteTypeAnims(note:Note, type:String){
    if (type == 'bendyShadow'){
        if (ClientPrefs.downScroll)
        {
            note.frames = Paths.getSparrowAtlas('bendy/NOTE_sin_notes_downscroll');
            note.animation.addByPrefix("greenScroll", "downscrollu");
            note.animation.addByPrefix("redScroll", "downscrollright");
            note.animation.addByPrefix("blueScroll", "downscrolldown");
            note.animation.addByPrefix("purpleScroll", "downscrollleft");

            note.typeOffsetY = -10;
        } else {
            note.frames = Paths.getSparrowAtlas('bendy/NOTE_sin_notes');
            note.animation.addByPrefix("greenScroll", "D-Up");
            note.animation.addByPrefix("redScroll", "D-Right");
            note.animation.addByPrefix("blueScroll", "D-Down");
            note.animation.addByPrefix("purpleScroll", "D-Left");
            
            note.typeOffsetY = 29;
        }

        if (!ClientPrefs.mechanics && !note.inEditor) {
            note.alpha = 0;
            note.kill();
        }

        note.usesDefaultColours = false;
        note.rgbShader.enabled = false;

        note.setGraphicSize(Std.int(note.width * 0.7));
		note.updateHitbox();
    }
}
