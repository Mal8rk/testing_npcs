local npcManager = require("npcManager")

local sampleNPC = {}

local npcID = NPC_ID

local sampleNPCSettings = {
	id = npcID,

	gfxheight = 48,
	gfxwidth = 34,

	width = 32,
	height = 32,

	gfxoffsetx = 0,
	gfxoffsety = 0,

	frames = 8,
	framestyle = 1,
	framespeed = 6, 

	speed = 1,

	npcblock = false,
	npcblocktop = false, 
	playerblock = false,
	playerblocktop = false, 

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = false,
	noyoshi= false,
	nowaterphysics = false,

	jumphurt = false, 
	spinjumpsafe = false, 
	harmlessgrab = false, 
	harmlessthrown = false, 

	grabside=true,
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



function sampleNPC.onInitAPI()
	npcManager.registerEvent(npcID, sampleNPC, "onTickNPC")
end

function sampleNPC.onTickNPC(v)

	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if v.despawnTimer <= 0 then
		data.initialized = false
		return
	end

	if not data.initialized then
		data.initialized = true
		data.timer = 0
	end

	if v:mem(0x12C, FIELD_WORD) > 0    
	or v:mem(0x136, FIELD_BOOL)        
	or v:mem(0x138, FIELD_WORD) > 0    
	then
		--Handling
	end

	data.timer = data.timer + 1
	v.animationFrame = math.floor(data.timer / 6) % 6
	v.animationTimer = 0

	local explosions = Explosion.get()
	local myExplosionID = Explosion.register(32, 781, 43, true, false)

	if data.timer == 500 then
	    v.animationFrame = math.floor(data.timer / 6) % 2 + 6
		v.animationTimer = 0
	elseif data.timer == 50 then
		local newExplosion = Explosion.spawn(v.x+v.width*0.5, v.y+v.height*0.5, myExplosionID)
        SFX.play(43)
		v:kill()
	end

    if v:mem(0x12C,FIELD_WORD) == 0 then
        if v.collidesBlockBottom then
            if v.speedX > 0 then
                v.speedX = math.max(0,v.speedX - 0.35)
            elseif v.speedX < 0 then
                v.speedX = math.min(0,v.speedX + 0.35)
            end
        else
            if v.speedX > 0 then
                v.speedX = math.max(0,v.speedX - 0.05)
            elseif v.speedX < 0 then
                v.speedX = math.min(0,v.speedX + 0.05)
            end
        end
            if v:mem(0x12E,FIELD_WORD) > 0 then
			    data.timer = 0
			end
        end
    end

	Text.print(data.timer, 8, 8)

return sampleNPC