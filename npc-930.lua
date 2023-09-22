local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 52,
	gfxwidth = 48,

	width = 32,
	height = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 5,
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



function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

function sampleNPC.onTickEndNPC(v)

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
	end

	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end


return sampleNPC