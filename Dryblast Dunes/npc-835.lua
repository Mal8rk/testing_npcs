local npcManager = require("npcManager")
local particles = require("particles")

local star = {}

local npcID = NPC_ID

npcManager.registerDefines(npcID, {NPC.UNHITTABLE})

local config = {
	id = npcID,
	gfxheight = 30,
    gfxwidth = 32,
	width = 32,
	height = 30,
    frames = 2,
    framestyle = 1,
	framespeed = 4, 
    nofireball=0,
	nogravity=1,
	noblockcollision = 0,
	noiceball = true,
	nowaterphysics = true,
	jumphurt = true,
	npcblock = false,
	spinjumpsafe = false,
	noyoshi = true
}

npcManager.setNpcSettings(config)


function star.onInitAPI()
	npcManager.registerEvent(npcID, star, "onTickEndNPC")
end

function star.onTickEndNPC(t)
		--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = t.data

	local explosions = Explosion.get()
	local myExplosionID = Explosion.register(32, 780, 43, true, false)
	
    if t.collidesBlockLeft then
		local newExplosion = Explosion.spawn(t.x+t.width*0.5, t.y+t.height*0.5, myExplosionID)
		if (t.x + t.width > camera.x and t.x < camera.x + 800 and t.y + t.height > camera.y and t.y < camera.y + 600) then
			SFX.play(43)
		end
		t:kill()
	end
	
	if t.collidesBlockUp then
		local newExplosion = Explosion.spawn(t.x+t.width*0.5, t.y+t.height*0.5, myExplosionID)
		if (t.x + t.width > camera.x and t.x < camera.x + 800 and t.y + t.height > camera.y and t.y < camera.y + 600) then
			SFX.play(43)
		end
		t:kill()
	elseif t.collidesBlockRight then
		local newExplosion = Explosion.spawn(t.x+t.width*0.5, t.y+t.height*0.5, myExplosionID)
		if (t.x + t.width > camera.x and t.x < camera.x + 800 and t.y + t.height > camera.y and t.y < camera.y + 600) then
			SFX.play(43)
		end
		t:kill()
	elseif t.collidesBlockBottom then
	    local newExplosion = Explosion.spawn(t.x+t.width*0.5, t.y+t.height*0.5, myExplosionID)
		if (t.x + t.width > camera.x and t.x < camera.x + 800 and t.y + t.height > camera.y and t.y < camera.y + 600) then
			SFX.play(43)
		end
	    t:kill()
	end

	if Colliders.collide(player, t) then
		local newExplosion = Explosion.spawn(t.x+t.width*0.5, t.y+t.height*0.5, myExplosionID)
		if (t.x + t.width > camera.x and t.x < camera.x + 800 and t.y + t.height > camera.y and t.y < camera.y + 600) then
			SFX.play(43)
		end
	    t:kill()
	end
end

return star;
