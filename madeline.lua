--[[

    Celeste Madeline Playable
    by MrDoubleA

    Sprites by MisterMike: https://www.spriters-resource.com/custom_edited/celestecustoms/sheet/111439/

]]

local playerManager = require("playerManager")

local animationPal = require("animationPal")
local distortionEffects = require("distortionEffects")

local easing = require("ext/easing")

local respawnRooms
pcall(function() respawnRooms = require("respawnRooms") end)

local dreamBlock


local madeline = {}


-- Constants
_G.CHARACTER_MADELINE = CHARACTER_ULTIMATERINKA


playerManager.overrideCharacterLib(CHARACTER_MADELINE,madeline)

Graphics.registerCharacterHUD(CHARACTER_MADELINE, Graphics.HUD_HEARTS)


local data = {} -- stores data about the player's current state for custom stuff. done this way to hopefully make converting this to be multiplayer compatible in the future easier

madeline.playerData = data


local colBox   = Colliders.Box(0,0,0,0)
local colBox2  = Colliders.Box(0,0,0,0)



local function canUseExtraStuff()
    return (
        player.character == CHARACTER_MADELINE -- actually using the character

        and player.forcedState == FORCEDSTATE_NONE and player.deathTimer == 0 and not player:mem(0x13C,FIELD_BOOL) -- not in a forced state/dead
        and player.mount == MOUNT_NONE

        and not player:mem(0x0C,FIELD_BOOL) -- fairy
        and not player:mem(0x44,FIELD_BOOL) -- riding a rainbow shell
        and not player:mem(0x4A,FIELD_BOOL) -- statue
        and player:mem(0x26,FIELD_WORD) == 0 -- pulling something out of the ground
    )
end

local function isOnGroundRedigit() -- isOnGround, but the redigit way. (perhaps surprisingly) is sometimes more reliable than :isOnGround()
    return (
        player.speedY == 0 -- """on a block"""
        or player:mem(0x48,FIELD_WORD) > 0 -- on a slope
        or player:mem(0x176,FIELD_WORD) > 0 -- on an NPC
    )
end



local function doTemporaryPause(time)
    data.pauseTime = time
    Misc.pause(true)
end

local function makeDust(xOffset,yOffset)
    xOffset = xOffset or ((player.width/2)*player.direction)
    yOffset = yOffset or player.height

    local e = Effect.spawn(74,player.x+(player.width/2)+xOffset,player.y+yOffset)

    e.x = e.x-(e.width /2)
    e.y = e.y-(e.height/2)
end


local function setColliderToPlayerSide(col,leniency)
    col.y = player.y
    col.width = leniency+math.abs(player.speedX*2)
    col.height = player.height

    if player.direction == DIR_LEFT then
        col.x = player.x+player.speedX-col.width
    else
        col.x = player.x+player.speedX+player.width
    end
end



local function getGravity()
    local gravity = Defines.player_grav

    if player:mem(0x40,FIELD_WORD) > 0 or player:mem(0x3A,FIELD_WORD) > 0 then
        gravity = 0
    elseif player:mem(0x34,FIELD_WORD) > 1 then
        gravity = gravity*0.1
    end


    return gravity
end



local function solidBlockFilter(v,includeSemisolid)
    local config = Block.config[v.id]

    return (
        Colliders.FILTER_COL_BLOCK_DEF(v)
        and (
            Block.SOLID_MAP[v.id]
            or Block.PLAYERSOLID_MAP[v.id]
            or (config.playerfilter > 0 and config.playerfilter ~= player.character and not config.passthrough and (includeSemisolid or not Block.SEMISOLID_MAP[v.id]))
            or (includeSemisolid and Block.SEMISOLID_MAP[v.id] and config.playerfilter == 0)
        )
    )
end
local function solidOrSemisolidBlockFilter(v)
    return solidBlockFilter(v,true)
end

local function solidNPCFilter(v,includeSemisolid)
    local config = NPC.config[v.id]

    return (
        Colliders.FILTER_COL_NPC_DEF(v)
        and v.despawnTimer > 0
        and (config.playerblock or (includeSemisolid and config.playerblocktop))

        and v:mem(0x12C,FIELD_WORD) == 0 -- grabbed by a player
        and not v:mem(0x136,FIELD_BOOL)  -- projectile flag
        and v:mem(0x138,FIELD_WORD) == 0 -- forced state
    )
end
local function solidOrSemisolidNPCFilter(v)
    return solidNPCFilter(v,true)
end

local function harmfulBlockFilter(v)
    local config = Block.config[v.id]

    return (
        Colliders.FILTER_COL_BLOCK_DEF(v)
        and Block.HURT_MAP[v.id]
    )
end
local function harmfulNPCFilter(v)
    local config = NPC.config[v.id]

    return (
        Colliders.FILTER_COL_NPC_DEF(v)
        and v.despawnTimer > 0

        and not config.nohurt
        and not config.isinteractable
    )
end

-- make these public for the dream blocks
madeline.solidBlockFilter            = solidBlockFilter
madeline.solidOrSemisolidBlockFilter = solidOrSemisolidBlockFilter
madeline.solidNPCFilter              = solidNPCFilter
madeline.solidOrSemisolidNPCFilter   = solidOrSemisolidNPCFilter


function madeline.increaseMaxSpeed(speed,decrease,decreasesInAir)
    if speed > Defines.player_runspeed then
        Defines.player_runspeed = speed

        data.increasedMaxSpeed = true
        data.maxSpeedDecrease = decrease or 0.4

        if decreasesInAir == nil then
            data.maxSpeedDecreasesInAir = true
        else
            data.maxSpeedDecreasesInAir = decreasesInAir
        end
    end
end




madeline.afterimages = {}

madeline.afterimageShader = Shader()
madeline.afterimageShader:compileFromFile(nil,Misc.resolveFile("madeline/solidColor.frag"))

local function createAfterimage(color)
    local animationData = animationPal.getPlayerData(1)
    local frame = animationData.animator.currentFrame
    
    local obj = {
        player = player,

        character  = player.character ,
        powerup    = player.powerup   ,
        direction  = player.direction ,
        mount      = player.mount     ,
        mountColor = player.mountColor,

        x = player.x + player.width*0.5,
        y = player.y + player.height,

        frame = frame,

        age = 0,

        opacity = 0.75,
        fullOpacityTime = 8,
        fadeSpeed = 0.02,

        color = color,
    }

    table.insert(madeline.afterimages,obj)

    return obj
