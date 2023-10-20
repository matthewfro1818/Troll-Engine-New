importClass("openfl.filters.ShaderFilter");

var jake = new Character(0, 0, 'jake');
jake.x += jake.positionArray[0] - 800;
jake.y += jake.positionArray[1] + 60;

var whiteBG:FlxSprite;
var chromVal:Float = 0;

var chromShaders;
var chromFilter;

function onCreatePost() {
    game.gfGroup.add(jake);

    whiteBG = new FlxSprite(-640, -640).makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.WHITE);
    whiteBG.scrollFactor.set(0, 0);
    whiteBG.alpha = 0.00001;
    game.addBehindGF(whiteBG);

    chromVal = 0.003;

    if (ClientPrefs.shaders != 'None') {
        chromShaders = newShader("chrom");
        addChromValue(chromVal);

        chromFilter = new ShaderFilter(chromShaders);
        game.camHUD.setFilters([chromFilter]);
        game.camGame.setFilters([chromFilter]);
    }
}

function onUpdate(elapsed)
    addChromValue(chromVal);

function onBeatHit() {
    if (curBeat % 4 == 0) {
        chromVal = 0.01;
        FlxTween.num(0.01, 0.003, 0.5, {ease: FlxEase.quadInOut}, updateValue);
    } 
}

function updateValue(value:Float):Void
	chromVal = value;

function removeChromShader()
{
    if (ClientPrefs.shaders != 'None') {
        if (chromShaders != null){
            if (script.get("game") == null){
                getInstance().camGame.setFilters([]);
                return;
            }
            game.camHUD.setFilters([]);
            game.camGame.setFilters([]);
        }
    }
}

onDestroy = removeChromShader;
onGameOver = removeChromShader;

function addChromValue(val:Float) {
    if (chromShaders != null) {
        chromShaders.data.rOffset.value = [val];
        chromShaders.data.gOffset.value = [0.0];
        chromShaders.data.bOffset.value = [val * -1];
    }
}

var singAnims = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];
function preOpponentNoteHit(note:Note, field:PlayField) {
    var chars:Array<Character> = note.characters;
    if (note.noteType == "Second Char Sing")
        chars.push(jake);
    else if (chars.length == 0)
        chars = field.characters; 
}

function opponentNoteHit(note:Note, field:PlayField) {
    var random = FlxG.random.float(-20, 20);
    var random2 = FlxG.random.float(-20, 20);

    if (game.health > 0.3 && !note.isSustainNote && !game.disableMechanics) {
        game.health -= 0.03;
    }
    if (note.noteType == "Glitch Note") {
        if(field == game.dadField) {
            game.camHUD.shake(0.01, 0.1);

            chromVal = 0.01;
            FlxTween.num(0.01, 0.003, 0.5, {ease: FlxEase.quadInOut}, updateValue);
            modManager.setValue("transform1X", random);
            modManager.setValue("transform2X", random2);
            modManager.setValue("transform1Y", random);
            modManager.setValue("transform2Y", random2);
        }
    }
    if (note.noteType != "Both Char Sing")
		return;

    if(field == game.dadField) {
        var animToPlay:String = singAnims[Std.int(Math.abs(Math.min(singAnims.length-1, note.noteData)))];
        jake.playAnim(animToPlay, true);
        jake.holdTimer = 0;
    } 
}

function generateModchart() {
    if (game.playOpponent) {
        modManager.queueEase(2071, 2071 + 4, 'alpha', 1, 'expoOut', 0);
        modManager.queueEase(2336, 2336 + 4, 'alpha', 0, 'expoOut', 0);
    
        modManager.queueSet(3360, 'alpha', 1, 0);
    } else {
        modManager.queueEase(2071, 2071 + 4, 'alpha', 1, 'expoOut', 1);
        modManager.queueEase(2336, 2336 + 4, 'alpha', 0, 'expoOut', 1);
    
        modManager.queueSet(3360, 'alpha', 1, 1);
    }
}

function onStepHit() {
    switch (curStep) {
        case 2080:
            game.gf.visible = false;
            jake.visible = false;
            whiteBG.alpha = 1;

            game.boyfriend.color = FlxColor.BLACK;
            game.dad.color = FlxColor.BLACK;
        case 2336:
            game.gf.visible = true;
            jake.visible = true;
            whiteBG.alpha = 0;

            game.boyfriend.color = FlxColor.WHITE;
            game.dad.color = FlxColor.WHITE;
        case 3360,3776:
            game.camGame.alpha = 0;
        case 3392:
            game.camGame.alpha = 1;
        case 3389:
            game.dad.visible = false;
            jake.visible = false;
            whiteBG.alpha = 1;

            game.boyfriend.color = FlxColor.BLACK;
            game.gf.color = FlxColor.BLACK;
    }
}