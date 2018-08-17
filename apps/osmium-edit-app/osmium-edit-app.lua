local args = {...}
local file = args[1]

if not file then
  local OsmiumBrowser = opm.require("osmium-file-browser")
  local IronEventLoop = opm.require("iron-event-loop")

  local loop = IronEventLoop.create()
  local w, h = term.getSize()
  term.setCursorPos(1, 2)
  term.setBackgroundColor(colors.lightGray)
  term.clearLine()
  term.setTextColor(colors.gray)
  local message = "Select a file"
  term.setCursorPos(math.floor((w - #message) / 2), 2)
  term.write(message)
  term.setBackgroundColor(colors.black)
  term.setCursorPos(1, 2)
  term.write(" ")
  term.setCursorPos(w, 2)
  term.write(" ")
  local browser = OsmiumBrowser.create(window.create(term.current(), 2, 3, w - 2, h - 3), {dir = shell.dir(), action = "open"})
  browser.screen.attach(loop)
  browser.on("cancel", function()
    loop.stop()
  end)
  browser.on("open", function(path)
    file = path
    loop.stop()
  end)
  loop.run()
end

if file then
  if file:sub(1,1) ~= "/" then
    file = "/" .. file
  end
  if fs.exists("/rom/programs/edit.lua") then
    shell.run("/rom/programs/edit.lua", file)
  else
    shell.run("/rom/programs/edit", file)
  end
end
