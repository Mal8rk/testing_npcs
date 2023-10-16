local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 64,
	gfxwidth = 122,

	width = 64,
	height = 48,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 10,
	framestyle = 1,
	framespeed = 8,

	speed = 1,

	npcblock = false,
	npcblocktop = false,
	playerblock = false,
	playerblocktop = true,

	nohurt=true,
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
	ignorethrownnpcs=true,
	enableChargeAttack=true,

	destroyblocktable = {90, 4, 188, 60, 293, 667, 457, 666, 686, 667, 668, 526, 226}
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

--Most of the code's from MegaDood's Clown Car Tank NPC

local STATE_IDLE = 0
local STATE_RIDDEN = 1
local STATE_RAMMING = 2
local STATE_CHARGING = 3
local STATE_CHARGE = 4
local STATE_HURT = 5

local playerRiding = 0

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
end

local function playerRideOn(v)
	local data = v.data

	player.frame = 30
	player.direction = v.direction
	player.x = v.x + v.width/3.2
	player.y = v.y - 38
	player:mem(0x50, FIELD_BOOL, false)
	player:mem(0x56, FIELD_WORD, 0)

	if player.keys.left or player.keys.right then
		if player.keys.left then
			if v.speedX > -4.5 then
				v.speedX = v.speedX - 0.25
			else
				v.speedX = -4.5
			end
		elseif player.keys.right then
			if v.speedX < 4.5 then
				v.speedX = v.speedX + 0.25
			else
				v.speedX = 4.5
			end
		end
	else
		if math.abs(v.speedX) > 0.1 then
			v.speedX = v.speedX - 0.1 * v.direction
		else
			v.speedX = 0
		end
	end
end

local function playerRideOnCharged(v)
	local data = v.data

	player.frame = 30
	player.direction = v.direction
	player.x = v.x + v.width/3.2
	player.y = v.y - 38
	player:mem(0x50, FIELD_BOOL, false)
	player:mem(0x56, FIELD_WORD, 0)
end

