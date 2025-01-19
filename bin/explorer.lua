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

local function createNewFolder(name)
    local folder = fwind.Application:new(1, 1, 10, 5)
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

local function getList(path)
    local ins = {}
    for fn in fs.list(path) do
        table.insert(ins, fn)
    end
    return ins
end

local function setDir(path)
    selected_dir = path

    for _, child in pairs(app.children) do
        child:close()
    end
    local x = 1
    local y = 1
    local back = app:addChild(createNewFolder(".."))
    back:setPosition(x, y)
    x = x + 11
    local list = getList(path)
    table.sort(list)
    for _, fn in pairs(list) do
        local folder = app:addChild(createNewFolder(fn))
        folder:setPosition(x, y)
        x = x + 11
        if (x + 10) > screen_resolution[1] then
            x = 1
            y = y + 6
            if (y + 5) > screen_resolution[2] then
                break
            end
        end
    end

end

cd = function(path)
    local resolved = resolve_path(path)
    if fs.isDirectory(resolved) then
        setDir(resolved)
    else
        os.execute("edit " .. resolved)
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