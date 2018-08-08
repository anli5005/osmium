local parentShell = shell

local bExit = false
local sDir = (parentShell and parentShell.dir()) or ""
local sPath = (parentShell and parentShell.path()) or ".:/rom/programs"
local tAliases = (parentShell and parentShell.aliases()) or {}
local tCompletionInfo = (parentShell and parentShell.getCompletionInfo()) or {}
local tProgramStack = {}

shell = {}
local function createShellEnv( sDir )
    local tEnv = {}
    tEnv[ "shell" ] = shell
    tEnv[ "multishell" ] = multishell

    local package = {}
    package.loaded = {
        _G = _G,
        bit32 = bit32,
        coroutine = coroutine,
        math = math,
        package = package,
        string = string,
        table = table,
    }
    package.path = "?;?.lua;?/init.lua"
    package.config = "/\n;\n?\n!\n-"
    package.preload = {}
    package.loaders = {
        function( name )
            if package.preload[name] then
                return package.preload[name]
            else
                return nil, "no field package.preload['" .. name .. "']"
            end
        end,
        function( name )
            local fname = string.gsub(name, "%.", "/")
            local sError = ""
            for pattern in string.gmatch(package.path, "[^;]+") do
                local sPath = string.gsub(pattern, "%?", fname)
                if sPath:sub(1,1) ~= "/" then
                    sPath = fs.combine(sDir, sPath)
                end
                if fs.exists(sPath) and not fs.isDir(sPath) then
                    local fnFile, sError = loadfile( sPath, tEnv )
                    if fnFile then
                        return fnFile, sPath
                    else
                        return nil, sError
                    end
                else
                    if #sError > 0 then
                        sError = sError .. "\n"
                    end
                    sError = sError .. "no file '" .. sPath .. "'"
                end
            end
            return nil, sError
        end
    }

    local sentinel = {}
    local function require( name )
        if type( name ) ~= "string" then
            error( "bad argument #1 (expected string, got " .. type( name ) .. ")", 2 )
        end
        if package.loaded[name] == sentinel then
            error("Loop detected requiring '" .. name .. "'", 0)
        end
        if package.loaded[name] then
            return package.loaded[name]
        end

        local sError = "Error loading module '" .. name .. "':"
        for n,searcher in ipairs(package.loaders) do
            local loader, err = searcher(name)
            if loader then
                package.loaded[name] = sentinel
                local result = loader( err )
                if result ~= nil then
                    package.loaded[name] = result
                    return result
                else
                    package.loaded[name] = true
                    return true
                end
            else
                sError = sError .. "\n" .. err
            end
        end
        error(sError, 2)
    end

    tEnv["package"] = package
    tEnv["require"] = require

    return tEnv
end

