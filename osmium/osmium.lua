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
log.setup()
osmium.log = log.log

osmium.log("Welcome to Osmium OS!")
osmium.log("Current time: " .. textutils.formatTime(os.time()))
osmium.log("[ ok ] Logging system initialized.")

-- TODO: Load polyfills for `window` and `term.blit`
if not window then
  osmium.log("[warn] Window API not found.")
  osmium.log("[info] Attempting to use a polyfill...")
  osmium.log("[todo] Polyfills have not been implemented.")
end

if not term.blit then
  osmium.log("[warn] term.blit not found.")
  osmium.log("[info] Attempting to use a polyfill...")
  osmium.log("[todo] Polyfills have not been implemented.")
end
