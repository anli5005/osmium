local IronEventLoop = opm.require("iron-event-loop")
local IronScreen = opm.require("iron-screen")
local IronView = opm.require("iron-view")
local OsmiumColors = opm.require("osmium-colors").colors
local UI = opm.require("osmium-ui")

local color = colors.black

local eventLoop = IronEventLoop.create()

local w,h = term.getSize()
local window = window.create(term.current(), 1, 1, w, h)
local screen = IronScreen.create(window)
screen.attach(eventLoop)

local button = UI.button.create(1, 1, 8, 1, "Osmium")
button.backgroundColor = OsmiumColors[color].colors[1]
button.textColor = color
button.activeBackgroundColor = OsmiumColors[color].colors[2]
button.activeTextColor = OsmiumColors[color].colors[1]
button.on("press", function()
  local id = osmium.getHomeID()
  osmium.switchTo(id)
  button.backgroundColor = OsmiumColors[color].colors[1]
  button.redraw()
end)
screen.addView(button)

eventLoop.on("osmium:barupdate", function()
  if osmium.getVisibleThread() == osmium.getHomeID() then
    term.write(osmium.getVisibleThread())
    term.write(osmium.getHomeID())
    button.backgroundColor = OsmiumColors[color].colors[1]
    button.redraw()
  else
    button.backgroundColor = OsmiumColors[color].colors[2]
    button.redraw()
  end
end)

screen.attach(eventLoop)
eventLoop.run()
