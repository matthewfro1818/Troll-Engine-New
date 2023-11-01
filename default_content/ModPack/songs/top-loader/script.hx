importClass("openfl.filters.ShaderFilter");

var singAnims = ["singLEFT", "singDOWN", "singUP", "singRIGHT"];

var indiGlitchShaders;
var glitchGraphic;
function onCreatePost() {
    if (ClientPrefs.shaders == 'All') {
		indiGlitchShaders = game.createRuntimeShader('glitch');
        indiGlitchShaders.data.time.value = [0.0];
        indiGlitchShaders.data.prob.value = [0.0];
		game.camGame.setFilters([new ShaderFilter(indiGlitchShaders)]);
    }
}

function removeGlitchShader()
{
    if (ClientPrefs.shaders == 'All') {
        if (indiGlitchShaders != null){
            if (script.get("game") == null){
                getInstance().camGame.setFilters([]);
                return;
            }
            game.camHUD.setFilters([]);
            game.camGame.setFilters([]);
        }
    }
}

onDestroy = removeGlitchShader;
onGameOver = removeGlitchShader;

function preOpponentNoteHit(note:Note, field:PlayField) {
    var chars:Array<Character> = note.characters;
    if (note.noteType == "White and Black duet") {
        chars.push(game.gf);
        chars.push(game.dad);
    }else if (chars.length == 0)
        chars = field.characters; 
}

function opponentNoteHit(note:Note, field:PlayField) {
    if (note.noteType == "Alt Animation" && ClientPrefs.shaders == 'All') {
        indiGlitchShaders.data.time.value = [Conductor.songPosition / 1000];
        indiGlitchShaders.data.prob.value = [0.25];
    }
    if (note.noteType != "White and Black duet")
		return;
}