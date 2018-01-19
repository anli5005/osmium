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

-- Load opm
local env = {}
setmetatable(env, {__index = _G})
os.run(env, "/osmium/opm.lua")

local o = {}
for k,v in pairs(env) do
  if k ~= "_ENV" then
    o[k] = v
  end
end
_G["opm"] = o

local osmium = {}

-- Setup logging
local log = opm.require("osmium-log")
local logStream = fs.open(log.logFile, "w")
logStream.write("")
logStream.close()
log.setup()
osmium.log = log.log

-- Finish booting
osmium.log("Booting Osmium...")
osmium.log("Current time: " .. textutils.formatTime(os.time()))
osmium.log("[ ok ] Logging system initialized.")
osmium.log("[info] Launching osmium-boot...")

local bootEnv = {osmium = osmium}
setmetatable(bootEnv, {__index = _G})
os.run(bootEnv, opm.resolve("osmium-boot"))
