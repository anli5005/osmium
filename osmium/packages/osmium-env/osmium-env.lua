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
local visibleThread = nil
local focus = 0
local barThread = nil

local unexpected = true

local function createThread(fn, win)
  local thread = {coroutine = coroutine.create(fn), window = win or window.create(currentTerm, 1, 1, w, h - 1, false), interacted = false}
  table.insert(threads, thread)
  term.redirect(thread.window)
  thread.success, thread.filter = coroutine.resume(thread.coroutine)
  thread.status = coroutine.status(thread.coroutine)
  return #threads, thread
end

local function switchTo(index)
  if visibleThread and visibleThread ~= index then
    threads[visibleThread].window.setVisible(false)
  end
  visibleThread = index
  threads[index].window.setVisible(true)
  threads[index].window.redraw()
  if focus == 1 then
    focus = 0
  end
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
  if event ~= "mouse_click" and event ~= "mouse_up" and event ~= "mouse_scroll" and event ~= "mouse_drag" and event ~= "char" and event ~= "key" and event ~= "paste" and event ~= "key_up" and event ~= "osmium:barupdate" then
    local toRemove = {}
    for i,t in pairs(threads) do
      if t and (t.filter == event or not t.filter) then
        term.redirect(t.window)
        t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
        t.status = coroutine.status(t.coroutine)
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
          term.redirect(t.window)
          t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
          t.status = coroutine.status(t.coroutine)
          t.interacted = true
          if t.status == "dead" then
            removeThread(visibleThread)
          end
        end
      end
    elseif barThread then
      focus = 2
      local t = threads[barThread]
      if t.filter == event or not t.filter then
        term.redirect(t.window)
        local resumeArgs = arg
        resumeArgs[3] = 1
        t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(resumeArgs))
        t.status = coroutine.status(t.coroutine)
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
          term.redirect(t.window)
          t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
          t.status = coroutine.status(t.coroutine)
          t.interacted = true
          if t.status == "dead" then
            removeThread(visibleThread)
          end
        end
      end
    elseif barThread then
      local t = threads[barThread]
      if t.filter == event or not t.filter then
        term.redirect(t.window)
        local resumeArgs = arg
        resumeArgs[3] = 1
        t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(resumeArgs))
        t.status = coroutine.status(t.coroutine)
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
          term.redirect(t.window)
          t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
          t.status = coroutine.status(t.coroutine)
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
          term.redirect(t.window)
          local resumeArgs = arg
          resumeArgs[3] = 1
          t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(resumeArgs))
          t.status = coroutine.status(t.coroutine)
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
        term.redirect(t.window)
        t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
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

local function run(path, ...)
  local permissions = {}
  if user.admin then
    permissions.editSystem = true
    permissions.otherUsers = true
  end
  local sandbox = OsmiumSandbox.create(osmiumAPI, user, permissions, {})
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
  if threads[i] and appNames[path] then
    threads[i].name = appNames[path]
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

local homeThread
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
    end
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
