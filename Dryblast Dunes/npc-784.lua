--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local effectconfig = require("game/effectconfig")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 80,
	gfxwidth = 94,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 32,
	height = 64,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 12,
	framestyle = 1,
	framespeed = 6, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,

	--Identity-related flags. Apply various vanilla AI based on the flag:
	--iswalker = false,
	--isbot = false,
	--isvegetable = false,
	--isshoe = false,
	--isyoshi = false,
	--isinteractable = false,
	--iscoin = false,
	--isvine = false,
	--iscollectablegoal = false,
	--isflying = false,
	--iswaternpc = false,
	--isshell = false,

	--Emits light if the Darkness feature is active:
	--lightradius = 100,
	--lightbrightness = 1,
	--lightoffsetx = 0,
	--lightoffsety = 0,
	--lightcolor = Color.white,

	--Define custom properties below
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		[HARM_TYPE_FROMBELOW]=763,
		[HARM_TYPE_NPC]=763,
		[HARM_TYPE_PROJECTILE_USED]=763,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below
local STATE_IDLE = 0
local STATE_SHOOT = 1
local STATE_WALK = 2
local spawnOffset = {}
spawnOffset[-1] = (sampleNPCSettings.width - 110)
spawnOffset[1] = (sampleNPCSettings.width)

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

function effectconfig.onTick.TICK_BAZUKA(v)
    if v.timer == v.lifetime-1 then
        v.speedX = math.abs(v.speedX)*v.direction
    end

	if v.timer == v.lifetime-1 then
		SFX.play("Klomp die.wav")
	end

    v.animationFrame = math.min(v.frames-1,math.floor((v.lifetime-v.timer)/v.framespeed))
end

function sampleNPC.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_IDLE
		data.timer = 0
		data.shootTimer = 0
		data.walkTimer = 0
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	data.timer = data.timer + 1
	if data.state == STATE_IDLE then
	    if v.direction == -1 then
            v.animationFrame = math.floor(lunatime.tick() / 12) % 2
			v.animationTimer = 0
		elseif v.direction == 1 then
		    v.animationFrame = math.floor(lunatime.tick() / 12) % 2 + 12
			v.animationTimer = 0
		end
		if data.timer > settings.delay then
		    data.state = STATE_SHOOT
		end
	end
	--This whole thing is a mess I know
	if data.state == STATE_SHOOT then
	    data.shootTimer = data.shootTimer + 1
		if data.shootTimer == 1 then
			if (v.x + v.width > camera.x and v.x < camera.x + 800 and v.y + v.height > camera.y and v.y < camera.y + 600) then
				SFX.play("Barrel_blast.mp3")
			end
			if settings.list == 1 then
				local bomb = NPC.spawn(835, v.x + spawnOffset[v.direction], v.y + 6, player.section, false)
				bomb.speedX = settings.speed * v.direction
			else
				local barrel = NPC.spawn(834, v.x + spawnOffset[v.direction], v.y, player.section, false)
				barrel.speedX = settings.speed * v.direction
			end
			Effect.spawn(760, v.x + spawnOffset[v.direction], v.y)
		elseif data.shootTimer > 3 and data.shootTimer <= 5 then
		    if v.direction == -1 then
			    v.animationFrame = 2
				v.animationTimer = 0
			elseif v.direction == 1 then
			    v.animationFrame = 14
				v.animationTimer = 0
			end
		elseif data.shootTimer > 6 and data.shootTimer <= 8 then
		    if v.direction == -1 then
			    v.animationFrame = 3
				v.animationTimer = 0
			elseif v.direction == 1 then
			    v.animationFrame = 15
				v.animationTimer = 0
			end
		elseif data.shootTimer > 9 and data.shootTimer <= 11 then
		    if v.direction == -1 then
			    v.animationFrame = 4
				v.animationTimer = 0
			elseif v.direction == 1 then
			    v.animationFrame = 16
				v.animationTimer = 0
			end
		elseif data.shootTimer > 12 and data.shootTimer <= 14 then
		    if v.direction == -1 then
			    v.animationFrame = 5
				v.animationTimer = 0
			elseif v.direction == 1 then
			    v.animationFrame = 17
				v.animationTimer = 0
			end
		elseif data.shootTimer > 15 and data.shootTimer <= 17 then
		    if v.direction == -1 then
			    v.animationFrame = 4
				v.animationTimer = 0
			elseif v.direction == 1 then
			    v.animationFrame = 16
				v.animationTimer = 0
			end
		elseif data.shootTimer > 18 and data.shootTimer <= 20 then
		    if v.direction == -1 then
			    v.animationFrame = 3
				v.animationTimer = 0
			elseif v.direction == 1 then
			    v.animationFrame = 15
				v.animationTimer = 0
			end
		elseif data.shootTimer > 21 and data.shootTimer <= 23 then
		    if v.direction == -1 then
			    v.animationFrame = 2
				v.animationTimer = 0
			elseif v.direction == 1 then
			    v.animationFrame = 14
				v.animationTimer = 0
			end
		elseif data.shootTimer > 25 and data.shootTimer <= 26 then
            data.state = STATE_IDLE
			data.timer = 0
			data.shootTimer = 0
		end
	end
end

--Gotta return the library table!
return sampleNPC