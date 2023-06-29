var daPixelZoom:Float = 6;
var bgGhouls:BGSprite;

function onLoad(stage, foreground)
{
    var add = function(o){
		return stage.add(o);
	}

    var posX = 400;
	var posY = 200;

	var bg:BGSprite;
	if(!ClientPrefs.lowQuality)
		bg = new BGSprite('weeb/animatedEvilSchool', posX, posY, 0.8, 0.9, ['background 2'], true);
	else
		bg = new BGSprite('weeb/animatedEvilSchool_low', posX, posY, 0.8, 0.9);

	bg.scale.set(daPixelZoom, daPixelZoom);
	bg.antialiasing = false;
	add(bg);

    if(!ClientPrefs.lowQuality)
    {
        bgGhouls = new BGSprite('weeb/bgGhouls', -100, 190, 0.9, 0.9, ['BG freaks glitch instance'], false);
        bgGhouls.setGraphicSize(Std.int(bgGhouls.width * daPixelZoom));
        bgGhouls.updateHitbox();
        bgGhouls.alpha = 0.0001;
        bgGhouls.antialiasing = false;
        bgGhouls.animation.finishCallback = function(name:String)
        {
           if(name == 'BG freaks glitch instance')
                bgGhouls.alpha = 0.0001;
        }
        add(bgGhouls);
    }
}
function onEvent(eventName, value1, value2)
{
    switch (eventName)
    {
		case "Trigger BG Ghouls":
			if(!ClientPrefs.lowQuality)
			{
				bgGhouls.dance(true);
				bgGhouls.alpha = 1;
			}
    }
}

function onPush(event)
{
    switch(event.event)
    {
    }
}