function generateModchart(){
    if (disableModcharts) {
		getInstance().saveScore = false;
		return;
	}

    modManager.queueEase(0, 0 + 4, 'opponentSwap', 0.5, 'expoOut');
    modManager.queueSet(4, "alpha", 1, 1);
    modManager.queueEase(0, 0 + 4, 'bumpyX', 1, 'expoOut');
    modManager.queueEase(0, 0 + 4, 'bumpyXPeriod', 4, 'expoOut');
    modManager.queueEase(0, 0 + 4, 'tipsyX', 0.5, 'expoOut');
    modManager.queueEase(0, 0 + 4, 'tipsy', 0.5, 'expoOut');
    modManager.queueEase(128, 128 + 4, 'bumpyX',0, 'expoOut');
    modManager.queueEase(128, 128 + 4, 'bumpyXPeriod', 0, 'expoOut');
    modManager.queueEase(128, 128 + 4, 'tipsyX', 0, 'expoOut');
    modManager.queueEase(128, 128 + 4, 'tipsy', 0, 'expoOut');
    modManager.queueSet(128, 'beat', 1);

    var tinyscreams = [
        140,
        156,
        172,
        204,
        220,
        236,
        //
        780,
        796,
        812,
    ];

    var tinyScreamVal = ClientPrefs.downScroll ? -50 : 50;
    var tinyScreamVal2 = ClientPrefs.downScroll ? 50 : -50;

    var vals = 1;
    for (i in 0...tinyscreams.length){
        vals = vals * -1;
        var step = tinyscreams[i];
        modManager.queueSet(step, 'centerrotateZ', 30 * vals);
        modManager.queueEase(step, step + 2, 'centerrotateZ', 0, 'expoOut');

        modManager.queueSet(step + 2, 'transform0Y-a', tinyScreamVal * vals);
        modManager.queueSet(step + 2, 'transform1Y-a', tinyScreamVal2 * vals);
        modManager.queueSet(step + 2, 'transform2Y-a', tinyScreamVal * vals);
        modManager.queueSet(step + 2, 'transform3Y-a', tinyScreamVal2 * vals);

        for(e in 0...4)
            modManager.queueEase(step + 2,step + 4, 'transform' + e +'Y-a', 0);
    }

    modManager.queueEase(183, 185, 'centerrotateZ', 40, 'expoIn');
    modManager.queueEase(185, 187, 'centerrotateZ', 0, 'expoOut');
    modManager.queueEase(187, 189, 'centerrotateZ', -40, 'expoIn');
    modManager.queueEase(189, 191, 'centerrotateZ', 0, 'expoOut');

    modManager.queueSet(192, 'blink', 1);
    modManager.queueSet(240, 'blink', 0);

    var threeMovesVal = ClientPrefs.downScroll ? -200 : 200;
    var threeMovesOGVal = ClientPrefs.downScroll ? 200 : -200;

    var scrollVal = 1;
    modManager.queueEase(258,260, 'transform0Y-a', threeMovesVal, 'expoOut');
    modManager.queueEase(261,263, 'transform0Y-a', threeMovesVal, 'expoOut');
    modManager.queueSet(265, 'transform0Y-a', 0);
    modManager.queueEase(264,266, 'reverse0', scrollVal, 'expoOut');
    modManager.queueEase(264,266, 'reverse1', scrollVal, 'expoOut');
    modManager.queueEase(267,269, 'reverse3', scrollVal, 'expoOut');
    modManager.queueEase(270,272, 'reverse2', scrollVal, 'expoOut');

    modManager.queueEase(274,276, 'transform3Y-a', threeMovesOGVal , 'expoOut');
    modManager.queueSet(278, 'transform3Y-a', 0);
    modManager.queueEase(277,279, 'reverse3', 0, 'expoOut');
    modManager.queueEase(280,282, 'reverse2', 0, 'expoOut');
    modManager.queueEase(283,285, 'reverse1', 0, 'expoOut');
    modManager.queueEase(286,288, 'reverse0', 0, 'expoOut');

    modManager.queueEase(290,292, 'transform3Y-a', threeMovesVal , 'expoOut');
    modManager.queueSet(294, 'transform3Y-a', 0);
    modManager.queueEase(293,295, 'reverse3', scrollVal, 'expoOut');
    modManager.queueEase(296,298, 'reverse0', scrollVal, 'expoOut');
    modManager.queueEase(299,301, 'reverse2', scrollVal, 'expoOut');
    modManager.queueEase(302,304, 'reverse1', scrollVal, 'expoOut');

    modManager.queueEase(306,308, 'transform3Y-a', threeMovesOGVal , 'expoOut');
    modManager.queueSet(310, 'transform3Y-a', 0);
    modManager.queueEase(309,311, 'reverse3', 0, 'expoOut');
    modManager.queueEase(312,314, 'reverse1', 0, 'expoOut');
    modManager.queueEase(315,317, 'reverse2', 0, 'expoOut');
    modManager.queueEase(318,320, 'reverse0', 0, 'expoOut');

    modManager.queueEase(322,324, 'transform3Y-a', threeMovesVal, 'expoOut');
    modManager.queueEase(325,327, 'transform3Y-a', threeMovesVal, 'expoOut');
    modManager.queueSet(329, 'transform3Y-a', 0);
    modManager.queueEase(328,330, 'reverse3', scrollVal, 'expoOut');
    modManager.queueEase(328,330, 'reverse2', scrollVal, 'expoOut');
    modManager.queueEase(331,333, 'reverse0', scrollVal, 'expoOut');
    modManager.queueEase(334,335, 'reverse1', scrollVal, 'expoOut');

    modManager.queueEase(338,340, 'transform0Y-a', threeMovesOGVal , 'expoOut');
    modManager.queueSet(342, 'transform0Y-a', 0);
    modManager.queueEase(340,343, 'reverse0', 0, 'expoOut');
    modManager.queueEase(344,346, 'reverse1', 0, 'expoOut');
    modManager.queueEase(347,349, 'reverse2', 0, 'expoOut');
    modManager.queueEase(350,352, 'reverse3', 0, 'expoOut');

    modManager.queueEase(354,356, 'transform0Y-a', threeMovesVal, 'expoOut');
    modManager.queueEase(357,359, 'transform0Y-a', threeMovesVal, 'expoOut');
    modManager.queueSet(361, 'transform0Y-a', 0);
    modManager.queueEase(360,362, 'reverse0', scrollVal, 'expoOut');
    modManager.queueEase(360,362, 'reverse3', scrollVal, 'expoOut');
    modManager.queueEase(363,365, 'reverse2', scrollVal, 'expoOut');
    modManager.queueEase(366,368, 'reverse1', scrollVal, 'expoOut');

    modManager.queueEase(370,372, 'transform3Y-a', threeMovesOGVal , 'expoOut');
    modManager.queueSet(374, 'transform3Y-a', 0);
    modManager.queueEase(373,375, 'reverse3', 0, 'expoOut');
    modManager.queueEase(376,378, 'reverse1', 0, 'expoOut');
    modManager.queueEase(379,381, 'reverse2', 0, 'expoOut');
    modManager.queueEase(382,384, 'reverse0', 0, 'expoOut');

    var big = [
        416,
        419,
        424,
        427,
        432,
        435,
        //
        480,
        483,
        488,
        491,
        496,
        499,
        //
        964,
        972,
        996
    ];

    var m = 1;
    for (i in 0...big.length){
        m = m * -1;
        var step = big[i];
        modManager.queueSet(step, 'transformX', 100 * m);
        modManager.queueSetP(step, 'tipsy', 100 * m);
        modManager.queueSetP(step, 'drunk', 145 * m);
                        
        modManager.queueEaseP(step, step + 10, 'tipsy', 0, 'cubeOut');
        modManager.queueEaseP(step, step + 10, 'drunk', 0, 'elasticOut');
        modManager.queueEase(step, step + 10, 'transformX', 0, 'cubeOut');
    }

    modManager.queueSet(415, 'beat', 0);
    modManager.queueSet(479, 'beat', 0);
    modManager.queueSet(448, 'beat', 1);

    modManager.queueFunc(512, 767, function(event, cDS:Float){
        var pos = (cDS - 512) / 2;

        for(pn in 1...3){
            for(col in 0...4){
                var cPos = col * -112;
                if (pn == 2) cPos = cPos - 620;
                var c = (pn - 1) * 4 + col;
                var mn = pn == 2?0:1;
                var cSpacing = 112;

                var newPos = (((col * cSpacing + (pn - 1) * 640 + pos * cSpacing) % (1280))) - 176;
                modManager.setValue("transform" + col + "X", cPos + newPos, mn);
            }
        }
    });

	for(i in 0...4)
        modManager.queueSet(767, "transform" + i + "X", 0);

    modManager.queueSet(768, 'opponentSwap', 0.5);
    modManager.queueEase(512,516, 'opponentSwap', 0, 'expoOut');
    modManager.queueEase(512,516, "alpha", 0, 'expoOut', 1);
    modManager.queueEase(512,516, "stealth", 0.5, 'expoOut', 1);

    modManager.queueSet(768, 'beat', 1);
    modManager.queueSet(768, "alpha", 1, 1);
    modManager.queueSet(768, "stealth", 0, 1);

    modManager.queueEase(824, 826, 'centerrotateZ', 40, 'expoIn');
    modManager.queueEase(826, 828, 'centerrotateZ', 0, 'expoOut');
    modManager.queueEase(828, 830, 'centerrotateZ', -40, 'expoIn');
    modManager.queueEase(830, 832, 'centerrotateZ', 0, 'expoOut');

    modManager.queueSet(832, 'blink', 1);
    modManager.queueSet(880, 'blink', 0);

    modManager.queueEase(944, 946, 'receptorScroll', 1, 'expoOut');
    modManager.queueEase(959, 961, 'receptorScroll', 0, 'expoOut');

    modManager.queueEase(1008, 1008 + 2, 'receptorScroll', 1, 'expoOut');
    modManager.queueEase(1024, 1024 + 2, 'receptorScroll', 0, 'expoOut');

    modManager.queueEase(1280, 1280 + 2, 'receptorScroll', 1, 'expoOut');
}

