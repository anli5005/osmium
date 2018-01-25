osmium.log("[ ok ] osmium-boot started.")
sleep(0.1)

local env = {osmium = osmium}
setmetatable(env, {__index = _G})

osmium.log("[info] Checking for users...")
if fs.exists("/osmium/settings/users.lson") then
  osmium.log("[ ok ] Users file found.")
  osmium.log("[info] Running osmium-login...")
  os.run(env, opm.resolve("osmium-login"))
else
  osmium.log("[ ok ] Users file not found.")
  osmium.log("[info] Running osmium-setup...")

  local result = textutils.serialize(opm.require("osmium-setup").setupOsmium())
  local w, h = term.getSize()
  term.setCursorPos(1, h - 5)
  term.setTextColor(colors.white)
  print(result)
end
