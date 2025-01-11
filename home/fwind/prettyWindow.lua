---------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------PrettyWindown---------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------
local fwind = require("fwind")

---@class PrettyWindown : Windown
---@field title string
local PrettyWindown = setmetatable({}, fwind.Windown)

---@param father Windown?
function PrettyWindown:new(x, y, width, height, father)
    ---@class PrettyWindown
    local instance = fwind.Windown:new(x, y, width, height, father)
    instance.title = ""
    instance.background = 0x666666
    instance.foreground = 0xffffff
    instance.background_factor = 0.8

    instance:addRender(function (fd, _this)
        local gpu = fd.gpu
        gpu.setActiveBuffer(instance.buffer_idx)
        local _r, _g, _b =
        ((instance.background >> 16) & 0xff) * instance.background_factor,
        ((instance.background >> 8) & 0xff) * instance.background_factor,
        (instance.background & 0xff) * instance.background_factor

        gpu.setForeground(instance.foreground)
        gpu.setBackground((math.floor(_r + 0.5) << 16) | (math.floor(_g + 0.5) << 8) | math.floor(_b + 0.5))
        gpu.fill(1, 1, instance.w, 1, " ")
        gpu.set(1, 1, instance.title)
        gpu.setBackground(instance.background)
        gpu.fill(1, 2, instance.w, instance.h, " ")
    end)

    return instance
end

function PrettyWindown:render()
    fwind.Windown.render(self)
end

return {PrettyWindown = PrettyWindown}