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
local function openBootManager()
  term.clear()
  term.setCursorPos(1,1)
  print("Boot manager")
  term.setTextColor(colors.white)
  print("Booting into CraftOS...")
  sleep(1)
  return "/rom/programs/shell.lua"
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
    toBoot = openBootManager()
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
      toBoot = openBootManager()
      break
    end
  end

  -- Boot the computer
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  term.clear()
  term.setCursorPos(1,1)
  os.run({shell = shell}, toBoot)
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
