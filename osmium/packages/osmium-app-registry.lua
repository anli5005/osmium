local lson = opm.require("lson") or opm.require("osmium-lson")

registry = {}

function read(path)
  local file = lson.read(path)
  if file then
    for k,v in ipairs(file) do
      registry[k] = v
    end
  end
end

function readSystem()
  if fs.exists("/osmium/settings/apps.lson") then
    return read("/osmium/settings/apps.lson")
  end
end

function save(path)
  lson.save(path, registry)
end

function saveSystem()
  return save("/osmium/settings/apps.lson")
end

function addApp(app)
  table.insert(registry, app)
end

function removeApp(index)
  registry[index] = nil
end

function addFile(file)
  local name = fs.getName(file):match("[^/]+$")
  if fs.isDir(file) then
    local pathsToTry = {name .. ".lua", name, "startup.lua", "startup"}
    local icon = nil
    local iconPaths = {"icon.nft", "icon.nfp", "icon.nfa", "icon"}
    for h,p in ipairs(iconPaths) do
      local path = fs.combine(file, p)
      if fs.exists(path) and not fs.isDir(path) then
        icon = path
      end
    end
    for i,p in ipairs(pathsToTry) do
      local path = fs.combine(file, p)
      if fs.exists(path) and not fs.isDir(path) then
        addApp({file = name, name = name, exec = path, icon = icon})
        return name
      end
    end
    local files = fs.list(file)
    for j,p in ipairs(files) do
      local path = fs.combine(file, p)
      if fs.exists(path) and not fs.isDir(path) then
        addApp({file = name, name = name, exec = path, icon = icon})
        return name
      end
    end
    return nil, "Directory is empty"
  else
    addApp({file = name, name = name, exec = file})
  end
  return name
end

function addPackage(package)
  local info = opm.resolveInfo(package)
  local name = package
  if info and info.osmium and info.osmium.name then
    name = info.osmium.name
  end
  addApp({package = package, name = name, exec = opm.resolve(package)})
end

function checkAppsFolder()
  local index = {}
  for i,a in ipairs(registry) do
    if a.package then
      index[a.package] = true
    elseif a.file then
      index[a.file] = true
    end
  end

  local packages = opm.listPackages()
  for j,package in ipairs(packages) do
    if not index[package] then
      local meta = opm.getInfo(package)
      if meta and meta.osmium and meta.osmium.app then
        addApp({package = package, name = meta.osmium.name, exec = opm.resolve(package)})
        index[package] = true
      end
    end
  end

  local files = fs.list("/apps")
  for k,file in ipairs(files) do
    local name = file:match("[^/]+$")
    if not index[name] then
      local n, err = addFile(fs.combine("/apps", file))
      if not err then
        index[name] = true
      end
    end
  end
end
