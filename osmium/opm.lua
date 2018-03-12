local directories = {
  "/osmium/packages",
  "/apps"
}

function getPackageDirectories()
  return directories
end

function setPackageDirectories(dirs)
  directories = dirs
end

function addPackageDirectory(dir)
  table.insert(directories, dir)
end

function listPackages()
  local packages = {}
  for i,d in ipairs(directories) do
    if fs.exists(d) and fs.isDir(d) then
      local files = fs.list(d)
      for j,f in ipairs(files) do
        if string.sub(f, -4) == ".lua" then
          table.insert(packages, string.sub(f, 0, -5))
        else
          table.insert(packages, f)
        end
      end
    end
  end
  return packages
end

function resolve(name)
  local path
  for i,d in ipairs(directories) do
    path = fs.combine(d, name)
    if fs.exists(path) then
      if fs.isDir(path) and fs.exists(fs.combine(path, name .. ".lua")) then
        path = fs.combine(path, name .. ".lua")
      elseif fs.isDir(path) and fs.exists(fs.combine(path, name)) then
        path = fs.combine(path, name)
      end
      break
    elseif fs.exists(path .. ".lua") then
      path = path .. ".lua"
      break
    end
    path = nil
  end

  return path
end

function require(name)
  local path = resolve(name)

  if path then
    local env = {}
    setmetatable(env, {__index = _G})
    os.run(env, path)

    local package = {}
    for k,v in pairs(env) do
      if k ~= "_ENV" then
        package[k] = v
      end
    end

    return package
  end
end

function resolveInfo(name)
  for i,d in ipairs(directories) do
    local path = fs.combine(d, name)
    if fs.exists(path) and fs.isDir(path) then
      local metaPath = fs.combine(path, "package.lson")
      if fs.exists(metaPath) then
        return fs.combine(path, "package.lson")
      end
    end
  end
end

local lson = require("lson") or require("osmium-lson")

function getInfo(name)
  local path = resolveInfo(name)
  if path then
    return lson.read(path)
  end
end

function resolveDir(name)
  for i,d in ipairs(directories) do
    local path = fs.combine(d, name)
    if fs.exists(path) and fs.isDir(path) then
      return path
    end
  end
end

function resolveFile(name, file)
  local path = resolveDir(name)
  if path then
    return fs.combine(path, file)
  end
end
