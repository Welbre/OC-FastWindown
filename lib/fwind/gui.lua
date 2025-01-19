local fwind = require("fwind")

---@class Button : Windown
local Button = {}

---@param x integer
---@param y integer
---@param width integer
---@param height integer
---@param onClick fun(self: Button, application: Application, ...:any)
---@param father Windown?
function Button:new(x, y, width, height, onClick, father)
    local instance = fwind.Windown:new(x, y, width, height, father)

    instance:addListener("touch", onClick)

    return instance
end

return {Button = Button}