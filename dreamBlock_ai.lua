--[[

    Celeste Madeline Playable
    by MrDoubleA

	See madeline.lua for more

]]

local blockManager = require("blockManager")
local blockutils = require("blocks/blockutils")

local playerManager = require("playerManager")

local distortionEffects = require("distortionEffects")

local madeline


local dreamBlock = {}


dreamBlock.playerData = {}


dreamBlock.idList = {}
dreamBlock.idMap  = {}


local drewBlock = false


function dreamBlock.register(blockID)
    blockManager.registerEvent(blockID,dreamBlock,"onCameraDrawBlock")

    table.insert(dreamBlock.idList,blockID)
    dreamBlock.idMap[blockID] = true
end


local STATE = {
    INACTIVE = 0,
    ACTIVE   = 1,
}
dreamBlock.STATE = STATE


local function canDreamDash(p,data)
    return (
        (data.state ~= STATE.ACTIVE and p.forcedState == FORCEDSTATE_NONE or data.state == STATE.ACTIVE and p.forcedState == FORCEDSTATE_SWALLOWED)
        and p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL)
    )
end

local function canStartDreamDash(p,data)
    if player.character == CHARACTER_MADELINE then
        if madeline.playerData.dashTimer == 0 or madeline.playerData.dashDirection == vector.zero2 then
            return false
        end
    end

    return canDreamDash(p,data)
end

local function getDashDirection(p,block)
    if p.character == CHARACTER_MADELINE then
        return madeline.playerData.dashDirection
    else
        -- Block's bottom
        if (p.y - p.speedY + 4) >= (block.y + block.height - block.speedY) then
            return vector(0,-1)
        end

        -- Block's top
        if (p.y + p.height - p.speedY - 4) <= (block.y - block.speedY) then
            return vector(0,1)
        end

        -- Block's right
        if (p.x - p.speedX + 4) >= (block.x + block.width - block.speedX) then
            return vector(-1,0)
        end

        -- Block's left
        if (p.x + p.width - p.speedX - 4) <= (block.x - block.speedX) then
            return vector(1,0)
        end
    end

    return vector.zero2
end


local function unduckPlayer(p)
    if p:mem(0x12E,FIELD_BOOL) then
        local settings = PlayerSettings.get(playerManager.getBaseID(p.character),p.powerup)

        p.y = p.y+p.height-settings.hitboxHeight
        p.height = settings.hitboxHeight

        p:mem(0x12E,FIELD_BOOL,false)
        p:mem(0x132,FIELD_BOOL,true)
        p:mem(0x134,FIELD_BOOL,true)
    end
end

local function stopTravelSounds(data)
    for i=1,2 do
        if data.travelSounds[i] ~= nil then
            data.travelSounds[i]:stop()
        end

        data.travelSounds[i] = nil
    end
end

local function hittableBlockFilter(v)
    return (
        madeline.solidBlockFilter(v)
        and not dreamBlock.idMap[v.id]
    )
end
local function hittableNPCFilter(v)
    return (
        madeline.solidNPCFilter(v)
        and (v:mem(0x130,FIELD_WORD) ~= player.idx or v:mem(0x12E,FIELD_WORD) == 0)
    )
end
local function hittableBlocksHere(col)
    return (
           #Colliders.getColliding{a = col,btype = Colliders.BLOCK,filter = hittableBlockFilter} > 0
        or #Colliders.getColliding{a = col,btype = Colliders.NPC  ,filter = hittableNPCFilter  } > 0
    )
end



local function resetState(p,data)
    data.state = STATE.INACTIVE
    data.timer = 0
    data.direction = nil

    data.block = nil

    data.afterExitJumpTimeLeft = 0
    data.beforeExitJumpTimeLeft = 0

    data.forceDuck = false


    data.travelSounds = data.travelSounds or {}
    data.travelSoundVolume = data.travelSoundVolume or 0
end


