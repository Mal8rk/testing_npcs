local npcutils = require "npcs/npcutils"
local yiYoshi = require("yiYoshi/yiYoshi")

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
	gfxheight = 58,
	gfxwidth = 70,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 60,
	height = 46,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 3,
	framestyle = 1,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi= false,
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

		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=npcID,
		[HARM_TYPE_PROJECTILE_USED]=npcID,
		--[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=npcID,
		[HARM_TYPE_TAIL]=npcID,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=npcID
	}
);

--Custom local definitions below

local STATE_HOP = 0
local STATE_ATTACK = 1

local tongueTexture = Graphics.loadImageResolved("toady-tongue.png")
HopSound = Audio.SfxOpen("FrogHop.ogg")
BurbSound = Audio.SfxOpen("FrogBurb.ogg")

BabyGone = 0 
--Register events
function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	--npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
end

local function loaddefaults(data)
	local settings = data._settings

	settings.speedX = settings.speedX or 1
	settings.speedY = settings.speedY or 5.5
	settings.maxHops = settings.maxHops or 3
	settings.hopCooldown = settings.hopCooldown or 24
	settings.lickRange = settings.lickRange or 64
	settings.tongueRange = settings.tongueRange or 48
	settings.tongueCooldown = settings.tongueCooldown or 24
	settings.tongueSpeed = settings.tongueSpeed or 1
	if settings.alwaysLick == nil then settings.alwaysLick = false end
	if settings.segmentedLick == nil then settings.segmentedLick = true end

	if not data.state then
		data.state = STATE_HOP
		data.timer = 0
		data.hops = 0
		data.attackcooldown = 0
		data.licktimer = 0
		data.lickstage = 0
	data.HasBaby = 0 -- Is in possession of baby mario

		if data._settings.maxHops == 0 then data._settings.maxHops = math.huge end
	end
end

local function setframe(v, frame)
	v.animationFrame = frame + (v.direction+1)*NPC.config[v.id].frames*0.5
end

local function getrealtimer(data)
	local realtimer = data.lickstage*16

	if data.lickstage >= data._settings.tongueRange/16 then
		realtimer = data._settings.tongueRange*2 - realtimer
	end

	return realtimer
end

function sampleNPC.onTickNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = data._settings
	


-- I dont remember what this does
if data.HasBaby == 1 and BabyGone == 0 and yiYoshi.playerData.babyMario.state == 1 then
BabyGone = BabyGone + 1

data.HasBaby = 0 
else if yiYoshi.playerData.babyMario.state == 0
then 
BabyGone = 0
data.HasBaby = 0 
data.caughtProcess = 0
end
end

if v:mem(0x12C, FIELD_WORD) > 0 or (v:mem(0x138, FIELD_WORD) > 0 and (v:mem(0x138, FIELD_WORD) ~= 4 and v:mem(0x138, FIELD_WORD) ~= 5)) then 

data.initialized = false
data.state = STATE_HOP
			data.licktimer = 0
		data.lickstage = 0
			data.hastounged = true
end


if data.caughtProcess ~= 0 then
	--When Mario is being handed over, make him land on the NPC
	if yiYoshi.playerData.babyMario.state == 1 then
		if yiYoshi.playerData.babyMario.x < v.x + 32 then
			yiYoshi.playerData.babyMario.speedX = 6
		else
			yiYoshi.playerData.babyMario.speedX = -6
		end
		--Attach him to the npc
	elseif yiYoshi.playerData.babyMario.state == 2 then
		yiYoshi.playerData.babyMario.y = v.y + v.height
		yiYoshi.playerData.babyMario.x = v.x + v.width / 2
	end
end




--More stuff relating to baby mario
if v.isValid and yiYoshi.playerData.starCounter == 0 then
yiYoshi.playerData.babyMario.state = 5
end



