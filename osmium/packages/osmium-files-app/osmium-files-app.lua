local OsmiumBrowser = opm.require("osmium-file-browser")
local IronEventLoop = opm.require("iron-event-loop")

local loop = IronEventLoop.create()
local browser = OsmiumBrowser.create(term.current(), {dir = shell.dir()})
browser.screen.attach(loop)
loop.run()
