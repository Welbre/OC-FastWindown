---------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------Transfomation2D--------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------

---@class Transfomation2D
---@field cache Transfomation2D?
local Transform2D = {}

---@param instance table?
---@param x number
---@param y number
---@param transform_father Transfomation2D?
function Transform2D:new(x, y, transform_father, instance)
    assert(x, "x is null!")
    assert(y, "y is null!")
    ---@class Transfomation2D
    instance = setmetatable(instance or {}, Transform2D)
    instance.x, instance.y, instance.transform_father = x, y, transform_father
    self.__index = self
    instance.cache = nil

    return instance
end

---@protected
function Transform2D:notifyTranformChange()
    self.cache = nil
end

function Transform2D:getGlobalTransform()
    --if self.cache then return self.cache end

    local accumulator = {0, 0}
    local next = self.transform_father
    while next do
        accumulator[1] = accumulator[1] + next.x -1
        accumulator[2] = accumulator[2] + next.y -1
        next = next.transform_father
    end
    self.cache = Transform2D:new(accumulator[1], accumulator[2])
    return self.cache
end

---@param x number
---@param y number
function Transform2D:transform(x, y)
    return self.x + x, self.y + y
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------Rectangle----------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------

---@class Rectangle : Transfomation2D
local Rectangle = setmetatable({}, Transform2D)

---@param instance table?
---@param x integer
---@param y integer
---@param width integer
---@param height integer
---@param transform_father Transfomation2D?
function Rectangle:new(x, y, width, height, transform_father, instance)
    ---@class Rectangle
    instance = Transform2D:new(x, y, transform_father, instance)
    instance.w = width
    instance.h = height
    setmetatable(instance, self)
    self.__index = self

    return instance
end

function Rectangle:isInside(x, y)
    assert(self, "self is null!")
    assert(x, "x is null!")
    assert(y, "y is null!")
    local gx, gy = self:getGlobalTransform():transform(self.x, self.y)
    if (gx > x) then return false end
    if (gx + self.w -1 < x) then return false end
    if (gy > y) then return false end
    if (gy + self.h -1 < y) then return false end
    return true
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------------------Canvas----------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------

local fdraw = require("fdraw").setVersion(1)

---@class Canvas : Rectangle
local Canvas = setmetatable({}, Rectangle)

---@param instance table?
---@param x integer
---@param y integer
---@param width integer
---@param height integer
---@param transform_father Transfomation2D?
function Canvas:new(x, y, width, height, transform_father, instance)
    ---@class Canvas
    instance = Rectangle:new(x, y, width, height, transform_father, instance)
    instance.buffer_idx = fdraw.new(width, height)
    instance.render_pipe = {}

    setmetatable(instance, self)
    self.__index = self

    return instance
end

---Start the render process in the canvas vram buffer, don't forget to use Canvas:doneRender to finish the render session.
function Canvas:begingRender()
    fdraw.select(self.buffer_idx)
    return fdraw
end

---Finish the render session.
function Canvas:doneRender()
    fdraw.flush()
end

function Canvas:render()
    fdraw.select(self.buffer_idx)
    for _, r in pairs(self.render_pipe) do
        fdraw.draw(r, fdraw, self)
        fdraw.flush()
    end
end

---@param fun fun(fd:FdrawRelease, this:Windown)
function Canvas:addRender(fun)
    assert(fun, "Function can't be null!", 2)
    table.insert(self.render_pipe, fun)
end

function Canvas:close()
    fdraw.free(self.buffer_idx)
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------EventHandler--------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------

---@alias oc_listeners_type "key_down" | "key_up" | "touch" | "drag" | "drop" | "scroll"
---@class EventHandler
---@field package listeners table<string, fun(handler:EventHandler, app:Application, ...)[]>
local EventHandler = {}

---@param instance table?
function EventHandler:new(instance)
    ---@class EventHandler
    instance = instance or {}
    instance.listeners = {}

    setmetatable(instance, self)
    self.__index = self

    return instance
end

---@param _type oc_listeners_type
---@param fun fun(self:EventHandler, application:Application, ...)
function EventHandler:addListener(_type, fun)
    if type(_type) ~= "string" then error("Bad argument #1 (string expected, got " .. type(_type) .. ")", 2) end
    if type(fun) ~= "function" then error("Bad argument #2 (function expected, got " .. type(fun) .. ")", 2) end
    local array = self.listeners[_type]
    ---Create if don't exist
    if not array then array = {} self.listeners[_type] = array end
    table.insert(array, fun)
end

