function setupNote(note:Note){
    note.noteTypeTexture = "mines";
    note.ignoreNote = true;
    note.hitCausesMiss = true;
    note.noAnimation = true;
    note.noMissAnimation = true;
}

var MINE_JUDGE:String = 'MY_MINE';

function onCreate(){
	judgeManager.judgmentData.set(MINE_JUDGE, {
		internalName: "mine", // name used for the image, counters internally, etc. Leave this as 'miss' so when you miss it'll show the fail image, add to the miss counter, etc.
		displayName: "Mine", // display name, not used atm but will prob be used in judge counter
		window: 75, // hit window in ms
		score: -350, // score to take away
		accuracy: -100, // % accuracy to add/take away on non-Wife3
		health: -10, // % of health to add/remove
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
    FlxG.sound.play(Paths.sound("mineExplode"));
}

var colArray:Array<String> = ['purple', 'blue', 'green', 'red'];
function loadNoteTypeAnims(note:Note, type:String){
    if (type == 'mines'){
        note.frames = Paths.getSparrowAtlas('noteType/MINENOTE_assets');
        note.animation.addByPrefix("greenScroll", "green0");
        note.animation.addByPrefix("redScroll", "red0");
        note.animation.addByPrefix("blueScroll", "blue0");
        note.animation.addByPrefix("purpleScroll", "purple0");

		if (note.isSustainNote)
		{
			note.animation.addByPrefix(colArray[note.noteData] + 'holdend', colArray[note.noteData] + ' hold end');
			note.animation.addByPrefix(colArray[note.noteData] + 'hold', colArray[note.noteData] + ' hold piece');
		}

        note.usesDefaultColours = false;
        note.rgbShader.enabled = false;

        note.setGraphicSize(Std.int(note.width * 0.7));
		note.updateHitbox();
    }
}