if yiYoshi.playerData.babyMario.state == 0 then
BabyGone = 0
end




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
           data.HasBaby = 0
		   data.caughtProcess = 0
		loaddefaults(data)
	end

	--Depending on the NPC, these checks must be handled differently
	if v:mem(0x12C, FIELD_WORD) > 0    --Grabbed
	or v:mem(0x136, FIELD_BOOL)        --Thrown
	or v:mem(0x138, FIELD_WORD) > 0    --Contained within
	then
		--Handling
	end

	v.animationTimer = -999

	if data.state == STATE_HOP and v.collidesBlockBottom and not data.hastounged then

		local p = npcutils.getNearestPlayer(v)

		local xdiff = p.x+p.width/2 - (v.x + v.width/2)

		if (math.abs(xdiff) <= settings.lickRange) or (settings.alwaysLick) then
			data.state = STATE_ATTACK
			data.timer = -settings.tongueCooldown
			data.lastdir = v.direction
			data.licktimer = -settings.tongueCooldown * settings.tongueSpeed + 8
			data.lickstage = 0

			v.direction = xdiff / math.abs(xdiff)

		end

	end

	if data.state == STATE_HOP then

          
		setframe(v, 0)

		if not v.collidesBlockBottom then
			data.timer = 0
		else
			v.speedX = 0

		end

		if data.timer == settings.hopCooldown then
			data.hops = data.hops + 1

			if data.hops > settings.maxHops then
				v.direction = -v.direction
				data.hops = 1

			end

			v.speedX = v.direction * settings.speedX
			v.speedY = -settings.speedY
SFX.play(HopSound)
			data.hastounged = nil

		end

		if v.speedY < 0 then
			setframe(v, 1)
		end

	else

		v.speedX = 0
		setframe(v, 0)

		data.licktimer = data.licktimer + settings.tongueSpeed*2

		if settings.segmentedLick then
			while data.licktimer >= 16 do
				data.lickstage = data.lickstage + 1
				data.licktimer = data.licktimer - 16

			end

		else
			data.lickstage = data.licktimer/16
SFX.play(BurbSound)
		end

		local realtimer = getrealtimer(data)

		if realtimer > 0 then

			local h = tongueTexture.height

			local x = v.x + (v.direction+1)*v.width*0.5 + realtimer*v.direction + realtimer*(-v.direction-1)*0.5
			local y = v.y + v.height/2 - h/4 + 0.5

			
			--Deals with when the player touches the npc if they still have baby mario, essentially handing the baby over. You're free to change this how you like of course
			local p = Player.getIntersecting(x, y, x + realtimer, y + h)

			for _,plr in ipairs(p) do
				if data.HasBaby == 0 and yiYoshi.playerData.babyMario.state == 0 then
					data.HasBaby = 1
					data.caughtProcess = 1					
					plr:harm()
				end 
			end

		end

		if data.lickstage > settings.tongueRange/8 then

			data.state = STATE_HOP
			data.timer = 0
			v.direction = data.lastdir
			data.hastounged = true

		end

	end

	data.timer = data.timer + 1

end

function sampleNPC.onDrawNPC(v)
	local data = v.data
	local settings = data._settings







	if data.state ~= STATE_HOP then

		loaddefaults(data)

		local realtimer = getrealtimer(data)

		if realtimer <= 0 then return end

		setframe(v, 2)

		local w = math.floor(tongueTexture.width/3)
		local h = tongueTexture.height

		local x = v.x + (v.direction+1)*v.width*0.5 + realtimer*v.direction
		local y = v.y + v.height/1.8 - h/4 + 0.5

		local mw = realtimer - w

		if realtimer > 8 then
			-- middle part
			Graphics.drawBox{
				texture = tongueTexture,
				x = x,
				y = y,
				width = mw*-v.direction,
				height = h,
				sourceX = w,
				sourceWidth = w,
				sceneCoords = true,
				priority = -45
			}

			-- right part
			Graphics.drawBox{
				texture = tongueTexture,
				x = x + mw*-v.direction - w*(v.direction+1)*0.5,
				y = y,
				width = w,
				height = h,
				sourceX = w*2,
				sourceWidth = w,
				sceneCoords = true,
				priority = -45
			}
		end

		-- left part
		Graphics.drawBox{
			texture = tongueTexture,
			x = x,
			y = y,
			width = w*-v.direction,
			height = h,
			sourceWidth = w,
			sceneCoords = true,
			priority = -45
		}

		-- dont ask how it works i dont know either

	end

end

--Gotta return the library table!
return sampleNPC