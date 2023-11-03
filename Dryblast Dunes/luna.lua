local animationPal = require("animationPal")
local cutscenePal = require("cutscenePal")

local minHUD = require("minHUD")
local warpTransition = require("warpTransition")
local respawnRooms = require("respawnRooms")

local intro = cutscenePal.newScene("intro")

intro.canSkip = false
intro.hasBars = false
intro.disablesHUD = false

function onStart()
	Player.setCostume(CHARACTER_MARIO, "SMW-Mario")
	player.powerup = PLAYER_BIG

	if not Checkpoint.getActive() then
		intro:start()
	end
end

local function spawnBarrelActor(x,y)
    local actor = intro:spawnChildActor(x,y)

    actor.image = Graphics.loadImageResolved("barrel.png")
    actor:setFrameSize(44,40)
    actor:setSize(40,40)

    actor.priority = -46

    actor:setUpAnimator{
        animationSet = {
            idle = {1},
			shaking = {2,3, frameDelay = 2},
        },
        startAnimation = "idle",
    }

    return actor
end

function intro:mainRoutineFunc()
	player.forcedState = 8
	local barrel = spawnBarrelActor(-199900, -200180)

	Routine.wait(1)
	barrel:setAnimation("shaking")

	Routine.wait(1)
	Audio.MusicChange(0, "Desert Scorcher - Kirby Mass Attack.ogg")

	player.forcedState = 0
	player.x = barrel.x + 6
	player.y = barrel.y
	player.speedY = -6

	Animation.spawn(760,barrel.x,barrel.y)
	for i = -1,1 do
		if i ~= 0 then
			local debris1 = Animation.spawn(761,barrel.x,barrel.y)
			debris1.speedX = 2*i
			debris1.speedY = -4 - i
			local debris2 = Animation.spawn(762,barrel.x,barrel.y)
			debris2.speedX = 2*i
			debris2.speedY = -4 + i
		end
	end
	SFX.play("Barrel_Break.wav")
end

function intro:stopFunc()
	player.forcedState = 0
end