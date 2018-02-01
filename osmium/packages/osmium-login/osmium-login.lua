local setupResult = nil

osmium.log("[info] Checking for users...")
if not fs.exists("/osmium/settings/users.lson") then
  osmium.log("[ ok ] Users file not found.")
  osmium.log("[info] Running osmium-setup...")

  setupResult = textutils.serialize(opm.require("osmium-setup").setupOsmium())
end
