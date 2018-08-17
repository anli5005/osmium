term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()

local args = {...}

local AppRegistry = opm.require("osmium-app-registry")
local IronEventLoop = opm.require("iron-event-loop")
local OsmiumSandbox = opm.require("osmium-sandbox")
local eventLoop = IronEventLoop.create()

local users = opm.require("osmium-users")
local user = users.getUser(args[1])
user.id = args[1]

local appNames = {}
AppRegistry.readSystem()
for i,a in ipairs(AppRegistry.registry) do
  appNames[a.exec] = a.name
end

local currentTerm = term.current()
local w, h = term.getSize()

local threads = {}
local nextID = 1
local visibleThread = nil
local focus = 1
local barThread = nil
local runningThread = nil
local homeThread = nil

local unexpected = true

local function createThread(fn, win)
  local thread = {coroutine = coroutine.create(fn), window = win or window.create(currentTerm, 1, 1, w, h - 1, false), interacted = false}
  thread.current = thread.window
  threads[nextID] = thread
  local curr = term.current()
  term.redirect(thread.window)
  thread.success, thread.filter = coroutine.resume(thread.coroutine)
  thread.current = term.current()
  thread.status = coroutine.status(thread.coroutine)
  term.redirect(curr)
  nextID = nextID + 1
  return nextID - 1, thread
end

local function switchTo(index)
  if visibleThread and visibleThread ~= index then
    threads[visibleThread].window.setVisible(false)
  end
  visibleThread = index
  threads[index].window.setVisible(true)
  threads[index].window.redraw()
  --[[if focus == 1 then
    focus = 0
  end]]--
end

local function removeThread(index)
  if visibleThread == index then
    visibleThread = nil
    for i,t in pairs(threads) do
      if i ~= index and t and t.status ~= "dead" and barThread ~= i then
        switchTo(i)
        break
      end
    end
  end
  if barThread == index then
    barThread = nil
  end
  threads[index] = nil
  eventLoop.emit("osmium:barupdate")
end

eventLoop.all(function(event, ...)
  if event == "terminate" then
    if visibleThread ~= homeThread then
      removeThread(visibleThread)
    end
  elseif event ~= "mouse_click" and event ~= "mouse_up" and event ~= "mouse_scroll" and event ~= "mouse_drag" and event ~= "char" and event ~= "key" and event ~= "paste" and event ~= "key_up" and event ~= "osmium:barupdate" then
    local toRemove = {}
    for i,t in pairs(threads) do
      if t and (t.filter == event or not t.filter) then
        runningThread = i
        term.redirect(t.current)
        t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
        t.status = coroutine.status(t.coroutine)
        t.current = term.current()
        t.interacted = true
        if t.status == "dead" then
          table.insert(toRemove, i)
        end
      end
    end
    for _,i in ipairs(toRemove) do
      removeThread(i)
    end
  elseif event == "mouse_click" then
    local y = arg[3]
    if y < h then
      if visibleThread then
        focus = 1
        local t = threads[visibleThread]
        if t.filter == event or not t.filter then
          runningThread = visibleThread
          term.redirect(t.current)
          t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
          t.status = coroutine.status(t.coroutine)
          t.current = term.current()
          t.interacted = true
          if t.status == "dead" then
            removeThread(visibleThread)
          end
        end
      end
    elseif barThread then
      focus = 1
      local t = threads[barThread]
      if t.filter == event or not t.filter then
        runningThread = barThread
        term.redirect(t.current)
        local resumeArgs = arg
        resumeArgs[3] = 1
        t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(resumeArgs))
        t.status = coroutine.status(t.coroutine)
        t.current = term.current()
        t.interacted = true
        if t.status == "dead" then
          removeThread(barThread)
        end
      end
    else
      focus = 0
    end
  elseif event == "mouse_up" or event == "mouse_scroll" or event == "mouse_drag" then
    local y = arg[3]
    if y < h then
      if visibleThread then
        local t = threads[visibleThread]
        if t.filter == event or not t.filter then
          runningThread = visibleThread
          term.redirect(t.current)
          t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
          t.status = coroutine.status(t.coroutine)
          t.current = term.current()
          t.interacted = true
          if t.status == "dead" then
            removeThread(visibleThread)
          end
        end
      end
    elseif barThread then
      local t = threads[barThread]
      if t.filter == event or not t.filter then
        runningThread = barThread
        term.redirect(t.current)
        local resumeArgs = arg
        resumeArgs[3] = 1
        t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(resumeArgs))
        t.status = coroutine.status(t.coroutine)
        t.current = term.current()
        t.interacted = true
        if t.status == "dead" then
          removeThread(barThread)
        end
      end
    end
  elseif event == "key" or event == "char" or event == "key_up" or event == "paste" then
    if focus == 1 then
      if visibleThread then
        local t = threads[visibleThread]
        if t.filter == event or not t.filter then
          runningThread = visibleThread
          term.redirect(t.current)
          t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
          t.status = coroutine.status(t.coroutine)
          t.current = term.current()
          t.interacted = true
          if t.status == "dead" then
            removeThread(visibleThread)
          end
        end
      end
    elseif focus == 2 then
      if barThread then
        local t = threads[barThread]
        if t.filter == event or not t.filter then
          runningThread = barThread
          term.redirect(t.current)
          local resumeArgs = arg
          resumeArgs[3] = 1
          t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(resumeArgs))
          t.status = coroutine.status(t.coroutine)
          t.current = term.current()
          t.interacted = true
          if t.status == "dead" then
            removeThread(barThread)
          end
        end
      end
    end
  elseif event == "osmium:barupdate" then
    if barThread then
      local t = threads[barThread]
      if t and (t.filter == event or not t.filter) then
        local c = term.current()
        term.redirect(t.current)
        t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
        t.current = term.current()
        term.redirect(c)
        t.status = coroutine.status(t.coroutine)
        t.interacted = true
        if t.status == "dead" then
          removeThread(barThread)
        end
      end
    end
  end

  if focus == 1 then
    if visibleThread then
      threads[visibleThread].window.restoreCursor()
    end
  elseif focus == 2 then
    if barThread then
      threads[barThread].window.restoreCursor()
    end
  else
    currentTerm.setCursorBlink(false)
  end
