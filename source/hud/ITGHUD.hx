package hud;

import PlayState.FNFHealthBar;
import flixel.util.FlxSpriteUtil;
import flixel.tweens.FlxEase;
import flixel.util.FlxStringUtil;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import playfields.*;
import JudgmentManager.JudgmentData;

import flixel.tweens.FlxTween;
import flixel.text.FlxText;

class ITGHUD extends CommonHUD {
    public var judgeTexts:Map<String, FlxText> = [];
	public var judgeNames:Map<String, FlxText> = [];
	
	public var accTxt:FlxText;
	public var accTxtRight:FlxText;
	public var scoreTxt:FlxText;

	public var hitbar:Hitbar;

	var hitbarTween:FlxTween;

	var songHighscore:Int = 0;
	var songWifeHighscore:Float = 0;

	var bpmText:FlxText;
	// ITG Bar
	var timeBar:FlxBar;
	var timeTxt:FlxText;
	var timeBarBG:FlxSprite;
	var scoreBG:FlxSprite;

	
	// just some extra variables lol
	public var healthBar2:FNFHealthBar;
	@:isVar
	public var healthBarBG2(get, null):FlxSprite;
	function get_healthBarBG2()return healthBar2.healthBarBG;

	override function set_displayedHealth(value:Float){
		healthBar.value = value;
		healthBar2.value = value;
		displayedHealth = value;
		return value;
	}

