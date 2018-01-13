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

-- TODO: Load polyfills for `window` and `term.blit`

-- Load opm
os.loadAPI("/osmium/opm.lua")

local test = opm.require("test")
test.hello()
