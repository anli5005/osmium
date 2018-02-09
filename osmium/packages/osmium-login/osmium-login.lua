local users = opm.require("osmium-users")

local setupID = nil

osmium.log("[info] Checking for users...")
if not fs.exists("/osmium/settings/users.lson") then
  osmium.log("[ ok ] Users file not found.")
  osmium.log("[info] Running osmium-setup...")

  local setupResult = opm.require("osmium-setup").setupOsmium()
  setupID = users.insertUser({username = setupResult.username, home = fs.combine("/home", setupResult.username)})
  if setupResult.password then
    users.setPassword(setupID, setupResult.password)
  end
end

if setupID then
end

local eventLoop = opm.require("iron-event-loop").create()
local w, h = term.getSize()
local termWindow = window.create(term.current(), 1, 1, w, h, true)
local screen = opm.require("iron-screen").create(termWindow)

local userlist = users.getUsers()
local rows = {}
for k,v in ipairs(userlist) do
  table.insert(rows, {id = k, text = v.username})
end

local list = opm.require("osmium-ui").list.create(1, 1, 16, h, rows)
list.row.height = 3
list.backgroundColor = colors.gray
list.textColor = colors.white
list.update()

list.on("select", function(row)
  term.setCursorPos(18, 2)
  term.setBackgroundColor(colors.black)
  term.setTextColor(colors.white)
  print(textutils.serialize(users.getUser(row.id)))
end)

screen.addView(list)

screen.attach(eventLoop)
eventLoop.run()
