function goodNoteHit(note:Note, field:PlayField) {
    if (note.noteType != "Dodge Note")
		return;

    if(field == game.playerField) {
      var random = FlxG.random.float(-20, 20);
      var random2 = FlxG.random.float(-20, 20);
      modManager.setValue("transform1X", random);
      modManager.setValue("transform2X", random2);
      modManager.setValue("transform1Y", random);
      modManager.setValue("transform2Y", random2);

      game.camHUD.shake(0.005, 0.1);
      
      bfHit(note, field);
    }
}
var dodgeAnimations:Array<String> = ['dodgeLEFT', 'dodgeDOWN', 'dodgeUP', 'dodgeRIGHT'];
function bfHit(note:Note, field:PlayField){
    var animToPlay:String = dodgeAnimations[Std.int(Math.abs(Math.min(dodgeAnimations.length-1, note.noteData)))];
    var boyfriend = game.boyfriend;
    boyfriend.playAnim(animToPlay, true);
	boyfriend.holdTimer = 0;
}