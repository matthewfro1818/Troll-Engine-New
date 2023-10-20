
local xx = 640;
local yy = 0;

local xx2 = 640;
local yy2 = 290;

local ofs = 0;

local followchars = true;
local del = 0;
local del2 = 0;
local zoomshit = 0;

local bfx = 441;
local bfy = 375;

local dadx = 200;
local dady = 77;

local zoomshit = 0;
local zoomshit2 = 0;
local zoomshit3 = 0;

local angleshit = 1;
local anglevar = 1;

local camLOL = 0;

local dadZoom = 0.66;
local bfZoom = 1;

function onCreate()


	-- background shit

	
	makeLuaSprite('bg', 'fatality/bg', -4522, -1434);
	setLuaSpriteScrollFactor('bg', 0, 1);

	makeLuaSprite('build2', 'fatality/build2', -4447, 570);
	setLuaSpriteScrollFactor('build2', 0.8, 0.3);

	makeLuaSprite('build' ,'fatality/build', -4478, -401);
	setLuaSpriteScrollFactor('build', 0.3, 0.3);



	makeLuaSprite('floor', 'fatality/floor', -901, 481);
	setLuaSpriteScrollFactor('floor', 0.6, 0.6);
                setProperty('floor.visible',false);

	makeLuaSprite('error' ,'fatality/error', -68, -257);
	setLuaSpriteScrollFactor('error', 0.3, 0.3);
                setProperty('error.visible',false);

	makeLuaSprite('error2' ,'fatality/error2', -242, -578);
	setLuaSpriteScrollFactor('error2', 1.3, 1.3);
                setProperty('error2.visible',false);


	makeLuaSprite('bsod', 'fatality/BSOD', 0, 1);
	setLuaSpriteScrollFactor('bsod', 0, 0);
                setProperty('bsod.visible',false);

	makeLuaSprite('rsod', 'fatality/RSOD', 0, 1);
	setLuaSpriteScrollFactor('rsod', 0, 0);
                setProperty('rsod.visible',false);
	setProperty('rsod.scale.x',3.2)
	setProperty('rsod.scale.y',3.2)

	makeLuaSprite('red', 'fatality/red', 0, 1);
	setLuaSpriteScrollFactor('red', 0, 0);
                setProperty('red.visible',false);
	setProperty('red.scale.x',4)
	setProperty('red.scale.y',4)

	makeLuaSprite('black', 'fatality/black', 0, 0);
	setLuaSpriteScrollFactor('black', 0, 0);
                setProperty('black.visible',false);

                makeAnimatedLuaSprite('grab', 'fatality/grab', -384, -721);
                addAnimationByPrefix('grab', 'grab', 'grab', 24, true);
                objectPlayAnimation('grab', 'grab', true);
	setLuaSpriteScrollFactor('grab', 1, 1);
                setProperty('grab.visible',false);

	addLuaSprite('red', false);
	addLuaSprite('bg', false);
	addLuaSprite('build2', false);
	addLuaSprite('build', false);

	addLuaSprite('bsod', false);
	addLuaSprite('rsod', false);

	addLuaSprite('black', true);
	setObjectCamera('black','hud');

	addLuaSprite('floor', false);
	addLuaSprite('error', false);
	addLuaSprite('error2', true);

	addLuaSprite('grab', true);




end




