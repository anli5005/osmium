function create(osmium, user, permissions, options)
  local self = {osmium = osmium, user = user, permissions = permissions or {}, options = options or {}}
  self.osmium.user = user
  self.user = user

  function self.canAccess(file, mode)
    -- Remove slashes if there are any.
    local path = {}
    for component in string.gmatch(file, "[^/]+") do
      table.insert(path, component)
    end

    if not self.permissions.otherUsers then
      if path[1] == "home" then
        if mode == "w" and not path[2] then
          return false, "otherUsers"
        end
        if path[2] and path[2] ~= self.user.username and path[2] ~= "" then
          return false, "otherUsers"
        end
      end
    end

    if mode == "w" and not self.permissions.editSystem then
      if path[1] == "osmium" or path[1] == "boot" or path[1] == "startup" or path[1] == "startup.lua" then
        return false, "editSystem"
      end
    end

    return true
  end

  if self.osmium then
    function self.osmium.canReadFile(file)
      local allowed, permission = self.canAccess(file, "r")
      return allowed, permission
    end

    function self.osmium.canWriteFile(file)
      local allowed, permission = self.canAccess(file, "w")
      return allowed, permission
    end
  end

  if self.options.requestPermission then
    function self.osmium.requestPermission(permission)
      return not not self.options.requestPermission(permission)
    end
  end

  function self.tryAccessing(file, mode)
    local allowed, permission = self.canAccess(file, mode)
    if self.options.requestPermission and not allowed then
      self.options.requestPermission(permission)
    end
    return allowed
  end

  function self.generateEnv()
    local env = {osmium = self.osmium, os = {}, fs = {}, term = term}
    setmetatable(env, {__index = _G})

    for k,v in pairs(fs) do
      env.fs[k] = v
    end

    function env.fs.list(path)
      if self.tryAccessing(path, "r") then
        return fs.list(path)
      else
        return {}
      end
    end

    function env.fs.exists(path)
      if self.tryAccessing(fs.getDir(path), "r") then
        return fs.exists(path)
      else
        return false
      end
    end

    function env.fs.isDir(path)
      if self.tryAccessing(fs.getDir(path), "r") then
        return fs.isDir(path)
      else
        return false
      end
    end

    function env.fs.isReadOnly(path)
      if self.tryAccessing(path, "w") then
        return fs.isReadOnly(path)
      else
        return true
      end
    end

    function env.fs.getDrive(path)
      if self.tryAccessing(fs.getDir(path), "r") then
        return fs.getDrive(path)
      else
        return nil
      end
    end

    function env.fs.getSize(path)
      if self.tryAccessing(path, "r") then
        return fs.isDir(path)
      else
        return 0
      end
    end

    function env.fs.getFreeSpace(path)
      if self.tryAccessing(fs.getDir(path), "r") then
        return fs.getFreeSpace(path)
      else
        return nil
      end
    end

    function env.fs.makeDir(path)
      if self.tryAccessing(path, "w") then
        return fs.makeDir(path)
      end
    end

    function env.fs.move(from, to)
      if self.tryAccessing(from, "r") and self.tryAccessing(from, "w") and self.tryAccessing(to, "w") then
        return fs.move(from, to)
      end
    end

    function env.fs.copy(from, to)
      if self.tryAccessing(from, "r") and self.tryAccessing(to, "w") then
        return fs.copy(from, to)
      end
    end

    function env.fs.delete(path)
      if self.tryAccessing(path, "w") then
        return fs.delete(path)
      end
    end

    function env.fs.open(path, filemode)
      local mode = "w"
      if filemode == "r" or filemode == "rb" then
        mode = "r"
      end
      if self.tryAccessing(path, mode) then
        return fs.open(path, mode)
      else
        return nil
      end
    end

    function env.fs.find(path)
      local files = fs.find(path)
      local result = {}
      for _,file in ipairs(files) do
        if self.canAccess(file, "r") then
          table.insert(result, file)
        end
      end
      return result
    end

    function env.fs.complete(partial, path, files, slashes)
      if self.tryAccessing(path, "r") then
        return fs.complete(partial, path, files, slashes)
      else
        return {}
      end
    end

    env.loadfile = function( _sFile, _tEnv )
      if type( _sFile ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sFile ) .. ")", 2 )
      end
      if _tEnv ~= nil and type( _tEnv ) ~= "table" then
        error( "bad argument #2 (expected table, got " .. type( _tEnv ) .. ")", 2 )
      end
      local file = env.fs.open( _sFile, "r" )
      if file then
        local func, err = load( file.readAll(), env.fs.getName( _sFile ), "t", _tEnv )
        file.close()
        return func, err
      end
      return nil, "File not found"
    end

    env.dofile = function( _sFile )
      if type( _sFile ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sFile ) .. ")", 2 )
      end
      local fnFile, e = loadfile( _sFile, _G )
      if fnFile then
        return fnFile()
      else
        error( e, 2 )
      end
    end

    for k,v in pairs(os) do
      env.os[k] = v
    end

    function env.os.run( _tEnv, _sPath, ... )
      if type( _tEnv ) ~= "table" then
        error( "bad argument #1 (expected table, got " .. type( _tEnv ) .. ")", 2 )
      end
      if type( _sPath ) ~= "string" then
        error( "bad argument #2 (expected string, got " .. type( _sPath ) .. ")", 2 )
      end
      local tArgs = table.pack( ... )
      local tEnv = _tEnv
      setmetatable( tEnv, { __index = env } )
      local fnFile, err = loadfile( _sPath, tEnv )
      if fnFile then
        setfenv(fnFile, tEnv)
        local ok, err = pcall( function()
          fnFile( table.unpack( tArgs, 1, tArgs.n ) )
        end )
        if not ok then
          if err and err ~= "" then
            printError( err )
          end
          return false
        end
        return true
      end
      if err and err ~= "" then
        printError( err )
      end
      return false
    end

    local tAPIsLoading = {}
    function env.os.loadAPI( _sPath )
      if type( _sPath ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sPath ) .. ")", 2 )
      end
      local sName = fs.getName( _sPath )
      if sName:sub(-4) == ".lua" then
        sName = sName:sub(1,-5)
      end
      if tAPIsLoading[sName] == true then
        printError( "API "..sName.." is already being loaded" )
        return false
      end
      tAPIsLoading[sName] = true

      local tEnv = {}
      setmetatable( tEnv, { __index = env } )
      local fnAPI, err = loadfile( _sPath, tEnv )
      if fnAPI then
        setfenv(fnAPI, tEnv)
        local ok, err = pcall( fnAPI )
        if not ok then
          printError( err )
          tAPIsLoading[sName] = nil
          return false
        end
      else
        printError( err )
        tAPIsLoading[sName] = nil
        return false
      end

      local tAPI = {}
      for k,v in pairs( tEnv ) do
        if k ~= "_ENV" then
          tAPI[k] =  v
        end
      end

      _G[sName] = tAPI
      tAPIsLoading[sName] = nil
      return true
    end

    function env.os.unloadAPI( _sName )
      if type( _sName ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sName ) .. ")", 2 )
      end
      if _sName ~= "_G" and type(_G[_sName]) == "table" then
        _G[_sName] = nil
      end
    end

    local tApis = fs.list( "rom/apis" )
    for n,sFile in ipairs( tApis ) do
      if string.sub( sFile, 1, 1 ) ~= "." then
        local sPath = fs.combine( "rom/apis", sFile )
        if not fs.isDir( sPath ) then
          local name = fs.getName(sPath)
          if name ~= "term" and name ~= "term.lua" and name ~= "fs" and name ~= "fs.lua" then
            if name:sub(-4) == ".lua" then
              name = name:sub(1, -5)
            end
            local tEnv = {}
            setmetatable(tEnv, {__index = env})

            local fnAPI, err = loadfile(sPath, tEnv)
            if fnAPI then
              setfenv(fnAPI, tEnv)
              local ok, err = pcall(fnAPI)
              if not ok then
                printError(err)
              else
                env[name] = {}
                for k,v in pairs(tEnv) do
                  if k ~= "_ENV" then
                    env[name][k] = v
                  end
                end
              end
            else
              printError(err)
            end
          end
        end
      end
    end

    local opmenv = {}
    setmetatable(opmenv, {__index = env})
    os.run(opmenv, "/osmium/opm.lua")

    local o = {}
    for k,v in pairs(opmenv) do
      if k ~= "_ENV" then
        o[k] = v
      end
    end
    env.opm = o

    env.shell = env.opm.require("minimal-shell").shell
    env.shell.setDir(fs.combine("home", self.user.username))

    return env
  end

  function self.run(path, ...)
    local env = self.generateEnv()
    local fn, err = env.loadfile(path)
    local ok
    if fn then
      setfenv(fn, env)
      ok, err = pcall(function()
        fn(unpack(arg))
      end)
    else
      ok = false
    end
    if not ok then
      term.setBackgroundColor(colors.black)
      term.setTextColor(colors.red)
      local w, h = term.getSize()
      if h < 3 then
        term.write(err)
      else
        print(err)
      end
    end
  end

  return self
end
