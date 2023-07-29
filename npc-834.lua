--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local barrel = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local barrelSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 40,
	gfxwidth = 40,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 40,
	height = 40,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 4,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	--speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	grabtop = false,
	grabside = false
}

--Applies NPC settings
npcManager.setNpcSettings(barrelSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		--[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Register events
function barrel.onInitAPI()
	npcManager.registerEvent(npcID, barrel, "onTickEndNPC")
	registerEvent(barrel, "onNPCKill")
end

function barrel.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local tbl = Block.SOLID .. Block.PLAYER
	collidingBlocks = Colliders.getColliding {
		a = v,
		b = tbl,
		btype = Colliders.BLOCK
	}

	if #collidingBlocks > 0 then --Not colliding with something
		v:kill()
	end
	if lunatime.tick() % 42 == 0 then 
		SFX.play("dkc2_kannon_barrel_fly.ogg")
	end
end

function barrel.onNPCKill(eventObj, v, reason)
	--Protect it from hits when these certain frames show
	if v.id ~= npcID then return end

	if reason ~= HARM_TYPE_OFFSCREEN then
		Animation.spawn(760,v.x,v.y)
		for i = -1,1 do
			if i ~= 0 then
				local debris1 = Animation.spawn(761,v.x,v.y)
				debris1.speedX = 2*i
				debris1.speedY = -4 - i
				local debris2 = Animation.spawn(762,v.x,v.y)
				debris2.speedX = 2*i
				debris2.speedY = -4 + i
			end
		end
		v:kill()
		SFX.play("Barrel_Break.wav")
		if v.ai1 and v.ai1 > 0 then
			NPC.spawn(v.ai1, v.x+20, v.y+20, v:mem(0x146,FIELD_WORD), false, true)
		end
	end
end

--Gotta return the library table!
return barrel