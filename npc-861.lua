local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 256,
	gfxwidth = 256,

	width = 128,
	height = 128,

	gfxoffsetx = 0,
	gfxoffsety = 2,

	frames = 32,
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
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 

	grabside=false,
	grabtop=false,

	beamColor     = 0xF8F8F8,                                                 
	beamPointGFX  = Graphics.loadImage(Misc.resolveFile("ice_beam_end.png")),
	beamMiddleGFX = Graphics.loadImage(Misc.resolveFile("ice_beam_middle.png")), 
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

local STATE_IDLE = 0
local STATE_TURN = 1
local STATE_RUN = 2
local STATE_JUMP = 3
local STATE_SHOOT = 4

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickEndNPC")
	npcManager.registerEvent(npcID, sampleNPC, "onDrawNPC")
end

local colBox = Colliders.Box(0,0,0,0)

local function tableMultiInsert(tbl,tbl2)
    for _,v in ipairs(tbl2) do
        table.insert(tbl,v)
    end
end

local beamSpeed = 16
local function doBeamLogic(v,dangerous)
    local config = NPC.config[v.id]
    local data = v.data

    data.beamProgress = data.beamProgress or 0

    local maxMoves = 48
    if dangerous then
        data.beamProgress = math.min(maxMoves,data.beamProgress + 1)
        maxMoves = data.beamProgress
    end
    
    for move=0,maxMoves-1 do
        colBox.x = (v.x+(v.width/2))+((move*beamSpeed)*v.direction)-(beamSpeed/2)
        colBox.y = (v.y+(v.height/2))-(v.height*0.375)
        colBox.width,colBox.height = beamSpeed,(v.height*0.75)

        local hit = false

        -- Account for blocks
        for _,w in ipairs(Colliders.getColliding{a = colBox,b = Block.SOLID.. Block.PLAYER.. Block.MEGA_SMASH,btype = Colliders.BLOCK}) do
            if Block.MEGA_SMASH_MAP[w.id] and dangerous then
                w:remove(true)
            end

            hit = true
        end
        
        -- Account for NPCs
        hit = hit or (#Colliders.getColliding{a = colBox,btype = Colliders.NPC,filter = solidNPCFilter} > 0)

        if hit then
            data.beamProgress = move
            return true
        end
    end

    data.beamProgress = maxMoves

    -- Hurt players
    if dangerous then
        local width,height = (data.beamProgress*beamSpeed),(v.height*0.75)
        local x,y = v.x+(v.width/2)-(width/2)+((width/2)*v.direction),v.y+(v.height/2)-(v.height*0.375)

        for _,w in ipairs(Player.getIntersecting(x,y,x+width,y+height)) do
            w:harm()
        end
    end

    return false
end

function isNearPit(v)
	--This function either returns false, or returns the direction the npc should go to. numbers can still be used as booleans.
	local testblocks = Block.SOLID.. Block.SEMISOLID.. Block.PLAYER

	local centerbox = Colliders.Box(v.x-32, v.y, 8, v.height + 10)
	local l = centerbox
	if v.direction == DIR_RIGHT then
		l.x = l.x + 192
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

function sampleNPC.onTickEndNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.state = data.state or STATE_IDLE
		data.timer = data.timer or 0
		data.animTimer = 0

		data.beamProgress = nil
        data.beamOpacity = nil
        data.beamHeight = nil
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		--Handling
	end

	data.timer = data.timer + 1

	if data.state == STATE_IDLE then
		v.animationFrame = math.floor(data.timer / 10) % 4

		if data.timer > 180 then
			data.state = STATE_JUMP
			data.timer = 0
		end
	elseif data.state == STATE_RUN then
		if data.timer > 72 then
			v.animationFrame = math.floor(data.timer / 6) % 4 + 10
			v.speedX = 4 * v.direction

			if data.timer % 24 == 0 then
				Defines.earthquake = 4
			end
		elseif data.timer > 60 then
			v.animationFrame = 9
		elseif data.timer > 54 then
			data.animTimer = data.animTimer + 1
			v.animationFrame = math.floor(data.animTimer / 6) % 2 + 8
	    elseif data.timer > 42 then
			v.animationFrame = 7
		elseif data.timer > 36 then
			v.animationFrame = math.floor(data.timer / 5) % 3 + 5
		elseif data.timer > 29 then
			v.animationFrame = math.floor(data.timer / 4.6) % 2 + 8
		elseif data.timer > 18 then
			v.animationFrame = 7
	    elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer / 5) % 4 + 4
		end

		if isNearPit(v) or v.collidesBlockLeft or v.collidesBlockRight then
			data.state = STATE_TURN
			data.timer = 0
		end
	elseif data.state == STATE_TURN then
		v.speedX = 0
		if data.timer > 20 then
			v.direction = -v.direction
			v.animationFrame = 0
			data.state = STATE_IDLE
			data.timer = 0
		elseif data.timer > 1 then
			v.animationFrame = math.floor(data.timer / 8) % 3 + 14
		end
	elseif data.state == STATE_JUMP then
		if data.timer > 280 then
			data.state = STATE_SHOOT
			data.timer = 0
		elseif data.timer > 106 then
			v.animationFrame = math.floor(data.timer / 10) % 4
		elseif data.timer > 103 then
			v.animationFrame = 18
			if data.timer == 104 then Defines.earthquake = 4.7 end
	    elseif data.timer > 84 then
			v.animationFrame = 19
	    elseif data.timer > 81 then
		    v.animationFrame = 18
			if data.timer == 82 then v.speedY = -3 end
	    elseif data.timer > 66 then
			v.animationFrame = 0
		elseif data.timer > 63 then
			v.animationFrame = 18
			if data.timer == 64 then Defines.earthquake = 4.7 end
	    elseif data.timer > 44 then
			v.animationFrame = 19
	    elseif data.timer > 41 then
		    v.animationFrame = 18
			if data.timer == 42 then v.speedY = -3 end
	    elseif data.timer > 26 then
			v.animationFrame = 0
		elseif data.timer > 23 then
			v.animationFrame = 18
			if data.timer == 24 then Defines.earthquake = 4.7 end
	    elseif data.timer > 4 then
			v.animationFrame = 19
	    elseif data.timer > 1 then
		    v.animationFrame = 18
			if data.timer == 2 then v.speedY = -3 end
	    end 
	elseif data.state == STATE_SHOOT then
		if data.timer > 480 then
			data.state = STATE_RUN
			data.timer = 0

			data.laserProgress = nil
			data.laserOpacity = nil
			data.laserHeight = nil
		elseif data.timer > 354 then
			v.animationFrame = math.floor(data.timer / 10) % 4
		elseif data.timer > 350 then
			v.animationFrame = 25
		elseif data.timer > 124 then
			v.animationFrame = math.floor(lunatime.tick() / 2) % 2 + 26

			if data.timer == 124 then
				data.beamProgress = 0
			elseif data.timer > 124 then
				doBeamLogic(v,true)
			else
				doBeamLogic(v,false)

				data.beamHeight = math.max(0,(data.beamHeight or (v.height*0.75))-((data.timer/v.height)*0.4))
				data.beamOpacity = math.min(0.65,(data.beamOpacity or 0) + 0.1)
			end
		elseif data.timer > 120 then
			v.animationFrame = 25
		elseif data.timer > 110 then
			v.animationFrame = 24
		elseif data.timer > 50 then
			v.animationFrame = 0
	    elseif data.timer > 1 then
		    v.animationFrame = math.floor(lunatime.tick() / 3) % 3 + 21
	    end 
	end

	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});
