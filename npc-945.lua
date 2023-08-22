local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 62,
	gfxwidth = 86,

	width = 32,
	height = 48,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 54,
	framestyle = 1,
	framespeed = 6, 

	speed = 1,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
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
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
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

local STATE_WALK = 0
local STATE_PUNCH = 1
local STATE_KICK = 2
local STATE_UPKICK = 3
local STATE_SHOOT = 4
local STATE_BONKED = 5

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
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
		data.state = STATE_WALK
		data.timer = data.timer or 0
		data.animTimer = data.animTimer or 0
		data.moveTimer = data.moveTimer or 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		--Handling
	end

	data.moveTimer = data.moveTimer + 1
	data.timer = data.timer + 1

	if v.speedY > 0 or v.speedY < 0 then
	    v.animationFrame = 4
		v.speedX = 0
	end

	if data.state == STATE_WALK then
	    if v.collidesBlockBottom then
		    if data.moveTimer <= 8 then
				if data.moveTimer == 1 then v.speedX = 0 end
				if data.moveTimer == 8 then v.speedX = 6 * v.direction end
			    v.animationFrame = 0
			else
				v.animationFrame = math.floor(data.moveTimer / 4) % 4
				v.speedX = 0.25 * v.direction
				if data.moveTimer >= 16 then
					npcutils.faceNearestPlayer(v)
					data.moveTimer = 0
				end
		    end
	    end
		if data.timer >= 100 then
		    data.state = STATE_SHOOT
			data.timer = 0
			data.moveTimer = 0
			data.animTimer = 0
		end
	elseif data.state == STATE_PUNCH then
		if data.timer >= 16 then
		    data.state = STATE_WALK
			data.timer = 0
			data.moveTimer = 0
			data.animTimer = 0
	    elseif data.timer >= 1 then
		    data.animTimer = data.animTimer + 1
		    v.animationFrame = math.floor(data.animTimer / 3) % 5 + 5
		end
	elseif data.state == STATE_KICK then
		if data.timer >= 22 then
		    data.state = STATE_WALK
			data.timer = 0
			data.moveTimer = 0
			data.animTimer = 0
	    elseif data.timer >= 1 then
		    data.animTimer = data.animTimer + 1
		    v.animationFrame = math.floor(data.animTimer / 2) % 11 + 10
		end
	elseif data.state == STATE_UPKICK then
		if data.timer >= 26 then
		    data.state = STATE_WALK
			data.timer = 0
			data.moveTimer = 0
			data.animTimer = 0
	    elseif data.timer >= 1 then
		    data.animTimer = data.animTimer + 1
		    v.animationFrame = math.floor(data.animTimer / 2) % 14 + 21
		end
	elseif data.state == STATE_SHOOT then
		if data.timer >= 160 then
		    data.state = STATE_WALK
			data.timer = 0
			data.moveTimer = 0
			data.animTimer = 0
		elseif data.timer >= 104 then
            v.animationFrame = 43
		elseif data.timer >= 100 then
		    data.animTimer = data.animTimer + 1
            v.animationFrame = math.floor(data.animTimer / 2) % 3 + 41
		elseif data.timer >= 99 then
		    data.animTimer = 0
            v.animationFrame = math.floor(data.animTimer / 2) % 3 + 38
		elseif data.timer >= 8 then
		    SFX.play(9)
		    data.animTimer = data.animTimer + 1
            v.animationFrame = math.floor(data.animTimer / 2) % 3 + 38
	    elseif data.timer >= 1 then
		    data.animTimer = data.animTimer + 1
		    v.animationFrame = math.floor(data.animTimer / 3) % 3 + 35
		end
	elseif data.state == STATE_BONKED then
		if data.timer >= 270 then
		    data.state = STATE_WALK
			data.timer = 0
			data.animTimer = 0
			data.moveTimer = 0
		elseif data.timer >= 220 then
		    data.animTimer = 0
		    v.animationFrame = 51
		elseif data.timer >= 160 then
		    data.animTimer = data.animTimer + 1
		    v.animationFrame = math.floor(data.animTimer / 3) % 2 + 52
		elseif data.timer >= 150 then
		    v.animationFrame = math.floor(data.animTimer / 4) % 2 + 50
		elseif data.timer >= 16 then
		    data.animTimer = 0
		    v.animationFrame = 49
	    elseif data.timer >= 1 then
		    data.animTimer = data.animTimer + 1
		    v.animationFrame = math.floor(data.animTimer / 4) % 6 + 45
		end
	end

	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
    local data = v.data
    if v.id ~= npcID then return end
	eventObj.cancelled = true

    if culprit then
        if data.state == STATE_WALK and (reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP) and type(culprit) == "Player" then
		    data.state = STATE_BONKED
			data.timer = 0
			SFX.play(2)
			v.speedX = 0
		end
    end
end

function sampleNPC.onDrawNPC(v)
    local data = v.data

    Text.print(data.timer, 8, 8)
end

return sampleNPC