function onUpdate(elapsed)

    if followchars == true then
        if mustHitSection == false then
            setProperty('defaultCamZoom',dadZoom)


        doTweenX('TweenX', 'bsod.scale', 1.63, 1, 'elasticOut')
        doTweenY('TweenY', 'bsod.scale', 1.63, 1, 'elasticOut')

            if getProperty('dad.animation.curAnim.name') == 'singLEFT' then
                triggerEvent('Camera Follow Pos',xx-ofs,yy)
            end
            if getProperty('dad.animation.curAnim.name') == 'singRIGHT' then
                triggerEvent('Camera Follow Pos',xx+ofs,yy)
            end
            if getProperty('dad.animation.curAnim.name') == 'singUP' then
                triggerEvent('Camera Follow Pos',xx,yy-ofs)
            end
            if getProperty('dad.animation.curAnim.name') == 'singDOWN' then
                triggerEvent('Camera Follow Pos',xx,yy+ofs)
            end
            if getProperty('dad.animation.curAnim.name') == 'singLEFT-alt' then
                triggerEvent('Camera Follow Pos',xx-ofs,yy)
            end
            if getProperty('dad.animation.curAnim.name') == 'singRIGHT-alt' then
                triggerEvent('Camera Follow Pos',xx+ofs,yy)
            end
            if getProperty('dad.animation.curAnim.name') == 'singUP-alt' then
                triggerEvent('Camera Follow Pos',xx,yy-ofs)
            end
            if getProperty('dad.animation.curAnim.name') == 'singDOWN-alt' then
                triggerEvent('Camera Follow Pos',xx,yy+ofs)
            end
            if getProperty('dad.animation.curAnim.name') == 'idle-alt' then
                triggerEvent('Camera Follow Pos',xx,yy)
            end
            if getProperty('dad.animation.curAnim.name') == 'idle' then
                triggerEvent('Camera Follow Pos',xx,yy)
            end
        else

            setProperty('defaultCamZoom',bfZoom)

        doTweenX('TweenX', 'bsod.scale', 1, 1, 'quadOut')
        doTweenY('TweenY', 'bsod.scale', 1, 1, 'quadOut')

            if getProperty('boyfriend.animation.curAnim.name') == 'singLEFT' then
                triggerEvent('Camera Follow Pos',xx2-ofs,yy2)
            end
            if getProperty('boyfriend.animation.curAnim.name') == 'singRIGHT' then
                triggerEvent('Camera Follow Pos',xx2+ofs,yy2)
            end
            if getProperty('boyfriend.animation.curAnim.name') == 'singUP' then
                triggerEvent('Camera Follow Pos',xx2,yy2-ofs)
            end
            if getProperty('boyfriend.animation.curAnim.name') == 'singDOWN' then
                triggerEvent('Camera Follow Pos',xx2,yy2+ofs)
            end
            if getProperty('boyfriend.animation.curAnim.name') == 'idle-alt' then
                triggerEvent('Camera Follow Pos',xx2,yy2)
            end
            if getProperty('boyfriend.animation.curAnim.name') == 'idle' then
                triggerEvent('Camera Follow Pos',xx2,yy2)
            end
        end
    else
        triggerEvent('Camera Follow Pos','','')
    end


	zoomshit = (getProperty('camGame.zoom')/1.5);
	--setCharacterX('boyfriend',bfx*zoomshit)
	--setCharacterY('boyfriend',bfy*zoomshit)
	setProperty('boyfriend.scale.x',zoomshit)
	setProperty('boyfriend.scale.y',zoomshit)

	zoomshit2 = (getProperty('camGame.zoom')/0.4);
	setProperty('error2.scale.x',zoomshit2)
	setProperty('error2.scale.y',zoomshit2)


                --zoomshit3 = (getProperty('camGame.zoom')/camLOL);
	--setProperty('bsod.scale.x',zoomshit3)
	--setProperty('bsod.scale.y',zoomshit3)




end


function onBeatHit()

               --and then the beat dropped... we were doing the WHIP... the NAE NAE...


    if curBeat == 64 then
        setProperty('floor.visible',true);
        setProperty('error.visible',true);

        setProperty('build.visible',false);
        setProperty('build2.visible',false);    
end

    if curBeat == 288 then
        setProperty('bg.visible',false);
        setProperty('error.visible',false);
        setProperty('floor.visible',false);
        setProperty('build.visible',false);
        setProperty('build2.visible',false);
        setProperty('bsod.visible',true);
end

    if curBeat == 432 then
        setProperty('bg.visible',true);
        setProperty('error.visible',true);
        setProperty('build.visible',true);
        setProperty('build2.visible',true);    
        setProperty('error2.visible',true);
        setProperty('bsod.visible',false);

end

    if curBeat == 496 then

        setCharacterX('dad', -60);
        setCharacterY('dad', -1000);

        dadZoom = 0.3;
        yy = -1000;


end

    if curBeat == 560 then
        setProperty('bg.visible',false);
        setProperty('error.visible',false);
        setProperty('build.visible',false);
        setProperty('build2.visible',false);    
        setProperty('error2.visible',false);
        setProperty('red.visible',true);
        setProperty('rsod.visible',true);

        setProperty('grab.visible',true);
        setCharacterX('dad', -60);
        setCharacterY('dad', -1000);
        setCharacterY('boyfriend', -900);
        yy2 = -1000;
        yy = -1000;
        dadZoom = 0.3;
        bfZoom = 0.3;

end

end


function onStepHit()

    if curStep == 256 then 
        setProperty('black.visible',true);
end

    if curStep == 258 then 
        setProperty('black.visible',false);
end


    if curStep == 1152 then 
        setProperty('black.visible',true);
end

    if curStep == 1154 then 
        setProperty('black.visible',false);
end


    if curStep == 1728 then 
        setProperty('black.visible',true);
end

    if curStep == 1730 then 
        setProperty('black.visible',false);
end

    if curStep == 1984 then 
        setProperty('black.visible',true);
end

    if curStep == 1986 then 
        setProperty('black.visible',false);
end


    if curStep == 2240 then 
        setProperty('black.visible',true);
end

    if curStep == 2242 then 
        setProperty('black.visible',false);
end

end