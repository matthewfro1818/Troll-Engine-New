function goodNoteHit(note:Note, field:PlayField) {
    if (note.noteType != "Attack Note")
		return;

    if(field == game.playerField) {
      bfHit(note, field);
    }
}
var shootAnimations:Array<String> = ['shootLEFT', 'shootDOWN', 'shootUP', 'shootRIGHT'];
function bfHit(note:Note, field:PlayField){
    var animToPlay:String = shootAnimations[Std.int(Math.abs(Math.min(shootAnimations.length-1, note.noteData)))];
    var boyfriend = game.boyfriend;
    boyfriend.playAnim(animToPlay, true);
	boyfriend.holdTimer = 0;
}