local function run( _sCommand, ... )
    local sPath = shell.resolveProgram( _sCommand )
    if sPath ~= nil then
        tProgramStack[#tProgramStack + 1] = sPath
        if multishell then
            local sTitle = fs.getName( sPath )
            if sTitle:sub(-4) == ".lua" then
                sTitle = sTitle:sub(1,-5)
            end
            multishell.setTitle( multishell.getCurrent(), sTitle )
        end
        local sDir = fs.getDir( sPath )
        local result = os.run( createShellEnv( sDir ), sPath, ... )
        tProgramStack[#tProgramStack] = nil
        if multishell then
            if #tProgramStack > 0 then
                local sTitle = fs.getName( tProgramStack[#tProgramStack] )
                if sTitle:sub(-4) == ".lua" then
                    sTitle = sTitle:sub(1,-5)
                end
                multishell.setTitle( multishell.getCurrent(), sTitle )
            else
                multishell.setTitle( multishell.getCurrent(), "shell" )
            end
        end
        return result
       else
        printError( "No such program" )
        return false
    end
end

local function tokenise( ... )
    local sLine = table.concat( { ... }, " " )
    local tWords = {}
    local bQuoted = false
    for match in string.gmatch( sLine .. "\"", "(.-)\"" ) do
        if bQuoted then
            table.insert( tWords, match )
        else
            for m in string.gmatch( match, "[^ \t]+" ) do
                table.insert( tWords, m )
            end
        end
        bQuoted = not bQuoted
    end
    return tWords
end

-- Install shell API
function shell.run( ... )
    local tWords = tokenise( ... )
    local sCommand = tWords[1]
    if sCommand then
        return run( sCommand, table.unpack( tWords, 2 ) )
    end
    return false
end

function shell.exit()
    bExit = true
end

function shell.dir()
    return sDir
end

function shell.setDir( _sDir )
    if type( _sDir ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sDir ) .. ")", 2 )
    end
    if not fs.isDir( _sDir ) then
        error( "Not a directory", 2 )
    end
    sDir = _sDir
end

function shell.path()
    return sPath
end

function shell.setPath( _sPath )
    if type( _sPath ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sPath ) .. ")", 2 )
    end
    sPath = _sPath
end

function shell.resolve( _sPath )
    if type( _sPath ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sPath ) .. ")", 2 )
    end
    local sStartChar = string.sub( _sPath, 1, 1 )
    if sStartChar == "/" or sStartChar == "\\" then
        return fs.combine( "", _sPath )
    else
        return fs.combine( sDir, _sPath )
    end
end

local function pathWithExtension( _sPath, _sExt )
    local nLen = #sPath
    local sEndChar = string.sub( _sPath, nLen, nLen )
    -- Remove any trailing slashes so we can add an extension to the path safely
    if sEndChar == "/" or sEndChar == "\\" then
        _sPath = string.sub( _sPath, 1, nLen - 1 )
    end
    return _sPath .. "." .. _sExt
end

function shell.resolveProgram( _sCommand )
    if type( _sCommand ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sCommand ) .. ")", 2 )
    end
    -- Substitute aliases firsts
    if tAliases[ _sCommand ] ~= nil then
        _sCommand = tAliases[ _sCommand ]
    end

    -- If the path is a global path, use it directly
    local sStartChar = string.sub( _sCommand, 1, 1 )
    if sStartChar == "/" or sStartChar == "\\" then
        local sPath = fs.combine( "", _sCommand )
        if fs.exists( sPath ) and not fs.isDir( sPath ) then
            return sPath
        else
            local sPathLua = pathWithExtension( sPath, "lua" )
            if fs.exists( sPathLua ) and not fs.isDir( sPathLua ) then
                return sPathLua
            end
        end
        return nil
    end

     -- Otherwise, look on the path variable
    for sPath in string.gmatch(sPath, "[^:]+") do
        sPath = fs.combine( shell.resolve( sPath ), _sCommand )
        if fs.exists( sPath ) and not fs.isDir( sPath ) then
            return sPath
        else
            local sPathLua = pathWithExtension( sPath, "lua" )
            if fs.exists( sPathLua ) and not fs.isDir( sPathLua ) then
                return sPathLua
            end
        end
    end

    -- Not found
    return nil
end

function shell.programs( _bIncludeHidden )
    local tItems = {}

    -- Add programs from the path
    for sPath in string.gmatch(sPath, "[^:]+") do
        sPath = shell.resolve( sPath )
        if fs.isDir( sPath ) then
            local tList = fs.list( sPath )
            for n=1,#tList do
                local sFile = tList[n]
                if not fs.isDir( fs.combine( sPath, sFile ) ) and
                   (_bIncludeHidden or string.sub( sFile, 1, 1 ) ~= ".") then
                    if #sFile > 4 and sFile:sub(-4) == ".lua" then
                        sFile = sFile:sub(1,-5)
                    end
                    tItems[ sFile ] = true
                end
            end
        end
    end

    -- Sort and return
    local tItemList = {}
    for sItem, b in pairs( tItems ) do
        table.insert( tItemList, sItem )
    end
    table.sort( tItemList )
    return tItemList
end

