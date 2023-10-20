function playNoteAnim(anim:String, note:Note) {
    var delay:Int = 0;

    if (note.isSustainNote)
    {
        delay = 4;
    }
    this.playAnim(anim, true, false, delay);
}