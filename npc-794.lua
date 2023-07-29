local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 46,
	gfxwidth = 36,

	width = 32,
	height = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 6,
	framestyle = 1,
	framespeed = 6, 

	speed = 1,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 

	nohurt=false,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = false,
	noyoshi= true,
	nowaterphysics = false,

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 

	grabside=false,
	grabtop=false,

	spring = 26,
	jumpheight = -2,
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

local STATE_MOVING = 0
local STATE_BOUNCED = 1

function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
	registerEvent(sampleNPC, "onNPCHarm")
end

function sampleNPC.onTickNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
	local settings = v.data._settings
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.timer = 0
		data.state = STATE_MOVING
		v.animationTimer = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		--Handling
	end

	if data.state == STATE_MOVING then
	    if v.collidesBlockBottom then
		    data.timer = data.timer + 1
		    if data.timer <= 24 then
			    v.animationFrame = 2
				v.animationTimer = 0
		    end
	    end
	
	    if data.timer == 1 and v.collidesBlockBottom then
		    v.speedX = 0
	    elseif data.timer >= 24 then
			v.animationFrame = math.floor(data.timer / 6) % 2 + 3
	        v.animationTimer = 0
		    npcutils.faceNearestPlayer(v)
		    v.speedX = sampleNPCSettings.speed * v.direction
		    v.speedY = sampleNPCSettings.jumpheight
		    data.timer = 0
	    end
	end

	if data.state == STATE_BOUNCED then
	    data.timer = data.timer + 1
		if data.timer == 1 then
		    SFX.play(24)
			player.speedY = -14
			if data.timer >= 24 then
			    v.animationFrame = 2
				v.animationTimer = 0
			else
			    v.animationFrame = math.floor(data.timer / 6) % sampleNPCSettings.frames
			end
		elseif data.timer >= 32 then
		    data.state = STATE_MOVING
			data.timer = 0
		end
	end

	-- animation controlling
	v.animationFrame = npcutils.getFrameByFramestyle(v, {
		frame = data.frame,
		frames = sampleNPCSettings.frames
	});

	if settings.list == nil then settings.list = 0 end
	if settings.list == 0 then
        for _,plr in ipairs(Player.get()) do
            if Colliders.speedCollide(plr,v) and plr.speedY > 1 and plr.y < v.y - (plr.height / 2) then
                plr.speedY = -15
                data.state = STATE_BOUNCED
                data.timer = 0
                v.speedX = 0
            end
        end
	elseif settings.list == 1 then
        for _,plr in ipairs(Player.get()) do
            if Colliders.speedCollide(plr,v) and plr.speedY > 1 and plr.y < v.y - (plr.height / 2) then
			    SFX.play(2)
				SFX.play(27)
			    plr.speedY = -8
				local spring = NPC.spawn(sampleNPCSettings.spring, v.x, v.y, player.section)
				spring.speedY = -4
                v:kill(HARM_TYPE_VANISH)
            end
        end
	end
end

return sampleNPC