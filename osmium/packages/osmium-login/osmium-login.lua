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
