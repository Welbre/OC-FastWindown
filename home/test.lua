local fwind = require("fwind")

local app = fwind.Application:new(1, 1, 160, 50)
app:isInside(30, 20)
local children = app:addChild(fwind.Windown:new(45, 12, 32, 12, nil))
local children2 = app:addChild(require("fwind.prettyWindow").PrettyWindown:new(1, 1, 60, 17, nil))
c21 = children2:addChild(fwind.Windown:new(40, 1, 16, 5, nil))
children2.title = "God is amazing"


app:addRender(function (fd, this)
    fd.setb(0xcccccc)
    fd.fill(1, 1, 160, 50, " ")
end)

children:addRender(function (fd, this)
    fd.setb(0xffcccc)
    fd.fill(1, 1, this.w, this.h, " ")
end)

c21:addRender(function (fd, this)
    fd.setb(0xccffcc)
    fd.fill(1, 1, this.w, this.h, " ")
end)

local geo = require("fdraw.geo")
children2:addRender(function(fd, this) fd.setb(0xff0000)  geo.draw_line(fd.set, {2,2}, {this.w, this.h}) end)

children2:setPosition(1, 20)

children2:addListener("touch", function (self, application, ...)
    ---@cast self PrettyWindown
    self.title = tostring(math.random(0, 8888888))
    self.foreground = math.random(0, 0xffffff)
    self.background = math.random(0, 0xffffff)
    self.background_factor = math.random(0,255*2) / 255
    self:dirt()
end)

c21:addListener("touch", function (self, application, ...)
    self.setPosition(self, self.x + 1, self.y)
end)

local button = c21:addChild(fwind.Windown:new(1, 1, 1, 1, nil))
button.color = 0x88cc00

button:addRender(function (fd, this)
    fd.setb(this.color)
    fd.fill(this.x ,this.y, this.w, this.h, " ")
end)

button:addListener("touch", function (self, application, ...)
    self.color = math.random(0, 0xffffff)
    self:dirt()
end)

app:run(20)