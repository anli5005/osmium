local AppRegistry = opm.require("osmium-app-registry")
local imageutils = opm.require("imageutils")
local IronEventLoop = opm.require("iron-event-loop")
local IronScreen = opm.require("iron-screen")
local OsmiumColors = opm.require("osmium-colors").colors
local UI = opm.require("osmium-ui")

local color = (osmium.user and osmium.user.color) or colors.blue
local signOutColor = colors.red

local loop = IronEventLoop.create()
local w, h = term.getSize()
local screen = IronScreen.create(term.current())

local appRow = {height = 3, selectable = false}
function appRow.drawLine(window, row, num, isSelected, x, y, w, view)
  local bkg = row.backgroundColor or OsmiumColors[color].colors[1]
  local txt = row.textColor or color
  if row.id % 2 > 0 and not row.backgroundColor then
    bkg = OsmiumColors[color].colors[2]
  end
  --[[if row.id % 2 > 0 and not row.textColor then
    txt = OsmiumColors[color].colors[1]
  end]]--
  window.setCursorPos(x, y)
  if row.image then
    imageutils.drawImage({
      {
        bg = {row.image[1].bg[num]},
        fg = row.image[1].fg and {row.image[1].fg[num]},
        text = row.image[1].text and {row.image[1].text[num]}
      }
    }, bkg)
  else
    window.setBackgroundColor(bkg)
    window.setTextColor(txt)
    if row.icon and row.icon.bg and row.icon.bg[num] then
      local r = row.icon.bg[num]
      imageutils.drawImage({
        {
          bg = {r},
          fg = row.icon.fg and {row.icon.fg[num]},
          text = row.icon.text and {row.icon.text[num]}
        }
      }, bkg)
      window.setBackgroundColor(bkg)
      window.setTextColor(txt)
      window.setCursorPos(x + #r, y)
    end
    if num ~= 2 then
      window.write(string.rep(" ", w))
    else
      window.write(string.rep(" ", 1) .. row.text .. string.rep(" ", math.max(0, w - (1 + string.len(row.text)))))
    end
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
    local row = {text = a.name, app = a, id = i}
    if a.icon and fs.exists(a.icon) then
      row.icon = imageutils.loadFromFile(a.icon)[1]
    end
    if a.package and opm.resolveInfo(a.package) then
      local info = opm.getInfo(a.package)
      if info.osmium and info.osmium.home then
        local home = info.osmium.home
        row.backgroundColor = home.backgroundColor
        row.textColor = home.textColor
        if home.image then
          local image = opm.resolveFile(a.package, home.image)
          if fs.exists(image) then
            local buffer = imageutils.crop(imageutils.loadFromFile(image), w, 3)
            if not home.hideText then
              if not buffer[1].fg[2] then
                buffer[1].fg[2] = {}
              end
              if not buffer[1].text[2] then
                buffer[1].text[2] = {}
              end
              for j = 1,#row.text do
                buffer[1].fg[2][j + 1] = row.textColor or color
                buffer[1].text[2][j + 1] = row.text:sub(j,j)
              end
            end
            row.image = buffer
          end
        end
      end
      if info.icon and not row.image then
        local icon = opm.resolveFile(a.package, info.icon)
        if fs.exists(icon) then
          row.icon = imageutils.loadFromFile(icon)[1]
        end
      end
    end
    list.addRow(row)
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

loop.on("osmium:color", function()
  color = (osmium.user and osmium.user.color) or colors.blue
  list.backgroundColor = color

  screen.forceDraw()
end)

screen.attach(loop)
update()
loop.run()