function dreamBlock.onTickPlayer(p)
    local data = dreamBlock.playerData

    if data.state == nil or not canDreamDash(p,data) then
        if data.state == STATE.ACTIVE and p.forcedState == FORCEDSTATE_SWALLOWED then
            p.forcedState = FORCEDSTATE_NONE
            p.forcedTimer = 0
            p:mem(0xBA,FIELD_WORD,0)
        end

        resetState(p,data)
    end


    if data.state == STATE.ACTIVE then
        local speed = data.direction*dreamBlock.playerSpeed

        p.speedX = speed.x
        p.speedY = speed.y

        p.x = p.x + p.speedX
        p.y = p.y + p.speedY

        if data.block ~= nil and data.block.isValid then
            p.x = p.x + data.block.speedX
            p.y = p.y + data.block.speedY
        end


        data.timer = data.timer + 1
        if data.timer%6 == 0 then
            distortionEffects.create{
                x = p.x+(p.width/2),y = p.y+(p.height/2),
                texture = distortionEffects.textures.circle,
                scaleGrowth = 0.1,
                strengthFade = 4,
            }
        end

        -- Attempt to exit the dream block if no longer in the current one. If a new one is found, move through it instead.
        local col = Colliders.getHitbox(p)

        col.width = col.width + math.abs(p.speedX)
        col.height = col.height + math.abs(p.speedY)
        col.x = col.x + math.min(0,p.speedX)
        col.y = col.y + math.min(0,p.speedY)

        if not data.block.isValid or not blockutils.hiddenFilter(data.block) or not col:collide(data.block) then
            local newBlocks = Colliders.getColliding{a = col,b = dreamBlock.idList,btype = Colliders.BLOCK}

            if #newBlocks == 0 then
                p.forcedState = FORCEDSTATE_NONE
                p.forcedTimer = 0
                p:mem(0xBA,FIELD_WORD,0)
                
                data.state = STATE.INACTIVE
                data.block = nil

                SFX.play(RNG.irandomEntry(dreamBlock.exitSounds),0.5)


                if p.character == CHARACTER_MADELINE then
                    madeline.refillDashes()
                    p.keys.down = data.forceDuck

                    madeline.increaseMaxSpeed(math.abs(p.speedX))
                end

                if data.direction.x ~= 0 then
                    data.afterExitJumpTimeLeft = dreamBlock.afterExitJumpTime
                end

                p:mem(0x11E,FIELD_BOOL,false)
            else
                data.block = newBlocks[1]
            end
        end

        -- Die by hitting a wall
        local col = Colliders.getSpeedHitbox(p)

        if data.block ~= nil and hittableBlocksHere(col) then
            p:kill()

            stopTravelSounds(data)
            data.travelSoundVolume = 0

            resetState(p,data)
        end

        -- Let you press the jump button a few frames before exiting and still jump
        if p.keys.jump == KEYS_PRESSED and data.direction.x ~= 0 then
            data.beforeExitJumpTimeLeft = dreamBlock.beforeExitJumpTime
        else
            data.beforeExitJumpTimeLeft = math.max(0,data.beforeExitJumpTimeLeft - 1)
        end


        --Graphics.drawBox{x = p.x,y = p.y,width = p.width,height = p.height,sceneCoords = true,priority = 5}
    elseif data.state == STATE.INACTIVE then
        -- Jumping out
        if p:isOnGround() or (p.speedX*p.direction) < 1 or (p:mem(0x148,FIELD_WORD) > 0 or p:mem(0x14C,FIELD_WORD) > 0) then
            data.afterExitJumpTimeLeft = 0
            data.beforeExitJumpTimeLeft = 0
        end


        if (data.afterExitJumpTimeLeft > 0 and p.keys.jump == KEYS_PRESSED) or (data.beforeExitJumpTimeLeft > 0) then
            p:mem(0x11C,FIELD_WORD,Defines.jumpheight*0.25)
            SFX.play(1)

            if player.character == CHARACTER_MADELINE then
                madeline.increaseMaxSpeed(10,nil,false)
            end
            
            p.speedX = Defines.player_runspeed*math.sign(p.speedX)
        end

        data.afterExitJumpTimeLeft = math.max(0,data.afterExitJumpTimeLeft - 1)
        data.beforeExitJumpTimeLeft = 0


        -- Force duck
        if data.forceDuck then
            local settings = PlayerSettings.get(playerManager.getBaseID(p.character),p.powerup)
            local col = Colliders.getHitbox(p)

            col.y = col.y+col.height-settings.hitboxHeight
            col.height = settings.hitboxHeight


            local blocks = Colliders.getColliding{a = col,btype = Colliders.BLOCK,filter = madeline.solidBlockFilter}
            local npcs   = Colliders.getColliding{a = col,btype = Colliders.NPC  ,filter = madeline.solidNPCFilter  }

            if #blocks == 0 and #npcs == 0 then
                data.forceDuck = false
            else
                p.keys.down = true
            end
        end


        -- Find blocks to enter
        if canStartDreamDash(p,data) then
            local col = Colliders.getSpeedHitbox(p)

            if p.character == CHARACTER_MADELINE then
                col.x = col.x + madeline.playerData.dashDirection.x
                col.y = col.y + madeline.playerData.dashDirection.y
            end
            
            local block = Colliders.getColliding{a = col,b = dreamBlock.idList,btype = Colliders.BLOCK}[1]

            if block ~= nil and not hittableBlocksHere(col) then
                local direction = getDashDirection(p,block)

                if direction.x ~= 0 or direction.y ~= 0 then
                    p.forcedState = FORCEDSTATE_SWALLOWED
                    p.forcedTimer = p.idx
                    p:mem(0xBA,FIELD_WORD,p.idx)

                    data.direction = direction

                    data.state = STATE.ACTIVE
                    data.block = block

                    p:mem(0x154,FIELD_WORD,0)

                    data.forceDuck = p:mem(0x12E,FIELD_BOOL)
                    unduckPlayer(p)

                    SFX.play(RNG.irandomEntry(dreamBlock.enterSounds),0.75)
                    stopTravelSounds(data)
                end
            end
        end
    end
