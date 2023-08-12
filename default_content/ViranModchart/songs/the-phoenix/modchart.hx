importClass("openfl.filters.ShaderFilter");

function generateModchart(){
    modManager.setValue("alpha", 1, 1);
    modManager.setPercent("opponentSwap", 50);

    if (disableModcharts) {
		getInstance().saveScore = false;
		return;
	}

    var drums = [];
    var drums2 = [];

    numericForInterval(160, 272, 4, function(i){
        drums.push(i);
    });

    numericForInterval(160 + 4, 272 + 4, 8, function(i){
        drums2.push(i);
    });

    for (i in 0...drums.length){
        var step = drums[i];
        modManager.queueSet(step, 'fieldYaw', 65);
        modManager.queueEase(step, step + 6, 'fieldYaw', 0, 'cubeOut');

        modManager.queueSet(step, 'fieldPitch', 65);
        modManager.queueEase(step, step + 6, 'fieldPitch', 0, 'cubeOut');
    }

    for (i in 0...drums2.length){
        var step = drums2[i];
        modManager.queueSet(step, 'fieldYaw', -65);
        modManager.queueEase(step, step + 6, 'fieldYaw', 0, 'cubeOut');

        modManager.queueSet(step, 'fieldPitch', -65);
        modManager.queueEase(step, step + 6, 'fieldPitch', 0, 'cubeOut');
    }

    modManager.queueEase(288, 288 + 4, 'invert', 1, 'cubeOut');

    var invertBeats = [];
    var invertBeats2 = [];

    numericForInterval(296, 380, 4, function(i){
        invertBeats.push(i);
    });

    numericForInterval(296 + 4, 380 + 4, 8, function(i){
        invertBeats2.push(i);
    });

    for (i in 0...invertBeats.length){
        var step = invertBeats[i];
        modManager.queueEase(step, step + 4, 'invert', 0, 'expoOut');
    }

    for (i in 0...invertBeats2.length){
        var step = invertBeats2[i];
        modManager.queueEase(step, step + 4, 'invert', 1, 'expoOut');
    }

    modManager.queueEase(396, 396 + 4, 'invert', 0, 'cubeOut');

    modManager.queueSet(155,"alpha", 0, 0);
    modManager.queueSet(160,"reverse0", 1, 0);
    modManager.queueSet(160,"reverse1", 1, 0);

    modManager.queueEase(268,272,"reverse0", 0,'quadOut', 0);
    modManager.queueEase(268,272,"reverse1", 0,'quadOut', 0);
    modManager.queueEase(268,272,"reverse", 0,'quadOut', 0);

    modManager.queueSet(274,"rotateX", -10, 0);
    modManager.queueSet(275,"rotateX", -20, 0);
    modManager.queueSet(276,"rotateX", -30, 0);
    modManager.queueSet(277,"rotateX", -40, 0);
    modManager.queueSet(278,"rotateX", -50, 0);
    modManager.queueSet(279,"rotateX", -60, 0);
    modManager.queueSet(280,"rotateX", -70, 0);

    //modManager.queueSet(288,"rotateX", -70, 0);
    modManager.queueSet(288,"dark", 1, 0);
    modManager.queueSet(288,"transformZ-a", 100, 0);
    modManager.queueSet(288,"transformY-a", 300, 0);
    modManager.queueEase(396,402,"transformZ", -100,'quadIn', 0);
    modManager.queueEase(396,402,"transformY-a", 0,'quadIn', 0);
    modManager.queueEase(396,402,"dark", 0,'quadIn', 0);
    modManager.queueEase(403,416,"centerrotateZ", 360 * 2,'circIn', 0);

    modManager.queueEase(416,419,"transformY-a", 0,'quadOut', 0);
    modManager.queueEase(416,419,"transformZ-a", 0,'quadOut', 0);
    modManager.queueEase(416,419,"transformZ", 0,'quadOut', 0);
    modManager.queueEase(416,419,"rotateX", 0,'quadOut', 0);
    modManager.queueEase(416,419,"receptorScroll", 1,'quadOut', 0);

    modManager.queueEase(672,675,"receptorScroll", 0,'quadOut', 0);

    modManager.queueEase(720 - 5,720,"invert", 1,'quadIn', 0);
    modManager.queueEase(752 - 5,752,"invert", 0,'quadIn', 0);
    modManager.queueEase(784 - 5,784,"invert", 1,'quadIn', 0);
    modManager.queueEase(816,818,"invert", 0,'quadIn', 0);
    modManager.queueEase(820,821,"invert", 1,'quadIn', 0);
    modManager.queueEase(822,826,"invert", 0,'quadIn', 0);
    modManager.queueEase(846 - 5,846,"invert", 1,'quadIn', 0);
    modManager.queueEase(880 - 5,880,"invert", 0,'quadIn', 0);
    modManager.queueEase(912 - 5,912,"invert", 1,'quadIn', 0);
    modManager.queueEase(952,953,"invert", 0,'quadIn', 0);
    modManager.queueEase(954,955,"invert", 1,'quadIn', 0);
    modManager.queueEase(956,957,"invert", 0,'quadIn', 0);

    modManager.queueEase(960,960 + 2,"drunk", 1,'quadIn', 0);
    modManager.queueEase(960,960 + 2,"drunkSpeed", 0.5,'quadIn', 0);

    modManager.queueEase(1184,1184 + 2,"drunk", 0,'quadIn', 0);
    modManager.queueEase(1184,1184 + 2,"drunkSpeed", 0,'quadIn', 0);

    /*modManager.queueSet(1392,"tipsy", 0.5, 0);
    modManager.queueSet(1392,"tipsySpeed", 0.5, 0);

    modManager.queueSet(1408,"tipsy", 0, 0);
    modManager.queueSet(1408,"tipsySpeed", 0, 0);

    modManager.queueSet(1424,"tipsy", 1.5, 0);
    modManager.queueSet(1424,"tipsySpeed", 0.5, 0);

    modManager.queueSet(1440,"tipsy", 0, 0);
    modManager.queueSet(1440,"tipsySpeed", 0, 0);

    modManager.queueSet(1456,"tipsy", 0.5, 0);
    modManager.queueSet(1456,"tipsySpeed", 0.5, 0);

    modManager.queueSet(1472,"tipsy", 0, 0);
    modManager.queueSet(1472,"tipsySpeed", 0, 0);*/

    modManager.queueEase(1248,1261,"receptorScroll", 1,'quadOut', 0);
    modManager.queueEase(1504,1506,"receptorScroll", 0,'quadOut', 0);

    modManager.queueFunc(1504, 1632, function(event, cDS:Float){
        var s = cDS - 928;
        var beat = s / 4;
        modManager.setValue("transformZ-a", -60 * Math.abs(Math.sin(Math.PI * beat)));
        modManager.setValue("transformX-a", 30 * Math.cos(Math.PI * beat));      
    });

    modManager.queueEaseP(1632, 1632 + 4, "transformZ-a", 0, 'quadOut');

    modManager.queueEase(1888,1888 + 4,"fieldRoll", 30,'quadOut', 0);

    modManager.queueEase(1632, 1632 + 4, "transformX-a", 0, 'quadOut');

    modManager.queueSet(1760,"receptorScroll", 1, 0);

    modManager.queueEase(2011,2011 + 4,"fieldRoll", 1,'quadOut', 0);
}

