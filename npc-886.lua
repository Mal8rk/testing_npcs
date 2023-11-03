local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 32,
	gfxwidth = 32,

	width = 32,
	height = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 3,
	framestyle = 1,
	framespeed = 1, 

	speed = 1,

	npcblock = false,
	npcblocktop = true, 
	playerblock = false,
	playerblocktop = true, 

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 

	grabside=false,
	grabtop=false,
}

npcManager.setNpcSettings(sampleNPCSettings)

npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
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

local STATE_GROW = 0
local STATE_IDLE = 1

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

function sampleNPC.onTickEndNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = STATE_GROW
		data.timer = 0
		data.growTimer = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		--Handling
	end

	v.despawnTimer = 180
    v:mem(0x124,FIELD_BOOL,true)
	data.timer = data.timer + 1

	if data.state == STATE_GROW then
        if data.timer >= 2 then
            data.state = STATE_IDLE
            data.timer = 0
        end
    end
	if data.state == STATE_IDLE then
	    data.growTimer = data.growTimer + 1
		v.animationFrame = 2
		if data.growTimer == 1 then
		    local pole = NPC.spawn(887, v.x + 32, v.y)
	        pole.direction = -1
	        pole.spawnDirection = v.direction
		end
		if data.growTimer == 2 then
		    local pole = NPC.spawn(887, v.x + 64, v.y)
	        pole.direction = -1
	        pole.spawnDirection = v.direction
		end
		if data.growTimer == 4 then
		    local pole = NPC.spawn(887, v.x + 96, v.y)
	        pole.direction = -1
	        pole.spawnDirection = v.direction
		end
		if data.growTimer == 6 then
		    local pole = NPC.spawn(887, v.x + 128, v.y)
	        pole.direction = -1
	        pole.spawnDirection = v.direction
		end
		if data.growTimer == 8 then
		    local pole = NPC.spawn(888, v.x + 160, v.y)
	        pole.direction = -1
	        pole.spawnDirection = v.direction
		end
	end

	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

return sampleNPC