end


local solidColorShader = Shader()
solidColorShader:compileFromFile(nil,Misc.resolveFile("madeline/solidColor.frag"))

local playerSprite

function dreamBlock.onDrawPlayer(p)
    local data = dreamBlock.playerData

    
    -- Draw the player thing
    if data.state == STATE.ACTIVE then
        local color = madeline.dashSettings.afterimageColors[0]
        if p.character == CHARACTER_MADELINE then
            color = madeline.playerData.dashAfterimageColor
        end

        p:render{
            color = Color.white.. 0.35,priority = -3.99,
            ignorestate = true,
            shader = solidColorShader,uniforms = {
                color = color,extremity = 1,
            }
        }

        -- Weird triangle thing
        playerSprite = playerSprite or Sprite{texture = dreamBlock.playerImage,frames = dreamBlock.playerFrames,pivot = Sprite.align.CENTRE}

        local frame = (math.floor(data.timer/dreamBlock.playerFramespeed)%dreamBlock.playerFrames)

        playerSprite.x = p.x+(p.width /2)
        playerSprite.y = p.y+(p.height/2)

        playerSprite.rotation = math.deg(math.atan2(data.direction.y,data.direction.x))+90

        playerSprite:draw{frame = frame+1,priority = -3.99,sceneCoords = true}
    end

    -- Travel sounds
    if data.travelSoundVolume > 0 then
        if data.travelSounds[1] == nil then
            data.travelSounds[1] = SFX.play(dreamBlock.travelStartSound)
        elseif not data.travelSounds[1]:isPlaying() and (data.travelSounds[2] == nil or not data.travelSounds[2]:isPlaying()) then
            data.travelSounds[2] = SFX.play(dreamBlock.travelLoopSound,1,0)
        end
    end


    if data.state == STATE.ACTIVE then
        data.travelSoundVolume = 1
    else
        data.travelSoundVolume = math.max(0,data.travelSoundVolume - 0.05)
    end

    for i=1,2 do
        local obj = data.travelSounds[i]

        if obj ~= nil then
            obj.volume = data.travelSoundVolume

            if obj.volume <= 0 then
                obj:stop()
                data.travelSounds[i] = nil
            end
        end
    end
end


function dreamBlock.onReset(fromRespawn)
    if fromRespawn then
        resetState(player,dreamBlock.playerData)
    end
end


function dreamBlock.onInitAPI()
    madeline = require("madeline")

    registerEvent(dreamBlock,"onTick")
    registerEvent(dreamBlock,"onDraw")
    registerEvent(dreamBlock,"onReset")
end

function dreamBlock.onTick()
    dreamBlock.onTickPlayer(player)
end



local particleBuffer = Graphics.CaptureBuffer(800,600)
local maskBuffer = Graphics.CaptureBuffer(800,600)

