--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local redirector = require("redirector")
local flap = SFX.open(Misc.resolveSoundFile("Krow Fly.mp3"))

--Create the library table
local sampleNPC = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID
local rad, sin, cos, pi = math.rad, math.sin, math.cos, math.pi

--Defines NPC config for our NPC. You can remove superfluous definitions.
local sampleNPCSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 50,
	gfxwidth = 98,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 64,
	height = 32,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 12,
	framestyle = 0,
	framespeed = 2, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = true,
	noblockcollision = true,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = true,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = true, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(sampleNPCSettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
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


--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
	--registerEvent(sampleNPC, "onNPCKill")
end

--Movement code taken from MegaDood's Zingers
local function variant1(v, data, settings)
local myplayer=Player.getNearest(v.x,v.y)
	data.w = 11 * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	if math.abs(v.y-myplayer.y) < 512 and math.abs(v.x-myplayer.x) < 470 then
		if v.x < myplayer.x then
			v.direction = 1
		else
			v.direction = 1
		end
	end
		if data.timer % 10 == 0 then
			v.speedY = data.w * sin(data.w*data.timer)
		end
end

local function variant2(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedX = settings.aamplitude * data.w * cos(data.w*data.timer)
end

local function variant3(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedY = settings.aamplitude * data.w * cos(data.w*data.timer)
end

local function variant4(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedX = settings.aamplitude * -data.w * cos(data.w*data.timer)
	v.speedY = settings.aamplitude * -data.w * sin(data.w*data.timer)
end

local function variant5(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer - 1
	v.speedX = settings.aamplitude * -data.w * cos(data.w*data.timer)
	v.speedY = settings.aamplitude * -data.w * sin(data.w*data.timer)
end


local function variant6(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedX = settings.aamplitude * -data.w * cos(data.w*data.timer / 2)
	v.speedY = settings.aamplitude * data.w * sin(data.w*data.timer)
end

local function variant7(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedX = settings.aamplitude * data.w * cos(data.w*data.timer / 2)
	v.speedY = settings.aamplitude * -data.w * sin(data.w*data.timer)
end

local function variant8(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedY = settings.aamplitude * -data.w * cos(data.w*data.timer / 2)
	v.speedX = settings.aamplitude * data.w * sin(data.w*data.timer)
end

local function variant9(v, data, settings)
	data.w = settings.aspeed * pi/65
	data.timer = data.timer or 0
	data.timer = data.timer + 1
	v.speedY = settings.aamplitude * data.w * cos(data.w*data.timer / 2)
	v.speedX = settings.aamplitude * -data.w * sin(data.w*data.timer)
end

local function variant10(v, data, settings)
	for _,bgo in ipairs(BGO.getIntersecting(v.x+(v.width/2)-0.5,v.y+(v.height/2),v.x+(v.width/2)+0.5,v.y+(v.height/2)+0.5)) do
		if redirector.VECTORS[bgo.id] then -- If this is a redirector and has a speed associated with it
			local redirectorSpeed = redirector.VECTORS[bgo.id]*settings.aspeed -- Get the redirector's speed and make it match the speed in the NPC's settings		
			-- Now, just put that speed from earlier onto the NPC
			v.speedX = redirectorSpeed.x
			v.speedY = redirectorSpeed.y
			if settings.aspeed <= -0.1 then
			v.speedX = -redirectorSpeed.x
			v.speedY = -redirectorSpeed.y
			end
		elseif bgo.id == redirector.TERMINUS then -- If this BGO is one of the crosses
			-- Simply make the NPC stop moving
			v.speedX = 0
			v.speedY = 0
		end
	end
end

function sampleNPC.onTickNPC(v)
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
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end
	
	--Execute main AI. This template just jumps when it touches the ground.
    if v.speedY < 0 then
        v.animationFrame = math.floor(lunatime.tick() / 2) % 12
		v.animationTimer = 0
    elseif v.speedY > 0 then
        v.animationFrame = math.floor(lunatime.tick() / 4) % 12
		v.animationTimer = 0
	end

	if settings.algorithm == 0 then
		variant1(v, data, settings)
	elseif settings.algorithm == 1 then
		variant2(v, data, settings)
	elseif settings.algorithm == 2 then
		variant3(v, data, settings)
	elseif settings.algorithm == 3 then
		variant4(v, data, settings)
	elseif settings.algorithm == 4 then
		variant5(v, data, settings)
	elseif settings.algorithm == 7 then
		variant6(v, data, settings)
	elseif settings.algorithm == 8 then
		variant7(v, data, settings)
	elseif settings.algorithm == 9 then
		variant8(v, data, settings)
	elseif settings.algorithm == 10 then
		variant9(v, data, settings)
	elseif settings.algorithm == 5 or settings.algorithm == 6 then
		variant10(v, data, settings)
	end
end

--Gotta return the library table!
return sampleNPC