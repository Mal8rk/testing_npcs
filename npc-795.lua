local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 40,
	gfxwidth = 52,

	width = 32,
	height = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 9,
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
	nofireball = false,
	noiceball = false,
	noyoshi= false,
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
		[HARM_TYPE_JUMP]=795,
		[HARM_TYPE_FROMBELOW]=796,
		[HARM_TYPE_NPC]=796,
		[HARM_TYPE_PROJECTILE_USED]=796,
		[HARM_TYPE_LAVA]={id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]=796,
		[HARM_TYPE_TAIL]=796,
		[HARM_TYPE_SPINJUMP]=10,
		--[HARM_TYPE_OFFSCREEN]=10,
		[HARM_TYPE_SWORD]=796,
	}
);

local STATE_WALK = 0
local STATE_JUMP = 1
local STATE_DIVE = 2
local STATE_LAND = 3

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
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

	sprite.pivot = args.pivot or Sprite.align.TOPLEFT
	sprite.rotation = args.rotation or 0

	if args.texture ~= nil then
		sprite.texpivot = args.texpivot or sprite.pivot or Sprite.align.TOPLEFT
		sprite.texscale = args.texscale or vector(args.texture.width*(args.width/args.sourceWidth),args.texture.height*(args.height/args.sourceHeight))
		sprite.texposition = args.texposition or vector(-args.sourceX*(args.width/args.sourceWidth)+((sprite.texpivot[1]*sprite.width)*((sprite.texture.width/args.sourceWidth)-1)),-args.sourceY*(args.height/args.sourceHeight)+((sprite.texpivot[2]*sprite.height)*((sprite.texture.height/args.sourceHeight)-1)))
	end

	sprite:draw{priority = args.priority,color = args.color,sceneCoords = args.sceneCoords or args.scene}
end

function sampleNPC.onTickEndNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.rotation then
		data.rotation = 0
	end

	if not data.initialized then
		data.initialized = true
		data.state = data.state or STATE_JUMP
		data.rotation = 0
		data.timer = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		data.rotation = 0
	end

	data.timer = data.timer + 1

	if data.state == STATE_WALK then
		v.animationFrame = math.floor(data.timer / 6) % 4
		v.speedX = 0.7 * v.direction

		if data.timer > 171.5 then
			v.animationFrame = 4
			v.direction = -v.direction
			data.state = STATE_JUMP
			data.timer = 0
			v.speedX = 0
		end
	elseif data.state == STATE_JUMP then
		if data.timer > 1 then
			v.animationFrame = 4
		end

		if data.timer > 10 then
			if data.timer == 11 then v.speedY = -8 end
			v.animationFrame = 5
		end

		if data.timer > 40 then
			data.state = STATE_DIVE
			data.timer = 0
		end
	elseif data.state == STATE_DIVE then
		v.speedY = -Defines.npc_grav + 2
		v.speedX = 2 * v.direction

		if data.timer > 1 then
			v.animationFrame = math.floor(data.timer / 4) % 3 + 6
		end

		if data.timer > 10 then
			v.animationFrame = 8
		end

	    if data.timer >= 2 and data.timer <= 10 then
		    data.rotation = ((data.rotation or 0) + math.deg((1 * v.direction)/((v.width+v.height)/-6)))
	    end

		if v.collidesBlockBottom then
			data.state = STATE_LAND
			data.timer = 0
			v.animationFrame = 0
			data.rotation = 0
		end
	elseif data.state == STATE_LAND then
		v.animationFrame = 4
		v.speedX = 0
		v.speedY = 0

		if data.timer > 20 then
			data.state = STATE_WALK
			v.direction = -v.direction
			data.timer = 0
		end
	end

	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

function sampleNPC.onDrawNPC(v)
	local config = NPC.config[v.id]
	local data = v.data

	if v:mem(0x12A,FIELD_WORD) <= 0 then return end

	local priority = -45
	if config.priority then
		priority = -15
	end

	drawSprite{
	texture = Graphics.sprites.npc[v.id].img,

	x = v.x+(v.width/2)+config.gfxoffsetx,y = v.y+v.height-(config.gfxheight/2)+config.gfxoffsety,
	width = config.gfxwidth,height = config.gfxheight,

	sourceX = 0,sourceY = v.animationFrame*config.gfxheight,
	sourceWidth = config.gfxwidth,sourceHeight = config.gfxheight,

	priority = priority,rotation = data.rotation,
	pivot = Sprite.align.CENTRE,sceneCoords = true,
	}
	npcutils.hideNPC(v)
end

return sampleNPC