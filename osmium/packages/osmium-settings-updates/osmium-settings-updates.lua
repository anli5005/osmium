local IronScreen = opm.require("iron-screen")
local UI = opm.require("osmium-ui")
local TeletextUI = opm.require("osmium-teletext-ui")

local h = term.getSize()

function create(w)
  local screen = IronScreen.create(nil)

  local box = UI.box.create(1, 1, w, h, colors.white)
  screen.addView(box)

  local bigtext = UI.text.create(2, 2, w - 1, 1, "Coming soon.")
  bigtext.backgroundColor = colors.white
  bigtext.textColor = colors.red
  bigtext.size = 1
  screen.addView(bigtext)

  return screen
end
