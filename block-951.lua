--[[

    Celeste Madeline Playable
    by MrDoubleA

	See madeline.lua for more

]]

local blockManager = require("blockManager")
local ai = require("dreamBlock_ai")

local dreamBlock = {}
local blockID = BLOCK_ID


local dreamBlockSettings = {
	id = blockID,
	
	frames = 1,
	framespeed = 8,
}

blockManager.setBlockSettings(dreamBlockSettings)

ai.register(blockID)

return dreamBlock