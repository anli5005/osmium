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

function require(name)
  local path
  for i,d in ipairs(directories) do
    path = fs.combine(d, name)
    if fs.exists(path) then
      break
    elseif fs.exists(path .. ".lua") then
      path = path .. ".lua"
      break
    end
    path = nil
  end

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
