local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 80,
	gfxwidth = 64,

	width = 32,
	height = 64,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 9,
	framestyle = 1,
	framespeed = 4, 

	speed = 1,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = true, 

	nohurt=true,
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
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_FROMBELOW]=763,
		[HARM_TYPE_NPC]=763,
		[HARM_TYPE_PROJECTILE_USED]=763,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

local STATE_IDLE = 0
local STATE_SHOOT = 1
local spawnOffset = {}
spawnOffset[-1] = (sampleNPCSettings.width - 44)
spawnOffset[1] = (sampleNPCSettings.width - 50)

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
end

function effectconfig.onTick.TICK_BAZUKA(v)
    if v.timer == v.lifetime-1 then
        v.speedX = math.abs(v.speedX)*v.direction
    end

	if v.timer == v.lifetime-1 then
		SFX.play("Klomp die.wav")
	end

    v.animationFrame = math.min(v.frames-1,math.floor((v.lifetime-v.timer)/v.framespeed))
end

function sampleNPC.onTickNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = STATE_IDLE
		data.timer = 0
		data.shootTimer = 0
		data.animTimer = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		--Handling
	end

	data.timer = data.timer + 1
	if data.state == STATE_IDLE then
	    if v.direction == -1 then
            v.animationFrame = math.floor(lunatime.tick() / 12) % 2
			v.animationTimer = 0
		elseif v.direction == 1 then
		    v.animationFrame = math.floor(lunatime.tick() / 12) % 2 + 9
			v.animationTimer = 0
		end
		if data.timer > settings.delay then
		    data.state = STATE_SHOOT
		end
	end
	if data.state == STATE_SHOOT then
	    data.shootTimer = data.shootTimer + 1
		if data.shootTimer == 1 then
		    SFX.play("Barrel_blast.mp3")
		    local barrel = NPC.spawn(834, v.x + spawnOffset[v.direction], v.y - 32, player.section, false)
			barrel.speedY = -2.8
			barrel.spawnDirection = v.direction
			Effect.spawn(760, v.x + spawnOffset[v.direction], v.y - 32)
		elseif data.shootTimer > 3 and data.shootTimer <= 5 then
		    data.animTimer = data.animTimer + 1
            v.animationFrame = math.floor(data.animTimer / 1) % 8 + 1
			v.animationTimer = 0
		elseif data.shootTimer > 30 and data.shootTimer <= 74 then
            data.state = STATE_IDLE
			data.timer = 0
			data.shootTimer = 0
			data.animTimer = 0
		end
	end

	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

return sampleNPC