function sampleNPC.onTickEndNPC(v)
	if Defines.levelFreeze then return end
	
	local data = v.data

	local config = NPC.config[v.id]

	if data.frameSpeed == nil then
		data.frameSpeed = 0
		data.timer = 0
	end
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.chargeTimer = 0
		data.state = STATE_IDLE
		data.timer = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0
	or v:mem(0x136, FIELD_BOOL)
	or v:mem(0x138, FIELD_WORD) > 0
	then
		--Handling
	end

	data.timer = data.timer + 1

	local collBox = Colliders.Box(v.x - (v.width * 1), v.y - (v.height * 1), v.width * 1.4, v.height)
	collBox.x = v.x - 14
	collBox.y = v.y + v.height * 0.1
	
	for _,n in ipairs(NPC.get()) do
		if Colliders.collide(n,collBox) and not (data.state == STATE_IDLE or data.state == STATE_HURT or data.state == STATE_CHARGING or data.state == STATE_CHARGE) then
			if n.idx ~= v.idx and n:mem(0x138, FIELD_WORD) == 0 then
				if (NPC.config[n.id].isinteractable or NPC.config[n.id].iscoin) then
					n.x = playerRiding.x
					n.y = playerRiding.y
				elseif not n.friendly and not n.isHidden and v.speedX ~= 0 and NPC.HITTABLE_MAP[n.id] then
					n:kill(HARM_TYPE_NPC)

					local e = Effect.spawn(75,n.x + n.width*0.5 + n.width*0.5*math.sign(n.direction),v.y + v.height*0.5)

					e.x = e.x - e.width *0.5
					e.y = e.y - e.height*0.5

					data.state = STATE_RAMMING
					data.timer = 0
				end
			end
		end
	end

	local isCharged = (data.chargeTimer >= 54)

	if data.state == STATE_IDLE then
		v.animationFrame = math.floor(lunatime.tick() / 10) % 4
		v.speedX = 0

		if Player.getNearest(v.x,v.y).standingNPC == v and v.ai1 <= 0 and Player.getNearest(v.x,v.y).mount == 0 then
			data.state = STATE_RIDDEN
		end
	elseif data.state == STATE_RIDDEN then
		if Player.getNearest(v.x,v.y) == player then
			playerRiding = player
		else
			playerRiding = player2
		end

		playerRideOn(v)

		if playerRiding.keys.jump and v.collidesBlockBottom then
			v.speedY = -8
		end

		if playerRiding.keys.altJump and v.collidesBlockBottom then
			data.state = STATE_IDLE
			playerRiding.speedY = -2
			playerRiding.speedX = 0
		end

		if v.collidesBlockLeft or v.collidesBlockRight then
			v.animationFrame = 5
			v.speedX = 0
		end

		if v.collidesBlockBottom then
			if v.speedX ~= 0 then
				v.animationFrame = math.floor((data.frameSpeed * v.direction) / 18) % 5 + 4
				data.frameSpeed = data.frameSpeed + math.floor(v.speedX)
			else
				data.frameSpeed = 0
				v.animationFrame = math.floor(lunatime.tick() / 10) % 4
			end
		else
			v.animationFrame = 5
		end

		if NPC.config[v.id].enableChargeAttack then
			if playerRiding.keys.run == KEYS_PRESSED and v.collidesBlockBottom and v.speedX == 0 then
				data.state = STATE_CHARGING
			end
		end
	elseif data.state == STATE_RAMMING then
		if data.timer > 11 and v.collidesBlockBottom then
			data.state = STATE_RIDDEN
			data.timer = 0
		elseif data.timer >= 10 then
		    v.animationFrame = 5
			if data.timer == 10 then v.speedY = -2 end
	    elseif data.timer >= 1 then
		    v.animationFrame = 9
		end

		playerRideOn(v)
	elseif data.state == STATE_CHARGING then
		if Player.getNearest(v.x,v.y) == player then
			playerRiding = player
		else
			playerRiding = player2
		end

		if playerRiding.keys.run and v.collidesBlockBottom then
			v.animationFrame = math.floor(lunatime.tick() / 7) % 5 + 4
			data.chargeTimer = data.chargeTimer + 1

			if isCharged then
				v.animationFrame = math.floor(lunatime.tick() / 3) % 5 + 4
			end
		else
			data.state = STATE_RIDDEN
			data.chargeTimer = 0

			if isCharged then
				data.state = STATE_CHARGE
				data.chargeTimer = 0
			end
		end

		playerRideOnCharged(v)
	elseif data.state == STATE_CHARGE then
		v.animationFrame = math.floor(lunatime.tick() / 3) % 5 + 4
		v.speedX = 9 * v.direction
		playerRideOnCharged(v)

		for _,n in ipairs(NPC.get()) do
			if Colliders.collide(n,collBox) then
				if n.idx ~= v.idx and n:mem(0x138, FIELD_WORD) == 0 then
					if (NPC.config[n.id].isinteractable or NPC.config[n.id].iscoin) then
						n.x = playerRiding.x
						n.y = playerRiding.y
					elseif not n.friendly and not n.isHidden and v.speedX ~= 0 and NPC.HITTABLE_MAP[n.id] then
						n:kill(HARM_TYPE_NPC)

						local e = Effect.spawn(75,n.x + n.width*0.5 + n.width*0.5*math.sign(n.direction),v.y + v.height*0.5)

						e.x = e.x - e.width *0.5
						e.y = e.y - e.height*0.5
					end
				end
			end
		end
	
		local list = Colliders.getColliding{
		a = collBox,
		b = sampleNPCSettings.destroyblocktable,
		btype = Colliders.BLOCK,
		filter = function(other)
			if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
				return false
			end
			return true
		end
		}
		for _,b in ipairs(list) do
			b:remove(true)
		end

		if playerRiding.keys.jump and v.collidesBlockBottom then
			v.speedY = -8
		end

		if playerRiding.keys.down and v.collidesBlockBottom then
			data.state = STATE_RIDDEN
			v.speedX = 0
		end

		if v.collidesBlockLeft or v.collidesBlockRight then
			data.state = STATE_RIDDEN
			v.speedX = 0
		end
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

return sampleNPC