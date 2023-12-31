local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 56,
	gfxwidth = 42,

	width = 32,
	height = 48,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 11,
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
	cliffturn=true,
	rightRollFrame = 1,
	leftRollFrame = 0,
}

npcManager.setNpcSettings(sampleNPCSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

local STATE_RUNNING = 0
local STATE_NOHAT = 1

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
end

function sampleNPC.onTickNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		data.state = nil
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = data.state or STATE_RUNNING
		data.timer = data.timer or 0
		data.animTimer = data.animTimer or 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0
	or v:mem(0x136, FIELD_BOOL)
	or v:mem(0x138, FIELD_WORD) > 0
	then
		--Handling
	end
	
    data.timer = data.timer + 1

	if data.state == STATE_RUNNING then
		if data.timer < 96 then
			if data.timer % 47 == 0 then
				v.direction = -v.direction
			end
		end
		v.speedX = 1.5 * v.direction
		v.animationFrame = math.floor(data.timer / 5) % 2 + 9
		v.animationTimer = 0
    elseif data.state == STATE_NOHAT then
		if data.timer >= 160 then
		    data.state = STATE_RUNNING
			data.timer = 0
		elseif data.timer >= 110 then
			v.animationFrame = 8
			v.animationTimer = 0
		elseif data.timer >= 80 then
			v.animationFrame = 4
			v.animationTimer = 0
		elseif data.timer > 2 and v.collidesBlockBottom then
			v.animationFrame = math.floor(data.timer / 2) % 4 + 4
			v.animationTimer = 0
		elseif data.timer >= 17 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer / 5) % 3 + 1
			v.animationTimer = 0
		elseif data.timer == 1 then
			v.speedY = -4
			data.move = true
        end
		
		if data.timer > 1 and v.collidesBlockBottom then 
			v.speedX = 0 
			data.move = false 
		end
		
		if data.move then
			v.x = v.x + 2.5 * -v.direction
		end

		if v.speedY < 0 then
			v.animationFrame = 0
			v.animationTimer = 0
	    end
	end

	--If grabbed then turn it into a rolling grunt, more intended for MrDoubleA's playable.
	if v:mem(0x12C, FIELD_WORD) > 0 or (v:mem(0x138, FIELD_WORD) > 0 and (v:mem(0x138, FIELD_WORD) ~= 4 and v:mem(0x138, FIELD_WORD) ~= 5)) then
		if v.direction == DIR_LEFT then
			v.ai1 = NPC.config[v.id].leftRollFrame
		else
			v.ai1 = NPC.config[v.id].rightRollFrame
		end
		v:transform(npcID + 1)
	end

	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

return sampleNPC