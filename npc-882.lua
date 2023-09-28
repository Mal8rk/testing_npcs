local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 64,
	gfxwidth = 96,

	width = 96,
	height = 64,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 5,
	framestyle = 1,
	framespeed = 8,

	speed = 1,

	npcblock = true,
	npcblocktop = true,
	playerblock = true,
	playerblocktop = true,

	nohurt=true,
	nogravity = true,
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
	staticdirection=true,

	destroyblocktable = {90, 4, 188, 60, 226, 293, 667, 457, 666, 686, 668, 526, 694}
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

local STATE_IDLE = 0
local STATE_CHASE = 1
local STATE_DROP = 2
local STATE_RISE = 3

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
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
		data.chasebox = data.chasebox or Colliders.Box(0, 0, 1, 1)
		data.slambox = data.slambox or Colliders.Box(0, 0, 1, 1)
		data.attackCollider = data.attackCollider or Colliders.Box(v.x, v.y, v.width, v.height)
		data.hitBlockCollider = data.hitBlockCollider or Colliders.Box(v.x, v.y, v.width, v.height)
		data.state = data.state or STATE_IDLE
		data.timer = data.timer or 0
		data.shake = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0
	or v:mem(0x136, FIELD_BOOL)
	or v:mem(0x138, FIELD_WORD) > 0
	then
		v.spawnY = v.y
		return
	end

	data.chasebox.width = v.width + 96
	data.chasebox.height = v.height + 300

	data.chasebox.x = v.x - 48
	data.chasebox.y = v.y

	data.slambox.width = v.width
	data.slambox.height = v.height + 300

	data.slambox.x = v.x
	data.slambox.y = v.y

	data.attackCollider.x = v.x
	data.attackCollider.y = v.y + 1

	data.hitBlockCollider.x = v.x
	data.hitBlockCollider.y = v.y + 1

	data.timer = data.timer + 1

	if data.state == STATE_IDLE then
		v.animationFrame = 0
		v.speedX = 0.9 * v.direction
		v.speedY = 0

		if v.collidesBlockLeft or v.collidesBlockRight then
			v.direction = -v.direction
		end

		if Colliders.collide(player, data.chasebox) then
			npcutils.faceNearestPlayer(v)
			data.state = STATE_CHASE
			data.timer = 0
		end
	elseif data.state == STATE_CHASE then
		if Colliders.collide(player, data.chasebox) then
			v.animationFrame = 1
			v.speedX = 2 * v.direction
		else
			data.state = STATE_IDLE
			data.timer = 0
		end

		if Colliders.collide(player, data.slambox) then
			data.state = STATE_DROP
			data.timer = 0
		end
	elseif data.state == STATE_DROP then
		v.speedX = 0
		if data.timer > 32 then
			v.animationFrame = 3
			v.speedY = math.clamp(v.speedY + .25, -20, 20)
	    elseif data.timer >= 24 then
			v.animationFrame = 3
			data.shake = 0
	    elseif data.timer >= 16 then
			v.animationFrame = 3
			if data.shake == 1 then
				data.shake = 0
				v.x = v.x + 4
			else
				data.shake = 1
				v.x = v.x - 4
			end
	    elseif data.timer >= 1 then
			v.animationFrame = 2
		end

		if Colliders.collide(player, v) and player.y > v.y + v.height - 4 and (player:isGroundTouching() or player.standingNPC ~= nil) then
			player:harm()
			player.speedX = 0
			player.speedY = 20
		end

		for _,p in ipairs(NPC.getIntersecting(v.x - 6, v.y - 6, v.x + v.width + 6, v.y + v.height + 6)) do
			if p:mem(0x12A, FIELD_WORD) > 0 and p:mem(0x138, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 and (not p.isHidden) and (not p.friendly) and p:mem(0x12C, FIELD_WORD) == 0 and p.idx ~= v.idx and v:mem(0x12C, FIELD_WORD) == 0 and NPC.HITTABLE_MAP[p.id] then
				p:harm(HARM_TYPE_HELD)
				if p.id == v.id and v.ai2 == 0 then
					p.speedX = 3.5 * data.hitter
					v.ai2 = 1
				elseif p.id == nil then
					v.ai2 = 0
				end
			end
		end

		local list = Colliders.getColliding{
		a = data.attackCollider,
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
			if b.id == 667 or b.id == 666 then
				b:hit()
			else
				b:remove(true)
			end
		end

		local list2 = Colliders.getColliding{
		a = data.hitBlockCollider,
		btype = Colliders.BLOCK,
		filter = function(other)
			if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
				return false
			end
			return true
		end
		}
		for _,b in ipairs(list2) do
			b:hit(true)
		end

		if v.collidesBlockBottom then
			data.state = STATE_RISE
			data.timer = 0
		end
	elseif data.state == STATE_RISE then
	    if data.timer > 48 then
			v.speedY = -2
			v.animationFrame = 2

			if v.y <= v.spawnY + 1 then
				data.state = STATE_IDLE
				data.timer = 0
				v.speedY = 0
			end
	    elseif data.timer >= 1 then
			v.speedY = 0
			v.animationFrame = 4
			if data.timer == 1 then
				Defines.earthquake = 4
				SFX.play(37)
				Animation.spawn(10, v.x - 17, v.y + v.height - 16)
				Animation.spawn(10, v.x + v.width - 15, v.y + v.height - 16)
			end
		end
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

return sampleNPC