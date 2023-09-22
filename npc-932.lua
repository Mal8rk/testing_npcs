local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 72,
	gfxwidth = 122,

	width = 64,
	height = 64,

	gfxoffsetx = 0,
	gfxoffsety = 6,

	frames = 25,
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
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,

	jumphurt = true, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 

	grabside=false,
	grabtop=false,
	staticdirection=true,
}

npcManager.setNpcSettings(sampleNPCSettings)

npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local STATE_IDLE = 0
local STATE_RAM = 1
local STATE_TURN = 2
local STATE_HURT = 3

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

--Thanks to MegaDood for the chasing code

function sampleNPC.onTickEndNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
	local p = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		data.state = nil
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = data.state or STATE_IDLE
		data.timer = data.timer or 0
		data.animTimer = 0
		data.xAccel = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		--Handling
	end

	data.timer = data.timer + 1
	data.animTimer = data.animTimer + 1

	if data.state == STATE_IDLE then
		v.animationFrame =  math.floor(data.timer / 6) % 8

		if math.abs(p.x - v.x) <= 256 and math.abs(p.y - v.y) <= 128 then
			npcutils.faceNearestPlayer(v)
			data.state = STATE_RAM
			data.timer = 0
		end
	elseif data.state == STATE_RAM then
		v.animationFrame =  math.floor(lunatime.tick() / 5) % 4 + 8

		v.speedX = math.clamp(v.speedX + 0.1 * v.direction, -4.5, 4.5)

		if p.x > v.x and v.direction == DIR_LEFT then
			data.state = STATE_TURN
			data.timer = 0
		elseif p.x < v.x and v.direction == DIR_RIGHT then
			data.state = STATE_TURN
			data.timer = 0
		end

		if v.collidesBlockLeft or v.collidesBlockRight then
			data.state = STATE_HURT
			data.timer = 0
		end

	elseif data.state == STATE_TURN then
		v.animationFrame =  math.floor((data.timer - 1) / 4) % 9 + 12

		if v.collidesBlockBottom then
            if v.speedX > 0 then
                v.speedX = math.max(0,v.speedX - 0.15)
            elseif v.speedX < 0 then
                v.speedX = math.min(0,v.speedX + 0.15)
            end
        else
            if v.speedX > 0 then
                v.speedX = math.max(0,v.speedX - 0.15)
            elseif v.speedX < 0 then
                v.speedX = math.min(0,v.speedX + 0.15)
            end
		end

		if data.timer >= 34 then
			data.state = STATE_RAM
			v.direction = -v.direction
			v.animationFrame = 0
			data.timer = 0
		end
	elseif data.state == STATE_HURT then

		if v.collidesBlockBottom then
            if v.speedX > 0 then
                v.speedX = math.max(0,v.speedX - 0.15)
            elseif v.speedX < 0 then
                v.speedX = math.min(0,v.speedX + 0.15)
            end
        else
            if v.speedX > 0 then
                v.speedX = math.max(0,v.speedX - 0.15)
            elseif v.speedX < 0 then
                v.speedX = math.min(0,v.speedX + 0.15)
            end
		end

	    if data.timer >= 78 then
		    data.state = STATE_IDLE
		    data.timer = 0
	    elseif data.timer >= 32 then
		    v.animationFrame =  math.floor(data.timer / 8) % 2 + 23
		elseif data.timer >= 1 then
			v.animationFrame =  math.floor(data.timer / 18) % 2 + 21
			if data.timer == 1 then SFX.play("Pow.wav") end
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
        if reason == HARM_TYPE_NPC and type(culprit) == "NPC" then
			Effect.spawn(774, v.x-40, v.y-40)
		    data.state = STATE_HURT
			data.timer = 0
			data.animTimer = 0
			v.speedX = 0
		end
    else
        for _,p in ipairs(NPC.getIntersecting(v.x - 12, v.y - 12, v.x + v.width + 12, v.y + v.height + 12)) do
            if p.id == 953 then
                p:kill(HARM_TYPE_VANISH)
				Effect.spawn(774, v.x-40, v.y-40)
				data.state = STATE_HURT
				data.timer = 0
				data.animTimer = 0
				v.speedX = 0
            end
        end
    end
end

return sampleNPC