var prox:ProxyField;
var prox2:ProxyField;

function onStepHit()
{
    switch (curStep)
    {
        case 416:
            prox.alpha = 1;
            prox2.alpha = 1;
        case 704:
            prox.alpha = 0;
            prox2.alpha = 0;
            game.camHUD.flash(FlxColor.fromString(0xFFFFFFFF), 0.5, null, true);
        case 1760:
            prox.alpha = 1;
            prox2.alpha = 1;
        case 2016:
            prox.alpha = 0;
            prox2.alpha = 0;
    }
}

if (ClientPrefs.shaders != 'None') {
    var vhsShaders;
    var vhsFilter;
}

function onCreatePost()
{
    game.camZooming = true;

    for (field in game.playfields) {
        prox = new ProxyField(field.noteField);
        prox.cameras = [game.camHUD];
        prox.x += 500;
        prox.alpha = 0;
        game.add(prox);

        prox2 = new ProxyField(field.noteField);
        prox2.cameras = [game.camHUD];
        prox2.x -= 500;
        prox2.alpha = 0;
        game.add(prox2);
    }

    if (ClientPrefs.shaders != 'None') {
        vhsShaders = newShader("vhs");
        vhsShaders.data.iTime.value = [0];

        vhsFilter = new ShaderFilter(vhsShaders);
        FlxG.game.setFilters([vhsFilter]);
    }
}
function removeVHSShader()
{
    if (ClientPrefs.shaders != 'None') {
        if (vhsShaders != null){
            if (script.get("game") == null){
                getInstance().camGame.setFilters([]);
                return;
            }
        
            game.camGame.setFilters([]);
            game.camHUD.setFilters([]);
            FlxG.game.setFilters([]);
        }
    }
}

onDestroy = removeVHSShader;
function update(elapsed)
{
    if (ClientPrefs.shaders != 'None')
        vhsShaders.data.iTime.value = [Conductor.songPosition * 0.001];
}

onGameOver = removeVHSShader;

function numericForInterval(start, end, interval, func){
    var index = start;
    while(index < end){
        func(index);
        index += interval;
    }
}