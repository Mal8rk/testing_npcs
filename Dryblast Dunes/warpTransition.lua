--[[

    warpTransition.lua
    by MrDoubleA

]]

local warpTransition = {} 
 

warpTransition.TRANSITION_NONE      = nil
warpTransition.TRANSITION_PAN       = 0
warpTransition.TRANSITION_FADE      = 1
warpTransition.TRANSITION_IRIS_OUT  = 2
warpTransition.TRANSITION_MOSAIC    = 3
warpTransition.TRANSITION_CROSSFADE = 4


warpTransition.currentTransitionType = nil
warpTransition.transitionTimer = 0

warpTransition.transitionIsFromLevelStart = false

local panCameraPosition -- Used for panning the camera

local RETURN_WARP_ADDR = 0x00B2C6D8

local customMusicPathsTbl = mem(0xB257B8, FIELD_DWORD)
local function getMusicPathForSection(section) -- thanks to Rednaxela#0380 on Discord for providing this function!
    return mem(customMusicPathsTbl + section*4, FIELD_STRING)
end

local function exitHasDifferentMusic(warp)
    if warpTransition.transitionIsFromLevelStart then return false end

    local entranceMusic = Section(warp.entranceSection).musicID
    local exitMusic     = Section(warp.exitSection).musicID

    return (warp.levelFilename ~= "") or (warp:mem(0x84,FIELD_BOOL)) or (entranceMusic ~= exitMusic) or (entranceMusic == 24 and exitMusic == 24 and getMusicPathForSection(warp.entranceSection) ~= getMusicPathForSection(warp.exitSection))
end

local function doorTransitionEffects()
    local currentWarp = Warp(player:mem(0x15E,FIELD_WORD)-1)

    if currentWarp.warpType == 2 then
        player.frame = 1
        SFX.play(46)
    end
end

local function exitLevelLogic() -- Exit the level if the warp is set to do so
    local currentWarp = Warp(player:mem(0x15E,FIELD_WORD)-1)

    if currentWarp.levelFilename ~= "" then
        Level.load(currentWarp.levelFilename,nil,currentWarp.warpNumber)
        mem(RETURN_WARP_ADDR,player:mem(0x15E,FIELD_WORD))
    elseif currentWarp:mem(0x84,FIELD_BOOL) then
        Level.exit()
    end
end


local irisOutShader = Shader()
irisOutShader:compileFromFile(nil,Misc.resolveFile("warpTransition_irisOut.frag"))
local mosaicShader = Shader()
mosaicShader:compileFromFile(nil,Misc.multiResolveFile("fuzzy_pixel.frag","shaders/npc/fuzzy_pixel.frag"))

local buffer = Graphics.CaptureBuffer(800,600)

function warpTransition.applyShader(priority,shader,uniforms)
    buffer:captureAt(priority or 0)
    Graphics.drawScreen{texture = buffer,priority = priority or 0,shader = shader,uniforms = uniforms}
end


function warpTransition.onInitAPI()
    registerEvent(warpTransition,"onStart")

    registerEvent(warpTransition,"onTick")
    registerEvent(warpTransition,"onCameraDraw")

    registerEvent(warpTransition,"onCameraUpdate")
end

function warpTransition.onStart()
    if warpTransition.levelStartTransition ~= warpTransition.TRANSITION_NONE then
        warpTransition.currentTransitionType = warpTransition.levelStartTransition
        warpTransition.transitionTimer = 0

        warpTransition.transitionIsFromLevelStart = true

        -- Prevent the long wait when starting from a warp
        local currentWarp = Warp(player:mem(0x15E,FIELD_WORD)-1)
        if currentWarp and currentWarp.isValid then
            if currentWarp.warpType == 1 then -- Pipes
                player.forcedState = 3
                player.forcedTimer = 1
            else -- Doors
                player.forcedState = 0
                player.forcedTimer = 0
            end
        end
    end

    -- Music volume doesn't reset when restarting a level, so here's a fix
    if Audio.MusicVolume() == 0 then
        Audio.MusicVolume(64)
    end
