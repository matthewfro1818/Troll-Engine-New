package hud;

import flixel.util.FlxSpriteUtil;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.util.FlxStringUtil;
import flixel.ui.FlxBar;
import flixel.util.FlxColor;
import playfields.*;
import flixel.tweens.FlxTween;
import flixel.text.FlxText;
import JudgmentManager.JudgmentData;

class AdvancedHUD extends BaseHUD
{
	public var judgeTexts:Map<String, FlxText> = [];
	public var judgeNames:Map<String, FlxText> = [];
	public var gradeTxt:FlxText;
	public var scoreTxt:FlxText;
	public var ratingTxt:FlxText;
	public var fcTxt:FlxText;
	public var npsTxt:FlxText;
	public var pcTxt:FlxText;
	public var hitbar:Hitbar;

	public var bar:FlxSprite;
	public var songPosBar:FlxBar = null;
	public var songNameTxt:FlxText;

	var peakCombo:Int = 0;
	var songHighscore:Int = 0;
	public var hudPosition(default, null):String = ClientPrefs.hudPosition;

	var npsIdx:Int = 0;
	override public function new(iP1:String, iP2:String, songName:String, stats:Stats)
	{
		super(iP1, iP2, songName, stats);

		stats.changedEvent.add(statChanged);

		add(healthBarBG);
		add(healthBar);
		add(iconP1);
		add(iconP2);
		
		displayedJudges.push("cb");
		
		songHighscore = Highscore.getScore(songName,PlayState.difficulty);
		var tWidth = 200;
		scoreTxt = new FlxText(0, 0, tWidth, "0", 20);
		scoreTxt.setFormat(Paths.font(gameFont), 40, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		scoreTxt.screenCenter(Y);
		scoreTxt.y -= 120;
		scoreTxt.x += 20 - 15;
		scoreTxt.scrollFactor.set();
		scoreTxt.borderSize = 1.25;
		add(scoreTxt);

		ratingTxt = new FlxText(0, 0, tWidth, "100%", 20);
		ratingTxt.setFormat(Paths.font(gameFont), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		ratingTxt.screenCenter(Y);
		ratingTxt.y -= 90;
		ratingTxt.x += 20 - 15;
		ratingTxt.scrollFactor.set();
		ratingTxt.borderSize = 1.25;
		add(ratingTxt);

		fcTxt = new FlxText(0, 0, tWidth, "Clear", 20);
		fcTxt.setFormat(Paths.font(gameFont), 32, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		fcTxt.screenCenter(Y);
		fcTxt.y -= 60;
		fcTxt.x += 20 - 15;
		fcTxt.scrollFactor.set();
		fcTxt.borderSize = 1.25;
		add(fcTxt);

		gradeTxt = new FlxText(0, 0, 0, "C", 20);
		gradeTxt.setFormat(Paths.font(gameFont), 46, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		gradeTxt.x = 20;
		gradeTxt.color = 0xFFD800;
		gradeTxt.y = FlxG.height - gradeTxt.height;
		gradeTxt.scrollFactor.set();
		gradeTxt.borderSize = 1.25;
		add(gradeTxt);

		var idx:Int = 0;
		if (ClientPrefs.judgeCounter != 'Off'){
			// maybe this'd benefit from a JudgeCounter object idk
			for (judgment in displayedJudges){
				var text = new FlxText(0, 0, tWidth, displayNames.get(judgment), 20);
				text.setFormat(Paths.font(gameFontBold), 24, judgeColours.get(judgment), LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				text.screenCenter(Y);
				text.y -= 35 - (25 * idx);
				text.x += 20 - 15;
				text.scrollFactor.set();
				text.borderSize = 1.25;
				add(text);

				var numb = new FlxText(0, 0, tWidth, "0", 20);
				numb.setFormat(Paths.font(gameFontBold), 24, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
				numb.screenCenter(Y);
				numb.y -= 35 - (25 * idx);
				numb.x += 25 - 15;
				numb.scrollFactor.set();
				numb.borderSize = 1.25;
				add(numb);

				judgeTexts.set(judgment, numb);
				judgeNames.set(judgment, text);
				idx++;
			}
		}else{
			var text = new FlxText(0, 0, tWidth, "Misses", 20);
			text.setFormat(Paths.font(gameFontBold), 24, 0xBDBDBD, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.WHITE);
			text.screenCenter(Y);
			text.y -= 35;
			text.x += 20 - 15;
			text.scrollFactor.set();
			text.borderSize = 1.25;
			add(text);
			var numb = new FlxText(0, 0, tWidth, "0", 20);
			numb.setFormat(Paths.font(gameFont), 24, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
			numb.screenCenter(Y);
			numb.y -= 35;
			numb.x += 25 - 15;
			numb.scrollFactor.set();
			numb.borderSize = 1.25;
			add(numb);
			judgeTexts.set('miss', numb);
			judgeNames.set('miss', text);
			idx++;
		}

		npsIdx = idx;
		npsTxt = new FlxText(0, 0, tWidth, "NPS: 0 (Peak: 0)", 20);
		npsTxt.setFormat(Paths.font(gameFont), 26, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		npsTxt.screenCenter(Y);
		npsTxt.y -= 5 - (25 * idx);
		npsTxt.x += 20 - 15;
		npsTxt.scrollFactor.set();
		npsTxt.borderSize = 1.25;
		npsTxt.visible = ClientPrefs.npsDisplay;
		add(npsTxt);
		
		pcTxt = new FlxText(0, 0, tWidth, "Peak Combo: 0", 20);
		pcTxt.setFormat(Paths.font(gameFont), 26, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		pcTxt.screenCenter(Y);
		pcTxt.y -= 5 - (25 * (ClientPrefs.npsDisplay ? (idx + 1) : idx));
		pcTxt.x += 20 - 15;
		pcTxt.scrollFactor.set();
		pcTxt.borderSize = 1.25;
		add(pcTxt);


		if (hudPosition == 'Right'){
			for(obj in members)
				obj.x = FlxG.width - obj.width - obj.x;
		}

		loadSongPos();

		//

		hitbar = new Hitbar();
		hitbar.alpha = alpha;
		hitbar.visible = ClientPrefs.hitbar;
		add(hitbar);
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
	}

	var tweenProg:Float = 0;

	override public function songStarted()
	{
		FlxTween.num(0, 1, 0.5, {ease: FlxEase.circOut, onComplete:function(tw:FlxTween){
			tweenProg = 1;
		}}, function(prog:Float)
		{
			tweenProg = prog;
			bar.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
			songPosBar.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
			songNameTxt.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
		});
	}

	override public function songEnding()
	{
		bar.visible = false;
		songPosBar.visible = false;
		songNameTxt.visible = false;
	}

	function colorLerp(clr1:FlxColor, clr2:FlxColor, alpha:Float){
		return FlxColor.fromRGBFloat(
			FlxMath.lerp(clr1.redFloat, clr2.redFloat, alpha),
			FlxMath.lerp(clr1.greenFloat, clr2.greenFloat, alpha),
			FlxMath.lerp(clr1.blueFloat, clr2.blueFloat, alpha),
			FlxMath.lerp(clr1.alphaFloat, clr2.alphaFloat, alpha)
		);
	}

	override function recalculateRating(){
		var gradeColor = FlxColor.WHITE;
		if(grade!='?'){
			if (ratingPercent < 0)
				gradeColor = judgeColours.get("miss");
			else if (ratingPercent >= 0.9)
				gradeColor = colorLerp(judgeColours.get("good"), 0xFFD800, (ratingPercent - 0.9) / 0.1);
			
			else if (ratingPercent >= 0.6)
				gradeColor = colorLerp(FlxColor.WHITE, judgeColours.get("good"), (ratingPercent - 0.6) / 0.3);
			else
				gradeColor = colorLerp(judgeColours.get("miss"), FlxColor.WHITE, (ratingPercent) / 0.6);
		}
		

		gradeTxt.color = gradeColor;
	}

	override function changedOptions(changed:Array<String>){
		healthBar.healthBarBG.y = FlxG.height * (ClientPrefs.downScroll ? 0.11 : 0.89);
		healthBar.y = healthBarBG.y + 5;
		healthBar.iconP1.y = healthBar.y - 75;
		healthBar.iconP2.y = healthBar.y - 75;

		var songPosY = FlxG.height - 706;
		if (ClientPrefs.downScroll)
			songPosY = FlxG.height - 33;
		songPosBar.y = songPosY;
		bar.y = songPosBar.y;
		songNameTxt.y = bar.y + ((songPosBar.height - 15) / 2) - 5;
		songPosBar.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
		songNameTxt.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
		bar.alpha = ClientPrefs.timeOpacity * alpha * tweenProg;
		hitbar.visible = ClientPrefs.hitbar;
		npsTxt.visible = ClientPrefs.npsDisplay;

		songNameTxt.visible = updateTime;
		songPosBar.visible = updateTime;
		bar.visible = updateTime;

		pcTxt.screenCenter(Y);
		pcTxt.y -= 5 - (25 * (ClientPrefs.npsDisplay ? npsIdx + 1 : npsIdx));
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
	}

	override function update(elapsed:Float)
	{
		gradeTxt.text = grade;
		if (hudPosition == 'Right')gradeTxt.x = FlxG.width - gradeTxt.width - 20;

		ratingTxt.text = (grade != "?"?(Highscore.floorDecimal(ratingPercent * 100, 2) + "%"):"0%");
		fcTxt.text = (ratingFC=='GFC' && ClientPrefs.wife3)?"FC":ratingFC;
		
		if (ClientPrefs.npsDisplay)
			npsTxt.text = 'NPS: ${nps} (Peak: ${npsPeak})';

		if(peakCombo < combo)peakCombo = combo;
		pcTxt.text = "Peak Combo: " + Std.string(peakCombo);
		
		for(k in stats.judgements.keys()){
			if (judgeTexts.exists(k))
				judgeTexts.get(k).text = Std.string(stats.judgements.get(k));
		}
		super.update(elapsed);

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

	function statChanged(stat:String, val:Dynamic){
		switch(stat){
			case 'score':
				var displayedScore = Std.string(val);
				if (displayedScore.length > 7)
				{
					if (score < 0)
						displayedScore = '-999999';
					else
						displayedScore = '9999999';
				}

				scoreTxt.text = displayedScore;
				scoreTxt.color = !PlayState.instance.saveScore ? 0x818181 : ((songHighscore != 0 && score > songHighscore) ? 0xFFD800 : 0xFFFFFF);
			case 'grade':
				FlxTween.cancelTweensOf(gradeTxt.scale);
				gradeTxt.scale.set(1.2, 1.2);
				FlxTween.tween(gradeTxt.scale, {x: 1, y: 1}, 0.2, {ease: FlxEase.circOut});
			case 'misses':
				var judgeName = judgeNames.get('miss');
				var judgeTxt = judgeTexts.get('miss');
				if (ClientPrefs.scoreZoom)
				{
					if (judgeName != null)
					{
						FlxTween.cancelTweensOf(judgeName.scale);
						judgeName.scale.set(1.075, 1.075);
						FlxTween.tween(judgeName.scale, {x: 1, y: 1}, 0.2);
					}
				}
				if (judgeTxt != null)
				{
					if (ClientPrefs.scoreZoom)
					{
						FlxTween.cancelTweensOf(judgeTxt.scale);
						judgeTxt.scale.set(1.075, 1.075);
						FlxTween.tween(judgeTxt.scale, {x: 1, y: 1}, 0.2);
					}
					judgeTxt.text = Std.string(val);
				}
			case 'comboBreaks':
				var judgeName = judgeNames.get('cb');
				var judgeTxt = judgeTexts.get('cb');
				if (ClientPrefs.scoreZoom)
				{
					if (judgeName != null)
					{
						FlxTween.cancelTweensOf(judgeName.scale);
						judgeName.scale.set(1.075, 1.075);
						FlxTween.tween(judgeName.scale, {x: 1, y: 1}, 0.2);
					}
				}
				if (judgeTxt != null)
				{
					if (ClientPrefs.scoreZoom)
					{
						FlxTween.cancelTweensOf(judgeTxt.scale);
						judgeTxt.scale.set(1.075, 1.075);
						FlxTween.tween(judgeTxt.scale, {x: 1, y: 1}, 0.2);
					}
					judgeTxt.text = Std.string(val);
				}
			case 'ratingPercent':
				if (ClientPrefs.scoreZoom)
				{
					FlxTween.cancelTweensOf(ratingTxt.scale);
					ratingTxt.scale.set(1.075, 1.075);
					FlxTween.tween(ratingTxt.scale, {x: 1, y: 1}, 0.2);
				}
		}
	}
	
	override function noteJudged(judge:JudgmentData, ?note:Note, ?field:PlayField)
	{
		var hitTime = note.strumTime - Conductor.songPosition + ClientPrefs.ratingOffset;

		if (ClientPrefs.hitbar)
			hitbar.addHit(-hitTime);
		if (ClientPrefs.scoreZoom)
		{
			FlxTween.cancelTweensOf(scoreTxt.scale);
			scoreTxt.scale.set(1.075, 1.075);
			FlxTween.tween(scoreTxt.scale, {x: 1, y: 1}, 0.2);

			var judgeName = judgeNames.get(judge.internalName);
			var judgeTxt = judgeTexts.get(judge.internalName);
			if(judgeName!=null){
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

		}

		fcTxt.color = (function()
			{
				var color:FlxColor = 0xFFA3A3A3;
				if (comboBreaks == 0)
				{
					if (stats.judgements.get("bad") > 0 || stats.judgements.get("shit") > 0)
						color = 0xFFFFFFFF;
					else if (stats.judgements.get("good") > 0)
					{
						color = judgeColours.get("good");
						if (stats.judgements.get("good") == 1)
							color.saturation *= 0.75;
					}
					else if (stats.judgements.get("sick") > 0)
					{
						color = judgeColours.get("sick");
						if (stats.judgements.get("sick") == 1)
							color.saturation *= 0.75;
					}
					else if (stats.judgements.get("epic") > 0)
					{
						color = judgeColours.get("epic");
					}
				}
	
				if (ratingFC == 'Fail')
					color = judgeColours.get("miss");
	
				return color;
			})();
	}

	override public function beatHit(beat:Int)
	{
		if (hitbar != null)
			hitbar.beatHit();

		super.beatHit(beat);
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
		}
}