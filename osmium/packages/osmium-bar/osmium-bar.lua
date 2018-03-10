local IronEventLoop = opm.require("iron-event-loop")
local IronScreen = opm.require("iron-screen")
local IronView = opm.require("iron-view")
local OsmiumColors = opm.require("osmium-colors").colors
local UI = opm.require("osmium-ui")

local color = colors.blue

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
  eventLoop.emit("osmium:barupdate")
end)
screen.addView(button)

local buffer = {}
local view = IronView.create(9, 1, w - 8, 1)
function view.draw(window)
  window.setBackgroundColor(color)
  window.setCursorPos(view.x, view.y)
  window.write(string.rep(" ", view.w))
  for i,p in ipairs(buffer) do
    window.setCursorPos(view.x + i - 1, view.y)
    window.setBackgroundColor(p.color)
    window.setTextColor(p.textColor)
    window.write(p.text)
  end
end
function view.click(event)
  if event.button == 1 then
    local x = event.x + 1 - view.x
    if buffer[x] and buffer[x].id then
      if buffer[x].close then
        osmium.close(buffer[x].id)
      else
        osmium.switchTo(buffer[x].id)
      end
      eventLoop.emit("osmium:barupdate")
    end
  end
  return true
end
screen.addView(view)

local threads = {}

function updateThreads()
  threads = {}
  local t = osmium.getThreads()
  for k,v in pairs(t) do
    if k > 2 then
      table.insert(threads, {name = v.name or "process", id = k})
    end
  end
end

function updateBuffer()
  buffer = {}
  local visible = osmium.getVisibleThread()
  local k = 1
  for i,t in ipairs(threads) do
    local bkg = color
    local txt = OsmiumColors[color].colors[1]
    if t.id == visible then
      bkg = txt
      txt = color
      buffer[k] = {text = "X", textColor = colors.white, color = colors.red, id = t.id, close = true}
      k = k + 1
    end
    buffer[k] = {text = " ", textColor = txt, color = bkg, id = t.id, close = false}
    k = k + 1
    for j = 1,#t.name do
      buffer[k] = {text = t.name:sub(j, j), textColor = txt, color = bkg, id = t.id, close = false}
      k = k + 1
    end
    buffer[k] = {text = " ", textColor = txt, color = bkg, id = t.id, close = false}
    k = k + 1
  end
end

eventLoop.on("osmium:barupdate", function()
  updateThreads()
  updateBuffer()
  view.redraw()

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
