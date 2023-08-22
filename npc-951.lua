--[[

    Celeste Madeline Playable
    by MrDoubleA

	See madeline.lua for more

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local distortionEffects = require("distortionEffects")
local madeline = require("madeline")


local dashDiamond = {}
local npcID = NPC_ID

local touuchedEffectID = npcID


local dashDiamondSettings = {
	id = npcID,
	
	gfxwidth = 32,
	gfxheight = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,
	
	width = 32,
	height = 32,
	
	frames = 7,
	framestyle = 0,
	framespeed = 8,
	
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt = true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = true,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	ignorethrownnpcs = true,


	touchedFrames = 1,
	touuchedEffectID = touuchedEffectID,

	regenerateTime = 115,
	
	lightradius = 128,
	lightbrightness = 2,
	lightoffsetx = 0,
	lightoffsety = 0,
	lightcolor = Color.fromHexRGB(0x82FF7B),
	lightflicker = true,

	touchSounds = {
		SFX.open(Misc.resolveSoundFile("madeline/sounds/dashDiamond_touch_1")),
		SFX.open(Misc.resolveSoundFile("madeline/sounds/dashDiamond_touch_2")),
		SFX.open(Misc.resolveSoundFile("madeline/sounds/dashDiamond_touch_3")),
	},
	returnSounds = {
		SFX.open(Misc.resolveSoundFile("madeline/sounds/dashDiamond_return_1")),
		SFX.open(Misc.resolveSoundFile("madeline/sounds/dashDiamond_return_2")),
		SFX.open(Misc.resolveSoundFile("madeline/sounds/dashDiamond_return_3")),
	},
}

npcManager.setNpcSettings(dashDiamondSettings)
npcManager.registerHarmTypes(npcID,{HARM_TYPE_OFFSCREEN},{})



local function getFrame(v,data,config)
	local idleFrames = (config.frames-config.touchedFrames)

	local frames = 1
	local frameOffset = 0

	if data.regenerateTimer > 0 then
		frames = config.touchedFrames
		frameOffset = idleFrames
	else
		frames = idleFrames
		frameOffset = 0
	end


	local frame = (math.floor(data.animationTimer/config.framespeed)%frames)+frameOffset
	frame = npcutils.getFrameByFramestyle(v,{frame = frame})


	data.animationTimer = data.animationTimer + 1

	return frame
end



function dashDiamond.onInitAPI()
	npcManager.registerEvent(npcID, dashDiamond, "onTickEndNPC")
end

function dashDiamond.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local config = NPC.config[v.id]
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.regenerateTimer = nil
		return
	end

	if not data.regenerateTimer then
		data.regenerateTimer = 0
		data.animationTimer = 0

		data.floatTimer = 0
	end


	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		v.animationFrame = getFrame(v,data,config)
		return
	end
	
	
	if data.regenerateTimer > 0 then
		data.regenerateTimer = data.regenerateTimer + 1

		if data.regenerateTimer >= config.regenerateTime then
			data.regenerateTimer = 0
			data.animationTimer = 0

			SFX.play(RNG.irandomEntry(config.returnSounds),0.75)
			distortionEffects.create{x = v.x+(v.width/2),y = v.y+(v.height/2)}
		end
	else
		if player.character == CHARACTER_MADELINE and Colliders.collide(v,player) then
			local refilled = madeline.refillDashes()

			if refilled then
				madeline.refillStamina()

				SFX.play(RNG.irandomEntry(config.touchSounds),0.75)
				data.regenerateTimer = 1

				data.animationTimer = 0
				data.floatTimer = 0

				--Misc.RumbleSelectedController(1,100,1)
				Defines.earthquake = 5

				if config.touuchedEffectID then
					local e = Effect.spawn(config.touuchedEffectID,v.x+(v.width/2),v.y+(v.height/2))

					e.x = e.x-(e.width /2)
					e.y = e.y-(e.height/2)
				end
			end
		end
	end


	-- Movement
	if data.regenerateTimer > 0 then
		v.speedY = (v.spawnY-v.y)
	else
		data.floatTimer = data.floatTimer + 1
		v.speedY = math.cos(data.floatTimer/32)*0.1
	end


	v.animationFrame = getFrame(v,data,config)

	npcutils.applyLayerMovement(v)
end


return dashDiamond