end


local function hasQuickRespawn()
    return (respawnRooms ~= nil and respawnRooms.respawnSettings.enabled)
end



-- Death animation
local resetDeathState
local handleDeath
local handleDeathDrawing

local DEATH_STATE = {
    INACTIVE    = 0,
    HIT         = 1,
    EXPLODE     = 2,
    PRE_RESPAWN = 3,
    RESPAWN     = 4,
}

do
    function madeline.drawDeathEffects(centre,distance,radius,rotation,color)
        for i = 0,madeline.deathSettings.effects-1 do
            local thisRotation = rotation + (i/madeline.deathSettings.effects)*360
            local position = centre + vector(0,-distance):rotate(thisRotation)

            Graphics.drawBox{
                texture = madeline.deathSettings.effectImage,color = color,priority = -5,
                width = radius*2,height = radius*2,

                x = position.x,y = position.y,

                centred = true,sceneCoords = true,
            }
        end
    end


    local function findDeathDirection()
        local col = Colliders.getSpeedHitbox(player)

        col.width = col.width + 8
        col.height = col.height + 12
        col.x = col.x - 4
        col.y = col.y - 4


        local npc = Colliders.getColliding{a = col,btype = Colliders.NPC,filter = harmfulNPCFilter}[1]
        if npc ~= nil then
            return vector(
                (npc.x + npc.width *0.5) - (player.x + player.width *0.5),
                (npc.y + npc.height*0.5) - (player.y + player.height*0.5)
            ):normalise()
        end

        local block = Colliders.getColliding{a = col,btype = Colliders.BLOCK,filter = harmfulBlockFilter}[1]
        if block ~= nil then
            local direction = math.sign((block.x + block.width*0.5) - (player.x + player.width*0.5))

            return vector(direction,0):rotate(RNG.random(-20,20))
        end

        return vector.zero2
    end


    local function startExplode()
        data.deathState = DEATH_STATE.EXPLODE
        data.deathTimer = 0

        data.deathSpeed = vector.zero2

        Defines.earthquake = 7

        SFX.play(madeline.deathSettings.deathSFX)


        local strength
        if data.deathDirection == vector.zero2 then
            strength = 40
        end

        distortionEffects.create{
            x = player.x+(player.width/2),y = player.y+(player.height/2),
            texture = distortionEffects.textures.circle,
            scaleGrowth = 0.1,
            strengthFade = 2,
            strength = strength,
        }
    end

    function madeline.startDeath(direction)
        direction = direction or findDeathDirection()

        if player.deathTimer == 0 then
            player.forcedState = FORCEDSTATE_INVISIBLE
            player.forcedTimer = -player.idx
        end

        if direction == vector.zero2 then
            startExplode()
        else
            data.deathState = DEATH_STATE.HIT
            data.deathTimer = 0

            data.deathSpeed = -direction*madeline.deathSettings.initialSpeed

            player.direction = -math.sign(data.deathSpeed.x)

            Defines.earthquake = 4

            SFX.play(madeline.deathSettings.hitSFX)
        end
        
        data.deathDirection = direction
    end

    function resetDeathState()
        data.deathState = DEATH_STATE.INACTIVE
        data.deathTimer = 0

        data.deathOffset = vector.zero2
        data.deathDirection = vector.zero2
        data.deathSpeed = vector.zero2

        data.deathEffectDistance = 0
        data.deathEffectSize = 0

        data.deathEffectColor = nil
    end

    function handleDeath()
        if data.deathState == DEATH_STATE.INACTIVE then
            return
        end


        local finish = false


        data.deathTimer = data.deathTimer + 1

        if data.deathState == DEATH_STATE.HIT then
            data.deathSpeed = data.deathSpeed*madeline.deathSettings.slowDown

            if data.deathSpeed.length < madeline.deathSettings.minSpeed then
                startExplode()
            end
        elseif data.deathState == DEATH_STATE.EXPLODE then
            local time = (hasQuickRespawn() and madeline.deathSettings.explodeTimeRespawn) or madeline.deathSettings.explodeTimeNormal

            if data.deathTimer >= time then
                --player.forcedState = FORCEDSTATE_NONE
                --player.forcedTimer = 0

                finish = true
            end
        elseif data.deathState == DEATH_STATE.PRE_RESPAWN then
            if data.deathTimer >= madeline.deathSettings.preRespawnTime then
                data.deathState = DEATH_STATE.RESPAWN
                data.deathTimer = 0

                SFX.play(madeline.deathSettings.respawnSFX)
            end
        elseif data.deathState == DEATH_STATE.RESPAWN then
            if data.deathTimer >= madeline.deathSettings.respawnTime then
                player.forcedState = FORCEDSTATE_NONE
                player.forcedTimer = 0

                data.deathState = DEATH_STATE.INACTIVE
                data.deathTimer = 0

                -- Effects
                distortionEffects.create{
                    x = player.x + player.width*0.5,y = player.y + player.height*0.5,
                }
            end
        end


        if hasQuickRespawn() then
            if finish then
                player.forcedState = FORCEDSTATE_NONE
                player.forcedTimer = 0

                player.deathTimer = 1
            end
        else
            if finish then
                player.deathTimer = math.max(player.deathTimer,298)
            else
                player.deathTimer = math.min(100,player.deathTimer)
            end
        end

        data.deathOffset = data.deathOffset + data.deathSpeed
    end


    function handleDeathDrawing()
        local t

        if data.deathState == DEATH_STATE.EXPLODE then
            t = easing.outQuad(math.min(1,data.deathTimer/madeline.deathSettings.explodeEffectsTime),0,1,1)
        elseif data.deathState == DEATH_STATE.RESPAWN then
            t = easing.inQuad(math.min(1,data.deathTimer/madeline.deathSettings.respawnTime),1,-1,1)
        end

        if t ~= nil then
            local centre = vector(player.x + player.width*0.5,player.y + player.height*0.5) + data.deathOffset

            local distance = madeline.deathSettings.effectsMaxDistance*t
            local radius = madeline.deathSettings.effectsMaxRadius*math.min(1,(1 - t)*8)

            madeline.drawDeathEffects(centre,distance,radius,t*90,madeline.getAfterimageColor())
        end
    end
