--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 32,
	gfxwidth = 32,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 2,
	--Frameloop-related
	frames = 4,
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

	value = 1,
	ignorethrownnpcs = true,
	notcointransformable = true,
	isinteractable=true,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	registerEvent(sampleNPC, "onNPCKill")
end

local coinsPointer = 0x00B2C5A8
local livesPointer = 0x00B2C5AC
local function addCoins(amount)
    mem(coinsPointer,FIELD_WORD,(mem(coinsPointer,FIELD_WORD)+amount))

    if mem(coinsPointer,FIELD_WORD) >= 100 then
        if mem(livesPointer,FIELD_FLOAT) < 99 then
            mem(livesPointer,FIELD_FLOAT,(mem(livesPointer,FIELD_FLOAT)+math.floor(mem(coinsPointer,FIELD_WORD)/100)))
            SFX.play(15)

            mem(coinsPointer,FIELD_WORD,(mem(coinsPointer,FIELD_WORD)%100))
        else
            mem(coinsPointer,FIELD_WORD,99)
        end
    end
end

--Spawn effects and coins.
function sampleNPC.onNPCKill(eventObj,v,reason,culprit)

    local config = NPC.config[v.id]

	if config.value then
		addCoins(config.value)
	end

	if v.id ~= npcID then return end
	Effect.spawn(765, v.x+16, v.y+16)
	SFX.play(14)
	end

--Gotta return the library table!
return sampleNPC