end

function warpTransition.onTick()
    local currentWarp = Warp(player:mem(0x15E,FIELD_WORD)-1)

    if warpTransition.currentTransitionType == warpTransition.TRANSITION_NONE and (player.forcedState == 3 and player.forcedTimer == 1 or player.forcedState == 7 and player.forcedTimer == 29) then
        if currentWarp.entranceSection == currentWarp.exitSection and currentWarp.levelFilename == "" and not currentWarp:mem(0x84,FIELD_BOOL) then
            warpTransition.currentTransitionType = warpTransition.sameSectionTransition
        else
            warpTransition.currentTransitionType = warpTransition.crossSectionTransition
        end

        if warpTransition.currentTransitionType ~= warpTransition.TRANSITION_NONE then
            warpTransition.transitionTimer = 0
            Misc.pause()
        end
    end
end

function warpTransition.onCameraDraw(camIdx)
    -- Transition effects
    local currentWarp = Warp(player:mem(0x15E,FIELD_WORD)-1)

    local middle = 0 -- Middle point for the transition

    if warpTransition.currentTransitionType == warpTransition.TRANSITION_FADE then
        warpTransition.transitionTimer = warpTransition.transitionTimer + 1

        local opacity = (warpTransition.transitionTimer/warpTransition.transitionSpeeds[warpTransition.currentTransitionType])
        middle = math.floor(warpTransition.transitionSpeeds[warpTransition.currentTransitionType]*1.35)

        if warpTransition.transitionIsFromLevelStart then
            middle = 0
        end


        if warpTransition.transitionTimer == middle-1 and not warpTransition.transitionIsFromLevelStart then
            exitLevelLogic()
            Misc.unpause()
        elseif warpTransition.transitionTimer == middle+1 and not warpTransition.transitionIsFromLevelStart then
            doorTransitionEffects()
            Misc.pause(true)
        elseif warpTransition.transitionTimer > middle then
            opacity = 1.35-((warpTransition.transitionTimer-middle)/warpTransition.transitionSpeeds[warpTransition.currentTransitionType])

            if opacity <= 0 then
                warpTransition.currentTransitionType = warpTransition.TRANSITION_NONE
                warpTransition.transitionTimer = 0

                Misc.unpause()
            end
        end

        Graphics.drawScreen{color = Color.black.. opacity,priority = 0}
    elseif warpTransition.currentTransitionType == warpTransition.TRANSITION_PAN then
        if panCameraPosition == nil then -- If the camera position isn't set
            panCameraPosition = vector(camera.x,camera.y)
        end

        local offset = vector((currentWarp.exitWidth/2),currentWarp.exitHeight)

        if currentWarp.warpType == 1 then -- Pipes
            if currentWarp.exitDirection == 1 then -- Down
                offset = vector((currentWarp.exitWidth/2),-8)
            elseif currentWarp.exitDirection == 2 then -- Right
                offset = vector((-player.width/2)-8,currentWarp.exitHeight)
            elseif currentWarp.exitDirection == 3 then -- Up
                offset = vector((currentWarp.exitWidth/2),currentWarp.exitHeight+8+player.height)
            elseif currentWarp.exitDirection == 4 then -- Left
                offset = vector(currentWarp.exitWidth+(player.width/2)+8,currentWarp.exitHeight)
            end
        end

        local targetPosition = vector(
            math.clamp(currentWarp.exitX+offset.x-(camera.width /2),player.sectionObj.boundary.left,player.sectionObj.boundary.right -camera.width ),
            math.clamp(currentWarp.exitY+offset.y-(camera.height/2),player.sectionObj.boundary.top ,player.sectionObj.boundary.bottom-camera.height)
        )

        local distance = vector(targetPosition.x-panCameraPosition.x,targetPosition.y-panCameraPosition.y)
        local speed = distance:normalise()*math.min(distance.length,warpTransition.transitionSpeeds[warpTransition.currentTransitionType])

        for i=1,2 do
            panCameraPosition[i] = panCameraPosition[i] + speed[i]
        end

        if panCameraPosition.x == targetPosition.x and panCameraPosition.y == targetPosition.y then -- The camera is in the right position
            warpTransition.currentTransitionType = warpTransition.TRANSITION_NONE
            warpTransition.transitionTimer = 0
            
            Misc.unpause()
        end
    elseif warpTransition.currentTransitionType == warpTransition.TRANSITION_IRIS_OUT then
        warpTransition.transitionTimer = warpTransition.transitionTimer + 1

        local startRadius = math.max(camera.width,camera.height)

        local radius = math.max(0,startRadius-(warpTransition.transitionTimer*warpTransition.transitionSpeeds[warpTransition.currentTransitionType]))
        middle = math.floor((startRadius+256)/warpTransition.transitionSpeeds[warpTransition.currentTransitionType])

        if warpTransition.transitionIsFromLevelStart then
            middle = 0
        end
        

        if warpTransition.transitionTimer == middle-1 and not warpTransition.transitionIsFromLevelStart then
            exitLevelLogic()
            Misc.unpause()
        elseif warpTransition.transitionTimer == middle+1 and not warpTransition.transitionIsFromLevelStart then
            doorTransitionEffects()
            Misc.pause(true)
        elseif warpTransition.transitionTimer > middle then
            radius = (warpTransition.transitionTimer-middle)*warpTransition.transitionSpeeds[warpTransition.currentTransitionType]

            if radius > startRadius then
                warpTransition.currentTransitionType = warpTransition.TRANSITION_NONE
                warpTransition.transitionTimer = 0

                Misc.unpause()
            end
        end

        warpTransition.applyShader(6,irisOutShader,{center = vector(player.x+(player.width/2)-camera.x,player.y+(player.height/2)-camera.y),radius = radius})
    elseif warpTransition.currentTransitionType == warpTransition.TRANSITION_MOSAIC then
        warpTransition.transitionTimer = warpTransition.transitionTimer + 1

        local opacity = (warpTransition.transitionTimer/warpTransition.transitionSpeeds[warpTransition.currentTransitionType])
        local mosaic = (warpTransition.transitionTimer/(warpTransition.transitionSpeeds[warpTransition.currentTransitionType]/64))

        middle = math.floor(warpTransition.transitionSpeeds[warpTransition.currentTransitionType]*1.35)

        if warpTransition.transitionIsFromLevelStart then
            middle = 0
        end


        if warpTransition.transitionTimer == middle-1 and not warpTransition.transitionIsFromLevelStart then
            exitLevelLogic()
            Misc.unpause()
        elseif warpTransition.transitionTimer == middle+1 and not warpTransition.transitionIsFromLevelStart then
            Misc.pause(true)
        elseif warpTransition.transitionTimer > middle then
            opacity = 1.35-((warpTransition.transitionTimer-middle)/warpTransition.transitionSpeeds[warpTransition.currentTransitionType])
            mosaic = (math.floor(warpTransition.transitionSpeeds[warpTransition.currentTransitionType]*1.35)/(warpTransition.transitionSpeeds[warpTransition.currentTransitionType]/64))-((warpTransition.transitionTimer-middle)/(warpTransition.transitionSpeeds[warpTransition.currentTransitionType]/64))

            if opacity <= 0 then
                warpTransition.currentTransitionType = warpTransition.TRANSITION_NONE
                warpTransition.transitionTimer = 0

                Misc.unpause()
            end
        end

        Graphics.drawScreen{color = Color.black.. opacity,priority = 6}
        warpTransition.applyShader(6,mosaicShader,{pxSize = {camera.width/math.max(1,mosaic),camera.height/math.max(1,mosaic)}})
    elseif warpTransition.currentTransitionType == warpTransition.TRANSITION_CROSSFADE then
        warpTransition.transitionTimer = warpTransition.transitionTimer + 1

        -- If the transition just started
        if warpTransition.transitionTimer == 1 then
            exitLevelLogic()
            Misc.unpause()

            buffer:captureAt(0)
        end

        local opacity = 1-(warpTransition.transitionTimer/warpTransition.transitionSpeeds[warpTransition.currentTransitionType])

        if opacity <= 0 then
            warpTransition.currentTransitionType = warpTransition.TRANSITION_NONE
            warpTransition.transitionTimer = 0
        end

        Graphics.drawScreen{texture = buffer,color = Color.white.. opacity,priority = 0}
    else
        warpTransition.transitionIsFromLevelStart = false
    end

    if warpTransition.currentTransitionType ~= warpTransition.TRANSITION_NONE then
        if warpTransition.transitionIsFromLevelStart and not Misc.isPaused() and lunatime.tick() > 1 then
            Misc.pause(true)
        end

        if warpTransition.currentTransitionType ~= warpTransition.TRANSITION_CROSSFADE and warpTransition.musicFadeOut and exitHasDifferentMusic(currentWarp) then
            -- Music fade out
            if player.section == currentWarp.entranceSection then
                Audio.MusicVolume(math.max(0,Audio.MusicVolume()-math.ceil(64/(middle-12))))
            elseif Audio.MusicVolume() == 0 then
                Audio.MusicVolume(64)
            end
        end
    end