end

function sampleNPC.onDrawNPC(v)
    if v.despawnTimer <= 0 then return end

    local config = NPC.config[v.id]
    local data = v.data

	Text.print(data.timer, 8, 8)
	Text.print(data.beamProgress, 8, 32)

	if not data.beamProgress then return end

	local color = config.beamColor or Color.white
    if type(color) == "number" then
        color = Color.fromHexRGBA(color)
    end

	local priority = -45
    if config.priority then
        priority = -15
    end

	local beamWidth = (data.beamProgress*beamSpeed)

	if data.timer > 124 and data.state == STATE_SHOOT then -- Actual beam
        local vertexCoords,textureCoords = {},{}

        local colorMultiplier = (math.abs(math.cos(data.timer/16))+0.5)*2
        local beamColor = Color(color.r*colorMultiplier,color.g*colorMultiplier,color.b*colorMultiplier,color.a)


        -- Middle part
        local middleFrame = (math.floor(data.timer/4)%4)

        local i = 0
        while i <= beamWidth do
            local segmentWidth = math.min(config.beamMiddleGFX.width,beamWidth-i)

            tableMultiInsert(vertexCoords,{
                (v.x+(v.width/2)+((i               )*v.direction)),(v.y+(v.height/2)-(config.beamMiddleGFX.height/6)),
                (v.x+(v.width/2)+((i+(segmentWidth))*v.direction)),(v.y+(v.height/2)-(config.beamMiddleGFX.height/6)),
                (v.x+(v.width/2)+((i               )*v.direction)),(v.y+(v.height/2)+(config.beamMiddleGFX.height/6)),
                (v.x+(v.width/2)+((i               )*v.direction)),(v.y+(v.height/2)+(config.beamMiddleGFX.height/6)),
                (v.x+(v.width/2)+((i+(segmentWidth))*v.direction)),(v.y+(v.height/2)-(config.beamMiddleGFX.height/6)),
                (v.x+(v.width/2)+((i+(segmentWidth))*v.direction)),(v.y+(v.height/2)+(config.beamMiddleGFX.height/6)),
            })
            tableMultiInsert(textureCoords,{
                (0                                       ),((middleFrame  )/3),
                (segmentWidth/config.beamMiddleGFX.width),((middleFrame  )/3),
                (0                                       ),((middleFrame+1)/3),
                (0                                       ),((middleFrame+1)/3),
                (segmentWidth/config.beamMiddleGFX.width),((middleFrame  )/3),
                (segmentWidth/config.beamMiddleGFX.width),((middleFrame+1)/3),
            })

            i = i + (config.beamMiddleGFX.width)
        end

        Graphics.glDraw{texture = config.beamMiddleGFX,vertexCoords = vertexCoords,textureCoords = textureCoords,color = beamColor,priority = priority+0.01,sceneCoords = true}


        -- Start and end points
        local pointFrame = (math.floor(data.timer/4)%2)

        for i=0,1 do
            Graphics.drawBox{
                texture = config.beamPointGFX,x = v.x+(v.width/2)+(((v.width*0.4)*v.direction)*((i+1)%2))-(config.beamPointGFX.width/2)+((i*beamWidth)*v.direction),y = v.y+(v.height/2)-(config.beamPointGFX.height/4),
                width = (config.beamPointGFX.width),height = (config.beamPointGFX.height/2),color = beamColor,priority = priority+0.01,sceneCoords = true,
                textureCoords = {
                    (0),((pointFrame  )/2),
                    (1),((pointFrame  )/2),
                    (1),((pointFrame+1)/2),
                    (0),((pointFrame+1)/2),
                },
            }
        end
	end
end

return sampleNPC