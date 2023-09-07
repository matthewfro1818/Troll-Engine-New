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
	var itgDisplays:Map<String, String> = [
		"epic" => Paths.getString("tier5itg"),
		"sick" => Paths.getString("tier4itg"),
		"good" => Paths.getString("tier3itg"),
		"bad" => Paths.getString("tier2itg"),
		"shit" => Paths.getString("tier1itg"),
		"miss" => Paths.getString("tier0itg"),
		"cb" => Paths.getString("cbitg")
	];

	var fullDisplays:Map<String, String> = [
		"epic" => Paths.getString("tier5plural"),
		"sick" => Paths.getString("tier4plural"),
		"good" => Paths.getString("tier3plural"),
		"bad" => Paths.getString("tier2plural"),
		"shit" => Paths.getString("tier1plural"),
		"miss" => Paths.getString("tier0plural"),
		"cb" => Paths.getString("cbplural")
	];

	var shortenedDisplays:Map<String, String> = [
		"epic" => Paths.getString("tier5short"),
		"sick" => Paths.getString("tier4short"),
		"good" => Paths.getString("tier3short"),
		"bad" => Paths.getString("tier2short"),
		"shit" => Paths.getString("tier1short"),
		"miss" => Paths.getString("tier0short"),
		"cb" => Paths.getString("cbshort")
	];

	public var displayNames(get, null):Map<String, String>;
    function get_displayNames()
		return ClientPrefs.judgeCounter == 'Shortened' ? ClientPrefs.etternaHUD == 'ITG' ? itgDisplays : shortenedDisplays : ClientPrefs.etternaHUD == 'ITG' ? itgDisplays : fullDisplays;

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
	public var displayedHealth(default, set):Float = 0;
	function set_displayedHealth(nV:Float)return displayedHealth = nV; // override healthbar shit here lol
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

	public function reloadHealthBarColors(dadColor:FlxColor, bfColor:FlxColor){}

	public function new(iP1:String, iP2:String, songName:String, stats:Stats) {
		super();
	}

	override public function update(elapsed:Float){
		super.update(elapsed);

	}

	public function beatHit(beat:Int){	}
	public function changedOptions(changed:Array<String>){}
	public function songStarted(){}
    public function changedCharacter(id:Int, char:Character){}
	public function songEnding(){}
	public function stepHit(step:Int){}
	public function noteJudged(judge:JudgmentData, ?note:Note, ?field:PlayField){}
	public function recalculateRating(){}

	function set_songLength(value:Float)return songLength = value;
	function set_time(value:Float)return time = value;
	function set_songName(value:String)return songName = value;
	function set_songPercent(value:Float)return songPercent = value;
}