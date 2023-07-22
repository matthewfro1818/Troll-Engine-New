package hud;

import flixel.util.FlxSpriteUtil;
import flixel.util.FlxColor;
import haxe.exceptions.NotImplementedException;
import playfields.*;
import PlayState.FNFHealthBar;
import JudgmentManager.JudgmentData;
import flixel.tweens.*;
import flixel.util.FlxStringUtil;
import flixel.ui.FlxBar;
import flixel.text.FlxText;

import flixel.group.FlxSpriteGroup;

// bunch of basic stuff to be extended by other HUDs

class BaseHUD extends FlxSpriteGroup {
	var stats:Stats;
	// just some ref vars
	static var itgDisplays:Map<String, String> = [
		"epic" => "Fantastics",
		"sick" => "Excellents",
		"good" => "Greats",
		"bad" => "Decents",
		"shit" => "Way Off",
		"miss" => "Misses",
		"cb" => "Combo Breaks"
	];

	static var fullDisplays:Map<String, String> = [
		"epic" => "Epics",
		"sick" => "Sicks",
		"good" => "Goods",
		"bad" => "Bads",
		"shit" => "Shits",
		"miss" => "Misses",
		"cb" => "Combo Breaks"
	];

	static var shortenedDisplays:Map<String, String> = [
		"epic" => "EP",
		"sick" => "SK",
		"good" => "GD",
		"bad" => "BD",
		"shit" => "ST",
		"miss" => "MS",
		"cb" => "CB"
	];

	public var displayNames:Map<String, String> = ClientPrefs.judgeCounter == 'Shortened' ? ClientPrefs.etternaHUD == 'ITG' ? itgDisplays : shortenedDisplays : ClientPrefs.etternaHUD == 'ITG' ? itgDisplays : fullDisplays;

	public var itgJudgeColours:Map<String, FlxColor> = [
		"epic" => 0xFF55daf3,
		"sick" => 0xFFedd48a,
		"good" => 0xFF74c857,
		"bad" => 0xFF8b37b7,
		"shit" => 0xFFce7f47,
		"miss" => 0xFF8d1c1c,
		"cb" => 0xFF7F265A
	];

	public var judgeColours:Map<String, FlxColor> = [
		"epic" => 0xFFB611E9,
		"sick" => 0xE70A7AFA,
		"good" => 0xFF4AB91D,
		"bad" => 0xFFC3C3C3,
		"shit" => 0xFF7F7F7F,
		"miss" => 0xFF7F2626,
		"cb" => 0xFF7F265A
	];

	public var displayedJudges:Array<String> = ["epic", "sick", "good", "bad", "shit", "miss"];

	// set by PlayState
	public var time(default, set):Float = 0;
	public var songLength(default, set):Float = 0;
	public var songName(default, set):String = '';
	public var score(get, null):Float = 0;
	function get_score()return stats.score;
	public var comboBreaks(get, null):Float = 0;
	function get_comboBreaks()return stats.comboBreaks;
	public var misses(get, null):Int = 0;
	function get_misses()return stats.misses;
	public var combo(get, null):Int = 0;
	function get_combo()return stats.combo;
	public var grade(get, null):String = '';
	function get_grade()return stats.grade;
	public var ratingFC(get, null):String = 'Clear';
	function get_ratingFC()return stats.clearType;
	public var totalNotesHit(get, null):Float = 0;
	function get_totalNotesHit()return stats.totalNotesHit;
	public var totalPlayed(get, null):Float = 0;
	function get_totalPlayed()return stats.totalPlayed;
	public var ratingPercent(get, null):Float = 0;
	function get_ratingPercent()return stats.ratingPercent;
	public var nps(get, null):Int = 0;
	function get_nps()return stats.nps;
	public var npsPeak(get, null):Int = 0;
	function get_npsPeak()return stats.npsPeak;
	public var songPercent(default, set):Float = 0;
	public var updateTime:Bool = false;
	@:isVar
	public var judgements(get, null):Map<String, Int>;
	function get_judgements()return stats.judgements;

	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var gameFont = PlayState.instance.gameFont;
	public var gameFontBold = PlayState.instance.gameFontBold;

	// just some extra variables lol
	public var healthBar:FNFHealthBar;
	@:isVar
	public var healthBarBG(get, null):FlxSprite;
	function get_healthBarBG()return healthBar.healthBarBG;

	// just some extra variables lol
	public var healthBar2:FNFHealthBar;
	@:isVar
	public var healthBarBG2(get, null):FlxSprite;
	function get_healthBarBG2()return healthBar2.healthBarBG;

	public var bar:FlxSprite;
	public var songPosBar:FlxBar = null;
	public var songNameTxt:FlxText;
	// ITG Bar
	public var timeBar:FlxBar;
	public var timeTxt:FlxText;
	private var timeBarBG:FlxSprite;

	public function new(iP1:String, iP2:String, songName:String, stats:Stats) {
		super();
		this.stats = stats;
		this.songName = songName;

		healthBar = new FNFHealthBar(iP1, iP2);
		if (ClientPrefs.etternaHUD == 'ITG')
			healthBar2 = new FNFHealthBar(iP1, iP2);
		iconP1 = healthBar.iconP1;
		iconP2 = healthBar.iconP2;

		loadSongPos();
	}

