local IronScreen = opm.require("iron-screen")
local UI = opm.require("osmium-ui")
local TeletextUI = opm.require("osmium-teletext-ui")

local a,h = term.getSize()

function create(w)
  local screen = IronScreen.create(nil)

  local box = UI.box.create(1, 1, w, h, colors.white)
  screen.addView(box)

  local bigtext = TeletextUI.text.create(2, 2, 16, 3, "System")
  bigtext.backgroundColor = colors.white
  bigtext.textColor = colors.black
  bigtext.size = 1
  screen.addView(bigtext)

  if osmium.user.admin then
    local cclabel = UI.text.create(2, 6, 16, 1, "ComputerCraft Settings")
    cclabel.backgroundColor = colors.white
    cclabel.textColor = colors.black
    screen.addView(cclabel)

    local ccdescription = UI.text.create(2, 7, 16, 1, "Saved to '.settings'")
    ccdescription.backgroundColor = colors.white
    ccdescription.textColor = colors.lightGray
    screen.addView(ccdescription)

    if settings then
      local checkboxes = {
        {setting = "shell.autocomplete", text = "Use autocomplete in shell"},
        {setting = "lua.autocomplete", text = "Use autocomplete in 'lua'"},
        {setting = "edit.autocomplete", text = "Use autocomplete in 'edit'"},
        {setting = "shell.allow_disk_startup", text = "Start up from disk"}
      }

      for k,v in ipairs(checkboxes) do
        local checkbox = UI.checkbox.create(2, 7 + (k * 2), 16, 1, v.text, settings.get(v.setting))
        checkbox.backgroundColor = colors.white
        checkbox.textColor = colors.black
        checkbox.on("change", function(value)
          settings.set(v.setting, value)
          settings.save(".settings")
        end)
        screen.addView(checkbox)
      end

      local allowStartupCheckbox = UI.checkbox.create(2, 9 + (#checkboxes * 2), 16, 1, "Start up from startup.lua", settings.get("bios.allow_startup"))
      allowStartupCheckbox.backgroundColor = colors.white
      allowStartupCheckbox.textColor = colors.red
      allowStartupCheckbox.on("change", function(value)
        settings.set("shell.allow_startup", value)
        settings.save(".settings")
      end)
      screen.addView(allowStartupCheckbox)

      local allowStartupLabel = UI.text.create(2, 10 + (#checkboxes * 2), 16, 1, "Unchecking will prevent Osmium from")
      allowStartupLabel.backgroundColor = colors.white
      allowStartupLabel.textColor = colors.lightGray
      screen.addView(allowStartupLabel)
      local allowStartupLabel2 = UI.text.create(2, 11 + (#checkboxes * 2), 16, 1, "booting.")
      allowStartupLabel2.backgroundColor = colors.white
      allowStartupLabel2.textColor = colors.lightGray
      screen.addView(allowStartupLabel2)
    else
      ccdescription.text = "Update ComputerCraft"
      ccdescription.redraw()
    end
  else
    local label = UI.text.create(2, 6, 16, 1, "You need to be an admin to change")
    label.backgroundColor = colors.white
    label.textColor = colors.gray
    screen.addView(label)

    local label2 = UI.text.create(2, 7, 16, 1, "these settings.")
    label2.backgroundColor = colors.white
    label2.textColor = colors.gray
    screen.addView(label2)
  end

  return screen
end
