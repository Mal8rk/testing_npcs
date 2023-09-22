local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

<<<<<<< HEAD
	gfxheight = 52,
	gfxwidth = 48,

	width = 32,
	height = 32,
=======
	gfxheight = 56,
	gfxwidth = 42,

	width = 32,
	height = 48,
>>>>>>> 93261c6854bebf645232dd8ae02ceb7e79a6dfa8

	gfxoffsetx = 0,
	gfxoffsety = 0,

<<<<<<< HEAD
	frames = 5,
	framestyle = 1,
	framespeed = 8, 

	speed = 1,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 
=======
	frames = 7,
	framestyle = 1,
	framespeed = 8,

	speed = 1,
	score = 0,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,
>>>>>>> 93261c6854bebf645232dd8ae02ceb7e79a6dfa8

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,

<<<<<<< HEAD
	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 

	grabside=false,
	grabtop=false,
=======
	jumphurt = true,
	spinjumpsafe = true,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	cliffturn=true,
	rightRollFrame = 1,
	leftRollFrame = 0,
>>>>>>> 93261c6854bebf645232dd8ae02ceb7e79a6dfa8
}

npcManager.setNpcSettings(sampleNPCSettings)

npcManager.registerHarmTypes(npcID,
	{
<<<<<<< HEAD
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



function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

function sampleNPC.onTickEndNPC(v)

=======
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
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
		[HARM_TYPE_NPC]=930,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickNPC(v)
>>>>>>> 93261c6854bebf645232dd8ae02ceb7e79a6dfa8
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.timer = data.timer or 0
	end

<<<<<<< HEAD
	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		data.timer = 0
		v.animationFrame = 4

		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
		return
	end

	data.timer = data.timer + 1

	if v.speedY < 0 then
		v.animationFrame = 3
	else
		v.animationFrame = 4
	end

	if data.timer > settings.resttime + 16 and v.collidesBlockBottom then
		data.timer = 0
		v.speedX = 0
	elseif data.timer >= settings.resttime + 14 then
		if data.timer == settings.resttime + 14 and v.collidesBlockBottom then 
			SFX.play("Jump.wav")
			v.speedY = -settings.yspeed 
			v.animationFrame = 3
		end
		if v.collidesBlockBottom then
			v.speedX = settings.xspeed * v.direction
		end
	elseif data.timer >= settings.resttime then
		v.animationFrame = 2
	elseif data.timer >= 1 then
		if data.timer == 2 then npcutils.faceNearestPlayer(v) end
		v.animationFrame = math.floor(data.timer / 8) % 2
=======
	if v:mem(0x12C, FIELD_WORD) > 0
	or v:mem(0x136, FIELD_BOOL)
	or v:mem(0x138, FIELD_WORD) > 0
	then
		--Handling
	end
	
    data.timer = data.timer + 1

	if settings.type == 0 then 
		v.speedX = 0.8 * v.direction
		v.animationFrame = math.floor(lunatime.tick() / 5) % 5
		v.animationTimer = 0
    elseif settings.type == 1 then
		v.speedX = 1.5 * v.direction
		v.animationFrame = math.floor(lunatime.tick() / 5) % 2 + 5
		v.animationTimer = 0
	end

	--If grabbed then turn it into a rolling grunt, more intended for MrDoubleA's playable.
	if v:mem(0x12C, FIELD_WORD) > 0 or (v:mem(0x138, FIELD_WORD) > 0 and (v:mem(0x138, FIELD_WORD) ~= 4 and v:mem(0x138, FIELD_WORD) ~= 5)) then
		if v.direction == DIR_LEFT then
			v.ai1 = NPC.config[v.id].leftRollFrame
		else
			v.ai1 = NPC.config[v.id].rightRollFrame
		end
		v:transform(npcID + 2)
>>>>>>> 93261c6854bebf645232dd8ae02ceb7e79a6dfa8
	end

	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end


<<<<<<< HEAD
=======
function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
    local data = v.data
    if v.id ~= npcID then return end

    if culprit then
        if (reason == HARM_TYPE_NPC or reason == HARM_TYPE_TAIL) and type(culprit) == "NPC" then
            local npc = NPC.spawn(931, v.x, v.y, player.section)
			npc.direction = v.direction
			npc.data.state = 1
		end
    else
        for _,p in ipairs(NPC.getIntersecting(v.x - 12, v.y - 12, v.x + v.width + 12, v.y + v.height + 12)) do
            if p.id == 953 then
				local npc = NPC.spawn(931, v.x, v.y, player.section)
				npc.direction = v.direction
				npc.data.state = 1
            end
        end
    end
end

>>>>>>> 93261c6854bebf645232dd8ae02ceb7e79a6dfa8
return sampleNPC