--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local effectconfig = require("game/effectconfig")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

local collectEffectID = (npcID)

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 48,
	gfxwidth = 48,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 48,
	height = 48,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 8,
	--Frameloop-related
	frames = 16,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 0,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	ignorethrownnpcs = true,
	notcointransformable = true,
	isinteractable=true,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCKill")
end

function effectconfig.onTick.TICK_ECOIN(v)
    if v.timer == v.lifetime-90 then
       Effect.spawn(752, v.x+25, v.y+25)
    end
	if RNG.randomInt(1,30) == 1 then
        local e = Effect.spawn(78, v.x + RNG.randomInt(0,v.width), v.y + RNG.randomInt(0,v.height))

        e.x = e.x - e.width *0.5
        e.y = e.y - e.height*0.5
    end
end

--Spawn effects and coins.
function sampleNPC.onDrawNPC(v)	
    --Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings

	if settings.style == 1 then
		v.animationFrame = math.floor(lunatime.tick() / 8) % 4 + 4
	elseif settings.style == 2 then
		v.animationFrame = math.floor(lunatime.tick() / 8) % 4 + 8
	elseif settings.style == 3 then 
		v.animationFrame = math.floor(lunatime.tick() / 8) % 4 + 12
	else 
		v.animationFrame = math.floor(lunatime.tick() / 8) % 4
	end
	
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});

	if RNG.randomInt(1,30) == 1 then
        local e = Effect.spawn(78, v.x + RNG.randomInt(0,v.width), v.y + RNG.randomInt(0,v.height))

        e.x = e.x - e.width *0.5
        e.y = e.y - e.height*0.5
    end
end

function sampleNPC.onNPCKill(eventObj, killedNPC)
	if killedNPC.id ~= npcID then return end

	local v = killedNPC
	local data = v.data
	local settings = data._settings

	if settings.style == nil then
		settings.style = 0
	end

    Effect.spawn(npcID, v.x, v.y+8, settings.style+1)
	SFX.play("collect.wav")
end
	

--Gotta return the library table!
return sampleNPC