---@param _type string | oc_listeners_type
---@param app Application
---@return boolean
function EventHandler:runListener(_type, app, ...)
    if type(_type) ~= "string" then error("Bad argument #1 (string expected, got " .. type(_type) .. ")", 2) end
    if type(app) ~= "table" then error("Bad argument #2 (table expected, got " .. type(app) .. ")", 2) end
    local array = self.listeners[_type]

    if array then
        for _,v in pairs(array) do
            app:addListenerRun(v, self, ...)
        end
        return true
    else
        return false
    end
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------
----------------------------------------------------------------------Windown----------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------

---@class Windown : Canvas, EventHandler
---@field buffer_idx integer
---@field children Windown[]
---@field render_pipe fun(fd:FdrawRelease ,self:Windown)[]
---@field isDirt boolean
---@field father Windown?
local Windown
Windown = setmetatable({}, {__index = function (tb, key)
    if rawget(Windown, key) then return Windown[key] end
    if Canvas[key] then return Canvas[key] end
    return EventHandler[key]
end})
Windown.__index = Windown

---@param x integer
---@param y integer
---@param width integer
---@param height integer
---@param instance table?
---@param father Windown?
function Windown:new(x, y, width, height, father, instance)
    ---@class Windown
    instance = instance or {}
    Canvas:new(x, y, width, height, father, instance)
    EventHandler:new(instance)

    setmetatable(instance, Windown)
    self.__index = self

    instance.children = {}
    instance.isDirt = true

    if father then father:addChild(instance) end

    return instance
end

---@param _type string | oc_listeners_type
---@param app Application
---@return boolean
function Windown:runListener(_type, app, ...)
    local array = self.listeners[_type]
    ---Check if the type have a position, if true verify if the possition is on windown
    if (_type == "touch") or (_type == "drop") or (_type == "drag") or (_type == "scroll") then
        local args = {...}
        if not self:isInside(args[2], args[3]) then return false end
        ---Check if a children can handle the click
        ---If true, this means that the children is in front of this window, so return to avoid that the listeners of this window ran!
        for i=#self.children, 1, -1 do
            local child = self.children[i]
            if child:runListener(_type, app, ...) then return true end
        end
    else
        ---Run in recustion to reach all children
        for _, child in pairs(self.children) do child:runListener(_type, app, ...) end
        return true
    end

    if array then
        for _,v in pairs(array) do
            app:addListenerRun(v, self, ...)
        end
    end

    return true
end

---@param skipChild boolean if the children render will be skiped
function Windown:doneRender(skipChild)
    --Dirt all father to force this windown to be re drawed
    self:dirt()
    fdraw.flush()
    if not skipChild then
        for _, child in pairs(self.children) do
            child:render()
            fdraw.gpu.bitblt(self.buffer_idx, child.x, child.y, child.w, child.h, child.buffer_idx, 1, 1)
        end
    end
    ---Set this windown to don't be rended, to avoid the render function overwrite the changes after of begingRender
    self.isDirt = false
end

function Windown:render()
    ---Check if need to render
    if not self.isDirt then return end

    fdraw.select(self.buffer_idx)
    for _, r in pairs(self.render_pipe) do
        fdraw.draw(r, fdraw, self)
        fdraw.flush()
    end
    for _, child in pairs(self.children) do
        child:render()
        fdraw.gpu.bitblt(self.buffer_idx, child.x, child.y, child.w, child.h, child.buffer_idx, 1, 1)
    end
    self.isDirt = false
end

function Windown:dirt()
    self.isDirt = true
    if self.father then self.father:dirt() end
end

---@generic T : Windown
---@param child T
---@return T
function Windown:addChild(child)
    if child.father then
        if self == child then error("Tryied to add child in self!", 2) end
        ---Check child is allready add to self
        if child.father == self then return child
        else
            child.father:removeChild(child)
        end
    end

    child.father = self
    child.transform_father = self
    table.insert(self.children, child)
    ---Update the internal tranform
    self:notifyTranformChange()
    child:notifyTranformChange()

    self:dirt()
    return child
end

---@param child Windown
---@return boolean
function Windown:removeChild(child)
    if child.father ~= self then return false end

    for i=1, #self.children do
        if self.children[i] == child then
            table.remove(self.children, i)
            child.father = nil
            child.transform_father = nil
            self:notifyTranformChange()
            child:notifyTranformChange()
            self:dirt()
            return true
        end
    end
    return false
end

---@param x integer
---@param y integer
function Windown:setPosition(x, y)
    self.x, self.y = x, y
    self:dirt()
    self:notifyTranformChange()
end

function Windown:close()
    Canvas.close(self)
    for _, child in pairs(self.children) do child:close() end
end

---------------------------------------------------------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------Application----------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------------------------------

---@class Application : Windown
---@field package occ_listeners integer[]
local Application = setmetatable({}, Windown)

