--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

--Create the library table
local frog = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local frogSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 58,
	gfxwidth = 80,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 56,
	height = 32,
	--Frameloop-related
	frames = 15,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = true,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(frogSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
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
		--[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=10,
	}
);

--To do:
--Make the hurt frames display alternate animations if the frog is looking up
--Make it able to be bounced around

--Weird things to note

--Frog pirates display a unique frame if they're attacked during their licking phase, depending on if its up or down.
--When hit and stunned, they can be bounced around for a bit.
--They can be killed by NPCs, but only if there isnt a culprit
--When they get hurt while in water, they briefly sink down until they pop back up

local yiYoshi
pcall(function() yiYoshi = require("yiYoshi/yiYoshi") end)

--The starting state, runs from the player and croaks at them. If in water it will bob up and down from the surface  and move about 
local STATE_TAUNT = 0

--The state that uses the tongue.
local STATE_GRAB = 1

--Only if MDA's Yoshi playable is used. If it grabs Baby Mario it will frantically try to get away with him. If underwater it will try to camp out Yoshi.
local STATE_RUN = 2

--When stomped or spinjumped, causes it to momentarily stop what it's doing and look up in surprise
local STATE_OW = 3

--When tossed, either by YI yoshi or if somehow picked up
local STATE_THROWN = 4

--For when in STATE_WANDER, basically a line of sight for detecting a player.
local lickColliderDir = {
[1] = -68,
[-1] = 180
}

--Register events
function frog.onInitAPI()
	npcManager.registerEvent(npcID, frog, "onTickEndNPC")
	npcManager.registerEvent(npcID, frog, "onDrawNPC")
	registerEvent(frog, "onNPCHarm")
end

