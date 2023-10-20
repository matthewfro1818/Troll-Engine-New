function setupNote(note:Note){
  trace("Called when the note's noteType is set");
  note.canQuant = false;
  note.reloadNote("", "NOTE_assets");
}

function onReloadNote(note:Note, skin:String, type:String){
    trace("Called at the beginning of the reloadNote function");
    // can return Function_Stop to stop the note from having its texture changed
}

function postReloadNote(note:Note, skin:String, type:String){
    trace("Called at the end of the reloadNote function");
}

function loadNoteTypeAnims(note:Note,type:String) {
    trace("Adding note Type sprite");
}

function goodNoteHit(note:Note){
    trace("Called when the player hits the note");
}

function opponentNoteHit(note:Note){
    trace("Called when the opponent hits the note");
}

function judgeNote(note:Note, msDiff:Float){
    // use this to return judgements
    // if you dont return anything, after this runs it'll run the normal judgement code

    // check Mine.hx for an example of custom judgements
    /*
        judgements by their tier:
        Judgement.TIER1 - Shit/Retard
        Judgement.TIER2 - Bad/Gay
        Judgement.TIER3 - Good/Cool
        Judgement.TIER4 - Sick/Awesome
        Judgement.TIER5 - Epic/Killer
        Judgement.MISS - Miss/Fail
        Judgement.UNJUDGED - Unjudged. Return this if the note shouldn't be hit.
        JudgementHIT_MINE - Default mine hit. -200 score, 5% damage, and doesnt cause a combo break.
        Judgement.MISS_MINE - Miss/Fail, but has no damage. Used when a note has hitCausesMiss, so it can use the note's missHealth as damage.
    */
    trace("Called when the note gets judged");

    // this forces killers/awesomes
    if(msDiff <= 180){
        if(ClientPrefs.useEpics)
            return Judgement.TIER5; // epic
        else
            return Judgement.TIER4; // sick
    }
    return Judgement.UNJUDGED; // cant be hit otherwise
}

function noteMiss(note:Note){
    trace("Called when the player misses the note");
}

function update(elapsed:Float){
    // gets called once per frame while the note type is in the song. use this to update stuff like hp drain, etc.
    trace("Called every frame the notetype is active");
}

function noteUpdate(elapsed:Float){
    // gets called by every spawned note per frame, so do this for stuff that should affect each note individually.

    // 'this' refers to the current note
    trace("Called every frame the note is active, strumtime: " + this.strumTime);
}

function onLoad(){
    trace("This is called when PlayState first loads the script, usually used for preloading etc");
}

function spawnNote(note:Note){
    trace("This is called when a note of the type is spawned!");
    // return Function_Stop to stop the note from spawning
}

function postSpawnNote(note:Note){
    trace("This is called when the note is actually spawned and added to the group!");
}

/*
    Animations used by FNF are 
    For tap notes: greenScroll, redScroll, blueScroll, purpleScroll
    For holds: greenhold, greenholdend, redhold, redholdend, bluehold, blueholdend and purplehold, purpleholdend

    // green is up, red is right, blue is down, purple is left
*/

function loadPixelNoteAnims(note:Note){
    super(); // if you dont want FNF's normal note anims to be added, just omit this
    trace("This is called when the note has its pixel animations loaded!");
}