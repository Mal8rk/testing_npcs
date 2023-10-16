--NPCManager is required for setting basic NPC properties
local npcManager = require("npcManager")

--Create the library table
local ThrowBarrel = {}
--NPC_ID is dynamic based on the name of the library file
local npcID = NPC_ID

--Defines NPC config for our NPC. You can remove superfluous definitions.
local ThrowBarrelSettings = {
	id = npcID,
	--Sprite size
	gfxheight = 40,
	gfxwidth = 40,
	--Hitbox size. Bottom-center-bound to sprite size.
	width = 40,
	height = 40,
	--Sprite offset from hitbox for adjusting hitbox anchor on sprite.
	gfxoffsetx = 0,
	gfxoffsety = 0,
	--Frameloop-related
	frames = 1,
	framestyle = 0,
	framespeed = 8, --# frames between frame change
	--Movement speed. Only affects speedX by default.
	--speed = 1,
	--Collision-related
	npcblock = false,
	npcblocktop = false, --Misnomer, affects whether thrown NPCs bounce off the NPC.
	playerblock = true,
	playerblocktop = true, --Also handles other NPCs walking atop this NPC.

	nohurt=true,
	nogravity = false,
	noblockcollision = false,
	nofireball = true,
	noiceball = true,
	noyoshi= true,
	nowaterphysics = false,
	--Various interactions
	jumphurt = false, --If true, spiny-like
	spinjumpsafe = false, --If true, prevents player hurt when spinjumping
	harmlessgrab = true, --Held NPC hurts other NPCs if false
	harmlessthrown = false, --Thrown NPC hurts other NPCs if false
	grabtop = true,
	grabside = true

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
npcManager.setNpcSettings(ThrowBarrelSettings)

--Custom local definitions below

--Register events
function ThrowBarrel.onInitAPI()
	npcManager.registerEvent(npcID, ThrowBarrel, "onTickEndNPC")
end

function ThrowBarrel.onTickEndNPC(v)
	--Don't act during time freeze
	if Defines.levelFreeze then return end
	
	local data = v.data
	
	if data.harmzone == nil then
		data.harmzone = Colliders.Box()
	end
	data.harmzone.x = v.x - 2
	data.harmzone.y = v.y + 18
	data.harmzone.width = v.width + 4
	data.harmzone.height = 4
	if data.throwtime == nil then
		data.throwtime = 0
	end
	if data.thrown == nil then
		data.thrown = false
		v.animationFrame = 0
		v.dontMove = true
	end
	if v:mem(0x136, FIELD_BOOL) and v.speedX ~= 0 then
		data.thrown = true
	else
		data.thrown = false
	end
	if not data.thrown then
		data.throwtime = 0
		for _,a in ipairs(NPC.get(-1,player.section)) do
			if Colliders.collide(data.harmzone,a) then
				if not a.friendly and not NPC.config[a.id].nohurt and not NPC.get(10) and (v:mem(0x12C, FIELD_WORD) > 0 or data.thrown) then
					Animation.spawn(760,v.x,v.y)
					for i = -1,1 do
						if i ~= 0 then
							local debris1 = Animation.spawn(761,v.x,v.y)
							debris1.speedX = 2*i
							debris1.speedY = -4 - i
							local debris2 = Animation.spawn(762,v.x,v.y)
							debris2.speedX = 2*i
							debris2.speedY = -4 + i
						end
					end
					v:kill()
					a:harm()
					SFX.play("Barrel_Break.wav")
					if v.ai1 and v.ai1 > 0 then
						NPC.spawn(v.ai1, v.x+20, v.y+20, v:mem(0x146,FIELD_WORD), false, true)
					end
				end
			end
		end
	else
		data.throwtime = data.throwtime + 1
		if Colliders.collide(data.harmzone,player) and data.throwtime > 16 and v:mem(0x130, FIELD_WORD) <= 0 then
			player:harm()
		end
		v.speedX = 4*v.direction
		if v.direction == 1 then
			v.animationFrame = 4 - math.floor((lunatime.tick() % 32)/8)
		else
			v.animationFrame = 1 + math.floor((lunatime.tick() % 32)/8)
		end
		if v:mem(0x0C,FIELD_WORD) == 2 or v:mem(0x10,FIELD_WORD) == 2 then
			Animation.spawn(760,v.x,v.y)
			for i = -1,1 do
				if i ~= 0 then
					local debris1 = Animation.spawn(761,v.x,v.y)
					debris1.speedX = 2*i
					debris1.speedY = -4 - i
					local debris2 = Animation.spawn(762,v.x,v.y)
					debris2.speedX = 2*i
					debris2.speedY = -4 + i
				end
			end
			v:kill()
			SFX.play("Barrel_Break.wav")
			if v.ai1 and v.ai1 > 0 then
				NPC.spawn(v.ai1, v.x+20, v.y+20, v:mem(0x146,FIELD_WORD), false, true)
			end
		end
	end
	
	--If despawned
	if v:mem(0x12A, FIELD_WORD) <= 0 then
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
end

--Gotta return the library table!
return ThrowBarrel