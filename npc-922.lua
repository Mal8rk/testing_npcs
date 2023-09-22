--[[

	See yiYoshi.lua for credits

]]

local npcManager = require("npcManager")
local npcutils = require("npcs/npcutils")

local yoshi
pcall(function() yoshi = require("yiYoshi/yiYoshi") end)

local ai
pcall(function() ai = require("yiYoshi/egg_ai") end)


local egg = {}
local npcID = NPC_ID


local smokeEffectID = 952


local eggSettings = {
	id = npcID,
	
	width = 32,
	height = 32,


	nohurt = true,
	nogravity = true,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi = true,
	nowaterphysics = false,
	
	jumphurt = true,
	spinjumpsafe = false,
	harmlessgrab = false,
	harmlessthrown = false,

	ignorethrownnpcs = true,


	speed = 16,
	luahandlesspeed = true,

	maxBounces = 3,

	smokeEffectID = smokeEffectID,
}

npcManager.setNpcSettings(eggSettings)
npcManager.registerHarmTypes(npcID,
	{
		HARM_TYPE_OFFSCREEN,
	},
	{
		[HARM_TYPE_JUMP]            = 10,
		[HARM_TYPE_FROMBELOW]       = 10,
		[HARM_TYPE_NPC]             = 10,
		[HARM_TYPE_PROJECTILE_USED] = 10,
		[HARM_TYPE_LAVA]            = {id=13, xoffset=0.5, xoffsetBack = 0, yoffset=1, yoffsetBack = 1.5},
		[HARM_TYPE_HELD]            = 10,
		[HARM_TYPE_TAIL]            = 10,
		[HARM_TYPE_SPINJUMP]        = 10,
		[HARM_TYPE_SWORD]           = 10,
	}
)


if ai then
	ai.registerThrown(npcID)


	yoshi.tongueSettings.thrownEggNPCID = npcID
end

--Register events
function egg.onInitAPI()
	npcManager.registerEvent(npcID, egg, "onTickNPC")
end

function egg.onTickNPC(v)
	local plr = Player.getNearest(v.x + v.width/2, v.y + v.height)
	if Colliders.collide(plr,v) and v.ai1 == 0 then
		v.ai1 = v.ai1 + 1
		plr.speedX = 4 * v.direction
		v.data.speed.x = (v.data.speed.x / 2) * -1
		v.data.speed.y = v.speedY + Defines.npc_grav
	end
	if v.ai1 > 0 then
		v.ai1 = v.ai1 + 1
		if v.ai1 >= 8 then
			v:transform(v.data.mimicID)
		end
	end
end


return egg