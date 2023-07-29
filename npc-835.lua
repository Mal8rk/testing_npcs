--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 222,
	gfxwidth = 200,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 200,
	height = 222,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 6,
	framestyle = 1,
	framespeed = 6, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = true,
	npcblocktop = true, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = true,
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
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
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
		[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

--Custom local definitions below


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

local STATE_IDLE = 1
local STATE_SHOOT = 2
local STATE_IDLE2 = 3
local STATE_MOVING = 4
local STATE_PUSHED = 5

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
        data.state = STATE_IDLE
        v.stateTimer = 0
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.state = STATE_IDLE
        v.data.stateTimer = 0
	end
	
	data.stateTimer = data.stateTimer + 1

	if data.state == STATE_IDLE then
        if data.stateTimer >= 280 and v.collidesBlockBottom then
            data.state = STATE_SHOOT
            data.stateTimer = 0
        end
    end

	if data.state == STATE_SHOOT then
	    v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 3
		v.animationTimer = 0
		if data.stateTimer >= 30 then
		    local bomb = NPC.spawn(136, v.x + 20, v.y + 100)
			bomb.direction = v.direction
			bomb.spawnDirection = v.direction
    	    bomb.speedX = 4.5 * v.direction
			SFX.play(41)
		    data.state = STATE_IDLE2
			data.stateTimer = 0
		end
	end


	if data.state == STATE_IDLE2 then
        if data.stateTimer >= 190 and v.collidesBlockBottom then
            data.state = STATE_MOVING
            data.stateTimer = 0
        end
    end

    if data.state == STATE_MOVING then
        if data.stateTimer == 1 then
            v.speedX = 4.7 * v.direction
            v.speedY = -2
        end
        if data.stateTimer > 15 and v.collidesBlockBottom then
            Defines.earthquake = 7
            data.state = STATE_IDLE
			v.speedX = 0
            v.speedY = 0
            data.stateTimer = 0
        end
    end

	if data.state == STATE_PUSHED then
	    v.animationFrame = math.floor(lunatime.tick() / 8) % 1 + 3
		v.animationTimer = 0
		if data.stateTimer == 1 then
            v.speedX = 3
			SFX.play("COI_Bosshit.wav")
        end
        if data.stateTimer > 50 then
            data.state = STATE_IDLE2
			v.speedX = 0
            v.speedY = 0
            data.stateTimer = 0
        end
	end
end

function sampleNPC.onNPCHarm(eventObj, v, reason, culprit)
    local data = v.data
    if v.id ~= npcID then return end
    if culprit then
        if reason == HARM_TYPE_NPC and type(culprit) == "NPC" then
            eventObj.cancelled = true
		    data.state = STATE_PUSHED
		    data.stateTimer = 0
        end
    end
end

--Gotta return the library table!
return sampleNPC