local maskShader = Shader()
maskShader:compileFromFile(nil,"madeline/dreamBlock_mask.frag")

local finalShader

local particleVC = {}
local particleTC = {}
local particleColors = {}
local particleVertexCount = 0
local particleOldVertexCount = 0
local particleColorCount = 0
local particleOldColorCount = 0
local particleDrawArgs = {target = particleBuffer,vertexCoords = particleVC,textureCoords = particleTC,vertexColors = particleColors,priority = -100}


local function drawParticles()
    Graphics.drawScreen{target = particleBuffer,color = Color.black,priority = -100}

    
    local texture = dreamBlock.particlesTexture

    particleDrawArgs.texture = texture

    local width = texture.width
    local height = texture.height/dreamBlock.particleFrames
    local twidth = 1
    local theight = 1/dreamBlock.particleFrames

    local rng = RNG.new(1)

    for i = 1,dreamBlock.particleCount do
        local topFrame = rng:randomInt(1,dreamBlock.particleFrames)
        local frame = 0

        if topFrame > 1 then
            frame = math.floor(lunatime.tick()/rng:random(10,20)) % ((topFrame*2) - 2)

            if frame >= topFrame then
                frame = frame - topFrame + 1
            end
        end


        local color = rng:irandomEntry(dreamBlock.particleColors)
        local parallax = rng:random(0.25,1)

        -- Vertex coords
        local x1 = (rng:random(0,800) - camera.x*parallax + width )%(800 + width ) - width 
        local y1 = (rng:random(0,600) - camera.y*parallax + height)%(600 + height) - height
        local x2 = x1 + width
        local y2 = y1 + height

        particleVC[particleVertexCount+1 ] = x1 -- top left
        particleVC[particleVertexCount+2 ] = y1
        particleVC[particleVertexCount+3 ] = x2 -- top right
        particleVC[particleVertexCount+4 ] = y1
        particleVC[particleVertexCount+5 ] = x1 -- bottom left
        particleVC[particleVertexCount+6 ] = y2
        particleVC[particleVertexCount+7 ] = x2 -- top right
        particleVC[particleVertexCount+8 ] = y1
        particleVC[particleVertexCount+9 ] = x1 -- bottom left
        particleVC[particleVertexCount+10] = y2
        particleVC[particleVertexCount+11] = x2 -- bottom right
        particleVC[particleVertexCount+12] = y2

        -- Texture coords
        local tx1 = 0
        local ty1 = frame*theight
        local tx2 = tx1 + twidth
        local ty2 = ty1 + theight

        particleTC[particleVertexCount+1 ] = tx1 -- top left
        particleTC[particleVertexCount+2 ] = ty1
        particleTC[particleVertexCount+3 ] = tx2 -- top right
        particleTC[particleVertexCount+4 ] = ty1
        particleTC[particleVertexCount+5 ] = tx1 -- bottom left
        particleTC[particleVertexCount+6 ] = ty2
        particleTC[particleVertexCount+7 ] = tx2 -- top right
        particleTC[particleVertexCount+8 ] = ty1
        particleTC[particleVertexCount+9 ] = tx1 -- bottom left
        particleTC[particleVertexCount+10] = ty2
        particleTC[particleVertexCount+11] = tx2 -- bottom right
        particleTC[particleVertexCount+12] = ty2

        -- Vertex colors
        for j = 1,6 do
            particleColors[particleColorCount+1] = color.r
            particleColors[particleColorCount+2] = color.g
            particleColors[particleColorCount+3] = color.b
            particleColors[particleColorCount+4] = 1

            particleColorCount = particleColorCount + 4
        end


        particleVertexCount = particleVertexCount + 12
    end

    -- Clear out old vertices
    for i = particleVertexCount+1,particleOldVertexCount do
        particleVC[i] = nil
        particleTC[i] = nil
    end

    for i = particleColorCount+1,particleOldColorCount do
        particleColors[i] = nil
    end

    particleOldVertexCount = particleVertexCount
    particleOldColorCount = particleColorCount
    particleVertexCount = 0
    particleColorCount = 0

    -- Draw
    Graphics.glDraw(particleDrawArgs)
end


