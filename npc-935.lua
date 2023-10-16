local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local rad, sin, cos, pi = math.rad, math.sin, math.cos, math.pi

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 42,
	gfxwidth = 56,

	width = 32,
	height = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 7,
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
	staticdirection=true,
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

local STATE_REST = 0
local STATE_FLY = 1
local STATE_CIRCLE = 2

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

local function fangMovement(v)
	local data = v.data

	if v.speedY > 0 then
		v.animationFrame = math.floor(lunatime.tick() / 4) % 6 + 1
		flapSound = 4
	else
		v.animationFrame = math.floor(lunatime.tick() / 2) % 6 + 1
		flapSound = nil
	end

	if (v.x + v.width > camera.x and v.x < camera.x + 800 and v.y + v.height > camera.y and v.y < camera.y + 600) then
		if v.speedY < 0 then
			playSound = 1
		else
			playSound = 2
		end
	end

	if v.speedX < 0 or v.speedX > 0 then
		if lunatime.tick() % 20 == 0 then
			Effect.spawn(npcID-1, v.x + v.width * 0.5, v.y + v.height * 0.5, player.section)
		end
	end
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
		data.state = data.state or STATE_REST
		data.activateBox = data.activateBox or Colliders.Box(v.x, v.y, v.width, v.height)
		data.circleBox = data.circleBox or Colliders.Box(v.x, v.y, v.width, v.height)
		data.timer = data.timer or 0
	end

	data.activateBox.width = v.width + 500
	data.activateBox.height = v.height + 400

	data.activateBox.x = v.x - 250
	data.activateBox.y = v.y

	data.circleBox.width = v.width + 800
	data.circleBox.height = v.height

	data.circleBox.x = v.x - 400
	data.circleBox.y = v.y - 32

	if v:mem(0x12C, FIELD_WORD) > 0
	or v:mem(0x136, FIELD_BOOL)
	or v:mem(0x138, FIELD_WORD) > 0
	then
		v.animationFrame = math.floor(lunatime.tick() / 4) % 6 + 1

		v.animationFrame = npcutils.getFrameByFramestyle(v, {
			frame = data.frame,
			frames = sampleNPCSettings.frames
		});
		return
	end

	if data.state == STATE_REST then
		v.animationFrame = 0
		v.speedY = 0
		v.speedX = 0

		if Colliders.collide(player, data.activateBox) and not v.friendly then
			data.state = STATE_FLY
		end
	elseif data.state == STATE_FLY then
		fangMovement(v)
		v.speedY = 1
		v.speedX = 0.4 * v.direction

		if Colliders.collide(player, data.circleBox) and not v.friendly then
			data.state = STATE_CIRCLE
		end
	elseif data.state == STATE_CIRCLE then
		fangMovement(v)
		data.w = 1 * pi/65
		data.timer = data.timer + 1

		if data.timer > 130 then
			v.speedY = 0
			v.speedX = 2 * v.direction
		elseif data.timer >= 1 then
			v.speedX = 40 * -data.w * cos(data.w*data.timer)
			v.speedY = 40 * -data.w * sin(data.w*data.timer)
		end
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

return sampleNPC