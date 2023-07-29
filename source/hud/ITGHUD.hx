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

class ITGHUD extends BaseHUD {
    public var judgeTexts:Map<String, FlxText> = [];
	public var judgeNames:Map<String, FlxText> = [];
	
	public var scoreTxt:FlxText;
	public var scoreTxtRight:FlxText;

	public var hitbar:Hitbar;

	var hitbarTween:FlxTween;

	var songHighscore:Int = 0;
	var songWifeHighscore:Float = 0;

	var bpmText:FlxText;
	override public function new(iP1:String, iP2:String, songName:String, stats:Stats)
	{
		super(iP1, iP2, songName, stats);

		stats.changedEvent.add(statChanged);
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

		scoreTxt = new FlxText(0, healthBarBG.y + 38, healthBar.width, "", 96);
		scoreTxt.setFormat(Paths.font("wendy.ttf"), 96, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.scrollFactor.set();
		scoreTxt.visible = scoreTxt.alpha > 0;

		scoreTxtRight = new FlxText(1000, healthBarBG2.y + 38, healthBar2.width, "", 96);
		scoreTxtRight.setFormat(Paths.font("wendy.ttf"), 96, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxtRight.scrollFactor.set();
		scoreTxtRight.visible = scoreTxtRight.alpha > 0;

		if (ClientPrefs.judgeCounter != 'Off')
		{
			var textWidth = ClientPrefs.judgeCounter == 'Shortened' ? 150 : 200;
			var textPosX = ClientPrefs.hudPosition == 'Right' ? (FlxG.width - 5 - textWidth) : 5;
			var textPosY = (FlxG.height - displayedJudges.length*25) * 0.5;

			for (idx in 0...displayedJudges.length)
			{
				var judgment = displayedJudges[idx];

				var text = new FlxText(textPosX, textPosY + idx*25, textWidth, displayNames.get(judgment), 20);
				text.setFormat(Paths.font(gameFontBold), 24, itgJudgeColours.get(judgment), LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				text.scrollFactor.set();
				text.borderSize = 1.25;
				add(text);

				var numb = new FlxText(textPosX, text.y, textWidth, "0", 20);
				numb.setFormat(Paths.font(gameFont), 24, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				numb.scrollFactor.set();
				numb.borderSize = 1.25;
				add(numb);

				judgeTexts.set(judgment, numb);
				judgeNames.set(judgment, text);
			}
		}

		//
		
		hitbar = new Hitbar();
		hitbar.alpha = alpha;
		hitbar.visible = ClientPrefs.hitbar;
		add(hitbar);
		if (ClientPrefs.hitbar)
		{
			hitbar.screenCenter(XY);
			if (ClientPrefs.downScroll)
				hitbar.y -= 250;
			else
				hitbar.y += 330;
		}

		add(scoreTxt);
		add(scoreTxtRight);
		add(bpmText);
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
	}

	override function update(elapsed:Float){
		var shownScore:String = Std.string(score);
		var isHighscore:Bool = false;
		if (ClientPrefs.showWifeScore){
			shownScore = Std.string(Math.floor(stats.totalNotesHit * 100));
			isHighscore = songWifeHighscore != 0 && stats.totalNotesHit > songWifeHighscore;
		}else
			isHighscore = songHighscore != 0 && score > songHighscore;


		scoreTxt.text = grade != '?' ? '${Highscore.floorDecimal(ratingPercent * 100, 2)}': '0.00';
		scoreTxtRight.text = grade != '?' ? '${Highscore.floorDecimal(ratingPercent * 100, 2)}': '0.00';

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

		if (ClientPrefs.hitbar)
			hitbar.addHit(hitTime);
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