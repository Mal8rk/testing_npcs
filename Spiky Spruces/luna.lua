local warpTransition = require('warpTransition')
local respawnRooms = require("respawnRooms")
local animationPal = require("animationPal")
local cutscenePal = require("cutscenePal")
local minHUD =  require("minHUD")

-- Turn the player into Mario, disable any costumes
Player.setCostume(CHARACTER_MARIO,nil,true)
player:transform(CHARACTER_MARIO)
player.powerup = PLAYER_BIG

local walkSpeed = Defines.player_walkspeed
local runSpeed = Defines.player_runspeed

local intro = cutscenePal.newScene("intro")


intro.canSkip = false

-- Creates the set of animations to use. The numbers represent which frames to use.

local animationSet = {
    idle = {1, defaultFrameX = 1},
    walk = {3,4,5,1,2, defaultFrameX = 2,frameDelay = 6},
    run = {6,7, defaultFrameX = 2,frameDelay = 4},

    jump = {1, defaultFrameX = 3},
    fall = {2,3, defaultFrameX = 3, frameDelay = 3, loops = false},

    duck = {2, defaultFrameX = 4},
    lookUp = {1, defaultFrameX = 4},
    slide = {3, defaultFrameX = 4},

    climb = {1,2,3,2, defaultFrameX = 5,frameDelay = 8},
}

local function spawnGruntActor(x,y)
    -- Spawn an actor.
    -- It is a "child" of the scene rather than a global one, so it will be removed when the scene ends.
    local actor = intro:spawnChildActor(x,y)

    -- Set up properties for the actor
    actor.image = Graphics.loadImageResolved("grunt_actor.png")
    actor.spriteOffset = vector(0,8)
    actor.spritePivotOffset = vector(0,-24)
    actor:setFrameSize(64,64) -- each frame is 56x54
    actor:setSize(32,48) -- hitbox size is 32x48

    actor.imageDirection = DIR_LEFT

    actor.useAutoFloor = true
    actor.gravity = 0.26
    actor.terminalVelocity = 8

    actor:setUpAnimator{
        animationSet = {
            idle = {1, defaultFrameX = 1},
            idleWithFood = {2, defaultFrameX = 1},

            walk = {1,2,3,4,5, defaultFrameX = 2,frameDelay = 6},

            pushed = {1, defaultFrameX = 3},
            sit = {2, defaultFrameX = 3},
            blink = {2,3, defaultFrameX = 3, frameDelay = 4},
            surprised = {4, defaultFrameX = 3},

            run = {1,2, defaultFrameX = 5, frameDelay = 5},
        },
        startAnimation = "idle",
    }

    -- Add it to the scene's data table (which is of course optional) and return.
    intro.data.gruntActor = actor

    return actor
end

local function spawnSnapJawActor(x,y)
    -- Spawn an actor.
    -- It is a "child" of the scene rather than a global one, so it will be removed when the scene ends.
    local actor = intro:spawnChildActor(x,y)

    -- Set up properties for the actor
    actor.image = Graphics.loadImageResolved("snap_jaw.png")
    actor.spriteOffset = vector(0,8)
    actor.spritePivotOffset = vector(0,-24)
    actor:setFrameSize(64,64) -- each frame is 56x54
    actor:setSize(32,32) -- hitbox size is 32x48

    actor.imageDirection = DIR_LEFT

    actor.useAutoFloor = true
    actor.gravity = 0.26
    actor.terminalVelocity = 8

    actor:setUpAnimator{
        animationSet = {
            idle = {1, defaultFrameY = 1},
            openMouth = {2, defaultFrameY = 1},
            chomp = {1,2, defaultFrameY = 1, frameDelay = 6},

            fall = {1,2, defaultFrameY = 2, frameDelay = 6},

            runWithFood = {1,2, defaultFrameY = 3, frameDelay = 4},
        },
        startAnimation = "idle",
    }

    -- Add it to the scene's data table (which is of course optional) and return.
    intro.data.snapjawActor = actor

    return actor
end

local function spawnAppleActor(x,y)
    -- Spawn an actor.
    -- It is a "child" of the scene rather than a global one, so it will be removed when the scene ends.
    local actor = intro:spawnChildActor(x,y)

    -- Set up properties for the actor
    actor.image = Graphics.loadImageResolved("tasty_treat.png")
    actor:setFrameSize(32,32) -- each frame is 16x16
    actor:setSize(16,16) -- hitbox size is 16x16

    actor.useAutoFloor = true
    actor.gravity = 0.26

    actor.priority = -46

    -- Set up an actor's animations, using the same arguments as animationPal.createAnimator.
    actor:setUpAnimator{
        animationSet = {
            idle = {1},
        },
        startAnimation = "idle",
    }

    -- Return it
    return actor
