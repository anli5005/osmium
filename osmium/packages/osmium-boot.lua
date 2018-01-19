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
  os.run(env, opm.resolve("osmium-setup"))
end
