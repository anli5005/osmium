local AppRegistry = opm.require("osmium-app-registry")
local IronEventLoop = opm.require("iron-event-loop")
local IronScreen = opm.require("iron-screen")
local OsmiumColors = opm.require("osmium-colors").colors
local UI = opm.require("osmium-ui")

local color = colors.green
local signOutColor = colors.red

local loop = IronEventLoop.create()
local w, h = term.getSize()
local screen = IronScreen.create(term.current())

local appRow = {height = 3, selectable = false}
function appRow.drawLine(window, row, num, isSelected, x, y, w, view)
  window.setBackgroundColor(OsmiumColors[color].colors[1])
  window.setTextColor(color)
  window.setCursorPos(x, y)
  if num ~= 2 then
    window.write(string.rep(" ", w))
  else
    window.write(string.rep(" ", 1) .. row.text .. string.rep(" ", math.max(0, w - (1 + string.len(row.text)))))
  end
end

local rows = {}
local list = UI.list.create(1, 1, w, h, rows, appRow)
list.setPadding(5)
list.backgroundColor = color
list.textColor = OsmiumColors[color].colors[1]
screen.addView(list)

local signOut = UI.button.create(2, 2, w - 2, 3, "Sign out")
signOut.backgroundColor = signOutColor
signOut.textColor = OsmiumColors[signOutColor].colors[1]
signOut.activeBackgroundColor = OsmiumColors[signOutColor].colors[2]
signOut.activeTextColor = signOutColor
signOut.on("press", osmium.signOut)
screen.addView(signOut)

local function refreshApps()
  AppRegistry.readSystem()
  table.sort(AppRegistry.registry, function(a, b)
    return a.name < b.name
  end)
end

local function update()
  term.setTextColor(colors.black)
  refreshApps()
  list.removeAllRows()
  for i,a in ipairs(AppRegistry.registry) do
    list.addRow({text = a.name, app = a})
  end
end

local run = shell.run
if osmium and osmium.run then
  run = function(path)
    osmium.switchTo(osmium.run(path))
  end
end

list.on("click", function(row)
  local path = row.app.exec
  if path then
    if path:sub(1,1) ~= "/" then
      path = "/" .. path
    end
    run(path)
  end
end)

screen.attach(loop)
update()
loop.run()
