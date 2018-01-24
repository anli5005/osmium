local IronEventLoop = opm.require("iron-event-loop")
local IronScreen = opm.require("iron-screen")
local IronView = opm.require("iron-view")
local UI = opm.require("osmium-ui")

local eventLoop = IronEventLoop.create()

local w, h = term.getSize()
local termWindow = window.create(term.current(), 1, 1, w, h, true)

local screen = IronScreen.create(termWindow)
screen.attach(eventLoop)

local osmiumText = "Osmium"
local label = UI.text.create(math.floor((w - string.len(osmiumText)) / 2), math.floor((h - 1) / 2), string.len(osmiumText), 1, osmiumText)
label.textColor = colors.lightGray
screen.addView(label)

local button = UI.button.create(1, h - 2, w, 3, "Set up ->")
button.backgroundColor = colors.blue
button.textColor = colors.white
button.activeBackgroundColor = colors.cyan
button.activeTextColor = colors.white
screen.addView(button)

button.on("press", function()
  screen.removeView(label)
  screen.removeView(button)

  local white = UI.box.create(1, 1, w, h, colors.white)
  screen.addView(white)

  local textbox = UI.input.create(2, 2, 20, 1)
  textbox.placeholder = "Username"
  screen.addView(textbox)

  local password = UI.input.create(1, h - 2, w, 3, "", "*")
  password.placeholder = "Password"
  screen.addView(password)
end)

screen.forceDraw()
eventLoop.run()
