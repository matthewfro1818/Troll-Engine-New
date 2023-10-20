package hud;

import flixel.util.FlxSpriteUtil;
import flixel.tweens.FlxEase;
import flixel.util.FlxStringUtil;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import playfields.*;
import JudgmentManager.JudgmentData;

import flixel.tweens.FlxTween;
import flixel.text.FlxText;

class SacHUD extends CommonHUD {
	public var judgeTexts:Map<String, FlxText> = [];
	public var judgeNames:Map<String, FlxText> = [];
	
	public var scoreTxt:FlxText;
	var accuracyTxt:FlxText;
	var missTxt:FlxText;
	var npsTxt:FlxText;

	public var hitbar:Hitbar;

	var hitbarTween:FlxTween;
	var scoreTxtTween:FlxTween;

	var songHighscore:Int = 0;
	var songWifeHighscore:Float = 0;
	var scoreString = Paths.getString("score");
	var hiscoreString = Paths.getString("highscore");
	var ratingString = Paths.getString("rating");
	var cbString = Paths.getString("cbplural");
	var npsString = Paths.getString("nps");
	
	override public function new(iP1:String, iP2:String, songName:String, stats:Stats)
	{
		super(iP1, iP2, songName, stats);
		if (!ClientPrefs.useEpics)
			displayedJudges.remove("epic");

		stats.changedEvent.add(statChanged);

		add(healthBarBG);
		add(healthBar);
		add(iconP1);
		add(iconP2);
		
		songHighscore = Highscore.getScore(songName,PlayState.difficulty);
		songWifeHighscore = Highscore.getNotesHit(songName,PlayState.difficulty);

		scoreTxt = new FlxText(healthBarBG.x - healthBarBG.width / 2, healthBarBG.y - 10, 0, "", 20);
		if (ClientPrefs.downScroll)
			scoreTxt.y = healthBarBG.y - 18;
		scoreTxt.setFormat(Paths.font("fullphanmuff.ttf"), 20, FlxColor.WHITE, RIGHT);
		scoreTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
		scoreTxt.scrollFactor.set();
		add(scoreTxt);
		scoreTxt.visible = scoreTxt.alpha > 0;

		missTxt = new FlxText(scoreTxt.x, scoreTxt.y - 26, 0, "", 20);
		if (ClientPrefs.downScroll)
			missTxt.y = scoreTxt.y + 26;
		missTxt.setFormat(Paths.font("fullphanmuff.ttf"), 20, FlxColor.WHITE, RIGHT);
		missTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
		missTxt.scrollFactor.set();
		add(missTxt);
		missTxt.visible = missTxt.alpha > 0;

		accuracyTxt = new FlxText(missTxt.x, missTxt.y - 26, 0, "", 20);
		if (ClientPrefs.downScroll)
			accuracyTxt.y = missTxt.y + 26;
		accuracyTxt.setFormat(Paths.font("fullphanmuff.ttf"), 20, FlxColor.WHITE, RIGHT);
		accuracyTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
		accuracyTxt.scrollFactor.set();
		add(accuracyTxt);
		accuracyTxt.visible = accuracyTxt.alpha > 0;

		npsTxt = new FlxText(accuracyTxt.x, accuracyTxt.y - 26, 0, "", 20);
		if (ClientPrefs.downScroll)
			npsTxt.y = accuracyTxt.y + 26;
		npsTxt.setFormat(Paths.font("fullphanmuff.ttf"), 20, FlxColor.WHITE, RIGHT);
		npsTxt.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);
		npsTxt.scrollFactor.set();
		if (!ClientPrefs.npsDisplay)
			npsTxt.alpha = 0;
		add(npsTxt);
		npsTxt.visible = npsTxt.alpha > 0;

		if (ClientPrefs.judgeCounter != 'Off')
			generateJudgementDisplays();

		//
		
		hitbar = new Hitbar();
		hitbar.alpha = alpha;
		hitbar.visible = ClientPrefs.hitbar;
		add(hitbar);
		if (ClientPrefs.hitbar)
		{
			hitbar.screenCenter(XY);
			if (ClientPrefs.downScroll)
				hitbar.y -= 230;
			else
				hitbar.y += 330;
		}

