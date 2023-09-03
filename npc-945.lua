local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 62,
	gfxwidth = 86,

	width = 32,
	height = 48,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 54,
	framestyle = 1,
	framespeed = 6, 

	speed = 1,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 

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
	staticdirection=true,
	destroyblocktable = {90, 4, 188, 60, 293, 667, 457, 666, 686, 668, 526, 694}
}

npcManager.setNpcSettings(sampleNPCSettings)

npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		--HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		HARM_TYPE_SPINJUMP,
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

local STATE_WALK = 0
local STATE_PUNCH = 1
local STATE_KICK = 2
local STATE_UPKICK = 3
local STATE_SHOOT = 4
local STATE_BONKED = 5
local spawnOffset = {[-1] = 16, [1] = -32}

local yiYoshi
pcall(function() yiYoshi = require("yiYoshi/yiYoshi") end)

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickEndNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
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
		data.moveTimer = 0
		data.jumpTimer = 0
		data.hitSpeed = 0
		data.attackCollider = data.attackCollider or Colliders.Box(v.x, v.y, v.width, v.height)
	end

	data.attackCollider.x = v.x + 24 * v.direction
	data.attackCollider.y = v.y

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		--Handling
	end

	data.moveTimer = data.moveTimer + 1
	data.timer = data.timer + 1

	if v.speedY > 0 or v.speedY < 0 then
	    v.animationFrame = 4
	end

    if data.jumpTimer == nil then data.jumpTimer = 0 end

    if v.collidesBlockLeft or v.collidesBlockRight then
        data.jumpTimer = 8
        if v.collidesBlockBottom then
            v.speedY = -8
        end
    else
		data.jumpTimer = data.jumpTimer - 1
		if data.jumpTimer <= 0 then
			data.jumpTimer = 0
		else
			v.speedX = 2 * v.direction
		end
    end

	if data.state == STATE_WALK then
	    if v.collidesBlockBottom then
		    if data.moveTimer <= 8 then
				if data.moveTimer == 1 then v.speedX = 0 end
				if data.moveTimer == 8 then v.speedX = 6 * v.direction end
			    v.animationFrame = 0
			else
				v.animationFrame = math.floor(data.moveTimer / 4) % 4
				v.speedX = 0.25 * v.direction
				if data.moveTimer >= 16 then
					npcutils.faceNearestPlayer(v)
					data.moveTimer = 0
				end
		    end
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
			data.state = RNG.irandomEntry{1,2,3}
			data.timer = 0
		end
		
		if data.hitSpeed > 0 then
			v.speedX = 0
			--Move a bit due to being hit by something
			if not v.collidesBlockLeft and not v.collidesBlockRight then
				v.x = v.x + data.hitSpeed * -v.direction
			else
				v.x = v.x + 32 * v.direction
			end
		
			--Stop the NPC when its slow enough
			if math.abs(data.hitSpeed) <= 0.1 then
				data.hitSpeed = 0
			else
				data.hitSpeed = data.hitSpeed - 0.15
			end
			
			--After 32 ticks, go back to walking
			if data.timer >= 32 then
				data.timer = 0
			end
		end
		
		if math.abs(plr.x - v.x) <= 48 and math.abs(plr.y - v.y) <= v.height * 2 and data.timer >= 50 then
			data.state = RNG.irandomEntry{1,2,3}
			data.timer = 0
			data.moveTimer = 0
			data.animTimer = 0
			v.speedX = 0
		end
		if data.timer >= 100 and v.collidesBlockBottom then
		    data.state = RNG.irandomEntry{1,2,3,4}
			data.timer = 0
			data.moveTimer = 0
			data.animTimer = 0
			v.speedX = 0
		end
	elseif data.state == STATE_PUNCH then
		if data.timer >= 16 then
		    data.state = STATE_WALK
			data.timer = 0
			data.moveTimer = 0
			data.animTimer = 0
	    elseif data.timer >= 1 then
			if data.timer == 1 then SFX.play("tongue_failed.ogg") end
		    data.animTimer = data.animTimer + 1
		    v.animationFrame = math.floor(data.animTimer / 3) % 5 + 5
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
	elseif data.state == STATE_KICK then
		if data.timer >= 22 then
		    data.state = STATE_WALK
			data.timer = 0
			data.moveTimer = 0
			data.animTimer = 0
	    elseif data.timer >= 1 then
			if data.timer == 1 then SFX.play("tongue_failed.ogg") end
		    data.animTimer = data.animTimer + 1
		    v.animationFrame = math.floor(data.animTimer / 2) % 11 + 10
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
	elseif data.state == STATE_UPKICK then
		if data.timer >= 26 then
		    data.state = STATE_WALK
			data.timer = 0
			data.moveTimer = 0
			data.animTimer = 0
	    elseif data.timer >= 1 then
			if data.timer == 1 then SFX.play("tongue_failed.ogg") end
		    data.animTimer = data.animTimer + 1
		    v.animationFrame = math.floor(data.animTimer / 2) % 14 + 21
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
	elseif data.state == STATE_SHOOT then
		if data.timer >= 1 and data.timer < 100 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer / 3) % 3 + 35
			if data.timer == 7 then
				data.npc = NPC.spawn(946, v.x + spawnOffset[v.direction], v.y + 16, player.section)
			end
			if data.timer >= 8 then
				SFX.play(9)
				data.animTimer = data.animTimer + 1
				v.animationFrame = math.floor(data.animTimer / 2) % 3 + 38
				data.npc.x = v.x + spawnOffset[v.direction]
				data.npc.y = v.y + 16
			end
		elseif data.timer >= 160 then
		    data.state = STATE_WALK
			data.npc = nil
			data.timer = 0
			data.moveTimer = 0
			data.animTimer = 0
		elseif data.timer >= 104 then
            v.animationFrame = 43
			data.npc.speedX = 3 * v.direction
			data.npc.speedY = 0
		elseif data.timer >= 100 then
		    data.animTimer = data.animTimer + 1
            v.animationFrame = math.floor(data.animTimer / 2) % 3 + 41
			data.npc.speedX = 9.9 * v.direction
			data.npc.speedY = -4
		elseif data.timer >= 99 then
		    data.animTimer = 0
            v.animationFrame = math.floor(data.animTimer / 2) % 3 + 38
		end
	elseif data.state == STATE_BONKED then
		if data.timer >= 270 then
		    data.state = STATE_WALK
			data.timer = 0
			data.animTimer = 0
			data.moveTimer = 0
		elseif data.timer >= 220 then
		    data.animTimer = 0
		    v.animationFrame = 51
		elseif data.timer >= 160 then
		    data.animTimer = data.animTimer + 1
		    v.animationFrame = math.floor(data.animTimer / 3) % 2 + 52
		elseif data.timer >= 150 then
		    v.animationFrame = math.floor(data.animTimer / 4) % 2 + 50
		elseif data.timer >= 16 then
		    data.animTimer = 0
		    v.animationFrame = 49
	    elseif data.timer >= 1 then
			if data.timer == 2 then v.speedY = -1.3 end
		    data.animTimer = data.animTimer + 1
		    v.animationFrame = math.floor(data.animTimer / 4) % 6 + 45
		end
	end
	
	if data.state ~= STATE_BONKED then
		if Colliders.collide(plr, v) and not v.friendly and not Defines.cheat_donthurtme then
			plr:harm()
		end
		
		--If licked by the player's Yoshi or MDA's Yoshi then cause it to be launched back, if hit front on that is.
		for _,w in ipairs(Player.get()) do
			if (yiYoshi ~= nil and yiYoshi.playerData.tongueTipCollider:collide(v) and yiYoshi.playerData.tongueState ~= 0) or Colliders.tongue(w, v) then
				if (w.x < v.x and v.animationFrame <= 5) or (w.x > v.x and v.animationFrame >= 6) then
					data.state = STATE_WALK
					data.timer = 0
					data.hitSpeed = 3
					w:mem(0xB8,FIELD_WORD,0)
					v.y = v.y - 1
					v.x = v.x + 16 * -v.direction
					if yiYoshi ~= nil then
						yiYoshi.playerData.tongueState = 3
						yiYoshi.playerData.tongueNPC = nil
						SFX.play("tongue_failed.ogg")
					end
				end
			end
		end
	end
	
	if data.state > 0 and data.state <= 3 then	
		if Colliders.collide(plr, data.attackCollider) and not v.friendly and not Defines.cheat_donthurtme then
			plr:harm()
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
        if data.state == STATE_WALK or data.state == STATE_BONKED and (reason == HARM_TYPE_JUMP or reason == HARM_TYPE_SPINJUMP) and type(culprit) == "Player" then
		    data.state = STATE_BONKED
			data.timer = 0
			SFX.play("Shoop.wav")
			v.speedX = 0
        elseif data.state == STATE_WALK or data.state == STATE_BONKED and reason == HARM_TYPE_NPC and type(culprit) == "NPC" then
		    data.state = RNG.irandomEntry{1,2,3}
			data.timer = 0
			v.speedX = 0
			if type(culprit) == "NPC" and culprit.id == 195 or culprit.id == 50 then
				return
			else
				if (type(culprit) == "NPC" and NPC.HITTABLE_MAP[culprit.id] or culprit.id == 45 and v:mem(0x138, FIELD_WORD) == 0) then
					culprit:kill()
				end
			end
		end
    else
		for _,p in ipairs(NPC.getIntersecting(v.x - 6, v.y - 6, v.x + v.width + 6, v.y + v.height + 6)) do
			if p.id == 953 then
				p:kill(HARM_TYPE_VANISH)
				SFX.play(2)
				local e = Effect.spawn(953,p.x+p.width*0.5,p.y+p.height)

				e.x = e.x - e.width*0.5
				e.y = e.y - e.height
			end
		end
	end
end

return sampleNPC