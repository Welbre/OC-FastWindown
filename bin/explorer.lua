local fwind = require("fwind")
local gui = require("fwind.gui")
local fs = require("filesystem")
local shell = require("shell")

local screen_resolution = {fwind.fdraw.gpu.getResolution()}
local selected_dir = ""

app = fwind.Application:new(1, 1, screen_resolution[1], screen_resolution[2])

local function resolve_path(path, ext)
    local dir = path
    if dir:find("/") ~= 1 then
      dir = fs.concat(selected_dir, dir)
    end
    local name = fs.name(path)
    dir = fs[name and "path" or "canonical"](dir)
    local fullname = fs.concat(dir, name or "")

    if not ext then
      return fullname
    elseif name then
      -- search for name in PATH if no dir was given
      -- no dir was given if path has no /
      local search_in = path:find("/") and dir or os.getenv("PATH")
      for search_path in string.gmatch(search_in, "[^:]+") do
        -- resolve search_path because they may be relative
        local search_name = fs.concat(resolve_path(search_path), name)
        if not fs.exists(search_name) then
          search_name = search_name .. "." .. ext
        end
        -- extensions are provided when the caller is looking for a file
        if fs.exists(search_name) and not fs.isDirectory(search_name) then
          return search_name
        end
      end
    end

    return nil, "file not found"
end

local cd
local setDir
local getList

local function createNewFolder(name)
    local folder = fwind.Windown:new(1, 1, 10, 5)
    local fd = folder:begingRender()
    if fs.isDirectory(resolve_path(name)) then
        fd.setb(0xffdd00)
    else
        fd.setb(0x4444ff)
    end
    fd.fill(1, 1, 10, 5, " ")
    fd.flush()
    fd.setf(0)
    fd.set(1, 5, name)
    folder:doneRender(true)

    folder:addListener("touch", function (self, application)
        cd(name)
    end)

    return folder
end

function getList(path)
    local list = {}
    for fn in fs.list(path) do
        table.insert(list, fn)
    end
    table.sort(list)
    return list
end

function cd(path)
    local resolved = resolve_path(path)
    if fs.isDirectory(resolved) then
        setDir(resolved)
    else
        os.execute("edit " .. resolved)
    end
end

function setDir(dir)
    selected_dir = dir
    app:removeAllChildrens()

    local x, y = 1, 1
    local back = app:addChild(createNewFolder(".."))
    local close = fwind.Windown:new(151,46,10,5)
    local fd = close:begingRender()
    fd.setb(0xff0000)
    fd.fill(1, 1, 10, 5, " ")
    close:doneRender(true)
    close:addListener("touch", function (self, application, ...)
        application:close()
    end)

    app:addChild(close)

    back.x, back.y = 1, 1
    x = x + 12
    for _,name in ipairs(getList(selected_dir)) do
        local folder = app:addChild(createNewFolder(name))
        folder.x,folder.y = x, y
        x = x + 12
        if (x + 10) > screen_resolution[1] then
            x = 1
            y = y + 6
            if (y + 5) > screen_resolution[2] then
                break
            end
        end
    end
end

---Background
app:addRender(function (fd, this)
    fd.setf(0xffffff)
    fd.setb(0xcccccc)
    fd.fill(this.x, this.y, this.w, this.h, " ")
end)

setDir(shell.getWorkingDirectory())

app:run(20)