var frag:String = "
void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    float aspect_ratio = iResolution.y/iResolution.x;
	vec2 uv = fragCoord.xy / iResolution.x;
    uv -= vec2(0.5, 0.5 * aspect_ratio);
    float rot = radians(-30. -iTime); // radians(45.0*sin(iTime));
    mat2 rotation_matrix = mat2(cos(rot), -sin(rot), sin(rot), cos(rot));
   	uv = rotation_matrix * uv;
    vec2 scaled_uv = 20.0 * uv; 
    vec2 tile = fract(scaled_uv);
    float tile_dist = min(min(tile.x, 1.0-tile.x), min(tile.y, 1.0-tile.y));
    float square_dist = length(floor(scaled_uv));
    
    float edge = sin(iTime-square_dist*20.);
    edge = mod(edge * edge, edge / edge);

    float value = mix(tile_dist, 1.0-tile_dist, step(1.0, edge));
    edge = pow(abs(1.0-edge), 2.2) * 0.5;
    
    value = smoothstep( edge-0.05, edge, 0.95*value);
    
    
    value += square_dist*.1;
    value *= 0.8 - 0.2;
    fragColor = vec4(pow(value, 2.), pow(value, 1.5), pow(value, 1.2), 1.);
}
";

var shadedSprite:FlxSprite;
var runTimeShaders:FlxShaderToyRuntimeShader;

var prox0:ProxyField;
var prox1:ProxyField;
var prox2:ProxyField;
function onCreatePost() {
	shadedSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xff000000);
	shadedSprite.screenCenter();
    shadedSprite.cameras = [game.camStageUnderlay];
    game.add(shadedSprite);

    newRuntimeShaderToy(shadedSprite,frag,shadedSprite.width, shadedSprite.height);

    for (field in game.playfields) {
        prox0 = new ProxyField(field.noteField);
        prox0.cameras = [game.camHUD];
        prox0.x += 500;
        //game.add(prox0);

        prox1 = new ProxyField(field.noteField);
        prox1.cameras = [game.camHUD];
        prox1.x += 500 + 500;
        prox1.alpha = 0;
        //game.add(prox1);

        prox2 = new ProxyField(field.noteField);
        prox2.cameras = [game.camHUD];
        prox2.x -= 500;
        //game.add(prox2);
    }

}

function onUpdate(elapsed)
{
    shaderToyUpdate(elapsed, FlxG.mouse);
}