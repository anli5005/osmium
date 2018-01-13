{
  ["boot"] = "osmium",
  ["profiles"] = {
    ["osmium"] = {
      ["name"] = "Osmium",
      ["boot"] = "/osmium/osmium.lua"
    },
    ["craftos"] = {
      ["name"] = "CraftOS",
      ["boot"] = "/rom/programs/shell.lua"
    }
  },
  ["enabledProfiles"] = {
    "osmium",
    "craftos"
  }
}
