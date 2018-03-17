local events = opm.require("iron-events")
local UI = opm.require("osmium-ui")
local users = opm.require("osmium-users")

function addTo(screen, width, height)
  local self = events.create()
  self.isUnlocked = false

  local w = width
  local h = height
  if screen.window then
    w,h = screen.window.getSize()
  end

  local text = nil
  local input = nil
  local button = nil

  local unlock
  local createUnlockButton
  local lock
  local createLockButton

  unlock = function()
    screen.removeView(text)
    if input then
      screen.removeView(input)
    end
    screen.removeView(button)

    self.isUnlocked = true
    self.emit("unlock")

    createLockButton()
  end

  createUnlockButton = function()
    if osmium.user.password then
      text = UI.text.create(2, h - 3, w - 1, 1, "Type your password to make changes.")
      text.backgroundColor = colors.white
      text.textColor = colors.black
      screen.addView(text)

      input = UI.input.create(1, h - 2, w - 8, 3, "", "*")
      input.placeholder = "Password"
      screen.addView(input)

      button = UI.button.create(w - 7, h - 2, 8, 3, "Unlock")
      button.backgroundColor = colors.yellow
      button.textColor = colors.black
      button.activeBackgroundColor = colors.orange
      button.activeTextColor = colors.black
      button.setDisabled(true)
      input.on("change", function(value)
        button.setDisabled((not value) or #value < 1)
      end)
      button.on("press", function()
        if users.auth(osmium.user.id, input.value) then
          unlock()
        else
          button.backgroundColor = colors.red
          input.placeholderColor = colors.red
          input.value = ""
          input.redraw()
        end
      end)
      screen.addView(button)
    else
      text = UI.text.create(2, h - 3, w - 1, 1, "Click the button to make changes.")
      text.backgroundColor = colors.white
      text.textColor = colors.black
      screen.addView(text)

      button = UI.button.create(1, h - 2, w, 3, "Unlock")
      button.backgroundColor = colors.yellow
      button.textColor = colors.black
      button.activeBackgroundColor = colors.orange
      button.activeTextColor = colors.black
      button.on("press", unlock)
      screen.addView(button)
    end
  end

  lock = function()
    screen.removeView(text)
    screen.removeView(button)

    self.isUnlocked = false
    self.emit("lock")

    createUnlockButton()
  end

  createLockButton = function()
    text = UI.text.create(2, h - 3, w - 1, 1, "Click Lock to stop making changes.")
    text.backgroundColor = colors.white
    text.textColor = colors.black
    screen.addView(text)

    button = UI.button.create(1, h - 2, w, 3, "Lock")
    button.backgroundColor = colors.yellow
    button.textColor = colors.black
    button.activeBackgroundColor = colors.orange
    button.activeTextColor = colors.black
    button.on("press", lock)
    screen.addView(button)
  end

  createUnlockButton()

  return self
end
