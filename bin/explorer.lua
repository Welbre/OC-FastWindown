local fwind = require("fwind")
local filesystem = require("filesystem")
local shell = require("shell")

local screen_resolution = {fwind.fdraw.gpu}

local screen_idx = fwind.Application:new(x, y, width, height)