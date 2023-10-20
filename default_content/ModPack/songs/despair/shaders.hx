importClass("openfl.filters.ShaderFilter");

var chromVal:Float = 0;

var chromShaders;
var chromFilter;

function onCreatePost() {
    chromVal = 0;

    if (ClientPrefs.shaders != 'None') {
        chromShaders = newShader("chrom");
        addChromValue(chromVal);

        chromFilter = new ShaderFilter(chromShaders);
        game.camHUD.setFilters([chromFilter]);
        game.camGame.setFilters([chromFilter]);
    }
}

function onUpdate(elapsed) {
    addChromValue(chromVal);
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

function opponentNoteHit(note:Note, field:PlayField) {
    if(field == game.dadField) {
        if (ClientPrefs.flashing) {
            FlxG.camera.shake(0.015, 0.1);
            game.camHUD.shake(0.005, 0.1);
        }

        chromVal = FlxG.random.float(0.005, 0.01);
        FlxTween.num(chromVal, 0, FlxG.random.float(0.05, 0.12), {ease: FlxEase.linear}, updateValue);
    }
}