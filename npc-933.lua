local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 108,
	gfxwidth = 130,

	width = 64,
	height = 64,

	gfxoffsetx = 0,
	gfxoffsety = 12,
	foreground = 1,

	frames = 10,
	framestyle = 1,
	framespeed = 6, 

	speed = 1,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = true,

	jumphurt = true, 
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
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=774,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		[HARM_TYPE_TAIL]=774,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=774,
	}
);

local STATE_FLYING = 0
local STATE_EATING = 1
local STATE_SPAT = 2

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

local colBox = Colliders.Box(0,0,0,0)

function sampleNPC.onTickEndNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		data.state = nil
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = data.state or STATE_FLYING
		data.shake = 0
		data.timer = data.timer or 0
		data.ySpeedhitbox = Colliders.Box(v.x, v.y, v.width, v.height)
		data.turnTimer = 0
		data.hasEatenPlayer = false

		data.targetPlayers = {
		targetplr,
		targetplr2,
		}
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		--Handling
	end

	if data.timer > 0 then
		data.timer = data.timer + 1
	end

	colBox.width = 72
	colBox.height = 82
	
	colBox.x = v.x-5
	colBox.y = v.y-6

	colBox:Debug(false)
	data.ySpeedhitbox:Debug(false)

	data.ySpeedhitbox.x = v.x
	data.ySpeedhitbox.y = v.y

	data.turnTimer = data.turnTimer + 1

	if data.state == STATE_FLYING then
		v.speedY = math.cos(lunatime.tick() / 10) * 0.8

		if math.abs(player.x - v.x) <= 96 and math.abs(player.y - v.y) <= 96 then
			v.animationFrame = math.floor(lunatime.tick() / 5.5) % 3 + 7
		else
			v.animationFrame = math.floor(lunatime.tick() / 5.5) % 7
		end

		v.speedX = 0.9 * v.direction
		if data.turnTimer >= 200 then
		    v.direction = -v.direction
			data.turnTimer = 0
	    end

		for _,p in ipairs(Player.get()) do
			if Colliders.collide(p, colBox) and (p.forcedState == 0 and p.deathTimer == 0) then
				data.state = STATE_EATING
				data.timer = 0
				data.turnTimer = 0
				data.hasEatenPlayer = true

				if data.timer == 0 then
					data.timer = data.timer + 1
				end
			else
				data.timer = 0
			end
		end
	elseif data.state == STATE_EATING then
		v.speedX = 0
		v.speedY = math.cos(lunatime.tick() / 10) * 0.8
		v.animationFrame = math.floor(lunatime.tick() / 5.5) % 7

		if player ~= nil then
			if data.timer > 1 then
				player.x = v.x
				player.y = v.y
				player.forcedState = 8
			end
	
			if data.timer > 72 then
				if data.shake == 1 then
					data.shake = 0
					v.x = v.x + 4
				else
					data.shake = 1
					v.x = v.x - 4
				end
			end
	
								
			if data.timer > 121 then
				player.forcedState = 0
				player.x = v.x + 16
				player.y = v.y + 68

				data.state = STATE_SPAT
				data.turnTimer = 0
			end
		end
	else
		v.animationFrame = math.floor(lunatime.tick() / 5.5) % 3 + 7
		v.speedY = math.cos(lunatime.tick() / 10) * 0.8

		if Colliders.collide(player, data.ySpeedhitbox) then
			if player.speedY < 0 then
				player.speedY = 5.5
				player.speedX = 0
			end
		end

		if data.timer > 122 then
			if data.timer == 123 then player:harm() end
		end

		if data.timer >= 196 then
			data.state = STATE_FLYING
			data.timer = 0
			data.turnTimer = 0
		end
	end

	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

return sampleNPC