--[[

    distortionEffects.lua
    by MrDoubleA

    Arguments to distortionEffects.create:

    - texture          The texture to use for the distortion. The R channel represents how much a pixel should be shifted horizontally, while the G channel is for vertical.
    - x                X position of the effect.
    - y                Y position of the effect.
    - priority         Render priority of the effect.
    - scale            The scale that the effect should start at.
    - scaleGrowth      How much the scale should increase per frame.
    - strength         How far the effect should shift pixels at the start.
    - strengthFade     How much strength the effect should lose per frame.

]]

local distortionEffects = {}


distortionEffects.objs = {}


distortionEffects.shader = Shader()
distortionEffects.shader:compileFromFile(nil, Misc.resolveFile("distortionEffects.frag"))


distortionEffects.textures = {
    -- both of these are from celeste
    circleHollow = Graphics.loadImageResolved("distortionEffects_circleHollow.png"),
    circle       = Graphics.loadImageResolved("distortionEffects_circle.png"),
}


local copyArgs = {
    {"texture",distortionEffects.textures.circleHollow},{"x"},{"y"},
    {"scale",0},{"scaleGrowth",0.15},{"strength",30},{"strengthFade",3.5},
    {"priority",-4},
}
function distortionEffects.create(args)
    local obj = {}

    for _,copy in ipairs(copyArgs) do
        local value = args[copy[1]]

        if value == nil then
            if copy[2] ~= nil then
                value = copy[2]
            else
                error("Property '".. copy[1].. "' is required.")
            end
        end

        obj[copy[1]] = value
    end

    obj.age = 0

    obj.isValid = true


    table.insert(distortionEffects.objs,obj)
    return obj
end


function distortionEffects.onInitAPI()
    registerEvent(distortionEffects,"onTick")
    registerEvent(distortionEffects,"onCameraDraw")
end


function distortionEffects.onTick()
    for k = #distortionEffects.objs, 1, -1 do -- done backwards to let table.remove work properly
        local obj = distortionEffects.objs[k]

        obj.age = obj.age + 1

        obj.scale = obj.scale + obj.scaleGrowth
        obj.strength = obj.strength - obj.strengthFade

        if obj.strength <= 0 then
            obj.isValid = false

            table.remove(distortionEffects.objs,k)
        end
    end
end


local buffer = Graphics.CaptureBuffer(800,600)

function distortionEffects.onCameraDraw(camIdx)
    local c = Camera(camIdx)

    for _,obj in ipairs(distortionEffects.objs) do
        buffer:captureAt(obj.priority)
        

        local width  = obj.texture.width *obj.scale
        local height = obj.texture.height*obj.scale

        local x = obj.x - width *0.5 - c.x
        local y = obj.y - height*0.5 - c.y

        Graphics.drawBox{
            texture = obj.texture,priority = obj.priority,
            x = x,y = y,width = width,height = height,

            shader = distortionEffects.shader,uniforms = {
                screenBuffer = buffer,
                screenSize = vector(buffer.width,buffer.height),

                strength = obj.strength,
            },
        }
    end
end


return distortionEffects