end


local function getWalkAnimationSpeed(p)
    return math.max(0.35,math.abs(p.speedX)/Defines.player_walkspeed)
end

local function findAnimation(p,animator)

    -- Pipes
    if p.forcedState == FORCEDSTATE_PIPE then
        local direction = animationPal.utils.getPipeDirection(p)

        if direction == 2 or direction == 4 then
            -- Sideways pipe
			return "walk",0.5
        else
            -- Vertical pipe
            return "idle"
		end
    end

    -- Other forced states

    -- Climbing
    if p.climbing then
        local speedX,speedY = animationPal.utils.getClimbingSpeed(p)
    
        if speedX ~= 0 or speedY < -0.1 then
            return "climb",2
        else
            return "climb",0
        end
    end


    if p:mem(0x12E,FIELD_BOOL) then -- ducking
        return "duck"
    end

    if p:mem(0x3C,FIELD_BOOL) then -- sliding
        return "slide"
    end

	-- Walking
    if animationPal.utils.isOnGroundAnimation(p) then
        -- GROUNDED ANIMATIONS --

        -- Walking
        if p.speedX ~= 0 and not animationPal.utils.isSlidingOnIce(p) then
            return "walk",getWalkAnimationSpeed(p)
        end

        if p.keys.up then
            return "lookUp"
        end

        return "idle"
    else
        -- AIR ANIMATIONS --

        if p.speedY < 0 then -- rising
            return "jump"
        else -- falling
            return "fall"
        end
    end
end

function intro:mainRoutineFunc()
    Routine.wait(0.25)

    local grunt = spawnGruntActor(-200064, -200096)
    grunt.direction = DIR_LEFT

    grunt:walkAndWait{
        goal = -199776,speed = 1,setDirection = false,
        walkAnimation = "walk",stopAnimation = "idleWithFood",
    }

    Routine.wait(1.4)

    local snapjaw = spawnSnapJawActor(-199776, -200640)
    snapjaw.direction = DIR_LEFT
    snapjaw:setAnimation("fall")

    SFX.play("Egg_fall.mp3")

    Routine.wait(1.3)

    SFX.play("tap_tap_hit.ogg")

    snapjaw:setAnimation("openMouth")
    snapjaw.speedX = 3.5
    snapjaw.speedY = -3

    grunt:setAnimation("pushed")
    grunt.speedX = -3.5
    grunt.speedY = -3

    local treat = spawnAppleActor(grunt.x+14, grunt.y)
    treat.speedY = -5

    Routine.wait(0.32)

    snapjaw:setAnimation("idle")
    snapjaw.speedX = 0

    grunt:setAnimation("sit")
    grunt.speedX = 0

    Routine.wait(1.5)

    grunt:setAnimation("blink")

    Routine.wait(1)

    snapjaw:setAnimation("chomp")
    grunt:setAnimation("sit")

    for i = 1,3 do
		SFX.play("piranha-plant.ogg")

		Routine.wait(0.3)
	end

    Routine.wait(0.32)

    snapjaw.speedX = -3.5

    Routine.wait(0.32)

    snapjaw:setAnimation("runWithFood")
    snapjaw.direction = DIR_RIGHT
    snapjaw.speedX = 5

    SFX.play(49)

    treat:remove()

    grunt:setAnimation("surprised")
    grunt.speedX = -3.5
    grunt.speedY = -3

    Routine.wait(0.32)

    grunt.speedX = 0

    Routine.wait(2)

    SFX.play(35)

    grunt:setAnimation("run")
    grunt.speedX = 4

    Routine.wait(4)
end

function intro:stopFunc()
    local warp = Layer.get("warp")

    warp:show(true)
end

function onStart()
    intro:start()
end


animationPal.registerCharacter(CHARACTER_MARIO,{
    findAnimationFunc = findAnimation,
    animationSet = animationSet,

    imageDirection = DIR_RIGHT,
    frameWidth = 100,
    frameHeight = 100,

    offset = vector(0,20),

    imagePathFormat = "grunt.png",
})