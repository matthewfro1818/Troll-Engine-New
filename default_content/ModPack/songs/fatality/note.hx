function onCreatePost() {
    game.gf.visible = false;
    game.dad.scrollFactor.set(0.6, 0.6);
}

function preModifierRegister(){
	game.dadField.cameras = [game.camGame];
}

function generateModchart() {
    modManager.setValue("opponentSwap", 0.5);
    modManager.setValue("alpha", 0.4, 1);
    modManager.setValue("bumpy", -20, 1);
    modManager.setValue("bumpyPeriod", 30, 1);
    modManager.setValue("fieldRoll", ClientPrefs.downScroll ? -90 : 90, 1);
    modManager.setValue("transformY", ClientPrefs.downScroll ? 750 : -750, 1);
    modManager.setValue("transformX",ClientPrefs.downScroll ? 460 : -460, 1);
    modManager.setValue("drawDistance", FlxG.width * 50, 1);
    //1984
    modManager.queueSet(1984,"transformX", ClientPrefs.downScroll ? 1360 : -1360, 1);
    
}