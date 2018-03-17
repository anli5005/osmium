local IronScreen = opm.require("iron-screen")
local lock = opm.require("osmium-settings-lock")
local OsmiumColors = opm.require("osmium-colors").colors
local setup = opm.require("osmium-setup")
local UI = opm.require("osmium-ui")
local users = opm.require("osmium-users")
local TeletextUI = opm.require("osmium-teletext-ui")

local a,h = term.getSize()

local function setPassword(id, newPassword, adminPassword)
  return osmium.setPassword(newPassword, adminPassword)
end
if osmium.user.admin then
  function setPassword(id, newPassword, adminPassword)
    if id == osmium.user.id then
      return osmium.setPassword(newPassword, adminPassword)
    else
      if (not osmium.user.password) or users.auth(osmium.user.id, adminPassword) then
        if newPassword then
          users.setPassword(id, newPassword)
        else
          user.password = nil
          user.salt = nil
          users.updateUser(id, user)
        end
        return true
      else
        return false
      end
    end
  end
end

function create(w, loop, forceDraw)
  local screen = IronScreen.create(nil)

  local box = UI.box.create(1, 1, w, h, colors.white)
  screen.addView(box)

  local lock = lock.addTo(screen, w, h)

  local bigtext = TeletextUI.text.create(2, 2, 16, 3, "Users")
  bigtext.backgroundColor = colors.white
  bigtext.textColor = colors.black
  bigtext.size = 1
  screen.addView(bigtext)

  local selectButton = UI.button.create(18, 2, w - 18, 3, "Select User v")
  selectButton.backgroundColor = colors.gray
  selectButton.textColor = colors.white
  selectButton.activeBackgroundColor = colors.lightGray
  selectButton.activeTextColor = colors.gray
  screen.addView(selectButton)

  local aboutName, aboutType, noPermissionLabel, passwordButton, deleteButton
  local user = nil
  local userID = nil

  local function reset()
    screen.removeView(aboutName)
    screen.removeView(aboutType)

    if noPermissionLabel then
      screen.removeView(noPermissionLabel)
    end

    if passwordButton then
      screen.removeView(passwordButton)
    end

    if adminButton then
      screen.removeView(adminButton)
    end
  end

  local function selectUser(id)
    if aboutName then
      reset()
    end

    userID = id
    user = users.getUser(id)

    aboutName = UI.text.create(1, 6, w, 1, " " .. user.username)
    aboutName.backgroundColor = user.color or colors.blue
    aboutName.textColor = OsmiumColors[user.color or colors.blue].colors[1]
    screen.addView(aboutName)

    local type = "Standard"
    if user.admin then
      type = "Administrator"
    end
    aboutType = UI.text.create(1, 7, w, 1, " " .. type)
    aboutType.backgroundColor = user.color or colors.blue
    aboutType.textColor = OsmiumColors[user.color or colors.blue].colors[2]
    screen.addView(aboutType)

    if osmium.user.admin or osmium.user.id == id then
      passwordButton = UI.button.create(2, 9, 17, 1, "Change Password")
      passwordButton.setDisabled(not lock.isUnlocked)
      screen.addView(passwordButton)

      if osmium.user.admin then
        if user.admin then
          adminButton = UI.button.create(2, 11, 15, 1, "Make Standard")
          adminButton.backgroundColor = colors.red
          adminButton.textColor = colors.white
        else
          adminButton = UI.button.create(2, 11, 12, 1, "Make Admin")
        end
        adminButton.setDisabled(not lock.isUnlocked)
        screen.addView(adminButton)

        adminButton.on("press", function()
          if user.admin then
            user.admin = false
          else
            user.admin = true
          end

          if osmium.user.id == id then
            osmium.signOut()
          end

          users.updateUser(userID, user)
          selectUser(userID)
        end)

        deleteButton = UI.button.create(2, 13, 16, 1, "Delete Account")
        deleteButton.backgroundColor = colors.red
        deleteButton.textColor = colors.white
        deleteButton.setDisabled(not lock.isUnlocked)
        screen.addView(deleteButton)
      end
    else
      noPermissionLabel = UI.text.create(2, 9, w - 1, 1, "You don't have permission")
      noPermissionLabel.backgroundColor = colors.white
      noPermissionLabel.textColor = colors.lightGray
      screen.addView(noPermissionLabel)
    end
  end

  lock.on("unlock", function()
    if passwordButton then
      passwordButton.setDisabled(false)
    end
    if adminButton then
      adminButton.setDisabled(false)
      deleteButton.setDisabled(false)
    end
  end)

  lock.on("lock", function()
    if passwordButton then
      passwordButton.setDisabled(true)
    end
    if adminButton then
      adminButton.setDisabled(true)
      deleteButton.setDisabled(true)
    end
  end)

  local function addUser()
    local result = setup.setupOsmium(true)
    if result then
      local id = users.insertUser({username = result.username, admin = false})
      if result.password then
        users.setPassword(id, result.password)
      end
      os.reboot()
    else
      forceDraw()
      screen.forceDraw()
    end
  end

  local rows = {}
  local userlist = users.getUsers()
  for i,user in pairs(userlist) do
    if user.id == osmium.user.id then
      user.username = user.username .. " (You)"
    end
    if user.admin then
      table.insert(rows, {text = "[A] " .. user.username, id = i})
    else
      table.insert(rows, {text = "[ ] " .. user.username, id = i})
    end
  end
  if osmium.user.admin then
    table.insert(rows, {text = " +  Add user", add = true})
  end

  local selectList = UI.list.create(2, 5, w - 2, h - 5, rows)
  selectList.row.selectable = false
  selectList.backgroundColor = colors.lightGray

  local showingUsers = false
  selectList.on("click", function(row)
    if row.id then
      selectUser(row.id)
    else
      addUser()
    end
    showingUsers = false
    screen.removeView(selectList)
  end)

  selectButton.on("press", function()
    if not showingUsers then
      screen.addView(selectList)
      showingUsers = true
    end
  end)

  selectUser(osmium.user.id)

  return screen
end
