local IronScreen = opm.require("iron-screen")
local UI = opm.require("osmium-ui")
local TeletextUI = opm.require("osmium-teletext-ui")

local h = term.getSize()

function create(w)
  local screen = IronScreen.create(nil)

  local box = UI.box.create(1, 1, w, h, colors.white)
  screen.addView(box)

  local bigtext = TeletextUI.text.create(2, 2, w - 1, 3, "Colors")
  bigtext.backgroundColor = colors.white
  bigtext.textColor = colors.black
  bigtext.size = 1
  screen.addView(bigtext)

  return screen
end