end



-- Dash stuff
local canDash
local resetDashState
local handleDash

do
    local function getDirection()
        local direction = vector.zero2

        if player.keys.left then
            direction.x = -1
        elseif player.keys.right then
            direction.x = 1
        end

        if player.keys.up then
            direction.y = -1
        elseif player.keys.down then
            direction.y = 1
        end


        if direction == vector.zero2 then -- If still 0, set to the current direction
            direction.x = player.direction
        end


        direction = direction:normalise()


        return direction
    end


    function madeline.getAfterimageColor()
        local color = madeline.dashSettings.afterimageColors

        if type(color) == "table" then
            color = color[data.currentDashes] or color[#color] or color[0] or Color.white
        end

        return color
    end


    local function spawnProjectile()
        local id = madeline.dashSettings.projectileNPCs[player.powerup]
        
        if id == nil then
            return
        end

        local v = NPC.spawn(id,player.x + player.width*0.5 + data.dashDirection.x*madeline.dashSettings.projectileOffset,player.y + player.height*0.5 + data.dashDirection.y*madeline.dashSettings.projectileOffset,player.section,false,true)

        if id == 13 then
            v.ai1 = madeline.dashSettings.fireballType
        end

        if data.dashDirection.x ~= 0 then
            v.direction = math.sign(data.dashDirection.x)
        else
            v.direction = player.direction
        end

        v.speedX = data.dashDirection.x*madeline.dashSettings.projectileSpeedX
        v.speedY = data.dashDirection.y*madeline.dashSettings.projectileSpeedY

        SFX.play(18)

        return v
    end


    function canDash()
        return (
            true
        )
    end


    function handleDash()
        if not canDash() then
            resetDashState()
            return
        end


        if data.dashCooldown > 0 then
            data.dashCooldown = data.dashCooldown - 1
        elseif isOnGroundRedigit() or Defines.cheat_ahippinandahoppin then
            madeline.refillDashes()
        end


        if data.dashTimer > 0 then
            if data.dashTimer == 1 then
                -- Initialise dash
                data.dashDirection = getDirection(player.keys)

                local speed = data.dashDirection*madeline.dashSettings.speed

                player.speedX = speed.x
                player.speedY = speed.y

                if speed.x ~= 0 then
                    player.direction = math.sign(speed.x)
                end
                if speed.y < 0 then
                    player:mem(0x176,FIELD_WORD,0) -- stop standing on an NPC
                end

                -- Increase max speed
                madeline.increaseMaxSpeed(math.abs(speed.x))


                -- Effects
                Defines.earthquake = 3

                distortionEffects.create{x = player.x+(player.width/2),y = player.y+(player.height/2)}

                --Misc.RumbleSelectedController(1,100,1)


                -- Play sound
                local sound = madeline.dashSettings.sounds[data.currentDashes+1] or madeline.dashSettings.sounds[#madeline.dashSettings.sounds]

                if sound ~= nil and type(sound) == "table" then
                    if speed.x > 0 or (speed.x == 0 and player.direction == DIR_RIGHT) then
                        sound = sound[2] -- going right
                    else
                        sound = sound[1] -- going left
                    end
                end

                if sound ~= nil then
                    SFX.play(sound)
                end
            end

            player.keys.left = false
            player.keys.right = false

            if data.dashDirection ~= vector(0,-1) and not isOnGroundRedigit() and not data.climbing then
                player.speedY = player.speedY - getGravity() + 0.00001
            end


            if data.dashTimer%madeline.dashSettings.afterimageFrequency == 0 and data.dashAfterimageColor ~= nil then
                createAfterimage(data.dashAfterimageColor)
            end


            if data.dashTimer < madeline.dashSettings.length then
                data.dashTimer = data.dashTimer + 1
            else
                spawnProjectile()

                data.dashDirection = vector.zero2
                data.dashTimer = 0
            end
        else
            if (player.keys.altJump == KEYS_PRESSED or (player.keys.altRun == KEYS_PRESSED and player.powerup ~= PLAYER_TANOOKIE)) and data.currentDashes > 0 and data.dashCooldown == 0 then
                data.dashTimer = 1
                data.dashCooldown = madeline.dashSettings.cooldownTime

                data.currentDashes = data.currentDashes - 1

                data.dashAfterimageColor = madeline.getAfterimageColor()

                data.climbing = false

                data.hairFlashTimer = madeline.dashSettings.hairFlashTime


                player:mem(0x11C,FIELD_WORD,0) -- stop jump force

                doTemporaryPause(madeline.dashSettings.startFreezeTime)
            end
        end
    end
end


-- Climbing
local canClimb
local resetClimbingState
local handleClimbing

do
    local function climbableBlockFilter(v)
        return (
            solidBlockFilter(v)
            and not Block.SLOPE_MAP[v.id]
            and not Block.HURT_MAP[v.id]
            and not madeline.climbingSettings.unclimbableBlockIDs[v.id]
        )
    end
    local function climbableNPCFilter(v)
        local config = NPC.config[v.id]
        
        return (
            solidNPCFilter(v)
            and not config.grabside

            and (dreamBlock == nil or data.dashTimer == 0 or not dreamBlock.idMap[v.id])
        )
    end

    local function stopMoveBlockFilter(v)
        return (solidBlockFilter(v) and not climbableBlockFilter(v))
    end


    local function removeStamina(amount)
        data.climbingStamina = math.max(0,data.climbingStamina - amount)
    end


    local function searchForBlocks(v)
        -- Search for blocks
        colBox.width = 2
        colBox.height = player.height - 8
        colBox.y = player.y + (player.height - colBox.height)*0.5

        if player.direction == DIR_RIGHT then
            colBox.x = player.x + player.width
        else
            colBox.x = player.x - colBox.width
        end

        --colBox:draw(Color.green)


        local newObjs = table.append(
            Colliders.getColliding{a = colBox,btype = Colliders.BLOCK,filter = climbableBlockFilter},
            Colliders.getColliding{a = colBox,btype = Colliders.NPC  ,filter = climbableNPCFilter  }
        )

        for _,obj in ipairs(data.climbingOnObjs) do
            if obj.isValid and ((type(obj) == "Block" and climbableBlockFilter(obj)) or (type(obj) == "NPC" and climbableNPCFilter(obj))) and not table.icontains(newObjs,obj) then
                -- If this old object was in range before it moved, we can still climb on it
                colBox2.x = obj.x-obj.speedX
                colBox2.y = obj.y-obj.speedY
                colBox2.width = obj.width
                colBox2.height = obj.height

                if Colliders.collide(colBox,colBox2) then
                    table.insert(newObjs,obj)
                end
            end
        end

        --[[for _,obj in ipairs(newObjs) do
            Colliders.getHitbox(obj):draw()
        end]]

        return newObjs
    end

    local function getSlowestObj(objs)
        local slowestObj
        local slowestSpeed

        for _,obj in ipairs(objs) do
            local speed = (obj.speedX*-player.direction)

            if slowestSpeed == nil or speed < slowestSpeed then
                slowestObj = obj
                slowestSpeed = speed
            end
        end

        return slowestObj
    end

    local function playClimbingSound()
        SFX.play(RNG.irandomEntry(madeline.climbingSettings.sounds))
    end


    local function getLedgeData()
        -- Search for blocks
        setColliderToPlayerSide(colBox,2)
        colBox.height = 1
        colBox.y = (player.y+player.height-18)-(colBox.height/2)

        setColliderToPlayerSide(colBox2,2)
        colBox2.height = (player.height-18)
        colBox2.y = player.y


        local blocks         = Colliders.getColliding{a = colBox2,btype = Colliders.BLOCK,filter = solidBlockFilter   }
        local npcs           = Colliders.getColliding{a = colBox2,btype = Colliders.NPC  ,filter = solidNPCFilter     }
        local stopMoveBlocks = Colliders.getColliding{a = colBox ,btype = Colliders.BLOCK,filter = stopMoveBlockFilter}
        

        return (#stopMoveBlocks == 0),(#blocks == 0 and #npcs == 0) -- can climb up, can hop up
    end


    local function handleClimbingMovement()
        -- Jumping
        if player.keys.jump and player:mem(0x11E,FIELD_BOOL) then
            local jumpForce = Defines.jumpheight

            if data.climbingStamina <= 0 then
                player.speedX = madeline.climbingSettings.noStaminaJumpSpeedX*-player.direction
                player.direction = -player.direction

                jumpForce = jumpForce*0.75
            elseif (player.direction == DIR_LEFT and player.keys.right) or (player.direction == DIR_RIGHT and player.keys.left) then
                player.speedX = madeline.climbingSettings.jumpAwaySpeedX*-player.direction
            end
            player.speedX = player.speedX + getSlowestObj(data.climbingOnObjs).speedX
            

            player:mem(0x11C,FIELD_WORD,jumpForce)
            player:mem(0x11E,FIELD_BOOL,false)


            removeStamina(madeline.climbingSettings.jumpStaminaCost)


            SFX.play(1)
            playClimbingSound()

            data.climbing = false

            return
        end


        -- Up/down movement and slipping with no stamina
        local targetSpeed = 0

        if data.climbingStamina <= 0 then
            data.climbingSpeed = math.clamp(data.climbingSpeed + madeline.climbingSettings.noStaminaAcceleration,0,madeline.climbingSettings.noStaminaMaxSpeed)
            makeDust()

            targetSpeed = nil
        elseif player.keys.up then
            local canClimbUp,canHopUp = getLedgeData()

            if canHopUp then
                local hopOntoObj = getSlowestObj(data.climbingOnObjs)

                data.climbHopPosition = vector(hopOntoObj.x + (hopOntoObj.width/2),hopOntoObj.y)
                data.climbing = false

                player.speedY = madeline.climbingSettings.hopUpSpeedY + math.min(0,hopOntoObj.speedY)

                playClimbingSound()

                return
            elseif canClimbUp then
                targetSpeed = madeline.climbingSettings.upwardSpeed

                removeStamina(madeline.climbingSettings.upStaminaCost)
            end
        elseif player.keys.down then
            targetSpeed = madeline.climbingSettings.downwardsSpeed

            removeStamina(madeline.climbingSettings.downStaminaCost)

            makeDust()
        else
            removeStamina(madeline.climbingSettings.stillStaminaCost)
        end

        if targetSpeed ~= nil then
            if data.climbingSpeed > targetSpeed then
                data.climbingSpeed = math.max(targetSpeed,data.climbingSpeed - madeline.climbingSettings.acceleration)
            elseif data.climbingSpeed < targetSpeed then
                data.climbingSpeed = math.min(targetSpeed,data.climbingSpeed + madeline.climbingSettings.acceleration)
            end
        end
    end


    local function canEndHop()
        return (
            ((player.y+player.height) >= data.climbHopPosition.y and player.speedY >= 0)
            or math.sign(data.climbHopPosition.x-(player.x+(player.width/2))) ~= player.direction -- Gone further than the position

            or math.sign(player.speedX) == -player.direction

            --or (player.direction == DIR_LEFT and player:mem(0x148,FIELD_WORD) > 0 or player.direction == DIR_RIGHT and player:mem(0x14C,FIELD_WORD) > 0) -- hit a wall
            or isOnGroundRedigit()
            or player:mem(0x14A,FIELD_WORD) > 1 -- Hit a ceiling
        )
    end

    local hopDisableKeys = {"jump","altJump","run","altRun","left","right","up","down"}
    local function handleHopUp()
        local position = data.climbHopPosition

        -- End the hop, if possible
        if canEndHop() then
            if isOnGroundRedigit() then
                madeline.refillStamina()
                madeline.refillDashes()
            end

            data.climbHopPosition = nil

            data.dashCooldown = 2 -- TO DO: find better way to stop dashing
            
            player.speedX = 0

            return
        end

        player.speedX = madeline.climbingSettings.hopUpSpeedX*player.direction
        if (player.y+player.height) > position.y and player.speedY < 0 then
            player.speedY = madeline.climbingSettings.hopUpSpeedY
        end


        for _,name in ipairs(hopDisableKeys) do
            player.keys[name] = false
        end
    end


    local function canStartClimbing()
        return (
            (isOnGroundRedigit() or player.speedY >= 0.75)
        )
    end


    function canClimb()
        return (
            not player:mem(0x36,FIELD_BOOL) -- underwater
            and player:mem(0x40,FIELD_WORD) == 0 -- climbing a vine

            and player.holdingNPC == nil -- holding an item
        )
    end

    function resetClimbingState()
        data.climbing = false
        data.climbingOnObjs = {}

        data.climbingStamina = madeline.climbingSettings.maxStamina
        data.climbingNoMoveTimer = 0

        data.climbingSpeed = 0


        data.climbHopPosition = nil
    end

    function handleClimbing()
        if not canClimb() then
            resetClimbingState()
            return
        end


        if isOnGroundRedigit() then
            madeline.refillStamina()
        end
        

        local oldObjs = data.climbingOnObjs


        if data.climbHopPosition then
            handleHopUp()
        elseif player.keys.run then
            data.climbingOnObjs = searchForBlocks()

            if #data.climbingOnObjs > 0 and (data.climbing or canStartClimbing()) then
                if not data.climbing then
                    -- Initialise climbing
                    player.speedY = 0
                    data.climbingSpeed = 0

                    playClimbingSound()
                end

                data.climbing = true


                player:mem(0x11C,FIELD_WORD,0) -- stop jump force


                handleClimbingMovement()


                if data.climbing then -- Still climbing after handling movement
                    -- Stick to a block
                    local slowestObj = getSlowestObj(data.climbingOnObjs)

                    local playerSide = (player.x    +(player.width    /2))+((player.width    /2)*player.direction)
                    local objSide    = (slowestObj.x+(slowestObj.width/2))-((slowestObj.width/2)*player.direction)-slowestObj.speedX

                    player.speedX = (objSide - playerSide) + slowestObj.speedX
                    player.speedY = data.climbingSpeed + slowestObj.speedY - getGravity() - 0.00001


                    player.keys.down = false -- (janky method to) stop ducking
                    player.keys.left = false
                    player.keys.right = false
                end
            elseif data.climbing then
                data.climbing = false
                player.speedX = 0
            end
        elseif data.climbing then
            data.climbing = false
            player.speedX = 0
        end


        if madeline.debugMode then
            local slowestObj = getSlowestObj(data.climbingOnObjs)

            for _,obj in ipairs(table.append(oldObjs,data.climbingOnObjs)) do
                if obj.isValid then
                    local isOld = table.icontains(oldObjs,obj)
                    local isNew = table.icontains(data.climbingOnObjs,obj)
                    local col = Colliders.getHitbox(obj)

                    if slowestObj == obj then
                        col:Draw(Color.green.. 0.5)
                    elseif isOld and isNew then
                        col:Draw(Color.yellow.. 0.5)
                    elseif isNew then
                        col:Draw(Color.red.. 0.5)
                    elseif isOld then
                        col:Draw(Color.lightblue.. 0.5)
                    end
                end
            end
        end
    end
end


-- Wall jumping
local canWallJump
local resetWallJumpState
local handleWallJump

do
    local function slide(canSuperWallJump)
        -- Jump
        if player.keys.jump and player:mem(0x11E,FIELD_BOOL) then
            local jumpForce = Defines.jumpheight
            if canSuperWallJump then
                jumpForce = madeline.wallJumpSettings.superWallJumpForce
            end


            player.speedX = madeline.wallJumpSettings.jumpSpeedX*-player.direction
            player.direction = -player.direction

            data.wallJumpUncontrollableTimer = madeline.wallJumpSettings.uncontrollableTimeAfterJump


            player:mem(0x11C,FIELD_WORD,jumpForce)
            player:mem(0x11E,FIELD_BOOL,false)

            if canSuperWallJump then
                SFX.play(madeline.wallJumpSettings.superWallJumpSFX)
            else
                SFX.play(madeline.wallJumpSettings.normalJumpSFX)
            end

            return
        end

        player.speedY = math.min(madeline.wallJumpSettings.slideSpeed,player.speedY)

        if not canSuperWallJump then
            makeDust()
        end
    end


    function canWallJump()
        return (
            not data.climbing
            and not isOnGroundRedigit()
        )
    end


    function resetWallJumpState()
        data.wallSliding = false

        data.wallJumpUncontrollableTimer = 0
    end

    function handleWallJump()
        if not canWallJump() then
            resetWallJumpState()
            return
        end


        local canSuperWallJump = (data.dashTimer > 0 and data.dashDirection == vector(0,-1))

        if (player.speedY >= 0.75 and (player.direction == DIR_LEFT and player.keys.left or player.direction == DIR_RIGHT and player.keys.right)) or canSuperWallJump then
            local leniency = madeline.wallJumpSettings.leniency
            if canSuperWallJump then
                leniency = madeline.wallJumpSettings.superWallJumpLeniency
            end

            setColliderToPlayerSide(colBox,leniency)


            local objs = table.append(
                Colliders.getColliding{a = colBox,btype = Colliders.BLOCK,filter = solidBlockFilter},
                Colliders.getColliding{a = colBox,btype = Colliders.NPC  ,filter = solidNPCFilter  }
            )

            if #objs > 0 then
                slide(canSuperWallJump)
                data.wallSliding = true
            else
                data.wallSliding = false
            end
        else
            data.wallSliding = false
        end


        if data.wallJumpUncontrollableTimer > 0 then
            data.wallJumpUncontrollableTimer = data.wallJumpUncontrollableTimer - 1

            player.keys.left = false
            player.keys.right = false
        end
    end
end


-- Boot hitbox nonsense fix
local applyBootFix
local cleanupBootFix

do
    local originalMarioHeight,originalMarioDuckHeight

    function applyBootFix()
        -- "Fix" hardcoded NONSENSE with the boot
        -- The boot uses the hitbox is big Mario for some reason, and there's more nonsense
        -- that messes up your position when unducking... for some reason.
        local bigMarioSettings = PlayerSettings.get(CHARACTER_MARIO,PLAYER_BIG)

        if originalMarioHeight == nil then
            originalMarioDuckHeight = bigMarioSettings.hitboxDuckHeight
            originalMarioHeight = bigMarioSettings.hitboxHeight
        end

        bigMarioSettings.hitboxDuckHeight = madeline.generalSettings.bootDuckHitboxHeight
        bigMarioSettings.hitboxHeight = madeline.generalSettings.bootHitboxHeight
    end

    function cleanupBootFix()
        if originalMarioHeight ~= nil then
            local bigMarioSettings = PlayerSettings.get(CHARACTER_MARIO,PLAYER_BIG)

            bigMarioSettings.hitboxDuckHeight = originalMarioDuckHeight
            bigMarioSettings.hitboxHeight = originalMarioHeight

            originalMarioDuckHeight = nil
            originalMarioHeight = nil
        end
    end
end


-- Animation/rendering
do
    madeline.animationSet = {
        idle = {1, defaultFrameY = 1},
        walk = {1,2,3,4,5,6,7, defaultFrameY = 2,frameDelay = 5},

        jump = {1, defaultFrameY = 3},
        fall = {2,3,4, defaultFrameY = 3,frameDelay = 4,loopPoint = 2},
        toJump = {3,2, defaultFrameY = 3,frameDelay = 2,loops = false},

        duck = {1, defaultFrameY = 4},
        lookUp = {2, defaultFrameY = 4},

        climb = {1,2, defaultFrameY = 5,frameDelay = 12},
        wallSlide = {1, defaultFrameY = 6},

        swimIdle = {1,2, defaultFrameY = 7,frameDelay = 8},
        swimStroke = {3,4,5,6, defaultFrameY = 7,frameDelay = 4},

        sit = {1, defaultFrameY = 8},
        crouch = {2, defaultFrameY = 8},
        lie = {3, defaultFrameY = 8},
        statue = {4,5,6,7, defaultFrameY = 8, frameDelay = 8},

        death = {1, defaultFrameY = 9},

        holdingIdle = {1, defaultFrameY = 10},
        holdingWalk = {1,2,3,4,5,6,7, defaultFrameY = 11,frameDelay = 5},
        holdingJump = {1, defaultFrameY = 12},
        holdingFall = {2,3, defaultFrameY = 12,frameDelay = 4,loops = false},
    }


    local pauseAnimationStates = table.map{
        FORCEDSTATE_POWERUP_BIG,FORCEDSTATE_POWERDOWN_SMALL,FORCEDSTATE_POWERUP_FIRE,FORCEDSTATE_POWERUP_LEAF,
        FORCEDSTATE_INVISIBLE,FORCEDSTATE_ONTONGUE,FORCEDSTATE_POWERUP_TANOOKI,FORCEDSTATE_POWERUP_HAMMER,
        FORCEDSTATE_POWERUP_ICE,FORCEDSTATE_POWERDOWN_FIRE,FORCEDSTATE_POWERDOWN_ICE,
    }

    function madeline.findAnimation(animator)
        if data.deathState ~= DEATH_STATE.INACTIVE then
            return "death"
        end


        if player.mount ~= MOUNT_NONE then
            return "idle"
        end


        if player.forcedState == FORCEDSTATE_PIPE then
            local direction = animationPal.utils.getPipeDirection(player)

            if direction == 2 or direction == 4 then
                return "walk",1
            else
                return "idle"
            end
        elseif dreamBlock ~= nil and dreamBlock.playerData.state == dreamBlock.STATE.ACTIVE then
            return "fall"
        elseif pauseAnimationStates[player.forcedState] then
            return animator.currentAnimation,0
        elseif player.forcedState ~= FORCEDSTATE_NONE then
            return "idle"
        end


        if player:mem(0x4A,FIELD_BOOL) then
            return "statue"
        end


        if player:mem(0x12E,FIELD_BOOL) then
            return "duck"
        end


        if data.climbing then
            return "climb",math.abs(data.climbingSpeed)
        end

        if player.holdingNPC ~= nil then
            if not animationPal.utils.isOnGroundAnimation(player) then -- in the air/swimming
                if player.speedY < 0 then -- rising
                    return "holdingJump"
                else -- falling
                    return "holdingFall"
                end
            end

            -- Walking
            if player.speedX ~= 0 then
                return "holdingWalk",math.max(1,math.abs(player.speedX)/3)
            end

            return "holdingIdle"
        end


        if animationPal.utils.isOnGroundAnimation(player) then
            if player.speedX ~= 0 then
                return "walk",math.max(1,math.abs(player.speedX)/3)
            end

            if player.keys.up then
                return "lookUp"
            end

            return "idle"
        elseif player:mem(0x34,FIELD_WORD) > 0 then
            if player:mem(0x38,FIELD_WORD) >= 15 then
                return "swimStroke",1,true
            elseif animator.currentAnimation == "swimStroke" and not animator.animationFinished then
                return "swimStroke"
            end

            return "swimIdle"
        else
            if data.wallSliding then
                return "wallSlide"
            end

            if player.speedY < 0 then
                if animator.currentAnimation == "fall" or (animator.currentAnimation == "toJump" and not animator.animationFinished) then
                    return "toJump"
                end

                return "jump"
            else
                return "fall"
            end
        end
    end


    local paletteImage = Graphics.loadImageResolved("madeline/palettes.png")

    local mainShader = Shader()
    mainShader:compileFromFile(nil,"madeline/main.frag",{COLOR_COUNT = paletteImage.width,PALETTE_COUNT = paletteImage.height})
    

    local powerupPalettes = {[PLAYER_FIREFLOWER] = 1,[PLAYER_ICE] = 2,[PLAYER_LEAF] = 3,[PLAYER_TANOOKIE] = 4,[PLAYER_HAMMER] = 5}

    local hairPalettes = {[0] = 1,[1] = 0}
    local hairPaletteCount = 4

    local function getPalette(properties)
        local hairPalette = hairPalettes[data.currentDashes] or (hairPaletteCount - 2)
        if data.hairFlashTimer > 0 then
            hairPalette = hairPaletteCount - 1
        end

        local powerupPalette = powerupPalettes[properties.powerup] or 0

        return hairPalette + powerupPalette*hairPaletteCount
    end


    function madeline.getTextureFunc(_,properties)
        local charData = animationPal.getCharacterData(player.character)

        local powerup = properties.powerup
        local image = charData.textures[powerup]

        if image == nil then
            local name = "madeline/main-backpack.png"

            if powerup == PLAYER_SMALL then
                name = "madeline/main-nobackpack.png"
            end

            image = Graphics.loadImageResolved(name)
            charData.textures[powerup] = image
        end

        return image
    end


    function madeline.isInvisibleFunc(p,args)
        if args.ignorestate then
            return false
        end

        if data.deathState ~= DEATH_STATE.INACTIVE then
            return (data.deathState ~= DEATH_STATE.HIT)
        end

        return animationPal.defaultCharacterFuncs.isInvisibleFunc(p,args)
    end


    animationPal.registerCharacter(CHARACTER_MADELINE,{
        imageDirection = DIR_RIGHT,

        animationSet = madeline.animationSet,

        getTextureFunc = madeline.getTextureFunc,
        findAnimationFunc = madeline.findAnimation,
        isInvisibleFunc = madeline.isInvisibleFunc,
        preDrawFunc = madeline.preDrawFunc,

        offsetY = 10,

        frameWidth = 64,
        frameHeight = 64,
    })
end





local function resetState()

    -- General state stuff
    if data.pauseTime ~= nil and data.pauseTime > 0 then
        Misc.unpause()
    end

    if data.increasedMaxSpeed then
        Defines.player_runspeed = madeline.generalSettings.runSpeed
    end
    data.increasedMaxSpeed = false
    data.maxSpeedDecrease = 0
    data.maxSpeedDecreasesInAir = false

    data.pauseTime = 0
end


function madeline.initCharacter()
    Defines.player_walkspeed = madeline.generalSettings.walkSpeed
    Defines.player_runspeed = madeline.generalSettings.runSpeed

    Defines.jumpheight = madeline.generalSettings.jumpForceTime
    Defines.jumpheight_bounce = Defines.jumpheight

    Audio.sounds[8].muted = true

    resetState()
    resetDeathState()

    applyBootFix()
end

function madeline.cleanupCharacter()
    Defines.player_walkspeed = nil
    Defines.player_runspeed = nil

    Defines.jumpheight = nil
    Defines.jumpheight_bounce = nil

    player:mem(0x04,FIELD_WORD,0)

    Audio.sounds[8].muted = false
    

    resetState()
    resetDeathState()

    cleanupBootFix()
end



function madeline.onInitAPI()
    
    registerEvent(madeline,"onTick","onTickPlayer")
    registerEvent(madeline,"onDraw","onDrawPlayer")

    registerEvent(madeline,"onTick")
    registerEvent(madeline,"onDraw")

    registerEvent(madeline,"onPlayerKill")

    if respawnRooms ~= nil then
        respawnRooms.onPostReset = madeline.onPostReset
    end


    resetState()
    resetDeathState()
end

function madeline.onTickPlayer()
    if player.character ~= CHARACTER_MADELINE then
        return
    end

    applyBootFix()
    
    handleDeath()

    if not canUseExtraStuff() then
        resetState()
        return
    end


    --[[if isOnGroundRedigit() then
        player:mem(0x04,FIELD_WORD,0)
    else
        player:mem(0x04,FIELD_WORD,1) -- disable ducking
    end]]

    if data.increasedMaxSpeed then
        if data.maxSpeedDecreasesInAir or isOnGroundRedigit() then
            Defines.player_runspeed = math.max(0,Defines.player_runspeed - data.maxSpeedDecrease)
        end

        if Defines.player_runspeed <= madeline.generalSettings.runSpeed then
            Defines.player_runspeed = madeline.generalSettings.runSpeed

            data.increasedMaxSpeed = false
            data.maxSpeedDecrease = 0
            data.maxSpeedDecreasesInAir = false
        else
            Defines.player_runspeed = math.min(Defines.player_runspeed,math.abs(player.speedX)*1.07)
        end

        if math.abs(player.speedX) > Defines.player_runspeed*0.93 then
            player.speedX = Defines.player_runspeed*0.93*math.sign(player.speedX)
        end
    end


    player:mem(0x120,FIELD_BOOL,false) -- stop jumping with the spin jump key
    -- disable peach hover
    player:mem(0x18,FIELD_BOOL,false)
    player:mem(0x1A,FIELD_BOOL,false)
    player:mem(0x1C,FIELD_WORD,0)
    player:mem(0x02,FIELD_BOOL,false)

    player:mem(0x168,FIELD_FLOAT,0) -- no tanooki flying

    if player.mount == MOUNT_NONE then
        player:mem(0x172,FIELD_BOOL,false)
        --player:mem(0x160,FIELD_WORD,3) -- prevent fireball shooting
    end
end

function madeline.onDrawPlayer()
    if player.character ~= CHARACTER_MADELINE then
        return
    end

    if data.pauseTime > 0 and Misc.isPausedByLua() then
        data.pauseTime = data.pauseTime - 1

        if data.pauseTime <= 0 then
            Misc.unpause()
        end
    end

    handleDeathDrawing()

    -- Rendering the player
    --[[if data.deathState == DEATH_STATE.INACTIVE then
        local blinkingSpeed = madeline.climbingSettings.dangerBlinkingSpeed

        if data.climbingStamina <= madeline.climbingSettings.dangerStamina and canUseExtraStuff() and canClimb() and lunatime.tick()%(blinkingSpeed*2) < blinkingSpeed then
            player:render{
                drawmounts = false,
                drawhair = false,
                color = madeline.climbingSettings.dangerBlinkingColor,
            }
        end


        --madeline.drawHairWithPipeCutoff(player,{})
    else
        local centre = vector(player.x+(player.width/2),player.y+(player.height/2))

        if data.deathState == DEATH_STATE.HIT then
            player:render{ignorestate = true}
        elseif data.deathEffectSize > 0 then
            madeline.drawDeathEffects(centre,data.deathEffectDistance,data.deathEffectSize,data.deathTimer*2)
        end
    end]]
end


-- Afterimage stuff
function madeline.onTick()
    for k = #madeline.afterimages, 1, -1 do -- done backwards to let table.remove work properly
        local obj = madeline.afterimages[k]

        obj.age = obj.age + 1

        if obj.age > obj.fullOpacityTime then
            obj.opacity = obj.opacity - obj.fadeSpeed
        end

        if obj.opacity <= 0 or not obj.player.isValid then
            table.remove(madeline.afterimages,k)
        end
    end
end

function madeline.onDraw()
    for _,obj in ipairs(madeline.afterimages) do
        if obj.player.isValid then
            obj.player:render{
                character  = obj.character ,
                powerup    = obj.powerup   ,
                direction  = obj.direction ,
                frame      = obj.frame     ,
                mount      = obj.mount     ,
                mounttype  = obj.mountColor,
                
                x = obj.x - player.width*0.5,
                y = obj.y - player.height,

                color = Color.white.. obj.opacity,
                ignorestate = true,
                priority = -31,

                shader = madeline.afterimageShader,uniforms = {
                    color = obj.color,
                },
            }
        end
    end
end


function madeline.onPostReset(fromRespawn)
    if fromRespawn then
        resetState()
        resetDeathState()

        for i = 1,#madeline.afterimages do
            madeline.afterimages[i] = nil
        end

        -- Respawn animation
        if player.character == CHARACTER_MADELINE then
            data.deathState = DEATH_STATE.PRE_RESPAWN
            data.deathTimer = 0

            player.forcedState = FORCEDSTATE_INVISIBLE
            player.forcedTimer = 0
        end
    else
        madeline.refillStamina()
    end
end

function madeline.onPlayerKill(eventObj,p)
    if p.character ~= CHARACTER_MADELINE then
        return
    end

    if hasQuickRespawn() then
        eventObj.cancelled = true

        if data.deathState == DEATH_STATE.INACTIVE then
            madeline.startDeath()
        end
    else
        madeline.startDeath()
    end
end



madeline.generalSettings = {
    -- How fast the player can walk/run.
    walkSpeed = 6,
    runSpeed = 6,

    -- For how long the player gets a jump force after doing a jump.
    jumpForceTime = 15,

    -- Size of the player's hitbox while in a boot.
    bootHitboxHeight = 42,
    bootDuckHitboxHeight = 28,

    -- Offset of Madeline's sprite while in a boot.
    bootOffsetX = 0,
    bootOffsetY = -8,
}


madeline.dashSettings = {
    -- How long the game pauses for when a dash starts.
    startFreezeTime = 3,
    -- How long the player must wait before being able to dash again.
    cooldownTime = 13,

    -- How fast the dash initially goes.
    speed = 12,
    -- How long the dash actually lasts.
    length = 11,

    -- How many frames it takes for one afterimage to spawn.
    afterimageFrequency = 3,

    -- Time the hair flashes white for.
    hairFlashTime = 4,

    -- How many dashes the player gets when their dashes are refilled.
    maxDashes = {
        [PLAYER_BIG] = 1,
        [PLAYER_LEAF] = 2,
        [PLAYER_TANOOKIE] = 2,
    },


    -- NPC's spawned after a dash.
    projectileNPCs = {
        [PLAYER_FIREFLOWER] = 13,
        [PLAYER_ICE] = 265,
        [PLAYER_HAMMER] = 291,
    },
    fireballType = CHARACTER_MARIO,

    projectileSpeedX = 8,
    projectileSpeedY = 12,
    projectileOffset = 16,


    -- What sounds get played while dashing. 
    sounds = {
        [1] = {SFX.open(Misc.resolveSoundFile("madeline/sounds/dash_1_left")),SFX.open(Misc.resolveSoundFile("madeline/sounds/dash_1_right"))},
        [2] = {SFX.open(Misc.resolveSoundFile("madeline/sounds/dash_2_left")),SFX.open(Misc.resolveSoundFile("madeline/sounds/dash_2_right"))},
    },

    -- The colour of the afterimages that appear while dashing.
    afterimageColors = {
        [0] = Color.lightred,
        [1] = Color.lightred,
        [2] = Color.lightred,
    },
}


madeline.climbingSettings = {
    maxSpeed = 1.5,

    acceleration   =  0.375,
    upwardSpeed    = -1.500,
    downwardsSpeed =  2.250,

    noStaminaAcceleration = 0.05,
    noStaminaMaxSpeed = 8,


    jumpAwaySpeedX = 2,
    noStaminaJumpSpeedX = 6,


    maxStamina       = 110,
    jumpStaminaCost  = 27.5,
    stillStaminaCost = 0.21,
    upStaminaCost    = 0.5,
    downStaminaCost  = 0,


    dangerStamina = 10, -- How much stamina the player has to have left in order to start blinking.    

    dangerBlinkingSpeed = 6,
    dangerBlinkingColor = Color(1,0.25,0.25),


    hopUpSpeedX = 1,
    hopUpSpeedY = -4,


    unclimbableBlockIDs = table.map{},


    sounds = {
        SFX.open(Misc.resolveSoundFile("madeline/sounds/climbing_1")),
        SFX.open(Misc.resolveSoundFile("madeline/sounds/climbing_2")),
        SFX.open(Misc.resolveSoundFile("madeline/sounds/climbing_3")),
        SFX.open(Misc.resolveSoundFile("madeline/sounds/climbing_4")),
        SFX.open(Misc.resolveSoundFile("madeline/sounds/climbing_5")),
        SFX.open(Misc.resolveSoundFile("madeline/sounds/climbing_6")),
    },
}


madeline.wallJumpSettings = {
    slideSpeed = 1.5,

    leniency = 3.5,
    superWallJumpLeniency = 8.5,

    jumpSpeedX = 4,
    uncontrollableTimeAfterJump = 3,

    superWallJumpForce = 30,


    normalJumpSFX = 2,
    superWallJumpSFX = SFX.open(Misc.resolveSoundFile("madeline/sounds/jumpAssisted")),
}


madeline.deathSettings = {
    hitSFX = SFX.open(Misc.resolveSoundFile("madeline/sounds/hit")),
    deathSFX = SFX.open(Misc.resolveSoundFile("madeline/sounds/death")),
    respawnSFX = SFX.open(Misc.resolveSoundFile("madeline/sounds/respawn")),

    effectImage = Graphics.loadImageResolved("madeline/deathEffect.png"),
    effects = 8,

    effectsMaxDistance = 80,
    effectsMaxRadius = 12,

    explodeEffectsTime = 32,
    explodeTimeRespawn = 32,
    explodeTimeNormal = 96,
    preRespawnTime = 4,
    respawnTime = 24,

    initialSpeed = 8,
    slowDown = 0.925,
    minSpeed = 1,
}


madeline.debugMode = false


return madeline