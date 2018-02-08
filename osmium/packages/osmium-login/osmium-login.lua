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

local eventLoop = opm.require("iron-event-loop").create()
local w, h = term.getSize()
local termWindow = window.create(term.current(), 1, 1, w, h, true)
local screen = opm.require("iron-screen").create(termWindow)

local view = opm.require("iron-view").create(2, 2, 10, 10)
local scroller = opm.require("osmium-ui").scroller.create(view, 10000)
function view.draw(window)
  window.setBackgroundColor(colors.blue)
  window.setTextColor(colors.white)
  for y = view.y,view.y + view.h - 1 do
    window.setCursorPos(view.x, y)
    for i = 1,view.w do
      window.write(" ")
    end
    window.setCursorPos(view.x, y)
    window.write(scroller.pos + y - view.y)
  end
  scroller.draw(window)
end
function view.scroll(event)
  scroller.scroll(event)
end
function view.click(event)
  scroller.click(event)
end
function view.drag(event)
  scroller.drag(event)
end
function view.mouseUp(event)
  scroller.mouseUp(event)
end
screen.addView(view)
screen.attach(eventLoop)
eventLoop.run()
