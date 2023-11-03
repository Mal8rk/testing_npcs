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
	gfxheight = 40,
	gfxwidth = 40,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 40,
	height = 40,
	--Frameloop-related
	frames = 4,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
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
	isinteractable=true,
	notcointransformable=true,
	ignorethrownnpcs=true,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onPostNPCKill")
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	v.animationFrame = v.data._settings.style
end

function sampleNPC.onPostNPCKill(v,reason)
	if v.id ~= npcID then return end
	local data = v.data
	for i = -1,1 do
		if i ~= 0 then
			local debris1 = Animation.spawn(761,v.x,v.y)
			debris1.speedX = 2*i
			debris1.speedY = -4
		end
	end
	Animation.spawn(760,v.x,v.y)
	SFX.play("Barrel break DKC2.wav")
	if v.data._settings.style == 0 or v.data._settings.style == 2 then
		SFX.play("+ barrel.wav")
	else
		SFX.play("- barrel.wav")
	end
end

--Gotta return the library table!
return sampleNPC