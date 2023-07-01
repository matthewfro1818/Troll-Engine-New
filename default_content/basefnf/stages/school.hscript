var daPixelZoom:Float = 6;
var bgGirls:FlxSprite;
function onLoad(stage, foreground)
{
    var add = function(o){
		return stage.add(o);
	}

    var bgSky:BGSprite = new BGSprite('weeb/weebSky', 0, 0, 0.1, 0.1);
	add(bgSky);
	bgSky.antialiasing = false;

	var repositionShit = -200;

    var bgSchool:BGSprite = new BGSprite('weeb/weebSchool', repositionShit, 0, 0.6, 0.90);
	add(bgSchool);
	bgSchool.antialiasing = false;

	var bgStreet:BGSprite = new BGSprite('weeb/weebStreet', repositionShit, 0, 0.95, 0.95);
	add(bgStreet);
	bgStreet.antialiasing = false;

	var widShit = Std.int(bgSky.width * daPixelZoom);
	if(!ClientPrefs.lowQuality) {
		var fgTrees:BGSprite = new BGSprite('weeb/weebTreesBack', repositionShit + 170, 130, 0.9, 0.9);
		fgTrees.setGraphicSize(Std.int(widShit * 0.8));
		fgTrees.updateHitbox();
		add(fgTrees);
		fgTrees.antialiasing = false;
	}

	var bgTrees:FlxSprite = new FlxSprite(repositionShit - 380, -800);
	bgTrees.frames = Paths.getPackerAtlas('weeb/weebTrees');
	bgTrees.animation.add('treeLoop', [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18], 12);
	bgTrees.animation.play('treeLoop');
	bgTrees.scrollFactor.set(0.85, 0.85);
	add(bgTrees);
	bgTrees.antialiasing = false;

	if(!ClientPrefs.lowQuality) {
		var treeLeaves:BGSprite = new BGSprite('weeb/petals', repositionShit, -40, 0.85, 0.85, ['PETALS ALL'], true);
		treeLeaves.setGraphicSize(widShit);
		treeLeaves.updateHitbox();
		add(treeLeaves);
		treeLeaves.antialiasing = false;
	}

	bgSky.setGraphicSize(widShit);
	bgSchool.setGraphicSize(widShit);
	bgStreet.setGraphicSize(widShit);
	bgTrees.setGraphicSize(Std.int(widShit * 1.4));

	bgSky.updateHitbox();
	bgSchool.updateHitbox();
	bgStreet.updateHitbox();
	bgTrees.updateHitbox();

    if(!ClientPrefs.lowQuality)
    {
        // BG fangirls dissuaded
        bgGirls = new FlxSprite(-100, 190);
        bgGirls.scrollFactor.set(0.9, 0.9);
		bgGirls.frames = Paths.getSparrowAtlas('weeb/bgFreaks');
		bgGirls.antialiasing = false;
		swapDanceType();

		bgGirls.setGraphicSize(Std.int(bgGirls.width * daPixelZoom));
		bgGirls.updateHitbox();
		bgGirls.animation.play('danceLeft');
        add(bgGirls);
    }
}

function onBeatHit(){
    if(bgGirls != null){ dance(); }
}

var danceDir:Bool = false;
var isPissed:Bool = true;

function swapDanceType()
{
	isPissed = !isPissed;
	if(!isPissed) { //Gets unpissed
		bgGirls.animation.addByIndices('danceLeft', 'BG girls group', CoolUtil.numberArray(14), "", 24, false);
		bgGirls.animation.addByIndices('danceRight', 'BG girls group', CoolUtil.numberArray(30, 15), "", 24, false);
	} else { //Pisses
		bgGirls.animation.addByIndices('danceLeft', 'BG fangirls dissuaded', CoolUtil.numberArray(14), "", 24, false);
		bgGirls.animation.addByIndices('danceRight', 'BG fangirls dissuaded', CoolUtil.numberArray(30, 15), "", 24, false);
	}
	dance();
}

function dance()
{
	danceDir = !danceDir;
	if (danceDir)
		bgGirls.animation.play('danceRight', true);
	else
		bgGirls.animation.play('danceLeft', true);
}

function onEvent(eventName, value1, value2)
{
    switch (eventName)
    {
        case "BG Freaks Expression":
			if(bgGirls != null) {swapDanceType();}
    }
}