	override public function new(iP1:String, iP2:String, songName:String, stats:Stats)
	{
		super(iP1, iP2, songName, stats);

		stats.changedEvent.add(statChanged);

		scoreBG = new FlxSprite(0, 0).makeGraphic(FlxG.width, 136, 0xFF000000);
		scoreBG.alpha = 0.6;
		insert(members.indexOf(timeBarBG), scoreBG);

		healthBar2 = new FNFHealthBar(iP1, iP2);
		add(healthBarBG2);
		add(healthBar2);
		add(healthBarBG);
		add(healthBar);

		healthBar2.x = 980;

		add(iconP1);
		add(iconP2);
		
		songHighscore = Highscore.getScore(songName,PlayState.difficulty);
		songWifeHighscore = Highscore.getNotesHit(songName,PlayState.difficulty);

		var bpmSizeText:Int = ClientPrefs.hitbar ? 30 : 55;

		bpmText = new FlxText(FlxG.width * 0.5 - 200, 50, 400, Std.string(PlayState.SONG.bpm),bpmSizeText);
		bpmText.setFormat(Paths.font('miso-bold.ttf'), bpmSizeText, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
		bpmText.scrollFactor.set();

		accTxt = new FlxText(0, healthBarBG.y + 38, healthBar.width, "", 96);
		accTxt.setFormat(Paths.font("wendy.ttf"), 96, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		accTxt.scrollFactor.set();
		accTxt.visible = accTxt.alpha > 0;

		accTxtRight = new FlxText(1000, healthBarBG2.y + 38, healthBar2.width, "", 96);
		accTxtRight.setFormat(Paths.font("wendy.ttf"), 96, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		accTxtRight.scrollFactor.set();
		accTxtRight.visible = accTxtRight.alpha > 0;

		var tWidth = 200;
		scoreTxt = new FlxText(0, 0, tWidth, "0", 20);
		scoreTxt.setFormat(Paths.font("miso-bold.ttf"), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.screenCenter(Y);
		scoreTxt.y -= 120;
		scoreTxt.x += 20 - 15;
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		add(scoreTxt);

		botplayTxt = new FlxText(0, (ClientPrefs.downScroll ? FlxG.height - 44 : 19) + 15 + (ClientPrefs.downScroll ? -78 : 55), FlxG.width, "AutoPlay", 32);
		botplayTxt.setFormat(Paths.font('miso-bold.ttf'), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		botplayTxt.scrollFactor.set();
		botplayTxt.borderSize = 1.25;
		botplayTxt.exists = false;
		add(botplayTxt);

		if (ClientPrefs.judgeCounter != 'Off')
			generateJudgementDisplays();

		//
		
		hitbar = new Hitbar();
		hitbar.alpha = alpha;
		hitbar.visible = ClientPrefs.hitbar;
		statChanged("totalNotesHit", stats.totalNotesHit);
		statChanged("score", stats.score);
		add(hitbar);
		if (ClientPrefs.hitbar)
		{
			hitbar.screenCenter(XY);
			if (ClientPrefs.downScroll)
				hitbar.y -= 250;
			else
				hitbar.y += 330;
		}

		add(accTxt);
		add(accTxtRight);
		add(bpmText);
	}

	override function loadSongPos() {
		timeTxt = new FlxText(FlxG.width * 0.5 - 200, 19 - 5, 400, songName, 32);
		timeTxt.setFormat(Paths.font("miso-bold.ttf"), 32, 0xFFFFFFFF, CENTER, FlxTextBorderStyle.OUTLINE, 0xFF000000);
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
	
		add(timeBarBG);
		add(timeBar);
		add(timeTxt);

		updateTimeBarType();
	}

	override function updateTimeBarType() {
		updateTime = (ClientPrefs.timeBarType != 'Disabled' && ClientPrefs.timeOpacity > 0);

		if (timeTxt != null || timeBarBG != null || timeBar != null) {
			timeTxt.exists = updateTime;
			timeBarBG.exists = updateTime;
			timeBar.exists = updateTime;
		}

		updateTimeBarAlpha();
	}

	override function updateTimeBarAlpha() {
		if (timeTxt != null || timeBarBG != null || timeBar != null)
		{
			timeBarBG.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
			timeBar.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
			timeTxt.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
		}
	}

	override function songEnding() {
		if (timeTxt != null || timeBarBG != null || timeBar != null) {
			timeBarBG.exists = false;
			timeBar.exists = false;
			timeTxt.exists = false;
		}
	}

	override function reloadHealthBarColors(dadColor:FlxColor, bfColor:FlxColor) {
		if (healthBar != null){
			healthBar.createFilledBar(
				FlxColor.BLACK,
				0xFFdce0e6
			);
			healthBar.updateBar();
		}

		if (healthBar2 != null){
			healthBar2.createFilledBar(
				FlxColor.BLACK,
				0xFFdce0e6
			);
			healthBar2.updateBar();
		}	
	}

	function clearJudgementDisplays()
	{
		for (text in judgeTexts){
			remove(text);
			text.destroy();
		}
		judgeTexts.clear();

		for (text in judgeNames){
			remove(text);
			text.destroy();
		}
		judgeNames.clear();
	}

	function generateJudgementDisplays()
	{
		var textWidth = ClientPrefs.judgeCounter == 'Shortened' ? 150 : 200;
		var textPosX = ClientPrefs.hudPosition == 'Right' ? (FlxG.width - 5 - textWidth) : 5;
		var textPosY = (FlxG.height - displayedJudges.length*25) * 0.5;

		for (idx in 0...displayedJudges.length)
		{
			var judgment = displayedJudges[idx];

			var text = new FlxText(textPosX, textPosY + idx*25, textWidth, displayNames.get(judgment), 20);
			text.setFormat(Paths.font("miso-bold.ttf"), 24, itgJudgeColours.get(judgment), LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1.25;
			add(text);

			var numb = new FlxText(textPosX, text.y, textWidth, "0", 20);
			numb.setFormat(Paths.font("miso-bold.ttf"), 24, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			numb.scrollFactor.set();
			numb.borderSize = 1.25;
			add(numb);

			judgeTexts.set(judgment, numb);
			judgeNames.set(judgment, text);
		}
	}


	override function changedOptions(changed:Array<String>)
	{
		super.changedOptions(changed);

		hitbar.visible = ClientPrefs.hitbar;
		
		if (ClientPrefs.hitbar)
		{
			hitbar.screenCenter(XY);
			if (ClientPrefs.downScroll)
			{
				hitbar.y -= 250;
				hitbar.averageIndicator.flipY = false;
				hitbar.averageIndicator.y = hitbar.y - (hitbar.averageIndicator.width + 5);
			}
			else
				hitbar.y += 330;
		}

		var regenJudgeDisplays:Bool = false;
		for (optionName in changed){
			if (optionName == "judgeCounter" || optionName == "hudPosition"){
				regenJudgeDisplays = true; 
				break;
			}
		}

		if (regenJudgeDisplays)
		{
			clearJudgementDisplays();

			if (ClientPrefs.judgeCounter != 'Off')
				generateJudgementDisplays();
		}
	}

	override function update(elapsed:Float){
		var shownScore:String = Std.string(score);
		var isHighscore:Bool = false;
		if (ClientPrefs.showWifeScore){
			shownScore = Std.string(Math.floor(stats.totalNotesHit * 100));
			isHighscore = songWifeHighscore != 0 && stats.totalNotesHit > songWifeHighscore;
		}else
			isHighscore = songHighscore != 0 && score > songHighscore;


		accTxt.text = grade != '?' ? '${Highscore.floorDecimal(ratingPercent * 100, 2)}': '0.00';
		accTxtRight.text = grade != '?' ? '${Highscore.floorDecimal(ratingPercent * 100, 2)}': '0.00';

		for (k in judgements.keys())
		{
			if (judgeTexts.exists(k))
				judgeTexts.get(k).text = Std.string(judgements.get(k));
		}
		
		super.update(elapsed);
	}

	override function noteJudged(judge:JudgmentData, ?note:Note, ?field:PlayField)
	{
		var hitTime = note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset;

		hitbar.addHit(-hitTime);
		if (ClientPrefs.scoreZoom)
		{
			FlxTween.cancelTweensOf(scoreTxt.scale);
			scoreTxt.scale.set(1.075, 1.075);
			FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2);
		}

		if (ClientPrefs.hitbar)
			hitbar.addHit(hitTime);
	}

	function statChanged(stat:String, val:Dynamic)
		{
			switch (stat)
			{
				case 'totalNotesHit':
					if (ClientPrefs.showWifeScore)
					{
						var disp:Int = Math.floor(val * 100);
						var displayedScore = Std.string(disp);
						if (displayedScore.length > 7)
						{
							if (disp < 0)
								displayedScore = '-999999';
							else
								displayedScore = '9999999';
						}

						scoreTxt.text = displayedScore;
						scoreTxt.color = !PlayState.instance.saveScore ? 0x818181 : ((songWifeHighscore != 0 && val > songWifeHighscore) ? 0xFFD800 : 0xFFFFFF);
					}
				case 'score':
					if(!ClientPrefs.showWifeScore){
						var displayedScore = Std.string(val);
						if (displayedScore.length > 7)
						{
							if (val < 0)
								displayedScore = '-999999';
							else
								displayedScore = '9999999';
						}
	
						scoreTxt.text = displayedScore;
						scoreTxt.color = !PlayState.instance.saveScore ? 0x818181 : ((songHighscore != 0 && val > songHighscore) ? 0xFFD800 : 0xFFFFFF);
					}
				case 'misses':
					misses = val;
					var judgeName = judgeNames.get('miss');
					var judgeTxt = judgeTexts.get('miss');
					if (judgeName != null)
					{
						FlxTween.cancelTweensOf(judgeName.scale);
						judgeName.scale.set(1.075, 1.075);
						FlxTween.tween(judgeName.scale, {x: 1, y: 1}, 0.2);
					}
					if (judgeTxt != null)
					{
						FlxTween.cancelTweensOf(judgeTxt.scale);
						judgeTxt.scale.set(1.075, 1.075);
						FlxTween.tween(judgeTxt.scale, {x: 1, y: 1}, 0.2);
	
						judgeTxt.text = Std.string(val);
					}
			}
		}

	override public function beatHit(beat:Int){
		if (hitbar != null)
			hitbar.beatHit();

		super.beatHit(beat);
	}
}