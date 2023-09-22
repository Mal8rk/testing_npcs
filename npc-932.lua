<<<<<<< HEAD
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 72,
	gfxwidth = 122,

	width = 64,
	height = 64,

	gfxoffsetx = 0,
	gfxoffsety = 6,

	frames = 25,
	framestyle = 1,
	framespeed = 8, 

	speed = 1,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,

	jumphurt = true, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 

	grabside=false,
	grabtop=false,
	staticdirection=true,
}

npcManager.setNpcSettings(sampleNPCSettings)

npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		--HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		--HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		--HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		HARM_TYPE_OFFSCREEN,
		--HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=10,
		--[HARM_TYPE_FROMBELOW]=10,
		[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		--[HARM_TYPE_HELD]=10,
=======
--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")
local colliders = require("colliders")
local sprite

--Create the library table
local guy = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local guySettings = {
	id = npcID,
	gfxheight = 32,
	gfxwidth = 42,
	width = 32,
	height = 32,
	frames = 2,
	framestyle = 1,
	framespeed = 8,
	speed = 1,
	
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = false,
	playerblocktop = false, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = false,
	noiceball = false,
	noyoshi = false,
	nowaterphysics = false,
	--Various interactions
	jumphurt = true, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = false, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false

	grabside=false,
	grabtop=false,
}

--Applies NPC settings
npcManager.setNpcSettings(guySettings)

--Register the vulnerable harm types for this NPC. The first table defines the harm types the NPC should be affected by, while the second maps an effect to each, if desired.
npcManager.registerHarmTypes(npcID,
	{
		--HARM_TYPE_JUMP,
		HARM_TYPE_FROMBELOW,
		HARM_TYPE_NPC,
		HARM_TYPE_PROJECTILE_USED,
		HARM_TYPE_LAVA,
		HARM_TYPE_HELD,
		--HARM_TYPE_TAIL,
		--HARM_TYPE_SPINJUMP,
		--HARM_TYPE_OFFSCREEN,
		HARM_TYPE_SWORD
	}, 
	{
		--[HARM_TYPE_JUMP]=npcID,
		[HARM_TYPE_FROMBELOW]=npcID,
		[HARM_TYPE_NPC]=10,
		--[HARM_TYPE_PROJECTILE_USED]=10,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=10,
>>>>>>> 93261c6854bebf645232dd8ae02ceb7e79a6dfa8
		--[HARM_TYPE_TAIL]=10,
		--[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		--[HARM_TYPE_SWORD]=10,
	}
);

<<<<<<< HEAD
local STATE_IDLE = 0
local STATE_RAM = 1
local STATE_TURN = 2
local STATE_HURT = 3

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

--Thanks to MegaDood for the chasing code

function sampleNPC.onTickEndNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
	local p = Player.getNearest(v.x + v.width/2, v.y + v.height)
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		data.state = nil
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = data.state or STATE_IDLE
		data.timer = data.timer or 0
		data.animTimer = 0
		data.xAccel = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		--Handling
	end

	data.timer = data.timer + 1
	data.animTimer = data.animTimer + 1

	if data.state == STATE_IDLE then
		v.animationFrame =  math.floor(data.timer / 6) % 8

		if math.abs(p.x - v.x) <= 256 and math.abs(p.y - v.y) <= 128 then
			npcutils.faceNearestPlayer(v)
			data.state = STATE_RAM
			data.timer = 0
		end
	elseif data.state == STATE_RAM then
		v.animationFrame =  math.floor(lunatime.tick() / 5) % 4 + 8

		v.speedX = math.clamp(v.speedX + 0.1 * v.direction, -4.5, 4.5)

		if p.x > v.x and v.direction == DIR_LEFT then
			data.state = STATE_TURN
			data.timer = 0
		elseif p.x < v.x and v.direction == DIR_RIGHT then
			data.state = STATE_TURN
			data.timer = 0
		end

		if v.collidesBlockLeft or v.collidesBlockRight then
			data.state = STATE_HURT
			data.timer = 0
		end

	elseif data.state == STATE_TURN then
		v.animationFrame =  math.floor((data.timer - 1) / 4) % 9 + 12

		if v.collidesBlockBottom then
            if v.speedX > 0 then
                v.speedX = math.max(0,v.speedX - 0.15)
            elseif v.speedX < 0 then
                v.speedX = math.min(0,v.speedX + 0.15)
            end
        else
            if v.speedX > 0 then
                v.speedX = math.max(0,v.speedX - 0.15)
            elseif v.speedX < 0 then
                v.speedX = math.min(0,v.speedX + 0.15)
            end
		end

		if data.timer >= 34 then
			data.state = STATE_RAM
			v.direction = -v.direction
			v.animationFrame = 0
			data.timer = 0
		end
	elseif data.state == STATE_HURT then

		if v.collidesBlockBottom then
            if v.speedX > 0 then
                v.speedX = math.max(0,v.speedX - 0.15)
            elseif v.speedX < 0 then
                v.speedX = math.min(0,v.speedX + 0.15)
            end
        else
            if v.speedX > 0 then
                v.speedX = math.max(0,v.speedX - 0.15)
            elseif v.speedX < 0 then
                v.speedX = math.min(0,v.speedX + 0.15)
            end
		end

	    if data.timer >= 78 then
		    data.state = STATE_IDLE
		    data.timer = 0
	    elseif data.timer >= 32 then
		    v.animationFrame =  math.floor(data.timer / 8) % 2 + 23
		elseif data.timer >= 1 then
			v.animationFrame =  math.floor(data.timer / 18) % 2 + 21
			if data.timer == 1 then SFX.play("Pow.wav") end
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
        if reason == HARM_TYPE_NPC and type(culprit) == "NPC" then
			Effect.spawn(774, v.x-40, v.y-40)
		    data.state = STATE_HURT
			data.timer = 0
			data.animTimer = 0
			v.speedX = 0
		end
    else
        for _,p in ipairs(NPC.getIntersecting(v.x - 12, v.y - 12, v.x + v.width + 12, v.y + v.height + 12)) do
            if p.id == 953 then
                p:kill(HARM_TYPE_VANISH)
				Effect.spawn(774, v.x-40, v.y-40)
				data.state = STATE_HURT
				data.timer = 0
				data.animTimer = 0
				v.speedX = 0
            end
        end
    end
end

return sampleNPC
=======
--Register events
function guy.onInitAPI()
	npcManager.registerEvent(npcID, guy, "onTickEndNPC")
	npcManager.registerEvent(npcID, guy, "onDrawNPC")
end

function guy.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local config = NPC.config[v.id]
	local data = v.data
	v.dontMove = false
	
	--If despawned
	if v.despawnTimer <= 0 then
		--Reset our properties, if necessary
		data.initialized = false
		data.timer = 0
		data.changeTimer = 16
		data.rotation = nil
		return
	end

	--Initialize
	if not data.initialized then
		--Initialize necessary data.
		data.initialized = true
		data.timer = data.timer or 0
	end
	
	if data.changeTimer == nil then
		data.changeTimer = data.changeTimer or 16
	end

	if not data.rotation then
		data.rotation = 0
	end
	
	if v:mem(0x12C, FIELD_WORD) == 0 then
		data.timer = data.timer + 1
	end
		data.rotation = ((data.rotation or 0) + math.deg((v.speedX*config.speed)/((v.width+v.height)/4)))
		for _,p in ipairs(NPC.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
			if p:mem(0x12A, FIELD_WORD) > 0 and p:mem(0x138, FIELD_WORD) == 0 and v:mem(0x138, FIELD_WORD) == 0 and (not p.isHidden) and (not p.friendly) and p:mem(0x12C, FIELD_WORD) == 0 and p.idx ~= v.idx and v:mem(0x12C, FIELD_WORD) == 0 and NPC.HITTABLE_MAP[p.id] then
				p:harm(HARM_TYPE_HELD)
				v:harm(HARM_TYPE_HELD)
			end
		end
		if v:mem(0x138, FIELD_WORD) == 0 then
			for _,p in ipairs(Player.getIntersecting(v.x - 1, v.y - 1, v.x + v.width + 1, v.y + v.height + 1)) do
				if data.timer >= 32 then
					v:harm(HARM_TYPE_HELD)
				end
			end
			if v.collidesBlockLeft or v.collidesBlockRight then
				v:harm(HARM_TYPE_HELD)
			end
			
			data.destroyCollider = data.destroyCollider or colliders.Box(v.x - 1, v.y + 1, v.width + 1, v.height - 1);
			data.destroyCollider.x = v.x + 0.5 * (2/v.width) * v.direction;
			
			local list = colliders.getColliding{
			a = data.destroyCollider,
			btype = colliders.BLOCK,
			filter = function(other)
				if other.isHidden or other:mem(0x5A, FIELD_BOOL) then
					return false
				end
				return true
			end
			}
			for _,b in ipairs(list) do		
				b:hit(true)	
			end
		end
		if v.collidesBlockBottom and v:mem(0x138, FIELD_WORD) == 0 and v:mem(0x12C, FIELD_WORD) == 0 then
			if v.speedX >= -3 and v.direction == DIR_LEFT or v.speedX <= 3 and v.direction == DIR_RIGHT then
				data.changeTimer = data.changeTimer - 1
				if data.changeTimer <= 0 then
					data.timer = 0
					data.changeTimer = 16
					v:transform(npcID - 2)
					v.speedX = 0
				end
			end
		else
			data.changeTimer = 16
		end
end

local function drawSprite(args) -- handy function to draw sprites
	args = args or {}

	args.sourceWidth  = args.sourceWidth  or args.width
	args.sourceHeight = args.sourceHeight or args.height

	if sprite == nil then
		sprite = Sprite.box{texture = args.texture}
	else
		sprite.texture = args.texture
	end

	sprite.x,sprite.y = args.x,args.y
	sprite.width,sprite.height = args.width,args.height

	sprite.pivot = args.pivot or Sprite.align.CENTER
	sprite.rotation = args.rotation or 0

	if args.texture ~= nil then
		sprite.texpivot = args.texpivot or sprite.pivot or Sprite.align.CENTER
		sprite.texscale = args.texscale or vector(args.texture.width*(args.width/args.sourceWidth),args.texture.height*(args.height/args.sourceHeight))
		sprite.texposition = args.texposition or vector(-args.sourceX*(args.width/args.sourceWidth)+((sprite.texpivot[1]*sprite.width)*((sprite.texture.width/args.sourceWidth)-1)),-args.sourceY*(args.height/args.sourceHeight)+((sprite.texpivot[2]*sprite.height)*((sprite.texture.height/args.sourceHeight)-1)))
	end

	sprite:draw{priority = args.priority,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end

function guy.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	v.animationFrame = 1
	
	if v.speedX == 0 and v.collidesBlockBottom then
		data.rotation = 0
	end

	if v:mem(0x12A,FIELD_WORD) <= 0 or not data.rotation or data.rotation == 0 then return end

	local priority = -45
	if config.priority then
		priority = -15
	end

	drawSprite{
		texture = Graphics.sprites.npc[v.id].img,

		x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety + 2,
		width = config.gfxwidth,height = config.gfxheight,

		sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
		sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

		priority = priority,rotation = data.rotation,
		pivot = Sprite.align.CENTRE,sceneCoords = true,
	}

	npcutils.hideNPC(v)
end

--Gotta return the library table!
return guy
>>>>>>> 93261c6854bebf645232dd8ae02ceb7e79a6dfa8
