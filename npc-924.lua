local npcManager = require("npcManager")


local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 86,
	gfxwidth = 64,
	width = 64,
	height = 78,
	frames = 1,
	framestyle = 0,
	framespeed = 8, 

	speed = 5,

	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = true,
	noblockcollision = true,
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

--Custom local definitions below
local STATE_IDLE = 0
local STATE_STEPPED = 1
local STATE_RECOVER = 2

--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

local animationLimit = 5

function sampleNPC.onDrawNPC(v)
	local data = v.data

	if data.state == STATE_IDLE then
	    data.timer = 0
		data.deathCounter = 0
	    v.animationFrame = 0
	    v.animationTimer = 0
	elseif data.state == STATE_STEPPED then
	    data.timer = data.timer + 1
		data.deathCounter = data.deathCounter + 1
	    v.animationFrame = math.floor(lunatime.tick() / 4) % 2 + 1
		v.animationTimer = 0
		if data.timer == 1 then
		   SFX.play("sfx_land.ogg")
		elseif data.timer >= 5 then
		    v.animationFrame = 3
			v.animationTimer = 0
		end
        if data.deathCounter == 60 then
            v:kill(HARM_TYPE_VANISH)
        elseif data.deathCounter >= 40 then
            if lunatime.tick() % 6 < 4 then
                v.animationFrame = 3
            else
                v.animationFrame = -1
            end
        end
	elseif data.state == STATE_RECOVER then
	    data.timer = 0
		v.animationFrame = 4
		v.animationTimer = 0
	end
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
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
		data.pressed = false
		data.timer = 0
		data.moveTimer = 0
		data.counter = 0
		data.deathCounter = 0
	end

	--Most of the code taken from MDA's Number Platforms

	-- 0x12C - The index of the player grabbing the NPC. Defaults to 0 when not grabbed, 
	-- setting to 1 or higher deactivates block collision when grabbed but causes the respective player to drop other objects.

	-- 0x136 - If true, the NPC can harm other NPC's. Usually true for thrown NPCs and projectile-generated NPCs.

	--

	local isPressed = false
	data.moveTimer = data.moveTimer + 1
	if not v.dontMove == true then
	    v.x = v.x + math.sin(data.moveTimer * 0.05) * 0.6
	    v.speedY = -1
	end

	if v:mem(0x12C,FIELD_WORD) == 0 and not v:mem(0x136,FIELD_BOOL) and v:mem(0x138,FIELD_WORD) == 0 then
		for _,p in ipairs(Player.get()) do
			if p.deathTimer == 0 and not p:mem(0x13C,FIELD_BOOL) then
				if p.standingNPC == v or (p:isOnGround() and p.x+p.width > v.x and p.x < v.x+v.width and p.y+p.height >= v.y-0.01 and p.y+p.height <= v.y+0.1) then
					isPressed = true
					break
				end
			end
		end
	end
	
	
	if data.pressed and isPressed then
		data.state = STATE_STEPPED
	    if not v.dontMove and player.standingNPC == v then
	         v.speedY = -0.4
			 player.x = player.x + math.sin(data.moveTimer * 0.05) * 0.6
	    end
		data.counter = 0
	elseif not data.pressed and not isPressed then
		data.state = STATE_IDLE
		data.counter = 0
	else
		if data.pressed then
			data.state = STATE_RECOVER
		else
			data.state = STATE_STEPPED
		end

		if data.counter == animationLimit then
			data.counter = 0
			data.pressed = isPressed
		else
			data.counter = data.counter + 1
		end
	end	
end



--Gotta return the library table!
return sampleNPC