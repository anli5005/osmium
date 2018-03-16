local IronScreen = opm.require("iron-screen")
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

function create(w)
  local screen = IronScreen.create(nil)

  local box = UI.box.create(1, 1, w, h, colors.white)
  screen.addView(box)

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

  local function addUser()
  end

  local function selectUser(id)
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
  table.insert(rows, {text = " +  Add user", add = true})

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