end)

local osmiumAPI = {}

local function createSandbox()
  local permissions = {}
  if user.admin then
    permissions.editSystem = true
    permissions.otherUsers = true
  end
  return OsmiumSandbox.create(osmiumAPI, user, permissions, {
    multishell = {
      launch = osmiumAPI.runWithEnv,
      getCurrent = function()
        return runningThread
      end,
      getCount = function()
        return #threads
      end,
      setFocus = function(thread)
        if thread ~= barThread and threads[thread] then
          switchTo(thread)
        end
      end,
      setTitle = function(thread, title)
        if thread ~= barThread and thread ~= homeThread and threads[thread] then
          threads[thread].description = title
          eventLoop.emit("osmium:barupdate")
        end
      end,
      getTitle = function(thread)
        if thread ~= barThread and threads[thread] then
          return threads[thread].description
        end
      end,
      getFocus = function(thread)
        return visibleThread
      end
    }
  })
end

local function run(path, ...)
  local sandbox = createSandbox()
  sandbox.run(path, ...)
end

function osmiumAPI.run(...)
  local args = arg
  local i = createThread(function()
    run(unpack(args))
  end)
  local path = args[1]
  if path:sub(1,1) == "/" then
    path = path:sub(2)
  end
  if threads[i] then
    if appNames[path] then
      threads[i].name = appNames[path]
      threads[i].isApp = true
    else
      threads[i].name = fs.getName(path)
    end
  end
  eventLoop.emit("osmium:barupdate")
  return i
end

function osmiumAPI.runWithEnv(tEnv, ...)
  local args = arg
  local i = createThread(function()
    local sandbox = createSandbox()
    local env = sandbox.generateEnv()
    setmetatable(tEnv, {__index = env})
    env.os.run(tEnv, unpack(args))
  end)
  local path = args[1]
  if path:sub(1,1) == "/" then
    path = path:sub(2)
  end
  if threads[i] then
    if appNames[path] then
      threads[i].name = appNames[path]
      threads[i].isApp = true
    else
      threads[i].name = fs.getName(path)
    end
  end
  eventLoop.emit("osmium:barupdate")
  return i
end

function osmiumAPI.switchTo(thread)
  if thread ~= barThread then
    switchTo(thread)
    eventLoop.emit("osmium:barupdate")
  end
end

local isBroadcastingColorChange = false
function osmiumAPI.setColor(color)
  local shouldNotify = false
  if color ~= user.color and not isBroadcastingColorChange then
    shouldNotify = true
  end
  user.color = color
  users.updateUser(user.id, user)
  if shouldNotify then
    isBroadcastingColorChange = true
    local currentTerm = term.current()
    eventLoop.emit("osmium:color")
    term.redirect(currentTerm)
    isBroadcastingColorChange = false
  end
end

function osmiumAPI.setPassword(newPassword, oldPassword)
  if (not user.password) or users.auth(user.id, oldPassword) then
    if newPassword then
      users.setPassword(user.id, newPassword)
    else
      user.password = nil
      user.salt = nil
      users.updateUser(user.id, user)
    end
    return true
  else
    return false
  end
end

function osmiumAPI.getHomeID()
  return homeThread
end

function osmiumAPI.signOut()
  eventLoop.stop()
  unexpected = false
end

barThread = createThread(function()
  local sandbox = OsmiumSandbox.create({
    switchTo = switchTo,
    getHomeID = osmiumAPI.getHomeID,
    getVisibleThread = function()
      return visibleThread
    end,
    getThreads = function()
      return threads
    end,
    close = removeThread
  }, user, permissions, {})
  sandbox.run(opm.resolve("osmium-bar"))
end, window.create(currentTerm, 1, h, w, 1, true))

homeThread = createThread(function()
  focus = 1
  switchTo(2)
  run(opm.resolve("osmium-home"))
end)

eventLoop.run()
term.redirect(currentTerm)

if unexpected then
  term.setBackgroundColor(colors.blue)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(2, 2)
  print(":(")
  term.setCursorPos(2, 4)
  print("Your computer needs to restart.")
  term.setCursorPos(2, 6)
  print("ERR_EVENT_LOOP_TERMINATED")
  sleep(5)
  term.setBackgroundColor(colors.black)
  term.clear()
  sleep(1)
end
