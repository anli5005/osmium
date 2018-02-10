osmium.log("[ ok ] osmium-boot started.")
sleep(0.1)

local env = {osmium = osmium}
setmetatable(env, {__index = _G})

osmium.log("[info] Running osmium-login...")
os.run(env, opm.resolve("osmium-login"))

os.shutdown()