		add(scoreTxt);
        loadSongPos();
	}

    var timeBar:FlxBar;
    var timeBarBG:FlxSprite;
    var timeTxt:FlxText;
	var timeTxtElapsed:FlxText;
    var songTxt:FlxText;

    override function loadSongPos() {
        timeBarBG = new FlxSprite(0, 10).loadGraphic(Paths.image('healthBar'));
		if (ClientPrefs.downScroll)
			timeBarBG.y = -4 + 10;
		else
			timeBarBG.y = 701 - 5;
		timeBarBG.screenCenter(X);
		timeBarBG.scale.x += 1.1;
		timeBarBG.scrollFactor.set();
		add(timeBarBG);

		timeBar = new FlxBar(0 + 16, timeBarBG.y + 4, LEFT_TO_RIGHT, FlxG.width - 32, Std.int(timeBarBG.height - 8), this, 'songPercent', 0, 1);
		timeBar.numDivisions = 1000;
		timeBar.scrollFactor.set();
		timeBar.createGradientBar([FlxColor.BLACK], [FlxColor.WHITE]);
		timeBar.updateBar();
		add(timeBar);

		songTxt = new FlxText(timeBarBG.x + (timeBarBG.width / 2) - (songName.length * 5), timeBarBG.y, 0, songName, 20);
		if (ClientPrefs.downScroll)
			songTxt.y = timeBarBG.y + 27;
		else
			songTxt.y = timeBarBG.y - 27;
		songTxt.setFormat(Paths.font("fullphanmuff.ttf"), 20, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		songTxt.scrollFactor.set();
		add(songTxt);

		timeTxt = new FlxText(1198, 664, 56, "", 20);
		if (ClientPrefs.downScroll)
			timeTxt.y = timeBarBG.y + 27;
		else
			timeTxt.y = timeBarBG.y - 27;
		timeTxt.setFormat(Paths.font("fullphanmuff.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxt.scrollFactor.set();
		add(timeTxt);

		timeTxtElapsed = new FlxText(26, 671, 56, "", 20);
		if (ClientPrefs.downScroll)
			timeTxtElapsed.y = timeBarBG.y + 27;
		else
			timeTxtElapsed.y = timeBarBG.y - 27;
		timeTxtElapsed.setFormat(Paths.font("fullphanmuff.ttf"), 20, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		timeTxtElapsed.scrollFactor.set();
		add(timeTxtElapsed);

		for (e in [timeTxtElapsed, timeTxt, songTxt])
			e.setBorderStyle(OUTLINE, 0xFF000000, 3, 1);

        updateTimeBarType();
    }

    override function updateTimeBarType(){	
		updateTime = (ClientPrefs.timeBarType != 'Disabled' && ClientPrefs.timeOpacity > 0);

        for (e in [timeTxtElapsed, timeTxt, songTxt,timeBar,timeBarBG]) {
            if (e != null) {
                e.exists = updateTime;
            }
        }

		updateTimeBarAlpha();
	}

	override function updateTimeBarAlpha(){
        for (e in [timeTxtElapsed, timeTxt, songTxt,timeBar,timeBarBG]) {
            if (e != null) {
                e.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
            }
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
			text.setFormat(Paths.font("Bold Normal Text.ttf"), 24, judgeColours.get(judgment), LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			text.scrollFactor.set();
			text.borderSize = 1.25;
			add(text);

			var numb = new FlxText(textPosX, text.y, textWidth, "0", 20);
			numb.setFormat(Paths.font("Normal Text.ttf"), 24, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
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

        scoreTxt.y = ClientPrefs.downScroll ? healthBarBG.y - 18 : healthBarBG.y - 10;
		missTxt.y = ClientPrefs.downScroll ? scoreTxt.y - 26 : scoreTxt.y + 26;
		accuracyTxt.y = ClientPrefs.downScroll ? missTxt.y - 26 : missTxt.y + 26;
		npsTxt.y = ClientPrefs.downScroll ? accuracyTxt.y - 26 : accuracyTxt.y + 26;

		if (ClientPrefs.downScroll)
			timeBarBG.y = -4 + 10;
		else
			timeBarBG.y = 701 - 5;
		timeBar.y = timeBarBG.y + 4;
		if (ClientPrefs.downScroll)
			songTxt.y = timeBarBG.y + 27;
		else
			songTxt.y = timeBarBG.y - 27;

		if (ClientPrefs.downScroll)
			timeTxt.y = timeBarBG.y + 27;
		else
			timeTxt.y = timeBarBG.y - 27;

		if (ClientPrefs.downScroll)
			timeTxtElapsed.y = timeBarBG.y + 27;
		else
			timeTxtElapsed.y = timeBarBG.y - 27;
		
		if (ClientPrefs.hitbar)
		{
			hitbar.screenCenter(XY);
			if (ClientPrefs.downScroll)
			{
				hitbar.y -= 220;
				hitbar.averageIndicator.flipY = false;
				hitbar.averageIndicator.y = hitbar.y - (hitbar.averageIndicator.width + 5);
			}
			else
				hitbar.y += 340;
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

	override function update(elapsed:Float)
	{
		var shownScore:String;
		var isHighscore:Bool;
		if (ClientPrefs.showWifeScore){
			shownScore = Std.string(Math.floor(totalNotesHit * 100));
			isHighscore = songWifeHighscore != 0 && totalNotesHit > songWifeHighscore;
		}else{
			shownScore = Std.string(score);
			isHighscore = songHighscore != 0 && score > songHighscore;
		}


		scoreTxt.text = '$scoreString: ' + shownScore;
		missTxt.text = '$cbString: ' + comboBreaks;
		accuracyTxt.text = "Accuracy: " + (grade == '?' ? grade : Highscore.floorDecimal(ratingPercent * 100, 2)
		+ '% / $grade [${(ratingFC == stats.gfc && ClientPrefs.wife3) ? stats.fc : ratingFC}]');
		if (ClientPrefs.npsDisplay)
			npsTxt.text = "NPS: " + '${nps} / ${npsPeak}';
		/*scoreTxt.text = 
		(isHighscore ? '$hiscoreString: ' : '$scoreString: ') + shownScore +
		' | $cbString: ' + comboBreaks + 
		' | $ratingString: '
		+ (grade == '?' ? grade : Highscore.floorDecimal(ratingPercent * 100, 2)
			+ '% / $grade [${(ratingFC == stats.gfc && ClientPrefs.wife3) ? stats.fc : ratingFC}]');
		if (ClientPrefs.npsDisplay)
			scoreTxt.text += ' | $npsString: ${nps} / ${npsPeak}';*/

		for (k => v in judgements){
			if (judgeTexts.exists(k))
				judgeTexts.get(k).text = Std.string(v);
		}

        if (updateTime)
            {
                var curTime:Float = Conductor.songPosition - ClientPrefs.noteOffset;
                if (curTime < 0)
                    curTime = 0;
                songPercent = (curTime / songLength);

                var songCalc:Float = (songLength - curTime);
                var songelapsed:Float = (songLength - curTime);
                songelapsed = curTime;

                var secondsTotal:Int = Math.floor(songCalc / 1000);
                if (secondsTotal < 0)
                    secondsTotal = 0;

                var elapsed:Int = Math.floor(songelapsed / 1000);
                if (elapsed < 0)
                    elapsed = 0;

                timeTxt.text = FlxStringUtil.formatTime(secondsTotal, false);
                timeTxtElapsed.text = FlxStringUtil.formatTime(elapsed, false);
            }
		
		super.update(elapsed);
	}

	override function noteJudged(judge:JudgmentData, ?note:Note, ?field:PlayField)
	{
		var hitTime = note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset;

		if (ClientPrefs.hitbar)
			hitbar.addHit(hitTime);
		if (ClientPrefs.scoreZoom)
		{
			if (scoreTxtTween != null)
				scoreTxtTween.cancel();

			var judgeName = judgeNames.get(judge.internalName);
			var judgeTxt = judgeTexts.get(judge.internalName);
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
			}

			scoreTxt.scale.x = 1.075;
			scoreTxt.scale.y = 1.075;
			scoreTxtTween = FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2, {
				onComplete: function(twn:FlxTween)
				{
					scoreTxtTween = null;
				}
			});
		}
	}

	function statChanged(stat:String, val:Dynamic)
		{
			switch (stat)
			{
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