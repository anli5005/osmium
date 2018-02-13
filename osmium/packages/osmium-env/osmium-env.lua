term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()

local args = {...}

local IronEventLoop = opm.require("iron-event-loop")
local OsmiumSandbox = opm.require("osmium-sandbox")
local eventLoop = IronEventLoop.create()

local users = opm.require("osmium-users")
local user = users.getUser(args[1])
user.id = args[1]

local currentTerm = term.current()
local w, h = term.getSize()

local threads = {}
local visibleThread = nil
local focus = 0
local barThread = nil

local unexpected = true

local function createThread(fn, win)
  local thread = {coroutine = coroutine.create(fn), window = win or window.create(currentTerm, 1, 1, w, h - 1, false)}
  table.insert(threads, thread)
  term.redirect(thread.window)
  thread.success, thread.filter = coroutine.resume(thread.coroutine)
  thread.status = coroutine.status(thread.coroutine)
  return index, thread
end

local function removeThread(index)
  if visibleThread == index then
    visibleThread = nil
  end
  if barThread == index then
    barThread = nil
  end
  threads[index] = nil
end

local function switchTo(index)
  if visibleThread then
    threads[visibleThread].window.setVisible(false)
  end
  visibleThread = index
  threads[visibleThread].window.setVisible(true)
  if focus == 1 then
    focus = 0
  end
end

eventLoop.all(function(event, ...)
  if event ~= "mouse_click" and event ~= "mouse_up" and event ~= "mouse_scroll" and event ~= "mouse_drag" and event ~= "char" and event ~= "key" and event ~= "paste" and event ~= "key_up" then
    local toRemove = {}
    for i,t in ipairs(threads) do
      if t and (t.filter == event or not t.filter) then
        term.redirect(t.window)
        t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
        t.status = coroutine.status(t.coroutine)
        if t.status == "dead" then
          toRemove[i] = true
        end
      end
    end
    for k,b in ipairs(toRemove) do
      --removeThread(k)
    end
  elseif event == "mouse_click" then
    local y = arg[3]
    if y < h then
      if visibleThread then
        focus = 1
        local t = threads[visibleThread]
        term.redirect(t.window)
        t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
        t.status = coroutine.status(t.coroutine)
        if t.status == "dead" then
          removeThread(visibleThread)
        end
      end
    elseif barThread then
      focus = 2
      local t = threads[barThread]
      term.redirect(t.window)
      local resumeArgs = arg
      resumeArgs[3] = 1
      t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(resumeArgs))
      t.status = coroutine.status(t.coroutine)
      if t.status == "dead" then
        removeThread(barThread)
      end
    else
      focus = 0
    end
  elseif event == "mouse_up" or event == "mouse_scroll" or event == "mouse_drag" then
    local y = arg[3]
    if y < h then
      if visibleThread then
        local t = threads[visibleThread]
        term.redirect(t.window)
        t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
        t.status = coroutine.status(t.coroutine)
        if t.status == "dead" then
          removeThread(visibleThread)
        end
      end
    elseif barThread then
      local t = threads[barThread]
      term.redirect(t.window)
      local resumeArgs = arg
      resumeArgs[3] = 1
      t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(resumeArgs))
      t.status = coroutine.status(t.coroutine)
      if t.status == "dead" then
        removeThread(barThread)
      end
    end
  elseif event == "key" or event == "char" or event == "key_up" or event == "paste" then
    if focus == 1 then
      if visibleThread then
        local t = threads[visibleThread]
        term.redirect(t.window)
        t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
        t.status = coroutine.status(t.coroutine)
        if t.status == "dead" then
          removeThread(visibleThread)
        end
      end
    elseif focus == 2 then
      if barThread then
        local t = threads[barThread]
        term.redirect(t.window)
        t.success, t.filter = coroutine.resume(t.coroutine, event, unpack(arg))
        t.status = coroutine.status(t.coroutine)
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

barThread = createThread(function()
  local ok, err = pcall(function()
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(1,1)
    sleep(1)
    local sandbox = OsmiumSandbox.create({}, user)
    sandbox.run(opm.resolve("osmium-bar"))
  end)
  if err then
    term.setCursorPos(1,1)
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.red)
    term.write(err)
  end
end, window.create(currentTerm, 1, h, w, 1, true))

createThread(function()
  switchTo(2)
  sleep(1)
  print("Hello!")
end)

createThread(function()
  sleep(2)
  switchTo(3)
  print("Hi!")
end)

createThread(function()
  sleep(3)
  switchTo(4)
  textutils.slowPrint("Goodbye!")
  sleep(1)
  unexpected = false
  eventLoop.stop()
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