---@param app Application
local function createListeners(app)
    local event = require("event")
    ---@param _app Application
    local function handle_listener(tp, _app)
        return tp, function(_, addrr, char, code, player_name)
            _app:runListener(tp, _app, addrr, char, code, player_name)
        end
    end
    table.insert(app.occ_listeners, event.listen(handle_listener("key_down", app)))
    table.insert(app.occ_listeners, event.listen(handle_listener("key_up", app)))
    table.insert(app.occ_listeners, event.listen(handle_listener("touch", app)))
end

---@param instance table?
function Application:new(x, y, width, height, instance)
    ---@class Application
    instance = Windown:new(x, y, width, height, nil, instance)

    instance.isRunning = false
    instance.occ_listeners = {}
    instance.listenersRun = {}

    setmetatable(instance, self)
    self.__index = self

    createListeners(instance)

    return instance
end

---@param ... string
function Application:throws(...)
    local term = require("term")
    local event = require("event")

    self:close()
    os.sleep(0.1)

    local gpu = fdraw.gpu
    gpu.setForeground(0xffffff)
    gpu.setBackground(0x78D7)
    term.setCursorBlink(false)
    term.clear()

    local err = {...}
    for i, vl in pairs(err) do
        print(vl)
        ::head::
        print("Press 'S' to save, ".. (i== #err and "" or "'Q' to quit, ") .. "'T' to traceback, or any key to " .. (i == #err and "continue.." or "next error"))
        local _, _, byte = event.pull("key_down")
        local _char = string.char(byte)
        if _char == "s" or _char == "S" then
            ::io_read::
            io.stdout:write("Type the file path: ")
            local input = io.stdin:read("l")
            local file, io_err = io.open(input, "w")
            if not file then print(io_err) goto io_read end
            file:write(vl)
            file:write(debug.traceback(vl, 2))
            file:close()
            print("Error saved in " .. input .. " with success!")
            print("Press any key to continue..")
            event.pull("key_down")
        elseif _char == "q" or _char == "Q" then
            break
        elseif _char == "t" or _char == "T" then
            term.clear()
            print(debug.traceback(vl, 2))
            goto head
        end
        term.clear()
    end

    gpu.setForeground(0xffffff)
    gpu.setBackground(0)
    term.clear()
    term.setCursorBlink(true)
end

---@param self Application
---@param show_fps boolean if the fps will be print on top right.
local function renderThread(self, dt, show_fps)
    local event = require("event")
    local idx_of_interrupt = event.listen("interrupted", function() self.isRunning = false end)

    if show_fps then
        ::continue::
        while self.isRunning do
            local t0 = os.clock()
            if not self:executeAllListenersRun() then goto continue end

            local ok, err_msg = pcall(self.render, self)
            if not ok then self:throws(err_msg) break end

            local t1 = os.clock()
            fdraw.gpu.setActiveBuffer(self.buffer_idx)
            fdraw.gpu.setBackground(0xcccccc)
            fdraw.gpu.setForeground(0x888800)
            if t1-t0 >= dt then
                fdraw.gpu.set(1,1, "gpu overload!")
            else
                fdraw.gpu.set(1,1, "fps:" .. (1/(t1-t0)))
            end
            fdraw.gpu.bitblt(0, self.x, self.y, self.w, self.h, self.buffer_idx)
            os.sleep(dt)
        end
    else
        ::continue::
        while self.isRunning do
            if not self:executeAllListenersRun() then goto continue end

            local ok, err_msg = pcall(self.render, self)
            if not ok then self:throws(err_msg) break end
            fdraw.gpu.bitblt(0, self.x, self.y, self.w, self.h, self.buffer_idx)
            os.sleep(dt)
        end
    end


    event.cancel(idx_of_interrupt)

    self:close()
end

---@param frequence integer
---@param show_fps boolean? if the fps will be print on top right.
function Application:run(frequence, show_fps)
    self.isRunning = true
    renderThread(self, (1/frequence) or 0.1, show_fps or false)
end

function Application:close()
    Windown.close(self)
    self.isRunning = false
    --Stop all occ_listeners
    local event = require("event")
    for _, idx in pairs(self.occ_listeners) do event.cancel(idx) end
end

---@param fun function
---@param handler EventHandler the event handler that will be run the listener.
---@package
function Application:addListenerRun(fun, handler, ...)
   table.insert(self.listenersRun, {fun, handler, {...}})
end
---@package
function Application:executeAllListenersRun()
    for _, data in pairs(self.listenersRun) do
        local ok, err = pcall(data[1], data[2], self, table.unpack(data[3]))
        if not ok then 
            self:throws(err)
            self.listenersRun = {}
            return false
        end
    end
    self.listenersRun = {}
    return true
end

return {Rectangle = Rectangle, Windown = Windown, Application = Application, fdraw = fdraw}