local function completeProgram( sLine )
    if #sLine > 0 and string.sub( sLine, 1, 1 ) == "/" then
        -- Add programs from the root
        return fs.complete( sLine, "", true, false )

    else
        local tResults = {}
        local tSeen = {}

        -- Add aliases
        for sAlias, sCommand in pairs( tAliases ) do
            if #sAlias > #sLine and string.sub( sAlias, 1, #sLine ) == sLine then
                local sResult = string.sub( sAlias, #sLine + 1 )
                if not tSeen[ sResult ] then
                    table.insert( tResults, sResult )
                    tSeen[ sResult ] = true
                end
            end
        end

        -- Add programs from the path
        local tPrograms = shell.programs()
        for n=1,#tPrograms do
            local sProgram = tPrograms[n]
            if #sProgram > #sLine and string.sub( sProgram, 1, #sLine ) == sLine then
                local sResult = string.sub( sProgram, #sLine + 1 )
                if not tSeen[ sResult ] then
                    table.insert( tResults, sResult )
                    tSeen[ sResult ] = true
                end
            end
        end

        -- Sort and return
        table.sort( tResults )
        return tResults
    end
end

local function completeProgramArgument( sProgram, nArgument, sPart, tPreviousParts )
    local tInfo = tCompletionInfo[ sProgram ]
    if tInfo then
        return tInfo.fnComplete( shell, nArgument, sPart, tPreviousParts )
    end
    return nil
end

function shell.complete( sLine )
    if type( sLine ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( sLine ) .. ")", 2 )
    end
    if #sLine > 0 then
        local tWords = tokenise( sLine )
        local nIndex = #tWords
        if string.sub( sLine, #sLine, #sLine ) == " " then
            nIndex = nIndex + 1
        end
        if nIndex == 1 then
            local sBit = tWords[1] or ""
            local sPath = shell.resolveProgram( sBit )
            if tCompletionInfo[ sPath ] then
                return { " " }
            else
                local tResults = completeProgram( sBit )
                for n=1,#tResults do
                    local sResult = tResults[n]
                    local sPath = shell.resolveProgram( sBit .. sResult )
                    if tCompletionInfo[ sPath ] then
                        tResults[n] = sResult .. " "
                    end
                end
                return tResults
            end

        elseif nIndex > 1 then
            local sPath = shell.resolveProgram( tWords[1] )
            local sPart = tWords[nIndex] or ""
            local tPreviousParts = tWords
            tPreviousParts[nIndex] = nil
            return completeProgramArgument( sPath , nIndex - 1, sPart, tPreviousParts )

        end
    end
    return nil
end

function shell.completeProgram( sProgram )
    if type( sProgram ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( sProgram ) .. ")", 2 )
    end
    return completeProgram( sProgram )
end

function shell.setCompletionFunction( sProgram, fnComplete )
    if type( sProgram ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( sProgram ) .. ")", 2 )
    end
    if type( fnComplete ) ~= "function" then
        error( "bad argument #2 (expected function, got " .. type( fnComplete ) .. ")", 2 )
    end
    tCompletionInfo[ sProgram ] = {
        fnComplete = fnComplete
    }
end

function shell.getCompletionInfo()
    return tCompletionInfo
end

function shell.getRunningProgram()
    if #tProgramStack > 0 then
        return tProgramStack[#tProgramStack]
    end
    return nil
end

function shell.setAlias( _sCommand, _sProgram )
    if type( _sCommand ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sCommand ) .. ")", 2 )
    end
    if type( _sProgram ) ~= "string" then
        error( "bad argument #2 (expected string, got " .. type( _sProgram ) .. ")", 2 )
    end
    tAliases[ _sCommand ] = _sProgram
end

function shell.clearAlias( _sCommand )
    if type( _sCommand ) ~= "string" then
        error( "bad argument #1 (expected string, got " .. type( _sCommand ) .. ")", 2 )
    end
    tAliases[ _sCommand ] = nil
end

function shell.aliases()
    -- Copy aliases
    local tCopy = {}
    for sAlias, sCommand in pairs( tAliases ) do
        tCopy[sAlias] = sCommand
    end
    return tCopy
end

if multishell then
    function shell.openTab( ... )
        local tWords = tokenise( ... )
        local sCommand = tWords[1]
        if sCommand then
            local sPath = shell.resolveProgram( sCommand )
            if sPath == "/rom/programs/shell.lua" then
                return multishell.launch( createShellEnv( "/rom/programs" ), sPath, table.unpack( tWords, 2 ) )
            elseif sPath ~= nil then
                return multishell.launch( createShellEnv( "/rom/programs" ), "/rom/programs/shell.lua", sCommand, table.unpack( tWords, 2 ) )
            else
                printError( "No such program" )
            end
        end
    end

    function shell.switchTab( nID )
        if type( nID ) ~= "number" then
            error( "bad argument #1 (expected number, got " .. type( nID ) .. ")", 2 )
        end
        multishell.setFocus( nID )
    end
end

sPath = ".:/rom/programs"
if term.isColor() then
    sPath = sPath..":/rom/programs/advanced"
end
if turtle then
    sPath = sPath..":/rom/programs/turtle"
else
    sPath = sPath..":/rom/programs/rednet:/rom/programs/fun"
    if term.isColor() then
        sPath = sPath..":/rom/programs/fun/advanced"
    end
end
if pocket then
    sPath = sPath..":/rom/programs/pocket"
end
if commands then
    sPath = sPath..":/rom/programs/command"
end
if http then
    sPath = sPath..":/rom/programs/http"
end
shell.setPath( sPath )
help.setPath( "/rom/help" )

-- Setup aliases
shell.setAlias( "ls", "list" )
shell.setAlias( "dir", "list" )
shell.setAlias( "cp", "copy" )
shell.setAlias( "mv", "move" )
shell.setAlias( "rm", "delete" )
shell.setAlias( "clr", "clear" )
shell.setAlias( "rs", "redstone" )
shell.setAlias( "sh", "shell" )
if term.isColor() then
    shell.setAlias( "background", "bg" )
    shell.setAlias( "foreground", "fg" )
end

-- Setup completion functions
local function completeMultipleChoice( sText, tOptions, bAddSpaces )
    local tResults = {}
    for n=1,#tOptions do
        local sOption = tOptions[n]
        if #sOption + (bAddSpaces and 1 or 0) > #sText and string.sub( sOption, 1, #sText ) == sText then
            local sResult = string.sub( sOption, #sText + 1 )
            if bAddSpaces then
                table.insert( tResults, sResult .. " " )
            else
                table.insert( tResults, sResult )
            end
        end
    end
    return tResults
end
local function completePeripheralName( sText, bAddSpaces )
    return completeMultipleChoice( sText, peripheral.getNames(), bAddSpaces )
end
local tRedstoneSides = redstone.getSides()
local function completeSide( sText, bAddSpaces )
    return completeMultipleChoice( sText, tRedstoneSides, bAddSpaces )
end
local function completeFile( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return fs.complete( sText, shell.dir(), true, false )
    end
end
local function completeDir( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return fs.complete( sText, shell.dir(), false, true )
    end
end
local function completeEither( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return fs.complete( sText, shell.dir(), true, true )
    end
end
local function completeEitherEither( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        local tResults = fs.complete( sText, shell.dir(), true, true )
        for n=1,#tResults do
            local sResult = tResults[n]
            if string.sub( sResult, #sResult, #sResult ) ~= "/" then
                tResults[n] = sResult .. " "
            end
        end
        return tResults
    elseif nIndex == 2 then
        return fs.complete( sText, shell.dir(), true, true )
    end
end
local function completeProgram( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return shell.completeProgram( sText )
    end
end
local function completeHelp( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return help.completeTopic( sText )
    end
end
local function completeAlias( shell, nIndex, sText, tPreviousText )
    if nIndex == 2 then
        return shell.completeProgram( sText )
    end
end
local function completePeripheral( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completePeripheralName( sText )
    end
end
local tGPSOptions = { "host", "host ", "locate" }
local function completeGPS( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, tGPSOptions )
    end
end
local tLabelOptions = { "get", "get ", "set ", "clear", "clear " }
local function completeLabel( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, tLabelOptions )
    elseif nIndex == 2 then
        return completePeripheralName( sText )
    end
end
local function completeMonitor( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completePeripheralName( sText, true )
    elseif nIndex == 2 then
        return shell.completeProgram( sText )
    end
end
local tRedstoneOptions = { "probe", "set ", "pulse " }
local function completeRedstone( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, tRedstoneOptions )
    elseif nIndex == 2 then
        return completeSide( sText )
    end
end
local tDJOptions = { "play", "play ", "stop " }
local function completeDJ( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, tDJOptions )
    elseif nIndex == 2 then
        return completePeripheralName( sText )
    end
end
local tPastebinOptions = { "put ", "get ", "run " }
local function completePastebin( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, tPastebinOptions )
    elseif nIndex == 2 then
        if tPreviousText[2] == "put" then
            return fs.complete( sText, shell.dir(), true, false )
        end
    end
end
local tChatOptions = { "host ", "join " }
local function completeChat( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, tChatOptions )
    end
end
local function completeSet( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 then
        return completeMultipleChoice( sText, settings.getNames(), true )
    end
end
local tCommands
if commands then
    tCommands = commands.list()
end
local function completeExec( shell, nIndex, sText, tPreviousText )
    if nIndex == 1 and commands then
        return completeMultipleChoice( sText, tCommands, true )
    end
end

local function setCompletionFunction(path, func)
  shell.setCompletionFunction(path, func)
  shell.setCompletionFunction(string.gsub(path, '\.lua$', ''), func)
  shell.setCompletionFunction(string.gsub(path:match("^.+/(.+)$"), '\.lua$', ''), func)
end

setCompletionFunction( "/rom/programs/alias.lua", completeAlias )
setCompletionFunction( "/rom/programs/cd.lua", completeDir )
setCompletionFunction( "/rom/programs/copy.lua", completeEitherEither )
setCompletionFunction( "/rom/programs/delete.lua", completeEither )
setCompletionFunction( "/rom/programs/drive.lua", completeDir )
setCompletionFunction( "/rom/programs/edit.lua", completeFile )
setCompletionFunction( "/rom/programs/eject.lua", completePeripheral )
setCompletionFunction( "/rom/programs/gps.lua", completeGPS )
setCompletionFunction( "/rom/programs/help.lua", completeHelp )
setCompletionFunction( "/rom/programs/id.lua", completePeripheral )
setCompletionFunction( "/rom/programs/label.lua", completeLabel )
setCompletionFunction( "/rom/programs/list.lua", completeDir )
setCompletionFunction( "/rom/programs/mkdir.lua", completeFile )
setCompletionFunction( "/rom/programs/monitor.lua", completeMonitor )
setCompletionFunction( "/rom/programs/move.lua", completeEitherEither )
setCompletionFunction( "/rom/programs/redstone.lua", completeRedstone )
setCompletionFunction( "/rom/programs/rename.lua", completeEitherEither )
setCompletionFunction( "/rom/programs/shell.lua", completeProgram )
setCompletionFunction( "/rom/programs/type.lua", completeEither )
setCompletionFunction( "/rom/programs/set.lua", completeSet )
setCompletionFunction( "/rom/programs/advanced/bg.lua", completeProgram )
setCompletionFunction( "/rom/programs/advanced/fg.lua", completeProgram )
setCompletionFunction( "/rom/programs/fun/dj.lua", completeDJ )
setCompletionFunction( "/rom/programs/fun/advanced/paint.lua", completeFile )
setCompletionFunction( "/rom/programs/http/pastebin.lua", completePastebin )
setCompletionFunction( "/rom/programs/rednet/chat.lua", completeChat )
setCompletionFunction( "/rom/programs/command/exec.lua", completeExec )

if turtle then
    local tGoOptions = { "left", "right", "forward", "back", "down", "up" }
    local function completeGo( shell, nIndex, sText )
        return completeMultipleChoice( sText, tGoOptions, true)
    end
    local tTurnOptions = { "left", "right" }
    local function completeTurn( shell, nIndex, sText )
            return completeMultipleChoice( sText, tTurnOptions, true )
    end
    local tEquipOptions = { "left", "right" }
    local function completeEquip( shell, nIndex, sText )
        if nIndex == 2 then
            return completeMultipleChoice( sText, tEquipOptions )
        end
    end
    local function completeUnequip( shell, nIndex, sText )
        if nIndex == 1 then
            return completeMultipleChoice( sText, tEquipOptions )
        end
    end
    setCompletionFunction( "/rom/programs/turtle/go.lua", completeGo )
    setCompletionFunction( "/rom/programs/turtle/turn.lua", completeTurn )
    setCompletionFunction( "/rom/programs/turtle/equip.lua", completeEquip )
    setCompletionFunction( "/rom/programs/turtle/unequip.lua", completeUnequip )
end
