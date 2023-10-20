package hud;

import PlayState.FNFHealthBar;
import flixel.ui.FlxBar;
import flixel.tweens.FlxEase;
import flixel.util.FlxStringUtil;
import JudgmentManager.JudgmentData;
import flixel.util.FlxColor;
import playfields.*;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;


// includes basic HUD stuff

class CommonHUD extends BaseHUD
{
	public var botplayTxt:FlxText;
	public var botplaySine:Float = 0;

    // just some extra variables lol
	public var healthBar:FNFHealthBar;
	@:isVar
	public var healthBarBG(get, null):FlxSprite;
	function get_healthBarBG()return healthBar.healthBarBG;

	override function set_displayedHealth(value:Float){
		healthBar.value = value;
		displayedHealth = value;
		return value;
	}

	public var bar:FlxSprite;
	public var songPosBar:FlxBar = null;
	public var songNameTxt:FlxText;
	public function new(iP1:String, iP2:String, songName:String, stats:Stats)
	{
		super(iP1, iP2, songName, stats);
		
		healthBar = new FNFHealthBar(iP1, iP2);
		iconP1 = healthBar.iconP1;
		iconP2 = healthBar.iconP2;

		loadSongPos();

		botplayTxt = new FlxText(0, (ClientPrefs.downScroll ? FlxG.height - 44 : 19) + 15 + (ClientPrefs.downScroll ? -78 : 55), FlxG.width,"[BOTPLAY]", 32);
		botplayTxt.setFormat(Paths.font(gameFont), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.exists = false;
		add(botplayTxt);

		#if (PE_MOD_COMPATIBILITY && false)
        if(FlxG.state == PlayState.instance){
            PlayState.instance.healthBar = healthBar;
			PlayState.instance.iconP1 = iconP1;
			PlayState.instance.iconP2 = iconP2;
        }
		#end
	}

	function loadSongPos()
	{
		var songPosY = FlxG.height - 706;
		if (ClientPrefs.downScroll)
			songPosY = FlxG.height - 33;
	
		var bfColor = FlxColor.fromRGB(PlayState.instance.boyfriend.healthColorArray[0], PlayState.instance.boyfriend.healthColorArray[1], PlayState.instance.boyfriend.healthColorArray[2]);
		var dadColor = FlxColor.fromRGB(PlayState.instance.dad.healthColorArray[0], PlayState.instance.dad.healthColorArray[1], PlayState.instance.dad.healthColorArray[2]);
		songPosBar = new FlxBar(390, songPosY, LEFT_TO_RIGHT, 500, 25, this, 'songPercent', 0, 1);
		songPosBar.alpha = 0;
		songPosBar.scrollFactor.set();
		songPosBar.createGradientBar([FlxColor.BLACK], [bfColor, dadColor]);
		songPosBar.numDivisions = 800;
		add(songPosBar);
	
		bar = new FlxSprite(songPosBar.x, songPosBar.y).makeGraphic(Math.floor(songPosBar.width), Math.floor(songPosBar.height), FlxColor.TRANSPARENT);
		bar.alpha = 0;
		add(bar);
	
		flixel.util.FlxSpriteUtil.drawRect(bar, 0, 0, songPosBar.width, songPosBar.height, FlxColor.TRANSPARENT, {thickness: 4, color: (FlxColor.BLACK)});
	
		songNameTxt = new FlxText(0, bar.y + ((songPosBar.height - 15) / 2) - 5, 0, '', 16);
		songNameTxt.setFormat(Paths.font(gameFont), 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songNameTxt.autoSize = true;
		songNameTxt.borderStyle = FlxTextBorderStyle.OUTLINE_FAST;
		songNameTxt.borderSize = 2;
		songNameTxt.scrollFactor.set();
		songNameTxt.text = songName +
			' (${FlxStringUtil.formatTime(songLength, false)} - ${FlxStringUtil.formatTime(Math.floor(songLength / 1000), false)})';
		songNameTxt.alpha = 0;
		add(songNameTxt);

		updateTimeBarType();
	}

	function updateTimeBarType(){	
		updateTime = (ClientPrefs.timeBarType != 'Disabled' && ClientPrefs.timeOpacity > 0);

		if (songNameTxt != null || songPosBar != null || bar != null) {
			songNameTxt.exists = updateTime;
			songPosBar.exists = updateTime;
			bar.exists = updateTime;
		}

		updateTimeBarAlpha();
	}

	function updateTimeBarAlpha(){
		var songPosY = FlxG.height - 706;
		if (ClientPrefs.downScroll)
			songPosY = FlxG.height - 33;

		if (songPosBar != null || bar != null || songNameTxt != null) {
			songPosBar.y = songPosY;
			bar.y = songPosBar.y;
			songNameTxt.y = bar.y;

			songPosBar.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
			bar.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
			songNameTxt.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
		}
	}

    override function changedCharacter(id:Int, char:Character){

        switch(id){
            case 1:
				iconP1.changeIcon(char.healthIcon);
            case 2:
				iconP2.changeIcon(char.healthIcon);
            case 3:
                // gf icon
            default:
                // idk
        }

		super.changedCharacter(id, char);
    }

	override public function update(elapsed:Float)
	{
		if (botplayTxt.exists = PlayState.instance.cpuControlled){
			botplaySine += 180 * elapsed;
			botplayTxt.alpha = 1 - flixel.math.FlxMath.fastSin((Math.PI * botplaySine) / 180);
		}else{
			botplaySine = 0;
		}

		if (updateTime)
		{
			var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
			if (curTime < 0)
				curTime = 0;
			songPercent = (curTime / songLength);
	
			var songCalc:Float = (songLength - curTime);
			songCalc = curTime;
	
			var secondsTotal:Int = Math.floor(songCalc / 1000);
			if (secondsTotal < 0)
				secondsTotal = 0;
			else if (secondsTotal >= Math.floor(songLength / 1000))
				secondsTotal = Math.floor(songLength / 1000);
	
			if (songNameTxt != null) {
				songNameTxt.text = songName
				+ ' (${FlxStringUtil.formatTime(secondsTotal, false)} - ${FlxStringUtil.formatTime(Math.floor(songLength / 1000), false)})';
				songNameTxt.updateHitbox();
				songNameTxt.screenCenter(X);
			}
		}

		super.update(elapsed);
	}

	override function beatHit(beat:Int)
	{
		healthBar.iconScale = 1.2;
	}

	override function changedOptions(changed:Array<String>)
	{
        healthBar.healthBarBG.y = FlxG.height * (ClientPrefs.downScroll ? 0.11 : 0.89);
        healthBar.y = healthBarBG.y + 5;
        healthBar.iconP1.y = healthBar.y - 75;
        healthBar.iconP2.y = healthBar.y - 75;

		botplayTxt.y = (ClientPrefs.downScroll ? (FlxG.height-107) : 89);

		updateTimeBarType();
	}

	var tweenProg:Float = 0;

	override function songStarted()
	{
		FlxTween.num(0, 1, 0.5, 
			{
				ease: FlxEase.circOut,
				onComplete: function(tw:FlxTween){
					tweenProg = 1;
					updateTimeBarAlpha();
				}
			}, 
			function(prog:Float){
				tweenProg = prog;
				updateTimeBarAlpha();
			}
		);
	}

	override function songEnding()
	{
		if (songPosBar != null || bar != null || songNameTxt != null) {
			songPosBar.exists = false;
			bar.exists = false;
			songNameTxt.exists = false;
		}
	}

    override function reloadHealthBarColors(dadColor:FlxColor, bfColor:FlxColor)
	{
		if (healthBar != null){
			healthBar.createFilledBar(dadColor, bfColor);
			healthBar.updateBar();
		}	
    }

}