term.setBackgroundColor(colors.gray)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(2,2)
term.write("Settings")

sleep(0.1)

local IronEventLoop = opm.require("iron-event-loop")
local IronScreen = opm.require("iron-screen")
local OsmiumColors = opm.require("osmium-colors").colors
local UI = opm.require("osmium-ui")

local color = colors.gray
local sideWidth = 14

local w,h = term.getSize()

local loop = IronEventLoop.create()

local sideWindow = window.create(term.current(), 1, 1, sideWidth, h, false)
local sidebar = IronScreen.create(sideWindow)

local currentScreen
local screens = {
  colors = opm.require("osmium-settings-colors").create(w - sideWidth, loop),
  users = opm.require("osmium-settings-users").create(w - sideWidth, loop, sidebar.requestForceDraw),
  updates = opm.require("osmium-settings-updates").create(w - sideWidth, loop)
}

local mainWindow = window.create(term.current(), sideWidth + 1, 1, w - sideWidth, h)
mainWindow.setBackgroundColor(colors.white)
mainWindow.clear()
sideWindow.setVisible(true)

local function hideScreen(screen)
  screen.detach(loop)
  screen.window = nil
  currentScreen = nil
end

local function showScreen(screen)
  screen.window = mainWindow
  screen.attach(loop)
  screen.requestForceDraw()
end

sidebar.addView(UI.box.create(sideWidth, 1, 1, h, colors.lightGray))

local bar = UI.box.create(1, 1, sideWidth - 1, 3, color)
sidebar.addView(bar)
local barText = UI.text.create(2, 2, sideWidth - 2, 1, "Settings")
barText.backgroundColor = color
barText.textColor = OsmiumColors[color].colors[1]
sidebar.addView(barText)

local rows = {
  {
    screen = "colors",
    text = "Colors"
  },
  {
    screen = "users",
    text = "Users"
  },
  {
    screen = "updates",
    text = "Updates"
  }
}
local list = UI.list.create(1, 4, sideWidth - 1, h - 3, rows)
list.on("select", function(row)
  if currentScreen then
    hideScreen(screens[currentScreen])
    if not row.screen then
      mainWindow.setBackgroundColor(colors.white)
      mainWindow.clear()
    end
  end
  if row.screen then
    showScreen(screens[row.screen])
    currentScreen = row.screen
  end
end)
sidebar.addView(list)

sidebar.attach(loop)
loop.run()
