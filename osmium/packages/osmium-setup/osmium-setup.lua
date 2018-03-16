local IronEventLoop = opm.require("iron-event-loop")
local IronScreen = opm.require("iron-screen")
local IronView = opm.require("iron-view")
local UI = opm.require("osmium-ui")
local TeletextUI = opm.require("osmium-teletext-ui")

function setupOsmium()
  local result = {}

  local eventLoop = IronEventLoop.create()

  local w, h = term.getSize()
  local termWindow = window.create(term.current(), 1, 1, w, h, true)

  local screen = IronScreen.create(termWindow)
  screen.attach(eventLoop)

  local osmiumText = "Osmium"
  local label = UI.text.create(math.floor((w - string.len(osmiumText)) / 2), math.floor((h - 1) / 2), string.len(osmiumText), 1, osmiumText)
  label.textColor = colors.lightGray
  screen.addView(label, true)

  local button = UI.button.create(1, h - 2, w, 3, "Set up ->")
  button.backgroundColor = colors.blue
  button.textColor = colors.white
  button.activeBackgroundColor = colors.cyan
  button.activeTextColor = colors.white
  screen.addView(button, true)

  button.on("press", function()
    screen.removeView(label)
    screen.removeView(button)

    local white = UI.box.create(1, 1, w, h, colors.white)
    screen.addView(white)

    local bigtext = TeletextUI.text.create(2, 2, 20, 3, "Hello, world!")
    bigtext.backgroundColor = colors.white
    bigtext.textColor = colors.black
    bigtext.size = 1
    screen.addView(bigtext)

    local description1 = UI.text.create(2, 5, 20, 1, "Welcome to Osmium!")
    description1.backgroundColor = colors.white
    description1.textColor = colors.gray
    screen.addView(description1)

    local description2 = UI.text.create(2, 6, 20, 1, "Start by creating an account.")
    description2.backgroundColor = colors.white
    description2.textColor = colors.gray
    screen.addView(description2)

    local usernameField = UI.input.create(2, 8, 20, 1)
    usernameField.placeholder = "Username"
    screen.addView(usernameField)

    local nextButton = UI.button.create(1, h - 2, w, 3, "Next ->")
    nextButton.backgroundColor = colors.blue
    nextButton.textColor = colors.white
    nextButton.activeBackgroundColor = colors.cyan
    nextButton.activeTextColor = colors.white
    nextButton.setDisabled(true)
    screen.addView(nextButton)

    usernameField.on("change", function(value)
      if nextButton.getDisabled() and string.len(value) > 0 then
        nextButton.setDisabled(false)
      elseif string.len(value) < 1 and not nextButton.getDisabled() then
        nextButton.setDisabled(true)
      end
    end)

    local checkbox = UI.checkbox.create(2, 8, 20, 1, "Create a password", false)
    checkbox.backgroundColor = colors.white
    checkbox.textColor = colors.gray

    local passwordField = UI.input.create(2, 10, 20, 1, "", "*")
    passwordField.placeholder = "Password"
    passwordField.setDisabled(true)

    local prevButton = UI.button.create(1, h - 2, 11, 3, "<- Prev")
    prevButton.backgroundColor = colors.red
    prevButton.textColor = colors.white
    prevButton.activeBackgroundColor = colors.pink
    prevButton.activeTextColor = colors.white

    local finishButton = UI.button.create(12, h - 2, w - 11, 3, "Finish ->")
    finishButton.backgroundColor = colors.green
    finishButton.textColor = colors.white
    finishButton.activeBackgroundColor = colors.lime
    finishButton.activeTextColor = colors.white

    nextButton.on("press", function()
      screen.removeView(nextButton, true)
      screen.removeView(usernameField, true)
      screen.addView(checkbox, true)
      screen.addView(passwordField, true)
      screen.addView(prevButton, true)
      screen.addView(finishButton, true)

      bigtext.text = "Safe and secure"
      description1.text = "In Osmium, you can set a password to"
      description2.text = "protect your account."

      screen.forceDraw()
    end)

    prevButton.on("press", function()
      screen.removeView(prevButton, true)
      screen.removeView(finishButton, true)
      screen.removeView(checkbox, true)
      screen.removeView(passwordField, true)
      screen.addView(usernameField, true)
      screen.addView(nextButton, true)

      bigtext.text = "Hello, world!"
      description1.text = "Welcome to Osmium!"
      description2.text = "Start by creating an account."

      screen.forceDraw()
    end)

    local function checkFinishDisabled()
      if finishButton.getDisabled() and (string.len(passwordField.value) > 0 or not checkbox.isChecked) then
        finishButton.setDisabled(false)
      elseif (string.len(passwordField.value) < 1 and checkbox.isChecked) and not finishButton.getDisabled() then
        finishButton.setDisabled(true)
      end
    end

    checkbox.on("change", function(value)
      passwordField.setDisabled(not value)
      checkFinishDisabled()
    end)

    passwordField.on("change", function()
      checkFinishDisabled()
    end)

    finishButton.on("press", function()
      screen.removeView(prevButton, true)
      screen.removeView(finishButton, true)
      screen.removeView(checkbox, true)
      screen.removeView(passwordField, true)
      screen.removeView(bigtext, true)
      screen.removeView(description1, true)
      screen.removeView(description2, true)
      screen.removeView(white, true)
      screen.addView(label, true)

      local settingUpText = "Setting up..."
      local settingUp = UI.text.create(math.floor((w - string.len(settingUpText)) / 2), label.y + 2, string.len(settingUpText), 1, settingUpText)
      settingUp.textColor = colors.gray
      screen.addView(settingUp, true)

      screen.forceDraw()

      result.username = usernameField.value
      if checkbox.isChecked then
        result.password = passwordField.value
      end
      result.color = colors.blue
      eventLoop.stop()
    end)
  end)

  screen.forceDraw()
  eventLoop.run()
  return result
end
