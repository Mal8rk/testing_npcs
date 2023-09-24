local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 128,
	gfxwidth = 114,

	width = 64,
	height = 64,

	gfxoffsetx = -8,
	gfxoffsety = 0,

	frames = 10,
	framestyle = 1,
	framespeed = 8,

	speed = 1,

	npcblock = false,
	npcblocktop = true,
	playerblock = false,
	playerblocktop = true,

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = false,

	jumphurt = false,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	grabside=false,
	grabtop=false,
	staticdirection=true,

	destroyblocktable = {90, 4, 188, 60, 293, 667, 457, 666, 686, 668, 526, 694}
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
local STATE_RAM = 1
local STATE_HURT = 2

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
		data.attackCollider = data.attackCollider or Colliders.Box(v.x, v.y, v.width, v.height)
		data.state = data.state or STATE_IDLE
		data.hitter = data.hitter or 0
		data.timer = data.timer or 0
	end

	data.attackCollider.x = v.x + 24 * v.direction
	data.attackCollider.y = v.y

	if v:mem(0x12C, FIELD_WORD) > 0
	or v:mem(0x136, FIELD_BOOL)
	or v:mem(0x138, FIELD_WORD) > 0
	then
		return
	end

	data.timer = data.timer + 1

	if data.state == STATE_IDLE then
		v.animationFrame = math.floor(data.timer / 12) %  4
		if math.abs(player.x - v.x) <= 256 and math.abs(player.y - v.y) <= 128 then
			npcutils.faceNearestPlayer(v)
			data.state = STATE_RAM
			data.timer = 0
		end
	elseif data.state == STATE_RAM then
		if data.timer > 48 then
			v.speedX = math.clamp(v.speedX + 0.5 * v.direction, -4.5, 4.5)
			v.animationFrame = math.floor(data.timer / 6) % 2 + 5
	    elseif data.timer >= 16 then
		    v.animationFrame = math.floor(data.timer / 5) % 2 + 5

			if lunatime.tick() % 5 == 0 then
				Effect.spawn(10, v.x+42, v.y+38, player.section)
				Effect.spawn(10, v.x+10, v.y+38, player.section)
				SFX.play("Rockpush.wav")
			end
		elseif data.timer >= 1 then
			v.animationFrame = 4
		end

		-- Interact with blocks
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

		for _,p in ipairs(NPC.getIntersecting(v.x - 6, v.y - 6, v.x + v.width + 6, v.y + v.height + 6)) do
			data.hitter = p.direction
			if p:mem(0x12A, FIELD_WORD) > 0 and p:mem(0x138, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 and (not p.isHidden) and (not p.friendly) and p:mem(0x12C, FIELD_WORD) == 0 and p.idx ~= v.idx and v:mem(0x12C, FIELD_WORD) == 0 and NPC.HITTABLE_MAP[p.id] then
				p:harm(HARM_TYPE_HELD)
				if p.id == v.id and v.ai2 == 0 then
					p.speedX = 3.5 * data.hitter
					v.speedX = 3.5 * -data.hitter
					v.ai2 = 1
				elseif p.id == nil then
					v.ai2 = 0
				end
			end
		end

		if v.collidesBlockLeft or v.collidesBlockRight then
			data.state = STATE_HURT
			data.timer = 0
		end
	elseif data.state == STATE_HURT then
		if data.timer > 132 then
			data.state = STATE_IDLE
			data.timer = 0
	    elseif data.timer > 4 and v.collidesBlockBottom then
		    v.animationFrame = math.floor(data.timer / 6) % 2 + 8
			v.speedX = 0
		elseif data.timer > 1 then
			v.animationFrame = 7
			v.speedX = 2 * -v.direction

			if data.timer == 2 then 
				Defines.earthquake = 4
				v.speedY = -4 
				SFX.play(37)
			end
		end
	end

	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

return sampleNPC