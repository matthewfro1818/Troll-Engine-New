function onCreate()
    makeLuaSprite('sky', 'neshill/sky', -400, -400);
    scaleObject('sky', 11.0, 11.0);
    addLuaSprite('sky', false)

    makeAnimatedLuaSprite('tlbg2', 'neshill/tlbg2', -550, -300);
    addAnimationByPrefix('tlbg2', 'Idle', 'tlbg2', 12, true);
    objectPlayAnimation('tlbg2','Idle',true)
    scaleObject('tlbg2', 11.0, 11.0);
    addLuaSprite('tlbg2', false)

    makeLuaSprite('border', 'neshill/border', 0, 0);
    scaleObject('border', 7.32, 5.48);
    setObjectCamera('border', 'stageunderlay')
    addLuaSprite('border', true)

    makeAnimatedLuaSprite('static', 'neshill/SMMStatic', -550, -300);
    addAnimationByPrefix('static', 'Idle', 'damfstatic', 24, true);
    objectPlayAnimation('static','Idle',true)
    setProperty('static.visible', false)
    scaleObject('static', 3.0, 3.0);
    addLuaSprite('static', false)

    makeAnimatedLuaSprite('static2', 'neshill/daSTAT', -500, -300);
    addAnimationByPrefix('static2', 'Idle', 'staticFLASH', 24, true);
    setProperty('static2.visible', false)
    objectPlayAnimation('static2','Idle',true)
    scaleObject('static2', 6.0, 6.0);
    addLuaSprite('static2', true)

    setProperty('sky.antialiasing', false)
    setProperty('tlbg2.antialiasing', false)
    setProperty('border.antialiasing', false)

end

 function onCreatePost()

        --setProperty('showRating', false);
        --setProperty('showComboNum', false);

end

function onUpdatePost(elapsed)
    --[[setProperty('healthBar.flipX',true)
    setProperty('healthBar.x',75)
    setProperty('timeBar.x',775)
    setProperty('healthBar.y', 700)
    setProperty('timeTxt.x',775)
    setProperty('iconP1.x', 25)
    setProperty('scoreTxt.y', 0)
    setProperty('scoreTxt.color', getColorFromHex('ff0000'))
    setProperty('timeBar.color', getColorFromHex('0000ff'))
    setProperty('iconP1.flipX',true)
    setProperty('iconP1.y', 610)
    setProperty('iconP2.visible', false)
    for i=0,3 do
        setPropertyFromGroup('opponentStrums', i, 'alpha', 0)
        setPropertyFromGroup('opponentStrums', i, 'x', -9999)
    end]]--
	if curStep == 568 then
        setProperty('static2.visible', true)
        end 
   	if curStep == 576 then
        setProperty('static2.visible', false)
        end 

	if curStep == 2536 then
        setProperty('static2.visible', true)
        end 
   	if curStep == 2544 then
        setProperty('static2.visible', false)
        end 

	if curStep == 3081 then
        setProperty('static2.visible', true)
        end 
	if curStep == 3083 then
        setProperty('static2.visible', false)
        end 
	if curStep == 3086 then
        setProperty('static2.visible', true)
        end 

	if curStep == 3088 then
        setProperty('static2.visible', false)
        end 
	if curStep == 3336 then
        setProperty('static2.visible', true)
        end 

	if curStep == 3344 then
        setProperty('static2.visible', false)
        end 

	if curStep == 4136 then
        setProperty('static2.visible', true)
	end

	if curStep == 4144 then
        setProperty('static2.visible', false)   
        end 
	if curStep == 5544 then
        setProperty('static2.visible', true)
	end
            if curStep == 2161 then
                setProperty('static2.visible', false)
                setProperty('static.visible', true)
                setProperty('dad.visible', true)
            end
                if curStep == 3344 then
                    setProperty('static2.visible', false)
                    setProperty('static.visible', false)
                    setProperty('gf.visible', false)
                    setProperty('dad.visible', true)
                end
	   if curStep == 4796 then
                setProperty('static2.visible', false)
                setProperty('static.visible', true)
		setProperty('gf.visible', true)
                setProperty('dad.visible', true)
            end
end