local IronScreen = opm.require("iron-screen")
local UI = opm.require("osmium-ui")
local TeletextUI = opm.require("osmium-teletext-ui")
local filesize = opm.require("osmium-filesize")

local a,h = term.getSize()

function create(w)
  local screen = IronScreen.create(nil)

  local box = UI.box.create(1, 1, w, h, colors.black)
  screen.addView(box)

  local abouttext = UI.text.create(2, 2, 16, 1, "About")
  abouttext.backgroundColor = colors.black
  abouttext.textColor = colors.gray
  screen.addView(abouttext)

  local bigtext = TeletextUI.text.create(2, 3, 16, 3, "Osmium OS")
  bigtext.backgroundColor = colors.black
  bigtext.textColor = colors.white
  bigtext.size = 1
  screen.addView(bigtext)

  local versiontext = UI.text.create(2, 6, 16, 1, "Version 1.0")
  versiontext.backgroundColor = colors.black
  versiontext.textColor = colors.lightGray
  screen.addView(versiontext)

  local computerType
  if commands then
    computerType = "Command"
  elseif term.isColor() then
    computerType = "Advanced"
  else
    computerType = "Standard"
  end
  if pocket then
    computerType = computerType .. " Pocket"
  end

  local texts = {
    os.getComputerLabel() or ("Computer " .. os.getComputerID()),
    "ID:   " .. os.getComputerID(),
    "Type: " .. computerType,
    "Host: " .. _HOST or (_CC_VERSION .. "(MC " .. _MC_VERSION .. ")"),
    os.version(),
    "",
    filesize.formatDiskSize(fs.getFreeSpace("/")) .. " bytes free",
    "",
    "Credits",
    "Design & Code - anli5005",
    "Ink           - oeed",
    "NPaintPro     - NitrogenFingers",
    "BigFont       - Wojbie",
    "SHA256        - lua-users.org",
    "base64        - Alex Kloss",
    "magiclines    - StackOverflow",
    "ComputerCraft - dan200",
    "",
    "Made with <3 by anli5005 at",
    "github.com/anli5005/osmium",
    ""
  }

  local rows = {}
  for k,v in ipairs(texts) do
    rows[k] = {text = v}
  end
  local list = UI.list.create(1, 8, w, h - 7, rows)
  list.backgroundColor = colors.black
  list.textColor = colors.white
  list.setPadding(0)
  list.row.selectable = false
  screen.addView(list)

  return screen
end
