-- Draw splash screen
term.setBackgroundColor(colors.black)
term.clear()
term.setCursorBlink(false)
term.setTextColor(colors.gray)
local w,h = term.getSize()
local osmium = "Osmium"
term.setCursorPos(math.floor((w - string.len(osmium)) / 2), math.floor(h / 2))
term.write(osmium)
sleep(0.1)

-- Define functions
local function openBootManager(settings)
  term.clear()
  term.setCursorPos(4,2)
  term.setTextColor(colors.white)
  print("Osmium Boot Manager")

  local y = {}
  local nextY = 4
  local selected = 4

  for k,v in pairs(settings.profiles) do
    term.setCursorPos(4, nextY)
    print(v.name)
    y[nextY] = k
    if k == settings.boot then
      selected = nextY
    end
    nextY = nextY + 1
  end

  term.setTextColor(colors.lightGray)

  while true do
    term.setCursorPos(1, selected)
    term.write("->")
    local event, key = os.pullEvent("key")

    if key == keys.enter then
      break
    elseif key == keys.up then
      if selected > 4 then
        term.setCursorPos(1, selected)
        term.write("  ")
        selected = selected - 1
      end
    elseif key == keys.down then
      if selected > #settings.profiles + 3 then
        term.setCursorPos(1, selected)
        term.write("  ")
        selected = selected + 1
      end
    end
  end

  return settings.profiles[y[selected]].boot
end

-- Read boot settings
if fs.exists("/boot/settings.lua") then
  local stream = fs.open("/boot/settings.lua", "r")
  local settings = textutils.unserialize(stream.readAll())
  stream.close()

  local toBoot
  if settings and settings.boot and settings.profiles and settings.profiles[settings.boot] and settings.profiles[settings.boot].boot then
    toBoot = settings.profiles[settings.boot].boot
  else
    toBoot = openBootManager(settings)
  end

  local message = "Press ALT for more options"
  term.setCursorPos(math.floor((w - string.len(message)) / 2), h - 1)
  term.write(message)

  local timer = os.startTimer(0.5)
  while true do
    local event, p = os.pullEvent()
    if event == "timer" and p == timer then
      break
    elseif event == "key" and (p == 56 or p == 184) then
      toBoot = openBootManager(settings)
      break
    end
  end

  if fs.exists(toBoot) then
    -- Boot the computer
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.clear()
    term.setCursorPos(1,1)
    os.run(getfenv(), toBoot)
  else
    term.setCursorPos(1, h - 1)
    term.clearLine()
    if term.isColor() then
      term.setTextColor(colors.red)
    else
      term.setTextColor(colors.white)
    end
    local error = "Cannot locate boot file"
    term.setCursorPos(math.floor((w - string.len(error)) / 2), h - 1)
    term.write(error)
    sleep(3)
    term.clear()
    term.setCursorPos(1,1)
    if not term.isColor() then
      term.setTextColor(colors.lightGray)
    end
    term.write(toBoot)
    print(" not found")
    if term.isColor() then
      term.setTextColor(colors.yellow)
    else
      term.setTextColor(colors.white)
    end
    print(os.version())
  end
else
  local error = "Boot settings not found"
  term.setCursorPos(math.floor((w - string.len(error)) / 2), h - 1)
  if term.isColor() then
    term.setTextColor(colors.red)
  else
    term.setTextColor(colors.white)
  end
  term.write(error)
  sleep(3)
  term.clear()
  term.setCursorPos(1,1)
  if not term.isColor() then
    term.setTextColor(colors.lightGray)
  end
  print("/boot/settings.lua not found")
  if term.isColor() then
    term.setTextColor(colors.yellow)
  end
  print(os.version())
end
