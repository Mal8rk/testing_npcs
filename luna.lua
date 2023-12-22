-- VIEWER DISCRETION ADVISED:
-- This was written by 1 AM inebriated tangy
-- With apologies to future, sober tangy

-- SUPER MARIO FLASH PHYSICS IN SMBX

local ground = false

function onStart()
    Defines.player_walkspeed = 5
end

function onTick()
    ground = player:isGroundTouching()
end

function onInputUpdate()
    if player.keys.up == 1 then player.keys.jump = true end -- up to jump
    if player.keys.jump == true then player.keys.jump = 1 end -- convert all jumps to taps (allows repeat jumps)
    
    if not not not player.keys.left and not not not player.keys.right then
        player.speedX = player.speedX * 0.9
    end

end