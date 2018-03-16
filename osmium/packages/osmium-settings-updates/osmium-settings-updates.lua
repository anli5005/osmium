local IronScreen = opm.require("iron-screen")
local UI = opm.require("osmium-ui")
--local TeletextUI = opm.require("osmium-teletext-ui")

local a,h = term.getSize()

function create(w)
  local screen = IronScreen.create(nil)

  local box = UI.box.create(1, 1, w, h, colors.white)
  screen.addView(box)

  if osmium.user.admin then
    local update = UI.button.create(2, 2, w - 2, 3, "Update")
    update.on("press", function()
      term.setBackgroundColor(colors.black)
      term.setTextColor(colors.white)
      term.clear()
      term.setCursorPos(1, 1)
      os.run({}, "/rom/programs/http/pastebin.lua", "run", "0fVDrAC1")
      os.reboot()
    end)
    screen.addView(update)
  end

  return screen
end
