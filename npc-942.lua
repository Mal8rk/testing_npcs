local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 32,
	gfxwidth = 78,

	width = 32,
	height = 32,

	gfxoffsetx = -10,
	gfxoffsety = 0,

	frames = 4,
	framestyle = 1,
	framespeed = 8, 

	speed = 1,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,

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

local spawnOffsetLong = {}
spawnOffsetLong[-1] = (sampleNPCSettings.width - 96)
spawnOffsetLong[1] = (sampleNPCSettings.width)

local spawnOffsetShort = {}
spawnOffsetShort[-1] = (sampleNPCSettings.width - 70)
spawnOffsetShort[1] = (sampleNPCSettings.width)

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

function effectconfig.onTick.TICK_SPEAR(v)
	if v.speedY > 0 then
		v.rotation= 8 * -v.direction
	end
end

function sampleNPC.onTickEndNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		data.timer = nil
		return
	end

	if not data.initialized then
		data.initialized = true
		data.timer = data.timer or 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		--Handling
	end

	if settings.length == nil then
		settings.length = 0
	end

	v.friendly = true

	data.timer = data.timer + 1

    if data.timer == settings.resttime + 40 then
	    data.timer = 0
    elseif data.timer >= settings.resttime + 24 then
	    if settings.length == 1 and data.timer == settings.resttime + 32 then
		    local longSpear = NPC.spawn(npcID + 1, v.x + spawnOffsetLong[v.direction], v.y + 10, player.section, false)
		    longSpear.speedX = settings.xspeed * v.direction
			v.animationFrame = 3
		elseif settings.length == 0 and data.timer == settings.resttime + 24 then
			local spear = NPC.spawn(npcID + 2, v.x + spawnOffsetShort[v.direction], v.y, player.section, false)
		    spear.speedX = settings.xspeed * v.direction
			spear.direction = v.direction
			data.timer = 0
		end
	elseif data.timer >= settings.resttime then
	    v.animationFrame = math.floor(lunatime.tick() / 5) % 2 + 1
	elseif data.timer >= 1 then
		v.animationFrame = 0
	end

	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

return sampleNPC