function dreamBlock.onDraw()
    dreamBlock.onDrawPlayer(player)

    
    if not drewBlock then
        return
    end


    if finalShader == nil then
        finalShader = Shader()
        finalShader:compileFromFile(nil,"madeline/dreamBlock_final.frag",{OUTLINE_THICKNESS = dreamBlock.blockOutlineThickness,PIXEL_SIZE = dreamBlock.blockPixelSize})
    end


    -- Draw particles that appear in blocks
    drawParticles()


    -- Draw dream blocks from the already-produced mask
    Graphics.drawScreen{
        texture = maskBuffer,priority = dreamBlock.priority,
        shader = finalShader,uniforms = {
            particleBuffer = particleBuffer,
            outlineColor = dreamBlock.blockOutlineColor,

            bufferSize = vector(maskBuffer.width,maskBuffer.height),
        },
    }

    drewBlock = false
end


function dreamBlock.onCameraDrawBlock(v,camIdx)
    local c = Camera(camIdx)

    if not blockutils.hiddenFilter(v) or not blockutils.visible(c,v.x,v.y,v.width,v.height) then return end

    if not drewBlock then
        maskBuffer:clear(-100)
        drewBlock = true
    end

    local perlinTexture = Graphics.sprites.hardcoded["53-1"].img

    local width = v.width + dreamBlock.blockRippleSize*2
    local height = v.height + dreamBlock.blockRippleSize*2

    Graphics.drawBox{
        target = maskBuffer,priority = -100,sceneCoords = true,
        x = v.x - dreamBlock.blockRippleSize,
        y = v.y - dreamBlock.blockRippleSize,
        width = width,height = height,

        shader = maskShader,uniforms = {
            perlinTexture = perlinTexture,

            time = lunatime.tick(),

            size = vector(width,height),

            rippleSize = dreamBlock.blockRippleSize,

            pixelSize = dreamBlock.blockPixelSize,

            cameraPos = vector(c.x,c.y),
        },
    }
end



dreamBlock.priority = -66


dreamBlock.blockRippleSize = 4
dreamBlock.blockPixelSize = 2
dreamBlock.blockOutlineThickness = 2
dreamBlock.blockOutlineColor = Color.white


dreamBlock.playerSpeed = 8

dreamBlock.afterExitJumpTime = 8
dreamBlock.beforeExitJumpTime = 6


dreamBlock.enterSounds = {
    SFX.open(Misc.resolveSoundFile("madeline/sounds/dreamBlock_enter_1")),
    SFX.open(Misc.resolveSoundFile("madeline/sounds/dreamBlock_enter_2")),
    SFX.open(Misc.resolveSoundFile("madeline/sounds/dreamBlock_enter_3")),
    SFX.open(Misc.resolveSoundFile("madeline/sounds/dreamBlock_enter_4")),
}
dreamBlock.exitSounds = {
    SFX.open(Misc.resolveSoundFile("madeline/sounds/dreamBlock_exit_1")),
    SFX.open(Misc.resolveSoundFile("madeline/sounds/dreamBlock_exit_2")),
    SFX.open(Misc.resolveSoundFile("madeline/sounds/dreamBlock_exit_3")),
    SFX.open(Misc.resolveSoundFile("madeline/sounds/dreamBlock_exit_4")),
}

dreamBlock.travelStartSound = SFX.open(Misc.resolveSoundFile("madeline/sounds/dreamBlock_travel_start"))
dreamBlock.travelLoopSound = SFX.open(Misc.resolveSoundFile("madeline/sounds/dreamBlock_travel_loop"))


dreamBlock.playerImage = Graphics.loadImageResolved("madeline/dreamBlock_player.png")
dreamBlock.playerFrames = 2
dreamBlock.playerFramespeed = 2

dreamBlock.particlesTexture = Graphics.loadImageResolved("madeline/dreamBlock_particles.png")
dreamBlock.particleFrames = 3
dreamBlock.particleCount = 128

dreamBlock.particleColors = {
    Color.fromHexRGB(0xFFFA07), -- yellow
    Color.fromHexRGB(0x55CFDD), -- turquoise
    Color.fromHexRGB(0x4259DD), -- dark blue
    Color.fromHexRGB(0x72A756), -- light green
    Color.fromHexRGB(0x05A00A), -- dark green
    Color.fromHexRGB(0xC71F28), -- red
}


return dreamBlock