function frog.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local plr = Player.getNearest(v.x + v.width / 2, v.y + v.height / 2)
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		data.owTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_TAUNT
		data.timer = data.timer or 0
		data.owTimer = data.owTimer or 0
		data.hopDirection = v.direction
		data.decision = RNG.randomInt(0,1)
		data.isUnderWater = false
	end

	local horizLickCollider = Colliders.Box(v.x - (v.width * 1), v.y - (v.height * 1), v.width * 5, v.height)
	horizLickCollider.x = v.x - v.width - lickColliderDir[v.direction]
	horizLickCollider.y = v.y
	
	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		data.state = STATE_THROWN
	end
		
	if Colliders.collide(plr,v) then
		if data.state ~= STATE_OW then
			if yiYoshi ~= nil then
				if plr.character ~= CHARACTER_KLONOA then
					if not v.underwater then
						plr:harm()
					end
				else
					--Nab the baby!
				end
			else
				if not v.underwater then
					plr:harm()
				end
			end
		else
			if not data.isHit and not v.underwater then
				SFX.play("FrogBurb.ogg")
				v.speedX = 4 * plr.direction
				v.speedY = -5
			end
		end
	end
	
	if data.state ~= STATE_OW then
		data.timer = data.timer + 1
		data.saveState = data.state
	end

	if data.state == STATE_TAUNT then
		if not v.underwater then
		
			--Reset behaviour when exiting water
			if data.isUnderWater then
				data.isUnderWater = false
				data.timer = 0
				v.speedX = 0
				data.decision = RNG.randomInt(0,1)
			end
			if data.decision == 0 then
			
				npcutils.faceNearestPlayer(v)
				
				--Things that try to make an accurate enough croaking animation
				if data.timer < 16 or (data.timer >= 32 and data.timer < 48) or data.timer >= 96 then
					v.animationFrame = 0
				elseif (data.timer >= 16 and data.timer < 32) or (data.timer >= 48 and data.timer < 96) then
					v.animationFrame = 1
					if data.timer == 16 then
						SFX.play("FrogCroak.wav")
					end
				end
				
				if data.timer == 112 then
					data.decision = RNG.randomInt(0,1)
					data.timer = 0
				end
				
				if data.timer >= 96 then
					if Colliders.collide(plr,horizLickCollider) or (math.abs(v.x + 16 - plr.x) <= 128 and plr.y < v.y - 48) then
						--data.state = STATE_GRAB
					end
				end
			else
				--Jump, a bit of a process to but it'll still achieve the same thing
				if data.timer >= 0 and data.timer <= 4 then
					v.direction = data.hopDirection
					v.animationFrame = 2
				elseif data.timer > 4 and data.timer <= 20 then
					v.animationFrame = 0
				elseif data.timer > 20 then
					if data.timer == 21 and v.collidesBlockBottom then
						SFX.play("FrogHop.ogg")
						v.speedX = 2 * v.direction
						v.speedY = -5
					else
						if v.collidesBlockBottom then
							data.timer = -65
							v.speedX = 0
						end
					end
				else
					if Colliders.collide(plr,horizLickCollider) or (math.abs(v.x + 16 - plr.x) <= 128 and plr.y < v.y - 48) then
						--data.state = STATE_GRAB
					end
					v.animationFrame = 4
					if data.timer >= -54 then
						npcutils.faceNearestPlayer(v)
						if data.timer == -1 then
							data.decision = RNG.randomInt(0,1)
							data.timer = 0
						end
					end
				end
				if not v.collidesBlockBottom then
					v.animationFrame = 3
				end
			end
		else
			
			v.animationFrame = 2
			
			--Reset behaviour when entering water
			if not data.isUnderWater then
				data.timer = 0
				data.decision = 0
				data.isUnderWater = true
				data.xPos = v.x
			end
			
			--Make a splashing animation when the NPC goes in and out, effect was taken from cold soup's icantswim.lua
			if data.timer == 0 then
				data.decision = 0
				data.yPos = v.y
				Animation.spawn(950, v.x-16, v.y-16)
				SFX.play(72)
			end
			
			--If underwater, then move back and forth
			if data.decision == 0 then
				v.friendly = false
				npcutils.faceNearestPlayer(v)
				v.speedY = -Defines.npc_grav
				v.y = v.y + math.sin(data.timer/10)*0.5 / 1.2
				if data.timer >= 56 then
					data.timer = 0
					Animation.spawn(950, v.x-16, v.y-16)
					SFX.play(72)
					data.decision = 1
					data.xPos = v.x
				end
				if Colliders.collide(plr,horizLickCollider) or (math.abs(v.x + 16 - plr.x) <= 128 and plr.y < v.y - 48) then
					--data.state = STATE_GRAB
				end
			else
				v.friendly = true
				--Stuff that handles the underwater movement
				if data.timer <= 8 then
					v.speedY = 4
					v.speedX = 0
				elseif data.timer > 8 and data.timer <= 40 then
					npcutils.faceNearestPlayer(v)
					v.speedX = 6 * v.direction
					v.speedY = 0
					if v.collidesBlockLeft or v.collidesBlockRight then
						v.x = data.xPos
						v.y = data.yPos + 24
						data.timer = 41
					end
					if data.timer == 40 then
						data.xPos = v.x
						v.y = data.yPos + 24
					end
				else
					v.speedY = -4
					v.speedX = 0
					v.x = data.xPos
					if data.timer == 48 then
						data.decision = 0
						data.timer = 0
					end
				end
			end
		end
	elseif data.state == STATE_GRAB then
		--This is the state where they try to grab you with their tongue
	elseif data.state == STATE_OW then
		
		data.owTimer = data.owTimer + 1
		
		--If underwater, then slowly sink down
		if v.underwater then
			if not data.isUnderWater then
				data.yPos = v.y
				data.xPos = v.x
				Animation.spawn(950, v.x-16, v.y-16)
				SFX.play(72)
				data.isUnderWater = true
			end
			v.friendly = true
			data.decision = 1
			if data.owTimer <= 64 then
				v.speedY = 0.5
			elseif data.owTimer > 64 then
				data.state = data.saveState
				data.timer = 0
				v.friendly = false
			end
		else
			data.isUnderWater = false
		end
		
		--Animation when hurt
		if data.owTimer <= 8 then
			v.animationFrame = 0
		elseif data.owTimer > 8 and data.owTimer <= 59 then
			v.animationFrame = 12
		elseif data.owTimer > 59 and data.owTimer <= 119 then
			v.animationFrame = 2
		elseif data.owTimer >= 120 and v.collidesBlockBottom then
			data.state = data.saveState
			data.timer = 0
			data.isHit = false
		end
		if v.collidesBlockBottom then
			v.speedX = 0
		else
			data.isHit = true
		end
	end
	
	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = frogSettings.frames
	});
end

function frog.onDrawNPC(v)
	local data = v.data
	if v.underwater then
		--Set it behind stuff
		npcutils.drawNPC(v,{priority = -90})
	else
		npcutils.drawNPC(v,{priority = -45})
	end
	npcutils.hideNPC(v)
end

--Handle damage
function frog.onNPCHarm(eventObj,v,reason,culprit)
	local data = v.data
	if v.id ~= npcID then return end
	
	if reason ~= HARM_TYPE_FROMBELOW and reason ~= HARM_TYPE_HELD and reason ~= HARM_TYPE_LAVA and reason ~= HARM_TYPE_OFFSCREEN and reason ~= HARM_TYPE_TAIL then
		if reason == HARM_TYPE_NPC then
			if culprit then
				if culprit.__type == "NPC" and culprit.id ~= 50 then
					eventObj.cancelled = true
					data.state = STATE_OW
					data.owTimer = 0
					culprit:kill()
					SFX.play("FrogBurb.ogg")
					v.speedX = 0
				else
					return
				end
			else
				return
			end
		else
			eventObj.cancelled = true
			data.state = STATE_OW
			data.owTimer = 0
			SFX.play("FrogBurb.ogg")
			v.speedX = 0
		end
	end
end

--Gotta return the library table!
return frog