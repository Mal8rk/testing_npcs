local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 62,
	gfxwidth = 62,

	width = 32,
	height = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 4,
	framestyle = 1,
	framespeed = 8, 

	speed = 1,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
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
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=774,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=774,
		[HARM_TYPE_PROJECTILE_USED]=774,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=774,
		[HARM_TYPE_TAIL]=774,
		[HARM_TYPE_SPINJUMP]=774,
		--[HARM_TYPE_OFFSCREEN]=774,
		[HARM_TYPE_SWORD]=774,
	}
);

local STATE_WALK = 0
local STATE_CLIMBDOWN = 1
local STATE_DIVE = 2

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

function isNearPit(v)
	--This function either returns false, or returns the direction the npc should go to. numbers can still be used as booleans.
	local testblocks = Block.SOLID.. Block.SEMISOLID.. Block.PLAYER

	local centerbox = Colliders.Box(v.x, v.y, v.width, v.height + 10)
	local l = centerbox
	
	for _,centerbox in ipairs(
	  Colliders.getColliding{
		a = testblocks,
		b = l,
		btype = Colliders.BLOCK
	  }) do
		return false
	end
	
	
	return true
end

function sampleNPC.onTickEndNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		data.hasCollided = false
		data.state = nil
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = data.state or STATE_WALK
		data.timer = data.timer or 0
		data.hasCollided = false
		data.climbTimer = data.climbTimer or 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		NPC.config[v.id].nogravity = false
		v.animationFrame = 1

		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
		return
	end

    data.hasCollided = false
    for _, npc in NPC.iterateIntersecting(v.x, v.y, v.x + v.width, v.y + v.height) do
        if npc ~= v and NPC.config[npc.id].isvine then
            data.hasCollided = true
        end
    end


	if isNearPit(v) then
		data.climbTimer = data.climbTimer + 1
	end

	if v.collidesBlockBottom then
		data.climbTimer = 0
	end

	if data.state == STATE_WALK then
		v.animationFrame = math.floor(lunatime.tick() / 6) % 2
		v.speedX = 1.8 * v.direction
	    if data.hasCollided and data.climbTimer == 1 then
			data.state = STATE_CLIMBDOWN
			v.speedX = 0
		end
	elseif data.state == STATE_CLIMBDOWN then
		if data.hasCollided and not v.collidesBlockBottom then
			v.speedY = -Defines.npc_grav + 1.8
			v.animationFrame = math.floor(lunatime.tick() / 6) % 2 + 2
		end
	    if not data.hasCollided and not v.collidesBlockBottom then
			data.state = STATE_DIVE
		end

		if v.collidesBlockBottom then
			data.state = STATE_WALK
			v.speedY = 0
		end
	elseif data.state == STATE_DIVE then
		if data.hasCollided and not v.collidesBlockBottom then
			data.state = STATE_CLIMBDOWN
		end
		if not data.hasCollided and not v.collidesBlockBottom then
			v.animationFrame = math.floor(lunatime.tick() / 6) % 2 + 2
		end

		if v.collidesBlockBottom then
			data.state = STATE_WALK
			v.speedY = 0
		end
	end

	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

return sampleNPC