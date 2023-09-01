local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 92,
	gfxwidth = 84,

	width = 32,
	height = 48,

	gfxoffsetx = 0,
	gfxoffsety = 20,

	frames = 25,
	framestyle = 1,
	framespeed = 6, 

	speed = 1,
	score = 0,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 

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

	prepareDetectionWidth = 52,
	prepareDetectionHeight = 52,
	enemyEggID = 922,
}

npcManager.setNpcSettings(sampleNPCSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		--HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
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

local STATE_WALK = 0
local STATE_SWINGBAT = 1
local STATE_BONKED = 2

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

local egg
pcall(function() yiYoshi = require("yiYoshi/egg_ai") end)

--Batting code taken from MrDoubleA's Battin' Chuck

local alwaysHittableIDs = table.map{40,85,87,246,319,390,615,617,954}

local function deflect(batter,projectile)
	projectile.speedX = math.clamp(math.abs(projectile.speedX)*1.5,1.5,16)*batter.direction
	if not NPC.config[projectile.id].nogravity then
		projectile.speedY = -1.5
	else
		projectile.speedY = 0
	end

	projectile:mem(0x12E,FIELD_WORD,0)
	projectile:mem(0x130,FIELD_WORD,0)
end

local function transformAndDeflect(batter,projectile,transformID)
	projectile:transform(transformID)
	deflect(batter,projectile)

	projectile:mem(0x12E,FIELD_WORD,0)
	projectile:mem(0x130,FIELD_WORD,0)
end


local npcHandlers = {}

local function defaultNPCHandler(batter,projectile)
	if projectile:mem(0x136,FIELD_BOOL) or alwaysHittableIDs[projectile.id] or (batter:mem(0x12C,FIELD_WORD) > 0 and NPC.HITTABLE_MAP[projectile.id]) then
		deflect(batter,projectile)

		if not alwaysHittableIDs[projectile.id] then
			projectile:mem(0x136,FIELD_BOOL,true)
		end

		if NPC.MULTIHIT_MAP[projectile.id] then
			projectile:harm(HARM_TYPE_NPC,0.5)
		end

		return true
	end

	return false
end

-- Fireball
npcHandlers[13] = (function(batter,projectile)
	transformAndDeflect(batter,projectile,390)
	projectile.speedX = math.abs(projectile.speedX)*NPC.config[projectile.id].speed*batter.direction

	return true
end)

-- Iceball
npcHandlers[265] = npcHandlers[13]

-- Hammer
npcHandlers[171] = (function(batter,projectile)
	transformAndDeflect(batter,projectile,617)

	return true
end)

-- Peach bomb
npcHandlers[291] = (function(batter,projectile)
	transformAndDeflect(batter,projectile,134)
	projectile.speedX = batter.direction*8

	return true
end)

-- Toad boomerang
npcHandlers[292] = (function(batter,projectile)
	transformAndDeflect(batter,projectile,615)
	projectile.y = batter.y + batter.height*0.5 - projectile.height*0.5
	projectile.speedX = batter.direction*8
	projectile.data._basegame.ownerBro = batter

	return true
end)

-- Link's beam
npcHandlers[266] = (function(batter,projectile)
	transformAndDeflect(batter,projectile,133)
	projectile.speedX = batter.direction*8
	projectile.speedY = 0
	projectile:mem(0x136,FIELD_BOOL,false)

	return true
end)

-- Birdo egg
npcHandlers[40] = (function(batter,projectile)
	deflect(batter,projectile)
	projectile:mem(0x136,FIELD_BOOL,true)
	projectile.speedX = projectile.speedX*1.25
	projectile.speedY = -1.5

	return true
end)

local colBox = Colliders.Box(0,0,0,0)

function isNearPit(v)
	--This function either returns false, or returns the direction the npc should go to. numbers can still be used as booleans.
	local testblocks = Block.SOLID.. Block.SEMISOLID.. Block.PLAYER

	local centerbox = Colliders.Box(v.x, v.y, 8, v.height + 10)
	local l = centerbox
	if v.direction == DIR_RIGHT then
		l.x = l.x + 28
	end
	
	for _,centerbox in ipairs(
	  Colliders.getColliding{
		a = testblocks,
		b = l,
		btype = Colliders.BLOCK
	  }) do
		return false
	end
	
	
	return true
end

function sampleNPC.onTickEndNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = STATE_WALK
		data.timer = data.timer or 0
		data.animTimer = 0
		data.turnTimer = 0
		data.health = 3
		data.attackRadius = data.attackRadius or 24
		data.attackCollider = data.attackCollider or Colliders.Box(v.x, v.y, v.width, v.height)
	end

	data.attackCollider.x = v.x + 16 * v.direction
	data.attackCollider.y = v.y

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		--Handling
	end

	data.timer = data.timer + 1
	data.animTimer = data.animTimer + 1

	colBox.width = config.prepareDetectionWidth
	colBox.height = config.prepareDetectionHeight
	
	colBox.x = v.x - 12
	colBox.y = v.y + v.height - colBox.height

	colBox:Debug(false)

	local npcs = Colliders.getColliding{a = colBox,btype = Colliders.NPC}

	for _,npc in ipairs(npcs) do
		if npc ~= v then
			local handler = npcHandlers[npc.id] or defaultNPCHandler
			local gotHit = handler(v,npc)
			if gotHit then
				if npc.x <= v.x then
				    v.direction = -1
			    else
				    v.direction = 1
			    end

				local e = Effect.spawn(75,npc.x + npc.width*0.5 + npc.width*0.5*math.sign(npc.direction),v.y + v.height*0.5)

				e.x = e.x - e.width *0.5
				e.y = e.y - e.height*0.5

				SFX.play("egg_hit.ogg")

				data.state = STATE_SWINGBAT
				data.timer = 0
				data.animTimer = 0
				data.turnTimer = 0
			end
		end
	end

	for _,p in ipairs(NPC.getIntersecting(v.x - 12, v.y - 12, v.x + v.width + 12, v.y + v.height + 12)) do
		if Colliders.collide(p, v) and not v.friendly and not Defines.cheat_donthurtme and p.id == 953 then
		
			p.data.speed.y = RNG.irandomEntry{-1,-2.5,-3,-3.9}
			data.state = STATE_SWINGBAT
			data.timer = 0
			data.animTimer = 0
			data.turnTimer = 0
			
			if p.x <= v.x then
				v.direction = -1
			else
				v.direction = 1
			end
			
			p.data.speed.x = -p.data.speed.x 
			
			p:transform(NPC.config[v.id].enemyEggID)
			
			local e = Effect.spawn(75,p.x + p.width*0.5 + p.width*0.5*math.sign(p.direction),v.y + v.height*0.5)

			e.x = e.x - e.width *0.5
			e.y = e.y - e.height*0.5

			SFX.play("egg_hit.ogg")
		end
	end

	if data.state == STATE_WALK then
		data.turnTimer = data.turnTimer + 1
		v.animationFrame =  math.floor(data.animTimer / 5) % 5
		v.speedX = 0.7 * v.direction
		if data.turnTimer >= 200 and v.collidesBlockBottom then
		    v.direction = -v.direction
			data.turnTimer = 0
	    elseif isNearPit(v) and v.collidesBlockBottom or v.collidesBlockLeft or v.collidesBlockRight then
		    v.direction = -v.direction
			data.turnTimer = 0
	    end
		if math.abs(plr.x - v.x) <= 96 and math.abs(plr.y - v.y) <= 24 then
			npcutils.faceNearestPlayer(v)
			v.animationFrame = 5
			data.turnTimer = 0
			data.animTimer = 0
			v.speedX = 0
			if Colliders.collide(plr, data.attackCollider) and not v.friendly and not Defines.cheat_donthurtme then
				plr:harm()
				data.state = STATE_SWINGBAT
				data.timer = 0
				data.animTimer = 0
				data.turnTimer = 0
			end
		end
    elseif data.state == STATE_SWINGBAT then
		if data.timer >= 70 then
		    data.state = STATE_WALK
			data.timer = 0
			data.animTimer = 0
			data.turnTimer = 0
	    elseif data.timer >= 28 then
		    v.animationFrame = 6
		elseif data.timer >= 20 then
		    v.animationFrame = math.floor(data.animTimer / 1.8) % 6 + 13
	    elseif data.timer >= 19 then
		    v.animationFrame = 12
			data.animTimer = 0
	    elseif data.timer >= 8 then
		    v.animationFrame = 12
		elseif data.timer >= 1 then
		    v.animationFrame = math.floor(data.animTimer / 1.4) % 7 + 6
		end
	elseif data.state == STATE_BONKED then
		if data.timer >= 205 then
		    data.state = STATE_WALK
			data.timer = 0
			data.animTimer = 0
			data.turnTimer = 0
		elseif data.timer >= 198 and v.collidesBlockBottom then
		    v.animationFrame = 24
		elseif data.timer >= 170 then
		    if data.timer == 171 then v.speedY = -3.5 end
		    v.animationFrame = 23
		elseif data.timer >= 160 then
		    v.animationFrame = 24
		elseif data.timer >= 125 then
		    v.animationFrame = 20
		elseif data.timer >= 100 then
		    v.animationFrame = math.floor(lunatime.tick() / 3) % 2 + 21
		elseif data.timer >= 60 then
		    v.animationFrame = 20
	    elseif data.timer >= 1 then
		    v.animationFrame = 19
		end
	end

	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
    local data = v.data
    if v.id ~= npcID then return end
	eventObj.cancelled = true

    if culprit then
        if (reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP) and type(culprit) == "Player" then
			if culprit.x <= v.x then
				culprit.speedX = -4
			else
				culprit.speedX = 4
			end
			data.health = data.health - 1
			Effect.spawn(773, v.x - 38, v.y - 32)
		    data.state = STATE_BONKED
			data.timer = 0
			data.turnTimer = 0
			data.animTimer = 0
			SFX.play("Shoop.wav")
			v.speedX = 0
		end
    end
	if data.health <= 0 then
        v:kill(HARM_TYPE_VANISH)
		SFX.play("bubblePop.wav")
		Effect.spawn(773, v.x - 38, v.y - 32)
		for i=1, 3 do
			local c = NPC.spawn(10,v.x + sampleNPCSettings.width * 0.5 / 1.5, v.y + sampleNPCSettings.width * 0.5 / 1.5,player.section, true)
			c.ai1 = 1
			c.speedY = -4.5
			c.speedX = RNG.random (-2.5, 2.5)
		end
	end
end

return sampleNPC