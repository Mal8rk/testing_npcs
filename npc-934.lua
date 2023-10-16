local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 42,
	gfxwidth = 56,

	width = 32,
	height = 32,

	gfxoffsetx = 0,
	gfxoffsety = 6,

	frames = 6,
	framestyle = 1,
	framespeed = 2,

	speed = 1,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = false,

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
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
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=10,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

local flap = Misc.resolveSoundFile("skeet_skeet")

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC,"onTick")
end

function sampleNPC.onTick()
    if playSound ~= nil then
        -- Create the looping sound effect for all of the NPC's
        if idleSoundObj == nil then
			if playSound == 1 then
				if lunatime.tick() % 6 == 0 then
					SFX.play(flap)
				end
			else
				if lunatime.tick() % 18 == 0 then
					SFX.play(flap)
				end
			end
        end
    elseif idleSoundObj ~= nil then -- If the sound is still playing but there's no NPC's, stop it
        idleSoundObj:stop()
        idleSoundObj = nil
    end
    -- Clear playSound for the next tick
    playSound = nil
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
		data.moveTimer = data.moveTimer or 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0
	or v:mem(0x136, FIELD_BOOL)
	or v:mem(0x138, FIELD_WORD) > 0
	then
		return
	end

	if v.speedY > 0 then
		v.animationFrame = math.floor(data.moveTimer / 4) % 6
		flapSound = 4
	else
		v.animationFrame = math.floor(data.moveTimer / 2) % 6
		flapSound = nil
	end

	if (v.x + v.width > camera.x and v.x < camera.x + 800 and v.y + v.height > camera.y and v.y < camera.y + 600) then
		if v.speedY < 0 then
			playSound = 1
		else
			playSound = 2
		end
	end

	data.moveTimer = data.moveTimer + 1
	v.speedY = math.cos(data.moveTimer / 36) * 1.4
	v.speedX = 0.8 * v.direction

	if v.speedX < 0 or v.speedX > 0 then
		if lunatime.tick() % 20 == 0 then
			Effect.spawn(npcID, v.x + v.width * 0.5, v.y + v.height * 0.5, player.section)
		end
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

return sampleNPC