local users = opm.require("osmium-users")
local UI = opm.require("osmium-ui")

local setupID = nil

osmium.log("[info] Checking for users...")
if not fs.exists("/osmium/settings/users.lson") then
  osmium.log("[ ok ] Users file not found.")
  osmium.log("[info] Running osmium-setup...")

  local setupResult = opm.require("osmium-setup").setupOsmium()
  setupID = users.insertUser({username = setupResult.username, admin = true})
  if setupResult.password then
    users.setPassword(setupID, setupResult.password)
  end
end

local eventLoop = opm.require("iron-event-loop").create()
local w, h = term.getSize()
local currentTerm = term.current()
local termWindow = window.create(currentTerm, 1, 1, w, h, true)
local screen = opm.require("iron-screen").create(termWindow)

local userlist = users.getUsers()
local rows = {}
for k,v in pairs(userlist) do
  table.insert(rows, {id = k, text = v.username})
end

local list = UI.list.create(1, 1, 16, h, rows)
list.row.height = 3
list.backgroundColor = colors.gray
list.textColor = colors.white
list.update()

local box = UI.box.create(17, 1, w - 16, h - 3, colors.black)

local selectedUser = nil

local passwordField = nil
local unlockButton = nil

local function login()
  if not fs.exists(fs.combine("/home", userlist[selectedUser].username)) then
    fs.makeDir(fs.combine("/home", userlist[selectedUser].username))
  end
  os.oldPullEvent = os.pullEvent
  os.pullEvent = os.pullEventRaw
  os.run(getfenv(), opm.resolve("osmium-env"), selectedUser)
  os.pullEvent = os.oldPullEvent
  os.oldPullEvent = nil
  term.redirect(currentTerm)
  userlist = users.getUsers()
  --sleep(10)
  passwordField.cursorPos = 0
  local userlist = users.getUsers()
  list.rows = {}
  for k,v in ipairs(userlist) do
    table.insert(list.rows, {id = k, text = v.username})
  end
  screen.requestForceDraw()
end

local function tryPassword()
  if selectedUser and passwordField and unlockButton then
    if users.auth(selectedUser, passwordField.value) then
      unlockButton.backgroundColor = colors.blue
      passwordField.placeholderColor = colors.lightGray
      passwordField.value = ""
      login()
    else
      unlockButton.backgroundColor = colors.red
      passwordField.placeholderColor = colors.red
      passwordField.redraw()
    end
  end
end

if setupID then
  selectedUser = setupID
  login()
end

list.on("deselect", function()
  selectedUser = nil

  if passwordField then
    screen.removeView(passwordField)
  end

  if unlockButton then
    screen.removeView(unlockButton)
  end
end)

list.on("select", function(row)
  selectedUser = row.id
  if userlist[selectedUser].password then
    passwordField = UI.input.create(17, h - 2, w - 12, 3, "", "*")
    passwordField.placeholder = "Password"
    passwordField.backgroundColor = colors.white
    passwordField.placeholderColor = colors.lightGray
    passwordField.textColor = colors.black
    screen.addView(passwordField)

    unlockButton = UI.button.create(w - 3, h - 2, 4, 3, "->")
    unlockButton.backgroundColor = colors.blue
    unlockButton.textColor = colors.white
    unlockButton.activeBackgroundColor = colors.cyan
    unlockButton.activeTextColor = colors.white
    unlockButton.setDisabled(true)
    screen.addView(unlockButton)

    passwordField.on("change", function(value)
      unlockButton.setDisabled((not value) or #value < 1)
    end)

    passwordField.on("enter", tryPassword)
    unlockButton.on("press", tryPassword)
  else
    unlockButton = UI.button.create(17, h - 2, w - 16, 3, "Unlock ->")
    unlockButton.backgroundColor = colors.blue
    unlockButton.textColor = colors.white
    unlockButton.activeBackgroundColor = colors.cyan
    unlockButton.activeTextColor = colors.white
    unlockButton.on("press", login)
    screen.addView(unlockButton)
  end

  box.color = userlist[selectedUser].color or colors.blue
  box.redraw()
end)

screen.addView(list)
screen.addView(box)

screen.attach(eventLoop)
eventLoop.run()