end

function warpTransition.onCameraUpdate()
    if panCameraPosition then
        camera.x,camera.y = panCameraPosition.x,panCameraPosition.y

        if warpTransition.currentTransitionType ~= warpTransition.TRANSITION_PAN then -- If the transition is finished
            panCameraPosition = nil
            panCameraTarget = nil
            panCameraHasUsedRedirectors = false
        end
    end
end


-- The type of transition used when using a warp that leads to somewhere else in the same section. Can be 'warpTransition.TRANSITION_NONE', 'warpTransition.TRANSITION_FADE', 'warpTransition.TRANSITION_PAN', 'warpTransition.TRANSITION_IRIS_OUT', 'warpTransition.TRANSITION_MOSAIC' or 'warpTransition.TRANSITION_CROSSFADE'.
warpTransition.sameSectionTransition = warpTransition.TRANSITION_PAN
-- The type of transition used when using a warp that leads to a different section. Can be 'warpTransition.TRANSITION_NONE', 'warpTransition.TRANSITION_FADE', 'warpTransition.TRANSITION_IRIS_OUT', 'warpTransition.TRANSITION_MOSAIC' or 'warpTransition.TRANSITION_CROSSFADE'.
warpTransition.crossSectionTransition = warpTransition.TRANSITION_MOSAIC

-- The type of transition used when entering the level. Can be 'warpTransition.TRANSITION_NONE', 'warpTransition.TRANSITION_FADE', 'warpTransition.TRANSITION_IRIS_OUT' or 'warpTransition.TRANSITION_MOSAIC'.
warpTransition.levelStartTransition = warpTransition.TRANSITION_MOSAIC

warpTransition.transitionSpeeds = {
    [warpTransition.TRANSITION_FADE     ] = 24, -- How long it takes to fade in/out.
    [warpTransition.TRANSITION_PAN      ] = 12, -- How fast the camera pan is.
    [warpTransition.TRANSITION_IRIS_OUT ] = 14, -- How quickly the radius of the iris out shrinks.
    [warpTransition.TRANSITION_MOSAIC   ] = 24, -- How long it takes to fade in/out.
    [warpTransition.TRANSITION_CROSSFADE] = 24, -- How long it takes to fade in/out.
}

-- Whether or not the music will fade out when travelling between sections with different music.
warpTransition.musicFadeOut = true

return warpTransition