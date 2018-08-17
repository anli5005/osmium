local lson = opm.require("osmium-lson")

local registry = "/osmium/settings/filetypes.lson"
if not fs.exists(registry) then
  fs.copy(opm.resolveFile("osmium-filetype-registry", "default.lson"), registry)
end

function getAll()
  return lson.read(registry)
end
