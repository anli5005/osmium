local IronScreen = opm.require("iron-screen")
local OsmiumColors = opm.require("osmium-colors").colors
local UI = opm.require("osmium-ui")
local TeletextUI = opm.require("osmium-teletext-ui")

local h = term.getSize()

function create(w, loop)
  local screen = IronScreen.create(nil)

  local box = UI.box.create(1, 1, w, h, colors.white)
  screen.addView(box)

  local bigtext = TeletextUI.text.create(2, 2, w - 1, 3, "Colors")
  bigtext.backgroundColor = colors.white
  bigtext.textColor = colors.black
  bigtext.size = 1
  screen.addView(bigtext)

  local currentColor = UI.box.create(2, 6, 1, 1, (osmium.user and osmium.user.color) or colors.blue)
  local currentColorLabel = UI.text.create(4, 6, w - 4, 1, OsmiumColors[(osmium.user and osmium.user.color) or colors.blue].name)
  currentColorLabel.backgroundColor = colors.white
  currentColorLabel.textColor = colors.black

  -- Create buttons
  local buttons = {
    {colors.white, colors.orange, colors.magenta, colors.lightBlue, colors.yellow, colors.lime, colors.pink, colors.gray},
    {colors.lightGray, colors.cyan, colors.purple, colors.blue, colors.brown, colors.green, colors.red, colors.black}
  }

  for i,row in ipairs(buttons) do
    local y = 7 + i
    for j,col in ipairs(row) do
      local x = 2 + (2 * (j - 1))
      local button = UI.button.create(x, y, 2, 1, "")
      button.backgroundColor = col
      button.activeBackgroundColor = OsmiumColors[col].colors[2]
      button.on("press", function()
        osmium.setColor(col)
        currentColor.color = col
        currentColorLabel.text = OsmiumColors[col].name
        currentColor.redraw()
      end)
      screen.addView(button, true)
    end
  end

  screen.addView(currentColor)
  screen.addView(currentColorLabel)

  loop.on("osmium:color", function()
    currentColor.color = (osmium.user and osmium.user.color) or colors.blue
    currentColorLabel.text = OsmiumColors[(osmium.user and osmium.user.color) or colors.blue].name
    currentColor.redraw()
  end)

  return screen
end
