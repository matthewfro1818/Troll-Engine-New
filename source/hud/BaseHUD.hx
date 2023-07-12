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

	public var displayNames:Map<String, String> = ClientPrefs.judgeCounter == 'Shortened' ? shortenedDisplays : fullDisplays;

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

	// just some extra variables lol
	public var healthBar:FNFHealthBar;
	@:isVar
	public var healthBarBG(get, null):FlxSprite;
	public var iconP1:HealthIcon;
	public var iconP2:HealthIcon;

	public var gameFont = PlayState.instance.gameFont;
	public var gameFontBold = PlayState.instance.gameFontBold;

	function get_healthBarBG()return healthBar.healthBarBG;

	public var bar:FlxSprite;
	public var songPosBar:FlxBar = null;
	public var songNameTxt:FlxText;

	public function new(iP1:String, iP2:String, songName:String, stats:Stats) {
		super();
		this.stats = stats;
		this.songName = songName;
		if (!ClientPrefs.useEpics)
			displayedJudges.remove("epic");

		healthBar = new FNFHealthBar(iP1, iP2);
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
	
			songNameTxt.text = songName
				+ ' (${FlxStringUtil.formatTime(secondsTotal, false)} - ${FlxStringUtil.formatTime(Math.floor(songLength / 1000), false)})';
			songNameTxt.updateHitbox();
			songNameTxt.screenCenter(X);
		}
		super.update(elapsed);

	}

	public function beatHit(beat:Int){
		healthBar.iconScale = 1.2;
	}

	public function changedOptions(changed:Array<String>){
		healthBar.healthBarBG.y = FlxG.height * (ClientPrefs.downScroll ? 0.11 : 0.89);
		healthBar.y = healthBarBG.y + 5;
		healthBar.iconP1.y = healthBar.y - 75;
		healthBar.iconP2.y = healthBar.y - 75;

		updateTimeBarType();
	}

	var tweenProg:Float = 0;
	public function songStarted(){
		FlxTween.num(0, 1, 0.5, {
			ease: FlxEase.circOut,
			onComplete: function(tw:FlxTween)
			{
				tweenProg = 1;
			}
		}, function(prog:Float)
		{
			tweenProg = prog;
			songPosBar.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
			bar.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
			songNameTxt.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
		});	
	}

	public function songEnding()
	{
		songPosBar.visible = false;
		bar.visible = false;
		songNameTxt.visible = false;
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

	function updateTimeBarType(){	
		updateTime = (ClientPrefs.timeBarType != 'Disabled' && ClientPrefs.timeOpacity > 0);

		songNameTxt.exists = updateTime;
		songPosBar.exists = updateTime;
		bar.exists = updateTime;

		var songPosY = FlxG.height - 706;
		if (ClientPrefs.downScroll)
			songPosY = FlxG.height - 33;

		if (updateTime){
			songPosBar.y = songPosY;
			bar.y = songPosBar.y;
			songNameTxt.y = bar.y;

			songPosBar.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
			bar.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
			songNameTxt.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
		}
	}
}