	override public function update(elapsed:Float){
		if (FlxG.keys.justPressed.NINE)
			iconP1.swapOldIcon();

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
	
			if (ClientPrefs.etternaHUD != 'ITG')
			{
				songNameTxt.text = songName
				+ ' (${FlxStringUtil.formatTime(secondsTotal, false)} - ${FlxStringUtil.formatTime(Math.floor(songLength / 1000), false)})';
				songNameTxt.updateHitbox();
				songNameTxt.screenCenter(X);
			}
		}
		super.update(elapsed);

	}

	public function beatHit(beat:Int){
		healthBar.iconScale = 1.2;
	}

	public function changedOptions(changed:Array<String>){
		if (ClientPrefs.etternaHUD != 'ITG')
		{
			healthBar.healthBarBG.y = FlxG.height * (ClientPrefs.downScroll ? 0.11 : 0.89);
			healthBar.y = healthBarBG.y + 5;
			healthBar.iconP1.y = healthBar.y - 75;
			healthBar.iconP2.y = healthBar.y - 75;
		}

		//updateTimeBarType();
	}

	var tweenProg:Float = 1;
	public function songStarted(){
		if (ClientPrefs.etternaHUD != 'ITG') {
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
	}

	public function songEnding()
	{
		if (ClientPrefs.etternaHUD == 'ITG') {
			timeBarBG.exists = false;
			timeBar.exists = false;
			timeTxt.exists = false;
		} else {
			songPosBar.exists = false;
			bar.exists = false;
			songNameTxt.exists = false;
		}
	}
	public function stepHit(step:Int){}
	public function noteJudged(judge:JudgmentData, ?note:Note, ?field:PlayField){}
	public function recalculateRating(){}

	function set_songLength(value:Float)return songLength = value;
	function set_time(value:Float)return time = value;
	function set_songName(value:String)return songName = value;
	function set_songPercent(value:Float)return songPercent = value;

	function loadSongPos()
	{
		if (ClientPrefs.etternaHUD == 'ITG')
		{
			timeTxt = new FlxText(FlxG.width * 0.5 - 200, 19 - 5, 400, songName, 32);
			timeTxt.setFormat(Paths.font(gameFont), 32, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
			timeTxt.scrollFactor.set();
			timeTxt.borderSize = 2;

			var bgGraphic = Paths.image('SimplyLoveHud/TimeBarBG');
			if (bgGraphic == null) bgGraphic = CoolUtil.makeOutlinedGraphic(400, 20, 0xFFFFFFFF, 5, 0xFF000000);

			timeBarBG = new FlxSprite(timeTxt.x - 120, 19 - 6, bgGraphic);
			timeBarBG.scale.set(0.7, 0.9);
			timeBarBG.updateHitbox();
			timeBarBG.color = FlxColor.BLACK;
			timeBarBG.scrollFactor.set();

			timeBar = new FlxBar(timeBarBG.x + 5,timeBarBG.y + 5, LEFT_TO_RIGHT, Std.int(timeBarBG.width - 10), Std.int(timeBarBG.height - 10), this,
				'songPercent', 0, 1);
			timeBar.scrollFactor.set();
			timeBar.createFilledBar(0xFF000000, 0xFFFFFFFF);
			timeBar.numDivisions = 800; // How much lag this causes?? Should i tone it down to idk, 400 or 200?
			timeBar.scrollFactor.set();

			updateTimeBarType();
	
			add(timeBarBG);
			add(timeBar);
			add(timeTxt);
		}
		else
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
		
			FlxSpriteUtil.drawRect(bar, 0, 0, songPosBar.width, songPosBar.height, FlxColor.TRANSPARENT, {thickness: 4, color: (FlxColor.BLACK)});
		
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
	}

	function updateTimeBarType(){	
		updateTime = (ClientPrefs.timeBarType != 'Disabled' && ClientPrefs.timeOpacity > 0);

		if (ClientPrefs.etternaHUD == 'ITG'){
			timeTxt.exists = updateTime;
			timeBarBG.exists = updateTime;
			timeBar.exists = updateTime;
		}else {
			songNameTxt.exists = updateTime;
			songPosBar.exists = updateTime;
			bar.exists = updateTime;
		}

		updateTimeBarAlpha();
	}

	function updateTimeBarAlpha(){
		var timeBarAlpha = ClientPrefs.timeOpacity * alpha * tweenProg;

		if (ClientPrefs.etternaHUD == 'ITG') {
			timeBarBG.alpha = timeBarAlpha;
			timeBar.alpha = timeBarAlpha;
			timeTxt.alpha = timeBarAlpha;
		} else {

			var songPosY = FlxG.height - 706;
			if (ClientPrefs.downScroll)
				songPosY = FlxG.height - 33;
	
			songPosBar.y = songPosY;
			bar.y = songPosBar.y;
			songNameTxt.y = bar.y;

			songPosBar.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
			bar.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
			songNameTxt.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
		}
	}
}