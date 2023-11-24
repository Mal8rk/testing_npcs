local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 92,
	gfxwidth = 90,

	width = 32,
	height = 48,

	gfxoffsetx = 0,
	gfxoffsety = 20,

	frames = 33,
	framestyle = 1,
	framespeed = 6, 

	speed = 1,

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

	prepareDetectionWidth = 64,
	prepareDetectionHeight = 64,
	YIEggID = 953,
	enemyEggID = 922,
	cursorEffect = 825,
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
local STATE_CATCH = 1
local STATE_THROW = 2
local STATE_BONKED = 3

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

local egg
pcall(function() yiYoshi = require("yiYoshi/egg_ai") end)

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

function effectconfig.onTick.TICK_CROSSHAIR(v)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
    v.x = plr.x
	v.y = plr.y
end

function sampleNPC.onTickEndNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
	local config = NPC.config[v.id]
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		data.npc = nil
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = STATE_WALK
		data.timer = data.timer or 0
		data.npc = nil
		data.animTimer = 0
		data.turnTimer = 0
		data.health = 3
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		--Handling
	end

	colBox.width = config.prepareDetectionWidth
	colBox.height = config.prepareDetectionHeight
	
	colBox.x = v.x - 16
	colBox.y = v.y + v.height - colBox.height

	colBox:Debug(false)

	data.timer = data.timer + 1
	data.animTimer = data.animTimer + 1

    data.hasCollided = false
    for _, npc in NPC.iterateIntersecting(colBox.x, colBox.y, colBox.x + colBox.width, colBox.y + colBox.height) do
        if (NPC.config[npc.id].grabside or NPC.config[npc.id].grabtop or NPC.config[npc.id].isshell or (NPC.config[npc.id].fallEffectID and not NPC.config[npc.id].isBigEgg or npc.id == NPC.config[v.id].YIEggID)) and npc:mem(0x12C, FIELD_WORD) == 0 then
            data.hasCollided = true
			
			if NPC.config[npc.id].fallEffectID then
				data.transformEgg = true
			else
				--Transform thrown yi eggs into the version that bumps players when touched
				if npc.id == NPC.config[v.id].YIEggID then 
					npc:transform(954)
				else
					npc.friendly = true
				end
				
				if not NPC.config[npc.id].isshell then
					npc.ai1 = 1
				end
			end
			data.thrownNPC = npc
        end
    end

	--Most of this is just for animation

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
		if data.hasCollided then
			data.state = STATE_CATCH
			data.timer = 0
			data.animTimer = 0
			data.turnTimer = 0
			v.speedX = 0
		end
	elseif data.state == STATE_CATCH then
		npcutils.faceNearestPlayer(v)
		if data.hasCollided and data.thrownNPC then
			if data.timer >= 88 then
				
				--Throw the YI egg here
				if data.transformEgg then 
					data.thrownNPC:transform(NPC.config[v.id].enemyEggID)
					data.dirVectr = vector.v2(
						(plr.x) - (v.x + v.width * 0.5),
						(plr.y) - (v.y + v.height * 0.5)
					):normalize() * 14
					if data.thrownNPC.data.speed then
						data.thrownNPC.data.speed.x = 14 * v.direction
						data.thrownNPC.data.speed.y = -Defines.npc_grav + data.dirVectr.y
					end
				else
					data.thrownNPC:mem(0x136, FIELD_BOOL, true)
					data.thrownNPC.friendly = false
				end
				
				data.dirVectr = vector.v2(
					(plr.x) - (v.x + v.width * 0.5),
					(plr.y) - (v.y + v.height * 0.5)
				):normalize() * 14

				data.thrownNPC.x = v.x + 32 * v.direction
				data.thrownNPC.speedX = data.dirVectr.x
				data.thrownNPC.speedY = data.dirVectr.y
				v.animationFrame = 16
				
				data.thrownNPC = nil
				
			elseif data.timer == 87 then
				v.animationFrame = 16
				data.animTimer = 0
				data.thrownNPC.animationFrame = 0
				data.thrownNPC.x = v.x
				data.thrownNPC.y = v.y
				SFX.play("egg_thrown.ogg")
			elseif data.timer >= 48 then
				SFX.play("Aim.wav")
				v.animationFrame = math.floor(data.animTimer / 5) % 4 + 12
				data.thrownNPC.animationFrame = -50
				data.thrownNPC.x = v.x
				data.thrownNPC.y = v.y
			elseif data.timer >= 32 then
			
				if data.timer == 32 then 
					v.x = v.x - 10 * v.direction 
					Effect.spawn(NPC.config[v.id].cursorEffect, v.x, v.y, player.section, true) 
				elseif data.timer == 43 then 
					v.x = v.x - 11 * v.direction 
				end
				
				SFX.play("Aim.wav")
				
				v.animationFrame = math.floor(data.animTimer / 6) % 3 + 9
				data.thrownNPC.animationFrame = -50
				data.thrownNPC.x = v.x
				data.thrownNPC.y = v.y
			elseif data.timer == 31 then
				v.animationFrame = 8
				data.animTimer = 0
				data.thrownNPC.animationFrame = -50
				data.thrownNPC.x = v.x
				data.thrownNPC.y = v.y
			elseif data.timer >= 16 then
				v.animationFrame = 8
				data.thrownNPC.animationFrame = -50
				data.thrownNPC.x = v.x
				data.thrownNPC.y = v.y
			elseif data.timer >= 1 then
				v.animationFrame = math.floor(data.animTimer / 5) % 4 + 5
				data.thrownNPC.animationFrame = -50
				data.thrownNPC.x = v.x
				data.thrownNPC.y = v.y
			end
		elseif not data.hasCollided then
			data.state = STATE_THROW
			data.timer = 0
			data.animTimer = 0
			data.turnTimer = 0
		end
	elseif data.state == STATE_THROW then
		if data.timer >= 61 then
			data.state = STATE_WALK
			data.timer = 0
			data.animTimer = 0
			data.turnTimer = 0
		elseif data.timer >= 56 then
			v.animationFrame = 26
		elseif data.timer >= 33 then
			v.animationFrame = math.floor(data.animTimer / 6) % 5 + 22
		elseif data.timer == 32 then
			v.animationFrame = 21
			data.animTimer = 0
		elseif data.timer >= 21 then
			v.animationFrame = 21
		elseif data.timer >= 1 then
			if data.timer == 5 then v.x = v.x + 20 * v.direction end
			v.animationFrame = math.floor(data.animTimer / 5) % 6 + 16
		end
	elseif data.state == STATE_BONKED then
	
		if data.hasCollided then
			data.hasCollided = false
			data.thrownNPC.friendly = false
			if data.timer == 1 then
				data.thrownNPC.animationFrame = 0
				data.thrownNPC = nil
			end
		end
		
		if data.timer >= 205 then
		    data.state = STATE_WALK
			data.timer = 0
			data.animTimer = 0
			data.turnTimer = 0
		elseif data.timer >= 198 and v.collidesBlockBottom then
		    v.animationFrame = 31
		elseif data.timer >= 170 then
		    if data.timer == 171 then v.speedY = -3.5 end
		    v.animationFrame = 32
		elseif data.timer >= 160 then
		    v.animationFrame = 31
		elseif data.timer >= 125 then
		    v.animationFrame = 28
		elseif data.timer >= 100 then
		    v.animationFrame = math.floor(lunatime.tick() / 3) % 2 + 29
		elseif data.timer >= 60 then
		    v.animationFrame = 28
	    elseif data.timer >= 1 then
		    v.animationFrame = 27
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

--[[function sampleNPC.onDrawNPC(v)
	local data = v.data
	Text.print(data.thrownNPC, 8, 8)
	Text.print(data.hasCollided, 8, 32)
end]]

return sampleNPC